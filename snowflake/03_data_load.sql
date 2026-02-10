-- Load demo data from GitHub repository (last week of Feb 2026)
-- Downloads CSV files directly from GitHub using External Access Integration

USE DATABASE TELCO_AI_DB;
USE SCHEMA NETWORK_ASSURANCE;
USE WAREHOUSE TELCO_ASSURANCE_WH;

-- ============================================================================
-- 1) NETWORK RULE FOR GITHUB ACCESS
-- ============================================================================
CREATE OR REPLACE NETWORK RULE GITHUB_NETWORK_RULE
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('raw.githubusercontent.com:443', 'github.com:443');

-- ============================================================================
-- 2) EXTERNAL ACCESS INTEGRATION
-- ============================================================================
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION GITHUB_ACCESS_INTEGRATION
  ALLOWED_NETWORK_RULES = (GITHUB_NETWORK_RULE)
  ENABLED = TRUE;

-- ============================================================================
-- 3) STORED PROCEDURE TO LOAD CSV FROM GITHUB
-- ============================================================================
CREATE OR REPLACE PROCEDURE LOAD_CSV_FROM_GITHUB(
    table_name VARCHAR,
    github_url VARCHAR
)
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python', 'requests', 'pandas')
HANDLER = 'load_csv'
EXTERNAL_ACCESS_INTEGRATIONS = (GITHUB_ACCESS_INTEGRATION)
AS
$$
import requests
import pandas as pd
from io import StringIO

def load_csv(session, table_name, github_url):
    response = requests.get(github_url)
    response.raise_for_status()
    
    df = pd.read_csv(StringIO(response.text), keep_default_na=False, na_values=[''])
    df = df.replace({'NULL': None, '': None})
    
    snowpark_df = session.create_dataframe(df)
    snowpark_df.write.mode("append").save_as_table(table_name)
    
    return f"Loaded {len(df)} rows into {table_name}"
$$;

-- ============================================================================
-- 4) TRUNCATE ALL TABLES
-- ============================================================================
TRUNCATE TABLE NETWORK_KPI;
TRUNCATE TABLE ALARMS;
TRUNCATE TABLE TOPOLOGY;
TRUNCATE TABLE INCIDENTS;
TRUNCATE TABLE SITE_GEO;
TRUNCATE TABLE SERVICE_FOOTPRINTS;
TRUNCATE TABLE CHANGE_EVENTS;
TRUNCATE TABLE TROUBLE_TICKETS;
TRUNCATE TABLE SLA_BREACHES;
TRUNCATE TABLE ANOMALY_SCORES;
TRUNCATE TABLE CMDB_CI;
TRUNCATE TABLE CMDB_RELATIONSHIPS;
TRUNCATE TABLE EVENT_CORRELATION_RULES;

-- ============================================================================
-- 5) LOAD DATA FROM GITHUB
-- ============================================================================
-- GitHub raw URL base: https://raw.githubusercontent.com/pmjose/MWC_Prodapt-2026-v2/main/snowflake/data/

-- Small tables first
CALL LOAD_CSV_FROM_GITHUB('SITE_GEO', 'https://raw.githubusercontent.com/pmjose/MWC_Prodapt-2026-v2/main/snowflake/data/site_geo.csv');
CALL LOAD_CSV_FROM_GITHUB('TOPOLOGY', 'https://raw.githubusercontent.com/pmjose/MWC_Prodapt-2026-v2/main/snowflake/data/topology.csv');
CALL LOAD_CSV_FROM_GITHUB('CHANGE_EVENTS', 'https://raw.githubusercontent.com/pmjose/MWC_Prodapt-2026-v2/main/snowflake/data/change_events.csv');
CALL LOAD_CSV_FROM_GITHUB('EVENT_CORRELATION_RULES', 'https://raw.githubusercontent.com/pmjose/MWC_Prodapt-2026-v2/main/snowflake/data/event_correlation_rules.csv');
CALL LOAD_CSV_FROM_GITHUB('SLA_BREACHES', 'https://raw.githubusercontent.com/pmjose/MWC_Prodapt-2026-v2/main/snowflake/data/sla_breaches.csv');
CALL LOAD_CSV_FROM_GITHUB('INCIDENTS', 'https://raw.githubusercontent.com/pmjose/MWC_Prodapt-2026-v2/main/snowflake/data/incidents.csv');

