# Secrets

**Secrets** are encrypted credentials stored securely by the platform. Workloads reference secrets by name — the actual values are never exposed in configuration files or logs.

---

## What to Store as Secrets

| Secret | Used For |
|---|---|
| Hugging Face token | Downloading gated models from HuggingFace Hub |
| AWS / S3 credentials | Accessing external object storage |
| External API keys | Third-party services used in workloads |
| Database passwords | Connecting to external databases |
| Registry credentials | Pulling private Docker images |

---

## Creating a Secret

1. Go to **Resource Manager → Secrets**
2. Click **Create Secret**
3. Enter:
    - **Name** — used to reference the secret in workloads (e.g., `huggingface-token`)
    - **Value** — the actual credential
4. Click **Save**

The value is encrypted and stored. It cannot be viewed again after creation.

---

## Using a Secret in a Workload

Reference secrets by name in your workload configuration:

```yaml
# Example Helm values
env:
  - name: HF_TOKEN
    valueFrom:
      secretKeyRef:
        name: huggingface-token
        key: value
```

---

!!! danger "Never Hardcode Credentials"
    Do not paste tokens, passwords, or API keys directly into workload YAML files or Jupyter notebooks. Always use Secrets.

---

## Official Reference

 [Secrets Docs](https://enterprise-ai.docs.amd.com/en/latest/resource-manager/secrets/overview.html)
