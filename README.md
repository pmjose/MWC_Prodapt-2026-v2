# Agentic Assurance Demo (ServiceNow + Snowflake MCP + A2A)

This repo contains a telecom assurance demo for agentic workflows:
- **ServiceNow Assurance Agent** orchestrates live events and remediation via Snowflake MCP
- **A2A Protocol** exposes the Snowflake Cortex Agent for multi-agent interoperability

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              SNOWFLAKE                                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                    TELCO_AI_DB.NETWORK_ASSURANCE                        │   │
│  │                                                                         │   │
│  │   ┌─────────────────────┐        ┌─────────────────────────────┐       │   │
│  │   │  MCP SERVER         │        │  CORTEX AGENT               │       │   │
│  │   │  TELCO_ASSURANCE_MCP│        │  TELCO_ASSURANCE_AGENT      │       │   │
│  │   ├─────────────────────┤        ├─────────────────────────────┤       │   │
│  │   │ • sql_exec_tool     │        │ • claude-3-5-sonnet LLM     │       │   │
│  │   │ • Raw SQL execution │        │ • AI-powered responses      │       │   │
│  │   │ • JSON-RPC protocol │        │ • Natural language queries  │       │   │
│  │   └─────────────────────┘        └─────────────────────────────┘       │   │
│  │              │                               │                          │   │
│  │              └───────────┬───────────────────┘                          │   │
│  │                          ▼                                              │   │
│  │                   ┌─────────────┐                                       │   │
│  │                   │   VIEWS     │  2M+ KPI Records                      │   │
│  │                   │ RADIO_KPI_V │  13 Tables, 15 Views                  │   │
│  │                   │ INCIDENTS_V │                                       │   │
│  │                   └─────────────┘                                       │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
          ▲                                              ▲
          │ JSON-RPC/HTTPS                               │ REST API
          │ Key-Pair JWT Auth                            │ Key-Pair JWT Auth
          │                                              │
┌─────────────────────┐                      ┌─────────────────────┐
│     ServiceNow      │                      │    A2A Wrapper      │
│   Assurance Agent   │                      │   (Python Server)   │
│                     │                      │                     │
│  - Event Detection  │                      │  - Agent Discovery  │
│  - RCA Workflows    │                      │  - Multi-Agent      │
│  - Remediation      │                      │    Interoperability │
└─────────────────────┘                      └─────────────────────┘
          │                                              ▲
          ▼                                              │
┌─────────────────────┐                      ┌─────────────────────┐
│  ServiceNow CMDB    │                      │   Other AI Agents   │
│  Incidents/Tickets  │                      │   (A2A Clients)     │
└─────────────────────┘                      └─────────────────────┘
```

## Two Integration Paths

| Feature | **MCP (ServiceNow)** | **A2A (Multi-Agent)** |
|---------|---------------------|----------------------|
| Protocol | JSON-RPC 2.0 | Google A2A Protocol |
| Snowflake Object | MCP Server | Cortex Agent |
| Response Type | Raw SQL results | AI-generated text |
| Use Case | Direct SQL queries | Natural language Q&A |
| Client | ServiceNow MCP Client | Any A2A-compatible agent |

## Contents

| Path | Description |
|------|-------------|
| `snowflake/01_provisioning_setup.sql` | Roles, users, OAuth, MCP server, Cortex Agent, resource monitor |
| `snowflake/02_demo_setup.sql` | Schema, tables, views |
| `snowflake/03_data_load.sql` | Load CSV data from GitHub into Snowflake |
| `snowflake/data/` | CSVs with synthetic Tier-1 telco telemetry (Feb 22-28, 2026) |
| `a2a/` | A2A Protocol wrapper for Cortex Agent |
| `servicenow/` | IntegrationHub action, prompts, dashboards, correlation rules |
| `docs/SERVICENOW_INTEGRATION_GUIDE.md` | Complete ServiceNow handoff guide |
| `test/` | Integration test scripts |
| `keys/` | RSA key pairs for authentication (not committed) |

---

## Quick Start

### Prerequisites

- Snowflake account with ACCOUNTADMIN privileges
- Python 3.11+ (for A2A wrapper and testing)
- OpenSSL (for key generation)

---

## Step 1: Run Snowflake Scripts

Run in order using Snowsight or SnowSQL as ACCOUNTADMIN:

```sql
-- 1. Provisioning (roles, users, OAuth, MCP server, Cortex Agent)
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
| Cortex Agent | `TELCO_ASSURANCE_AGENT` |
| ServiceNow User | `SERVICENOW_SVC_USER` |
| A2A User | `A2A_SVC_USER` |
| Tables | 13 tables (2M+ rows) |
| Views | 15 views |

---

## Step 2: Generate RSA Key Pairs

### For ServiceNow (MCP)

```bash
mkdir -p keys
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out keys/servicenow_rsa_key.p8 -nocrypt
openssl rsa -in keys/servicenow_rsa_key.p8 -pubout -out keys/servicenow_rsa_key.pub
```

### For A2A Wrapper

