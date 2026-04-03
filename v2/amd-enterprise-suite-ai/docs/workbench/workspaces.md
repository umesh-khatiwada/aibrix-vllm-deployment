# Workspaces

**Workspaces** are isolated development environments you can launch directly on the cluster. They're ideal for exploratory data analysis, prototyping, and hands-on experimentation.

---

## Available Workspace Types

### JupyterLab
An interactive Python notebook environment — the most popular choice for AI/ML work.

- Run Python, R, and shell commands interactively
- Visualize data inline
- Access your project's storage bucket
- Pre-installed with common ML libraries (PyTorch, transformers, etc.)

### VS Code (via Reference Workload)
A full browser-based VS Code IDE.

- Full IDE experience: file explorer, terminal, extensions
- Git integration
- Useful for larger codebases and script development

Launch via the `dev-workspace-vscode` reference workload.

### MLflow Tracking Server
An experiment tracking UI built into the Workbench.

- Automatically logs metrics from training jobs
- Compare runs across different hyperparameters
- Track models and artifacts
- Register production-ready models

---

## Launching a JupyterLab Workspace

1. Go to **Workbench → Workspaces**
2. Click **Create Workspace**
3. Select **JupyterLab**
4. Configure:
    - GPU allocation
    - Storage mount (your project bucket)
    - Docker image (default is pre-configured)
5. Click **Launch**

The workspace will start in 1–3 minutes. Click **Open** to access it in your browser.

!!! warning "Save Your Work"
    Workspaces are ephemeral — files saved **inside the container** (not in the mounted storage bucket) will be lost when the workspace is stopped. Always save important files to your mounted storage path.

---

## Connecting to Storage in JupyterLab

Your project's storage bucket is mounted at `/data` by default. Access your files:

```python
import os

# List files in storage
files = os.listdir("/data")
print(files)

# Load a dataset
import pandas as pd
df = pd.read_csv("/data/my-dataset.csv")
```

---

## Official Reference

 [Workspaces Docs](https://enterprise-ai.docs.amd.com/en/latest/workbench/workspaces/overview.html)
 [MLflow Tracking Server](https://enterprise-ai.docs.amd.com/en/latest/workbench/workspaces/mlflow.html)
