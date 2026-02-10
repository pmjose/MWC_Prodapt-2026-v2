-- Snowflake demo setup for Telecom Assurance (schema, tables, sample data, views)
-- Run in a Snowflake worksheet as ACCOUNTADMIN or a role with sufficient privileges.

-- 1) Warehouse, database, and schema
CREATE WAREHOUSE IF NOT EXISTS TELCO_ASSURANCE_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE;

CREATE DATABASE IF NOT EXISTS TELCO_AI_DB;
CREATE SCHEMA IF NOT EXISTS TELCO_AI_DB.NETWORK_ASSURANCE;

USE DATABASE TELCO_AI_DB;
USE SCHEMA NETWORK_ASSURANCE;
USE WAREHOUSE TELCO_ASSURANCE_WH;

-- 2) Core tables
CREATE OR REPLACE TABLE NETWORK_KPI (
  ts TIMESTAMP_NTZ,
  region STRING,
  cell_id STRING,
  kpi_name STRING,
  kpi_value FLOAT,
  kpi_unit STRING,
  vendor STRING,
  tech STRING
);

CREATE OR REPLACE TABLE ALARMS (
  ts TIMESTAMP_NTZ,
  region STRING,
  cell_id STRING,
  alarm_code STRING,
  severity STRING,
  description STRING,
  incident_number STRING
);

CREATE OR REPLACE TABLE TOPOLOGY (
  element_id STRING,
  element_type STRING,
  region STRING,
  parent_id STRING,
  service_id STRING
);

CREATE OR REPLACE TABLE INCIDENTS (
  sys_id STRING,
  number STRING,
  opened_at TIMESTAMP_NTZ,
  resolved_at TIMESTAMP_NTZ,
  sys_created_on TIMESTAMP_NTZ,
  sys_updated_on TIMESTAMP_NTZ,
  sys_created_by STRING,
  sys_updated_by STRING,
  sys_domain STRING,
  region STRING,
  service_id STRING,
  priority STRING,
  impact STRING,
  urgency STRING,
  state STRING,
  assignment_group STRING,
  assigned_to STRING,
  category STRING,
  subcategory STRING,
  service_type STRING,
  contact_type STRING,
  short_description STRING,
  description STRING,
  impacted_elements STRING,
  duration_minutes INTEGER,
  mttr_minutes INTEGER,
  close_code STRING,
  close_notes STRING
);

CREATE OR REPLACE TABLE SITE_GEO (
  site_id STRING,
  region STRING,
  latitude FLOAT,
  longitude FLOAT,
  neighborhood STRING
);

CREATE OR REPLACE TABLE SERVICE_FOOTPRINTS (
  service_id STRING,
  element_id STRING,
  subscriber_count INTEGER,
  vip_subscribers INTEGER
);

CREATE OR REPLACE TABLE CHANGE_EVENTS (
  change_id STRING,
  ts TIMESTAMP_NTZ,
  region STRING,
  element_id STRING,
  change_type STRING,
  description STRING,
  planned STRING,
  status STRING
);

CREATE OR REPLACE TABLE TROUBLE_TICKETS (
  sys_id STRING,
  number STRING,
  opened_at TIMESTAMP_NTZ,
  sys_created_on TIMESTAMP_NTZ,
  sys_updated_on TIMESTAMP_NTZ,
  sys_created_by STRING,
  sys_updated_by STRING,
  sys_domain STRING,
  region STRING,
  element_id STRING,
  priority STRING,
  state STRING,
  assignment_group STRING,
  short_description STRING,
  description STRING,
  contact_type STRING
);

CREATE OR REPLACE TABLE SLA_BREACHES (
  breach_id STRING,
  ts_start TIMESTAMP_NTZ,
  ts_end TIMESTAMP_NTZ,
  service_id STRING,
  region STRING,
  metric STRING,
  threshold FLOAT,
  observed FLOAT,
  penalty_eur FLOAT
);

