# MCP Server Test Report

**Generated:** 2026-02-11 16:13:52  
**Duration:** 29.08s  
**Endpoint:** `https://ra19199.eu-west-3.aws.snowflakecomputing.com/api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/mcp-servers/TELCO_ASSURANCE_MCP`

---

## Summary

| Metric | Value |
|--------|-------|
| Total Tests | 25 |
| Passed | 25 |
| Failed | 0 |
| Errors/Timeouts | 0 |
| Success Rate | 100.0% |

---

## Results by Category

### Connectivity (1/1 passed)

| Test | Status | Time (ms) | Details |
|------|--------|-----------|----------|
| tools/list | ✅ PASS | 733 | OK |

### Table Queries (7/7 passed)

| Test | Status | Time (ms) | Details |
|------|--------|-----------|----------|
| ALARMS - Count | ✅ PASS | 2093 | 1 rows returned |
| NETWORK_KPI - Count | ✅ PASS | 794 | 1 rows returned |
| TOPOLOGY - Count | ✅ PASS | 773 | 1 rows returned |
| INCIDENTS - Count | ✅ PASS | 943 | 1 rows returned |
| CMDB_CI - Count | ✅ PASS | 1596 | 1 rows returned |
| SLA_BREACHES - Count | ✅ PASS | 754 | 1 rows returned |
| ANOMALY_SCORES - Count | ✅ PASS | 670 | 1 rows returned |

### Aggregations (5/5 passed)

| Test | Status | Time (ms) | Details |
|------|--------|-----------|----------|
| Alarms by Severity | ✅ PASS | 2628 | 3 rows returned |
| Alarms by Region | ✅ PASS | 689 | 1 rows returned |
| KPI Averages | ✅ PASS | 1616 | 15 rows returned |
| Incidents by Priority | ✅ PASS | 728 | 4 rows returned |
| SLA Penalty Sum | ✅ PASS | 1612 | 1 rows returned |

### Filters (4/4 passed)

| Test | Status | Time (ms) | Details |
|------|--------|-----------|----------|
| Major Alarms | ✅ PASS | 617 | 5 rows returned |
| High Anomaly Scores | ✅ PASS | 1634 | 5 rows returned |
| Open Incidents | ✅ PASS | 1593 | 0 rows returned |
| Barcelona KPIs | ✅ PASS | 1860 | 5 rows returned |

### Joins (2/2 passed)

| Test | Status | Time (ms) | Details |
|------|--------|-----------|----------|
| Alarms + Topology | ✅ PASS | 1944 | 3 rows returned |
| Incidents + Topology | ✅ PASS | 608 | 5 rows returned |

### Views (4/4 passed)

| Test | Status | Time (ms) | Details |
|------|--------|-----------|----------|
| RADIO_KPI_V | ✅ PASS | 792 | 5 rows returned |
| CORE_KPI_V | ✅ PASS | 1600 | 5 rows returned |
| TRANSPORT_KPI_V | ✅ PASS | 737 | 5 rows returned |
| ANOMALY_SCORES_V | ✅ PASS | 795 | 5 rows returned |

### Edge Cases (2/2 passed)

| Test | Status | Time (ms) | Details |
|------|--------|-----------|----------|
| Empty Result | ✅ PASS | 628 | 0 rows returned |
| Large Result (Limited) | ✅ PASS | 620 | 100 rows returned |

---

## Performance Summary

| Category | Avg Response (ms) | Max Response (ms) |
|----------|-------------------|-------------------|
| Connectivity | 733 | 733 |
| Table Queries | 1089 | 2093 |
| Aggregations | 1455 | 2628 |
| Filters | 1426 | 1860 |
| Joins | 1276 | 1944 |
| Views | 981 | 1600 |
| Edge Cases | 624 | 628 |

---

## Test Configuration

| Parameter | Value |
|-----------|-------|
| Account | `SFSEEUROPE-PJOSE_AWS3` |
| User | `SERVICENOW_SVC_USER` |
| Authentication | Key-Pair (JWT/RS256) |
| Database | `TELCO_AI_DB` |
| Schema | `NETWORK_ASSURANCE` |


---

## Detailed Request/Response Log

### Test 1: tools/list

**Category:** Connectivity  
**Status Code:** 200  
**Response Time:** 733ms

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/list",
  "params": {}
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "tools": [
      {
        "name": "sql_exec_tool",
        "description": "Execute SQL queries on telecom assurance views for network KPIs, alarms, incidents, and anomaly detection.",
        "title": "SQL Execution Tool",
        "inputSchema": {
          "type": "object",
          "description": "Tool to execute a SQL query.",
          "properties": {
            "sql": {
              "description": "Single SQL query to execute.",
              "type": "string"
            }
          }
        }
      }
    ]
  }
}
```

---

### Test 2: ALARMS - Count

**Category:** Table Queries  
**Status Code:** 200  
**Response Time:** 2093ms

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "SELECT COUNT(*) as cnt FROM TELCO_AI_DB.NETWORK_ASSURANCE.ALARMS"
    }
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"query_id\":\"01c2582d-0001-9123-0001-392601116f26\",\"result_set\":{\"data\":[[\"148\"]],\"resultSetMetaData\":{\"format\":\"jsonv2\",\"numRows\":1,\"partition\":0,\"partitionInfo\":[{\"rowCount\":1,\"uncompressedSize\":7}],\"rowType\":[{\"length\":0,\"name\":\"CNT\",\"nullable\":false,\"precision\":18,\"scale\":0,\"type\":\"fixed\"}]},\"statementHandle\":\"01c2582d-0001-9123-0001-392601116f26\"}}"
      }
    ],
    "isError": false
  }
}
```

