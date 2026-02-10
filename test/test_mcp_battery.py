"""
MCP Server Battery Test Suite
==============================
Comprehensive test suite for Snowflake MCP Server connectivity and queries.

Requirements:
    pip install PyJWT cryptography requests

Usage:
    python test/test_mcp_battery.py
"""

import jwt
import time
import hashlib
import base64
import requests
import json
from datetime import datetime, timedelta
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend

# Configuration
SNOWFLAKE_ACCOUNT = "SFSEEUROPE-PJOSE_AWS3"
SNOWFLAKE_USER = "SERVICENOW_SVC_USER"
PRIVATE_KEY_PATH = "keys/servicenow_rsa_key.p8"
MCP_ENDPOINT = "https://ra19199.eu-west-3.aws.snowflakecomputing.com/api/v2/databases/TELCO_AI_DB/schemas/NETWORK_ASSURANCE/mcp-servers/TELCO_ASSURANCE_MCP"

# Test Results
results = []
request_responses = []


def load_private_key(key_path):
    with open(key_path, "rb") as key_file:
        return serialization.load_pem_private_key(
            key_file.read(), password=None, backend=default_backend()
        )


def get_public_key_fingerprint(private_key):
    public_key = private_key.public_key()
    public_key_bytes = public_key.public_bytes(
        encoding=serialization.Encoding.DER,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    )
    sha256_hash = hashlib.sha256(public_key_bytes).digest()
    fingerprint = base64.b64encode(sha256_hash).decode('utf-8')
    return f"SHA256:{fingerprint}"


def generate_jwt_token(account, user, private_key):
    fingerprint = get_public_key_fingerprint(private_key)
    qualified_username = f"{account.upper()}.{user.upper()}"
    now = datetime.utcnow()
    
    payload = {
        "iss": f"{qualified_username}.{fingerprint}",
        "sub": qualified_username,
        "iat": now,
        "exp": now + timedelta(minutes=60)
    }
    
    return jwt.encode(payload, private_key, algorithm="RS256")


def run_test(token, test_name, category, method, params):
    """Run a single test and record results."""
    start_time = time.time()
    
    request_body = {
        "jsonrpc": "2.0",
        "id": len(results) + 1,
        "method": method,
        "params": params
    }
    
    response_body = None
    
    try:
        response = requests.post(
            MCP_ENDPOINT,
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {token}",
                "X-Snowflake-Authorization-Token-Type": "KEYPAIR_JWT"
            },
            json=request_body,
            timeout=60
        )
        
        elapsed = round((time.time() - start_time) * 1000)
        status = response.status_code
        
        try:
            body = response.json()
            response_body = body
            is_error = body.get("result", {}).get("isError", False)
            if status == 200 and not is_error:
                result = "PASS"
                details = extract_result_summary(body)
            else:
                result = "FAIL"
                details = str(body)[:200]
        except:
            result = "FAIL"
            details = response.text[:200]
            response_body = {"raw": response.text[:500]}
            
    except requests.exceptions.Timeout:
        elapsed = 60000
        status = 0
        result = "TIMEOUT"
        details = "Request timed out after 60s"
        response_body = {"error": "Timeout"}
    except Exception as e:
        elapsed = round((time.time() - start_time) * 1000)
        status = 0
        result = "ERROR"
        details = str(e)[:200]
        response_body = {"error": str(e)}
    
    results.append({
        "test_name": test_name,
        "category": category,
        "status": status,
        "result": result,
        "time_ms": elapsed,
        "details": details
    })
    
    # Store request/response
    request_responses.append({
        "test_name": test_name,
        "category": category,
        "request": request_body,
        "response": response_body,
        "status_code": status,
        "time_ms": elapsed
    })
    
    # Print progress
    icon = "✅" if result == "PASS" else "❌" if result == "FAIL" else "⏱️"
    print(f"  {icon} {test_name} ({elapsed}ms)")
    
    return result == "PASS"


