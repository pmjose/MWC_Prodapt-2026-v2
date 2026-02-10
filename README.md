# Agentic Assurance Demo (ServiceNow + Snowflake MCP)

This repo contains a telecom assurance demo design and Snowflake setup assets for an agentic workflow:
ServiceNow Assurance Agent orchestrates live events and remediation, while a Snowflake Insight/Anomaly Agent
analyzes historical telemetry and returns predictions via the Snowflake-managed MCP server.

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
         │                                                  │
         ▼                                                  ▼
┌─────────────────────┐                         ┌─────────────────────────┐
│  ServiceNow CMDB    │                         │   Snowflake Tables      │
│  Incidents/Tickets  │                         │   2M+ KPI Records       │
└─────────────────────┘                         └─────────────────────────┘
```

## Contents

| Path | Description |
|------|-------------|
| `docs/architecture.md` | Architecture, agent lifecycle, A2A flow, and demo sequence |
| `docs/servicenow_mcp_integration.md` | Instructions for calling Snowflake MCP from ServiceNow |
| `docs/snowflake_validation_checklist.md` | Post-deployment validation steps |
| `snowflake/01_provisioning_setup.sql` | Roles, users, OAuth, network policy, MCP server, resource monitor |
| `snowflake/02_demo_setup.sql` | Schema, tables, sample data, views |
| `snowflake/03_data_load.sql` | Load CSV data into Snowflake tables |
| `snowflake/data/` | CSVs with synthetic Tier-1 telco telemetry (Feb 22-28, 2026) |
| `servicenow/` | IntegrationHub action, prompts, dashboards, correlation rules, playbooks |
| `servicenow/xml_exports/` | Example ServiceNow XML exports (incident, cmdb_ci) |
| `streamlit-erd-app/` | ERD visualization app for schema exploration |

## Quick Start

```bash
# 1. Run provisioning (creates OAuth, network policy, MCP server)
snowflake/01_provisioning_setup.sql

# 2. Create tables and views
snowflake/02_demo_setup.sql

# 3. Upload CSVs to stage, then load data
snowflake/03_data_load.sql

# 4. Get OAuth credentials for ServiceNow
SELECT SYSTEM$SHOW_OAUTH_CLIENT_SECRETS('SERVICENOW_OAUTH_INTEGRATION');

# 5. Test MCP endpoint
POST https://<account>.snowflakecomputing.com/api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/mcp-servers/TELCO_ASSURANCE_MCP
```

## Deployment Runbook

### Step 1: Snowflake Setup

```sql
-- Run as ACCOUNTADMIN
-- 1. Execute provisioning (creates all infrastructure)
@snowflake/01_provisioning_setup.sql

-- 2. Execute demo setup (creates tables/views)
@snowflake/02_demo_setup.sql

-- 3. Upload CSVs to stage via Snowsight or SnowSQL
PUT file:///path/to/snowflake/data/*.csv @TELCO_DATA_STAGE AUTO_COMPRESS=TRUE;

-- 4. Load data
@snowflake/03_data_load.sql
```

### Step 2: Configure OAuth

```sql
-- Get OAuth credentials
SELECT SYSTEM$SHOW_OAUTH_CLIENT_SECRETS('SERVICENOW_OAUTH_INTEGRATION');

-- Returns: client_id, client_secret
-- Store these in ServiceNow Credentials store
```

### Step 3: ServiceNow Configuration

| Setting | Value |
|---------|-------|
| **OAuth Provider** | Snowflake |
| **Token URL** | `https://<account>.snowflakecomputing.com/oauth/token-request` |
| **Client ID** | From step 2 |
| **Client Secret** | From step 2 |
| **MCP Endpoint** | `https://<account>.snowflakecomputing.com/api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/mcp-servers/TELCO_ASSURANCE_MCP` |

### Step 4: Validate Setup

```sql
-- Check row counts
SELECT 'NETWORK_KPI' AS tbl, COUNT(*) FROM NETWORK_KPI
UNION ALL SELECT 'ALARMS', COUNT(*) FROM ALARMS
UNION ALL SELECT 'INCIDENTS', COUNT(*) FROM INCIDENTS
UNION ALL SELECT 'CMDB_CI', COUNT(*) FROM CMDB_CI;

-- Expected:
-- NETWORK_KPI: 2,016,903
-- ALARMS: 148
-- INCIDENTS: 18
-- CMDB_CI: 363
```

### Step 5: Test MCP Call

```json
POST /api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/mcp-servers/TELCO_ASSURANCE_MCP
Authorization: Bearer <oauth_token>
Content-Type: application/json

{
  "jsonrpc": "2.0",
  "id": "test-001",
  "method": "tools/list",
  "params": {}
}
```

## Demo Flow

```
1. ServiceNow detects KPI degradation (PRB_UTIL > 90%)
        │
        ▼
2. IntegrationHub calls Snowflake MCP (sql_exec_tool)
        │
        ▼
3. Snowflake returns historical KPIs + anomaly scores
        │
        ▼
4. ServiceNow correlates with CMDB, identifies impacted services
        │
        ▼
5. RCA playbook triggered (e.g., PB-002: Cell congestion)
        │
        ▼
6. Remediation executed, feedback sent to Snowflake
```

## Snowflake Components

### MCP Server
- **Name**: `TELCO_ASSURANCE_MCP`
- **Location**: `TELCO_AI_DB.NETWORK_ASSURANCE`
- **Tool**: `sql_exec_tool` (SYSTEM_EXECUTE_SQL)

