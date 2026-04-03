# Prefill-Decode Disaggregation with SGLang on AMD Instinct™ MI300X GPUs

This guide demonstrates how to deploy a disaggregated LLM serving architecture using SGLang on AMD Instinct™ MI300X GPUs. By separating prefill and decode phases into dedicated servers, you can optimize GPU utilization and improve inference performance.

## Overview

### What is Prefill-Decode Disaggregation?

In traditional LLM serving, a single server handles both:

- **Prefill Phase**: Processing the input prompt and generating the KV cache
- **Decode Phase**: Generating output tokens one at a time using the KV cache

Disaggregation separates these phases into specialized servers:

```
┌─────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Client    │────▶│  Load Balancer  │────▶│  Prefill Server │
│             │     │   (Mini LB)     │     │  (KV Generation)│
└─────────────┘     └────────┬────────┘     └────────┬────────┘
                             │                       │
                             │                       │ KV Cache Transfer
                             │                       ▼
                             │              ┌─────────────────┐
                             └─────────────▶│  Decode Server  │
                                            │ (Token Gen)     │
                                            └─────────────────┘
```

### Benefits

- **Optimized GPU Utilization**: Each server is tuned for its specific workload
- **Independent Scaling**: Scale prefill and decode servers based on demand
- **Better Memory Management**: Different memory configurations for each phase
- **Improved Throughput**: Parallel processing of prefill and decode operations

## Prerequisites

### Environment Setup

```bash
# Install Python virtual environment
apt install python3-venv

# Create and activate virtual environment
python3 -m venv env
source env/bin/activate

# Install Hugging Face Hub
pip install huggingface_hub

# Authenticate with Hugging Face
hf auth login

# Download the model
hf download meta-llama/Llama-3.2-1B --local-dir /home/amd/models/llama3-1b
```

### Kubernetes Requirements

- Kubernetes cluster with AMD GPU support
- AMD device plugin installed (`amd.com/gpu` resource available)
- Namespace `sglang` created

```bash
kubectl create namespace sglang
```

---

## Architecture Components

### 1. Prefill Server

The prefill server processes input prompts and generates KV caches.

#### Service Definition

```yaml
apiVersion: v1
kind: Service
metadata:
  name: sglang-prefill
  namespace: sglang
spec:
  selector:
    app: sglang-prefill
  ports:
    - protocol: TCP
      port: 8998
      name: grpc-bootstrap
      targetPort: 8998
    - protocol: TCP
      port: 8898
      name: http
      targetPort: 8898
  type: NodePort
```

#### Deployment Definition

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sglang-prefill
  namespace: sglang
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sglang-prefill
  template:
    metadata:
      labels:
        app: sglang-prefill
    spec:
      restartPolicy: Always
      containers:
        - name: sglang-prefill
          image: lmsysorg/sglang:v0.5.8-rocm700-mi30x
          resources:
            limits:
              amd.com/gpu: 2
          command: ["python3", "-m", "sglang.launch_server"]
          args:
            - "--model-path"
            - "/models/llama3-1b"
            - "--trust-remote-code"
            - "--stream-output"
            - "--host"
            - "0.0.0.0"
            - "--port"
            - "8898"
            - "--mem-fraction-static"
            - "0.9"
            - "--disable-radix-cache"
            - "--tp-size"
            - "2"
            - "--base-gpu-id"
            - "0"
            - "--quantization"
            - "fp8"
            - "--disaggregation-mode"
            - "prefill"
            - "--disaggregation-bootstrap-port"
            - "8998"
          env:
            - name: HUGGINGFACE_HUB_CACHE
              value: "/models"
            - name: MODELSCOPE_CACHE
              value: "/models"
          ports:
            - name: grpc-bootstrap
              containerPort: 8998
            - name: http
              containerPort: 8898
          volumeMounts:
            - name: models
              mountPath: /models
            - name: shm-volume
              mountPath: /dev/shm
          securityContext:
            privileged: true
            capabilities:
              add: ["SYS_ADMIN", "SYS_PTRACE"]
      volumes:
        - name: models
          hostPath:
            path: /home/amd/models
            type: Directory
        - name: shm-volume
          emptyDir:
            medium: Memory
            sizeLimit: 5Gi
