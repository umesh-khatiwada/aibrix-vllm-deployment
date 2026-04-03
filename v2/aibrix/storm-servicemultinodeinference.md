# Why Does AIBrix Need StormService in Addition to Ray?

A common question in distributed system design is: If Ray already provides distributed computing, why does AIBrix introduce another Custom Resource Definition (CRD) called StormService? This is a valid concern, as good architecture avoids unnecessary layers.

## Distinct Responsibilities: StormService vs. RayClusterFleet
AIBrix exposes two CRDs for managing inference workloads, each targeting a different architectural layer:

| Responsibility                                 | CRD             |
|------------------------------------------------|-----------------|
| Inference service architecture (prefill/decode routing, scaling) | StormService     |
| Distributed compute cluster (multi-node GPU execution)           | RayClusterFleet  |

- **StormService**: Handles service orchestration—defining roles (prefill, decode), routing, and scaling.
- **RayClusterFleet**: Manages distributed compute infrastructure—multi-node GPU execution, cluster lifecycle.

These CRDs operate at different layers and do not duplicate functionality.

---

## RayClusterFleet: The Multi-Node Compute Layer
[`RayClusterFleet`](aibrix/multi-node-inference/rayclusterfleet.yaml) is responsible for creating and managing Ray clusters on Kubernetes. Its role is to provide a distributed execution environment for large-scale model inference.

**Conceptual Hierarchy:**
```
RayClusterFleet
   ↓
RayCluster
   ↓
Ray Head Pod
Ray Worker Pods
```
Ray then handles:
- Distributed scheduling
- Tensor/pipeline parallelism
- Multi-node model execution
- GPU coordination

**Key Point:** RayClusterFleet is not an inference service abstraction; it is the distributed compute substrate.

---

## StormService: The Inference Service Layer
StormService is designed specifically for LLM inference architecture. It defines:
- Prefill workers
- Decode workers
- Routing between roles
- Independent scaling policies

**Example Structure:**
```
StormService
   ↓
RoleSet
   ↓
Roles
   ├─ Prefill
   └─ Decode
```
StormService manages:
- Inference pods
- Scaling policies
- Role separation
- Service routing

**Key Point:** StormService does not manage distributed compute across nodes; it orchestrates the inference service architecture.

---

## The Two Core Problems in Modern LLM Inference
Modern LLM inference faces two distinct challenges:

### 1. Distributed Compute
Large models often cannot fit on a single GPU or machine.

| Model Size | GPUs Needed |
|------------|------------|
| 7B         | 1 GPU      |
| 70B        | 8 GPUs     |
| 405B       | 64+ GPUs   |

**Solution:** Distribute execution across machines (model parallelism) using frameworks like Ray, MPI, or DeepSpeed. Ray handles distributed execution, GPU scheduling, and worker coordination.

### 2. Inference Architecture
Efficiently serving requests is challenging even if the model fits on a node. LLM inference has two phases:
- **Prefill phase**: Processes the prompt (compute-heavy, short, parallelizable)
- **Decode phase**: Generates tokens one by one (long-running, latency-sensitive, less parallel)

**Production systems separate these phases:**
```
Client
   ↓
Router
   ↓
Prefill workers
   ↓
Decode workers
   ↓
Response
```
This is called **PD Disaggregation** (Prefill–Decode separation).

---

## Why Ray Alone Cannot Solve PD Disaggregation
Ray is excellent for distributed computing but does not provide LLM service architecture. Ray sees everything as tasks or actors, but does not understand prefill/decode roles, request routing, or scaling policies for these roles. It only handles task execution, worker scheduling, and distributed compute—not inference pipelines.

---

## What StormService Actually Does
StormService is purpose-built for LLM inference services. It defines a structured service architecture:
- Role definitions (prefill, decode)
- Pod creation and scaling
- Routing between roles

**Example Deployment:**
- Prefill pods: 4
- Decode pods: 16

StormService is essentially an LLM inference service orchestrator.

---

## The Three Architectural Layers
AIBrix's architecture separates concerns into three layers:

### Layer 1 — Inference Service
Handles requests, routing, and scaling.
- **Component:** StormService
- **Example Flow:**
  - User Request → Gateway → Prefill Workers → Decode Workers → Response

### Layer 2 — Distributed Compute
If the model is large, each worker may require multiple nodes.
- **Component:** RayCluster
- **Example:**
  - Decode worker → Ray distributed execution → multiple GPUs

### Layer 3 — GPU Execution
The actual inference engine (e.g., vLLM, SGLang) runs inside the pods.

---

## How StormService and Ray Work Together
When combined, the architecture looks like this:
```
Client
   ↓
AIBrix Gateway
   ↓
StormService
   ↓
Prefill Role
   ↓
RayCluster
   ↓
Distributed GPUs
```
| Layer              | Technology      |
|--------------------|----------------|
| Request routing    | AIBrix Gateway |
| Service orchestration | StormService |
| Distributed compute | Ray           |
| Model execution    | vLLM           |

---

## In Summary
StormService and Ray solve different problems:
- **StormService**: Manages the inference service architecture (prefill/decode roles, routing, scaling)
- **Ray**: Manages distributed execution across machines

AIBrix separates these concerns for clarity, scalability, and operational efficiency. StormService defines the service-level orchestration, while RayClusterFleet provides the distributed compute environment required for large-scale LLM inference.
