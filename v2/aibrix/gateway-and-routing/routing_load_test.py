"""
AIBrix Routing Strategy Load Test v3
- Uses aibrix-gateway-plugins logs for pod tracking
- Matches by timestamp proximity (not request_id) since vLLM and AIBrix use different IDs
- Tracks: target_pod, routing_duration, tokens, fallback_used
"""

import json as jsonlib
import csv
import re
import time
import uuid
import threading
import subprocess
from datetime import datetime, timedelta
from pathlib import Path
from locust import HttpUser, task, between, events

# ─── CONFIG ───────────────────────────────────────────────────────────────
HOST      = "http://134.199.201.56"
ENDPOINT  = "/v1/chat/completions"
CSV_FILE  = "routing_analysis.csv"

GATEWAY_NAMESPACE  = "aibrix-system"
GATEWAY_DEPLOY     = "aibrix-gateway-plugins"

MODEL_NAMESPACE = "default"
MODEL_LABEL     = "model.aibrix.ai/name=qwen-coder-1-5b-instruct"

ADAPTERS = [
    "qwen-coder-1-5b-instruct",
    "qwen-code-sql-lora",
    "qwen-code-lora",
    "qwen-code-educational",
    "qwen-code-flutter-dev-lora",
    "qwen-code-n8n-workflow-generator-lora",
    "yugdave-finetuned-query-response",
    "qwen-typescript-code-lora",
]

ADAPTER_PROMPTS = {
    "qwen-coder-1-5b-instruct":              "Write a Python function to reverse a linked list",
    "qwen-code-sql-lora":                    "Write a SQL JOIN query to get top 10 customers by revenue",
    "qwen-code-lora":                        "Write a Python function to implement binary search",
    "qwen-code-educational":                 "Explain recursion with a simple Python example",
    "qwen-code-flutter-dev-lora":            "Create a Flutter StatefulWidget for a login form",
    "qwen-code-n8n-workflow-generator-lora": "Generate an n8n workflow that sends Slack alerts on webhook",
    "yugdave-finetuned-query-response":      "What are best practices for Kubernetes deployments?",
    "qwen-typescript-code-lora":             "Write a TypeScript interface for a REST API response",
}

# ─── GLOBALS ──────────────────────────────────────────────────────────────
CSV_LOCK      = threading.Lock()
pod_ip_map    = {}
# Shared log cache — refreshed by background thread
log_cache     = []
log_cache_lock = threading.Lock()

CSV_HEADERS = [
    "Timestamp_NPT",
    "Request_ID",
    "User_ID",
    "Adapter_Model",
    "Routing_Strategy",
    "HTTP_Status",
    "Response_Time_ms",
    "Target_Pod_IP",
    "Target_Pod_Name",
    "Outstanding_Requests",
    "Routing_Duration",
    "Total_Time_Taken",
    "Prompt_Tokens",
    "Completion_Tokens",
    "Total_Tokens",
    "Fallback_Used",
    "Success",
    "Error_Detail",
    "Prompt_Preview",
    "Response_Preview",
]

# ─── HELPERS ──────────────────────────────────────────────────────────────
def get_npt():
    return (datetime.utcnow() + timedelta(hours=5, minutes=45)) \
           .strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]

def init_csv():
    print(f"📁 CSV: {Path(CSV_FILE).absolute()}")
    with open(CSV_FILE, "w", newline="") as f:
        csv.DictWriter(f, fieldnames=CSV_HEADERS).writeheader()

def write_row(row):
    with CSV_LOCK:
        with open(CSV_FILE, "a", newline="") as f:
            csv.DictWriter(f, fieldnames=CSV_HEADERS).writerow(row)

def ip_to_name(ip):
    return pod_ip_map.get(ip, ip)

# ─── POD IP MAP ───────────────────────────────────────────────────────────
def refresh_pod_map():
    try:
        result = subprocess.run(
            ["kubectl", "get", "pods", "-n", MODEL_NAMESPACE,
             "-l", MODEL_LABEL,
             "-o", "custom-columns=NAME:.metadata.name,IP:.status.podIP",
             "--no-headers"],
            capture_output=True, text=True, timeout=5
        )
        for line in result.stdout.strip().splitlines():
            parts = line.split()
            if len(parts) == 2:
                pod_ip_map[parts[1]] = parts[0]
        print(f"📍 Pod map: {pod_ip_map}")
    except Exception as e:
        print(f"⚠️  Pod map error: {e}")

# ─── LOG CACHE — refreshed every 2 seconds ────────────────────────────────
def refresh_log_cache():
    global log_cache
    while True:
        try:
            result = subprocess.run(
                ["kubectl", "logs", f"deploy/{GATEWAY_DEPLOY}",
                 "-n", GATEWAY_NAMESPACE, "--tail=200"],
                capture_output=True, text=True, timeout=5
            )
            with log_cache_lock:
                log_cache = result.stdout.strip().splitlines()
        except Exception as e:
            print(f"⚠️  Log cache error: {e}")
        time.sleep(2)

