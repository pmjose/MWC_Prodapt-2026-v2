# ServiceNow to Snowflake MCP Integration Guide

## Overview

This document provides all the information required for ServiceNow IntegrationHub to connect to the Snowflake MCP (Model Context Protocol) Server for the Telecom Network Assurance solution.

---

## 1. Authentication

### Method: Key-Pair (JWT)

| Parameter | Value |
|-----------|-------|
| **Snowflake Account** | `<YOUR_SNOWFLAKE_ACCOUNT>` |
| **Service User** | `SERVICENOW_SVC_USER` |
| **Role** | `TELCO_SN_INTEGRATION_RL` |
| **Warehouse** | `TELCO_ASSURANCE_WH` |
| **Key Fingerprint** | `<YOUR_KEY_FINGERPRINT>` |

### Private Key

The private key file (`servicenow_rsa_key.p8`) must be stored securely in ServiceNow Credentials.

**Location:** Provided separately via secure channel.

---

## 2. API Endpoint

### MCP Server URL

```
POST https://<ACCOUNT_LOCATOR>.<REGION>.aws.snowflakecomputing.com/api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/mcp-servers/TELCO_ASSURANCE_MCP
```

---

## 3. HTTP Headers

All requests must include the following headers:

```http
Content-Type: application/json
Authorization: Bearer <JWT_TOKEN>
X-Snowflake-Authorization-Token-Type: KEYPAIR_JWT
```

---

## 4. JWT Token Generation

### Token Structure

```json
{
    "iss": "<YOUR_SNOWFLAKE_ACCOUNT>.SERVICENOW_SVC_USER.<YOUR_KEY_FINGERPRINT>",
    "sub": "<YOUR_SNOWFLAKE_ACCOUNT>.SERVICENOW_SVC_USER",
    "iat": <current_unix_timestamp>,
    "exp": <current_unix_timestamp + 3600>
}
```

### Token Parameters

| Field | Description |
|-------|-------------|
| `iss` | Issuer: `<ACCOUNT>.<USER>.<KEY_FINGERPRINT>` |
| `sub` | Subject: `<ACCOUNT>.<USER>` |
| `iat` | Issued At: Current Unix timestamp |
| `exp` | Expiration: Unix timestamp (max 60 minutes from iat) |

### Algorithm

- **Signing Algorithm:** RS256
- **Key Type:** RSA 2048-bit

### JavaScript Example (ServiceNow)

```javascript
var jwt = new sn_auth.GlideJWT();
jwt.setSigningKey(privateKey);
jwt.setAlgorithm('RS256');

var payload = {
    iss: '<YOUR_SNOWFLAKE_ACCOUNT>.SERVICENOW_SVC_USER.<YOUR_KEY_FINGERPRINT>',
    sub: '<YOUR_SNOWFLAKE_ACCOUNT>.SERVICENOW_SVC_USER',
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 3600
};

var token = jwt.encode(payload);
```

---

## 5. MCP Protocol

### JSON-RPC 2.0 Format

All MCP requests use JSON-RPC 2.0 protocol.

### Discover Available Tools

**Request:**
```json
{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/list",
    "params": {}
}
```

**Response:**
```json
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "tools": [
            {
                "name": "sql_exec_tool",
                "description": "Execute SQL queries on telecom assurance views for network KPIs, alarms, incidents, and anomaly detection.",
                "title": "SQL Execution Tool",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "sql": {
                            "description": "Single SQL query to execute.",
                            "type": "string"
                        }
                    }
                }
            }
        ]
    }
}
```

### Execute SQL Query

**Request:**
```json
{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
        "name": "sql_exec_tool",
        "arguments": {
            "sql": "SELECT region, severity, COUNT(*) as count FROM TELCO_AI_DB.NETWORK_ASSURANCE.ALARMS GROUP BY region, severity"
        }
    }
}
```

**Response:**
```json
{
    "jsonrpc": "2.0",
    "id": 2,
    "result": {
        "content": [
            {
                "type": "text",
                "text": "{\"query_id\":\"...\",\"result_set\":{\"data\":[[\"BARCELONA\",\"MINOR\",\"90\"],[\"BARCELONA\",\"MAJOR\",\"56\"]]}}"
            }
        ],
        "isError": false
    }
}
```

---

## 6. Available Data

### Database Schema

- **Database:** `TELCO_AI_DB`
- **Schema:** `NETWORK_ASSURANCE`

### Tables

| Table | Description | Row Count |
|-------|-------------|-----------|
| `NETWORK_KPI` | Network performance metrics (PRB utilization, RSRP, throughput, etc.) | 2,016,903 |
| `ALARMS` | Active network alarms with severity levels | 148 |
| `TOPOLOGY` | Network element topology and relationships | 375 |
| `INCIDENTS` | ServiceNow incident records | 18 |
| `SITE_GEO` | Site geographic coordinates | 72 |
| `SERVICE_FOOTPRINTS` | Service subscriber mappings | 300 |
| `CHANGE_EVENTS` | Network change events | 7 |
| `TROUBLE_TICKETS` | Trouble ticket records | 100 |
| `SLA_BREACHES` | SLA violation records with penalties | 12 |
| `ANOMALY_SCORES` | ML-based anomaly detection scores | 126 |
| `CMDB_CI` | Configuration items from CMDB | 363 |
| `CMDB_RELATIONSHIPS` | CI relationships | 360 |
| `EVENT_CORRELATION_RULES` | Event correlation rule definitions | 4 |

