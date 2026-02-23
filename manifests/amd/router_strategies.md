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

## 2. Least Request Routing
Routes the request to the pod currently processing the fewest active/ongoing requests. Standard connection-level LB strategy.

**cURL Example:**
```bash
curl -X POST http://<gateway-ip>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "routing-strategy: least-request" \
  -d '...'
```

## 3. Throughput Routing
Routes the request to the pod that has processed the lowest total weighted tokens over time, maintaining a fair long-term load balance across hardware.

**cURL Example:**
```bash
curl -X POST http://<gateway-ip>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "routing-strategy: throughput" \
  -d '...'
```

## 4. Prefix-Cache Routing
Optimizes latency and compute for multi-turn conversations or massive common prefixes by routing the request to the specific pod that already holds the matching prompt prefix in its KV Cache.

**cURL Example:**
```bash
curl -X POST http://<gateway-ip>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "routing-strategy: prefix-cache" \
  -d '...'
```

## 5. Prefix-Cache Preble Routing
A more sophisticated prefix-cache approach based on *[Preble: Efficient Distributed Prompt Scheduling](https://arxiv.org/abs/2407.00023)*. It jointly considers both the expected prefix cache hit rate AND the current pod load/wait time before making a decision.

**cURL Example:**
```bash
curl -X POST http://<gateway-ip>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "routing-strategy: prefix-cache-preble" \
  -d '...'
```

## 6. Least Busy Time Routing
Tracks the cumulative busy processing time of inference engines and routes your request to the pod that has the least aggregated busy time.

**cURL Example:**
```bash
curl -X POST http://<gateway-ip>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "routing-strategy: least-busy-time" \
  -d '...'
```

## 7. Least KV Cache Size (VRAM) Routing
Routes the request to the pod with the smallest current KV Cache allocation. Essential for maximizing total cluster batch sizes, preventing nodes from OOMing or thrashing VRAM.

**cURL Example:**
```bash
curl -X POST http://<gateway-ip>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "routing-strategy: least-kv-cache" \
  -d '...'
```

## 8. Least Latency Routing
Routes your request to the pod with the lowest historical average processing latency (time per token or Time To First Token).

**cURL Example:**
```bash
curl -X POST http://<gateway-ip>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "routing-strategy: least-latency" \
  -d '...'
```

## 9. VTC-Basic (Virtual Token Counter)
Hybrid load balancer evaluating fairness based on user token count vs pod utilization. Balances heavily active users against overall system fairness.

**cURL Example:**
```bash
curl -X POST http://<gateway-ip>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "routing-strategy: vtc-basic" \
  -d '...'
```

## 10. PD (Prefill-Decode Disaggregation)
Uses heterogeneous instances by splitting up the processing. One pool of pods runs the fast prefill (prompt processing), and then the KV states are offloaded/transferred to Decode pods for token generation.

**cURL Example:**
```bash
curl -X POST http://<gateway-ip>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "routing-strategy: pd" \
  -d '...'
```

## 11. Session Affinity (Sticky Sessions)
Encodes the target pod's address (IP:Port) into a Base64 value tracked via the `x-session-id` header. On a subsequent request, routing hits the same pod if it is alive. If dead, falls back to a random pod and issues a newly updated `x-session-id`.

**Initial Request (Gateway issues new Session ID in response headers):**
```bash
curl -v -X POST http://<gateway-ip>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "routing-strategy: session-affinity" \
  ...

# You receive response headers:
# x-session-id: <base64-string>
```

**Subsequent Request (Client passes Session ID back):**
```bash
curl -X POST http://<gateway-ip>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "routing-strategy: session-affinity" \
  -H "x-session-id: <base64-string>" \
  -d '...'
```

---

## Setting Default Routes in AIGatewayRoute/HTTPRoute
If you do not want clients to manage headers directly, you can enforce specific AIBrix algorithms natively in your API Gateway by doing header mutations in Envoy.

Example using an `AIGatewayRoute` or standard Gateway API `HTTPRoute` to inject the strategy:

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: enforce-preble-routing
  namespace: envoy-gateway-system
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
