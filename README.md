# Agentic Assurance Demo (ServiceNow + Snowflake MCP)

This repo contains a telecom assurance demo for an agentic workflow: ServiceNow Assurance Agent orchestrates live events and remediation, while a Snowflake Insight/Anomaly Agent analyzes historical telemetry and returns predictions via the Snowflake-managed MCP server.

## Architecture Overview

```
┌─────────────────────┐     JSON-RPC/HTTPS      ┌─────────────────────────┐
│     ServiceNow      │ ───────────────────────►│   Snowflake MCP Server  │
│   Assurance Agent   │◄─────────────────────── │  (TELCO_ASSURANCE_MCP)  │
│                     │    Prediction Response  │                         │
│  - Event Detection  │                         │  - Historical Analysis  │
│  - RCA Workflows    │                         │  - Anomaly Detection    │
│  - Remediation      │                         │  - KPI Queries          │
└─────────────────────┘                         └─────────────────────────┘
         │                                                  │
         │  Key-Pair (JWT)                                  │
         │  Authentication                                  │
         ▼                                                  ▼
┌─────────────────────┐                         ┌─────────────────────────┐
│  ServiceNow CMDB    │                         │   Snowflake Tables      │
│  Incidents/Tickets  │                         │   2M+ KPI Records       │
└─────────────────────┘                         └─────────────────────────┘
```

## Contents

| Path | Description |
|------|-------------|
| `snowflake/01_provisioning_setup.sql` | Roles, users, OAuth, network policy, MCP server, resource monitor |
| `snowflake/02_demo_setup.sql` | Schema, tables, views |
| `snowflake/03_data_load.sql` | Load CSV data from GitHub into Snowflake |
| `snowflake/data/` | CSVs with synthetic Tier-1 telco telemetry (Feb 22-28, 2026) |
| `servicenow/` | IntegrationHub action, prompts, dashboards, correlation rules, playbooks |
| `docs/SERVICENOW_INTEGRATION_GUIDE.md` | Complete ServiceNow handoff guide |
| `test/` | Integration test scripts |
| `keys/` | RSA key pair for authentication (not committed - generate locally) |

---

## Complete Setup Guide

### Prerequisites

- Snowflake account with ACCOUNTADMIN privileges
- Python 3.x (for testing)
- OpenSSL (for key generation)

---

## Step 1: Run Snowflake Scripts

Run these scripts in order using Snowsight or SnowSQL as ACCOUNTADMIN:

```sql
-- 1. Provisioning (roles, users, OAuth, MCP server)
-- Execute: snowflake/01_provisioning_setup.sql

-- 2. Demo setup (tables, views)
-- Execute: snowflake/02_demo_setup.sql

-- 3. Data load (loads CSVs directly from GitHub)
-- Execute: snowflake/03_data_load.sql
```

### What Gets Created

| Component | Name |
|-----------|------|
| Database | `TELCO_AI_DB` |
| Schema | `NETWORK_ASSURANCE` |
| Warehouse | `TELCO_ASSURANCE_WH` |
| MCP Server | `TELCO_ASSURANCE_MCP` |
| Service User | `SERVICENOW_SVC_USER` |
| Integration Role | `TELCO_SN_INTEGRATION_RL` |
| Tables | 13 tables (2M+ rows) |
| Views | 15 views |

---

## Step 2: Generate RSA Key Pair

Generate keys for ServiceNow authentication:

```bash
# Create keys directory
mkdir -p keys

# Generate private key (PKCS8 format)
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out keys/servicenow_rsa_key.p8 -nocrypt

# Extract public key
openssl rsa -in keys/servicenow_rsa_key.p8 -pubout -out keys/servicenow_rsa_key.pub

# Display public key (you'll need this for Snowflake)
cat keys/servicenow_rsa_key.pub
```

---

## Step 3: Assign Public Key to Service User

In Snowflake, run:

```sql
-- Copy the public key content (without BEGIN/END headers)
ALTER USER SERVICENOW_SVC_USER SET RSA_PUBLIC_KEY='MIIBIjAN...your_key_here...AQAB';

-- Verify the fingerprint
DESC USER SERVICENOW_SVC_USER;
-- Look for RSA_PUBLIC_KEY_FP value (e.g., SHA256:xxxxx)
```

