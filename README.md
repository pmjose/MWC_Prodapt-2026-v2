# Agentic Assurance Demo (ServiceNow + Snowflake MCP)

This repo contains a telecom assurance demo design and Snowflake setup assets for an agentic workflow:
ServiceNow Assurance Agent orchestrates live events and remediation, while a Snowflake Insight/Anomaly Agent
analyzes historical telemetry and returns predictions via the Snowflake-managed MCP server.

## Contents
- `docs/architecture.md`: Architecture, agent lifecycle, A2A flow, and demo sequence.
- `docs/servicenow_mcp_integration.md`: Instructions for calling Snowflake MCP from ServiceNow.
- `snowflake/demo_setup.sql`: Snowflake schema, tables, sample data, views, and MCP server template.
- `snowflake/provisioning_setup.sql`: Create roles, user, warehouse, database, schema, and MCP server.
- `snowflake/data_load.sql`: Loads CSV data into Snowflake tables.
- `snowflake/data/`: CSVs with synthetic Tier-1 telco telemetry for Feb 22-28, 2026.
- `servicenow/`: ServiceNow stubs (IntegrationHub action, prompts, dashboards, correlation rules, playbooks).
- `servicenow/xml_exports/`: Example ServiceNow XML exports (incident, cmdb_ci).

## Quick Start
1. Run `snowflake/provisioning_setup.sql` to create roles, user, warehouse, database, schema, and MCP server.
2. Run `snowflake/demo_setup.sql` to create the demo data model and views.
3. Upload CSVs from `snowflake/data/` to the stage and run `snowflake/data_load.sql`.
4. Configure OAuth (or PAT) for MCP access and identify the MCP endpoint URL.
5. Use the instructions in `docs/servicenow_mcp_integration.md` to call the MCP server from ServiceNow.

## End-to-End Runbook
1. Run `snowflake/provisioning_setup.sql`.
2. Run `snowflake/demo_setup.sql`.
3. Upload all CSVs in `snowflake/data/` to the `TELCO_DATA_STAGE` stage.
4. Run `snowflake/data_load.sql`.
5. Validate row counts (example):
   - `NETWORK_KPI`: 2,016,903
   - `ALARMS`: 148
   - `INCIDENTS`: 18
   - `TROUBLE_TICKETS`: 100
   - `CMDB_CI`: 363
6. Call MCP `tools/list` and `tools/call` to confirm access.

## Demo Flow Summary
1. ServiceNow detects a live KPI degradation or alarm.
2. ServiceNow calls the Snowflake MCP server tool for deeper insight.
3. Snowflake analyzes historical telemetry and returns prediction signals.
4. ServiceNow correlates predictions, performs RCA, and triggers remediation.

## Snowflake MCP Highlights
- MCP server created in `TELCO_AI_DB.NETWORK_ASSURANCE`.
- Tool: `SYSTEM_EXECUTE_SQL` (`sql_exec_tool`) for querying views.
- ServiceNow integration role: `TELCO_SN_INTEGRATION_RL`.

## Data Sets (Barcelona, Feb 22-28, 2026)
All demo data is synthetic but realistic for a Tier‑1 telco operating in Barcelona.

### `snowflake/data/network_kpi_part1.csv` (1,008,451 records)
### `snowflake/data/network_kpi_part2.csv` (1,008,452 records)
15‑minute KPIs per cell/site (60 macro sites, 180 sectors, 120 small cells). Load both parts.
- `PRB_UTIL`: cell resource utilization (%), shows congestion during peak hours.
- `RSRP` / `SINR`: radio quality metrics (dBm / dB), degrade during congestion.
- `THROUGHPUT`: user throughput (Mbps), drops during congestion and backhaul stress.
- `BACKHAUL_LATENCY` / `PACKET_LOSS`: transport KPIs for 4G cells, spike mid‑week.
- `CPU_UTIL` / `MEM_UTIL` / `SESSION_FAIL_RATE`: core node health, spikes when city congestion peaks.
- `VOLTE_DROP_RATE`, `ERAB_DROP_RATE`, `DATA_SESSION_SETUP_TIME`, `PAGING_SUCCESS`,
  `LTE_RSRQ`, `5G_RSRQ`: additional access/mobility/quality KPIs.

