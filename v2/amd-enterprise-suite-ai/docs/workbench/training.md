# Training & Fine-tuning

Fine-tuning lets you customize a pre-trained model with your own data — making it more relevant, accurate, or specialized for your use case.

---

## When Should You Fine-tune?

Fine-tuning is useful when:

- A general model doesn't perform well on your domain-specific content
- You need the model to follow a specific output format
- You want to teach the model a new language or vocabulary
- You're doing continuous pretraining to extend knowledge

---

## Supported Techniques

| Technique | Description | GPU Memory |
|---|---|---|
| **Full Fine-tuning** | Update all model weights | High |
| **LoRA** | Low-Rank Adaptation — only trains small adapter layers | Low–Medium |
| **VLM LoRA** | LoRA for vision-language models | Medium |
| **Continuous Pretraining** | Extend base model's knowledge on new text | High |

!!! tip
    **LoRA is recommended for most newcomers.** It requires significantly less GPU memory than full fine-tuning and produces strong results.

---

## Step-by-Step: Fine-tune a Model

### 1. Prepare Your Dataset

Datasets should be in **JSONL** (recommended) or **CSV** format.

**JSONL example (instruction fine-tuning):**
```jsonl
{"prompt": "What is the capital of France?", "response": "The capital of France is Paris."}
{"prompt": "Summarize this text: ...", "response": "This text discusses..."}
```

Go to **Workbench → Training → Datasets** and upload your file.

### 2. Configure the Fine-tuning Job

Go to **Workbench → Training** and:

1. Select your **base model** from the catalog
2. Select your **dataset**
3. Choose your **fine-tuning technique** (LoRA recommended)
4. Set training parameters:
    - Learning rate
    - Number of epochs
    - Batch size
    - LoRA rank (if using LoRA)

### 3. Launch and Monitor

Click **Launch**. The job will be submitted to the cluster. You can:

- Watch job status in the Workbench
- Track metrics (loss, accuracy) in **MLflow**
- View GPU utilization in the Resource Manager

### 4. Evaluate and Deploy

When training completes:

1. The fine-tuned model checkpoint is saved to your storage bucket
2. Evaluate quality by deploying it for [inference](inference.md)
3. Chat with it and compare results to the base model

---

## Tutorials

| Tutorial | Format | Description |
|---|---|---|
| [Low-code Fine-tuning](https://enterprise-ai.docs.amd.com/en/latest/tutorials/low-code-fine-tuning-tutorial.html) | GUI | No-code walkthrough, recommended for beginners |
| [Fine-tuning in JupyterLab](https://enterprise-ai.docs.amd.com/en/latest/tutorials/fine-tune-in-jupyterlab.html) | GUI / Notebook | Code-based fine-tuning |
| [Dataset Preparation](https://enterprise-ai.docs.amd.com/en/latest/tutorials/dataset-preparation-tutorial.html) | GUI | How to format and upload datasets |
| [Deliver Resources & Fine-tune](https://enterprise-ai.docs.amd.com/en/latest/ai-workloads-docs/tutorials/tutorial-01-deliver-resources-and-finetune.html) | CLI | Command-line fine-tuning walkthrough |
| [Language Extension (Odia)](https://enterprise-ai.docs.amd.com/en/latest/ai-workloads-docs/tutorials/tutorial-02-language-extension-finetune.html) | CLI | Fine-tune for a new language |
| [Llama 3.1-8B Pretraining](https://enterprise-ai.docs.amd.com/en/latest/ai-workloads-docs/tutorials/tutorial-03-deliver-resources-and-run-megatron-cpt.html) | CLI | Continuous pretraining with Megatron |

---

## Official Reference

 [Training & Fine-tuning Docs](https://enterprise-ai.docs.amd.com/en/latest/workbench/training/overview.html)