---

## Step 4: Grant Permissions

```sql
-- Grant SELECT on all tables to integration role
GRANT SELECT ON ALL TABLES IN SCHEMA TELCO_AI_DB.NETWORK_ASSURANCE TO ROLE TELCO_SN_INTEGRATION_RL;
GRANT SELECT ON ALL VIEWS IN SCHEMA TELCO_AI_DB.NETWORK_ASSURANCE TO ROLE TELCO_SN_INTEGRATION_RL;
```

---

## Step 5: Test the Integration

### Install Python dependencies

```bash
pip install PyJWT cryptography requests
```

### Run the test script

```bash
cd /path/to/project
python test/test_keypair_auth.py
```

### Expected output

```
[TEST] MCP tools/list
Status: 200
{"jsonrpc": "2.0", "id": 1, "result": {"tools": [{"name": "sql_exec_tool"...}]}}

[TEST] Barcelona Alarms
Status: 200
{"jsonrpc": "2.0", "id": 2, "result": {"content": [{"type": "text", "text": "...MINOR: 90, MAJOR: 56..."}]}}
```

---

## Step 6: Validate Data Load

```sql
-- Check row counts
SELECT 'NETWORK_KPI' AS table_name, COUNT(*) AS row_count FROM TELCO_AI_DB.NETWORK_ASSURANCE.NETWORK_KPI
UNION ALL SELECT 'ALARMS', COUNT(*) FROM TELCO_AI_DB.NETWORK_ASSURANCE.ALARMS
UNION ALL SELECT 'TOPOLOGY', COUNT(*) FROM TELCO_AI_DB.NETWORK_ASSURANCE.TOPOLOGY
UNION ALL SELECT 'INCIDENTS', COUNT(*) FROM TELCO_AI_DB.NETWORK_ASSURANCE.INCIDENTS
UNION ALL SELECT 'CMDB_CI', COUNT(*) FROM TELCO_AI_DB.NETWORK_ASSURANCE.CMDB_CI
ORDER BY row_count DESC;
```

### Expected counts

| Table | Rows |
|-------|------|
| NETWORK_KPI | 2,016,903 |
| TOPOLOGY | 375 |
| CMDB_CI | 363 |
| CMDB_RELATIONSHIPS | 360 |
| SERVICE_FOOTPRINTS | 300 |
| ALARMS | 148 |
| ANOMALY_SCORES | 126 |
| TROUBLE_TICKETS | 100 |
| SITE_GEO | 72 |
| INCIDENTS | 18 |
| SLA_BREACHES | 12 |
| CHANGE_EVENTS | 7 |
| EVENT_CORRELATION_RULES | 4 |

---

## ServiceNow Integration

### Configuration for ServiceNow Team

Provide the ServiceNow team with:

1. **`docs/SERVICENOW_INTEGRATION_GUIDE.md`** - Complete integration guide
2. **`keys/servicenow_rsa_key.p8`** - Private key (send via secure channel)

### Key Parameters

| Parameter | Value |
|-----------|-------|
| **Account** | `SFSEEUROPE-PJOSE_AWS3` (or your account) |
| **User** | `SERVICENOW_SVC_USER` |
| **Authentication** | Key-Pair (JWT) with RS256 |
| **MCP Endpoint** | `https://<account_locator>.<region>.aws.snowflakecomputing.com/api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/mcp-servers/TELCO_ASSURANCE_MCP` |

### HTTP Headers Required

```
Content-Type: application/json
Authorization: Bearer <JWT_TOKEN>
X-Snowflake-Authorization-Token-Type: KEYPAIR_JWT
```

### JWT Token Structure

```json
{
    "iss": "<ACCOUNT>.<USER>.<KEY_FINGERPRINT>",
    "sub": "<ACCOUNT>.<USER>",
    "iat": <current_unix_timestamp>,
    "exp": <expiration_timestamp>
}
```

### MCP Request Examples

**List available tools:**
```json
{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/list",
    "params": {}
}
```