```bash
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out keys/a2a_rsa_key.p8 -nocrypt
openssl rsa -in keys/a2a_rsa_key.p8 -pubout -out keys/a2a_rsa_key.pub
```

---

## Step 3: Assign Public Keys to Users

```sql
-- ServiceNow user
ALTER USER SERVICENOW_SVC_USER SET RSA_PUBLIC_KEY='<content of servicenow_rsa_key.pub>';

-- A2A user
ALTER USER A2A_SVC_USER SET RSA_PUBLIC_KEY='<content of a2a_rsa_key.pub>';

-- Verify fingerprints
DESC USER SERVICENOW_SVC_USER;
DESC USER A2A_SVC_USER;
```

---

## ServiceNow MCP Integration

### Connection Details

| Parameter | Value |
|-----------|-------|
| **Endpoint** | `https://<locator>.<region>.snowflakecomputing.com/api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/mcp-servers/TELCO_ASSURANCE_MCP` |
| **User** | `SERVICENOW_SVC_USER` |
| **Authentication** | Key-Pair JWT (RS256) |

### HTTP Headers

```
Content-Type: application/json
Authorization: Bearer <JWT_TOKEN>
X-Snowflake-Authorization-Token-Type: KEYPAIR_JWT
```

### Request Examples

**List tools:**
```json
{"jsonrpc": "2.0", "id": 1, "method": "tools/list", "params": {}}
```

**Execute SQL:**
```json
{
  "jsonrpc": "2.0", "id": 2, "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {"sql": "SELECT * FROM TELCO_AI_DB.NETWORK_ASSURANCE.RADIO_KPI_V LIMIT 10"}
  }
}
```

**Important:** Always use fully qualified table names (`TELCO_AI_DB.NETWORK_ASSURANCE.<table>`).

---

## A2A Protocol Integration

The A2A wrapper exposes the Snowflake Cortex Agent via Google's Agent-to-Agent protocol.

### Setup

```bash
cd a2a
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Configure environment
cp env.template .env
# Edit .env with your values

# Run the server
python main.py
```

### Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /.well-known/agent.json` | Agent discovery (capabilities) |
| `POST /` | Send messages to the agent |

### Test the A2A Wrapper

```bash
# Check agent card
curl http://localhost:8000/.well-known/agent.json

# Send a query
curl -X POST http://localhost:8000/ \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "message/send",
    "id": "1",
    "params": {
      "message": {
        "messageId": "msg-001",
        "role": "user",
        "parts": [{"type": "text", "text": "What network issues are in Barcelona?"}]
      }
    }
  }'
```

---

## Testing

### Test MCP Integration

```bash
pip install PyJWT cryptography requests
python test/test_mcp_battery.py
```

### Test A2A Wrapper

```bash
cd a2a
python test_a2a.py --query "Show me network anomalies"
```

---

## Data Model

### Tables

| Table | Description |
|-------|-------------|
| `NETWORK_KPI` | Network performance metrics (2M+ rows) |
| `ALARMS` | Active network alarms |
| `TOPOLOGY` | Network element hierarchy |
| `INCIDENTS` | Incident records |
| `SITE_GEO` | Site coordinates |
| `ANOMALY_SCORES` | ML anomaly detection |
| `CMDB_CI` | Configuration items |

### Views

| View | Description |
|------|-------------|
| `RADIO_KPI_V` | Radio KPIs (PRB_UTIL, RSRP, RSRQ, SINR) |
| `CORE_KPI_V` | Core node KPIs |
| `TRANSPORT_KPI_V` | Transport KPIs |
| `INCIDENTS_V` | Incident details |
| `ANOMALY_SCORES_V` | Anomaly results |

---

## Security

| Component | Purpose |
|-----------|---------|
| `TELCO_SN_INTEGRATION_RL` | ServiceNow role (SELECT only) |
| `TELCO_A2A_RL` | A2A role (SELECT only) |
| `SERVICENOW_SVC_USER` | ServiceNow service account |
| `A2A_SVC_USER` | A2A service account |
| `SERVICENOW_NETWORK_POLICY` | IP allowlist |
| `TELCO_ASSURANCE_MONITOR` | Resource monitor (100 credits) |

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `390144: JWT token is invalid` | Check account format in JWT issuer |
| `002003: Object does not exist` | Use fully qualified table names |
| `401 Unauthorized` | Verify key fingerprint matches |
| `Unable to fetch tools` | Add `X-Snowflake-Authorization-Token-Type: KEYPAIR_JWT` header |
| `Network policy violation` | Add IPs to allowlist |

---

## References

- [Snowflake MCP Server Docs](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-mcp)
- [Snowflake Cortex Agent Docs](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents)
- [Google A2A Protocol](https://github.com/google/a2a)
- [Snowflake Key-Pair Authentication](https://docs.snowflake.com/en/user-guide/key-pair-auth)
- [ServiceNow IntegrationHub](https://docs.servicenow.com/bundle/utah-integrate-applications/page/administer/integrationhub/concept/integrationhub.html)

---

## License

ISC
