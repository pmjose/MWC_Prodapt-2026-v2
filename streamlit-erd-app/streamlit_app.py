"""
ERD Viewer - Based on Cristian Scutaru's approach
https://github.com/cristiscu/streamlit-erd-viewer
"""

import streamlit as st
import json
import re
from snowflake.snowpark.context import get_active_session

st.set_page_config(page_title="ERD Viewer", page_icon=":material/schema:", layout="wide")

class Theme:
    def __init__(self, color, fillcolor, fillcolorC, bgcolor, icolor, tcolor, style, shape, pencolor, penwidth):
        self.color = color
        self.fillcolor = fillcolor
        self.fillcolorC = fillcolorC
        self.bgcolor = bgcolor
        self.icolor = icolor
        self.tcolor = tcolor
        self.style = style
        self.shape = shape
        self.pencolor = pencolor
        self.penwidth = penwidth

class Column:
    def __init__(self, table, name, comment):
        self.table = table
        self.name = name
        self.comment = comment if comment and comment != 'None' else ''
        self.nullable = True
        self.datatype = None
        self.identity = False
        self.isunique = False
        self.ispk = False
        self.pkconstraint = None
        self.fkof = None

    def getName(self, useUpperCase, withQuotes=True):
        return Table.getClassName(self.name, useUpperCase, withQuotes)

    def setDataType(self, datatype):
        self.datatype = datatype.get("type", "")
        self.nullable = bool(datatype.get("nullable", True))
        if self.datatype == "FIXED":
            self.datatype = "NUMBER"
        elif "fixed" in datatype:
            fixed = bool(datatype.get("fixed", False))
            if self.datatype == "TEXT":
                self.datatype = "CHAR" if fixed else "VARCHAR"
        if "length" in datatype:
            self.datatype += f"({datatype['length']})"
        elif "precision" in datatype:
            prec = int(datatype.get('precision', 0))
            scale = int(datatype.get('scale', 0))
            if prec > 0:
                if scale == 0:
                    self.datatype += f"({prec})"
                else:
                    self.datatype += f"({prec},{scale})"
        self.datatype = self.datatype.lower()

class Table:
    def __init__(self, name, comment):
        self.name = name
        self.comment = comment if comment and comment != 'None' else ''
        self.label = None
        self.columns = []
        self.uniques = {}
        self.pks = []
        self.fks = {}

    @classmethod
    def getClassName(cls, name, useUpperCase, withQuotes=True):
        if re.match("^[A-Z_0-9]*$", name) is None:
            return f'"{name}"' if withQuotes else name
        return name.upper() if useUpperCase else name.lower()

    def getName(self, useUpperCase, withQuotes=True):
        return Table.getClassName(self.name, useUpperCase, withQuotes)

    def getColumn(self, name):
        for column in self.columns:
            if column.name == name:
                return column
        return None

    def getDotShape(self, theme, showColumns, showTypes, useUpperCase):
        fillcolor = theme.fillcolorC if showColumns else theme.fillcolor
        colspan = "2" if showTypes else "1"
        tableName = self.getName(useUpperCase, False)
        s = (f'  {self.label} [\n'
            + f'    fillcolor="{fillcolor}" color="{theme.color}" penwidth="1"\n'
            + f'    label=<<table style="{theme.style}" border="0" cellborder="0" cellspacing="0" cellpadding="1">\n'
            + f'      <tr><td bgcolor="{theme.bgcolor}" align="center"'
            + f' colspan="{colspan}"><font color="{theme.tcolor}"><b>{tableName}</b></font></td></tr>\n')

        if showColumns:
            for column in self.columns:
                name = column.getName(useUpperCase, False)
                if column.ispk:
                    name = f"<u>{name}</u>"
                if column.fkof is not None:
                    name = f"<i>{name}</i>"
                if column.nullable:
                    name = f"{name}*"
                if column.identity:
                    name = f"{name} I"
                if column.isunique:
                    name = f"{name} U"
                datatype = column.datatype
                if useUpperCase:
                    datatype = datatype.upper()

                if showTypes:
                    s += (f'      <tr><td align="left"><font color="{theme.icolor}">{name}&nbsp;</font></td>\n'
                        + f'        <td align="left"><font color="{theme.icolor}">{datatype}</font></td></tr>\n')
                else:
                    s += f'      <tr><td align="left"><font color="{theme.icolor}">{name}</font></td></tr>\n'

        return s + '    </table>>\n  ]\n'

    def getDotLinks(self, theme):
        s = ""
        for constraint in self.fks:
            fks = self.fks[constraint]
            fk1 = fks[0]
            dashed = "" if not fk1.nullable else ' style="dashed"'
            arrow = "" if fk1.ispk and len(self.pks) == len(fk1.fkof.table.pks) else ' arrowtail="crow"'
            s += (f'  {self.label} -> {fk1.fkof.table.label}'
                + f' [ penwidth="{theme.penwidth}" color="{theme.pencolor}"{dashed}{arrow} ]\n')
        return s

