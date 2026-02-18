# AIBrix Advanced Features: A Deep Dive Guide

Beyond basic model serving, AIBrix provides a suite of enterprise-grade features for Large Language Model (LLM) orchestration. This guide covers the advanced CRDs and configurations available in the AIBrix control plane.

---

## 1. Dynamic LoRA Management (`ModelAdapter`)

AIBrix allows you to load fine-tuned LoRA adapters onto running base model instances without restarting the pods. This enables high-density multi-tenant serving.

### How it works:
1. You deploy a base model (e.g., Llama-3-8B).
2. You create a `ModelAdapter` resource pointing to your LoRA weights (e.g., on S3).
3. AIBrix sidecars download and inject the adapter into the target vLLM instances.

### Example Configuration:
```yaml
apiVersion: model.aibrix.ai/v1alpha1
kind: ModelAdapter
metadata:
  name: marketing-lora-adapter
spec:
  baseModel: deepseek-r1-qwen-1b5
  artifactURL: "s3://my-bucket/adapters/marketing-v1"
  podSelector:
    matchLabels:
      model.aibrix.ai/name: deepseek-r1-qwen-1b5
  replicas: 1
```

---

## 2. Context-Aware Autoscaling (`PodAutoscaler`)

Standard Kubernetes HPA is often too slow or coarse for LLM workloads. AIBrix's `PodAutoscaler` supports three distinct strategies:

| Strategy | Full Name | Description |
|---|---|---|
| **HPA** | Horizontal Pod Autoscaler | Traditional CPU/Memory based scaling. |
| **KPA** | Knative Pod Autoscaler | Scales based on request concurrency (in-flight requests). |
| **APA** | AIBrix Pod Autoscaler | AIBrix-native strategy using GPU-specific metrics (KV cache usage, etc.). |

### Example Configuration:
```yaml
apiVersion: autoscaling.aibrix.ai/v1alpha1
kind: PodAutoscaler
metadata:
  name: deepseek-autoscaler
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: deepseek-r1-qwen-1b5
  minReplicas: 1
  maxReplicas: 5
  scalingStrategy: APA
  metricsSources:
    - type: Prometheus
      prometheus:
        query: "avg(vllm:num_requests_running)"
```

---

## 3. Distributed KV Cache (`KVCache`)

This is one of AIBrix's most powerful features. It allows multiple inference nodes to share KV cache entries, significantly reducing "TTFT" (Time To First Token) for common prefixes.

### Features:
- **Global Sharing**: A request hitting Node A can reuse a KV cache prefix generated on Node B.
- **Offloading**: KV blocks can be offloaded to system memory or distributed storage (Redis/AIBrix Metadata Service).

### Example Control:
```yaml
apiVersion: orchestration.aibrix.ai/v1alpha1
kind: KVCache
metadata:
  name: global-prefix-cache
spec:
  capacity: "100Gi"
  engine: "vLLM"
  selector:
    matchLabels:
      app: llm-worker
```

---

## 4. Advanced Gateway Routing

The AIBrix LLM Gateway (based on Envoy) supports sophisticated routing beyond simple round-robin:

### Supported Strategies:
- **Random**: Basic load balancing.
- **Least-Request**: Routes to the instance with the fewest active requests.
- **Prefix-Matching**: Routes to instances that already have the prompt prefix cached.
- **Rate-Limiting**: Per-user or per-model rate limits enforced at the edge.

### Test Headers:
```bash
# Force a specific routing strategy
curl -H "routing-strategy: least-request" ...
```

---

## 5. GPU Hardware Diagnostics

AIBrix proactively monitors GPU health to prevent the "Black Hole" effect where a failed GPU keeps accepting but failing requests.

- **Failure Detection**: Automaticaly taints nodes with failing GPUs.
- **Graceful Termination**: Drains requests before restarting pods on faulty hardware.

---

## 6. Infrastructure & Diagnostic Tools

AIBrix includes several utilities for Day-2 operations:

### Aibrix Benchmark Tool
Used to measure throughput (Tokens Per Second) and latency (TTFT) across different model configurations.
- **Location**: Usually run as a separate Job or inside the Gateway namespace.
- **Goal**: Find the "sweet spot" for `--gpu-memory-utilization`.

### Multi-Node Ray Orchestration
For models that don't fit on a single node (e.g., Llama-3-70B), AIBrix leverages **KubeRay** to orchestrate distributed inference.
- **CRD**: `RayClusterFleet`
- **Benefit**: Seamlessly manages head and worker pods across the cluster as a single logical unit.

### Unified AI Runtime (Sidecars)
Every model pod can include AIBrix sidecars for:
- **Metric Standardization**: Exports vLLM/SGLang metrics into a unified format for Prometheus.
- **GPU Streaming Loader**: Faster model downloads from object storage (S3/OSS) directly into GPU memory.

---

**Learning Tip**: To explore these, try applying a `PodAutoscaler` to your current deployment and observe how replicas change under load!