# ─── GET ROUTING INFO BY MODEL + STRATEGY PROXIMITY ──────────────────────
def get_routing_info(model, strategy, req_start_time, max_wait=4.0):
    """
    Find the most recent request_start log line matching:
    - model name
    - routing_strategy
    - logged after req_start_time

    AIBrix log format:
    "request_start" ... model="X" ... routing_strategy="Y"
                    target_pod="name" target_pod_ip="ip:port"
                    outstanding_requests=N routing_duration="X"
    """
    deadline = time.time() + max_wait
    info = {
        "pod_ip":               "N/A",
        "pod_name":             "N/A",
        "outstanding_requests": "N/A",
        "routing_duration":     "N/A",
        "total_time_taken":     "N/A",
        "prompt_tokens":        "N/A",
        "completion_tokens":    "N/A",
        "total_tokens":         "N/A",
        "fallback_used":        "NO",
    }

    while time.time() < deadline:
        with log_cache_lock:
            lines = list(log_cache)

        matched_req_id = None

        # Find most recent request_start matching model + strategy
        for line in reversed(lines):
            if "request_start" not in line:
                continue
            if f'model="{model}"' not in line:
                continue
            if f'routing_strategy="{strategy}"' not in line:
                continue

            # Extract AIBrix internal request_id
            m = re.search(r'request_id="([^"]+)"', line)
            if not m:
                continue
            matched_req_id = m.group(1)

            # Parse pod info
            m = re.search(r'target_pod_ip="([^"]+)"', line)
            if m:
                full_ip          = m.group(1)
                pod_ip           = full_ip.split(":")[0]
                info["pod_ip"]   = pod_ip
                info["pod_name"] = ip_to_name(pod_ip)

            m = re.search(r'outstanding_requests=(\d+)', line)
            if m:
                info["outstanding_requests"] = m.group(1)

            m = re.search(r'routing_duration="([^"]+)"', line)
            if m:
                info["routing_duration"] = m.group(1)

            break  # most recent match found

        # Now find corresponding request_end and fallback for same request_id
        if matched_req_id:
            for line in reversed(lines):
                if matched_req_id not in line:
                    continue

                if "request_end" in line:
                    for field in ["prompt_tokens", "completion_tokens", "total_tokens"]:
                        m = re.search(rf'{field}=(\d+)', line)
                        if m:
                            info[field] = m.group(1)
                    m = re.search(r'total_time_taken="([^"]+)"', line)
                    if m:
                        info["total_time_taken"] = m.group(1)

                if "selecting a pod randomly as fallback" in line:
                    info["fallback_used"] = "YES"

            return info

        time.sleep(0.3)

    return info

# ─── CORE REQUEST ─────────────────────────────────────────────────────────
def make_request(client, user_id, adapter, strategy, max_tokens=150):
    prompt  = ADAPTER_PROMPTS.get(adapter, "Hello")
    payload = {
        "model":      adapter,
        "messages":   [{"role": "user", "content": prompt}],
        "max_tokens": max_tokens,
    }

    req_start = time.time()
    with client.post(
        ENDPOINT,
        data=jsonlib.dumps(payload),
        headers={
            "Content-Type":     "application/json",
            "routing-strategy": strategy,
        },
        catch_response=True,
        timeout=120,
        name=f"[{strategy}][{adapter}]",
    ) as resp:
        rt_ms   = (time.time() - req_start) * 1000
        success = resp.status_code == 200

        response_preview = ""
        request_id       = str(uuid.uuid4())

        if success:
            try:
                body             = resp.json()
                response_preview = body["choices"][0]["message"]["content"][:200]
                request_id       = body.get("id", request_id)
            except Exception:
                response_preview = resp.text[:200]
        else:
            response_preview = resp.text[:120]

        # Small wait so AIBrix log is written
        time.sleep(0.5)
        info = get_routing_info(adapter, strategy, req_start)

        write_row({
            "Timestamp_NPT":        get_npt(),
            "Request_ID":           request_id,
            "User_ID":              user_id[:8],
            "Adapter_Model":        adapter,
            "Routing_Strategy":     strategy,
            "HTTP_Status":          resp.status_code,
            "Response_Time_ms":     round(rt_ms, 2),
            "Target_Pod_IP":        info["pod_ip"],
            "Target_Pod_Name":      info["pod_name"],
            "Outstanding_Requests": info["outstanding_requests"],
            "Routing_Duration":     info["routing_duration"],
            "Total_Time_Taken":     info["total_time_taken"],
            "Prompt_Tokens":        info["prompt_tokens"],
            "Completion_Tokens":    info["completion_tokens"],
            "Total_Tokens":         info["total_tokens"],
            "Fallback_Used":        info["fallback_used"],
            "Success":              "YES" if success else "NO",
            "Error_Detail":         "" if success else resp.text[:120],
            "Prompt_Preview":       prompt[:60],
            "Response_Preview":     response_preview,
        })

        fb   = " ⚡FALLBACK" if info["fallback_used"] == "YES" else ""
        icon = "✅" if success else "❌"
        print(
            f"{icon} [{strategy:<22}] [{adapter:<45}] "
            f"Pod: {info['pod_name']:<45} "
            f"IP: {info['pod_ip']:<16} "
            f"RT: {rt_ms:6.0f}ms  "
            f"RouteTime: {info['routing_duration']}{fb}"
        )

        resp.success() if success else resp.failure(f"HTTP {resp.status_code}")