@st.cache_resource
def get_session():
    return get_active_session()

@st.cache_data(ttl=300)
def get_databases():
    session = get_session()
    results = session.sql("SHOW DATABASES").collect()
    return [str(row["name"]) for row in results]

@st.cache_data(ttl=300)
def get_schemas(database):
    if not database:
        return []
    session = get_session()
    db_name = database.upper() if database.upper() == database else f'"{database}"'
    query = f"SHOW SCHEMAS IN DATABASE {db_name}"
    results = session.sql(query).collect()
    return [str(row["name"]) for row in results if str(row["name"]) != "INFORMATION_SCHEMA"]

def safe_get(row, key, default=""):
    try:
        val = row[key]
        return str(val) if val is not None else default
    except:
        return default

def import_metadata(database, schema):
    session = get_session()
    tables = {}
    debug_info = {"tables": 0, "views": 0, "columns": 0, "pks": 0, "fks": 0, "fk_rows": []}
    if not database or not schema:
        return tables, debug_info
    
    db_name = database.upper() if database.upper() == database else f'"{database}"'
    sch_name = schema.upper() if schema.upper() == schema else f'"{schema}"'
    suffix = f"IN SCHEMA {db_name}.{sch_name}"

    results = session.sql(f"SHOW TABLES {suffix}").collect()
    for row in results:
        tableName = str(row["name"])
        table = Table(tableName, safe_get(row, "comment", ""))
        tables[tableName] = table
        table.label = f"n{len(tables)}"
    debug_info["tables"] = len(tables)

    try:
        results = session.sql(f"SHOW VIEWS {suffix}").collect()
        view_count = 0
        for row in results:
            viewName = str(row["name"])
            if viewName not in tables:
                table = Table(viewName, safe_get(row, "comment", ""))
                tables[viewName] = table
                table.label = f"n{len(tables)}"
                view_count += 1
        debug_info["views"] = view_count
    except:
        pass

    results = session.sql(f"SHOW COLUMNS {suffix}").collect()
    col_count = 0
    for row in results:
        tableName = str(row["table_name"])
        if tableName in tables:
            table = tables[tableName]
            name = str(row["column_name"])
            column = Column(table, name, safe_get(row, "comment", ""))
            table.columns.append(column)
            column.identity = safe_get(row, "autoincrement", "") != ''
            col_count += 1
            try:
                column.setDataType(json.loads(str(row["data_type"])))
            except:
                column.datatype = "unknown"
    debug_info["columns"] = col_count

    try:
        results = session.sql(f"SHOW UNIQUE KEYS {suffix}").collect()
        for row in results:
            tableName = str(row["table_name"])
            if tableName in tables:
                table = tables[tableName]
                column = table.getColumn(str(row["column_name"]))
                if column:
                    constraint = str(row["constraint_name"])
                    if constraint not in table.uniques:
                        table.uniques[constraint] = []
                    table.uniques[constraint].append(column)
                    column.isunique = True
    except:
        pass

    try:
        results = session.sql(f"SHOW PRIMARY KEYS {suffix}").collect()
        pk_count = 0
        for row in results:
            tableName = str(row["table_name"])
            if tableName in tables:
                table = tables[tableName]
                column = table.getColumn(str(row["column_name"]))
                if column:
                    column.ispk = True
                    column.pkconstraint = str(row["constraint_name"])
                    pk_count += 1
                    pos = int(row["key_sequence"]) - 1
                    while len(table.pks) <= pos:
                        table.pks.append(None)
                    table.pks[pos] = column
        for table in tables.values():
            table.pks = [pk for pk in table.pks if pk is not None]
        debug_info["pks"] = pk_count
    except:
        pass

    try:
        results = session.sql(f"SHOW IMPORTED KEYS {suffix}").collect()
        fk_count = 0
        for row in results:
            debug_info["fk_rows"].append(dict(row))
            pktableName = str(row["pk_table_name"])
            fktableName = str(row["fk_table_name"])
            if pktableName in tables and fktableName in tables:
                pktable = tables[pktableName]
                pkcolumn = pktable.getColumn(str(row["pk_column_name"]))
                fktable = tables[fktableName]
                fkcolumn = fktable.getColumn(str(row["fk_column_name"]))
                if pkcolumn and fkcolumn:
                    if safe_get(row, "pk_schema_name", "") == safe_get(row, "fk_schema_name", ""):
                        constraint = str(row["fk_name"])
                        if constraint not in fktable.fks:
                            fktable.fks[constraint] = []
                        fktable.fks[constraint].append(fkcolumn)
                        fkcolumn.fkof = pkcolumn
                        fk_count += 1
        debug_info["fks"] = fk_count
    except Exception as e:
        debug_info["fk_error"] = str(e)

    return tables, debug_info