---

### Test 3: NETWORK_KPI - Count

**Category:** Table Queries  
**Status Code:** 200  
**Response Time:** 794ms

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "SELECT COUNT(*) as cnt FROM TELCO_AI_DB.NETWORK_ASSURANCE.NETWORK_KPI"
    }
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"query_id\":\"01c2582d-0001-9123-0001-392601116f36\",\"result_set\":{\"data\":[[\"2016903\"]],\"resultSetMetaData\":{\"format\":\"jsonv2\",\"numRows\":1,\"partition\":0,\"partitionInfo\":[{\"rowCount\":1,\"uncompressedSize\":11}],\"rowType\":[{\"length\":0,\"name\":\"CNT\",\"nullable\":false,\"precision\":18,\"scale\":0,\"type\":\"fixed\"}]},\"statementHandle\":\"01c2582d-0001-9123-0001-392601116f36\"}}"
      }
    ],
    "isError": false
  }
}
```

---

### Test 4: TOPOLOGY - Count

**Category:** Table Queries  
**Status Code:** 200  
**Response Time:** 773ms

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "SELECT COUNT(*) as cnt FROM TELCO_AI_DB.NETWORK_ASSURANCE.TOPOLOGY"
    }
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"query_id\":\"01c2582d-0001-9123-0001-392601116f3a\",\"result_set\":{\"data\":[[\"375\"]],\"resultSetMetaData\":{\"format\":\"jsonv2\",\"numRows\":1,\"partition\":0,\"partitionInfo\":[{\"rowCount\":1,\"uncompressedSize\":7}],\"rowType\":[{\"length\":0,\"name\":\"CNT\",\"nullable\":false,\"precision\":18,\"scale\":0,\"type\":\"fixed\"}]},\"statementHandle\":\"01c2582d-0001-9123-0001-392601116f3a\"}}"
      }
    ],
    "isError": false
  }
}
```

---

### Test 5: INCIDENTS - Count

**Category:** Table Queries  
**Status Code:** 200  
**Response Time:** 943ms

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 5,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "SELECT COUNT(*) as cnt FROM TELCO_AI_DB.NETWORK_ASSURANCE.INCIDENTS"
    }
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 5,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"query_id\":\"01c2582d-0001-9161-0001-392601117046\",\"result_set\":{\"data\":[[\"18\"]],\"resultSetMetaData\":{\"format\":\"jsonv2\",\"numRows\":1,\"partition\":0,\"partitionInfo\":[{\"rowCount\":1,\"uncompressedSize\":6}],\"rowType\":[{\"length\":0,\"name\":\"CNT\",\"nullable\":false,\"precision\":18,\"scale\":0,\"type\":\"fixed\"}]},\"statementHandle\":\"01c2582d-0001-9161-0001-392601117046\"}}"
      }
    ],
    "isError": false
  }
}
```

---

### Test 6: CMDB_CI - Count

**Category:** Table Queries  
**Status Code:** 200  
**Response Time:** 1596ms

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 6,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "SELECT COUNT(*) as cnt FROM TELCO_AI_DB.NETWORK_ASSURANCE.CMDB_CI"
    }
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 6,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"query_id\":\"01c2582d-0001-9161-0001-39260111704a\",\"result_set\":{\"data\":[[\"363\"]],\"resultSetMetaData\":{\"format\":\"jsonv2\",\"numRows\":1,\"partition\":0,\"partitionInfo\":[{\"rowCount\":1,\"uncompressedSize\":7}],\"rowType\":[{\"length\":0,\"name\":\"CNT\",\"nullable\":false,\"precision\":18,\"scale\":0,\"type\":\"fixed\"}]},\"statementHandle\":\"01c2582d-0001-9161-0001-39260111704a\"}}"
      }
    ],
    "isError": false
  }
}
```

---

### Test 7: SLA_BREACHES - Count

