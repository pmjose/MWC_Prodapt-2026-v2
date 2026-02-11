#!/usr/bin/env python3
"""
Test script for Snowflake MCP Server and Cortex Agent (A2A)
Generates JWT token and runs test queries against both endpoints.
"""

import json
import time
import requests
from datetime import datetime, timedelta
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend
import jwt
import hashlib
import base64
import os

# =============================================================================
# CONFIGURATION
# =============================================================================
ACCOUNT_LOCATOR = "RA19199"
REGION = "eu-west-3.aws"
DATABASE = "TELCO_AI_DB"
SCHEMA = "NETWORK_ASSURANCE"

# Service account for testing (update these)
USER = "A2A_SVC_USER"  # or "SERVICENOW_SVC_USER" for MCP
PRIVATE_KEY_PATH = os.path.expanduser("~/.ssh/snowflake_a2a_key.pem")

# Endpoints
BASE_URL = f"https://{ACCOUNT_LOCATOR.lower()}.{REGION}.snowflakecomputing.com"
MCP_ENDPOINT = f"{BASE_URL}/api/v2/databases/{DATABASE}/schemas/{SCHEMA}/mcp-servers/TELCO_ASSURANCE_MCP"
AGENT_ENDPOINT = f"{BASE_URL}/api/v2/databases/{DATABASE}/schemas/{SCHEMA}/agents/TELCO_ASSURANCE_AGENT:run"


def load_private_key(key_path: str):
    """Load RSA private key from file."""
    with open(key_path, "rb") as key_file:
        private_key = serialization.load_pem_private_key(
            key_file.read(),
            password=None,
            backend=default_backend()
        )
    return private_key


def get_public_key_fingerprint(private_key) -> str:
    """Generate SHA256 fingerprint of the public key."""
    public_key = private_key.public_key()
    public_key_bytes = public_key.public_bytes(
        encoding=serialization.Encoding.DER,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    )
    sha256_hash = hashlib.sha256(public_key_bytes).digest()
    fingerprint = base64.b64encode(sha256_hash).decode("utf-8")
    return f"SHA256:{fingerprint}"


def generate_jwt(account: str, user: str, private_key, lifetime_minutes: int = 60) -> str:
    """Generate JWT token for Snowflake key-pair authentication."""
    account_upper = account.upper()
    user_upper = user.upper()
    
    qualified_username = f"{account_upper}.{user_upper}"
    fingerprint = get_public_key_fingerprint(private_key)
    
    now = datetime.utcnow()
    payload = {
        "iss": f"{qualified_username}.{fingerprint}",
        "sub": qualified_username,
        "iat": now,
        "exp": now + timedelta(minutes=lifetime_minutes)
    }
    
    token = jwt.encode(payload, private_key, algorithm="RS256")
    return token


def test_mcp_tools_list(token: str) -> dict:
    """Test MCP Server - List available tools."""
    print("\n" + "=" * 60)
    print("TEST: MCP Server - tools/list")
    print("=" * 60)
    
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/list",
        "params": {}
    }
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "X-Snowflake-Authorization-Token-Type": "KEYPAIR_JWT"
    }
    
    response = requests.post(MCP_ENDPOINT, headers=headers, json=payload)
    print(f"Status: {response.status_code}")
    
    try:
        result = response.json()
        print(f"Response: {json.dumps(result, indent=2)}")
        return result
    except:
        print(f"Response: {response.text}")
        return {"error": response.text}


def test_mcp_sql_exec(token: str, query: str) -> dict:
    """Test MCP Server - Execute SQL via sql_exec_tool."""
    print("\n" + "=" * 60)
    print("TEST: MCP Server - sql_exec_tool")
    print(f"Query: {query}")
    print("=" * 60)
    
    payload = {
        "jsonrpc": "2.0",
        "id": 2,
        "method": "tools/call",
        "params": {
            "name": "sql_exec_tool",
            "arguments": {
                "query": query
            }
        }
    }
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "X-Snowflake-Authorization-Token-Type": "KEYPAIR_JWT"
    }
    
    response = requests.post(MCP_ENDPOINT, headers=headers, json=payload)
    print(f"Status: {response.status_code}")
    
    try:
        result = response.json()
        print(f"Response: {json.dumps(result, indent=2)}")
        return result
    except:
        print(f"Response: {response.text}")
        return {"error": response.text}