CREATE OR REPLACE TABLE ANOMALY_SCORES (
  ts TIMESTAMP_NTZ,
  region STRING,
  element_id STRING,
  kpi_name STRING,
  score FLOAT,
  label STRING,
  model_version STRING
);

CREATE OR REPLACE TABLE CMDB_CI (
  sys_id STRING,
  ci_id STRING,
  ci_class STRING,
  region STRING,
  ci_name STRING,
  operational_status STRING,
  ci_type STRING,
  parent_ci STRING,
  sys_created_on TIMESTAMP_NTZ,
  sys_updated_on TIMESTAMP_NTZ,
  sys_created_by STRING,
  sys_updated_by STRING,
  sys_domain STRING
);

CREATE OR REPLACE TABLE CMDB_RELATIONSHIPS (
  child_ci STRING,
  parent_ci STRING,
  relationship_type STRING
);

CREATE OR REPLACE TABLE EVENT_CORRELATION_RULES (
  rule_id STRING,
  name STRING,
  match_condition STRING,
  action_field STRING,
  severity STRING,
  action STRING
);

-- 3) Sample data is loaded from CSVs in snowflake/data via snowflake/data_load.sql

INSERT INTO TOPOLOGY (element_id, element_type, region, parent_id, service_id) VALUES
  ('CELL-001', 'RADIO_CELL', 'NORTH', 'SITE-01', 'SVC-VOICE'),
  ('CELL-002', 'RADIO_CELL', 'NORTH', 'SITE-01', 'SVC-DATA'),
  ('CELL-003', 'RADIO_CELL', 'NORTH', 'SITE-02', 'SVC-DATA'),
  ('CELL-101', 'RADIO_CELL', 'SOUTH', 'SITE-10', 'SVC-VOICE'),
  ('CELL-102', 'RADIO_CELL', 'SOUTH', 'SITE-10', 'SVC-DATA'),
  ('SITE-01', 'RADIO_SITE', 'NORTH', 'CORE-01', 'SVC-VOICE'),
  ('SITE-02', 'RADIO_SITE', 'NORTH', 'CORE-01', 'SVC-DATA'),
  ('SITE-10', 'RADIO_SITE', 'SOUTH', 'CORE-02', 'SVC-VOICE'),
  ('CORE-01', 'CORE_NODE', 'NORTH', NULL, 'SVC-VOICE'),
  ('CORE-02', 'CORE_NODE', 'SOUTH', NULL, 'SVC-DATA');

INSERT INTO INCIDENTS (number, opened_at, region, service_id, state, short_description) VALUES
  ('INC-1001', '2026-02-24 10:12:00', 'NORTH', 'SVC-VOICE', 'OPEN', 'Voice service degradation in North'),
  ('INC-1002', '2026-02-26 10:22:00', 'SOUTH', 'SVC-DATA', 'OPEN', 'Data throughput drop in South'),
  ('INC-1003', '2026-02-23 11:05:00', 'NORTH', 'SVC-DATA', 'OPEN', 'Intermittent data slowness in North'),
  ('INC-1004', '2026-02-28 10:30:00', 'SOUTH', 'SVC-VOICE', 'RESOLVED', 'Voice drops in South resolved after backhaul fix');

-- 4) Semantic views for domains
CREATE OR REPLACE VIEW RADIO_KPI_V AS
SELECT * FROM NETWORK_KPI
WHERE kpi_name IN ('PRB_UTIL', 'RSRP', 'RSRQ', 'SINR');

CREATE OR REPLACE VIEW CORE_KPI_V AS
SELECT * FROM NETWORK_KPI
WHERE kpi_name IN ('CPU_UTIL', 'MEM_UTIL', 'SESSION_FAIL_RATE');

CREATE OR REPLACE VIEW TRANSPORT_KPI_V AS
SELECT * FROM NETWORK_KPI
WHERE kpi_name IN ('BACKHAUL_LATENCY', 'PACKET_LOSS');

