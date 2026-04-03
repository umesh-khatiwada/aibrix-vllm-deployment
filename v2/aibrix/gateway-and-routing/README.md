# AIBrix Routing Strategy Load Test

A load testing framework for AIBrix gateway routing strategies using [Locust](https://locust.io/). Tracks per-request pod routing, latency, token usage, and fallback behavior via gateway logs.

---

## Project Structure

```
.
├── routing_load_test.py     # Main Locust load test file
├── verify_routing.py        # Post-test CSV analysis & verification script
├── routing_analysis.csv     # Output: per-request routing data (auto-generated)
└── README.md
```

## Reference Link
 - [Gateway Plugins](https://aibrix.readthedocs.io/latest/features/gateway-plugins.html)
 - [AIBrix Router](https://aibrix.readthedocs.io/latest/designs/aibrix-router.html)
---

## Routing Strategies

### `random`
Picks any pod randomly. Expect a ~60/40 split — that's normal statistical variance.
Use this as a **baseline** when you don't care where requests land.

### `least-request`
Sends each request to whichever pod currently has the fewest active requests. In testing, this achieved a near-perfect 50/50 split.
**Best general-purpose strategy** for even load distribution.

### `least-latency`
Routes to the pod that responded fastest recently. Expect it to heavily prefer one pod when one is genuinely faster. Good for **latency-sensitive workloads**.

### `prefix-cache`
Routes requests sharing the same prompt prefix to the same pod, so it can reuse cached KV computation. Cold/new prompts fall back to `least-request`. Will shine when users send **repeated or similar prompts** — like a chatbot with a long system prompt.

### `session-affinity`
Same user always goes to the same pod. Confirmed: user `58200ba1` consistently hit `p9dl6`. Good for **stateful conversations** where the model needs context continuity.

### `vtc-basic` — Virtual Token Credits
Tracks how many tokens each user has consumed and routes heavy users to less busy pods. Distributes across both pods for the same user over time. Good for **fairness** when multiple teams or tenants share the gateway.

### `throughput`
Routes to the pod processing the fewest tokens per second. Currently falls back to random because it requires Prometheus metrics. Once Prometheus is connected, this becomes the **best strategy for heavy generation workloads**.

### `least-kv-cache`
Routes to the pod with the least KV cache pressure. Also falls back to random without Prometheus. Once connected, best for **long-context requests**.

### `least-busy-time`
Routes to the pod that has been idle the longest. Also requires Prometheus. Good for **bursty workloads** with uneven request sizes.

---

## Prerequisites

### Replicas

The routing strategies only work meaningfully with **at least 2 running model pod replicas**. Single-replica deployments will cause all requests to land on the same pod regardless of strategy, making distribution-based strategies (`least-request`, `random`, `least-latency`, etc.) impossible to validate.

Scale your deployment before running the test:

```bash
# Scale the model deployment to 2 replicas
kubectl scale deployment <your-model-deployment> \
  -n default --replicas=2

# Verify both pods are Running
kubectl get pods -n default -l model.aibrix.ai/name=qwen-coder-1-5b-instruct
```

You should see two pods with status `Running` before proceeding. The test script auto-discovers pod IPs at startup and refreshes them every 30 seconds.

### Python dependencies

```bash
pip install locust
```

---

## Running the Load Test

### Light test (2 min, 10 users)
```bash
locust -f routing_load_test.py \
  --host http://134.199.201.56 \
  --users 10 --spawn-rate 2 \
  --run-time 2m --headless
```

### Medium test (5 min, 60 users)
```bash
locust -f routing_load_test.py \
  --host http://134.199.201.56 \
  --users 60 --spawn-rate 10 \
  --run-time 5m --headless \
  --csv=results_medium
```

### Heavy test (10 min, 200 users)
```bash
locust -f routing_load_test.py \
  --host http://134.199.201.56 \
  --users 200 --spawn-rate 50 \
  --run-time 10m --headless \
  --csv=results_heavy
```

---

## Verifying Results

After the test, run the verification script to get a per-strategy breakdown:

```bash
python verify_routing.py
```

Outputs success rate, average latency, pod distribution, and strategy-specific pass/fail checks for `random`, `prefix-cache`, `vtc-basic`, and `least-request`.

---


## Manual curl Test Cases

```bash
# prefix-cache
curl -v http://134.199.201.56/v1/completions \
  -H "Content-Type: application/json" \
  -H "routing-strategy: prefix-cache" \
  -d '{
    "model": "qwen-code-lora",
    "prompt": "write an email",
    "max_tokens": 512,
    "temperature": 0
  }'

# random
curl -v http://134.199.201.56/v1/completions \
  -H "Content-Type: application/json" \
  -H "routing-strategy: random" \
  -d '{
    "model": "qwen-code-lora",
    "prompt": "write an email",
    "max_tokens": 512,
    "temperature": 0
  }'

# least-request
curl -v http://134.199.201.56/v1/completions \
  -H "Content-Type: application/json" \
  -H "routing-strategy: least-request" \
  -d '{
    "model": "qwen-code-lora",
    "prompt": "write an email",
    "max_tokens": 512,
    "temperature": 0
  }'

# throughput
curl -v http://134.199.201.56/v1/completions \
  -H "Content-Type: application/json" \
  -H "routing-strategy: throughput" \
  -d '{
    "model": "qwen-code-lora",
    "prompt": "write an email",
    "max_tokens": 512,
    "temperature": 0
  }'
```

---

## Configuration

Edit the top of `routing_load_test.py` to change targets:

| Variable | Default | Description |
|---|---|---|
| `HOST` | `http://134.199.201.56` | Gateway address |
| `GATEWAY_NAMESPACE` | `aibrix-system` | Namespace for gateway pod |
| `GATEWAY_DEPLOY` | `aibrix-gateway-plugins` | Gateway deployment name |
| `MODEL_NAMESPACE` | `default` | Namespace for model pods |
| `MODEL_LABEL` | `model.aibrix.ai/name=qwen-coder-1-5b-instruct` | Label selector for pods |
| `CSV_FILE` | `routing_analysis.csv` | Output file path |
