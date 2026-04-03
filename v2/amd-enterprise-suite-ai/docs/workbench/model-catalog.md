# Model Catalog

The **Model Catalog** is your library of pre-trained AI models. Browse, search, and select models to deploy or fine-tune — no need to source models yourself.

---

## Browsing the Catalog

1. Open **AMD AI Workbench** from the dashboard
2. Click **Model Catalog** in the left navigation
3. Use filters to narrow by:
    - Task type (text generation, image generation, vision, etc.)
    - Model size (number of parameters)
    - License type

---

## Downloading a Model

Models are downloaded to your project's **storage bucket**. To download:

1. Select a model from the catalog
2. Click **Download to Storage**
3. The platform pulls the model weights (from Hugging Face or internal registry)
4. Once complete, the model is available for inference and training workloads

!!! warning "Gated Models"
    Some models (like Meta's Llama family) require approval from the model publisher. You'll need:

    1. A Hugging Face account with access granted
    2. A Hugging Face token stored as a [Secret](../resource-manager/secrets.md)

    See the [Create a Hugging Face Token tutorial](https://enterprise-ai.docs.amd.com/en/latest/tutorials/create-hugging-face-token.html) for step-by-step instructions.

---

## Using a Model

Once downloaded, a model can be:

- **Deployed for inference** → [Inference Guide](inference.md)
- **Used as a base for fine-tuning** → [Training Guide](training.md)

---

## Popular Models in the Catalog

| Model Family | Type | Use Case |
|---|---|---|
| Llama 3.1 (8B, 70B) | LLM | General text generation, chat |
| Mistral / Mixtral | LLM | Fast chat, instruction following |
| Qwen | LLM | Multilingual text generation |
| Stable Diffusion | Image Gen | Text-to-image generation |
| SwinUNETR | Vision | Medical image segmentation |
| PanGu / GenCast | Weather | Weather forecasting |

---

## Official Reference

 [Model Catalog Docs](https://enterprise-ai.docs.amd.com/en/latest/workbench/models.html)
