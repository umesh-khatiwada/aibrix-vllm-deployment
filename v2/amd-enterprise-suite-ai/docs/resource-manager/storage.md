# Storage

The platform uses **object storage** (similar to Amazon S3) to persist all AI data — models, datasets, checkpoints, and logs.

---

## What Gets Stored?

| Data Type | Examples |
|---|---|
| Model weights | Pre-trained models downloaded from catalog |
| Datasets | Training data uploaded by practitioners |
| Checkpoints | Fine-tuned model snapshots saved during training |
| Artifacts | MLflow logs, evaluation results |

---

## Managing Storage

Go to **Resource Manager → Storage**:

- **Create a bucket** — create a new storage bucket for a project
- **Browse contents** — view files in a bucket
- **Set permissions** — control which projects can access a bucket
- **Delete** — remove buckets (caution: permanent)

---

## Using Storage in Workloads

Storage buckets are mounted into workloads and workspaces as file paths. Typical mount point: `/data`

```python
# In JupyterLab, access your mounted storage
import os
files = os.listdir("/data/models/")
```

---

!!! tip
    Always save important files to `/data` (the storage mount), not to the local container filesystem. Container-local files are lost when a workspace stops.

---

## Official Reference

 [Storage Docs](https://enterprise-ai.docs.amd.com/en/latest/resource-manager/storage/overview.html)
