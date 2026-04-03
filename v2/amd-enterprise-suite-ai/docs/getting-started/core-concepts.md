# Core Concepts

Before diving into the platform, get familiar with these key terms. Understanding them will make every other part of the documentation much clearer.

---

## Workloads

A **workload** is any AI job you submit to run on the cluster. Examples include:

- Training a model from scratch
- Fine-tuning a pre-trained model
- Running batch inference
- Benchmarking throughput

Workloads are defined using **Helm charts** (Kubernetes packaging format) and submitted through the Workbench UI or CLI. The platform comes with a library of [Reference Workloads](../reference/workloads.md) you can launch immediately.

---

## Models

The platform has a **Model Catalog** containing hundreds of pre-trained models — mostly sourced from Hugging Face. You don't need to bring your own model to get started.

Models are stored in your **storage bucket** and referenced by workloads during training and inference.

!!! tip
    Some models on Hugging Face are **gated** (require approval). You'll need a Hugging Face token stored as a [Secret](../resource-manager/secrets.md) to download them.

---

## Workspaces

A **workspace** is an isolated development environment where you can write code, run experiments, and explore data. Think of it like a cloud IDE.

Available workspace types:

| Workspace | Description |
|---|---|
| **JupyterLab** | Interactive Python notebooks |
| **VS Code** | Full browser-based IDE (via reference workload) |
| **MLflow** | Experiment tracking UI |

---

## Projects

A **project** is an organizational unit that groups compute, storage, users, and workloads together. Projects give you:

- **Compute quotas** — limit how many GPUs a team can use
- **Access control** — only project members can see and run workloads
- **Usage tracking** — see spending and resource consumption per team

> Think of a project as a "team workspace" with its own budget and members.

---

## Clusters

A **cluster** is the underlying AMD GPU hardware. The Resource Manager monitors cluster health, availability, and utilization. Clusters contain:

- **Nodes** — individual machines with AMD GPUs
- **Namespaces** — Kubernetes namespaces that isolate workloads per project

---

## Inference

**Inference** means using a trained model to generate outputs — answering questions, generating images, classifying text, etc. On this platform you can:

- Deploy a model as a REST API endpoint
- Chat with it via the built-in Chat UI
- Compare two models side-by-side
- Monitor latency and throughput via Inference Metrics

---

## Fine-tuning

**Fine-tuning** adapts a general pre-trained model to your specific domain or task. For example, you might fine-tune a general LLM on your company's internal documents to make it more relevant.

Common fine-tuning techniques supported:

| Technique | Description |
|---|---|
| **Full fine-tuning** | Update all model weights (requires more GPU memory) |
| **LoRA** | Low-Rank Adaptation — efficient, fewer resources needed |
| **Continuous Pretraining** | Extend the model's knowledge on new text data |

---

## Storage

The platform uses **object storage** (similar to AWS S3 buckets) for:

- Model weights
- Training datasets
- Fine-tuned model checkpoints
- Logs and metrics

Storage is managed in the Resource Manager and shared across workloads in a project.

---

## Secrets

**Secrets** are sensitive credentials stored securely by the platform. Examples:

- Hugging Face API tokens
- External database passwords
- Cloud storage access keys

Always store credentials as Secrets — never paste them into workload configuration files.

---

## API Keys

**API Keys** are generated in the Workbench and allow external applications to call your deployed models programmatically. Each key is scoped to your project.

---

## Summary Table

| Concept | What it is | Where to manage it |
|---|---|---|
| Workload | An AI job (train, infer, etc.) | Workbench |
| Model | Pre-trained AI weights | Model Catalog / Storage |
| Workspace | Dev environment (Jupyter, VS Code) | Workbench |
| Project | Team/budget boundary | Resource Manager |
| Cluster | AMD GPU hardware | Resource Manager |
| Inference | Running a deployed model | Workbench → Inference |
| Fine-tuning | Customizing a model | Workbench → Training |
| Storage | Object storage (like S3) | Resource Manager |
| Secret | Stored credentials | Resource Manager |
| API Key | Auth token for model APIs | Workbench → API Keys |