CREATE OR REPLACE VIEW CUSTOMER_IMPACT_V AS
SELECT
  i.number AS incident_number,
  i.opened_at,
  i.resolved_at,
  i.region,
  i.service_id,
  i.priority,
  i.impact,
  i.urgency,
  i.state,
  i.assignment_group,
  i.assigned_to,
  i.short_description,
  i.description,
  i.impacted_elements,
  i.duration_minutes,
  i.mttr_minutes,
  i.close_code,
  i.close_notes,
  t.element_id,
  t.element_type
FROM INCIDENTS i
LEFT JOIN LATERAL (
  SELECT TRIM(value::string) AS element_id
  FROM TABLE(FLATTEN(input => SPLIT(i.impacted_elements, ',')))
) ie
  ON TRUE
LEFT JOIN TOPOLOGY t
  ON t.element_id = ie.element_id;

CREATE OR REPLACE VIEW TOPOLOGY_V AS
SELECT * FROM TOPOLOGY;

CREATE OR REPLACE VIEW INCIDENTS_V AS
SELECT * FROM INCIDENTS;

CREATE OR REPLACE VIEW SITE_GEO_V AS
SELECT * FROM SITE_GEO;

CREATE OR REPLACE VIEW SERVICE_FOOTPRINTS_V AS
SELECT * FROM SERVICE_FOOTPRINTS;

CREATE OR REPLACE VIEW CHANGE_EVENTS_V AS
SELECT * FROM CHANGE_EVENTS;

CREATE OR REPLACE VIEW TROUBLE_TICKETS_V AS
SELECT * FROM TROUBLE_TICKETS;

CREATE OR REPLACE VIEW SLA_BREACHES_V AS
SELECT * FROM SLA_BREACHES;

CREATE OR REPLACE VIEW ANOMALY_SCORES_V AS
SELECT * FROM ANOMALY_SCORES;

CREATE OR REPLACE VIEW CMDB_CI_V AS
SELECT * FROM CMDB_CI;

CREATE OR REPLACE VIEW CMDB_RELATIONSHIPS_V AS
SELECT * FROM CMDB_RELATIONSHIPS;

CREATE OR REPLACE VIEW EVENT_CORRELATION_RULES_V AS
SELECT * FROM EVENT_CORRELATION_RULES;

-- 5) Optional: MCP server (Snowflake-managed) exposing SQL execution tool
-- Reference: https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-mcp
-- Note: The MCP server is created in provisioning_setup.sql. This block is provided for reference only.
/*
CREATE OR REPLACE MCP SERVER TELCO_ASSURANCE_MCP
FROM SPECIFICATION $$
  tools:
    - title: "SQL Execution Tool"
      name: "sql_exec_tool"
      type: "SYSTEM_EXECUTE_SQL"
      description: "Execute SQL queries on the telecom assurance schema."
$$;

-- Grant access to a dedicated integration role
CREATE ROLE IF NOT EXISTS TELCO_SN_INTEGRATION_RL;
GRANT USAGE ON DATABASE TELCO_AI_DB TO ROLE TELCO_SN_INTEGRATION_RL;
GRANT USAGE ON SCHEMA TELCO_AI_DB.NETWORK_ASSURANCE TO ROLE TELCO_SN_INTEGRATION_RL;
GRANT SELECT ON ALL TABLES IN SCHEMA TELCO_AI_DB.NETWORK_ASSURANCE TO ROLE TELCO_SN_INTEGRATION_RL;
GRANT SELECT ON ALL VIEWS IN SCHEMA TELCO_AI_DB.NETWORK_ASSURANCE TO ROLE TELCO_SN_INTEGRATION_RL;
GRANT USAGE ON MCP SERVER TELCO_AI_DB.NETWORK_ASSURANCE.TELCO_ASSURANCE_MCP
  TO ROLE TELCO_SN_INTEGRATION_RL;
*/
