# Quick Start Guide

Get up and running on the AMD Enterprise AI Suite in minutes. Choose your path below.

---

## Step 1: Log In

Navigate to your organization's AMD Enterprise AI Suite URL and sign in.

Your admin will have set up one of these:

- **SSO (Single Sign-On)** — use your company credentials
- **Email invitation** — check your inbox for a setup link
- **Manual account** — contact your admin for credentials

[Detailed Login Instructions →](login.md)

---

## Step 2: Choose Your Path

=== "🤖 I want to run an AI model"

    **Goal:** Deploy a model and start chatting with it.

    1. Go to **AMD AI Workbench** from the main dashboard
    2. Click **Model Catalog** and pick a model (e.g., `Llama-3.1-8B`)
    3. Click **Deploy for Inference**
    4. Once deployed, click **Chat with Model**
    5. Start asking questions!

    **Time to complete:** ~10 minutes

    [Full Inference Guide →](../workbench/inference.md)

=== "🔧 I want to fine-tune a model"

    **Goal:** Customize a model with your own data.

    1. Prepare your dataset as a CSV or JSONL file
    2. Go to **Workbench → Training → Datasets** and upload it
    3. Go to **Workbench → Training** and configure your fine-tuning job
    4. Select your base model and dataset
    5. Launch the job and track progress in **MLflow**

    **Time to complete:** Setup ~15 min, training time varies

    [Full Fine-tuning Guide →](../workbench/training.md)

=== "⚙️ I'm setting up the platform"

    **Goal:** Install and configure AMD Enterprise AI Suite for your team.

    1. Review [Platform Overview](overview.md) and [Supported Environments](https://enterprise-ai.docs.amd.com/en/latest/platform-infrastructure/supported-environments.html)
    2. Follow the [On-premises Installation Guide](https://enterprise-ai.docs.amd.com/en/latest/platform-infrastructure/on-premises-installation.html) or [DigitalOcean Guide](https://enterprise-ai.docs.amd.com/en/latest/platform-infrastructure/digitalocean-installation.html)
    3. Set up [Users & Access](../resource-manager/users.md)
    4. Create your first [Project](../resource-manager/projects.md)
    5. Verify the cluster is healthy in the [Resource Manager](../resource-manager/overview.md)

    **Time to complete:** 30–60 minutes depending on environment

=== "👥 I'm managing a team"

    **Goal:** Set up projects, add users, and manage compute access.

    1. Go to **AMD Resource Manager** from the dashboard
    2. Click **Projects → Create Project**
    3. Set a compute quota for the project
    4. Go to **Users → Add Users** and invite your team
    5. Assign users to the project with appropriate roles

    **Time to complete:** ~15 minutes

    [Full User Management Guide →](../resource-manager/users.md)

---

## Step 3: Explore Further

Once you're comfortable with the basics, explore:

- [Reference Workloads](../reference/workloads.md) — pre-built jobs you can launch immediately
- [Solution Blueprints](../solution-blueprints/overview.md) — full AI applications ready to deploy
- [AIMs Catalog](../aims/catalog.md) — production-ready inference microservices

---

!!! tip "Official Quick Starts"
    The AMD documentation also has official quick start guides:

    - [Platform Quick Start](https://enterprise-ai.docs.amd.com/en/latest/quick-start.html)
    - [AI Workbench Quick Start](https://enterprise-ai.docs.amd.com/en/latest/workbench/quick-start.html)
    - [Resource Manager Quick Start](https://enterprise-ai.docs.amd.com/en/latest/resource-manager/quick-start.html)
