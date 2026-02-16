# Snowflake Telco Assurance - Integration Test Report

**Test Date**: February 15, 2026  
**Tested By**: Automated Test Suite  
**Environment**: Production (RA19199.eu-west-3.aws)

---

## Summary

| Category | Tests | Passed | Failed |
|----------|-------|--------|--------|
| MCP Server | 3 | 3 | 0 |
| Cortex Agent | 2 | 2 | 0 |
| **Total** | **5** | **5** | **0** |

**Overall Status**: ✅ **ALL TESTS PASSED**

---

## Test Details

### Test 1: MCP - List Tools ✅

**Endpoint**: `POST /api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/mcp-servers/TELCO_ASSURANCE_MCP`

**Request**:
```json
{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}
```

**Response**:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "tools": [{
      "name": "sql_exec_tool",
      "description": "Execute SQL queries on telecom assurance views for network KPIs, alarms, incidents, and anomaly detection.",
      "title": "SQL Execution Tool",
      "inputSchema": {
        "type": "object",
        "description": "Tool to execute a SQL query.",
        "properties": {
          "sql": {
            "description": "Single SQL query to execute.",
            "type": "string"
          }
        }
      }
    }]
  }
}
```

**Result**: Tool `sql_exec_tool` discovered successfully

---

### Test 2: MCP - Execute SQL Query ✅

**Endpoint**: `POST /api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/mcp-servers/TELCO_ASSURANCE_MCP`

**Request**:
```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "SELECT COUNT(*) AS total FROM TELCO_AI_DB.NETWORK_ASSURANCE.ALARMS"
    }
  }
}
```

**Response**:
```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "content": [{
      "type": "text",
      "text": "{\"query_id\":\"01c26ff5-0001-93ad-0001-39260130c7ee\",\"result_set\":{\"data\":[[\"148\"]]}}"
    }],
    "isError": false
  }
}
```

**Result**: Query executed successfully, returned **148 alarms**

---

### Test 3: MCP - Initialize (Handshake) ✅

**Endpoint**: `POST /api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/mcp-servers/TELCO_ASSURANCE_MCP`

**Request**:
```json
{
  "jsonrpc": "2.0",
  "id": 0,
  "method": "initialize",
  "params": {
    "protocolVersion": "2024-11-05",
    "clientInfo": {"name": "test-client", "version": "1.0"}
  }
}
```

**Response**:
```json
{
  "jsonrpc": "2.0",
  "id": 0,
  "result": {
    "protocolVersion": "2024-11-05",
    "capabilities": {
      "tools": {"listChanged": false}
    },
    "serverInfo": {
      "name": "TELCO_ASSURANCE_MCP",
      "title": "Snowflake Server: TELCO_ASSURANCE_MCP",
      "version": "1.0.0"
    }
  }
}
```

**Result**: MCP protocol handshake successful

---

### Test 4: Cortex Agent - Simple Question ✅

**Endpoint**: `POST /api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/agents/TELCO_ASSURANCE_AGENT:run`

**Request**:
```json
{
  "messages": [{
    "role": "user",
    "content": [{"type": "text", "text": "How many alarms are there?"}]
  }]
}
```

**Response**: Streaming SSE response with:
- Planning phase completed
- TelcoAnalyst tool invoked
- SQL generated via Cortex Analyst
- Query executed successfully

**Result**: Agent processed natural language query and returned alarm count

---

### Test 5: Cortex Agent - Complex Query ✅

**Endpoint**: `POST /api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/agents/TELCO_ASSURANCE_AGENT:run`

**Request**:
```json
{
  "messages": [{
    "role": "user",
    "content": [{"type": "text", "text": "Show critical alarms by region"}]
  }]
}
```

**Result**: Agent processed complex analytical query with grouping

---

## Configuration Verified

| Component | Status |
|-----------|--------|
| MCP Server | ✅ Online |
| Cortex Agent | ✅ Online |
| Semantic View | ✅ Accessible |
| JWT Authentication | ✅ Working |
| Network Policy | ✅ Open (all IPs) |

---

## Endpoints

| Service | URL |
|---------|-----|
| MCP Server | `https://ra19199.eu-west-3.aws.snowflakecomputing.com/api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/mcp-servers/TELCO_ASSURANCE_MCP` |
| Cortex Agent | `https://ra19199.eu-west-3.aws.snowflakecomputing.com/api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/agents/TELCO_ASSURANCE_AGENT:run` |

---

## Authentication

- **Method**: JWT Key-Pair (RS256)
- **User**: `A2A_SVC_USER`
- **Role**: `TELCO_A2A_RL`
- **Network Policy**: `A2A_OPEN_POLICY` (allows all IPs)

---

## Data Availability

| Table | Records |
|-------|---------|
| NETWORK_KPI | 2,016,903 |
| TOPOLOGY | 375 |
| ALARMS | 148 |
| ANOMALY_SCORES | 126 |
| INCIDENTS | 18 |
| SLA_BREACHES | 12 |

---

## Notes

1. All tests executed from local environment
2. External access verified from separate laptop (IP: 89.115.93.199)
3. Token valid until: **Feb 18, 2026 21:35 UTC**
