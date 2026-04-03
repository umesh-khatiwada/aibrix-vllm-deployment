# Glossary

Quick definitions for terms used throughout this guide and the AMD Enterprise AI Suite.

---

## A

**AIM (AMD Inference Microservice)**
: A pre-packaged, AMD-optimized container that serves an AI model as a REST API. AIMs are ready to deploy without custom configuration.

**API Key**
: An authentication token that allows external applications to call deployed models. Generated in the Workbench.

---

## C

**Checkpoint**
: A saved snapshot of model weights during or after training. Checkpoints let you resume training or deploy a specific version of a fine-tuned model.

**Cluster**
: A group of AMD GPU nodes managed by the platform. Workloads run on clusters.

**ComfyUI**
: An open-source node-based interface for Stable Diffusion image generation. Available as a reference workload.

**Continuous Pretraining (CPT)**
: A fine-tuning technique that extends a base model's knowledge by training on new text data — without changing the model's instruction-following behavior.

---

## F

**Fine-tuning**
: The process of adapting a pre-trained model to a specific task or domain by training it on a smaller, targeted dataset.

---

## H

**Helm**
: A Kubernetes package manager. Workloads on this platform are defined and deployed using Helm charts.

**Hugging Face**
: A platform hosting thousands of open-source AI models and datasets. The AMD Model Catalog sources many models from here.

---

## I

**Inference**
: Using a trained model to generate outputs (predictions, text, images, etc.). The opposite of training.

---

## J

**JupyterLab**
: An interactive Python notebook environment available as a workspace type in the Workbench.

---

## K

**KServe**
: A Kubernetes-based ML model serving framework that adds autoscaling, canary releases, and advanced routing to model deployments.

**kubectl**
: The command-line tool for interacting with Kubernetes clusters.

---

## L

**llama.cpp**
: An open-source LLM inference engine optimized for quantized models. Particularly efficient on AMD MI300X hardware.

**LoRA (Low-Rank Adaptation)**
: An efficient fine-tuning technique that trains only small "adapter" layers instead of all model weights — requiring much less GPU memory than full fine-tuning.

---

## M

**MLflow**
: An open-source platform for tracking ML experiments, comparing runs, and registering models. Integrated into the Workbench.

**Model Catalog**
: The built-in library of pre-trained models available in the Workbench.

---

## N

**Namespace**
: A Kubernetes concept that isolates resources. Each project gets its own namespace on the cluster.

---

## O

**Object Storage**
: File storage organized as key-value pairs (like Amazon S3). Used on this platform to store models, datasets, and artifacts.

---

## P

**Project**
: An organizational unit grouping compute, storage, users, and workloads. Projects have compute quotas and access control.

---

## R

**RBAC (Role-Based Access Control)**
: A security model where users are assigned roles (admin, developer, viewer) that determine what they can do.

---

## S

**Secret**
: An encrypted credential stored by the Resource Manager. Workloads reference secrets by name — actual values are never exposed.

**SGLang**
: An inference engine optimized for structured outputs and complex prompting patterns.

**SSO (Single Sign-On)**
: Authentication via a corporate identity provider (e.g., Okta, Azure AD). Allows users to sign in with their company credentials.

**Solution Blueprint**
: A complete, deployable AI application template combining models, interfaces, and configuration.

---

## T

**TTFT (Time to First Token)**
: A key inference metric measuring how long a model takes to start generating its response.

**TPOT (Time Per Output Token)**
: A key inference metric measuring how long each successive token takes to generate.

---

## V

**vLLM**
: A high-throughput LLM inference engine using PagedAttention for efficient GPU memory management. The most popular engine for multi-user serving.

**VLM (Vision-Language Model)**
: A model that can process both text and images as input (e.g., for image captioning, visual question answering).

---

## W

**Workload**
: Any AI job submitted to run on the cluster — training, inference, benchmarking, etc.

**Workspace**
: An isolated development environment (JupyterLab, VS Code) running on the cluster.
