# AIBrix Multi-Model Routing Guide

This guide demonstrates how AIBrix handles routing to multiple models through a single entry point (AI Gateway).

## 1. Multi-Model Deployment
On a resource-constrained cluster (like a single GPU node), you can deploy multiple models by sharing the GPU.

Apply the multi-model manifest:
```bash
kubectl apply -f manifests/amd/multi_model_amd.yaml
```

This deploys:
1.  **DeepSeek-R1-Qwen-1.5B** (`deepseek-r1-qwen-1b5-amd`)
2.  **Llama-3.2-1B** (`llama-3-2-1b-amd`)

## 2. How Routing Works
AIBrix uses **LLM-aware routing**. When you send a request to the AI Gateway, the AIBrix Gateway plugin:
1.  Parses the JSON body to extract the `model` field.
2.  Injects a `model` header into the request.
3.  Match the request against an `HTTPRoute` created for that model.

## 3. Testing Routing

Port-forward the gateway:
```bash
kubectl -n envoy-gateway-system port-forward service/envoy-aibrix-system-aibrix-eg-903790dc 8888:80 &
```

### Route to DeepSeek
```bash
curl http://localhost:8888/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-r1-qwen-1b5-amd",
    "prompt": "The capital of France is",
    "max_tokens": 5
  }'
```

### Route to Llama
```bash
curl http://localhost:8888/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama-3-2-1b-amd",
    "prompt": "The capital of Germany is",
    "max_tokens": 5
  }'
```

## 4. Verifying Routing Targets
You can verify which pod handled the request by checking the logs of the `aibrix-runtime` sidecar:

```bash
# Check DeepSeek logs
kubectl logs -l model.aibrix.ai/name=deepseek-r1-qwen-1b5-amd -c aibrix-runtime

# Check Llama logs
kubectl logs -l model.aibrix.ai/name=llama-3-2-1b-amd -c aibrix-runtime
```

## 5. Advanced: Model Alias & Weighting
You can also configure `HTTPRoute` to route a single alias to multiple model versions or use weights for A/B testing.
AIBrix automatically creates a router for each model labeled with `model.aibrix.ai/name`.
