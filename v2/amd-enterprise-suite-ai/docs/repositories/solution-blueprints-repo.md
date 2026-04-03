# solution-blueprints

[github.com/amd-enterprise-ai/solution-blueprints](https://github.com/amd-enterprise-ai/solution-blueprints) · Python / Helm · MIT License

---

## What Is It?

`solution-blueprints` (also known as **AIMSB — AIM Solution Blueprints**) contains the source code and Helm charts for end-to-end AI application templates that run on the AMD Enterprise AI Suite.

This is the open-source backing for the **Solution Blueprints** feature in the platform UI.

---

## Repository Structure

```
solution-blueprints/
├── aimcharts/            ← Helm charts for AIM-based deployments
└── solution-blueprints/  ← Blueprint definitions and code
```

---

## What Are Solution Blueprints?

Solution Blueprints are **pre-built, deployable AI applications** that combine AIMs, frontends, storage, and configuration into one package. Instead of assembling components yourself, you deploy a blueprint and get a working application.

The blueprints in this repo are the source of what appears in the platform's Solution Blueprints catalog.

---

## Relationship to the Platform

```
solution-blueprints repo
    ↓  (packaged as Helm charts via aimcharts/)
Platform Solution Blueprints Catalog
    ↓  (deployed by users via)
Workbench UI  OR  helm install
```

---

## Using Blueprints

You generally interact with blueprints through the platform UI or by deploying Helm charts directly. See the [Solution Blueprints deployment guide](../solution-blueprints/deployment.md) for step-by-step instructions.

To contribute or customize a blueprint, clone this repo and work with the Helm charts in `aimcharts/`.

---

## Versioning

Solution Blueprints follow [Semantic Versioning](https://semver.org/).

---

## Source & License

[github.com/amd-enterprise-ai/solution-blueprints](https://github.com/amd-enterprise-ai/solution-blueprints)
