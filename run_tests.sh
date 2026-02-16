#!/bin/bash
TOKEN="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJSQTE5MTk5LkEyQV9TVkNfVVNFUi5TSEEyNTY6dmFFaDE4T0FhTC91RGo2cm9qRkROMW9HU2dKT2luak5VWHE3Z24vZ0hmOD0iLCJzdWIiOiJSQTE5MTk5LkEyQV9TVkNfVVNFUiIsImlhdCI6MTc3MTE5MTMwMywiZXhwIjoxNzcxNDUwNTAzfQ.drEsglJ0pUcKVbpJZRge6_JgBhPlauu6UnZL1kmnyhQYrkL6Ohbofuva-nUvowFOcwqnwAi09jEjdbSKQINnW5E7mCCh9-L5JUwBkCFop8HuUogHkxQYwXZn7HPLtkJjPLlmxeKxuJG507gk30h99cA0XrQapTuAE_hwl_aNS4TJja6maOda0gy4q2j0Ch3K0_1VeMCEkeIysvkCp8DZ7kXihWPl-aMxe8YYDmgmbby6PMOwtTknVZxpMCtSXSyR1Wmyh-0Q1erCgMNv3Au3eDf9YQe2a2oKRTTtHao0QFkbdESa7RYjbkumY36hNv_ZM6SlwPKjP5a3eIkCsZIjJg"
MCP_URL="https://ra19199.eu-west-3.aws.snowflakecomputing.com/api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/mcp-servers/TELCO_ASSURANCE_MCP"
AGENT_URL="https://ra19199.eu-west-3.aws.snowflakecomputing.com/api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/agents/TELCO_ASSURANCE_AGENT:run"

echo "TEST1_RESULT:"
curl -s -m 30 -X POST "$MCP_URL" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Snowflake-Authorization-Token-Type: KEYPAIR_JWT" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
echo ""
echo "TEST1_END"

echo "TEST2_RESULT:"
curl -s -m 30 -X POST "$MCP_URL" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Snowflake-Authorization-Token-Type: KEYPAIR_JWT" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"sql_exec_tool","arguments":{"sql":"SELECT COUNT(*) AS total FROM TELCO_AI_DB.NETWORK_ASSURANCE.ALARMS"}}}'
echo ""
echo "TEST2_END"

echo "TEST3_RESULT:"
curl -s -m 30 -X POST "$MCP_URL" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Snowflake-Authorization-Token-Type: KEYPAIR_JWT" \
  -d '{"jsonrpc":"2.0","id":0,"method":"initialize","params":{"protocolVersion":"2024-11-05","clientInfo":{"name":"test-client","version":"1.0"}}}'
echo ""
echo "TEST3_END"
