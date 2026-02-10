import os
import snowflake.connector

DATA_DIR = "/Users/pjose/Documents/GitHub/MWC_Prodapt_2026_v2/snowflake/data"

conn = snowflake.connector.connect(
    connection_name=os.getenv("SNOWFLAKE_CONNECTION_NAME") or "pjose_aws3"
)

cursor = conn.cursor()

cursor.execute("USE DATABASE TELCO_AI_DB")
cursor.execute("USE SCHEMA NETWORK_ASSURANCE")
cursor.execute("USE WAREHOUSE TELCO_ASSURANCE_WH")

csv_files = [
    "alarms.csv",
    "anomaly_scores.csv",
    "change_events.csv",
    "cmdb_ci.csv",
    "cmdb_relationships.csv",
    "event_correlation_rules.csv",
    "incidents.csv",
    "network_kpi_part1.csv",
    "network_kpi_part2.csv",
    "service_footprints.csv",
    "site_geo.csv",
    "sla_breaches.csv",
    "topology.csv",
    "trouble_tickets.csv",
]

print("Uploading files to stage...")
for csv_file in csv_files:
    file_path = os.path.join(DATA_DIR, csv_file)
    print(f"  Uploading {csv_file}...")
    cursor.execute(f"PUT file://{file_path} @TELCO_DATA_STAGE AUTO_COMPRESS=TRUE OVERWRITE=TRUE")

print("\nTruncating tables...")
tables = [
    "NETWORK_KPI", "ALARMS", "TOPOLOGY", "INCIDENTS", "SITE_GEO",
    "SERVICE_FOOTPRINTS", "CHANGE_EVENTS", "TROUBLE_TICKETS",
    "SLA_BREACHES", "ANOMALY_SCORES", "CMDB_CI", "CMDB_RELATIONSHIPS",
    "EVENT_CORRELATION_RULES"
]
for table in tables:
    cursor.execute(f"TRUNCATE TABLE {table}")

print("\nLoading data into tables...")

load_map = {
    "NETWORK_KPI": ["network_kpi_part1.csv", "network_kpi_part2.csv"],
    "ALARMS": ["alarms.csv"],
    "TOPOLOGY": ["topology.csv"],
    "INCIDENTS": ["incidents.csv"],
    "SITE_GEO": ["site_geo.csv"],
    "SERVICE_FOOTPRINTS": ["service_footprints.csv"],
    "CHANGE_EVENTS": ["change_events.csv"],
    "TROUBLE_TICKETS": ["trouble_tickets.csv"],
    "SLA_BREACHES": ["sla_breaches.csv"],
    "ANOMALY_SCORES": ["anomaly_scores.csv"],
    "CMDB_CI": ["cmdb_ci.csv"],
    "CMDB_RELATIONSHIPS": ["cmdb_relationships.csv"],
    "EVENT_CORRELATION_RULES": ["event_correlation_rules.csv"],
}

for table, files in load_map.items():
    for f in files:
        print(f"  Loading {f} into {table}...")
        cursor.execute(f"""
            COPY INTO {table}
            FROM @TELCO_DATA_STAGE/{f}.gz
            FILE_FORMAT = (FORMAT_NAME = TELCO_CSV_FF)
            ON_ERROR = 'CONTINUE'
        """)

print("\nValidating row counts...")
cursor.execute("""
    SELECT 'NETWORK_KPI' AS tbl, COUNT(*) AS cnt FROM NETWORK_KPI
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
""")

print("\nRow counts:")
for row in cursor.fetchall():
    print(f"  {row[0]}: {row[1]:,}")

cursor.close()
conn.close()
print("\nDone!")
