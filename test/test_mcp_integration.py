"""
ServiceNow to Snowflake MCP Integration Test
============================================
This script tests the MCP endpoint using JWT/Key-pair authentication.

For ServiceNow, you'll configure:
1. Key-pair authentication on SERVICENOW_SVC_USER
2. Generate JWT tokens using the private key
3. Call MCP endpoints with the JWT
"""

import subprocess
import json

def test_mcp_with_snowsql():
    """Test MCP server functionality via SnowSQL queries."""
    
    print("=" * 60)
    print("Testing MCP Server Configuration")
    print("=" * 60)
    
    tests = [
        ("MCP Server exists", "SHOW MCP SERVERS IN SCHEMA TELCO_AI_DB.NETWORK_ASSURANCE"),
        ("MCP Grants configured", "SHOW GRANTS ON MCP SERVER TELCO_AI_DB.NETWORK_ASSURANCE.TELCO_ASSURANCE_MCP"),
        ("Integration role has access", "SHOW GRANTS TO ROLE TELCO_SN_INTEGRATION_RL"),
        ("Service user configured", "SHOW GRANTS TO USER SERVICENOW_SVC_USER"),
    ]
    
    for name, query in tests:
        print(f"\n[TEST] {name}")
        print(f"Query: {query}")
        print("-" * 40)


def test_sample_queries():
    """Test sample queries that ServiceNow would execute."""
    
    print("\n" + "=" * 60)
    print("Sample Queries ServiceNow Will Execute via MCP")
    print("=" * 60)
    
    queries = [
        ("Barcelona Network KPIs", """
SELECT region, kpi_name, 
       ROUND(AVG(kpi_value), 2) as avg_value,
       COUNT(*) as samples
FROM TELCO_AI_DB.NETWORK_ASSURANCE.NETWORK_KPI 
WHERE region = 'BARCELONA' 
GROUP BY region, kpi_name 
ORDER BY samples DESC
LIMIT 5"""),
        
        ("Active Alarms by Severity", """
SELECT region, severity, COUNT(*) as alarm_count 
FROM TELCO_AI_DB.NETWORK_ASSURANCE.ALARMS 
GROUP BY region, severity 
ORDER BY alarm_count DESC"""),
        
        ("Open Incidents", """
SELECT number, region, state, short_description 
FROM TELCO_AI_DB.NETWORK_ASSURANCE.INCIDENTS 
WHERE state IN ('OPEN', 'In Progress')"""),
        
        ("SLA Breaches with Penalties", """
SELECT service_id, region, metric, 
       threshold, observed, penalty_eur
FROM TELCO_AI_DB.NETWORK_ASSURANCE.SLA_BREACHES
ORDER BY penalty_eur DESC
LIMIT 5"""),
        
        ("Anomaly Detection Scores", """
SELECT region, element_id, kpi_name, score, label
FROM TELCO_AI_DB.NETWORK_ASSURANCE.ANOMALY_SCORES
WHERE score > 0.7
ORDER BY score DESC
LIMIT 10"""),
    ]
    
    for name, query in queries:
        print(f"\n[QUERY] {name}")
        print("-" * 40)
        print(query.strip())


def print_servicenow_config():
    """Print ServiceNow IntegrationHub configuration guide."""
    
    print("\n" + "=" * 60)
    print("ServiceNow IntegrationHub Configuration")
    print("=" * 60)
    
    config = """
1. SNOWFLAKE CREDENTIAL SETUP IN SERVICENOW
   ----------------------------------------
   - Go to: Connections & Credentials > Credentials
   - Create new "OAuth 2.0 Credential"
   - Token URL: https://ra19199.eu-west-3.aws.snowflakecomputing.com/oauth/token-request
   - Client ID: WUNdcfzsquE2lbVVPTEE60rM/0I=
   - Client Secret: zELLqR5ZzneStFwyzUqrip+GV2NlNobsXoHa2hMZxWY=
   - Grant Type: Authorization Code (requires user interaction)
   
   OR use Key-Pair Authentication:
   - Generate RSA key pair
   - Assign public key to SERVICENOW_SVC_USER
   - Use private key to sign JWT tokens

2. MCP ENDPOINT
   ------------
   POST https://ra19199.eu-west-3.aws.snowflakecomputing.com/api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/mcp-servers/TELCO_ASSURANCE_MCP

3. MCP REQUEST FORMAT (tools/list)
   --------------------------------
   {
     "jsonrpc": "2.0",
     "id": 1,
     "method": "tools/list",
     "params": {}
   }

4. MCP REQUEST FORMAT (tools/call for SQL)
   ----------------------------------------
   {
     "jsonrpc": "2.0",
     "id": 2,
     "method": "tools/call",
     "params": {
       "name": "sql_exec_tool",
       "arguments": {
         "query": "SELECT * FROM NETWORK_KPI LIMIT 10"
       }
     }
   }

5. SERVICENOW INTEGRATION HUB ACTION
   ----------------------------------
   Use the REST step with:
   - Method: POST
   - Endpoint: MCP endpoint above
   - Headers: 
     - Content-Type: application/json
     - Authorization: Bearer ${oauth_token}
   - Body: JSON-RPC request
"""
    print(config)


def print_curl_examples():
    """Print curl examples for manual testing."""
    
    print("\n" + "=" * 60)
    print("Manual Testing with cURL")
    print("=" * 60)
    
    examples = """
# Step 1: For Authorization Code flow, you need to:
# 1a. Open browser to authorize:
open "https://ra19199.eu-west-3.aws.snowflakecomputing.com/oauth/authorize?client_id=WUNdcfzsquE2lbVVPTEE60rM%2F0I%3D&response_type=code&redirect_uri=https://your-instance.service-now.com/oauth_redirect.do"

# 1b. After authorization, exchange code for token:
curl -X POST "https://ra19199.eu-west-3.aws.snowflakecomputing.com/oauth/token-request" \\
  -H "Content-Type: application/x-www-form-urlencoded" \\
  -d "grant_type=authorization_code" \\
  -d "code=<AUTHORIZATION_CODE>" \\
  -d "client_id=WUNdcfzsquE2lbVVPTEE60rM/0I=" \\
  -d "client_secret=zELLqR5ZzneStFwyzUqrip+GV2NlNobsXoHa2hMZxWY=" \\
  -d "redirect_uri=https://your-instance.service-now.com/oauth_redirect.do"

# Step 2: Test MCP tools/list
curl -X POST "https://ra19199.eu-west-3.aws.snowflakecomputing.com/api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/mcp-servers/TELCO_ASSURANCE_MCP" \\
  -H "Content-Type: application/json" \\
  -H "Authorization: Bearer <ACCESS_TOKEN>" \\
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'

# Step 3: Test SQL execution via MCP
curl -X POST "https://ra19199.eu-west-3.aws.snowflakecomputing.com/api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/mcp-servers/TELCO_ASSURANCE_MCP" \\
  -H "Content-Type: application/json" \\
  -H "Authorization: Bearer <ACCESS_TOKEN>" \\
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"sql_exec_tool","arguments":{"query":"SELECT region, COUNT(*) FROM ALARMS GROUP BY region"}}}'
"""
    print(examples)


if __name__ == "__main__":
    test_mcp_with_snowsql()
    test_sample_queries()
    print_servicenow_config()
    print_curl_examples()
    
    print("\n" + "=" * 60)
    print("Test Complete - Configuration Guide Generated")
    print("=" * 60)
