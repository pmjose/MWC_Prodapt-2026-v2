"""
ServiceNow to Snowflake MCP Integration - Key-Pair Authentication Test
======================================================================
This script demonstrates JWT-based authentication for ServiceNow IntegrationHub.

Requirements:
    pip install PyJWT cryptography requests

Usage:
    python test_keypair_auth.py
"""

import jwt
import time
import hashlib
import base64
import requests
import json
from datetime import datetime, timedelta
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend

# ============================================================================
# Configuration
# ============================================================================
SNOWFLAKE_ACCOUNT = "SFSEEUROPE-PJOSE_AWS3"
SNOWFLAKE_ACCOUNT_LOCATOR = "RA19199"
SNOWFLAKE_USER = "SERVICENOW_SVC_USER"
PRIVATE_KEY_PATH = "keys/servicenow_rsa_key.p8"

# MCP Endpoint
MCP_ENDPOINT = f"https://ra19199.eu-west-3.aws.snowflakecomputing.com/api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/mcp-servers/TELCO_ASSURANCE_MCP"


def load_private_key(key_path):
    """Load private key from file."""
    with open(key_path, "rb") as key_file:
        private_key = serialization.load_pem_private_key(
            key_file.read(),
            password=None,
            backend=default_backend()
        )
    return private_key


def get_public_key_fingerprint(private_key):
    """Calculate SHA256 fingerprint of the public key."""
    public_key = private_key.public_key()
    public_key_bytes = public_key.public_bytes(
        encoding=serialization.Encoding.DER,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    )
    sha256_hash = hashlib.sha256(public_key_bytes).digest()
    fingerprint = base64.b64encode(sha256_hash).decode('utf-8')
    return f"SHA256:{fingerprint}"


def generate_jwt_token(account, user, private_key, lifetime_minutes=60):
    """Generate JWT token for Snowflake authentication."""
    
    # Get the public key fingerprint
    fingerprint = get_public_key_fingerprint(private_key)
    
    # Qualified username
    qualified_username = f"{account.upper()}.{user.upper()}"
    
    # Current time
    now = datetime.utcnow()
    
    # JWT payload
    payload = {
        "iss": f"{qualified_username}.{fingerprint}",
        "sub": qualified_username,
        "iat": now,
        "exp": now + timedelta(minutes=lifetime_minutes)
    }
    
    # Sign the token
    token = jwt.encode(
        payload,
        private_key,
        algorithm="RS256"
    )
    
    return token


def test_mcp_tools_list(token):
    """Test MCP tools/list endpoint."""
    print("\n[TEST] MCP tools/list")
    print("-" * 50)
    
    response = requests.post(
        MCP_ENDPOINT,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}",
            "X-Snowflake-Authorization-Token-Type": "KEYPAIR_JWT"
        },
        json={
            "jsonrpc": "2.0",
            "id": 1,
            "method": "tools/list",
            "params": {}
        }
    )
    
    print(f"Status: {response.status_code}")
    try:
        result = response.json()
        print(json.dumps(result, indent=2))
        return response.status_code == 200
    except:
        print(response.text[:500])
        return False


def test_mcp_sql_query(token, query, query_name="SQL Query"):
    """Test MCP SQL execution."""
    print(f"\n[TEST] {query_name}")
    print("-" * 50)
    
    response = requests.post(
        MCP_ENDPOINT,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}",
            "X-Snowflake-Authorization-Token-Type": "KEYPAIR_JWT"
        },
        json={
            "jsonrpc": "2.0",
            "id": 2,
            "method": "tools/call",
            "params": {
                "name": "sql_exec_tool",
                "arguments": {
                    "sql": query
                }
            }
        }
    )
    
    print(f"Status: {response.status_code}")
    try:
        result = response.json()
        print(json.dumps(result, indent=2))
        return response.status_code == 200
    except:
        print(response.text[:500])
        return False


def main():
    print("=" * 60)
    print("ServiceNow → Snowflake MCP Key-Pair Authentication Test")
    print("=" * 60)
    
    # Step 1: Load private key
    print("\n[STEP 1] Loading private key...")
    try:
        private_key = load_private_key(PRIVATE_KEY_PATH)
        print("SUCCESS: Private key loaded")
    except Exception as e:
        print(f"ERROR: Failed to load private key - {e}")
        return
    
    # Step 2: Calculate fingerprint
    print("\n[STEP 2] Calculating public key fingerprint...")
    fingerprint = get_public_key_fingerprint(private_key)
    print(f"Fingerprint: {fingerprint}")
    
    # Step 3: Generate JWT token
    print("\n[STEP 3] Generating JWT token...")
    try:
        token = generate_jwt_token(SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER, private_key)
        print(f"SUCCESS: JWT token generated ({len(token)} chars)")
        print(f"Token preview: {token[:50]}...")
    except Exception as e:
        print(f"ERROR: Failed to generate token - {e}")
        return
    
    # Step 4: Test MCP endpoints
    print("\n[STEP 4] Testing MCP endpoints...")
    
    # Test tools/list
    test_mcp_tools_list(token)
    
    # Test SQL queries
    queries = [
        ("Barcelona Alarms", "SELECT severity, COUNT(*) as count FROM TELCO_AI_DB.NETWORK_ASSURANCE.ALARMS WHERE region='BARCELONA' GROUP BY severity"),
        ("Network KPIs", "SELECT kpi_name, ROUND(AVG(kpi_value),2) as avg FROM TELCO_AI_DB.NETWORK_ASSURANCE.NETWORK_KPI WHERE region='BARCELONA' GROUP BY kpi_name LIMIT 5"),
        ("SLA Breaches", "SELECT service_id, metric, penalty_eur FROM TELCO_AI_DB.NETWORK_ASSURANCE.SLA_BREACHES ORDER BY penalty_eur DESC LIMIT 3"),
    ]
    
    for name, query in queries:
        test_mcp_sql_query(token, query, name)
    
    print("\n" + "=" * 60)
    print("Test Complete")
    print("=" * 60)
    
    # Print ServiceNow configuration
    print("\n" + "=" * 60)
    print("ServiceNow Configuration")
    print("=" * 60)
    print(f"""
Store the private key securely in ServiceNow:
- Go to: Connections & Credentials > Credentials
- Create: "JWT Credential"  
- Private Key: Contents of keys/servicenow_rsa_key.p8
- Account: {SNOWFLAKE_ACCOUNT}
- User: {SNOWFLAKE_USER}

MCP Endpoint: {MCP_ENDPOINT}

Headers required:
- Content-Type: application/json
- Authorization: Bearer <JWT_TOKEN>
- X-Snowflake-Authorization-Token-Type: KEYPAIR_JWT
""")


if __name__ == "__main__":
    main()