**Category:** Table Queries  
**Status Code:** 200  
**Response Time:** 754ms

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 7,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "SELECT COUNT(*) as cnt FROM TELCO_AI_DB.NETWORK_ASSURANCE.SLA_BREACHES"
    }
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 7,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"query_id\":\"01c2582d-0001-9161-0001-39260111704e\",\"result_set\":{\"data\":[[\"12\"]],\"resultSetMetaData\":{\"format\":\"jsonv2\",\"numRows\":1,\"partition\":0,\"partitionInfo\":[{\"rowCount\":1,\"uncompressedSize\":6}],\"rowType\":[{\"length\":0,\"name\":\"CNT\",\"nullable\":false,\"precision\":18,\"scale\":0,\"type\":\"fixed\"}]},\"statementHandle\":\"01c2582d-0001-9161-0001-39260111704e\"}}"
      }
    ],
    "isError": false
  }
}
```

---

### Test 8: ANOMALY_SCORES - Count

**Category:** Table Queries  
**Status Code:** 200  
**Response Time:** 670ms

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 8,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "SELECT COUNT(*) as cnt FROM TELCO_AI_DB.NETWORK_ASSURANCE.ANOMALY_SCORES"
    }
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 8,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"query_id\":\"01c2582d-0001-9123-0001-392601116f4e\",\"result_set\":{\"data\":[[\"126\"]],\"resultSetMetaData\":{\"format\":\"jsonv2\",\"numRows\":1,\"partition\":0,\"partitionInfo\":[{\"rowCount\":1,\"uncompressedSize\":7}],\"rowType\":[{\"length\":0,\"name\":\"CNT\",\"nullable\":false,\"precision\":18,\"scale\":0,\"type\":\"fixed\"}]},\"statementHandle\":\"01c2582d-0001-9123-0001-392601116f4e\"}}"
      }
    ],
    "isError": false
  }
}
```

---

### Test 9: Alarms by Severity

**Category:** Aggregations  
**Status Code:** 200  
**Response Time:** 2628ms

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 9,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "SELECT severity, COUNT(*) as cnt FROM TELCO_AI_DB.NETWORK_ASSURANCE.ALARMS GROUP BY severity"
    }
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 9,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"query_id\":\"01c2582d-0001-9161-0001-392601117052\",\"result_set\":{\"data\":[[\"MINOR\",\"90\"],[\"MAJOR\",\"56\"],[\"WARNING\",\"2\"]],\"resultSetMetaData\":{\"format\":\"jsonv2\",\"numRows\":3,\"partition\":0,\"partitionInfo\":[{\"rowCount\":3,\"uncompressedSize\":58}],\"rowType\":[{\"length\":16777216,\"name\":\"SEVERITY\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":0,\"name\":\"CNT\",\"nullable\":false,\"precision\":18,\"scale\":0,\"type\":\"fixed\"}]},\"statementHandle\":\"01c2582d-0001-9161-0001-392601117052\"}}"
      }
    ],
    "isError": false
  }
}
```

---

### Test 10: Alarms by Region

**Category:** Aggregations  
**Status Code:** 200  
**Response Time:** 689ms

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 10,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "SELECT region, COUNT(*) as cnt FROM TELCO_AI_DB.NETWORK_ASSURANCE.ALARMS GROUP BY region"
    }
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 10,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"query_id\":\"01c2582d-0001-9161-0001-392601117056\",\"result_set\":{\"data\":[[\"BARCELONA\",\"148\"]],\"resultSetMetaData\":{\"format\":\"jsonv2\",\"numRows\":1,\"partition\":0,\"partitionInfo\":[{\"rowCount\":1,\"uncompressedSize\":30}],\"rowType\":[{\"length\":16777216,\"name\":\"REGION\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":0,\"name\":\"CNT\",\"nullable\":false,\"precision\":18,\"scale\":0,\"type\":\"fixed\"}]},\"statementHandle\":\"01c2582d-0001-9161-0001-392601117056\"}}"
      }
    ],
    "isError": false
  }
}
```

---

### Test 11: KPI Averages

