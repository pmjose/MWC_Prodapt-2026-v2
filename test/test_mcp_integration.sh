#!/bin/bash
# ============================================================================
# ServiceNow to Snowflake MCP Integration Test Script
# ============================================================================
# This script tests the full integration flow:
# 1. OAuth token acquisition
# 2. MCP tools/list call
# 3. MCP tools/call (SQL execution)
# ============================================================================

# Configuration - UPDATE THESE VALUES
SNOWFLAKE_ACCOUNT="SFSEEUROPE-PJOSE_AWS3"
SNOWFLAKE_ACCOUNT_URL="https://sfseeurope-pjose_aws3.snowflakecomputing.com"

# OAuth Credentials from SYSTEM$SHOW_OAUTH_CLIENT_SECRETS
OAUTH_CLIENT_ID="WUNdcfzsquE2lbVVPTEE60rM/0I="
OAUTH_CLIENT_SECRET="zELLqR5ZzneStFwyzUqrip+GV2NlNobsXoHa2hMZxWY="

# MCP Server endpoint
MCP_ENDPOINT="${SNOWFLAKE_ACCOUNT_URL}/api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/mcp-servers/TELCO_ASSURANCE_MCP"

echo "============================================"
echo "ServiceNow -> Snowflake MCP Integration Test"
echo "============================================"
echo ""

# ----------------------------------------------------------------------------
# Step 1: Get OAuth Token
# ----------------------------------------------------------------------------
echo "[Step 1] Acquiring OAuth Token..."

TOKEN_RESPONSE=$(curl -s -X POST "${SNOWFLAKE_ACCOUNT_URL}/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=${OAUTH_CLIENT_ID}" \
  -d "client_secret=${OAUTH_CLIENT_SECRET}" \
  -d "scope=session:role:TELCO_SN_INTEGRATION_RL")

ACCESS_TOKEN=$(echo $TOKEN_RESPONSE | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$ACCESS_TOKEN" ]; then
  echo "ERROR: Failed to get access token"
  echo "Response: $TOKEN_RESPONSE"
  exit 1
fi

echo "SUCCESS: Got access token (${#ACCESS_TOKEN} chars)"
echo ""

# ----------------------------------------------------------------------------
# Step 2: Test MCP tools/list
# ----------------------------------------------------------------------------
echo "[Step 2] Testing MCP tools/list..."

TOOLS_LIST_RESPONSE=$(curl -s -X POST "${MCP_ENDPOINT}" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/list",
    "params": {}
  }')

echo "Response:"
echo "$TOOLS_LIST_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$TOOLS_LIST_RESPONSE"
echo ""

# ----------------------------------------------------------------------------
# Step 3: Test SQL Execution - Network KPIs
# ----------------------------------------------------------------------------
echo "[Step 3] Testing SQL Execution - Get Barcelona KPIs..."

SQL_RESPONSE=$(curl -s -X POST "${MCP_ENDPOINT}" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "sql_exec_tool",
      "arguments": {
        "query": "SELECT region, kpi_name, AVG(kpi_value) as avg_value FROM NETWORK_KPI WHERE region = '\''BARCELONA'\'' GROUP BY region, kpi_name LIMIT 10"
      }
    }
  }')

echo "Response:"
echo "$SQL_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$SQL_RESPONSE"
echo ""

# ----------------------------------------------------------------------------
# Step 4: Test SQL Execution - Active Alarms
# ----------------------------------------------------------------------------
echo "[Step 4] Testing SQL Execution - Get Active Alarms..."

ALARMS_RESPONSE=$(curl -s -X POST "${MCP_ENDPOINT}" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "sql_exec_tool",
      "arguments": {
        "query": "SELECT region, severity, COUNT(*) as alarm_count FROM ALARMS GROUP BY region, severity ORDER BY alarm_count DESC LIMIT 10"
      }
    }
  }')

echo "Response:"
echo "$ALARMS_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$ALARMS_RESPONSE"
echo ""

# ----------------------------------------------------------------------------
# Step 5: Test SQL Execution - Open Incidents
# ----------------------------------------------------------------------------
echo "[Step 5] Testing SQL Execution - Get Open Incidents..."

INCIDENTS_RESPONSE=$(curl -s -X POST "${MCP_ENDPOINT}" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -d '{
    "jsonrpc": "2.0",
    "id": 4,
    "method": "tools/call",
    "params": {
      "name": "sql_exec_tool",
      "arguments": {
        "query": "SELECT number, region, state, short_description FROM INCIDENTS WHERE state = '\''OPEN'\'' LIMIT 10"
      }
    }
  }')

echo "Response:"
echo "$INCIDENTS_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$INCIDENTS_RESPONSE"
echo ""

echo "============================================"
echo "Integration Test Complete"
echo "============================================"
