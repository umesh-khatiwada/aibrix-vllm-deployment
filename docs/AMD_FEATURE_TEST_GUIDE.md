# AIBrix AMD Feature Testing Guide

This guide provides steps to verify AIBrix features on your AMD cluster.

## 1. Setup Testing Environment
Apply the feature test manifest which includes a secondary model (`llama-3-2-1b-amd`) and a `PodAutoscaler`.

```bash
kubectl apply -f manifests/amd/feature_test.yaml
```

Wait for pods to be ready:
```bash
kubectl get pods -w
```

## 2. Test LLM Gateway Routing

Port-forward the gateway (if not already done):
```bash
kubectl -n envoy-gateway-system port-forward service/envoy-aibrix-system-aibrix-eg-903790dc 8888:80 &
```

### Strategy: Least-Request
```bash
curl http://localhost:8888/v1/completions \
  -H "routing-strategy: least-request" \
  -d '{
    "model": "deepseek-r1-qwen-1b5-amd",
    "prompt": "Explain AIBrix in one sentence.",
    "max_tokens": 50
  }'
```

### Strategy: Prefix-Cache (Verify TTFT)
Run this twice with the same prompt. The second run should have a lower TTFT.
```bash
curl -w "\nTTFT: %{time_starttransfer}\n" http://localhost:8888/v1/completions \
  -H "routing-strategy: prefix-cache" \
  -d '{
    "model": "deepseek-r1-qwen-1b5-amd",
    "prompt": "AIBrix is a cloud-native framework for scalable GenAI inference.",
    "max_tokens": 50
  }'
```

## 3. Test Multi-Model Routing
Verify that the gateway can route to different models based on the `model` field in the request.

### Route to DeepSeek
```bash
curl http://localhost:8888/v1/completions \
  -d '{
    "model": "deepseek-r1-qwen-1b5-amd",
    "prompt": "Hello DeepSeek!",
    "max_tokens": 10
  }'
```

### Route to Llama
```bash
curl http://localhost:8888/v1/completions \
  -d '{
    "model": "llama-3-2-1b-amd",
    "prompt": "Hello Llama!",
    "max_tokens": 10
  }'
```

## 4. Test LLM-Specific Autoscaling
The `PodAutoscaler` is set to `KPA` (Knative Pod Autoscaler) for rapid response.

1. Check initial replicas:
   ```bash
   kubectl get deployment deepseek-r1-qwen-1b5-amd
   ```

2. Generate load (run in multiple terminals or use `ab`/`k6`):
   ```bash
   for i in {1..10}; do curl http://localhost:8888/v1/completions -d '{"model": "deepseek-r1-qwen-1b5-amd", "prompt": "load test", "max_tokens": 100}' & done
   ```

3. Watch replicas scale up:
   ```bash
   kubectl get pods -l model.aibrix.ai/name=deepseek-r1-qwen-1b5-amd -w
   ```

## 5. Verify KV Cache Offloading (Logs)
Check the vLLM logs for DRAM offloading activity:
```bash
kubectl logs -l model.aibrix.ai/name=deepseek-r1-qwen-1b5-amd -c vllm-openai | grep -i "cache"
```
