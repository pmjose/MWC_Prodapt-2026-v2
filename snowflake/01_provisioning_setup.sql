-- Snowflake provisioning for Telecom Assurance demo
-- Creates roles, user, warehouse, database, schema, MCP server, OAuth, and network policy.
-- Run with ACCOUNTADMIN or equivalent privileges.

-- ============================================================================
-- 1) ROLES
-- ============================================================================
CREATE ROLE IF NOT EXISTS TELCO_ADMIN_RL;
CREATE ROLE IF NOT EXISTS TELCO_MCP_RL;
CREATE ROLE IF NOT EXISTS TELCO_SN_INTEGRATION_RL;

-- Grant roles to SYSADMIN for administration
GRANT ROLE TELCO_ADMIN_RL TO ROLE SYSADMIN;
GRANT ROLE TELCO_MCP_RL TO ROLE TELCO_ADMIN_RL;
GRANT ROLE TELCO_SN_INTEGRATION_RL TO ROLE TELCO_ADMIN_RL;

-- ============================================================================
-- 2) WAREHOUSE
-- ============================================================================
CREATE WAREHOUSE IF NOT EXISTS TELCO_ASSURANCE_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

GRANT USAGE, OPERATE ON WAREHOUSE TELCO_ASSURANCE_WH TO ROLE TELCO_ADMIN_RL;
GRANT USAGE ON WAREHOUSE TELCO_ASSURANCE_WH TO ROLE TELCO_MCP_RL;
GRANT USAGE ON WAREHOUSE TELCO_ASSURANCE_WH TO ROLE TELCO_SN_INTEGRATION_RL;

-- ============================================================================
-- 3) DATABASE + SCHEMA
-- ============================================================================
CREATE DATABASE IF NOT EXISTS TELCO_AI_DB;
CREATE SCHEMA IF NOT EXISTS TELCO_AI_DB.NETWORK_ASSURANCE;

GRANT USAGE ON DATABASE TELCO_AI_DB TO ROLE TELCO_ADMIN_RL;
GRANT USAGE ON SCHEMA TELCO_AI_DB.NETWORK_ASSURANCE TO ROLE TELCO_ADMIN_RL;
GRANT ALL PRIVILEGES ON SCHEMA TELCO_AI_DB.NETWORK_ASSURANCE TO ROLE TELCO_ADMIN_RL;

GRANT USAGE ON DATABASE TELCO_AI_DB TO ROLE TELCO_MCP_RL;
GRANT USAGE ON SCHEMA TELCO_AI_DB.NETWORK_ASSURANCE TO ROLE TELCO_MCP_RL;

GRANT USAGE ON DATABASE TELCO_AI_DB TO ROLE TELCO_SN_INTEGRATION_RL;
GRANT USAGE ON SCHEMA TELCO_AI_DB.NETWORK_ASSURANCE TO ROLE TELCO_SN_INTEGRATION_RL;

-- ============================================================================
-- 4) NETWORK POLICY (Allowlist ServiceNow IPs)
-- ============================================================================
-- ServiceNow datacenter IP ranges - update with your instance's actual IPs
-- Find your ServiceNow instance IPs at: https://support.servicenow.com/kb?id=kb_article_view&sysparm_article=KB0547244

CREATE OR REPLACE NETWORK POLICY SERVICENOW_NETWORK_POLICY
  ALLOWED_IP_LIST = (
    -- ServiceNow US Commercial datacenter ranges (example)
    '158.99.0.0/16',
    '192.204.0.0/16',
    -- ServiceNow EU datacenter ranges (example)
    '185.80.0.0/16',
    -- Add your specific ServiceNow MID Server IPs here
    '0.0.0.0/0'  -- REMOVE THIS IN PRODUCTION - allows all IPs for demo only
  )
  BLOCKED_IP_LIST = ()
  COMMENT = 'Network policy for ServiceNow integration - restrict to ServiceNow datacenter IPs';

-- Apply network policy to integration user (created below)
-- ALTER USER SERVICENOW_SVC_USER SET NETWORK_POLICY = SERVICENOW_NETWORK_POLICY;

