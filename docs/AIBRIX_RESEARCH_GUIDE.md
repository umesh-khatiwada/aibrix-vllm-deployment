# AIBrix Research Guide (NVIDIA & AMD)

## Overview
AIBrix is a cloud-native framework for scalable GenAI inference, co-designed with engines like vLLM. It features a control plane for orchestration and a data plane for optimized request routing and KV cache management.

## Key Features
- **LLM Gateway & Routing**: Envoy-based gateway with strategies like `prefix-cache` (~45% TTFT improvement), `least-request`, and `throughput`.
- **Autoscaling**: Supports HPA, KPA (panic mode), and APA (custom LLM-aware metrics).
- **LoRA Management**: Dynamic loading/unloading of adapters for high-density serving.
- **KVCache Offloading**: Two-tier architecture (L1 DRAM, L2 Distributed) for reduced memory pressure and latency (~70% reduction).
- **Heterogeneous GPU Support**: (Experimental) Deployment across different GPU types with an automated optimizer.

## GPU Specifics

### NVIDIA
- **Engine**: vLLM (standard).
- **Resource**: `nvidia.com/gpu`.
- **Device Plugin**: NVIDIA Device Plugin.

### AMD
- **Engine**: vLLM (ROCm-enabled).
- **Resource**: `amd.com/gpu`.
- **Target Device**: `VLLM_TARGET_DEVICE=rocm`.
- **Images**: e.g., `vllm/vllm-omni-rocm:v0.12.0rc1`.
