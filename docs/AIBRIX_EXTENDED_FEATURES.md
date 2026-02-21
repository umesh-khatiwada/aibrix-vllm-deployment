# AIBrix Advanced Features: A Deep Dive Guide

AIBrix provides a suite of enterprise-grade features for Large Language Model (LLM) orchestration, following a co-design philosophy with engines like vLLM.

---

## 1. Dynamic LoRA Management (`ModelAdapter`)

AIBrix enables multi-LoRA-per-pod deployments, improving scalability and resource efficiency. Users can load adapters without restarting pods.

### Key Components:
- **Model Adapter Controller**: Manages the LoRA lifecycle and registry.
- **Service Discovery**: Allows pods with different LoRAs to belong to multiple Kubernetes services.
- **Scheduling Strategies**: Bin packing, least latency, least throughput, and random.

---

## 2. LLM-Specific Autoscaling (`PodAutoscaler`)

AIBrix fetches and maintains metrics internally, enabling second-level response times compared to Prometheus-based HPA.

| Strategy | Description | Key Feature |
|---|---|---|
| **HPA** | Kubernetes HPA | CPU-based baseline. |
| **KPA** | Knative Pod Autoscaler | **Panic Window** for rapid scale-up. |
| **APA** | AIBrix Pod Autoscaler | **Fluctuation parameters** to prevent oscillation; LLM-native metrics. |

---

## 3. KVCache Offloading Framework

Introduced in v0.3.0, this framework enables efficient memory tiering and cross-engine KV reuse, delivering up to **70% reduction in latency**.

### Two-Tier Architecture:
- **L1 (DRAM-based)**: Offloads GPU memory pressure to CPU; enabled via `AIBRIX_KV_CACHE_OL_L1_CACHE_ENABLED`.
- **L2 (Distributed)**: Remote caching for multi-node sharing and large-scale reuse.

**Performance Impact**: ~50% increase in throughput.

---

## 4. LLM-Aware Gateway Routing

Extending Envoy, AIBrix analyzes token patterns and cache availability for intelligent routing.

### Strategies:
- **`prefix-cache`**: **~45% TTFT improvement** by routing to pods with matching KV cache prompts.
- **`least-kv-cache`**: Routes to pods with the smallest VRAM usage.
- **`vtc-basic`**: Fairness-oriented routing using the Windowed Adaptive Fairness algorithm.

---

## 5. Multi-Node Distributed Inference

Leverages **KubeRay** for fine-grained execution while using Kubernetes for coarse-grained scheduling.

- **`RayClusterFleet`**: Abstracts Ray clusters as single application instances.
- **Distributed Executor**: Uses Ray for tensor parallelism across multiple nodes.

---

## 6. Heterogeneous GPU Inference (Experimental)

Enables cost-efficient serving by deploying models across different GPU types (e.g., NVIDIA and AMD).

1. **Monitoring**: Analyzes request patterns.
2. **Optimizer**: Dynamically selects optimal GPU types and counts based on SLOs.
3. **Routing**: Directs traffic to the optimal hardware backend.

