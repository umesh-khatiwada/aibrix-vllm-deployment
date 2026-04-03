# ClusterBloom

**ClusterBloom** is an open-source tool by [Silogen](https://github.com/silogen/cluster-bloom) that automates the deployment and configuration of **RKE2 Kubernetes clusters** with specialized support for AMD GPU environments. It is the first step in setting up AMD Enterprise AI Suite on bare metal.

!!! info "Where it fits"
    ClusterBloom handles **infrastructure provisioning** — it gets you a working Kubernetes cluster with AMD GPUs ready. Once complete, [ClusterForge](cluster-forge.md) takes over and installs all the platform tools on top.

---

## What ClusterBloom Does

ClusterBloom automates RKE2 Kubernetes cluster deployment, ROCm setup and configuration for AMD GPU nodes, disk management and Longhorn storage integration, multi-node cluster support, and ClusterForge integration.

In plain terms: you run one command on your first node, and ClusterBloom handles everything from OS-level setup through to a production-ready Kubernetes cluster.

---

## Prerequisites

Before running ClusterBloom, make sure your hardware meets these requirements:

| Requirement | Details |
|---|---|
| **OS** | Ubuntu (version checked at runtime) |
| **Root access** | `sudo` required |
| **Disk space** | 500 GB+ for root partition; 2 TB+ for workloads |
| **Storage** | NVMe drives recommended |
| **GPUs** | ROCm-compatible AMD GPUs (for GPU nodes) |

---

## Installation

### Step 1: Set Up the First Node

On your first server, simply run:

```bash
sudo ./bloom
```

ClusterBloom will walk you through cluster setup interactively.

### Step 2: Join Additional Nodes

After the first node is configured, ClusterBloom generates a join command saved to `additional_node_command.txt`. Run it on each additional node:

```bash
# The actual token/IP will be different — use the generated command
echo -e 'FIRST_NODE: false\nJOIN_TOKEN: your-token-here\nSERVER_IP: your-server-ip' > bloom.yaml
sudo ./bloom --config bloom.yaml
```

### Step 3 (Optional): Interactive Configuration Wizard

For a guided setup experience:

```bash
sudo ./bloom
```

The UI provides real-time validation, TLS-SAN configuration previews, and color-coded feedback.

---

## Configuration

ClusterBloom is configured via a YAML file, environment variables, or command-line flags.

### Key Configuration Variables

| Variable | Description | Default |
|---|---|---|
| `DOMAIN` | Your cluster's domain (e.g. `cluster.example.com`) | *(required)* |
| `FIRST_NODE` | `true` if this is the first node | `true` |
| `GPU_NODE` | `true` if this node has AMD GPUs | `true` |
| `RKE2_VERSION` | Specific RKE2 version to install | latest |
| `JOIN_TOKEN` | Token to join additional nodes | *(generated)* |
| `SERVER_IP` | IP of the first node (for joining) | *(required for additional nodes)* |
| `CLUSTER_DISKS` | Comma-separated disk devices for storage | `""` |
| `NO_DISKS_FOR_CLUSTER` | Skip disk setup | `false` |
| `USE_CERT_MANAGER` | Use Let's Encrypt for automatic TLS | `false` |
| `CLUSTERFORGE_RELEASE` | ClusterForge version to install | latest |
| `DISABLED_STEPS` | Steps to skip (e.g. `SetupLonghornStep`) | `""` |

### Example `bloom.yaml`

```yaml
FIRST_NODE: true
GPU_NODE: true
DOMAIN: "ai.example.com"
RKE2_VERSION: v1.34.1+rke2r1
NO_DISKS_FOR_CLUSTER: false
USE_CERT_MANAGER: true
```

Run with:

```bash
sudo ./bloom --config bloom.yaml
```

---

## TLS-SAN Configuration

TLS Subject Alternative Names (SANs) allow your Kubernetes API server to be reached via multiple domain names. ClusterBloom automatically generates `k8s.{DOMAIN}` — you can add more:

```yaml
DOMAIN: "example.com"
ADDITIONAL_TLS_SAN_URLS:
  - "api.example.com"
  - "lb.example.com"
```

This results in a certificate valid for: `k8s.example.com`, `api.example.com`, `lb.example.com`.

!!! warning
    Do not duplicate `k8s.{DOMAIN}` in `ADDITIONAL_TLS_SAN_URLS` — it is always auto-generated.

---

## OIDC / SSO Configuration

ClusterBloom supports configuring OIDC providers for Kubernetes API authentication. By default, it sets up an internal Keycloak `airm` realm. You can add additional providers:

```yaml
ADDITIONAL_OIDC_PROVIDERS:
  - url: "https://keycloak.example.com/realms/main"
    audiences: ["k8s"]
```

---

## What Gets Installed

ClusterBloom runs these steps in order:

1. Checks for supported Ubuntu version
2. Installs required packages (`jq`, `nfs-common`, `open-iscsi`)
3. Configures firewall and networking
4. Sets up **ROCm** for AMD GPU nodes
5. Prepares and installs **RKE2**
6. Configures storage with **Longhorn**
7. Installs `kubectl` and `k9s`
8. Automatically installs **[ClusterForge](cluster-forge.md)**

---

## Useful Commands

```bash
# Check version
./bloom version

# Get help
./bloom help

# Verify TLS-SANs after install
sudo cat /etc/rancher/rke2/config.yaml | grep -A 10 "tls-san:"

# Test kubectl access
kubectl get nodes
```

---

## Source & License

[Silogen/cluster-bloom](https://github.com/silogen/cluster-bloom)
License: Apache 2.0