```

#### Prefill Server Arguments

| Argument | Value | Description |
|----------|-------|-------------|
| `--model-path` | `/models/llama3-1b` | Path to model files inside container |
| `--trust-remote-code` | - | Allow custom code from model repos |
| `--stream-output` | - | Stream generated tokens as produced |
| `--host` | `0.0.0.0` | Bind server to all network interfaces |
| `--port` | `8898` | HTTP/gRPC API port |
| `--mem-fraction-static` | `0.9` | Reserve 90% of GPU memory for model |
| `--disable-radix-cache` | - | Disable radix-based caching for memory efficiency |
| `--tp-size` | `2` | Tensor parallelism size (splits model across GPUs) |
| `--base-gpu-id` | `0` | Starting GPU index for this container |
| `--quantization` | `fp8` | Use FP8 precision for model weights |
| `--disaggregation-mode` | `prefill` | Mark server as prefill-only |
| `--disaggregation-bootstrap-port` | `8998` | Port for coordination with decode servers |

---

### 2. Decode Server

The decode server generates output tokens using KV caches from the prefill server.

#### Service Definition

```yaml
apiVersion: v1
kind: Service
metadata:
  name: sglang-decode
  namespace: sglang
spec:
  selector:
    app: sglang-decode
  ports:
    - protocol: TCP
      port: 8898
      name: http
      targetPort: 8898
  type: NodePort
```

#### Deployment Definition

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sglang-decode
  namespace: sglang
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sglang-decode
  template:
    metadata:
      labels:
        app: sglang-decode
    spec:
      restartPolicy: Always
      containers:
        - name: sglang-decode
          image: lmsysorg/sglang:v0.5.8-rocm700-mi30x
          resources:
            limits:
              amd.com/gpu: 2
          command: ["python3", "-m", "sglang.launch_server"]
          args:
            - "--model-path"
            - "/models/llama3-1b"
            - "--trust-remote-code"
            - "--stream-output"
            - "--host"
            - "0.0.0.0"
            - "--port"
            - "8898"
            - "--mem-fraction-static"
            - "0.7"
            - "--disable-radix-cache"
            - "--tp-size"
            - "2"
            - "--base-gpu-id"
            - "0"
            - "--disaggregation-bootstrap-port"
            - "8998"
            - "--enable-torch-compile"
            - "--quantization"
            - "fp8"
            - "--disaggregation-mode"
            - "decode"
            - "--disable-cuda-graph"
          env:
            - name: HUGGINGFACE_HUB_CACHE
              value: "/models"
            - name: MODELSCOPE_CACHE
              value: "/models"
          ports:
            - name: http
              containerPort: 8898
          volumeMounts:
            - name: models
              mountPath: /models
            - name: shm-volume
              mountPath: /dev/shm
          securityContext:
            privileged: true
            capabilities:
              add: ["SYS_ADMIN", "SYS_PTRACE"]
      volumes:
        - name: models
          hostPath:
            path: /home/amd/models
            type: Directory
        - name: shm-volume
          emptyDir:
            medium: Memory
            sizeLimit: 5Gi
```

#### Decode Server Arguments

| Argument | Value | Description |
|----------|-------|-------------|
| `--model-path` | `/models/llama3-1b` | Model location inside container |
| `--trust-remote-code` | - | Allow execution of model-specific code |
| `--stream-output` | - | Stream token outputs |
| `--host` | `0.0.0.0` | Bind server to all interfaces |
| `--port` | `8898` | HTTP/gRPC port |
| `--mem-fraction-static` | `0.7` | Reserve 70% of GPU memory |
| `--disable-radix-cache` | - | Disable radix cache to save memory |
| `--tp-size` | `2` | Tensor parallelism size |
| `--base-gpu-id` | `0` | GPU index to start from |
| `--disaggregation-bootstrap-port` | `8998` | Connect to prefill server bootstrap port |
| `--enable-torch-compile` | - | Enable Torch compilation for faster decoding |
| `--quantization` | `fp8` | FP8 weights |
| `--disaggregation-mode` | `decode` | Mark server as decode-only |
| `--disable-cuda-graph` | - | Disable CUDA graph to avoid FP8 conflicts |

---

### 3. Mini Load Balancer

The load balancer routes requests between prefill and decode servers.

#### Service Definition

```yaml
apiVersion: v1
kind: Service
metadata:
  name: sglang-lb
  namespace: sglang
spec:
  selector:
    app: sglang-lb
  ports:
    - protocol: TCP
      port: 8002
      targetPort: 8000
  type: NodePort
```

#### Deployment Definition

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sglang-lb
  namespace: sglang
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sglang-lb
  template:
    metadata:
      labels:
        app: sglang-lb
    spec:
      restartPolicy: Always
      containers:
        - name: sglang-lb
          image: lmsysorg/sglang:v0.4.7.post1-rocm630
          resources:
            limits:
              amd.com/gpu: 1
          command: ["python3", "-m", "sglang.srt.disaggregation.mini_lb"]
          args:
            - "--prefill"
            - "http://sglang-prefill:8898"
            - "--decode"
            - "http://sglang-decode:8898"
          env:
            - name: HUGGINGFACE_HUB_CACHE
              value: "/models"
            - name: MODELSCOPE_CACHE
              value: "/models"
          volumeMounts:
            - name: models
              mountPath: /models
          securityContext:
            privileged: true
            capabilities:
              add: ["SYS_ADMIN", "SYS_PTRACE"]
      volumes:
        - name: models
          hostPath:
            path: /home/amd/models
            type: Directory