def test_mcp_analyst(token: str, question: str) -> dict:
    """Test MCP Server - Natural language query via analyst_tool."""
    print("\n" + "=" * 60)
    print("TEST: MCP Server - analyst_tool")
    print(f"Question: {question}")
    print("=" * 60)
    
    payload = {
        "jsonrpc": "2.0",
        "id": 3,
        "method": "tools/call",
        "params": {
            "name": "analyst_tool",
            "arguments": {
                "question": question
            }
        }
    }
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "X-Snowflake-Authorization-Token-Type": "KEYPAIR_JWT"
    }
    
    response = requests.post(MCP_ENDPOINT, headers=headers, json=payload)
    print(f"Status: {response.status_code}")
    
    try:
        result = response.json()
        print(f"Response: {json.dumps(result, indent=2)}")
        return result
    except:
        print(f"Response: {response.text}")
        return {"error": response.text}


def test_cortex_agent(token: str, message: str) -> dict:
    """Test Cortex Agent (A2A) - Natural language conversation."""
    print("\n" + "=" * 60)
    print("TEST: Cortex Agent (A2A)")
    print(f"Message: {message}")
    print("=" * 60)
    
    payload = {
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": message
                    }
                ]
            }
        ]
    }
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "X-Snowflake-Authorization-Token-Type": "KEYPAIR_JWT"
    }
    
    response = requests.post(AGENT_ENDPOINT, headers=headers, json=payload)
    print(f"Status: {response.status_code}")
    
    try:
        result = response.json()
        print(f"Response: {json.dumps(result, indent=2)}")
        return result
    except:
        print(f"Response: {response.text}")
        return {"error": response.text}


def generate_rsa_keypair():
    """Generate RSA key pair and print public key for Snowflake."""
    from cryptography.hazmat.primitives.asymmetric import rsa
    
    print("\n" + "=" * 60)
    print("GENERATING RSA KEY PAIR")
    print("=" * 60)
    
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
        backend=default_backend()
    )
    
    private_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    )
    
    public_key = private_key.public_key()
    public_pem = public_key.public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    )
    
    key_path = os.path.expanduser("~/.ssh/snowflake_a2a_key.pem")
    os.makedirs(os.path.dirname(key_path), exist_ok=True)
    
    with open(key_path, "wb") as f:
        f.write(private_pem)
    os.chmod(key_path, 0o600)
    
    print(f"Private key saved to: {key_path}")
    print("\nPublic key (add to Snowflake user):")
    print("-" * 40)
    
    public_key_str = public_pem.decode("utf-8")
    public_key_oneline = public_key_str.replace("-----BEGIN PUBLIC KEY-----", "").replace("-----END PUBLIC KEY-----", "").replace("\n", "")
    
    print(f"\nALTER USER {USER} SET RSA_PUBLIC_KEY = '{public_key_oneline}';")
    print("-" * 40)
    
    return private_key


def main():
    print("=" * 60)
    print("SNOWFLAKE MCP & A2A TEST SCRIPT")
    print("=" * 60)
    print(f"Account: {ACCOUNT_LOCATOR}")
    print(f"Region: {REGION}")
    print(f"User: {USER}")
    print(f"MCP Endpoint: {MCP_ENDPOINT}")
    print(f"Agent Endpoint: {AGENT_ENDPOINT}")
    
    if not os.path.exists(PRIVATE_KEY_PATH):
        print(f"\nPrivate key not found at: {PRIVATE_KEY_PATH}")
        print("Generating new RSA key pair...")
        private_key = generate_rsa_keypair()
        print("\n*** Run the ALTER USER command in Snowflake, then re-run this script ***")
        return
    
    print(f"\nLoading private key from: {PRIVATE_KEY_PATH}")
    private_key = load_private_key(PRIVATE_KEY_PATH)
    
    print("Generating JWT token...")
    token = generate_jwt(ACCOUNT_LOCATOR, USER, private_key)
    print(f"JWT Token (first 50 chars): {token[:50]}...")
    
    # ==========================================================================
    # MCP SERVER TESTS
    # ==========================================================================
    print("\n" + "#" * 60)
    print("# MCP SERVER TESTS")
    print("#" * 60)
    
    test_mcp_tools_list(token)
    
    test_mcp_sql_exec(token, 
        "SELECT state, COUNT(*) as cnt FROM TELCO_AI_DB.NETWORK_ASSURANCE.INCIDENTS GROUP BY state"
    )
    
    test_mcp_analyst(token, "How many open incidents are there?")
    
    # ==========================================================================
    # CORTEX AGENT (A2A) TESTS
    # ==========================================================================
    print("\n" + "#" * 60)
    print("# CORTEX AGENT (A2A) TESTS")
    print("#" * 60)
    
    test_cortex_agent(token, "What data sources do you have access to?")
    
    test_cortex_agent(token, "Show me the open incidents in the network")
    
    test_cortex_agent(token, "What regions have the highest anomaly scores?")
    
    print("\n" + "=" * 60)
    print("TESTS COMPLETED")
    print("=" * 60)


if __name__ == "__main__":
    main()