-- ============================================================================
-- 5) USERS
-- ============================================================================
-- Generic MCP user (for testing)
CREATE USER IF NOT EXISTS TELCO_MCP_USER
  PASSWORD = '<TEMP_PASSWORD>'
  LOGIN_NAME = 'TELCO_MCP_USER'
  DISPLAY_NAME = 'TELCO MCP User'
  DEFAULT_ROLE = TELCO_MCP_RL
  DEFAULT_WAREHOUSE = TELCO_ASSURANCE_WH
  MUST_CHANGE_PASSWORD = TRUE;

GRANT ROLE TELCO_MCP_RL TO USER TELCO_MCP_USER;

-- Dedicated ServiceNow service account
CREATE USER IF NOT EXISTS SERVICENOW_SVC_USER
  LOGIN_NAME = 'SERVICENOW_SVC_USER'
  DISPLAY_NAME = 'ServiceNow Integration Service Account'
  DEFAULT_ROLE = TELCO_SN_INTEGRATION_RL
  DEFAULT_WAREHOUSE = TELCO_ASSURANCE_WH
  TYPE = SERVICE
  COMMENT = 'Service account for ServiceNow MCP integration';

GRANT ROLE TELCO_SN_INTEGRATION_RL TO USER SERVICENOW_SVC_USER;

-- Apply network policy to ServiceNow user
ALTER USER SERVICENOW_SVC_USER SET NETWORK_POLICY = SERVICENOW_NETWORK_POLICY;

-- ============================================================================
-- 6) OAUTH SECURITY INTEGRATION (for ServiceNow)
-- ============================================================================
-- OAuth 2.0 Client Credentials flow for machine-to-machine authentication

CREATE OR REPLACE SECURITY INTEGRATION SERVICENOW_OAUTH_INTEGRATION
  TYPE = OAUTH
  OAUTH_CLIENT = CUSTOM
  ENABLED = TRUE
  OAUTH_CLIENT_TYPE = 'CONFIDENTIAL'
  OAUTH_REDIRECT_URI = 'https://<your-instance>.service-now.com/oauth_redirect.do'
  OAUTH_ISSUE_REFRESH_TOKENS = TRUE
  OAUTH_REFRESH_TOKEN_VALIDITY = 86400
  OAUTH_ALLOW_NON_TLS_REDIRECT_URI = FALSE
  COMMENT = 'OAuth integration for ServiceNow IntegrationHub';

-- After creating, run this to get client ID and secret:
-- SELECT SYSTEM$SHOW_OAUTH_CLIENT_SECRETS('SERVICENOW_OAUTH_INTEGRATION');

-- Grant the integration role to use OAuth
CREATE OR REPLACE SECURITY INTEGRATION SERVICENOW_OAUTH_USER_MAPPING
  TYPE = OAUTH
  OAUTH_CLIENT = CUSTOM
  ENABLED = TRUE
  OAUTH_CLIENT_TYPE = 'CONFIDENTIAL'
  OAUTH_REDIRECT_URI = 'https://<your-instance>.service-now.com/oauth_redirect.do'
  OAUTH_ISSUE_REFRESH_TOKENS = TRUE
  OAUTH_REFRESH_TOKEN_VALIDITY = 86400;

-- ============================================================================
-- 7) MCP SERVER
-- ============================================================================
USE DATABASE TELCO_AI_DB;
USE SCHEMA NETWORK_ASSURANCE;

CREATE OR REPLACE MCP SERVER TELCO_ASSURANCE_MCP
FROM SPECIFICATION $$
  tools:
    - title: "SQL Execution Tool"
      name: "sql_exec_tool"
      type: "SYSTEM_EXECUTE_SQL"
      description: "Execute SQL queries on telecom assurance views for network KPIs, alarms, incidents, and anomaly detection."
$$;

GRANT USAGE ON MCP SERVER TELCO_AI_DB.NETWORK_ASSURANCE.TELCO_ASSURANCE_MCP
  TO ROLE TELCO_MCP_RL;
GRANT USAGE ON MCP SERVER TELCO_AI_DB.NETWORK_ASSURANCE.TELCO_ASSURANCE_MCP
  TO ROLE TELCO_SN_INTEGRATION_RL;