**Category:** Aggregations  
**Status Code:** 200  
**Response Time:** 1616ms

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 11,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "SELECT kpi_name, ROUND(AVG(kpi_value),2) as avg FROM TELCO_AI_DB.NETWORK_ASSURANCE.NETWORK_KPI GROUP BY kpi_name"
    }
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 11,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"query_id\":\"01c2582d-0001-9123-0001-392601116f62\",\"result_set\":{\"data\":[[\"LTE_RSRQ\",\"-9.8000000000000007\"],[\"PRB_UTIL\",\"54.060000000000002\"],[\"RSRP\",\"-94.530000000000001\"],[\"SINR\",\"17.109999999999999\"],[\"THROUGHPUT\",\"111.16\"],[\"DATA_SESSION_SETUP_TIME\",\"82.879999999999995\"],[\"BACKHAUL_LATENCY\",\"82.299999999999997\"],[\"5G_RSRQ\",\"-9.8000000000000007\"],[\"VOLTE_DROP_RATE\",\"0.87\"],[\"ERAB_DROP_RATE\",\"0.71999999999999997\"],[\"PAGING_SUCCESS\",\"98.469999999999999\"],[\"PACKET_LOSS\",\"0.78000000000000003\"],[\"CPU_UTIL\",\"64.370000000000005\"],[\"MEM_UTIL\",\"70.900000000000006\"],[\"SESSION_FAIL_RATE\",\"0.93999999999999995\"]],\"resultSetMetaData\":{\"format\":\"jsonv2\",\"numRows\":15,\"partition\":0,\"partitionInfo\":[{\"rowCount\":15,\"uncompressedSize\":561}],\"rowType\":[{\"length\":16777216,\"name\":\"KPI_NAME\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":0,\"name\":\"AVG\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"real\"}]},\"statementHandle\":\"01c2582d-0001-9123-0001-392601116f62\"}}"
      }
    ],
    "isError": false
  }
}
```

---

### Test 12: Incidents by Priority

**Category:** Aggregations  
**Status Code:** 200  
**Response Time:** 728ms

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 12,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "SELECT priority, COUNT(*) as cnt FROM TELCO_AI_DB.NETWORK_ASSURANCE.INCIDENTS GROUP BY priority"
    }
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 12,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"query_id\":\"01c2582d-0001-9161-0001-39260111705a\",\"result_set\":{\"data\":[[\"P1\",\"1\"],[\"P2\",\"6\"],[\"P3\",\"9\"],[\"P4\",\"2\"]],\"resultSetMetaData\":{\"format\":\"jsonv2\",\"numRows\":4,\"partition\":0,\"partitionInfo\":[{\"rowCount\":4,\"uncompressedSize\":57}],\"rowType\":[{\"length\":16777216,\"name\":\"PRIORITY\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":0,\"name\":\"CNT\",\"nullable\":false,\"precision\":18,\"scale\":0,\"type\":\"fixed\"}]},\"statementHandle\":\"01c2582d-0001-9161-0001-39260111705a\"}}"
      }
    ],
    "isError": false
  }
}
```

---

### Test 13: SLA Penalty Sum

**Category:** Aggregations  
**Status Code:** 200  
**Response Time:** 1612ms

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 13,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "SELECT SUM(penalty_eur) as total FROM TELCO_AI_DB.NETWORK_ASSURANCE.SLA_BREACHES"
    }
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 13,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"query_id\":\"01c2582d-0001-9123-0001-392601116f66\",\"result_set\":{\"data\":[[\"9900\"]],\"resultSetMetaData\":{\"format\":\"jsonv2\",\"numRows\":1,\"partition\":0,\"partitionInfo\":[{\"rowCount\":1,\"uncompressedSize\":19}],\"rowType\":[{\"length\":0,\"name\":\"TOTAL\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"real\"}]},\"statementHandle\":\"01c2582d-0001-9123-0001-392601116f66\"}}"
      }
    ],
    "isError": false
  }
}
```

---

### Test 14: Major Alarms

**Category:** Filters  
**Status Code:** 200  
**Response Time:** 617ms

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 14,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "SELECT cell_id, description FROM TELCO_AI_DB.NETWORK_ASSURANCE.ALARMS WHERE severity='MAJOR' LIMIT 5"
    }
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 14,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"query_id\":\"01c2582d-0001-9123-0001-392601116f6a\",\"result_set\":{\"data\":[[\"CELL-1202\",\"PRB utilization above 90%\"],[\"CELL-1002\",\"PRB utilization above 90%\"],[\"CELL-1103\",\"PRB utilization above 90%\"],[\"CELL-1201\",\"PRB utilization above 90%\"],[\"CELL-1103\",\"RSRP/RSRQ degradation observed\"]],\"resultSetMetaData\":{\"format\":\"jsonv2\",\"numRows\":5,\"partition\":0,\"partitionInfo\":[{\"rowCount\":5,\"uncompressedSize\":229}],\"rowType\":[{\"length\":16777216,\"name\":\"CELL_ID\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":16777216,\"name\":\"DESCRIPTION\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"}]},\"statementHandle\":\"01c2582d-0001-9123-0001-392601116f6a\"}}"
      }
    ],
    "isError": false
  }
}
```

---

### Test 15: High Anomaly Scores

