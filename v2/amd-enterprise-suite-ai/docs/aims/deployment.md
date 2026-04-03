# AIMs Deployment

Deploy an AMD Inference Microservice using Kubernetes, KServe, or Docker.

---

## Kubernetes

Step-by-step instructions for deploying an AIM on a Kubernetes cluster. This covers the full workflow from prerequisites through to testing a live inference endpoint.

### Prerequisites

- Kubernetes cluster with `kubectl` configured (v1.32.8+rke2r1 or later)
- AMD GPU with ROCm support (e.g., MI300X)

---

### Step 1: Create a Hugging Face Secret

AIM images are hosted publicly on Docker Hub — no authentication is needed to pull them. However, some models (such as Meta Llama) are **gated on Hugging Face** and require a token to download.

Create a Kubernetes secret with your Hugging Face token:

```bash
kubectl create secret generic hf-token \
    --from-literal="hf-token=YOUR_HUGGINGFACE_TOKEN" \
    -n YOUR_K8S_NAMESPACE
```

Expected output:

```
secret/hf-token created
```

!!! tip "Getting a Hugging Face Token"
    Go to [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens), create a token with read permissions, and request access to any gated model you want to use (e.g., Llama).

---

### Step 2: Install the AMD Device Plugin

The AMD GPU device plugin makes your GPUs visible to Kubernetes. Skip this step if it is already installed in your cluster.

```bash
kubectl create -f https://raw.githubusercontent.com/ROCm/k8s-device-plugin/master/k8s-ds-amdgpu-dp.yaml
```

Expected output:

```
daemonset.apps/amdgpu-device-plugin-daemonset created
```

---

### Step 3: Create the Deployment Manifests

Create two files in the same directory: `deployment.yaml` and `service.yaml`.

#### deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minimal-aim-deployment
  labels:
    app: minimal-aim-deployment
spec:
  progressDeadlineSeconds: 3600
  replicas: 1
  selector:
    matchLabels:
      app: minimal-aim-deployment
  template:
    metadata:
      labels:
        app: minimal-aim-deployment
    spec:
      containers:
        - name: minimal-aim-deployment
          image: "amdenterpriseai/aim-meta-llama-llama-3-1-8b-instruct:0.10.0"
          imagePullPolicy: Always
          env:
            - name: HF_TOKEN
              valueFrom:
                secretKeyRef:
                  name: hf-token
                  key: hf-token
          ports:
            - name: http
              containerPort: 8000
          resources:
            requests:
              memory: "16Gi"
              cpu: "4"
              amd.com/gpu: "1"
            limits:
              memory: "16Gi"
              cpu: "4"
              amd.com/gpu: "1"
          startupProbe:
            httpGet:
              path: /v1/models
              port: http
            periodSeconds: 10
            failureThreshold: 60
          livenessProbe:
            httpGet:
              path: /health
              port: http
          readinessProbe:
            httpGet:
              path: /v1/models
              port: http
          volumeMounts:
            - name: ephemeral-storage
              mountPath: /tmp
            - name: dshm
              mountPath: /dev/shm
      volumes:
        - name: ephemeral-storage
          emptyDir:
            sizeLimit: 256Gi
        - name: dshm
          emptyDir:
            medium: Memory
            sizeLimit: 32Gi
```

#### service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: minimal-aim-deployment
  labels:
    app: minimal-aim-deployment
spec:
  type: ClusterIP
  ports:
    - name: http
      port: 80
      targetPort: 8000
  selector:
    app: minimal-aim-deployment
```

!!! note "Key manifest details"
    - **`amd.com/gpu: "1"`** — requests one AMD GPU from the device plugin
    - **`/dev/shm`** — shared memory volume is required by vLLM for inter-process communication
    - **`startupProbe`** — allows up to 10 minutes (60 × 10s) for the model to load before Kubernetes marks it as failed
    - **`progressDeadlineSeconds: 3600`** — gives the deployment up to 1 hour to become available (large models take time to download)
    - **`ClusterIP`** — the service is only accessible within the cluster; use port-forward or an Ingress for external access

