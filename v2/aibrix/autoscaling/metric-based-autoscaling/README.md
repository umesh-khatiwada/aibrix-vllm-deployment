# Metric-Based Autoscaling

This directory contains examples of metric-based autoscaling configurations for AIBrix deployments. These configurations demonstrate different autoscaling strategies to dynamically adjust the number of pod replicas based on various metrics.

## Overview

Metric-based autoscaling automatically adjusts the number of running pods based on observed metrics such as CPU utilization, memory usage, or custom application metrics. This ensures optimal resource utilization and maintains application performance under varying workloads.

## Autoscaling Strategies

### 1. Horizontal Pod Autoscaler (HPA)

The Kubernetes-native Horizontal Pod Autoscaler scales pods based on resource metrics.

```yaml
apiVersion: autoscaling.aibrix.ai/v1alpha1
kind: PodAutoscaler
metadata:
  name: qwen-coder-1-5b-instruct-hpa
  namespace: default
  labels:
    app.kubernetes.io/name: aibrix
spec:
  scalingStrategy: HPA
  minReplicas: 1
  maxReplicas: 10
  metricsSources:
    - metricSourceType: pod
      protocolType: http
      port: '8000'
      path: /metrics
      targetMetric: kv_cache_usage_perc
      targetValue: '50'
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: qwen-coder-1-5b-instruct
```

**Key Features:**

- Native Kubernetes resource
- Scales based on CPU utilization (50% target)
- Replica range: 1-4 pods
- Simple configuration for resource-based scaling

**Use Cases:**

- General workloads where CPU is the primary bottleneck
- Applications without custom metrics requirements

---

### 2. KPA (Knative-style Pod Autoscaler)

AIBrix's KPA provides Knative-style autoscaling with panic mode and stable window configurations.

```yaml
apiVersion: autoscaling.aibrix.ai/v1alpha1
kind: PodAutoscaler
metadata:
  name: qwen-coder-lora-autoscaler
  namespace: default
  labels:
    app.kubernetes.io/name: aibrix
  annotations:
    kpa.autoscaling.aibrix.ai/scale-down-delay: 3m
spec:
  scalingStrategy: KPA
  minReplicas: 1
  maxReplicas: 2
  metricsSources:
    - metricSourceType: pod
      protocolType: http
      port: "8000"
      path: metrics/
      targetMetric: "num_requests_running"
      targetValue: "5"
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: qwen-coder-1-5b-instruct
```

**Key Features:**

- Knative-style autoscaling algorithm
- Custom metrics from pod endpoints (e.g., `num_requests_running`)
- Configurable scale-down delay to prevent thrashing
- Support for panic mode (rapid scale-up) and stable window configurations

**Available Annotations:**

| Annotation | Description | Example |
|------------|-------------|---------|
| `kpa.autoscaling.aibrix.ai/stable-window` | Time window for stable scaling decisions | `60s` |
| `kpa.autoscaling.aibrix.ai/panic-window` | Time window for panic mode detection | `10s` |
| `kpa.autoscaling.aibrix.ai/panic-threshold` | Percentage threshold to trigger panic mode | `110` |
| `kpa.autoscaling.aibrix.ai/scale-down-delay` | Delay before scaling down | `120s`, `3m` |

**Use Cases:**

- LLM inference workloads with bursty traffic
- Applications requiring rapid scale-up during traffic spikes
- Workloads where request concurrency is the key metric

---

### 3. APA (Adaptive Pod Autoscaler)

AIBrix's APA provides adaptive autoscaling with fluctuation tolerance for smoother scaling behavior.

```yaml
apiVersion: autoscaling.aibrix.ai/v1alpha1
kind: PodAutoscaler
metadata:
  name: qwen-coder-1-5b-instruct-apa
  namespace: default
  labels:
    app.kubernetes.io/name: aibrix
    app.kubernetes.io/managed-by: kustomize
  annotations:
    autoscaling.aibrix.ai/up-fluctuation-tolerance: '0.1'
    autoscaling.aibrix.ai/down-fluctuation-tolerance: '0.2'
    apa.autoscaling.aibrix.ai/window: 30s
spec:
  scalingStrategy: APA
  minReplicas: 1
  maxReplicas: 8
  metricsSources:
    - metricSourceType: pod
      protocolType: http
      port: '8000'
      path: metrics
      targetMetric: kv_cache_usage_perc
      targetValue: '0.01'
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: qwen-coder-1-5b-instruct
```

**Key Features:**

- Adaptive scaling with fluctuation tolerance
- Prevents unnecessary scaling due to minor metric variations
- Custom metrics support (e.g., `kv_cache_usage_perc` for KV cache utilization)
- Configurable observation window

**Available Annotations:**

| Annotation | Description | Example |
|------------|-------------|---------|
| `autoscaling.aibrix.ai/up-fluctuation-tolerance` | Tolerance for scale-up decisions (percentage) | `0.1` (10%) |
| `autoscaling.aibrix.ai/down-fluctuation-tolerance` | Tolerance for scale-down decisions (percentage) | `0.2` (20%) |
| `apa.autoscaling.aibrix.ai/window` | Observation window for metric averaging | `30s` |


## Common Metrics for LLM Workloads

When configuring metric-based autoscaling for LLM inference, consider these metrics:

| Metric | Description | Typical Target |
|--------|-------------|----------------|
| `num_requests_running` | Number of concurrent requests being processed | 5-10 per pod |
| `kv_cache_usage_perc` | KV cache memory utilization percentage | 0.5-0.8 |
| `num_requests_waiting` | Number of requests in queue | 0-5 |
| `gpu_utilization` | GPU compute utilization | 70-90% |


## Related Documentation

- [AIBrix Autoscaling Documentation](https://aibrix.readthedocs.io/latest/features/autoscaling/metric-based-autoscaling.html)
- [vLLM Metrics](https://docs.vllm.ai/en/stable/design/metrics/)
- [Multi Engine Support](https://aibrix.readthedocs.io/latest/features/multi-engine.html)