**Category:** Filters  
**Status Code:** 200  
**Response Time:** 1634ms

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 15,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "SELECT element_id, kpi_name, score FROM TELCO_AI_DB.NETWORK_ASSURANCE.ANOMALY_SCORES WHERE score > 0.8 LIMIT 5"
    }
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 15,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"query_id\":\"01c2582d-0001-9161-0001-392601117062\",\"result_set\":{\"data\":[[\"CELL-1201\",\"PRB_UTIL\",\"0.87\"],[\"CELL-1102\",\"PRB_UTIL\",\"0.85999999999999999\"],[\"CELL-1003\",\"PRB_UTIL\",\"0.92000000000000004\"],[\"CELL-1003\",\"RSRP\",\"0.87\"],[\"CELL-1002\",\"PRB_UTIL\",\"0.92000000000000004\"]],\"resultSetMetaData\":{\"format\":\"jsonv2\",\"numRows\":5,\"partition\":0,\"partitionInfo\":[{\"rowCount\":5,\"uncompressedSize\":215}],\"rowType\":[{\"length\":16777216,\"name\":\"ELEMENT_ID\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":16777216,\"name\":\"KPI_NAME\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":0,\"name\":\"SCORE\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"real\"}]},\"statementHandle\":\"01c2582d-0001-9161-0001-392601117062\"}}"
      }
    ],
    "isError": false
  }
}
```

---

### Test 16: Open Incidents

**Category:** Filters  
**Status Code:** 200  
**Response Time:** 1593ms

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 16,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "SELECT number, short_description FROM TELCO_AI_DB.NETWORK_ASSURANCE.INCIDENTS WHERE state='OPEN' LIMIT 5"
    }
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 16,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"query_id\":\"01c2582d-0001-9123-0001-392601116f76\",\"result_set\":{\"resultSetMetaData\":{\"format\":\"jsonv2\",\"numRows\":0,\"partition\":0,\"partitionInfo\":[{\"rowCount\":0,\"uncompressedSize\":0}],\"rowType\":[{\"length\":16777216,\"name\":\"NUMBER\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":16777216,\"name\":\"SHORT_DESCRIPTION\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"}]},\"statementHandle\":\"01c2582d-0001-9123-0001-392601116f76\"}}"
      }
    ],
    "isError": false
  }
}
```

---

### Test 17: Barcelona KPIs

**Category:** Filters  
**Status Code:** 200  
**Response Time:** 1860ms

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 17,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "SELECT kpi_name, kpi_value FROM TELCO_AI_DB.NETWORK_ASSURANCE.NETWORK_KPI WHERE region='BARCELONA' LIMIT 5"
    }
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 17,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"query_id\":\"01c2582d-0001-9161-0001-39260111706a\",\"result_set\":{\"data\":[[\"PRB_UTIL\",\"56.600000000000001\"],[\"RSRP\",\"-95.5\"],[\"SINR\",\"16.399999999999999\"],[\"THROUGHPUT\",\"120.2\"],[\"VOLTE_DROP_RATE\",\"0.71999999999999997\"]],\"resultSetMetaData\":{\"format\":\"jsonv2\",\"numRows\":5,\"partition\":0,\"partitionInfo\":[{\"rowCount\":5,\"uncompressedSize\":160}],\"rowType\":[{\"length\":16777216,\"name\":\"KPI_NAME\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":0,\"name\":\"KPI_VALUE\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"real\"}]},\"statementHandle\":\"01c2582d-0001-9161-0001-39260111706a\"}}"
      }
    ],
    "isError": false
  }
}
```

---

### Test 18: Alarms + Topology

**Category:** Joins  
**Status Code:** 200  
**Response Time:** 1944ms

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 18,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "\n            SELECT a.severity, t.element_type, COUNT(*) as cnt \n            FROM TELCO_AI_DB.NETWORK_ASSURANCE.ALARMS a\n            JOIN TELCO_AI_DB.NETWORK_ASSURANCE.TOPOLOGY t ON a.cell_id = t.element_id\n            GROUP BY a.severity, t.element_type\n            LIMIT 10\n        "
    }
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 18,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"query_id\":\"01c2582d-0001-9161-0001-392601117076\",\"result_set\":{\"data\":[[\"MAJOR\",\"RADIO_CELL\",\"56\"],[\"MINOR\",\"RADIO_CELL\",\"90\"],[\"WARNING\",\"CORE_NODE\",\"2\"]],\"resultSetMetaData\":{\"format\":\"jsonv2\",\"numRows\":3,\"partition\":0,\"partitionInfo\":[{\"rowCount\":3,\"uncompressedSize\":96}],\"rowType\":[{\"length\":16777216,\"name\":\"SEVERITY\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":16777216,\"name\":\"ELEMENT_TYPE\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":0,\"name\":\"CNT\",\"nullable\":false,\"precision\":18,\"scale\":0,\"type\":\"fixed\"}]},\"statementHandle\":\"01c2582d-0001-9161-0001-392601117076\"}}"
      }
    ],
    "isError": false
  }
}
```

---

### Test 19: Incidents + Topology