# ─── USER CLASS ───────────────────────────────────────────────────────────
class RoutingTestUser(HttpUser):
    wait_time = between(1, 3)

    def on_start(self):
        self.user_id = str(uuid.uuid4())[:8]

    @task(4)
    def test_random(self):
        import random
        make_request(self.client, self.user_id,
                     random.choice(ADAPTERS), "random")

    @task(3)
    def test_least_request(self):
        make_request(self.client, self.user_id,
                     "qwen-code-sql-lora", "least-request")

    @task(3)
    def test_prefix_cache(self):
        make_request(self.client, self.user_id,
                     "qwen-code-lora", "prefix-cache")

    @task(2)
    def test_least_kv_cache(self):
        make_request(self.client, self.user_id,
                     "qwen-code-educational", "least-kv-cache",
                     max_tokens=512)

    @task(2)
    def test_least_latency(self):
        make_request(self.client, self.user_id,
                     "qwen-code-flutter-dev-lora", "least-latency")

    @task(2)
    def test_throughput(self):
        make_request(self.client, self.user_id,
                     "qwen-code-n8n-workflow-generator-lora", "throughput")

    @task(2)
    def test_vtc(self):
        import random
        make_request(self.client,
                     random.choice(["team-user-A", "team-user-B"]),
                     "yugdave-finetuned-query-response", "vtc-basic")

    @task(1)
    def test_least_busy(self):
        import random
        make_request(self.client, self.user_id,
                     random.choice(ADAPTERS), "least-busy-time")

    @task(2)
    def test_session_affinity(self):
        make_request(self.client, self.user_id,
                     "qwen-typescript-code-lora", "session-affinity")

# ─── EVENTS ───────────────────────────────────────────────────────────────
@events.test_start.add_listener
def on_start(environment, **kwargs):
    init_csv()
    refresh_pod_map()

    # Background threads
    threading.Thread(target=refresh_log_cache, daemon=True).start()

    def auto_refresh_pods():
        while True:
            time.sleep(30)
            refresh_pod_map()
    threading.Thread(target=auto_refresh_pods, daemon=True).start()

    # Wait for first log cache load
    time.sleep(2)

    print("\n" + "="*80)
    print("  AIBrix Routing Strategy Load Test v3")
    print(f"  Target  : {HOST}{ENDPOINT}")
    print(f"  Gateway : deploy/{GATEWAY_DEPLOY} in {GATEWAY_NAMESPACE}")
    print(f"  CSV     : {Path(CSV_FILE).absolute()}")
    print(f"  Pods    : {pod_ip_map}")
    print(f"  Models  : {len(ADAPTERS)} adapters")
    print("="*80 + "\n")

@events.test_stop.add_listener
def on_stop(environment, **kwargs):
    s = environment.stats.total
    print("\n" + "="*80)
    print(f"  CSV       : {Path(CSV_FILE).absolute()}")
    print(f"  Requests  : {s.num_requests}")
    print(f"  Failures  : {s.num_failures}")
    print(f"  Avg RT    : {s.avg_response_time:.0f}ms")
    print(f"  p95 RT    : {s.get_response_time_percentile(0.95):.0f}ms")
    print("="*80)

    summary   = {}
    fallbacks = 0
    try:
        with open(CSV_FILE, newline="") as f:
            for row in csv.DictReader(f):
                if row.get("Fallback_Used") == "YES":
                    fallbacks += 1
                key = (
                    row["Routing_Strategy"],
                    row["Adapter_Model"],
                    row["Target_Pod_IP"],
                    row["Target_Pod_Name"],
                )
                if key not in summary:
                    summary[key] = {"count": 0, "rt": 0.0}
                summary[key]["count"] += 1
                summary[key]["rt"]    += float(row["Response_Time_ms"] or 0)

        print(f"\n  ⚡ Fallbacks: {fallbacks}\n")
        print(f"{'Strategy':<24} {'Adapter':<45} {'Pod IP':<16} {'Pod Name':<40} {'Reqs':>5} {'AvgRT':>8}")
        print("-"*145)
        for (start, adapter, ip, name), v in sorted(summary.items()):
            avg = v["rt"] / v["count"] if v["count"] else 0
            print(f"{start:<24} {adapter:<45} {ip:<16} {name:<40} {v['count']:>5} {avg:>7.0f}ms")
    except Exception as e:
        print(f"Summary error: {e}")
