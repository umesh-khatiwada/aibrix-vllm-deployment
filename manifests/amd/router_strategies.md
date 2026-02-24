# AIBrix Advanced Routing Examples

AIBrix Router is an intelligent traffic management component built as an Envoy Gateway extension. Below are examples of how to consume and configure its supported routing strategies by setting the `routing-strategy` HTTP header or configuring proxy routing logic.

## 1. Random Routing
Routes requests indiscriminately to any available pod in the pool. Good for simple load balancing when all pods act exactly the same without any special state (like specific adapters or kv-cache).

**cURL Example:**
```bash
curl -X POST http://<gateway-ip>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "routing-strategy: random" \
  -d '{
    "model": "deepseek-r1-distill-llama-8b",
    "messages": [{"role": "user", "content": "Hello AIBrix"}]
  }'
```

**Manifest Example (Gateway API HTTPRoute):**
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: enforce-random-routing
  namespace: default
spec:
  parentRefs:
    - name: aibrix-ai-gateway
      namespace: envoy-gateway-system
  rules:
    - backendRefs:
        - name: deepseek-r1-distill-llama-8b-backend
          port: 8000
      filters:
        - type: RequestHeaderModifier
          requestHeaderModifier:
            add:
              - name: routing-strategy
                value: random
```

## 2. Least Request Routing
Routes the request to the pod currently processing the fewest active/ongoing requests. Standard connection-level LB strategy.

**cURL Example:**
```bash
curl -X POST http://<gateway-ip>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "routing-strategy: least-request" \
  -d '{
    "model": "deepseek-r1-distill-llama-8b",
    "messages": [{"role": "user", "content": "Are you busy?"}]
  }'
```

**Manifest Example (Gateway API HTTPRoute):**
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: enforce-least-request-routing
  namespace: default
spec:
  parentRefs:
    - name: aibrix-ai-gateway
      namespace: envoy-gateway-system
  rules:
    - backendRefs:
        - name: deepseek-r1-distill-llama-8b-backend
          port: 8000
      filters:
        - type: RequestHeaderModifier
          requestHeaderModifier:
            add:
              - name: routing-strategy
                value: least-request
```

## 3. Throughput Routing
Routes the request to the pod that has processed the lowest total weighted tokens over time, maintaining a fair long-term load balance across hardware.

**cURL Example:**
```bash
curl -X POST http://<gateway-ip>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "routing-strategy: throughput" \
  -d '{
    "model": "deepseek-r1-distill-llama-8b",
    "messages": [{"role": "user", "content": "Explain AIBrix throughput routing."}]
  }'
```

**Manifest Example (Gateway API HTTPRoute):**
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: enforce-throughput-routing
  namespace: default
spec:
  parentRefs:
    - name: aibrix-ai-gateway
      namespace: envoy-gateway-system
  rules:
    - backendRefs:
        - name: deepseek-r1-distill-llama-8b-backend
          port: 8000
      filters:
        - type: RequestHeaderModifier
          requestHeaderModifier:
            add:
              - name: routing-strategy
                value: throughput
```

## 4. Prefix-Cache Routing
Optimizes latency and compute for multi-turn conversations or massive common prefixes by routing the request to the specific pod that already holds the matching prompt prefix in its KV Cache.

**cURL Example:**
```bash
curl -X POST http://<gateway-ip>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "routing-strategy: prefix-cache" \
  -d '{
    "model": "deepseek-r1-distill-llama-8b",
    "messages": [{"role": "user", "content": "What is the capital of Nepal?"}]
  }'
```

**Manifest Example (Gateway API HTTPRoute):**
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: enforce-prefix-cache-routing
  namespace: default
spec:
  parentRefs:
    - name: aibrix-ai-gateway
      namespace: envoy-gateway-system
  rules:
    - backendRefs:
        - name: deepseek-r1-distill-llama-8b-backend
          port: 8000
      filters:
        - type: RequestHeaderModifier
          requestHeaderModifier:
            add:
              - name: routing-strategy
                value: prefix-cache
```

## 5. Prefix-Cache Preble Routing
A more sophisticated prefix-cache approach based on *[Preble: Efficient Distributed Prompt Scheduling](https://arxiv.org/abs/2407.00023)*. It jointly considers both the expected prefix cache hit rate AND the current pod load/wait time before making a decision.

**cURL Example:**
```bash
curl -X POST http://<gateway-ip>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "routing-strategy: prefix-cache-preble" \
  -d '{
    "model": "deepseek-r1-distill-llama-8b",
    "messages": [{"role": "user", "content": "Write a 1000 word essay about the history of preble."}]
  }'
```

**Manifest Example (Gateway API HTTPRoute):**
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: enforce-prefix-cache-preble-routing
  namespace: default
spec:
  parentRefs:
    - name: aibrix-ai-gateway
      namespace: envoy-gateway-system
  rules:
    - backendRefs:
        - name: deepseek-r1-distill-llama-8b-backend
          port: 8000
      filters:
        - type: RequestHeaderModifier
          requestHeaderModifier:
            add:
              - name: routing-strategy
                value: prefix-cache-preble
```

## 6. Least Busy Time Routing
Tracks the cumulative busy processing time of inference engines and routes your request to the pod that has the least aggregated busy time.

**cURL Example:**
```bash
curl -X POST http://<gateway-ip>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "routing-strategy: least-busy-time" \
  -d '{
    "model": "deepseek-r1-distill-llama-8b",
    "messages": [{"role": "user", "content": "Are you busy right now?"}]
  }'