**Category:** Joins  
**Status Code:** 200  
**Response Time:** 608ms

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 19,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "\n            SELECT i.priority, i.short_description \n            FROM TELCO_AI_DB.NETWORK_ASSURANCE.INCIDENTS i\n            LIMIT 5\n        "
    }
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 19,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"query_id\":\"01c2582d-0001-9161-0001-39260111707a\",\"result_set\":{\"data\":[[\"P2\",\"Downtown congestion impacting data service\"],[\"P1\",\"Backhaul latency causing voice drops\"],[\"P2\",\"Elevated core CPU impacting session setup\"],[\"P2\",\"Backhaul issue resolved after reroute\"],[\"P3\",\"Evening capacity strain in central district\"]],\"resultSetMetaData\":{\"format\":\"jsonv2\",\"numRows\":5,\"partition\":0,\"partitionInfo\":[{\"rowCount\":5,\"uncompressedSize\":263}],\"rowType\":[{\"length\":16777216,\"name\":\"PRIORITY\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":16777216,\"name\":\"SHORT_DESCRIPTION\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"}]},\"statementHandle\":\"01c2582d-0001-9161-0001-39260111707a\"}}"
      }
    ],
    "isError": false
  }
}
```

---

### Test 20: RADIO_KPI_V

**Category:** Views  
**Status Code:** 200  
**Response Time:** 792ms

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 20,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "SELECT * FROM TELCO_AI_DB.NETWORK_ASSURANCE.RADIO_KPI_V LIMIT 5"
    }
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 20,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"query_id\":\"01c2582d-0001-9123-0001-392601116f86\",\"result_set\":{\"data\":[[\"2026-02-22 11:30:00.000\",\"BARCELONA\",\"CELL-2502\",\"PRB_UTIL\",\"47\",\"%\",\"ERICSSON\",\"4G\"],[\"2026-02-22 11:30:00.000\",\"BARCELONA\",\"CELL-2502\",\"RSRP\",\"-92.299999999999997\",\"dBm\",\"ERICSSON\",\"4G\"],[\"2026-02-22 11:30:00.000\",\"BARCELONA\",\"CELL-2502\",\"SINR\",\"13.5\",\"dB\",\"ERICSSON\",\"4G\"],[\"2026-02-22 11:30:00.000\",\"BARCELONA\",\"CELL-2503\",\"PRB_UTIL\",\"56.600000000000001\",\"%\",\"ERICSSON\",\"5G\"],[\"2026-02-22 11:30:00.000\",\"BARCELONA\",\"CELL-2503\",\"RSRP\",\"-95.400000000000006\",\"dBm\",\"ERICSSON\",\"5G\"]],\"resultSetMetaData\":{\"format\":\"jsonv2\",\"numRows\":5,\"partition\":0,\"partitionInfo\":[{\"rowCount\":5,\"uncompressedSize\":499}],\"rowType\":[{\"length\":0,\"name\":\"TS\",\"nullable\":true,\"precision\":0,\"scale\":9,\"type\":\"timestamp_ntz\"},{\"length\":16777216,\"name\":\"REGION\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":16777216,\"name\":\"CELL_ID\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":16777216,\"name\":\"KPI_NAME\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":0,\"name\":\"KPI_VALUE\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"real\"},{\"length\":16777216,\"name\":\"KPI_UNIT\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":16777216,\"name\":\"VENDOR\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":16777216,\"name\":\"TECH\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"}]},\"statementHandle\":\"01c2582d-0001-9123-0001-392601116f86\"}}"
      }
    ],
    "isError": false
  }
}
```

---

### Test 21: CORE_KPI_V