def extract_result_summary(body):
    """Extract a summary from the MCP response."""
    try:
        content = body.get("result", {}).get("content", [])
        if content and len(content) > 0:
            text = content[0].get("text", "")
            data = json.loads(text)
            if "result_set" in data:
                rows = data["result_set"].get("data", [])
                return f"{len(rows)} rows returned"
            return text[:100]
        return "OK"
    except:
        return "OK"


def generate_report(start_time, end_time):
    """Generate markdown report."""
    total = len(results)
    passed = sum(1 for r in results if r["result"] == "PASS")
    failed = sum(1 for r in results if r["result"] == "FAIL")
    errors = sum(1 for r in results if r["result"] in ("ERROR", "TIMEOUT"))
    
    report = f"""# MCP Server Test Report

**Generated:** {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}  
**Duration:** {round(end_time - start_time, 2)}s  
**Endpoint:** `{MCP_ENDPOINT}`

---

## Summary

| Metric | Value |
|--------|-------|
| Total Tests | {total} |
| Passed | {passed} |
| Failed | {failed} |
| Errors/Timeouts | {errors} |
| Success Rate | {round(passed/total*100, 1)}% |

---

## Results by Category

"""
    
    # Group by category
    categories = {}
    for r in results:
        cat = r["category"]
        if cat not in categories:
            categories[cat] = []
        categories[cat].append(r)
    
    for cat, tests in categories.items():
        cat_passed = sum(1 for t in tests if t["result"] == "PASS")
        report += f"### {cat} ({cat_passed}/{len(tests)} passed)\n\n"
        report += "| Test | Status | Time (ms) | Details |\n"
        report += "|------|--------|-----------|----------|\n"
        
        for t in tests:
            icon = "✅" if t["result"] == "PASS" else "❌"
            details = t["details"][:50] + "..." if len(t["details"]) > 50 else t["details"]
            details = details.replace("|", "\\|").replace("\n", " ")
            report += f"| {t['test_name']} | {icon} {t['result']} | {t['time_ms']} | {details} |\n"
        
        report += "\n"
    
    # Performance summary
    report += """---

## Performance Summary

| Category | Avg Response (ms) | Max Response (ms) |
|----------|-------------------|-------------------|
"""
    
    for cat, tests in categories.items():
        times = [t["time_ms"] for t in tests if t["result"] == "PASS"]
        if times:
            report += f"| {cat} | {round(sum(times)/len(times))} | {max(times)} |\n"
    
    report += """
---

## Test Configuration

| Parameter | Value |
|-----------|-------|
| Account | `SFSEEUROPE-PJOSE_AWS3` |
| User | `SERVICENOW_SVC_USER` |
| Authentication | Key-Pair (JWT/RS256) |
| Database | `TELCO_AI_DB` |
| Schema | `NETWORK_ASSURANCE` |

"""
    
    # Add detailed request/response log
    report += """
---

## Detailed Request/Response Log

"""
    
    for i, rr in enumerate(request_responses, 1):
        report += f"### Test {i}: {rr['test_name']}\n\n"
        report += f"**Category:** {rr['category']}  \n"
        report += f"**Status Code:** {rr['status_code']}  \n"
        report += f"**Response Time:** {rr['time_ms']}ms\n\n"
        
        report += "**Request:**\n```json\n"
        report += json.dumps(rr['request'], indent=2)
        report += "\n```\n\n"
        
        report += "**Response:**\n```json\n"
        resp_str = json.dumps(rr['response'], indent=2)
        if len(resp_str) > 2000:
            resp_str = resp_str[:2000] + "\n... [truncated]"
        report += resp_str
        report += "\n```\n\n---\n\n"
    
    report += "*Report generated by test_mcp_battery.py*\n"
    
    return report


