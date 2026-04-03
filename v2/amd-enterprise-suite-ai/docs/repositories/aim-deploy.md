# aim-deploy

[github.com/amd-enterprise-ai/aim-deploy](https://github.com/amd-enterprise-ai/aim-deploy)

---

## What Is It?

`aim-deploy` is a **reference implementation repository** containing example manifests and scripts for deploying AIMs (AMD Inference Microservices) in different environments. It is the practical complement to `aim-build` — where `aim-build` produces the containers, `aim-deploy` shows you how to run them.

!!! note

    This repo is explicitly described as a reference/example implementation. Use it as your starting point, then adapt to your specific environment.

---

## What's Included

```
aim-deploy/
├── docker/     ← Docker-based deployment examples
├── k8s/        ← Kubernetes deployment manifests
└── kserve/     ← KServe deployment manifests
```

---

## Deployment Options

### Kubernetes

Deploy an AIM on a Kubernetes cluster using the sample minimal deployment:

[k8s/sample-minimal-aims-deployment/README.md](https://github.com/amd-enterprise-ai/aim-deploy/blob/main/k8s/sample-minimal-aims-deployment/README.md)

This gives you a minimal but complete Kubernetes manifest that you can extend.

### KServe

Deploy an AIM using KServe for production-grade serving with autoscaling:

[kserve/README.md](https://github.com/amd-enterprise-ai/aim-deploy/blob/main/kserve/README.md)

---

## When to Use This vs. aim-build

| Use `aim-build` when… | Use `aim-deploy` when… |
|---|---|
| You need to build or customize AIM containers | You have a container and need deployment manifests |
| You're working on profiles or runtime logic | You're wiring up Kubernetes or KServe resources |
| You need the CLI (`dry-run`, `list-profiles`) | You need a minimal working deployment to start from |

---

## Source & License

[github.com/amd-enterprise-ai/aim-deploy](https://github.com/amd-enterprise-ai/aim-deploy)