**Category:** Views  
**Status Code:** 200  
**Response Time:** 1600ms

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 21,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "SELECT * FROM TELCO_AI_DB.NETWORK_ASSURANCE.CORE_KPI_V LIMIT 5"
    }
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 21,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"query_id\":\"01c2582d-0001-9161-0001-39260111707e\",\"result_set\":{\"data\":[[\"2026-02-22 10:10:00.000\",\"BARCELONA\",\"CORE-BCN-01\",\"CPU_UTIL\",\"62.799999999999997\",\"%\",\"NOKIA\",\"CORE\"],[\"2026-02-22 10:10:00.000\",\"BARCELONA\",\"CORE-BCN-01\",\"MEM_UTIL\",\"70.099999999999994\",\"%\",\"NOKIA\",\"CORE\"],[\"2026-02-22 10:10:00.000\",\"BARCELONA\",\"CORE-BCN-01\",\"SESSION_FAIL_RATE\",\"0.82999999999999996\",\"%\",\"NOKIA\",\"CORE\"],[\"2026-02-22 10:10:00.000\",\"BARCELONA\",\"CORE-BCN-02\",\"CPU_UTIL\",\"62.299999999999997\",\"%\",\"HUAWEI\",\"CORE\"],[\"2026-02-22 10:10:00.000\",\"BARCELONA\",\"CORE-BCN-02\",\"MEM_UTIL\",\"69.200000000000003\",\"%\",\"HUAWEI\",\"CORE\"]],\"resultSetMetaData\":{\"format\":\"jsonv2\",\"numRows\":5,\"partition\":0,\"partitionInfo\":[{\"rowCount\":5,\"uncompressedSize\":551}],\"rowType\":[{\"length\":0,\"name\":\"TS\",\"nullable\":true,\"precision\":0,\"scale\":9,\"type\":\"timestamp_ntz\"},{\"length\":16777216,\"name\":\"REGION\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":16777216,\"name\":\"CELL_ID\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":16777216,\"name\":\"KPI_NAME\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":0,\"name\":\"KPI_VALUE\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"real\"},{\"length\":16777216,\"name\":\"KPI_UNIT\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":16777216,\"name\":\"VENDOR\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":16777216,\"name\":\"TECH\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"}]},\"statementHandle\":\"01c2582d-0001-9161-0001-39260111707e\"}}"
      }
    ],
    "isError": false
  }
}
```

---

### Test 22: TRANSPORT_KPI_V

**Category:** Views  
**Status Code:** 200  
**Response Time:** 737ms

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 22,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "SELECT * FROM TELCO_AI_DB.NETWORK_ASSURANCE.TRANSPORT_KPI_V LIMIT 5"
    }
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 22,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"query_id\":\"01c2582d-0001-9123-0001-392601116f8e\",\"result_set\":{\"data\":[[\"2026-02-22 10:05:00.000\",\"BARCELONA\",\"CELL-0102\",\"BACKHAUL_LATENCY\",\"78.200000000000003\",\"ms\",\"ERICSSON\",\"4G\"],[\"2026-02-22 10:05:00.000\",\"BARCELONA\",\"CELL-0102\",\"PACKET_LOSS\",\"0.88\",\"%\",\"ERICSSON\",\"4G\"],[\"2026-02-22 10:05:00.000\",\"BARCELONA\",\"CELL-0202\",\"BACKHAUL_LATENCY\",\"79\",\"ms\",\"NOKIA\",\"4G\"],[\"2026-02-22 10:05:00.000\",\"BARCELONA\",\"CELL-0202\",\"PACKET_LOSS\",\"0.66000000000000003\",\"%\",\"NOKIA\",\"4G\"],[\"2026-02-22 10:05:00.000\",\"BARCELONA\",\"CELL-0302\",\"BACKHAUL_LATENCY\",\"81.299999999999997\",\"ms\",\"ERICSSON\",\"4G\"]],\"resultSetMetaData\":{\"format\":\"jsonv2\",\"numRows\":5,\"partition\":0,\"partitionInfo\":[{\"rowCount\":5,\"uncompressedSize\":532}],\"rowType\":[{\"length\":0,\"name\":\"TS\",\"nullable\":true,\"precision\":0,\"scale\":9,\"type\":\"timestamp_ntz\"},{\"length\":16777216,\"name\":\"REGION\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":16777216,\"name\":\"CELL_ID\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":16777216,\"name\":\"KPI_NAME\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":0,\"name\":\"KPI_VALUE\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"real\"},{\"length\":16777216,\"name\":\"KPI_UNIT\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":16777216,\"name\":\"VENDOR\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":16777216,\"name\":\"TECH\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"}]},\"statementHandle\":\"01c2582d-0001-9123-0001-392601116f8e\"}}"
      }
    ],
    "isError": false
  }
}
```

---

### Test 23: ANOMALY_SCORES_V

**Category:** Views  
**Status Code:** 200  
**Response Time:** 795ms

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 23,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "SELECT * FROM TELCO_AI_DB.NETWORK_ASSURANCE.ANOMALY_SCORES_V LIMIT 5"
    }
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 23,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"query_id\":\"01c2582d-0001-9161-0001-392601117086\",\"result_set\":{\"data\":[[\"2026-02-22 19:30:00.000\",\"BARCELONA\",\"CELL-1001\",\"PRB_UTIL\",\"0.78000000000000003\",\"ANOMALY\",\"v1.0\"],[\"2026-02-22 19:30:00.000\",\"BARCELONA\",\"CELL-1001\",\"RSRP\",\"0.69999999999999996\",\"ANOMALY\",\"v1.0\"],[\"2026-02-22 19:30:00.000\",\"BARCELONA\",\"CELL-1201\",\"PRB_UTIL\",\"0.87\",\"ANOMALY\",\"v1.0\"],[\"2026-02-22 19:30:00.000\",\"BARCELONA\",\"CELL-1201\",\"RSRP\",\"0.60999999999999999\",\"ANOMALY\",\"v1.0\"],[\"2026-02-22 19:30:00.000\",\"BARCELONA\",\"CELL-1102\",\"PRB_UTIL\",\"0.85999999999999999\",\"ANOMALY\",\"v1.0\"]],\"resultSetMetaData\":{\"format\":\"jsonv2\",\"numRows\":5,\"partition\":0,\"partitionInfo\":[{\"rowCount\":5,\"uncompressedSize\":501}],\"rowType\":[{\"length\":0,\"name\":\"TS\",\"nullable\":true,\"precision\":0,\"scale\":9,\"type\":\"timestamp_ntz\"},{\"length\":16777216,\"name\":\"REGION\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":16777216,\"name\":\"ELEMENT_ID\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":16777216,\"name\":\"KPI_NAME\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":0,\"name\":\"SCORE\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"real\"},{\"length\":16777216,\"name\":\"LABEL\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":16777216,\"name\":\"MODEL_VERSION\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"}]},\"statementHandle\":\"01c2582d-0001-9161-0001-392601117086\"}}"
      }
    ],
    "isError": false
  }
}
```

---

### Test 24: Empty Result

**Category:** Edge Cases  
**Status Code:** 200  
**Response Time:** 628ms

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 24,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "SELECT * FROM TELCO_AI_DB.NETWORK_ASSURANCE.ALARMS WHERE severity='NONEXISTENT'"
    }
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 24,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"query_id\":\"01c2582d-0001-9161-0001-39260111708a\",\"result_set\":{\"resultSetMetaData\":{\"format\":\"jsonv2\",\"numRows\":0,\"partition\":0,\"partitionInfo\":[{\"rowCount\":0,\"uncompressedSize\":0}],\"rowType\":[{\"length\":0,\"name\":\"TS\",\"nullable\":true,\"precision\":0,\"scale\":9,\"type\":\"timestamp_ntz\"},{\"length\":16777216,\"name\":\"REGION\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":16777216,\"name\":\"CELL_ID\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":16777216,\"name\":\"ALARM_CODE\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":16777216,\"name\":\"SEVERITY\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":16777216,\"name\":\"DESCRIPTION\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"},{\"length\":16777216,\"name\":\"INCIDENT_NUMBER\",\"nullable\":true,\"precision\":0,\"scale\":0,\"type\":\"text\"}]},\"statementHandle\":\"01c2582d-0001-9161-0001-39260111708a\"}}"
      }
    ],
    "isError": false
  }
}
```