def create_graph(tables, theme, showColumns, showTypes, useUpperCase):
    s = ('digraph {\n'
        + '  graph [ rankdir="LR" bgcolor="#ffffff" ]\n'
        + f'  node [ style="filled" shape="{theme.shape}" gradientangle="180" ]\n'
        + '  edge [ arrowhead="none" arrowtail="none" dir="both" ]\n\n')

    for name in tables:
        s += tables[name].getDotShape(theme, showColumns, showTypes, useUpperCase)
    s += "\n"
    for name in tables:
        s += tables[name].getDotLinks(theme)
    s += "}\n"
    return s

def create_script(tables, database, schema, useUpperCase):
    db = Table.getClassName(database, useUpperCase)
    sch = f'{db}.{Table.getClassName(schema, useUpperCase)}'
    if useUpperCase:
        s = f"USE DATABASE {db};\nCREATE OR REPLACE SCHEMA {sch};\n\n"
    else:
        s = f"use database {db};\ncreate or replace schema {sch};\n\n"

    for name in tables:
        table = tables[name]
        if useUpperCase:
            s += f"CREATE OR REPLACE TABLE {table.getName(useUpperCase)} (\n"
        else:
            s += f"create or replace table {table.getName(useUpperCase)} (\n"
        
        first = True
        for column in table.columns:
            if first:
                first = False
            else:
                s += ",\n"
            nullable = "" if column.nullable else " NOT NULL" if useUpperCase else " not null"
            datatype = column.datatype.upper() if useUpperCase else column.datatype
            s += f"  {column.getName(useUpperCase)} {datatype}{nullable}"
        
        if table.pks:
            pks = [col.getName(useUpperCase) for col in table.pks]
            pklist = ", ".join(pks)
            if useUpperCase:
                s += f",\n  PRIMARY KEY ({pklist})"
            else:
                s += f",\n  primary key ({pklist})"
        
        s += "\n);\n\n"

    for name in tables:
        table = tables[name]
        for constraint in table.fks:
            fks = table.fks[constraint]
            pktable = fks[0].fkof.table
            fklist = ", ".join([col.getName(useUpperCase) for col in fks])
            pklist = ", ".join([col.fkof.getName(useUpperCase) for col in fks])
            if useUpperCase:
                s += f"ALTER TABLE {table.getName(useUpperCase)}\n"
                s += f"  ADD CONSTRAINT {Table.getClassName(constraint, useUpperCase)}\n"
                s += f"  FOREIGN KEY ({fklist})\n"
                s += f"  REFERENCES {pktable.getName(useUpperCase)} ({pklist});\n\n"
            else:
                s += f"alter table {table.getName(useUpperCase)}\n"
                s += f"  add constraint {Table.getClassName(constraint, useUpperCase)}\n"
                s += f"  foreign key ({fklist})\n"
                s += f"  references {pktable.getName(useUpperCase)} ({pklist});\n\n"
    return s

def get_themes():
    return {
        "Common gray": Theme("#6c6c6c", "#e0e0e0", "#f5f5f5",
            "#e0e0e0", "#000000", "#000000", "rounded", "Mrecord", "#696969", "1"),
        "Blue navy": Theme("#1a5282", "#1a5282", "#ffffff",
            "#1a5282", "#000000", "#ffffff", "rounded", "Mrecord", "#0078d7", "2"),
        "Gray box": Theme("#6c6c6c", "#e0e0e0", "#f5f5f5",
            "#e0e0e0", "#000000", "#000000", "rounded", "record", "#696969", "1")
    }

themes = get_themes()
databases = get_databases()

def on_database_change():
    if "schema_select" in st.session_state:
        del st.session_state["schema_select"]

with st.sidebar:
    st.markdown(":material/schema: **ERD Viewer**")
    st.caption("Visualize database schema relationships")
    st.space("small")
    
    database = st.selectbox('Database', databases, index=0 if databases else None, key="db_select", on_change=on_database_change)
    
    schemas = get_schemas(database) if database else []
    default_idx = schemas.index("PUBLIC") if "PUBLIC" in schemas else (0 if schemas else None)
    schema = st.selectbox('Schema', schemas, index=default_idx, key="schema_select")
    
    st.space("small")
    
    with st.expander(":material/palette: Display options", expanded=False):
        theme = st.selectbox('Theme', list(themes.keys()), index=0)
        showColumns = st.toggle('Show column names', value=True)
        showTypes = st.toggle('Show data types', value=False)
        useUpperCase = st.toggle('Use uppercase', value=False)
    
    st.space("small")
    
    if st.button(":material/refresh: Refresh cache", use_container_width=True):
        st.cache_data.clear()
        st.rerun()