```

#### Load Balancer Arguments

| Argument | Value | Description |
|----------|-------|-------------|
| `--prefill` | `http://sglang-prefill:8898` | URL of prefill server |
| `--decode` | `http://sglang-decode:8898` | URL of decode server |

---

## Benchmarking

### Benchmark Job Definition

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: bmk-client
  namespace: sglang
spec:
  backoffLimit: 0
  template:
    spec:
      restartPolicy: Never
      nodeSelector:
        feature.node.kubernetes.io/amd-gpu: "true"
      containers:
        - name: bmk-client
          image: rocm/vllm-dev:nightly_main_20250706
          imagePullPolicy: IfNotPresent
          workingDir: /app/vllm/benchmarks
          securityContext:
            privileged: true
            capabilities:
              add: ["SYS_ADMIN", "SYS_PTRACE"]
            seccompProfile:
              type: Unconfined
          env:
            - name: HUGGINGFACE_HUB_CACHE
              value: /models
            - name: MODELSCOPE_CACHE
              value: /models
          resources:
            limits:
              amd.com/gpu: 1
            requests:
              amd.com/gpu: 1
          volumeMounts:
            - name: models
              mountPath: /models
          command: ["python"]
          args:
            - benchmark_serving.py
            - --backend
            - sglang
            - --base-url
            - "http://sglang-lb:8002"
            - --model
            - /models/llama3-1b
            - --percentile-metrics
            - ttft,tpot,itl,e2el
            - --metric-percentiles
            - "95,99"
            - --request-rate
            - "8"
            - --max-concurrency
            - "64"
            - --dataset-name
            - random
            - --random-input-len
            - "1024"
            - --random-output-len
            - "128"
            - --random-range-ratio
            - "0.8"
            - --num-prompts
            - "256"
            - --goodput
            - 'tpot:25'
            - --save-result
            - --result-dir
            - /models/results
            - --result-filename
            - sglang_benchmark.json
      volumes:
        - name: models
          hostPath:
            path: /home/amd/models
            type: Directory
```

### Benchmark Arguments

| Argument | Value | Description |
|----------|-------|-------------|
| `--backend` | `sglang` | Backend type: SGLang API |
| `--base-url` | `http://sglang-lb:8002` | Load balancer endpoint |
| `--model` | `/models/llama3-1b` | Model path for test inputs |
| `--percentile-metrics` | `ttft,tpot,itl,e2el` | Metrics to record |
| `--metric-percentiles` | `95,99` | Percentiles for metrics |
| `--request-rate` | `8` | Requests per second |
| `--max-concurrency` | `64` | Maximum simultaneous requests |
| `--dataset-name` | `random` | Use random inputs |
| `--random-input-len` | `1024` | Input sequence length |
| `--random-output-len` | `128` | Output sequence length |
| `--num-prompts` | `256` | Number of test prompts |
| `--goodput` | `tpot:25` | Threshold for "good" throughput |

### Metrics Explained

| Metric | Description |
|--------|-------------|
| **TTFT** | Time to First Token - latency until first token is generated |
| **TPOT** | Time per Output Token - average time between tokens |
| **ITL** | Inter-Token Latency - time between consecutive tokens |
| **E2EL** | End-to-End Latency - total request completion time |

---

## Benchmark Results

### Performance Comparison

| Metric | Run 1 | Run 2 | Run 3 |
|--------|-------|-------|-------|
| **Configuration** | RPS 5.0, Concurrency 128, Output 256 | RPS 8.0, Concurrency 64, Output 128 | RPS 8.0, Concurrency 16, Output 128 |
| Request Throughput (req/s) | 4.43 | 7.14 | 7.16 |
| Output Token Throughput (tok/s) | 1182.13 | 743.18 | 742.12 |
| Total Token Throughput (tok/s) | 5673.80 | 7989.63 | 8003.30 |
| Mean TTFT (ms) | 70.91 | 197.43 | 71.60 |
| P99 TTFT (ms) | 103.29 | 2216.22 | 113.15 |
| Mean TPOT (ms) | 13.90 | 14.34 | 13.93 |
| P99 TPOT (ms) | 14.41 | 17.39 | 16.10 |
| Mean ITL (ms) | 13.91 | 14.48 | 14.09 |
| P99 ITL (ms) | 29.23 | 30.13 | 29.84 |
| Mean E2EL (ms) | 3769.28 | 1688.38 | 1516.79 |
| P99 E2EL (ms) | 6343.01 | 4548.28 | 3253.19 |

### Key Observations

- **Run 3** (lower concurrency) achieved the best TTFT and E2EL latencies
- **Run 1** achieved highest output token throughput due to longer output sequences
- **Run 2** showed TTFT degradation at higher concurrency (64 vs 16)
- All runs maintained consistent TPOT (~14ms) indicating stable decode performance

