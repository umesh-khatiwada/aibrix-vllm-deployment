# Multi-LoRA Adapter Testing Guide

This guide explains how to deploy and test multiple LoRA adapters served from a single base model (`qwen-coder-1-5b-instruct`) using AIBrix `ModelAdapter` resources.

## How It Works

All 7 adapters share a **single base model deployment**. AIBrix dynamically loads/unloads adapters at runtime via the `aibrix-runtime` sidecar. You select which adapter to use per-request by passing its `ModelAdapter` name as the model in your request.

```
Client Request (model: "qwen-code-sql-lora")
        ↓
  AIBrix Gateway / vLLM
        ↓
  Base Model: qwen-coder-1-5b-instruct
        + LoRA Adapter: qwen-code-sql-lora  ← loaded dynamically
```

## Available Adapters

| # | Name | Adapter | Use Case |
|---|------|---------|----------|
| 1 | `qwen-code-lora` | ai-blond/Qwen-Qwen2.5-Coder-1.5B-Instruct-lora | General code generation |
| 2 | `qwen-typescript-code-lora` | muzaffermut/Qwen2.5-Coder-1.5B-Deep-LoRA | TypeScript / deep code tasks |
| 3 | `yugdave-finetuned-query-response` | yugdave/qwen-1.5b-finetuned-query-response | Query & response fine-tuning |
| 4 | `qwen-code-educational` | Beebey/qwen-coder-1.5b-educational | Educational code explanations |
| 5 | `qwen-code-sql-lora` | faizaltkl/qwen-2.5-coder-sql-lora | SQL generation |
| 6 | `qwen-code-flutter-dev-lora` | sumitndev/flutter-dev-lora | Flutter / Dart development |
| 7 | `qwen-code-n8n-workflow-generator-lora` | Nishan30/n8n-workflow-generator | n8n workflow generation |

## Folder Structure

```
lora-adapters/
├── qwen-model.yaml                          # Base model Deployment, Service, PVC
├── adapters/
│   ├── qwen-code-lora.yaml                  # Adapter 1 - General code
│   ├── qwen-typescript-code-lora.yaml       # Adapter 2 - TypeScript
│   ├── yugdave-finetuned-query-response.yaml # Adapter 3 - Query/response
│   ├── qwen-code-educational.yaml           # Adapter 4 - Educational
│   ├── qwen-code-sql-lora.yaml              # Adapter 5 - SQL
│   ├── qwen-code-flutter-dev-lora.yaml      # Adapter 6 - Flutter
│   └── qwen-code-n8n-workflow-generator-lora.yaml # Adapter 7 - n8n
```

## Deployment

### 1. Deploy the Base Model

```sh
kubectl apply -f qwen-model.yaml
```

Wait for the model pod to be ready:
```sh
kubectl wait --timeout=5m -n default deployment/qwen-coder-1-5b-instruct --for=condition=Available
```

### 2. Deploy All Adapters

```sh
kubectl apply -f adapters/
```

Or apply individually:
```sh
kubectl apply -f adapters/qwen-code-lora.yaml
kubectl apply -f adapters/qwen-code-sql-lora.yaml
kubectl apply -f adapters/qwen-code-flutter-dev-lora.yaml
# ... etc
```

### 3. Verify Adapters Are Registered

```sh
kubectl get modeladapter -n default
```

Expected output:
```
NAME                                    BASEMODEL                   STATUS
kubectl get modeladapters -A
NAMESPACE   NAME                                    PHASE     DESIRED   READY   CANDIDATES   MODEL PATH                                                     AGE
default     qwen-code-educational                   Running   1         1       1            huggingface://Beebey/qwen-coder-1.5b-educational               9m56s
default     qwen-code-flutter-dev-lora              Running   1         1       1            huggingface://sumitndev/flutter-dev-lora                       9m56s
default     qwen-code-lora                          Running   1         1       1            huggingface://ai-blond/Qwen-Qwen2.5-Coder-1.5B-Instruct-lora   9m56s
default     qwen-code-n8n-workflow-generator-lora   Running   1         1       1            huggingface://Nishan30/n8n-workflow-generator                  9m56s
default     qwen-code-sql-lora                      Running   1         1       1            huggingface://faizaltkl/qwen-2.5-coder-sql-lora                9m56s
default     qwen-typescript-code-lora               Running   1         1       1            huggingface://muzaffermut/Qwen2.5-Coder-1.5B-Deep-LoRA         9m56s
default     yugdave-finetuned-query-response        Running   1         1       1            huggingface://yugdave/qwen-1.5b-finetuned-query-response       9m56s
```

