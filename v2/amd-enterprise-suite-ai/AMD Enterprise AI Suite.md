# AMD Enterprise AI Suite

---

## Executive Summary

AMD Enterprise AI Suite is a full-stack solution for developing, deploying, and running AI workloads on a Kubernetes platform optimized for AMD compute. It is designed for system administrators, resource managers, AI researchers, and AI solution developers.

**Key Benefits:**
| Benefit | Description |
|---------|-------------|
| ⚡ Optimized GPU Utilization | Intelligent workload placement and dynamic GPU sharing eliminate waste |
| 🏗️ Unified AI Infrastructure | Single governed platform standardizing tools, processes, and collaboration |
| 🚀 Accelerated Time-to-Production | Built-in training and inference microservices streamline development |
| 🎯 AI-Native Orchestration | Purpose-built scheduling prioritizes AI workloads on AMD Instinct™ GPUs |
| 🔐 Information Security | Built-in RBAC enforces secure, compliant access to AI resources |

> 📌 For the full business case: [docs/01-overview/business-case.md](docs/01-overview/business-case.md)


---

## ⚡ Quick Start

### Prerequisites
- AMD MI300X or MI325X GPUs
- Ubuntu 22.04+ with root/sudo access
- 500GB+ disk for root, 3TB+ for data
- Unformatted NVMe drives for Longhorn storage

### 1. Download Bloom installer
```bash
wget https://github.com/silogen/cluster-bloom/releases/latest/download/bloom
chmod +x bloom
```

### 2. Create configuration
```bash
cat > bloom.yaml << EOF
CLUSTER_SIZE: large
DOMAIN: 129.212.181.118.nip.io
FIRST_NODE: true
GPU_NODE: true
CLUSTER_PREMOUNTED_DISKS: "/var/lib/longhorn,/mnt/longhorn"
CERT_OPTION: generate
EOF
```

### 3. Install (takes ~20 minutes)
```bash
sudo ./bloom --config bloom.yaml
```