---

## Troubleshooting

### NCCL Shared Memory Error

**Error:**

```
torch.distributed.DistBackendError: NCCL error in: /app/pytorch/torch/csrc/distributed/c10d/NCCLUtils.cpp:94
ncclSystemError: System call (e.g. socket, malloc) or external library call failed
Error while creating shared memory segment /dev/shm/nccl-cjY8K5 (size 10617216), error: No space left on device (28)
```

**Cause:** Insufficient shared memory for NCCL communication when using tensor parallelism.

**Solution:** Add a shared memory volume to your deployments:

```yaml
volumeMounts:
  - name: models
    mountPath: /models
  - name: shm-volume
    mountPath: /dev/shm

volumes:
  - name: models
    hostPath:
      path: /home/amd/models
      type: Directory
  - name: shm-volume
    emptyDir:
      medium: Memory
      sizeLimit: 5Gi
```

**Reference:** [SGLang Issue #9227](https://github.com/sgl-project/sglang/issues/9227)

---

### Tensor Parallelism Size Mismatch

**Issue:** Different `tp-size` between prefill and decode servers can cause performance degradation.

**Important Notes:**

- For **non-MLA models**: Using different TP sizes (e.g., TP=4 for prefill, TP=8 for decode) may work but performance is not guaranteed
- For **MLA models**: TP sizes should match between prefill and decode servers
- Mismatched TP sizes can result in slow, unstable, or inefficient inference

**Recommendation:** Use the same `tp-size` for both prefill and decode servers unless you have specific requirements and have tested the configuration.

---

### GPU Low-Power State Warning

**Warning:**

```
WARNING: AMD GPU device(s) is/are in a low-power state. Check power control/runtime_status
```

**Cause:** GPUs are in power-saving mode when idle.

**Solution:** This is normal behavior. GPUs will automatically switch to high-performance mode when workloads are submitted. You can verify GPU status with:

```bash
rocm-smi
```

Example output showing healthy GPU status:

```
============================================ ROCm System Management Interface ============================================
====================================================== Concise Info ======================================================
Device  Node  IDs              Temp        Power     Partitions          SCLK     MCLK    Fan  Perf  PwrCap  VRAM%  GPU%
              (DID,     GUID)  (Junction)  (Socket)  (Mem, Compute, ID)
==========================================================================================================================
0       2     0x74b5,   21947  38.0°C      163.0W    NPS1, SPX, 0        2102Mhz  900Mhz  0%   auto  750.0W  81%    0%
1       3     0x74b5,   37820  37.0°C      169.0W    NPS1, SPX, 0        2108Mhz  900Mhz  0%   auto  750.0W  81%    0%
...
```

---

## Deployment

### Deploy All Components

```bash
# Create namespace
kubectl create namespace sglang

# Deploy prefill server
kubectl apply -f prefill.yaml

# Deploy decode server
kubectl apply -f decode.yaml

# Deploy load balancer
kubectl apply -f lb.yaml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=sglang-prefill -n sglang --timeout=300s
kubectl wait --for=condition=ready pod -l app=sglang-decode -n sglang --timeout=300s
kubectl wait --for=condition=ready pod -l app=sglang-lb -n sglang --timeout=300s
```

### Verify Deployment

```bash
# Check pod status
kubectl get pods -n sglang

# Check services
kubectl get svc -n sglang

# View logs
kubectl logs -f deployment/sglang-prefill -n sglang
kubectl logs -f deployment/sglang-decode -n sglang
kubectl logs -f deployment/sglang-lb -n sglang
```

### Run Benchmark

```bash
# Apply benchmark job
kubectl apply -f benchmark-job.yaml

# Watch job progress
kubectl logs -f job/bmk-client -n sglang

# Get results
kubectl cp sglang/bmk-client:/models/results/sglang_benchmark.json ./results.json
```

---

## Best Practices

1. **Memory Allocation**: Use higher `mem-fraction-static` (0.9) for prefill and lower (0.7) for decode
2. **Shared Memory**: Always configure `/dev/shm` volume for NCCL communication
3. **TP Size Consistency**: Keep tensor parallelism size consistent between prefill and decode
4. **Concurrency Tuning**: Start with lower concurrency and increase based on latency requirements
5. **Monitoring**: Monitor GPU utilization and memory usage during benchmarks
6. **FP8 Quantization**: Use `--disable-cuda-graph` when using FP8 to avoid conflicts

## Related Resources

- [SGLang Documentation](https://sgl-project.github.io/)
- [AMD ROCm Documentation](https://rocm.docs.amd.com/)
- [vLLM Benchmarking Guide](https://docs.vllm.ai/en/latest/serving/benchmarking.html)
