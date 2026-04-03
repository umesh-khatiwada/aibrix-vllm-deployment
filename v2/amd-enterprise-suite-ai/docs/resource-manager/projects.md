# Projects

**Projects** are organizational units that group compute, storage, users, and workloads together. Every workload on the platform belongs to a project.

---

## Why Projects?

Projects give you:

- **Isolation** — workloads in one project don't interfere with another
- **Quotas** — limit how many GPUs a team can use at once
- **Access control** — only project members can see and run workloads
- **Cost tracking** — monitor resource consumption per team or initiative

---

## Creating a Project

1. Go to **Resource Manager → Projects**
2. Click **Create Project**
3. Fill in:
    - **Project name** — e.g., `team-nlp` or `customer-service-bot`
    - **Description**
    - **Compute quota** — maximum GPUs allowed
4. Click **Create**

---

## Project Dashboard

Each project has its own dashboard showing:

- Active workloads and their GPU consumption
- Storage usage
- Recent activity

Go to **Resource Manager → Projects → [Your Project] → Dashboard**

---

## Project Settings

Configure your project from **Projects → [Your Project] → Settings**:

- Adjust compute quotas
- Change project description
- View assigned users

---

## Adding Users to a Project

1. Go to **Resource Manager → Projects → [Your Project]**
2. Click **Members** or navigate to [Users](users.md)
3. Assign users with a role:
    - **Admin** — full access, can manage project settings and members
    - **Developer** — can create and run workloads
    - **Viewer** — read-only access

---

## Official Reference

 [Projects Docs](https://enterprise-ai.docs.amd.com/en/latest/resource-manager/projects/manage-projects.html)
