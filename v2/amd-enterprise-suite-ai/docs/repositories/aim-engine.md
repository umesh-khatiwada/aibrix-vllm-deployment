# Aim-Engine

[github.com/amd-enterprise-ai/aim-engine](https://github.com/amd-enterprise-ai/aim-engine)

## What Is It?

`aim-engine` is the **AIM runtime engine**, written in Go. It is a lower-level component that underpins the AIM container system — handling the core runtime logic that `aim-build` packages into Docker images.

!!! note
    This repo is the most technical of the AIM repositories. Most users interacting with AIMs via the Workbench UI, Kubernetes, or Docker will not need to work with `aim-engine` directly. It is primarily relevant to contributors and advanced users building custom AIM integrations.

---

## Relationship to Other AIM Repos

```
aim-engine  (Go runtime core)
    ↓
aim-build   (Python — packages runtime into Docker, manages profiles)
    ↓
aim-deploy  (Shell/Helm — example deployment manifests)
```

---

## Source & License

[github.com/amd-enterprise-ai/aim-engine](https://github.com/amd-enterprise-ai/aim-engine)