def main():
    print("=" * 60)
    print("MCP Server Battery Test Suite")
    print("=" * 60)
    
    # Load key and generate token
    print("\n[SETUP] Loading credentials...")
    try:
        private_key = load_private_key(PRIVATE_KEY_PATH)
        token = generate_jwt_token(SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER, private_key)
        print("  ✅ JWT token generated")
    except Exception as e:
        print(f"  ❌ Failed: {e}")
        return
    
    start_time = time.time()
    
    # =========================================================================
    # TEST CATEGORY 1: Connectivity
    # =========================================================================
    print("\n[CATEGORY] Connectivity Tests")
    print("-" * 40)
    
    run_test(token, "tools/list", "Connectivity", "tools/list", {})
    
    # =========================================================================
    # TEST CATEGORY 2: Table Queries
    # =========================================================================
    print("\n[CATEGORY] Table Query Tests")
    print("-" * 40)
    
    table_tests = [
        ("ALARMS - Count", "SELECT COUNT(*) as cnt FROM TELCO_AI_DB.NETWORK_ASSURANCE.ALARMS"),
        ("NETWORK_KPI - Count", "SELECT COUNT(*) as cnt FROM TELCO_AI_DB.NETWORK_ASSURANCE.NETWORK_KPI"),
        ("TOPOLOGY - Count", "SELECT COUNT(*) as cnt FROM TELCO_AI_DB.NETWORK_ASSURANCE.TOPOLOGY"),
        ("INCIDENTS - Count", "SELECT COUNT(*) as cnt FROM TELCO_AI_DB.NETWORK_ASSURANCE.INCIDENTS"),
        ("CMDB_CI - Count", "SELECT COUNT(*) as cnt FROM TELCO_AI_DB.NETWORK_ASSURANCE.CMDB_CI"),
        ("SLA_BREACHES - Count", "SELECT COUNT(*) as cnt FROM TELCO_AI_DB.NETWORK_ASSURANCE.SLA_BREACHES"),
        ("ANOMALY_SCORES - Count", "SELECT COUNT(*) as cnt FROM TELCO_AI_DB.NETWORK_ASSURANCE.ANOMALY_SCORES"),
    ]
    
    for name, sql in table_tests:
        run_test(token, name, "Table Queries", "tools/call", {
            "name": "sql_exec_tool",
            "arguments": {"sql": sql}
        })
    
    # =========================================================================
    # TEST CATEGORY 3: Aggregation Queries
    # =========================================================================
    print("\n[CATEGORY] Aggregation Query Tests")
    print("-" * 40)
    
    agg_tests = [
        ("Alarms by Severity", "SELECT severity, COUNT(*) as cnt FROM TELCO_AI_DB.NETWORK_ASSURANCE.ALARMS GROUP BY severity"),
        ("Alarms by Region", "SELECT region, COUNT(*) as cnt FROM TELCO_AI_DB.NETWORK_ASSURANCE.ALARMS GROUP BY region"),
        ("KPI Averages", "SELECT kpi_name, ROUND(AVG(kpi_value),2) as avg FROM TELCO_AI_DB.NETWORK_ASSURANCE.NETWORK_KPI GROUP BY kpi_name"),
        ("Incidents by Priority", "SELECT priority, COUNT(*) as cnt FROM TELCO_AI_DB.NETWORK_ASSURANCE.INCIDENTS GROUP BY priority"),
        ("SLA Penalty Sum", "SELECT SUM(penalty_eur) as total FROM TELCO_AI_DB.NETWORK_ASSURANCE.SLA_BREACHES"),
    ]
    
    for name, sql in agg_tests:
        run_test(token, name, "Aggregations", "tools/call", {
            "name": "sql_exec_tool",
            "arguments": {"sql": sql}
        })
    
    # =========================================================================
    # TEST CATEGORY 4: Filter Queries
    # =========================================================================
    print("\n[CATEGORY] Filter Query Tests")
    print("-" * 40)
    
    filter_tests = [
        ("Major Alarms", "SELECT cell_id, description FROM TELCO_AI_DB.NETWORK_ASSURANCE.ALARMS WHERE severity='MAJOR' LIMIT 5"),
        ("High Anomaly Scores", "SELECT element_id, kpi_name, score FROM TELCO_AI_DB.NETWORK_ASSURANCE.ANOMALY_SCORES WHERE score > 0.8 LIMIT 5"),
        ("Open Incidents", "SELECT number, short_description FROM TELCO_AI_DB.NETWORK_ASSURANCE.INCIDENTS WHERE state='OPEN' LIMIT 5"),
        ("Barcelona KPIs", "SELECT kpi_name, kpi_value FROM TELCO_AI_DB.NETWORK_ASSURANCE.NETWORK_KPI WHERE region='BARCELONA' LIMIT 5"),
    ]
    
    for name, sql in filter_tests:
        run_test(token, name, "Filters", "tools/call", {
            "name": "sql_exec_tool",
            "arguments": {"sql": sql}
        })
    
    # =========================================================================
    # TEST CATEGORY 5: Join Queries
    # =========================================================================
    print("\n[CATEGORY] Join Query Tests")
    print("-" * 40)
    
    join_tests = [
        ("Alarms + Topology", """
            SELECT a.severity, t.element_type, COUNT(*) as cnt 
            FROM TELCO_AI_DB.NETWORK_ASSURANCE.ALARMS a
            JOIN TELCO_AI_DB.NETWORK_ASSURANCE.TOPOLOGY t ON a.cell_id = t.element_id
            GROUP BY a.severity, t.element_type
            LIMIT 10
        """),
        ("Incidents + Topology", """
            SELECT i.priority, i.short_description 
            FROM TELCO_AI_DB.NETWORK_ASSURANCE.INCIDENTS i
            LIMIT 5
        """),
    ]
    
    for name, sql in join_tests:
        run_test(token, name, "Joins", "tools/call", {
            "name": "sql_exec_tool",
            "arguments": {"sql": sql}
        })
    
    # =========================================================================
    # TEST CATEGORY 6: View Queries
    # =========================================================================
    print("\n[CATEGORY] View Query Tests")
    print("-" * 40)
    
    view_tests = [
        ("RADIO_KPI_V", "SELECT * FROM TELCO_AI_DB.NETWORK_ASSURANCE.RADIO_KPI_V LIMIT 5"),
        ("CORE_KPI_V", "SELECT * FROM TELCO_AI_DB.NETWORK_ASSURANCE.CORE_KPI_V LIMIT 5"),
        ("TRANSPORT_KPI_V", "SELECT * FROM TELCO_AI_DB.NETWORK_ASSURANCE.TRANSPORT_KPI_V LIMIT 5"),
        ("ANOMALY_SCORES_V", "SELECT * FROM TELCO_AI_DB.NETWORK_ASSURANCE.ANOMALY_SCORES_V LIMIT 5"),
    ]
    
    for name, sql in view_tests:
        run_test(token, name, "Views", "tools/call", {
            "name": "sql_exec_tool",
            "arguments": {"sql": sql}
        })
    
    # =========================================================================
    # TEST CATEGORY 7: Edge Cases
    # =========================================================================
    print("\n[CATEGORY] Edge Case Tests")
    print("-" * 40)
    
    edge_tests = [
        ("Empty Result", "SELECT * FROM TELCO_AI_DB.NETWORK_ASSURANCE.ALARMS WHERE severity='NONEXISTENT'"),
        ("Large Result (Limited)", "SELECT * FROM TELCO_AI_DB.NETWORK_ASSURANCE.NETWORK_KPI LIMIT 100"),
    ]
    
    for name, sql in edge_tests:
        run_test(token, name, "Edge Cases", "tools/call", {
            "name": "sql_exec_tool",
            "arguments": {"sql": sql}
        })
    
    end_time = time.time()
    
    # Generate report
    print("\n" + "=" * 60)
    print("Generating Report...")
    print("=" * 60)
    
    report = generate_report(start_time, end_time)
    
    report_path = "test/MCP_TEST_REPORT.md"
    with open(report_path, "w") as f:
        f.write(report)
    
    print(f"\n✅ Report saved to: {report_path}")
    
    # Summary
    total = len(results)
    passed = sum(1 for r in results if r["result"] == "PASS")
    print(f"\n📊 Summary: {passed}/{total} tests passed ({round(passed/total*100, 1)}%)")


if __name__ == "__main__":
    main()