---

### Test 25: Large Result (Limited)

**Category:** Edge Cases  
**Status Code:** 200  
**Response Time:** 620ms

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 25,
  "method": "tools/call",
  "params": {
    "name": "sql_exec_tool",
    "arguments": {
      "sql": "SELECT * FROM TELCO_AI_DB.NETWORK_ASSURANCE.NETWORK_KPI LIMIT 100"
    }
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 25,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"query_id\":\"01c2582d-0001-9161-0001-39260111708e\",\"result_set\":{\"data\":[[\"2026-02-23 17:30:00.000\",\"BARCELONA\",\"SCELL-021\",\"PRB_UTIL\",\"56.600000000000001\",\"%\",\"NOKIA\",\"5G\"],[\"2026-02-23 17:30:00.000\",\"BARCELONA\",\"SCELL-021\",\"RSRP\",\"-95.5\",\"dBm\",\"NOKIA\",\"5G\"],[\"2026-02-23 17:30:00.000\",\"BARCELONA\",\"SCELL-021\",\"SINR\",\"16.399999999999999\",\"dB\",\"NOKIA\",\"5G\"],[\"2026-02-23 17:30:00.000\",\"BARCELONA\",\"SCELL-021\",\"THROUGHPUT\",\"120.2\",\"Mbps\",\"NOKIA\",\"5G\"],[\"2026-02-23 17:30:00.000\",\"BARCELONA\",\"SCELL-021\",\"VOLTE_DROP_RATE\",\"0.71999999999999997\",\"%\",\"NOKIA\",\"5G\"],[\"2026-02-23 17:30:00.000\",\"BARCELONA\",\"SCELL-021\",\"ERAB_DROP_RATE\",\"0.84999999999999998\",\"%\",\"NOKIA\",\"5G\"],[\"2026-02-23 17:30:00.000\",\"BARCELONA\",\"SCELL-021\",\"DATA_SESSION_SETUP_TIME\",\"86.700000000000003\",\"ms\",\"NOKIA\",\"5G\"],[\"2026-02-23 17:30:00.000\",\"BARCELONA\",\"SCELL-021\",\"PAGING_SUCCESS\",\"98.469999999999999\",\"%\",\"NOKIA\",\"5G\"],[\"2026-02-23 17:30:00.000\",\"BARCELONA\",\"SCELL-021\",\"LTE_RSRQ\",\"-7.25\",\"dB\",\"NOKIA\",\"5G\"],[\"2026-02-23 17:30:00.000\",\"BARCELONA\",\"SCELL-021\",\"5G_RSRQ\",\"-7.5300000000000002\",\"dB\",\"NOKIA\",\"5G\"],[\"2026-02-23 17:30:00.000\",\"BARCELONA\",\"SCELL-022\",\"PRB_UTIL\",\"53.299999999999997\",\"%\",\"SAMSUNG\",\"5G\"],[\"2026-02-23 17:30:00.000\",\"BARCELONA\",\"SCELL-022\",\"RSRP\",\"-94.099999999999994\",\"dBm\",\"SAMSUNG\",\"5G\"],[\"2026-02-23 17:30:00.000\",\"BARCELONA\",\"SCELL-022\",\"SINR\",\"16.800000000000001\",\"dB\",\"SAMSUNG\",\"5G\"],[\"2026-02-23 17:30:00.000\",\"BARCELONA\",\"SCELL-022\",\"THROUGHPUT\",\"115.5\",\"Mbps\",\"SAMSUNG\",\"5G\"],[\"2026-02-23 17:30:00.000\",\"BARCELONA\",\"SCELL-022\",\"VOLTE_DROP_RATE\",\"0.76000000000000001\",\"%\",\"SAMSUNG\",\"5G\"],[\"2026-02-23 17:30:00.000\",\"BARCELONA\",\
... [truncated]
```

---

*Report generated by test_mcp_battery.py*
