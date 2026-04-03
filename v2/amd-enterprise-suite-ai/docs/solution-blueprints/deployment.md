# Deploying a Solution Blueprint

Deploy a complete AI application from the Solution Blueprints catalog.

---

## Prerequisites

- Access to a running AMD Enterprise AI Suite cluster
- `helm` and `kubectl` installed and configured
- Required [Secrets](../resource-manager/secrets.md) created (e.g., Hugging Face token)

---

## Deployment Steps

### 1. Browse the Catalog

Visit **Solution Blueprints → Catalog** and choose a blueprint that fits your use case.

### 2. Review Requirements

Each blueprint page lists:
- Required GPU type and count
- Required secrets and configuration values
- Expected deployment time

### 3. Configure Values

Each blueprint uses a Helm `values.yaml` file. Create your own overrides:

```yaml
# my-values.yaml (example for a chat UI blueprint)
model:
  name: "meta-llama/Llama-3.1-8B-Instruct"
  secretName: "huggingface-token"

ui:
  replicas: 1
  service:
    type: ClusterIP
```

### 4. Deploy with Helm

```bash
helm install my-chat-app amd-ai/dev-chatui-openwebui \
  --namespace my-project \
  -f my-values.yaml
```

### 5. Verify

```bash
# Check all pods are running
kubectl get pods -n my-project

# Get the service URL
kubectl get svc -n my-project
```

### 6. Access the Application

Port-forward or configure an ingress to access the UI:

```bash
kubectl port-forward svc/my-chat-app 8080:80 -n my-project
# Then open http://localhost:8080
```

---

## Updating a Blueprint

```bash
# Pull the latest chart version
helm repo update

# Upgrade your deployment
helm upgrade my-chat-app amd-ai/dev-chatui-openwebui \
  --namespace my-project \
  -f my-values.yaml
```

---

## Removing a Blueprint

```bash
helm uninstall my-chat-app --namespace my-project
```

---

## Official Reference

 [Blueprints Deployment Guide](https://enterprise-ai.docs.amd.com/en/latest/solution-blueprints/deployment.html)
