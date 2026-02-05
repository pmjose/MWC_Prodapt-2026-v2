# ServiceNow → Snowflake MCP Integration Guide

This guide explains how ServiceNow can call the Snowflake-managed MCP server created in `snowflake/provisioning_setup.sql`
and how the demo datasets map to ServiceNow-style records.

## Prerequisites
- MCP server created in Snowflake (`CREATE MCP SERVER`).
- A role with access to the MCP server and underlying data.
- OAuth security integration configured for the MCP client (recommended).
- Optionally, a Programmatic Access Token (PAT) for a least-privilege role.

References:
- https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-mcp
- https://www.snowflake.com/en/developers/guides/getting-started-with-snowflake-mcp-server/

## 1) Snowflake setup summary
Ensure these items are in place:
- `TELCO_AI_DB.NETWORK_ASSURANCE` exists.
- MCP server `TELCO_ASSURANCE_MCP` exists and has the `sql_exec_tool`.
- Role `TELCO_SN_INTEGRATION_RL` has:
  - `USAGE` on database, schema, MCP server
  - `SELECT` on tables/views used by the tool

If you are provisioning from scratch, use `snowflake/provisioning_setup.sql` to create:
- Roles: `TELCO_ADMIN_RL`, `TELCO_MCP_RL`
- User: `TELCO_MCP_USER`
- Warehouse: `TELCO_ASSURANCE_WH`
- Database/Schema: `TELCO_AI_DB.NETWORK_ASSURANCE`
- MCP server: `TELCO_ASSURANCE_MCP`

For a dedicated ServiceNow integration role, use `TELCO_SN_INTEGRATION_RL`.

If you are loading demo data, upload CSVs from `snowflake/data/` and run `snowflake/data_load.sql`.

Recommended grants (example):
```sql
GRANT USAGE ON DATABASE TELCO_AI_DB TO ROLE TELCO_SN_INTEGRATION_RL;
GRANT USAGE ON SCHEMA TELCO_AI_DB.NETWORK_ASSURANCE TO ROLE TELCO_SN_INTEGRATION_RL;
GRANT SELECT ON ALL TABLES IN SCHEMA TELCO_AI_DB.NETWORK_ASSURANCE TO ROLE TELCO_SN_INTEGRATION_RL;
GRANT SELECT ON ALL VIEWS IN SCHEMA TELCO_AI_DB.NETWORK_ASSURANCE TO ROLE TELCO_SN_INTEGRATION_RL;
GRANT USAGE ON MCP SERVER TELCO_AI_DB.NETWORK_ASSURANCE.TELCO_ASSURANCE_MCP
  TO ROLE TELCO_SN_INTEGRATION_RL;
```

## 2) Create OAuth integration (Snowflake)
Create an OAuth security integration (client credentials or authorization code).
Use the integration to obtain a client id/secret:

```sql
CREATE OR REPLACE SECURITY INTEGRATION SNOW_MCP_OAUTH
  TYPE = OAUTH
  OAUTH_CLIENT = CUSTOM
  ENABLED = TRUE
  OAUTH_CLIENT_TYPE = 'CONFIDENTIAL'
  OAUTH_REDIRECT_URI = '<redirect_uri>';

SELECT SYSTEM$SHOW_OAUTH_CLIENT_SECRETS('SNOW_MCP_OAUTH');
```

Store the returned client id/secret in ServiceNow credentials (or in your MCP gateway).

## 3) Identify the MCP endpoint
Snowflake MCP endpoint format:

```
https://<account_url>/api/v2/databases/{database}/schemas/{schema}/mcp-servers/{name}
```

Example:
```
https://xy12345.us-east-1.snowflakecomputing.com/api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/mcp-servers/TELCO_ASSURANCE_MCP
```

## 4) Call from ServiceNow
You can call MCP directly from ServiceNow (RESTMessageV2/IntegrationHub) or through a small MCP client service.

### 4.1 Direct REST call (RESTMessageV2)
Use a POST to the MCP endpoint with JSON-RPC:

Request headers:
- `Authorization: Bearer <oauth_access_token>` (OAuth) or `Authorization: Bearer <pat_token>` (PAT)
- `Content-Type: application/json`

Body:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "SELECT * FROM RADIO_KPI_V WHERE region = 'BARCELONA' LIMIT 10"
    }
  }
}
```

Response (example):
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [
      { "type": "text", "text": "..." }
    ]
  }
}
```

### 4.2 Via MCP client service (recommended)
If ServiceNow cannot speak MCP directly, create a small gateway that forwards requests to MCP and returns a simplified response.

### 4.3 Optional: Discover available tools
Use `tools/list` to see tool names and schemas:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/list",
  "params": {}
}
```

## 5) Sample ServiceNow Scripted REST step (pseudo-code)
```javascript
var r = new sn_ws.RESTMessageV2();
r.setHttpMethod("POST");
r.setEndpoint("https://<account_url>/api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/mcp-servers/TELCO_ASSURANCE_MCP");
r.setRequestHeader("Authorization", "Bearer " + accessToken);
r.setRequestHeader("Content-Type", "application/json");
r.setRequestBody(JSON.stringify({
  jsonrpc: "2.0",
  id: 1,
  method: "tools/call",
  params: {
    name: "sql_exec_tool",
    arguments: { sql: "SELECT * FROM RADIO_KPI_V WHERE region = 'NORTH' LIMIT 10" }
  }
}));
var response = r.execute();
var body = response.getBody();
```

## 6) ServiceNow workflow example
1. Assurance Agent detects degraded KPI.
2. Scripted step calls MCP `sql_exec_tool` to fetch historical KPIs and alarms.
3. ServiceNow correlates results with live incidents.
4. ServiceNow triggers RCA/remediation workflow.

## 7) ServiceNow data alignment
- `INCIDENTS` and `TROUBLE_TICKETS` use ServiceNow-style fields (`number`, `state`, `priority`,
  `assignment_group`, `sys_id`, `sys_created_on`, `sys_updated_on`,
  `sys_created_by`, `sys_updated_by`, `sys_domain`).
- `ALARMS.incident_number` links alarms to incidents for correlation.
- CMDB alignment is provided in `CMDB_CI` and `CMDB_RELATIONSHIPS`.
- Correlation rules are in `EVENT_CORRELATION_RULES`.
 - Example ServiceNow XML exports are in `servicenow/xml_exports/`.

## 8) Notes and limits
- Snowflake MCP server supports tool calls only and non-streaming responses.
- Ensure the MCP server hostname uses hyphens, not underscores.
- Use least-privilege roles for OAuth tokens or PATs.