**Execute SQL query:**
```json
{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
        "name": "sql_exec_tool",
        "arguments": {
            "sql": "SELECT region, severity, COUNT(*) FROM TELCO_AI_DB.NETWORK_ASSURANCE.ALARMS GROUP BY region, severity"
        }
    }
}
```

---

## Sample Queries for ServiceNow

```sql
-- Get alarms by severity
SELECT region, severity, COUNT(*) as count 
FROM TELCO_AI_DB.NETWORK_ASSURANCE.ALARMS 
GROUP BY region, severity;

-- Get KPIs for Barcelona
SELECT kpi_name, ROUND(AVG(kpi_value), 2) as avg_value 
FROM TELCO_AI_DB.NETWORK_ASSURANCE.NETWORK_KPI 
WHERE region = 'BARCELONA' 
GROUP BY kpi_name;

-- Get high anomaly scores
SELECT element_id, kpi_name, score 
FROM TELCO_AI_DB.NETWORK_ASSURANCE.ANOMALY_SCORES 
WHERE score > 0.8 
ORDER BY score DESC;

-- Get SLA breaches
SELECT service_id, metric, penalty_eur 
FROM TELCO_AI_DB.NETWORK_ASSURANCE.SLA_BREACHES 
ORDER BY penalty_eur DESC;
```

---

## Data Model

### Tables

| Table | Description |
|-------|-------------|
| `NETWORK_KPI` | Network performance metrics (PRB_UTIL, RSRP, throughput, etc.) |
| `ALARMS` | Active network alarms with severity levels |
| `TOPOLOGY` | Network element hierarchy |
| `INCIDENTS` | ServiceNow-style incident records |
| `SITE_GEO` | Site geographic coordinates |
| `SERVICE_FOOTPRINTS` | Service-to-subscriber mappings |
| `CHANGE_EVENTS` | Planned network changes |
| `TROUBLE_TICKETS` | NOC operational tickets |
| `SLA_BREACHES` | SLA violations with penalties |
| `ANOMALY_SCORES` | ML anomaly detection outputs |
| `CMDB_CI` | Configuration items |
| `CMDB_RELATIONSHIPS` | CI relationships |
| `EVENT_CORRELATION_RULES` | Alarm correlation rules |

### Views

| View | Description |
|------|-------------|
| `RADIO_KPI_V` | Radio KPIs (PRB_UTIL, RSRP, RSRQ, SINR) |
| `CORE_KPI_V` | Core node KPIs (CPU, Memory, Session failures) |
| `TRANSPORT_KPI_V` | Transport KPIs (Latency, Packet loss) |
| `CUSTOMER_IMPACT_V` | Incidents with impacted elements |
| `ANOMALY_SCORES_V` | Anomaly detection results |

---

## Security

| Component | Purpose |
|-----------|---------|
| `TELCO_SN_INTEGRATION_RL` | Least-privilege role (SELECT only) |
| `SERVICENOW_SVC_USER` | Service account with key-pair auth |
| `SERVICENOW_NETWORK_POLICY` | IP allowlist for ServiceNow |
| `TELCO_ASSURANCE_MONITOR` | Resource monitor (100 credit quota) |

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `390144: JWT token is invalid` | Check account name format in JWT issuer |
| `002003: Object does not exist` | Use fully qualified table names |
| `401 Unauthorized` | Verify key fingerprint matches |
| `Network policy violation` | Add ServiceNow IPs to allowlist |
| `Timeout` | Add LIMIT clause, check warehouse size |

---

## File Security

The `.gitignore` excludes sensitive files:
- `keys/` - RSA key pairs
- `*.p8`, `*.pem`, `*.key` - Private keys
- `.env` - Environment variables

**Never commit private keys to git.**

---

## References

- [Snowflake MCP Server Docs](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-mcp)
- [Snowflake Key-Pair Authentication](https://docs.snowflake.com/en/user-guide/key-pair-auth)
- [ServiceNow IntegrationHub](https://docs.servicenow.com/bundle/utah-integrate-applications/page/administer/integrationhub/concept/integrationhub.html)

---

## License

ISC