st.title("ERD Viewer")

if not database or not schema:
    with st.container(border=True):
        st.markdown(":material/info: Select a database and schema from the sidebar to view the ERD.")
else:
    col1, col2 = st.columns([3, 1])
    with col1:
        st.caption(f":material/database: {database} :material/chevron_right: {schema}")
    
    with st.spinner('Reading metadata...'):
        tables, debug_info = import_metadata(database, schema)

    if len(tables) == 0:
        with st.container(border=True):
            st.markdown(f":material/warning: No tables found in **{database}.{schema}**")
    else:
        with col2:
            st.caption(f"{len(tables)} objects")
        
        with st.spinner('Generating diagram and script...'):
            graph = create_graph(tables, themes[theme], showColumns, showTypes, useUpperCase)
            script = create_script(tables, database, schema, useUpperCase)

        tabERD, tabDOT, tabScript, tabStats = st.tabs([":material/schema: ERD diagram", ":material/code: DOT code", ":material/edit_document: Create script", ":material/analytics: Statistics"])
        
        with tabERD:
            st.graphviz_chart(graph)
        
        with tabDOT:
            st.code(graph, language="dot", line_numbers=True)
        
        with tabScript:
            st.code(script, language="sql", line_numbers=True)
        
        with tabStats:
            total_columns = sum(len(t.columns) for t in tables.values())
            total_pks = sum(len(t.pks) for t in tables.values())
            total_fks = sum(len(t.fks) for t in tables.values())
            nullable_cols = sum(1 for t in tables.values() for c in t.columns if c.nullable)
            identity_cols = sum(1 for t in tables.values() for c in t.columns if c.identity)
            unique_cols = sum(1 for t in tables.values() for c in t.columns if c.isunique)
            
            col1, col2, col3, col4 = st.columns(4)
            with col1:
                with st.container(border=True):
                    st.metric("Tables", debug_info.get("tables", 0))
            with col2:
                with st.container(border=True):
                    st.metric("Views", debug_info.get("views", 0))
            with col3:
                with st.container(border=True):
                    st.metric("Columns", total_columns)
            with col4:
                with st.container(border=True):
                    st.metric("Relationships", total_fks)
            
            st.space("small")
            
            col1, col2 = st.columns(2)
            
            with col1:
                with st.container(border=True):
                    st.markdown("**:material/key: Keys & constraints**")
                    st.caption(f"Primary keys: {total_pks}")
                    st.caption(f"Foreign keys: {total_fks}")
                    st.caption(f"Unique columns: {unique_cols}")
                    st.caption(f"Identity columns: {identity_cols}")
            
            with col2:
                with st.container(border=True):
                    st.markdown("**:material/format_list_bulleted: Column properties**")
                    st.caption(f"Nullable: {nullable_cols}")
                    st.caption(f"Not nullable: {total_columns - nullable_cols}")
                    if total_columns > 0:
                        st.caption(f"Nullable ratio: {nullable_cols/total_columns*100:.1f}%")
            
            st.space("small")
            
            with st.container(border=True):
                st.markdown("**:material/table: Table details**")
                table_data = []
                for name, t in tables.items():
                    table_data.append({
                        "Table": name,
                        "Columns": len(t.columns),
                        "PKs": len(t.pks),
                        "FKs": len(t.fks),
                        "Comment": t.comment[:50] + "..." if len(t.comment) > 50 else t.comment
                    })
                st.dataframe(table_data, use_container_width=True, hide_index=True)
            
            datatype_counts = {}
            for t in tables.values():
                for c in t.columns:
                    base_type = c.datatype.split("(")[0].upper() if c.datatype else "UNKNOWN"
                    datatype_counts[base_type] = datatype_counts.get(base_type, 0) + 1
            
            if datatype_counts:
                with st.container(border=True):
                    st.markdown("**:material/data_object: Data type distribution**")
                    type_data = [{"Type": k, "Count": v} for k, v in sorted(datatype_counts.items(), key=lambda x: -x[1])]
                    st.bar_chart(type_data, x="Type", y="Count", horizontal=True)
            
            if total_fks == 0:
                st.info("No foreign key relationships found. Define FK constraints to see relationships in the ERD.")