### Security
| Component | Purpose |
|-----------|---------|
| `TELCO_SN_INTEGRATION_RL` | Least-privilege role for ServiceNow |
| `SERVICENOW_SVC_USER` | Service account (TYPE=SERVICE) |
| `SERVICENOW_OAUTH_INTEGRATION` | OAuth 2.0 client credentials |
| `SERVICENOW_NETWORK_POLICY` | IP allowlist for ServiceNow datacenters |
| `TELCO_ASSURANCE_MONITOR` | Resource monitor (100 credit quota) |

### Views (Semantic Layer)
| View | Purpose |
|------|---------|
| `RADIO_KPI_V` | PRB_UTIL, RSRP, RSRQ, SINR |
| `CORE_KPI_V` | CPU_UTIL, MEM_UTIL, SESSION_FAIL_RATE |
| `TRANSPORT_KPI_V` | BACKHAUL_LATENCY, PACKET_LOSS |
| `CUSTOMER_IMPACT_V` | Incidents joined with topology |
| `ANOMALY_SCORES_V` | ML anomaly detection outputs |

## Data Sets (Barcelona, Feb 22-28, 2026)

All demo data is synthetic but realistic for a Tier-1 telco operating in Barcelona.

| File | Records | Description |
|------|---------|-------------|
| `network_kpi_part1.csv` | 1,008,451 | 15-min KPIs (part 1) |
| `network_kpi_part2.csv` | 1,008,452 | 15-min KPIs (part 2) |
| `alarms.csv` | 148 | Operational alarms |
| `incidents.csv` | 18 | ServiceNow-style incidents |
| `trouble_tickets.csv` | 100 | NOC operational tickets |
| `topology.csv` | 375 | Network hierarchy |
| `cmdb_ci.csv` | 363 | CMDB configuration items |
| `cmdb_relationships.csv` | 360 | CI relationships |
| `site_geo.csv` | 72 | Geospatial data |
| `service_footprints.csv` | 300 | Subscriber counts |
| `anomaly_scores.csv` | 126 | ML anomaly outputs |
| `sla_breaches.csv` | 12 | SLA violations |
| `change_events.csv` | 7 | Planned changes |
| `event_correlation_rules.csv` | 4 | Alarm→Incident rules |

### Key KPIs
- **PRB_UTIL**: Cell resource utilization (%), congestion indicator
- **RSRP/SINR**: Radio quality (dBm/dB)
- **THROUGHPUT**: User throughput (Mbps)
- **BACKHAUL_LATENCY/PACKET_LOSS**: Transport health
- **CPU_UTIL/MEM_UTIL**: Core node health

## ServiceNow Integration

### IntegrationHub Action
`servicenow/integrationhub_action.json` - Secure MCP integration with:
- Input validation (allowlist-based SQL injection prevention)
- Correlation ID tracking
- Error handling and retry logic
- OAuth token refresh

### RCA Playbooks
`servicenow/rca_playbooks.json` - Four remediation playbooks:
| ID | Name | Trigger |
|----|------|---------|
| PB-001 | Backhaul latency remediation | BACKHAUL_LATENCY > 50ms |
| PB-002 | Cell congestion mitigation | PRB_UTIL > 90% |
| PB-003 | Core CPU saturation | CPU_UTIL > 85% |
| PB-004 | Mobility/handover failures | HO_FAILURE_RATE > 3% |

### Correlation Rules
`servicenow/correlation_rules.json` - Alarm-to-incident mapping rules

### Dashboard Definitions
`servicenow/dashboard_definitions.json` - NOC dashboard widgets

## Prerequisites

### Snowflake
- Account with ACCOUNTADMIN privileges
- Ability to create: database, schema, warehouse, MCP server, OAuth integration, network policy

### ServiceNow
- Instance with IntegrationHub or MID Server
- Network access to Snowflake MCP endpoint
- Credentials store for OAuth client_id/secret

### Network
- ServiceNow datacenter IPs must be in Snowflake network policy
- HTTPS (443) access to Snowflake account URL

## Post-Setup Checklist

- [ ] Replace `<your-instance>` in OAuth redirect URI
- [ ] Replace `<TEMP_PASSWORD>` with strong password
- [ ] Get OAuth credentials: `SELECT SYSTEM$SHOW_OAUTH_CLIENT_SECRETS('SERVICENOW_OAUTH_INTEGRATION');`
- [ ] Store credentials in ServiceNow
- [ ] Update network policy with actual ServiceNow IPs
- [ ] Remove `0.0.0.0/0` from network policy (demo only)
- [ ] Test `tools/list` call from ServiceNow
- [ ] Test `tools/call` with sample SQL query
- [ ] Verify resource monitor alerts are configured

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `401 Unauthorized` | Check OAuth token, refresh if expired |
| `403 Forbidden` | Verify role has MCP server USAGE grant |
| `Network policy violation` | Add ServiceNow IPs to allowlist |
| `tools/call fails` | Check SQL syntax, verify SELECT grants |
| `Timeout` | Reduce query scope, check warehouse size |

## References

- [Snowflake MCP Server Docs](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-mcp)
- [Snowflake MCP Getting Started Guide](https://www.snowflake.com/en/developers/guides/getting-started-with-snowflake-mcp-server/)
- [ServiceNow IntegrationHub](https://docs.servicenow.com/bundle/utah-integrate-applications/page/administer/integrationhub/concept/integrationhub.html)
- [ServiceNow IP Ranges](https://support.servicenow.com/kb?id=kb_article_view&sysparm_article=KB0547244)

## Limitations

- Snowflake MCP server supports **tool calls only** (no streaming)
- MCP hostnames must use **hyphens** (not underscores)
- Maximum response size limited by MCP protocol
- OAuth tokens expire (configure refresh in ServiceNow)

## License

ISC