-- Medium tables
CALL LOAD_CSV_FROM_GITHUB('ALARMS', 'https://raw.githubusercontent.com/pmjose/MWC_Prodapt-2026-v2/main/snowflake/data/alarms.csv');
CALL LOAD_CSV_FROM_GITHUB('ANOMALY_SCORES', 'https://raw.githubusercontent.com/pmjose/MWC_Prodapt-2026-v2/main/snowflake/data/anomaly_scores.csv');
CALL LOAD_CSV_FROM_GITHUB('TROUBLE_TICKETS', 'https://raw.githubusercontent.com/pmjose/MWC_Prodapt-2026-v2/main/snowflake/data/trouble_tickets.csv');
CALL LOAD_CSV_FROM_GITHUB('SERVICE_FOOTPRINTS', 'https://raw.githubusercontent.com/pmjose/MWC_Prodapt-2026-v2/main/snowflake/data/service_footprints.csv');
CALL LOAD_CSV_FROM_GITHUB('CMDB_CI', 'https://raw.githubusercontent.com/pmjose/MWC_Prodapt-2026-v2/main/snowflake/data/cmdb_ci.csv');
CALL LOAD_CSV_FROM_GITHUB('CMDB_RELATIONSHIPS', 'https://raw.githubusercontent.com/pmjose/MWC_Prodapt-2026-v2/main/snowflake/data/cmdb_relationships.csv');

-- Large tables (network KPI split into 2 files ~72MB each)
CALL LOAD_CSV_FROM_GITHUB('NETWORK_KPI', 'https://raw.githubusercontent.com/pmjose/MWC_Prodapt-2026-v2/main/snowflake/data/network_kpi_part1.csv');
CALL LOAD_CSV_FROM_GITHUB('NETWORK_KPI', 'https://raw.githubusercontent.com/pmjose/MWC_Prodapt-2026-v2/main/snowflake/data/network_kpi_part2.csv');

-- ============================================================================
-- 6) VERIFY DATA LOAD
-- ============================================================================
SELECT 'NETWORK_KPI' AS table_name, COUNT(*) AS row_count FROM NETWORK_KPI
UNION ALL SELECT 'ALARMS', COUNT(*) FROM ALARMS
UNION ALL SELECT 'TOPOLOGY', COUNT(*) FROM TOPOLOGY
UNION ALL SELECT 'INCIDENTS', COUNT(*) FROM INCIDENTS
UNION ALL SELECT 'SITE_GEO', COUNT(*) FROM SITE_GEO
UNION ALL SELECT 'SERVICE_FOOTPRINTS', COUNT(*) FROM SERVICE_FOOTPRINTS
UNION ALL SELECT 'CHANGE_EVENTS', COUNT(*) FROM CHANGE_EVENTS
UNION ALL SELECT 'TROUBLE_TICKETS', COUNT(*) FROM TROUBLE_TICKETS
UNION ALL SELECT 'SLA_BREACHES', COUNT(*) FROM SLA_BREACHES
UNION ALL SELECT 'ANOMALY_SCORES', COUNT(*) FROM ANOMALY_SCORES
UNION ALL SELECT 'CMDB_CI', COUNT(*) FROM CMDB_CI
UNION ALL SELECT 'CMDB_RELATIONSHIPS', COUNT(*) FROM CMDB_RELATIONSHIPS
UNION ALL SELECT 'EVENT_CORRELATION_RULES', COUNT(*) FROM EVENT_CORRELATION_RULES
ORDER BY row_count DESC;

-- ============================================================================
-- EXPECTED ROW COUNTS
-- ============================================================================
/*
| TABLE_NAME              | ROW_COUNT |
|-------------------------|-----------|
| NETWORK_KPI             | 2,016,903 |
| TOPOLOGY                |       375 |
| CMDB_CI                 |       363 |
| CMDB_RELATIONSHIPS      |       360 |
| SERVICE_FOOTPRINTS      |       300 |
| ALARMS                  |       148 |
| ANOMALY_SCORES          |       126 |
| TROUBLE_TICKETS         |       100 |
| SITE_GEO                |        72 |
| INCIDENTS               |        18 |
| SLA_BREACHES            |        12 |
| CHANGE_EVENTS           |         7 |
| EVENT_CORRELATION_RULES |         4 |
|-------------------------|-----------|
| TOTAL                   | 2,018,798 |
*/
