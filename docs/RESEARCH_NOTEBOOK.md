# AIBrix Research Notebook: GenAI Inference Infrastructure

This notebook documents the research findings and architectural insights for AIBrix (v0.3.0+), a framework designed by ByteDance for scalable LLM inference.

---

## 1. Architectural Philosophy: Control vs. Data Plane

AIBrix follows a **co-design philosophy**, ensuring the infrastructure is purpose-built for inference engines like vLLM.

- **Control Plane**: Orchestrates model metadata, multi-LoRA life-cycles, and second-level autoscaling (HPA/KPA/APA).
- **Data Plane**: Features the **LLM Gateway** (Envoy-based) and **Distributed KV Cache**.

---

## 2. Multi-GPU Benchmarks & Performance data

Research results demonstrate significant improvements over vanilla cloud-native stacks:

| Metric | Improvement | Rationale |
|---|---|---|
| **TTFT** | **~45%** | Prefix-cache routing hits existing KV cache. |
| **Throughput** | **~50%** | Distributed KV cache sharing across nodes. |
| **Inference Latency** | **~70%** | Efficient memory tiering (L1 DRAM + L2 Distributed). |
| **Autoscaling Latency** | **~11.5%** | Internal metric fetching vs. Prometheus overhead. |

---

## 3. Hardware-Specific Implementation Notes

### NVIDIA Integration
- **Optimization**: Use `--gpu-memory-utilization 0.7` for 8GB VRAM cards to avoid OOM during KV cache reservation.
- **Sidecar**: Deploy with `aibrix-runtime` for metric standardization and LoRA management.

### AMD (ROCm) Support
- **Engine**: Requires ROCm-compatible vLLM images (e.g., `vllm-omni-rocm`).
- **Target Device**: Set `VLLM_TARGET_DEVICE=rocm`.
- **Resource**: Request `amd.com/gpu: 1`.

---

## 4. Key Learnings & Troubleshooting

### A. Prefix-Cache Routing
To enable prefix-cache routing, include the strategy in the request header:
```bash
"routing-strategy": "prefix-cache"
```
This is particularly effective for multi-turn conversations where the history is cached.

### B. Distributed KV Cache (L1/L2)
Ensure `AIBRIX_KV_CACHE_OL_L1_CACHE_ENABLED=1` is set in the environment to leverage DRAM offloading, reducing GPU memory pressure.

### C. RayClusterFleet
For large models (e.g., DeepSeek-V3), use `RayClusterFleet` to orchestrate multi-node tensor parallelism. This abstracts the complexity of KubeRay.

---
**Conclusion**: AIBrix transitions LLM serving from "general-purpose containers" to "inference-aware agents," drastically improving resource efficiency and user experience.