### Views

| View | Description |
|------|-------------|
| `RADIO_KPI_V` | Radio network KPIs (PRB_UTIL, RSRP, RSRQ, SINR) |
| `CORE_KPI_V` | Core network KPIs (CPU, Memory, Session failures) |
| `TRANSPORT_KPI_V` | Transport KPIs (Latency, Packet loss) |
| `CUSTOMER_IMPACT_V` | Incidents with impacted network elements |
| `ANOMALY_SCORES_V` | Anomaly detection results |

---

## 7. Sample Queries

### Get Alarms by Severity

```sql
SELECT region, severity, COUNT(*) as alarm_count 
FROM TELCO_AI_DB.NETWORK_ASSURANCE.ALARMS 
GROUP BY region, severity 
ORDER BY alarm_count DESC
```

### Get Network KPIs for Barcelona

```sql
SELECT kpi_name, 
       ROUND(AVG(kpi_value), 2) as avg_value,
       MIN(kpi_value) as min_value,
       MAX(kpi_value) as max_value
FROM TELCO_AI_DB.NETWORK_ASSURANCE.NETWORK_KPI 
WHERE region = 'BARCELONA' 
GROUP BY kpi_name
```

### Get SLA Breaches with Penalties

```sql
SELECT service_id, region, metric, 
       threshold, observed, penalty_eur
FROM TELCO_AI_DB.NETWORK_ASSURANCE.SLA_BREACHES 
ORDER BY penalty_eur DESC
```

### Get High-Score Anomalies

```sql
SELECT ts, region, element_id, kpi_name, score, label
FROM TELCO_AI_DB.NETWORK_ASSURANCE.ANOMALY_SCORES 
WHERE score > 0.8 
ORDER BY score DESC
LIMIT 20
```

### Get Open Incidents with Impact

```sql
SELECT number, region, priority, state, 
       short_description, impacted_elements
FROM TELCO_AI_DB.NETWORK_ASSURANCE.INCIDENTS 
WHERE state IN ('OPEN', 'In Progress')
ORDER BY priority
```

### Correlate Alarms with Topology

```sql
SELECT a.ts, a.region, a.cell_id, a.severity, a.description,
       t.element_type, t.parent_id, t.service_id
FROM TELCO_AI_DB.NETWORK_ASSURANCE.ALARMS a
JOIN TELCO_AI_DB.NETWORK_ASSURANCE.TOPOLOGY t 
  ON a.cell_id = t.element_id
WHERE a.severity IN ('MAJOR', 'CRITICAL')
ORDER BY a.ts DESC
```

---

## 8. Error Handling

### Common Error Codes

| Code | Description | Resolution |
|------|-------------|------------|
| `390144` | JWT token is invalid | Regenerate token with correct fingerprint |
| `002003` | Object does not exist or not authorized | Use fully qualified table names |
| `422` | SQL compilation error | Check SQL syntax |
| `401` | Unauthorized | Verify JWT token and headers |

### Error Response Format

```json
{
    "jsonrpc": "2.0",
    "id": 2,
    "result": {
        "content": [
            {
                "type": "text",
                "text": "MCP error calling tool sql_exec_tool: <error_message>"
            }
        ],
        "isError": true
    }
}
```

---

## 9. Rate Limits & Best Practices

### Recommendations

1. **Use fully qualified table names:** `TELCO_AI_DB.NETWORK_ASSURANCE.<TABLE>`
2. **Limit result sets:** Always use `LIMIT` clause for large tables
3. **Cache JWT tokens:** Tokens are valid for 60 minutes
4. **Handle pagination:** Large result sets may be paginated
5. **Use appropriate timeouts:** Network KPI queries may take longer

### Query Timeout

Default query timeout is 60 seconds. For large aggregations, consider:
- Adding `WHERE` clauses to filter data
- Using pre-aggregated views
- Limiting time ranges

---

## 10. Security Notes

1. **Private Key:** Store securely in ServiceNow Credentials vault
2. **Network Policy:** Requests are restricted to ServiceNow datacenter IPs
3. **Role-Based Access:** Service user has SELECT-only access
4. **Audit Logging:** All queries are logged in Snowflake

---

## 11. Support Contacts

| Role | Contact |
|------|---------|
| **Snowflake Admin** | [Your contact info] |
| **Integration Support** | [Your team contact] |

---

## 12. Appendix: cURL Test Example

```bash
# Generate JWT token (requires Python script or JWT library)
# Then test with:

curl -X POST "https://<ACCOUNT_LOCATOR>.<REGION>.aws.snowflakecomputing.com/api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/mcp-servers/TELCO_ASSURANCE_MCP" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -H "X-Snowflake-Authorization-Token-Type: KEYPAIR_JWT" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
```

---

*Document Version: 1.0*  
*Last Updated: February 2026*