```

**Manifest Example (Gateway API HTTPRoute):**
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: enforce-least-busy-time-routing
  namespace: default
spec:
  parentRefs:
    - name: aibrix-ai-gateway
      namespace: envoy-gateway-system
  rules:
    - backendRefs:
        - name: deepseek-r1-distill-llama-8b-backend
          port: 8000
      filters:
        - type: RequestHeaderModifier
          requestHeaderModifier:
            add:
              - name: routing-strategy
                value: least-busy-time
```

## 7. Least KV Cache Size (VRAM) Routing
Routes the request to the pod with the smallest current KV Cache allocation. Essential for maximizing total cluster batch sizes, preventing nodes from OOMing or thrashing VRAM.

**cURL Example:**
```bash
curl -X POST http://<gateway-ip>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "routing-strategy: least-kv-cache" \
  -d '{
    "model": "deepseek-r1-distill-llama-8b",
    "messages": [{"role": "user", "content": "How much VRAM do you have?"}]
  }'
```

**Manifest Example (Gateway API HTTPRoute):**
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: enforce-least-kv-cache-routing
  namespace: default
spec:
  parentRefs:
    - name: aibrix-ai-gateway
      namespace: envoy-gateway-system
  rules:
    - backendRefs:
        - name: deepseek-r1-distill-llama-8b-backend
          port: 8000
      filters:
        - type: RequestHeaderModifier
          requestHeaderModifier:
            add:
              - name: routing-strategy
                value: least-kv-cache
```

## 8. Least Latency Routing
Routes your request to the pod with the lowest historical average processing latency (time per token or Time To First Token).

**cURL Example:**
```bash
curl -X POST http://<gateway-ip>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "routing-strategy: least-latency" \
  -d '{
    "model": "deepseek-r1-distill-llama-8b",
    "messages": [{"role": "user", "content": "Respond as quickly as possible."}]
  }'
```

**Manifest Example (Gateway API HTTPRoute):**
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: enforce-least-latency-routing
  namespace: default
spec:
  parentRefs:
    - name: aibrix-ai-gateway
      namespace: envoy-gateway-system
  rules:
    - backendRefs:
        - name: deepseek-r1-distill-llama-8b-backend
          port: 8000
      filters:
        - type: RequestHeaderModifier
          requestHeaderModifier:
            add:
              - name: routing-strategy
                value: least-latency
```

## 9. VTC-Basic (Virtual Token Counter)
Hybrid load balancer evaluating fairness based on user token count vs pod utilization. Balances heavily active users against overall system fairness.

**cURL Example:**
```bash
curl -X POST http://<gateway-ip>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "routing-strategy: vtc-basic" \
  -d '{
    "model": "deepseek-r1-distill-llama-8b",
    "messages": [{"role": "user", "content": "Hello VTC balancer!"}]
  }'
```

**Manifest Example (Gateway API HTTPRoute):**
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: enforce-vtc-basic-routing
  namespace: default
spec:
  parentRefs:
    - name: aibrix-ai-gateway
      namespace: envoy-gateway-system
  rules:
    - backendRefs:
        - name: deepseek-r1-distill-llama-8b-backend
          port: 8000
      filters:
        - type: RequestHeaderModifier
          requestHeaderModifier:
            add:
              - name: routing-strategy
                value: vtc-basic
```

## 10. PD (Prefill-Decode Disaggregation)
Uses heterogeneous instances by splitting up the processing. One pool of pods runs the fast prefill (prompt processing), and then the KV states are offloaded/transferred to Decode pods for token generation.

**cURL Example:**
```bash
curl -X POST http://<gateway-ip>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "routing-strategy: pd" \
  -d '{
    "model": "deepseek-r1-distill-llama-8b",
    "messages": [{"role": "user", "content": "Split this prefill and decode."}]
  }'
```

**Manifest Example (Gateway API HTTPRoute):**
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: enforce-pd-routing
  namespace: default
spec:
  parentRefs:
    - name: aibrix-ai-gateway
      namespace: envoy-gateway-system
  rules:
    - backendRefs:
        - name: deepseek-r1-distill-llama-8b-backend
          port: 8000
      filters:
        - type: RequestHeaderModifier
          requestHeaderModifier:
            add:
              - name: routing-strategy
                value: pd
```

## 11. Session Affinity (Sticky Sessions)
Encodes the target pod's address (IP:Port) into a Base64 value tracked via the `x-session-id` header. On a subsequent request, routing hits the same pod if it is alive. If dead, falls back to a random pod and issues a newly updated `x-session-id`.

**Initial cURL Request (Gateway issues new Session ID in response headers):**
```bash
curl -v -X POST http://<gateway-ip>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "routing-strategy: session-affinity" \
  -d '{
    "model": "deepseek-r1-distill-llama-8b",
    "messages": [{"role": "user", "content": "Start session"}]
  }'

# You receive response headers including:
# x-session-id: <base64-string>
```

**Subsequent cURL Request (Client passes Session ID back):**
```bash
curl -v -X POST http://<gateway-ip>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "routing-strategy: session-affinity" \
  -H "x-session-id: <base64-string>" \
  -d '{
    "model": "deepseek-r1-distill-llama-8b",
    "messages": [{"role": "user", "content": "Continue session"}]
  }'
```

**Manifest Example (Gateway API HTTPRoute):**
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: enforce-session-affinity-routing
  namespace: default
spec:
  parentRefs:
    - name: aibrix-ai-gateway
      namespace: envoy-gateway-system
  rules:
    - backendRefs:
        - name: deepseek-r1-distill-llama-8b-backend
          port: 8000
      filters:
        - type: RequestHeaderModifier
          requestHeaderModifier:
            add:
              - name: routing-strategy
                value: session-affinity
```