---

### Step 4: Apply the Manifests

From the directory containing both YAML files:

```bash
kubectl apply -f . -n YOUR_K8S_NAMESPACE
```

Expected output:

```
deployment.apps/minimal-aim-deployment created
service/minimal-aim-deployment created
```

Watch the pod come up:

```bash
kubectl get pods -n YOUR_K8S_NAMESPACE -w
```

Wait until the pod status shows `Running` and `1/1` ready. This can take several minutes while the model downloads.

---

### Step 5: Test the Inference Endpoint

#### Port-forward the service

```bash
kubectl port-forward service/minimal-aim-deployment 8000:80 -n YOUR_K8S_NAMESPACE
```

Expected output:

```
Forwarding from 127.0.0.1:8000 -> 8000
Forwarding from [::1]:8000 -> 8000
```

#### Send a test request

```bash
curl http://localhost:8000/v1/completions \
    -H "Content-Type: application/json" \
    -d '{
        "model": "meta-llama/Llama-3.1-8B-Instruct",
        "prompt": "San Francisco is a",
        "max_tokens": 7,
        "temperature": 0
    }'
```

Expected response:

```json
{
  "id": "cmpl-703ff7b124a944849d64d063720a28f4",
  "object": "text_completion",
  "created": 1758657978,
  "model": "meta-llama/Llama-3.1-8B-Instruct",
  "choices": [
    {
      "index": 0,
      "text": " city that is known for its v",
      "logprobs": null,
      "finish_reason": "length",
      "stop_reason": null,
      "prompt_logprobs": null
    }
  ],
  "usage": {
    "prompt_tokens": 5,
    "total_tokens": 12,
    "completion_tokens": 7,
    "prompt_tokens_details": null
  },
  "kv_transfer_params": null
}
```

The API is **OpenAI-compatible** — you can also use the `/v1/chat/completions` endpoint with the standard messages format.

---

### Removing the Deployment

```bash
kubectl delete -f . -n YOUR_K8S_NAMESPACE
```

Expected output:

```
deployment.apps "minimal-aim-deployment" deleted
service "minimal-aim-deployment" deleted
```

---

## KServe

For teams that need **autoscaling** and advanced serving features.

KServe extends Kubernetes with:

- Automatic scale-to-zero when idle
- Canary releases (gradual traffic shifting)
- Request batching and optimization
- Built-in monitoring

 [Full KServe Guide](https://enterprise-ai.docs.amd.com/en/latest/aims/kserve_deployment.html)

---

## Docker

For quick single-node testing without a full Kubernetes cluster.

```bash
docker run -d \
  -e AIM_MODEL_ID=meta-llama/Llama-3.1-8B-Instruct \
  -e HF_TOKEN=your_token_here \
  --device=/dev/kfd \
  --device=/dev/dri \
  -p 8000:8000 \
  amdenterpriseai/aim-meta-llama-llama-3-1-8b-instruct:0.10.0
```

Test it:

```bash
curl http://localhost:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "meta-llama/Llama-3.1-8B-Instruct",
    "prompt": "Hello!",
    "max_tokens": 20
  }'
```

 [Full Docker Guide](https://enterprise-ai.docs.amd.com/en/latest/aims/docker_deployment.html)

---

## Choosing a Deployment Method

| | Kubernetes | KServe | Docker |
|---|---|---|---|
| **Best for** | Production multi-user serving | Production with autoscaling | Local testing |
| **Autoscaling** | Manual (HPA) | Automatic | No |
| **Scale to zero** | No | Yes | No |
| **Setup complexity** | Medium | High | Low |
| **GPU sharing** | Via device plugin | Via device plugin | Direct mount |

---

## Official Reference

 [Kubernetes Deployment — Official Docs](https://enterprise-ai.docs.amd.com/en/latest/aims/kubernetes_deployment.html)
 [Deployment Overview](https://enterprise-ai.docs.amd.com/en/latest/aims/deployment_overview.html)
