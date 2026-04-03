# Common Workflows

Quick recipes for the most common tasks on the platform.

---

## I want to chat with an AI model

```
Workbench → Model Catalog → Select model → Deploy for Inference → Chat with Model
```

1. Browse the [Model Catalog](../workbench/model-catalog.md)
2. Click **Deploy for Inference** on your chosen model
3. Wait ~2-5 minutes for startup
4. Click **Chat with Model** and start a conversation

---

## I want to fine-tune a model on my data

```
Prepare dataset → Upload → Workbench → Training → Configure → Launch → Monitor in MLflow
```

1. Format your data as JSONL (see [Training guide](../workbench/training.md))
2. Upload via **Workbench → Training → Datasets**
3. Configure your fine-tuning job (select model, dataset, technique)
4. Launch and monitor in **MLflow**

---

## I want to deploy a model as a production API

```
AIMs Catalog → Choose AIM → Deploy via Helm → Generate API Key → Test
```

1. Browse the [AIMs Catalog](../aims/catalog.md)
2. Follow the [Kubernetes deployment](../aims/deployment.md) guide
3. Generate an [API Key](../workbench/api-keys.md)
4. Test with `curl` or your Python client

---

## I want to give my team access

```
Resource Manager → Users → Add Users → Projects → Assign Members
```

1. Go to [Users](../resource-manager/users.md) and add team members
2. Go to [Projects](../resource-manager/projects.md) and create a project
3. Assign users to the project with appropriate roles

---

## I want to download a gated model (e.g., Llama)

1. Get Hugging Face access for the model at huggingface.co
2. Create a Hugging Face token
3. Store the token as a [Secret](../resource-manager/secrets.md) named `huggingface-token`
4. Use the **download-huggingface-model-to-bucket** reference workload

---

## I want to compare two models

```
Workbench → Inference → Deploy both models → Compare Models
```

1. Deploy both models (base model + fine-tuned checkpoint, or two different models)
2. Go to **Workbench → Inference → Compare Models**
3. Select Model A and Model B
4. Enter your test prompts

---

## I want to set up a full chat application for my team

1. Go to [Solution Blueprints](../solution-blueprints/overview.md)
2. Choose the **dev-chatui-openwebui** blueprint
3. Follow the [deployment guide](../solution-blueprints/deployment.md)
4. Share the URL with your team
