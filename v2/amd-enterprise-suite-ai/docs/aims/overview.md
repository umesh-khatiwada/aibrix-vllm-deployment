# AMD Inference Microservices (AIMs) Overview

**AIM** stands for **AMD Inference Microservice**. AIMs provide standardized, portable inference microservices for serving AI models on **AMD Instinct™ GPUs**, using **ROCm 7** under the hood.

AIMs are distributed as **Docker images**, making them easy to deploy and manage across different environments. They abstract away the complexity of configuring and serving AI models by automatically choosing optimal runtime parameters based on your input, hardware, and model specifications.

AIMs expose an **OpenAI-compatible API** for LLMs, so they integrate easily with any application that already works with OpenAI's API.

---

## Features

### Broad Model Support
- Community models, custom fine-tuned models, and popular foundation models are all supported.

### Intelligent Configuration via Profiles
- **Profiles** are predefined configurations optimized for specific models and hardware.
- Profile selection is **automatic** — the best profile is chosen based on your input, hardware, and model.
- You can bypass automatic selection and specify a profile directly using an environment variable.
- **Custom profiles** can be created to suit your specific needs.
- All published profiles are validated against a schema, tested on target hardware, and optimized for throughput or latency.

### Model Downloading and Caching
- Models can be downloaded from **HuggingFace** or **S3**.
- Downloaded models are cached to speed up subsequent runs.
- Downloading **gated models** from Hugging Face is supported.

### Integration-Friendly
- Container-level logging compatible with orchestrating frameworks.
- **AIM Runtime CLI** simplifies integration with Kubernetes and other orchestrators.
- OpenAI-compatible API means no changes needed in existing LLM applications.

---

## Deployment Options

| Method | Use Case |
|---|---|
| [Kubernetes](deployment.md#kubernetes) | Standard production deployment on your cluster |
| [KServe](deployment.md#kserve) | Advanced ML serving with autoscaling |
| [Docker](deployment.md#docker) | Quick single-node testing or local development |

---

## Terminology Reference

| Term | Meaning |
|---|---|
| **AIM** | AMD Inference Microservice |
| **Docker** | Platform for running applications in containers |
| **GPU** | Graphics Processing Unit — essential hardware for AI models |
| **HF** | Hugging Face — platform for sharing ML models and datasets |
| **LLM** | Large Language Model |
| **Profile** | A predefined AIM run configuration optimized for specific models, compute, or use cases |
| **ROCm** | Radeon Open Compute — AMD's open software platform for GPU computing |
| **S3** | Amazon Simple Storage Service — scalable object storage |
| **YAML** | Human-readable configuration file format |

---

## Official Reference

 [AIMs Overview](https://enterprise-ai.docs.amd.com/en/latest/aims/overview.html)
