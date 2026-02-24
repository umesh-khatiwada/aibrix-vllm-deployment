helm repo add jetstack https://charts.jetstack.io --force-update
helm repo update


helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.15.1 \
  --set crds.enabled=true


helm repo add rocm https://rocm.github.io/gpu-operator
helm repo update


helm install amd-gpu-operator rocm/gpu-operator-charts \
  --namespace kube-amd-gpu \
  --create-namespace \
  --version v1.2.2


kubectl apply -f ./manifests/amd/amd-device-config.yaml