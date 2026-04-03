# Prometheus Helm repo
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/prometheus \
  -f prometheus-values.yaml \
  --namespace monitoring --create-namespace
```
### prometheus-values.yaml
```
server:
  persistentVolume:
    enabled: true
    size: 50Gi
    storageClass: default
  nodeSelector:
    kubernetes.io/hostname: main
  tolerations: []
alertmanager:
  persistentVolume:
    enabled: false
```

# Grafana Helm repo
```
helm repo add grafana https://grafana.github.io/helm-charts
helm install grafana grafana/grafana \
  -f grafana-values.yaml \
  --namespace monitoring
```
### grafana-values.yaml
```
persistence:
  enabled: true
  size: 50Gi
  storageClassName: default

nodeSelector:
  kubernetes.io/hostname: main

tolerations: []
service:
  type: ClusterIP
  port: 3000

adminUser: admin
adminPassword: admin
root@main:~/charts#
```




Grafana Dashboard


(AIBrix Control Plane Runtime Dashboard)[https://raw.githubusercontent.com/vllm-project/aibrix/main/observability/grafana/AIBrix_Control_Plane_Runtime_Dashboard.json]

(AIBrix Envoy Gateway Dashboard)[https://raw.githubusercontent.com/vllm-project/aibrix/main/observability/grafana/AIBrix_vLLM_Engine_Dashboard.json]

(AIBrix vLLM Engine Dashboard)[https://raw.githubusercontent.com/vllm-project/aibrix/main/observability/grafana/AIBrix_Envoy_Gateway_Dashboard.json]