## Testing Each Adapter

Switch adapters per-request by changing the `model` field to the `ModelAdapter` name.

### Port Forward (Local Testing)

```sh
kubectl port-forward -n default svc/qwen-coder-1-5b-instruct 8000:8000
```

---

### Adapter 1 — General Code (`qwen-code-lora`)

```sh
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen-code-lora",
    "messages": [{"role": "user", "content": "Write a Python function to reverse a linked list."}],
    "temperature": 0.2
  }'
```

---

### Adapter 2 — TypeScript (`qwen-typescript-code-lora`)

```sh
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen-typescript-code-lora",
    "messages": [{"role": "user", "content": "Write a TypeScript interface for a User with id, name, and email fields."}],
    "temperature": 0.2
  }'
```

---

### Adapter 3 — Query/Response (`yugdave-finetuned-query-response`)

```sh
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "yugdave-finetuned-query-response",
    "messages": [{"role": "user", "content": "What is the difference between REST and GraphQL?"}],
    "temperature": 0.3
  }'
```

---

### Adapter 4 — Educational (`qwen-code-educational`)

```sh
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen-code-educational",
    "messages": [{"role": "user", "content": "Explain recursion to a beginner with a simple example."}],
    "temperature": 0.5
  }'
```

---

### Adapter 5 — SQL (`qwen-code-sql-lora`)

```sh
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen-code-sql-lora",
    "messages": [{"role": "user", "content": "Write a SQL query to find the top 5 customers by total order value from an orders table."}],
    "temperature": 0.1
  }'
```

---

### Adapter 6 — Flutter (`qwen-code-flutter-dev-lora`)

```sh
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen-code-flutter-dev-lora",
    "messages": [{"role": "user", "content": "Create a Flutter widget for a login screen with email and password fields."}],
    "temperature": 0.2
  }'
```

---

### Adapter 7 — n8n Workflow (`qwen-code-n8n-workflow-generator-lora`)

```sh
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen-code-n8n-workflow-generator-lora",
    "messages": [{"role": "user", "content": "Generate an n8n workflow that sends a Slack notification when a new row is added to a Google Sheet."}],
    "temperature": 0.3
  }'
```

---

## List Loaded Adapters at Runtime

You can query the vLLM server directly to see which adapters are currently loaded:

```sh
curl http://localhost:8000/v1/models | jq '.data[].id'
```

## Troubleshooting

**Adapter stuck in Pending:**
```sh
kubectl describe modeladapter <adapter-name> -n default
```

**Check aibrix-runtime sidecar logs (handles adapter loading):**
```sh
kubectl logs -n default deployment/qwen-coder-1-5b-instruct -c aibrix-runtime
```

**Check vLLM logs:**
```sh
kubectl logs -n default deployment/qwen-coder-1-5b-instruct -c vllm-openai
```

**Verify env vars are set correctly on the pod:**
```sh
kubectl exec -n default deployment/qwen-coder-1-5b-instruct -c vllm-openai -- env | grep VLLM_LORA
```

Expected:
```
VLLM_ALLOW_RUNTIME_LORA_UPDATING=True
VLLM_LORA_MODULES_LOADING_TIMEOUT=300
```

## Key Configuration Notes

- `adapter.model.aibrix.ai/enabled: "true"` must be set on both the **Deployment** and **pod template labels** — this marks the pod as eligible for adapter scheduling.
- `VLLM_ALLOW_RUNTIME_LORA_UPDATING=True` is **required** on the base model container for dynamic adapter loading to work.
- Each `ModelAdapter`'s `podSelector` must match the base model pod labels exactly.
- The `baseModel` field must match the Deployment/Service name (`qwen-coder-1-5b-instruct`).
- Adapter names (e.g. `qwen-code-sql-lora`) are used directly as the `model` value in API requests.

## References

- [AIBrix ModelAdapter Documentation](https://aibrix.ai/docs/model-adapter)
- [vLLM LoRA Documentation](https://docs.vllm.ai/en/latest/models/lora.html)
