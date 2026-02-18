# AIBrix Research Notebook: Scalable LLM Inference on K3s

> **Researcher/Learner Context**: This document serves as a comprehensive guide for deploying AIBrix (v0.5.0) on a local K3s cluster with NVIDIA GPUs. It emphasizes resource constraints, troubleshooting patterns, and optimal configuration for consumer-grade hardware (e.g., RTX 4060).

---

## 1. Architectural Overview

**AIBrix** is a Kubernetes-native control plane designed to manage large-scale LLM inference. It acts as an orchestration layer on top of engines like **vLLM** and **SGLang**.

### Key Components:
- **LLM Gateway**: Handles request routing (Random, Least-Request, Prefix-Cache).
- **Metadata Service**: Stores model states and health metadata.
- **GPU Optimizer**: Dynamically manages GPU resources and scaling.
- **Envoy Gateway**: Core infrastructure for traffic management.

---

## 2. Prerequisites & Environment

### Hardware Requirements (Research Cluster)
- **Host OS**: Ubuntu 24.04 (or similar Linux distro).
- **GPU**: NVIDIA GPU with 8GB+ VRAM (e.g., RTX 4060).
- **Disk**: 100GB+ free space (LLM images are 4GB–15GB each).

### Software Requirements
- **K3s**: Lightweight Kubernetes.
- **NVIDIA Container Toolkit**: For GPU passthrough to containers.
- **NVIDIA Device Plugin**: To make `nvidia.com/gpu` a schedulable resource.

---

## 3. Installation Step-by-Step

### Phase 1: Cluster Preparation
```bash
# 1. Point to your K3s kubeconfig
export KUBECONFIG=/path/to/k.yaml

# 2. Verify GPU availability
kubectl describe nodes | grep -A5 "Capacity" | grep gpu
```

### Phase 2: AIBrix Core Setup
```bash
# Install Envoy Gateway and KubeRay CRDs
kubectl create -f https://github.com/vllm-project/aibrix/releases/download/v0.5.0/aibrix-dependency-v0.5.0.yaml

# Install AIBrix Core Controllers
kubectl create -f https://github.com/vllm-project/aibrix/releases/download/v0.5.0/aibrix-core-v0.5.0.yaml
```

### Phase 3: Model Deployment
For limited hardware (8GB VRAM), use a small model (e.g., 1.5B parameters).

**File: `nvidia-model.yaml`**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deepseek-r1-qwen-1b5
  labels:
    model.aibrix.ai/name: deepseek-r1-qwen-1b5
spec:
  template:
    spec:
      containers:
      - name: vllm-openai
        image: vllm/vllm-openai:v0.11.0
        command: ["python3", "-m", "vllm.entrypoints.openai.api_server"]
        args:
          - "--host"
          - "0.0.0.0"
          - "--port"
          - "8000"
          - "--model"
          - "deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B"
          - "--gpu-memory-utilization"
          - "0.7" # Crucial for 8GB GPUs
        resources:
          limits:
            nvidia.com/gpu: "1"
```

---

## 4. Researcher Notes: Troubleshooting & Optimization

### A. The "Disk Pressure" Taint
**Scenario**: All pods suddenly go to `Pending` or `Evicted`.
- **Insight**: Kubernetes has an eviction threshold (usually 85-90% disk usage). Large LLM images quickly fill consumer-grade SSDs.
- **Solution**: 
  - Prune old images: `docker system prune -af`
  - Clear system trash: `rm -rf ~/.local/share/Trash/*`
  - Verify: `kubectl describe node <node-name>` should show `DiskPressure: False`.

### B. CUDA Out of Memory (OOM)
**Scenario**: `RuntimeError: Engine core initialization failed` or `torch.OutOfMemoryError`.
- **Insight**: vLLM V1 engine (default in 0.11.0) tries to reserve 90% of VRAM for KV cache. If your OS/Desktop (Gnome, Firefox) uses ~1GB, vLLM will fail.
- **Solution**: 
  - Decrease utilization: `--gpu-memory-utilization 0.7` or lower.
  - Clear rogue processes: Check `nvidia-smi` and kill dead `VLLM::EngineCore` PIDs.

### C. Startup Timeouts
**Scenario**: Pod restarts repeatedly even if logs look fine.
- **Insight**: Downloading a 1.5B model (~4GB) and compiling CUDA graphs takes ~3 minutes. Default Kubernetes `startupProbe` may be too short.
- **Solution**: Increase `failureThreshold` to `60` with `periodSeconds: 5` (total 5 minutes).

---

## 5. Learning Outcome: Verification

### Gateway Routing
AIBrix allows you to route requests across different model versions. Test via the Envoy Gateway:
```bash
# Port-forward to the gateway
kubectl -n envoy-gateway-system port-forward service/envoy-aibrix-system-aibrix-eg-903790dc 8888:80 &

# Call the API
curl http://localhost:8888/v1/chat/completions \
  -H "routing-strategy: random" \
  -d '{"model":"deepseek-r1-qwen-1b5", "messages": [{"role": "user", "content": "Hi"}]}'
```

**Conclusion**: Successful AIBrix deployment on consumer hardware requires a precise balance between **Model Size**, **Memory Utilization**, and **Cluster Storage** hygiene.