-- ============================================================================
-- 8) DATA ACCESS GRANTS
-- ============================================================================
-- Apply after demo_setup.sql creates tables/views

GRANT SELECT ON ALL TABLES IN SCHEMA TELCO_AI_DB.NETWORK_ASSURANCE TO ROLE TELCO_MCP_RL;
GRANT SELECT ON ALL VIEWS IN SCHEMA TELCO_AI_DB.NETWORK_ASSURANCE TO ROLE TELCO_MCP_RL;
GRANT SELECT ON ALL TABLES IN SCHEMA TELCO_AI_DB.NETWORK_ASSURANCE TO ROLE TELCO_SN_INTEGRATION_RL;
GRANT SELECT ON ALL VIEWS IN SCHEMA TELCO_AI_DB.NETWORK_ASSURANCE TO ROLE TELCO_SN_INTEGRATION_RL;

-- Future grants for new objects (auto-apply SELECT to any new tables/views)
GRANT SELECT ON FUTURE TABLES IN SCHEMA TELCO_AI_DB.NETWORK_ASSURANCE TO ROLE TELCO_MCP_RL;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA TELCO_AI_DB.NETWORK_ASSURANCE TO ROLE TELCO_MCP_RL;
GRANT SELECT ON FUTURE TABLES IN SCHEMA TELCO_AI_DB.NETWORK_ASSURANCE TO ROLE TELCO_SN_INTEGRATION_RL;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA TELCO_AI_DB.NETWORK_ASSURANCE TO ROLE TELCO_SN_INTEGRATION_RL;

-- ============================================================================
-- 9) RESOURCE MONITOR (Cost Control)
-- ============================================================================
CREATE OR REPLACE RESOURCE MONITOR TELCO_ASSURANCE_MONITOR
  WITH CREDIT_QUOTA = 100
  FREQUENCY = MONTHLY
  START_TIMESTAMP = IMMEDIATELY
  TRIGGERS
    ON 75 PERCENT DO NOTIFY
    ON 90 PERCENT DO NOTIFY
    ON 100 PERCENT DO SUSPEND;

ALTER WAREHOUSE TELCO_ASSURANCE_WH SET RESOURCE_MONITOR = TELCO_ASSURANCE_MONITOR;

-- ============================================================================
-- 10) VALIDATION QUERIES
-- ============================================================================
-- Run these after setup to verify configuration

-- Check MCP server exists
-- SHOW MCP SERVERS IN SCHEMA TELCO_AI_DB.NETWORK_ASSURANCE;

-- Check OAuth integration
-- SHOW SECURITY INTEGRATIONS LIKE 'SERVICENOW%';

-- Get OAuth client credentials (run after creating integration)
-- SELECT SYSTEM$SHOW_OAUTH_CLIENT_SECRETS('SERVICENOW_OAUTH_INTEGRATION');

-- Check network policy
-- SHOW NETWORK POLICIES;

-- Check user grants
-- SHOW GRANTS TO USER SERVICENOW_SVC_USER;

-- Test MCP tools/list call (after authentication)
-- POST to: https://<account>.snowflakecomputing.com/api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/mcp-servers/TELCO_ASSURANCE_MCP
-- Body: {"jsonrpc": "2.0", "id": 1, "method": "tools/list", "params": {}}

-- ============================================================================
-- POST-SETUP CHECKLIST
-- ============================================================================
/*
1. Replace '<your-instance>' in OAUTH_REDIRECT_URI with your ServiceNow instance name
2. Replace '<TEMP_PASSWORD>' with a strong password
3. Run: SELECT SYSTEM$SHOW_OAUTH_CLIENT_SECRETS('SERVICENOW_OAUTH_INTEGRATION');
4. Store the client_id and client_secret in ServiceNow Credentials store
5. Update SERVICENOW_NETWORK_POLICY with actual ServiceNow datacenter IPs
6. Remove '0.0.0.0/0' from ALLOWED_IP_LIST in production
7. Run demo_setup.sql to create tables/views
8. Run data_load.sql to load sample data
9. Test with tools/list call from ServiceNow
*/
