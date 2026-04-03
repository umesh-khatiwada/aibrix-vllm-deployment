# Inference

**Inference** is the process of using a deployed model to generate outputs. The Workbench provides a complete inference UI — from deployment to monitoring.

---

## Inference Features

| Feature | Description |
|---|---|
| [Deploy a Model](#deploying-a-model) | Launch a model as a running service |
| [Chat with Model](#chat-with-model) | Interact with your model via a chat UI |
| [Compare Models](#compare-models) | Run two models side-by-side |
| [Advanced Deployment](#advanced-deployment-options) | Configure replicas, GPU allocation, quantization |
| [Inference Metrics](#inference-metrics) | Monitor latency, throughput, and token rates |

---

## Deploying a Model

1. Go to **Workbench → Inference**
2. Click **Deploy Model**
3. Select your model from the catalog (or a fine-tuned checkpoint)
4. Choose deployment settings (see [Advanced Options](#advanced-deployment-options) for details)
5. Click **Deploy**

The model will start up on the cluster. Startup time is typically 2–5 minutes depending on model size.

!!! note
    Once deployed, a model runs continuously and consumes GPU resources. **Stop or delete deployments when not in use** to free up compute.

---

## Chat with Model

Once your model is deployed:

1. Go to **Workbench → Inference → Chat with Model**
2. Select your deployed model
3. Start a conversation

The chat interface supports:
- System prompts (to set model behavior)
- Temperature and sampling settings
- Conversation history

[Official Guide →](https://enterprise-ai.docs.amd.com/en/latest/workbench/inference/chat.html)

---

## Compare Models

Run two deployed models side-by-side with the same prompt:

1. Go to **Workbench → Inference → Compare Models**
2. Select **Model A** and **Model B**
3. Enter your prompt
4. Review outputs from both models simultaneously

This is useful for evaluating a fine-tuned model against its base model.

[Official Guide →](https://enterprise-ai.docs.amd.com/en/latest/workbench/inference/compare.html)

---

## Advanced Deployment Options

Configure how your model is served:

| Option | Description |
|---|---|
| **Replicas** | Number of model instances (for load balancing) |
| **GPU allocation** | Which GPUs to use and how many |
| **Quantization** | Reduce model precision to save memory (e.g., INT4, INT8) |
| **Max context length** | Maximum tokens per request |
| **Inference engine** | vLLM, SGLang, or llama.cpp |

[Official Guide →](https://enterprise-ai.docs.amd.com/en/latest/workbench/inference/deployment-options.html)

---

## Inference Metrics

Monitor performance of your deployed model:

- **Latency** — time to first token (TTFT) and time per output token (TPOT)
- **Throughput** — tokens per second across all requests
- **Request queue** — number of pending requests
- **GPU utilization** — how hard the hardware is working

[Official Guide →](https://enterprise-ai.docs.amd.com/en/latest/workbench/inference/metrics.html)

---

## Calling the Model via API

Once deployed, your model is accessible as a REST API. Get your [API Key](api-keys.md) and:

```python
import requests

response = requests.post(
    "https://your-platform-url/v1/chat/completions",
    headers={"Authorization": "Bearer YOUR_API_KEY"},
    json={
        "model": "your-deployed-model-name",
        "messages": [{"role": "user", "content": "Hello!"}]
    }
)

print(response.json()["choices"][0]["message"]["content"])
```

The API is **OpenAI-compatible**, so most OpenAI client libraries work out of the box.

---

## Tutorial

:material-play: [Deploy a Model and Run Inference — Step by Step](https://enterprise-ai.docs.amd.com/en/latest/workbench/inference/how-to-deploy-and-inference.html)
