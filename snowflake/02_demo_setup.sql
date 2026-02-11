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

-- ============================================================================
-- 6) SEMANTIC VIEW (for Cortex Agent / A2A integration)
-- ============================================================================
-- Reference: https://docs.snowflake.com/en/user-guide/views-semantic/overview
-- The semantic view provides metadata for Cortex Analyst to generate accurate SQL
-- Uses SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML with dimensions, facts, and metrics

CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
  'TELCO_AI_DB.NETWORK_ASSURANCE',
  $$
name: TELCO_SEMANTIC_VIEW
description: Semantic model for telecom network assurance data including KPIs, alarms, incidents, topology, and anomaly detection.

tables:
  - name: NETWORK_KPI
    description: Network performance KPIs across all network layers
    base_table:
      database: TELCO_AI_DB
      schema: NETWORK_ASSURANCE
      table: NETWORK_KPI
    dimensions:
      - name: TS
        description: Timestamp of the KPI measurement
        expr: TS
        data_type: TIMESTAMP_NTZ
      - name: REGION
        description: Geographic region (BARCELONA, MADRID, VALENCIA)
        expr: REGION
        data_type: VARCHAR
      - name: CELL_ID
        description: Unique identifier for the network cell
        expr: CELL_ID
        data_type: VARCHAR
      - name: KPI_NAME
        description: Name of the KPI (PRB_UTIL, RSRP, RSRQ, SINR, CPU_UTIL, MEM_UTIL, BACKHAUL_LATENCY, PACKET_LOSS, SESSION_FAIL_RATE)
        expr: KPI_NAME
        data_type: VARCHAR
      - name: KPI_UNIT
        description: Unit of measurement (%, dBm, dB, ms)
        expr: KPI_UNIT
        data_type: VARCHAR
      - name: VENDOR
        description: Equipment vendor (ERICSSON, NOKIA, HUAWEI)
        expr: VENDOR
        data_type: VARCHAR
      - name: TECH
        description: Technology generation (4G, 5G)
        expr: TECH
        data_type: VARCHAR
    facts:
      - name: KPI_VALUE
        description: Numeric value of the KPI measurement
        expr: KPI_VALUE
        data_type: FLOAT
    metrics:
      - name: AVG_KPI_VALUE
        description: Average KPI value
        expr: AVG(KPI_VALUE)
      - name: MAX_KPI_VALUE
        description: Maximum KPI value
        expr: MAX(KPI_VALUE)
      - name: MIN_KPI_VALUE
        description: Minimum KPI value
        expr: MIN(KPI_VALUE)
      - name: KPI_COUNT
        description: Count of KPI measurements
        expr: COUNT(*)

  - name: ALARMS
    description: Network alarms with severity levels
    base_table:
      database: TELCO_AI_DB
      schema: NETWORK_ASSURANCE
      table: ALARMS
    dimensions:
      - name: TS
        description: Timestamp when the alarm was raised
        expr: TS
        data_type: TIMESTAMP_NTZ
      - name: REGION
        description: Geographic region
        expr: REGION
        data_type: VARCHAR
      - name: CELL_ID
        description: Cell that raised the alarm
        expr: CELL_ID
        data_type: VARCHAR
      - name: ALARM_CODE
        description: Alarm code identifier
        expr: ALARM_CODE
        data_type: VARCHAR
      - name: SEVERITY
        description: Alarm severity (CRITICAL, MAJOR, MINOR, WARNING)
        expr: SEVERITY
        data_type: VARCHAR
      - name: DESCRIPTION
        description: Alarm description
        expr: DESCRIPTION
        data_type: VARCHAR
      - name: INCIDENT_NUMBER
        description: Associated incident number
        expr: INCIDENT_NUMBER
        data_type: VARCHAR
    metrics:
      - name: ALARM_COUNT
        description: Count of alarms
        expr: COUNT(*)
      - name: CRITICAL_ALARM_COUNT
        description: Count of critical alarms
        expr: COUNT_IF(SEVERITY = 'CRITICAL')

  - name: INCIDENTS
    description: Network incidents from ServiceNow
    base_table:
      database: TELCO_AI_DB
      schema: NETWORK_ASSURANCE
      table: INCIDENTS
    dimensions:
      - name: NUMBER
        description: Unique incident number (e.g., INC-1001)
        expr: NUMBER
        data_type: VARCHAR
      - name: OPENED_AT
        description: When the incident was opened
        expr: OPENED_AT
        data_type: TIMESTAMP_NTZ
      - name: RESOLVED_AT
        description: When resolved (null if open)
        expr: RESOLVED_AT
        data_type: TIMESTAMP_NTZ
      - name: REGION
        description: Affected region
        expr: REGION
        data_type: VARCHAR
      - name: SERVICE_ID
        description: Impacted service
        expr: SERVICE_ID
        data_type: VARCHAR
      - name: PRIORITY
        description: Incident priority (P1-Critical, P2-High, P3-Medium, P4-Low)
        expr: PRIORITY
        data_type: VARCHAR
      - name: STATE
        description: Current state (OPEN, IN_PROGRESS, RESOLVED, CLOSED)
        expr: STATE
        data_type: VARCHAR
      - name: SHORT_DESCRIPTION
        description: Brief summary
        expr: SHORT_DESCRIPTION
        data_type: VARCHAR
      - name: ASSIGNMENT_GROUP
        description: Team assigned
        expr: ASSIGNMENT_GROUP
        data_type: VARCHAR
    facts:
      - name: DURATION_MINUTES
        description: Total duration in minutes
        expr: DURATION_MINUTES
        data_type: INTEGER
      - name: MTTR_MINUTES
        description: Mean time to repair in minutes
        expr: MTTR_MINUTES
        data_type: INTEGER
    metrics:
      - name: INCIDENT_COUNT
        description: Count of incidents
        expr: COUNT(*)
      - name: OPEN_INCIDENT_COUNT
        description: Count of open incidents
        expr: COUNT_IF(STATE = 'OPEN')
      - name: AVG_MTTR
        description: Average mean time to repair
        expr: AVG(MTTR_MINUTES)

  - name: TOPOLOGY
    description: Network element hierarchy
    base_table:
      database: TELCO_AI_DB
      schema: NETWORK_ASSURANCE
      table: TOPOLOGY
    dimensions:
      - name: ELEMENT_ID
        description: Network element identifier
        expr: ELEMENT_ID
        data_type: VARCHAR
      - name: ELEMENT_TYPE
        description: Type of element (RADIO_CELL, RADIO_SITE, CORE_NODE)
        expr: ELEMENT_TYPE
        data_type: VARCHAR
      - name: REGION
        description: Region location
        expr: REGION
        data_type: VARCHAR
      - name: PARENT_ID
        description: Parent element
        expr: PARENT_ID
        data_type: VARCHAR
      - name: SERVICE_ID
        description: Associated service
        expr: SERVICE_ID
        data_type: VARCHAR
    metrics:
      - name: ELEMENT_COUNT
        description: Count of network elements
        expr: COUNT(*)

  - name: ANOMALY_SCORES
    description: ML-detected anomalies
    base_table:
      database: TELCO_AI_DB
      schema: NETWORK_ASSURANCE
      table: ANOMALY_SCORES
    dimensions:
      - name: TS
        description: Timestamp
        expr: TS
        data_type: TIMESTAMP_NTZ
      - name: REGION
        description: Region
        expr: REGION
        data_type: VARCHAR
      - name: ELEMENT_ID
        description: Network element
        expr: ELEMENT_ID
        data_type: VARCHAR
      - name: KPI_NAME
        description: KPI name
        expr: KPI_NAME
        data_type: VARCHAR
      - name: LABEL
        description: Classification label
        expr: LABEL
        data_type: VARCHAR
      - name: MODEL_VERSION
        description: ML model version
        expr: MODEL_VERSION
        data_type: VARCHAR
    facts:
      - name: SCORE
        description: Anomaly score 0-1 (higher = more anomalous)
        expr: SCORE
        data_type: FLOAT
    metrics:
      - name: AVG_ANOMALY_SCORE
        description: Average anomaly score
        expr: AVG(SCORE)
      - name: HIGH_ANOMALY_COUNT
        description: Count of high anomalies (score > 0.7)
        expr: COUNT_IF(SCORE > 0.7)

  - name: SLA_BREACHES
    description: SLA violations
    base_table:
      database: TELCO_AI_DB
      schema: NETWORK_ASSURANCE
      table: SLA_BREACHES
    dimensions:
      - name: BREACH_ID
        description: Breach identifier
        expr: BREACH_ID
        data_type: VARCHAR
      - name: TS_START
        description: Start time
        expr: TS_START
        data_type: TIMESTAMP_NTZ
      - name: TS_END
        description: End time
        expr: TS_END
        data_type: TIMESTAMP_NTZ
      - name: SERVICE_ID
        description: Affected service
        expr: SERVICE_ID
        data_type: VARCHAR
      - name: REGION
        description: Affected region
        expr: REGION
        data_type: VARCHAR
      - name: METRIC
        description: Breached metric
        expr: METRIC
        data_type: VARCHAR
    facts:
      - name: THRESHOLD
        description: SLA threshold
        expr: THRESHOLD
        data_type: FLOAT
      - name: OBSERVED
        description: Observed value
        expr: OBSERVED
        data_type: FLOAT
      - name: PENALTY_EUR
        description: Penalty in Euros
        expr: PENALTY_EUR
        data_type: FLOAT
    metrics:
      - name: TOTAL_PENALTY
        description: Total penalty amount
        expr: SUM(PENALTY_EUR)
      - name: BREACH_COUNT
        description: Count of SLA breaches
        expr: COUNT(*)

  - name: SITE_GEO
    description: Site coordinates
    base_table:
      database: TELCO_AI_DB
      schema: NETWORK_ASSURANCE
      table: SITE_GEO
    dimensions:
      - name: SITE_ID
        description: Site identifier
        expr: SITE_ID
        data_type: VARCHAR
      - name: REGION
        description: Region name
        expr: REGION
        data_type: VARCHAR
      - name: NEIGHBORHOOD
        description: Neighborhood name
        expr: NEIGHBORHOOD
        data_type: VARCHAR
    facts:
      - name: LATITUDE
        description: Latitude
        expr: LATITUDE
        data_type: FLOAT
      - name: LONGITUDE
        description: Longitude
        expr: LONGITUDE
        data_type: FLOAT
    metrics:
      - name: SITE_COUNT
        description: Count of sites
        expr: COUNT(*)
$$);

-- Grant SELECT on semantic view to roles
GRANT SELECT ON SEMANTIC VIEW TELCO_AI_DB.NETWORK_ASSURANCE.TELCO_SEMANTIC_VIEW 
  TO ROLE TELCO_A2A_RL;
GRANT SELECT ON SEMANTIC VIEW TELCO_AI_DB.NETWORK_ASSURANCE.TELCO_SEMANTIC_VIEW 
  TO ROLE TELCO_ADMIN_RL;
GRANT SELECT ON SEMANTIC VIEW TELCO_AI_DB.NETWORK_ASSURANCE.TELCO_SEMANTIC_VIEW 
  TO ROLE TELCO_MCP_RL;
GRANT SELECT ON SEMANTIC VIEW TELCO_AI_DB.NETWORK_ASSURANCE.TELCO_SEMANTIC_VIEW 
  TO ROLE TELCO_SN_INTEGRATION_RL;