### `snowflake/data/alarms.csv` (148 records)
Operational alarms aligned to KPI anomalies.
- RF degradation and congestion on downtown sectors.
- Backhaul latency and packet loss events.
- Core CPU warning tied to session failures.
- `incident_number` links alarms to ServiceNow incidents.

### `snowflake/data/topology.csv` (375 records)
Network topology hierarchy.
- `RADIO_CELL` → `RADIO_SITE` → `CORE_NODE` relationships.
- Service mapping (`SVC-VOICE`, `SVC-DATA`) used for impact correlation.

### `snowflake/data/incidents.csv` (18 records)
ServiceNow-style incidents aligned with alarm/KPI patterns.
- Fields include `sys_id`, `sys_created_on`, `sys_updated_on`, `sys_created_by`, `sys_updated_by`,
  `sys_domain`, `number`, `state`, `priority`, `impact`, `urgency`, `assignment_group`,
  `short_description`, `description`, `resolved_at`, `close_code`, `close_notes`.
- Includes `impacted_elements`, `duration_minutes`, and `mttr_minutes`.
- Congestion‑driven data incidents and backhaul‑driven voice degradation.
- Core CPU spikes impacting session setup.
- Maintenance windows, fiber cut reroute, power fluctuation, traffic surge.

### `snowflake/data/site_geo.csv` (72 records)
Geospatial context for sites and small‑cell groups.
- `latitude`/`longitude` approximate Barcelona locations.
- `neighborhood` tags for mapping and heat‑map demos.

### `snowflake/data/service_footprints.csv` (300 records)
Service footprint per network element.
- Subscriber counts per `element_id` and `service_id`.
- VIP subscriber counts for impact prioritization.

### `snowflake/data/change_events.csv` (7 records)
Planned change events for correlation with KPI shifts.
- Upgrade window timestamps and status for specific sites.

### `snowflake/data/trouble_tickets.csv` (100 records)
ServiceNow-style operational tickets for NOC workflows.
- Fields include `sys_id`, `sys_created_on`, `sys_updated_on`, `sys_created_by`, `sys_updated_by`,
  `sys_domain`, `number`, `state`, `assignment_group`, `short_description`, `description`, `contact_type`.

### `snowflake/data/sla_breaches.csv` (12 records)
SLA violations tied to KPI and service impact.
- Thresholds, observed values, and penalty estimates.

### `snowflake/data/anomaly_scores.csv` (126 records)
Model outputs for anomaly detection.
- Scores and labels by element and KPI, with model version.

### `snowflake/data/cmdb_ci.csv` (363 records)
ServiceNow CMDB configuration items aligned to sites, cells, small cells, and core nodes.
- CI class, operational status, parent CI, and `sys_*` fields for ServiceNow alignment.

### `snowflake/data/cmdb_relationships.csv` (360 records)
Relationships between CI items (cell → site, site → core).
- Supports CMDB-driven RCA and topology traversals.

### `snowflake/data/event_correlation_rules.csv` (4 records)
Event correlation rules used for alarm → incident linking.
- Match conditions, severity, and action descriptions.

## ServiceNow Stubs
- `servicenow/integrationhub_action.json`: Example IntegrationHub action to call Snowflake MCP.
- `servicenow/agent_prompt.md`: Assurance Agent prompt guidance.
- `servicenow/correlation_rules.json`: Correlation rule examples aligned to `EVENT_CORRELATION_RULES`.
- `servicenow/rca_playbooks.json`: Remediation playbooks for common fault types.
- `servicenow/dashboard_definitions.json`: Suggested dashboard widgets for demo views.

## Prerequisites and Tips
- Snowflake account with privileges to create database/schema/warehouse and MCP server.
- ServiceNow instance with IntegrationHub or MID Server for outbound calls.
- Network access from ServiceNow (or gateway) to Snowflake MCP endpoint.
- Use OAuth 2.0 with least-privilege roles; PAT is ok for demos.
- If `tools/call` fails, verify grants and endpoint URL.

## References
- Snowflake MCP server docs: https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-mcp
- Snowflake MCP guide: https://www.snowflake.com/en/developers/guides/getting-started-with-snowflake-mcp-server/

## Notes
- Snowflake MCP server supports tool calls only and non-streaming responses.
- MCP hostnames should use hyphens, not underscores.

