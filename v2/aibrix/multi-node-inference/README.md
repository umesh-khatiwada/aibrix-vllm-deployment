# Multi-Node Inference with AIBrix

## What does the manifest do?

[`multi-node-inference.yaml`](aibrix/multi-node-inference/multi-node-inference.yaml) is a comprehensive manifest that deploys a distributed, multi-node LLM inference service using AIBrix and KubeRay. It includes:

- **RayClusterFleet**: Orchestrates a Ray cluster for distributed inference, with a head node (running vLLM and aibrix-runtime) and worker nodes for tensor parallelism.
- **Service**: Exposes the vLLM/aibrix-runtime API endpoints for external access.
- **HTTPRoute**: Integrates the model with the AIBrix gateway, enabling header-based routing for inference requests.

**Key features:**
- Launches a Ray head pod and worker pod(s) on specified nodes, with GPU and CPU resource requests/limits.
- Starts the vLLM server in distributed mode, using Ray as the backend for tensor parallelism.
- Exposes both direct vLLM and aibrix-runtime endpoints (ports 8000 and 8080).
- Provides health/readiness probes and lifecycle hooks for robust operation.
- Enables gateway-based routing for OpenAI-compatible inference APIs.

See below for a detailed breakdown of each section of the manifest.


Distributed inference splits a large LLM across multiple nodes or devices — essential for models that don't fit in a single machine's GPU memory. AIBrix uses **KubeRay** to orchestrate Ray Clusters for this purpose.

---

## How It Works

AIBrix divides responsibilities between two layers:

**Ray** handles internal, fine-grained orchestration — distributed computation within a single application instance (one Ray Cluster = one model serving instance).

**Kubernetes** handles the outer layer — resource allocation, autoscaling, rolling updates, and environment configuration. It no longer orchestrates roles inside the application; Ray owns that.

This clean separation simplifies Kubernetes operator design while giving Ray full control over the distributed execution internals.

### Key CRDs

AIBrix introduces two CRDs for Ray Cluster management, analogous to Kubernetes' `ReplicaSet` and `Deployment`:

- **`RayClusterReplicaSet`** — manages a fixed set of Ray Clusters
- **`RayClusterFleet`** — adds rolling update strategy on top, like a Deployment

In most cases you only need `RayClusterFleet`.

---

## Prerequisites

### KubeRay

KubeRay must be installed for `RayClusterFleet`-based workloads.

```bash
helm repo add kuberay https://ray-project.github.io/kuberay-helm/
helm repo update
# Install both CRDs and KubeRay operator v1.5.1.
helm install kuberay-operator kuberay/kuberay-operator --version 1.5.1
```

## Architecture Overview

```
RayClusterFleet (Kubernetes layer)
└── RayCluster (one per replica)
    ├── Head Pod       ← runs vLLM server + aibrix-runtime sidecar
    └── Worker Pod(s)  ← additional GPU nodes for tensor parallelism
```

A `Service` exposes the head pod, and an `HTTPRoute` wires it into the AIBrix gateway so routing strategies apply normally.

---
## Gateway Routing

The `HTTPRoute` exposes the model through the AIBrix gateway. Requests are matched by the `model` header and routed to either port `8000` (vLLM direct) or `8080` (aibrix-runtime sidecar, recommended):

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: qwen-coder-7b-instruct-router
  namespace: aibrix-system
spec:
  rules:
    - backendRefs:
        - name: qwen-coder-7b-instruct
          port: 8080
      matches:
        - headers:
            - name: model
              value: qwen-coder-7b-instruct
          path:
            type: PathPrefix
            value: /v1/chat/completions
      timeouts:
        request: 120s
```

---

## Verify Deployment

```bash
# Check RayClusterFleet status
kubectl get rayclusterfleet -n default

# Check head and worker pods are Running
kubectl get pods -n default -l model.aibrix.ai/name=qwen-coder-7b-instruct

# Check Ray dashboard (port-forward to head pod)
kubectl port-forward pod/<head-pod-name> 8265:8265 -n default
# Then open http://localhost:8265

# Test inference through the gateway
curl http://<gateway-ip>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "model: qwen-coder-7b-instruct" \
  -d '{
    "model": "qwen-coder-7b-instruct",
    "messages": [{"role": "user", "content": "Write a binary search in Python"}],
    "max_tokens": 256
    }]}'

```

###  Check Cluster & GPU Status
```bash
rocm-smi --showmeminfo vram
rocm-smi
```


##### ray-status
```
======== Autoscaler status: 2026-03-11 11:12:15.170950 ========
Node status
---------------------------------------------------------------
Active:
 1 headgroup
 1 small-group
Idle:
 (no idle nodes)
Pending:
 (no pending nodes)
Recent failures:
 (no failures)

Resources
---------------------------------------------------------------
Total Usage:
 0.0/8.0 CPU
 2.0/2.0 GPU (2.0 used of 2.0 reserved in placement groups)
 0B/329.60GiB memory
 0B/141.26GiB object_store_memory

From request_resources:
 (none)
Pending Demands:
 (no resource demands)

```

### 3. Run Inference Requests
Once the cluster is ready, you can send inference requests to the vLLM server (default port: 8000):

#### Example: Large Code Generation
```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen-coder-7b-instruct",
    "messages": [{"role": "user", "content": "Write a 500 line Python web server with full examples"}],
    "max_tokens": 600
  }' | jq
```
```bash
curl -X POST http://134.199.201.56/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "model: qwen-coder-30b-a3b-instruct" \
  -d '{
    "model": "qwen-coder-30b-a3b-instruct",
    "messages": [{"role": "user", "content": "Write a Python web server"}],
    "max_tokens": 500
  }'
```



#### Example: Simple Hello World
```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen-coder-7b-instruct",
    "messages": [{"role": "user", "content": "Write a hello world in Python with example"}],
    "max_tokens": 100
  }' | jq
```

#### Example: Medium Code Generation
```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen-coder-7b-instruct",
    "messages": [{"role": "user", "content": "Write a 500 line Python web server with full comments"}],
    "max_tokens": 2000
  }'
```
