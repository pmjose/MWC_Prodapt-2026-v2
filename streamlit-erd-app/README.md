# Snowflake ERD Viewer

A Streamlit in Snowflake app that dynamically displays Entity Relationship Diagrams for any database/schema.

## Features

- **Dynamic Discovery**: Browse all accessible databases and schemas
- **ERD Visualization**: Mermaid-based ERD diagrams showing tables, views, and relationships
- **Relationship Detection**: 
  - Foreign key constraints (when defined)
  - Inferred relationships from `_ID` column naming conventions
- **Table Details**: Expandable cards showing columns, types, primary keys, row counts, and sizes
- **Filtering**: Search/filter objects within a schema

## Deployment to Streamlit in Snowflake

### Option 1: Via Snowsight UI

1. Navigate to **Streamlit** in Snowsight
2. Click **+ Streamlit App**
3. Choose your database and schema
4. Copy the contents of `streamlit_app.py` into the editor
5. Click **Run**

### Option 2: Via SQL

```sql
CREATE OR REPLACE STREAMLIT MY_DB.MY_SCHEMA.ERD_VIEWER
  ROOT_LOCATION = '@MY_DB.MY_SCHEMA.MY_STAGE/streamlit-erd-app'
  MAIN_FILE = 'streamlit_app.py'
  QUERY_WAREHOUSE = 'MY_WAREHOUSE';
```

### Option 3: Via Snow CLI

```bash
snow streamlit deploy --database MY_DB --schema MY_SCHEMA
```

## Required Privileges

The app queries `INFORMATION_SCHEMA` views, so users need:

```sql
GRANT USAGE ON DATABASE <db> TO ROLE <role>;
GRANT USAGE ON SCHEMA <db>.<schema> TO ROLE <role>;
-- For full metadata access:
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE TO ROLE <role>;
```

## Files

```
streamlit-erd-app/
├── streamlit_app.py    # Main Streamlit application
├── environment.yml     # Conda dependencies for SiS
└── README.md           # This file
```

## Notes

- Snowflake does not enforce foreign keys, so relationships are inferred from naming conventions
- Large schemas (50+ objects) are truncated in the ERD view for performance
- Mermaid diagrams render natively in Streamlit
