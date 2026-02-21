# AIBrix: Scalable GenAI Inference (NVIDIA & AMD)

This repository contains the configuration and research data for deploying [AIBrix](https://github.com/vllm-project/aibrix) on K3s clusters, optimized for both NVIDIA and AMD GPUs.

## 🚀 Overview

AIBrix is a cloud-native framework co-designed with inference engines like vLLM to provide scalable, enterprise-grade LLM serving infrastructure.

### Key Components
- **Control Plane**: Manages model metadata, multi-LoRA deployments, and LLM-specific autoscaling.
- **Data Plane**: Features an LLM-aware Request Router and a Distributed KV Cache Runtime.

## 📁 Repository Structure

| File/Directory | Description |
|---|---|
| `docs/` | Comprehensive AIBrix research data and guides. |
| `manifests/` | Kubernetes manifests for NVIDIA, AMD, and Distributed setups. |
| `setup_aibrix.sh` | Installation script for AIBrix core and dependencies. |
| `cleanup_gpu.sh` | Utility to clear GPU memory and processes. |

## 🛠 Multi-GPU Quick Start

### 1. Installation
```bash
# Point to your kubeconfig
export KUBECONFIG=$(pwd)/k.yaml

# Install AIBrix v0.3.0
bash setup_aibrix.sh
```

### 2. Deploy Based on GPU Type

**For NVIDIA:**
```bash
kubectl apply -f manifests/nvidia/nvidia-model.yaml
```

**For AMD:**
```bash
kubectl apply -f manifests/amd/amd_model.yaml
```

### 3. Deploy Distributed Inference (Optional)
```bash
kubectl apply -f manifests/distributed-inference.yaml
```

### 4. Query the Gateway
```bash
# Port-forward the gateway
kubectl -n envoy-gateway-system port-forward service/envoy-aibrix-system-aibrix-eg-903790dc 8888:80

# Send request with prefix-cache strategy
curl http://localhost:8888/v1/completions \
  -H "routing-strategy: prefix-cache" \
  -d '{"model": "deepseek-r1...", "prompt": "Hello world"}'
```

## 📖 Key Documentation
- [Research Guide](docs/AIBRIX_RESEARCH_GUIDE.md)
- [Implementation Report](docs/IMPLEMENTATION_REPORT.md)
- [Extended Features](docs/AIBRIX_EXTENDED_FEATURES.md)
- [Research Notebook](docs/RESEARCH_NOTEBOOK.md)
- [Multi-Model Routing Guide](docs/MULTI_MODEL_ROUTING_GUIDE.md)
- [AMD Feature Test Guide](docs/AMD_FEATURE_TEST_GUIDE.md)


## 📊 Performance at a Glance
- **TTFT Improvement**: ~45% using prefix-cache routing.
- **Latency Reduction**: ~70% with KVCache offloading.
- **Throughput Increase**: ~50% with distributed KV cache.

---
*Developed by ByteDance & the Open Source Community.*

