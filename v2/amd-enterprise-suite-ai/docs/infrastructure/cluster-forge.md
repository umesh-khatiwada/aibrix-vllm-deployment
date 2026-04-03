# ClusterForge

**ClusterForge** is an open-source tool by [Silogen](https://github.com/silogen/cluster-forge) that deploys the **AMD Enterprise AI Suite** into a Kubernetes cluster. It bundles all required third-party, community, and in-house components into a single streamlined stack using GitOps.

!!! info "Where it fits"
    [ClusterBloom](cluster-bloom.md) provisions the Kubernetes cluster and AMD GPU infrastructure. **ClusterForge** runs next — it installs all platform tools and services on top of that cluster, making it ready for AI workloads.

---

## What ClusterForge Does

ClusterForge bundles various third-party, community, and in-house components into a single, streamlined stack that can be deployed in Kubernetes clusters. By automating the deployment process, ClusterForge simplifies the creation of consistent, ready-to-use clusters.

It is ideal for:

- **Ephemeral test clusters** — spin up environments quickly
- **CI/CD pipeline clusters** — consistent testing environments every time
- **Multiple production clusters** — manage a fleet of clusters efficiently
- **Reproducible environments** — guaranteed consistency across deployments

---

## How It Works

ClusterForge deploys all necessary components within the cluster using the GitOps controller ArgoCD and the app-of-apps pattern, where ClusterForge acts as an app of apps.

This means every component is declared as code, versioned, and automatically reconciled — the cluster always converges to the desired state.

---

## Quick Start

Once you have a running Kubernetes cluster (e.g., set up via [ClusterBloom](cluster-bloom.md)), deploy the full AMD Enterprise AI Suite with a single command:

```bash
./scripts/bootstrap.sh <domain>
```

Replace `<domain>` with your cluster's domain name, e.g.:

```bash
./scripts/bootstrap.sh ai.example.com
```

---

## Components Installed

ClusterForge installs and manages a comprehensive set of components:

### Core Infrastructure

| Component | Purpose |
|---|---|
| **Longhorn** | Cloud-native distributed storage |
| **MetalLB** | Load balancer for bare metal clusters |
| **CertManager** | Automated TLS certificate management |
| **External Secrets** | Sync secrets from external secret stores |
| **Gateway API / KGateway** | Next-generation Kubernetes ingress |

### Monitoring & Observability

| Component | Purpose |
|---|---|
| **Grafana** | Metrics dashboards and visualization |
| **Prometheus** | Metrics collection and alerting |
| **Grafana Loki** | Log aggregation |
| **Grafana Mimir** | Highly available metrics backend |
| **Promtail** | Log collector feeding into Loki |
| **OpenTelemetry Operator** | Telemetry collection and management |
| **Kube-Prometheus-Stack** | End-to-end cluster monitoring |

### Database & Object Storage

| Component | Purpose |
|---|---|
| **MinIO Operator + Tenant** | S3-compatible object storage (for models, datasets) |
| **CNPG Operator** | Cloud Native PostgreSQL |

### GPU Support

| Component | Purpose |
|---|---|
| **AMD GPU Operator** | GPU operator for AMD Instinct GPUs |
| **AMD Device Config** | GPU device configuration |

### ML & Scheduling

| Component | Purpose |
|---|---|
| **KubeRay Operator** | Kubernetes operator for Ray distributed computing |
| **Kueue** | Job queue controller for batch AI workloads |
| **AppWrapper** | Application wrapper for job scheduling |
| **Kaiwo** | ML workflow management |

### Autoscaling

| Component | Purpose |
|---|---|
| **KEDA** | Kubernetes Event-driven Autoscaling |
| **Kedify OTEL** | OpenTelemetry add-on for KEDA |

### Security & Identity

| Component | Purpose |
|---|---|
| **Kyverno** | Kubernetes policy engine |
| **KeyCloak** | SSO and identity & access management |

---

## Storage Classes

ClusterForge sets up these Longhorn-backed storage classes by default:

| StorageClass | Access Mode | Best For |
|---|---|---|
| `mlstorage` | RWO (ReadWriteOnce) | GPU training jobs |
| `default` | RWO | General GPU workloads |
| `direct` | RWO | Advanced/local-only storage |
| `multinode` | RWX (ReadWriteMany) | Shared multi-container access |

---

## Relationship to ClusterBloom

ClusterBloom automatically installs ClusterForge as its final step. You can also control which version gets installed:

```yaml
# In bloom.yaml
CLUSTERFORGE_RELEASE: "https://github.com/silogen/cluster-forge/releases/download/deploy/deploy-release.tar.gz"

# To skip ClusterForge installation
CLUSTERFORGE_RELEASE: "none"
```

---

## Source & License

[github.com/silogen/cluster-forge](https://github.com/silogen/cluster-forge)
License: Apache 2.0
