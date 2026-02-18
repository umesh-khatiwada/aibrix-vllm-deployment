# AIBrix K3s Deployment Workspace

This repository contains the configuration and scripts used to deploy and manage [AIBrix](https://github.com/vllm-project/aibrix) on a local K3s cluster with NVIDIA GPUs.

## 📁 Repository Structure

| File | Description |
|---|---|
| `nvidia-model.yaml` | Deployment & Service manifest for DeepSeek-R1-1.5B (Optimized). |
| `setup_aibrix.sh` | script to install AIBrix dependencies and core components. |
| `query_model.py` | Python example to query the model via the LLM Gateway. |
| `cleanup_gpu.sh` | Utility to force-clear GPU memory and stale vLLM processes. |
| `k.yaml` | K3s cluster kubeconfig. |
| `RESEARCH_NOTEBOOK.md` | Deep dive into architecture, OOM fixes, and learning outcomes. |

## 🚀 Quick Start

### 1. Environment Setup
```bash
export KUBECONFIG=$(pwd)/k.yaml
```

### 2. Install AIBrix (If not already installed)
```bash
bash setup_aibrix.sh
```

### 3. Deploy Model
```bash
kubectl apply -f nvidia-model.yaml
```

### 4. Port-Forward Gateway
In a separate terminal:
```bash
kubectl -n envoy-gateway-system port-forward service/envoy-aibrix-system-aibrix-eg-903790dc 8888:80
```

### 5. Query Model
```bash
python3 query_model.py
```

## 🛠 Troubleshooting

If you encounter **CUDA Out of Memory** or **Disk Pressure**:
1. Run `./cleanup_gpu.sh` to kill rogue processes.
2. Run `docker system prune -af` to free disk space.
3. Check `nvidia-smi` to ensure at least 5GB of VRAM is free before starting.

---
*Created for research and learning on local LLM infrastructure.*
