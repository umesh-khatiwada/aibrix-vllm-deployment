

## AIBrix: Quick Start

AIBrix is a modular, production-grade platform for deploying and managing large language models (LLMs) on Kubernetes, with support for distributed inference, autoscaling, and advanced routing.

### Clone the Repository
```bash
git clone https://github.com/vllm-project/aibrix
cd aibrix
```

### Dependencies
#### Apply required dependencies
```bash
kubectl apply -k config/dependency --server-side
```

#### Install KubeRay operator (for distributed/multi-node workloads)
```bash
helm repo add kuberay https://ray-project.github.io/kuberay-helm/
helm repo update
helm install kuberay-operator kuberay/kuberay-operator \
  --namespace kuberay-system \
  --version 1.5.1 \
  --set env[0].name=ENABLE_PROBES_INJECTION \
  --set-string env[0].value=false \
  --set fullnameOverride=kuberay-operator \
  --set featureGates[0].name=RayClusterStatusConditions \
  --set featureGates[0].enabled=true
```

#### Install CRDs
> `--install-crds` is not available in local chart installation. Install CRDs manually:
```bash
kubectl apply -f dist/chart/crds/ --server-side
```

#### Helm Install
Install AIBrix with the default values:
```bash
helm install aibrix dist/chart -n aibrix-system --create-namespace
```
Or use a custom values file:
```bash
helm install aibrix dist/chart -f my-values.yaml -n aibrix-system --create-namespace
```
### Metallb (for LoadBalancer IPs in bare-metal clusters)
```bash
helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb
```

Example Metallb configuration:
```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
    - 134.199.201.56/32
    - 129.212.177.116/32
  autoAssign: true
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default-l2
  namespace: metallb-system
spec:
  ipAddressPools:
    - default-pool
```
