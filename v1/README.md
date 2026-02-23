# Envoy AI Gateway Demo & Setup Guide
A hands-on walkthrough for your team

**AI Gateway Repo:** [github.com/envoyproxy/ai-gateway](https://github.com/envoyproxy/ai-gateway)
**Envoy Gateway Repo:** [github.com/envoyproxy/gateway](https://github.com/envoyproxy/gateway)

## 1. Architecture Overview
Envoy AI Gateway is a cloud-native API gateway purpose-built for AI/LLM workloads. It sits between your clients and AI providers (OpenAI, AWS Bedrock, etc.), handling routing, security, rate limiting, and token quota management.

**Key Insight: How the pieces fit together**
The AI Gateway Controller programs Envoy Gateway (the data plane) via the xDS protocol — the same dynamic discovery API used by Envoy in service meshes like Istio. The controller itself does NOT proxy traffic; Envoy Gateway does. This means you always need both components installed.

### Component Summary

| Component | Role | Namespace |
| --- | --- | --- |
| AI Gateway Controller | Control plane — programs Envoy via xDS | `envoy-ai-gateway-system` |
| Envoy Gateway | Data plane — actually proxies traffic | `envoy-gateway-system` |
| Gateway API Inference Extension | Adds InferencePool & InferenceObjective CRDs | `kube-system` |
| Gateway API CRDs | Kubernetes standard gateway primitives | cluster-wide |

## 2. Installation Steps
Run the following commands in order. Each step must complete successfully before proceeding to the next.

### Step 1 — Gateway API CRDs
Install the standard Kubernetes Gateway API CRDs. We use the experimental channel to get access to all features:

```bash
# Remove any existing install first
kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/experimental-install.yaml

# Apply fresh install
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/experimental-install.yaml
```

### Step 2 — AI Gateway CRDs
Install the Custom Resource Definitions (CRDs) that define the AI Gateway-specific resources like AIGatewayRoute, AIServiceBackend, and BackendSecurityPolicy:

```bash
helm upgrade -i aieg-crd oci://docker.io/envoyproxy/ai-gateway-crds-helm \
  --version v0.0.0-latest \
  --namespace envoy-ai-gateway-system \
  --create-namespace
```

### Step 3 — AI Gateway Controller
Install the controller (the control plane). After install, wait for it to become ready before continuing:

```bash
helm upgrade -i aieg oci://docker.io/envoyproxy/ai-gateway-helm \
  --version v0.0.0-latest \
  --namespace envoy-ai-gateway-system \
  --create-namespace

# Wait for the controller to be ready
kubectl wait --timeout=2m \
  -n envoy-ai-gateway-system \
  deployment/ai-gateway-controller \
  --for=condition=Available
```

### Step 4 — Gateway API Inference Extension
This installs a separate CNCF project that adds LLM-specific pool and routing primitives (InferencePool, InferenceObjective):

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/releases/download/v1.0.1/manifests.yaml
```

### Step 5 — Envoy Gateway (Data Plane)
Finally, install Envoy Gateway with the two values files that enable AI Gateway integration and InferencePool support:

```bash
helm upgrade -i eg oci://docker.io/envoyproxy/gateway-helm \
  --version v0.0.0-latest \
  --namespace envoy-gateway-system \
  --create-namespace \
  -f https://raw.githubusercontent.com/envoyproxy/ai-gateway/main/manifests/envoy-gateway-values.yaml \
  -f https://raw.githubusercontent.com/envoyproxy/ai-gateway/main/examples/inference-pool/envoy-gateway-values-addon.yaml
```

**Why two values files?**
The base values file (`envoy-gateway-values.yaml`) enables the AI Gateway extension manager and Backend API. The addon file (`envoy-gateway-values-addon.yaml`) adds InferencePool CRD support. Keeping them separate lets you mix and match features.

### Verify Installation
Run these commands to confirm everything is healthy:

```bash
# Check all pods are running
kubectl get pods -n envoy-ai-gateway-system
kubectl get pods -n envoy-gateway-system

# List all AI Gateway CRDs
kubectl get crds | grep aigateway
```

## 3. Core Concepts — Custom Resources
Once installed, you configure the gateway using Kubernetes custom resources. Here is what each resource does and why it exists.

### 3.1 Backend
A Backend CRD "upgrades" a standard Kubernetes Service into a managed network destination that the gateway can attach policies to. You need it because:

* **Policy attachment** — `BackendTrafficPolicy` rules (retries, circuit breaking, timeouts) cannot attach to a plain Service; they need a `Backend` resource as the hook.
* **External AI providers** — OpenAI, AWS Bedrock, etc. live outside your cluster. The `Backend` CRD lets you define external FQDNs just like internal services.
* **Security context** — `BackendSecurityPolicy` (API keys, AWS SigV4 credentials) attaches here, keeping secrets out of your application code.
* **Dynamic forward proxy** — Envoy can resolve hostnames on the fly instead of relying on static cluster endpoints.
* **Protocol flexibility** — Supports non-standard endpoints like Unix Domain Sockets that plain Services cannot represent.

### 3.2 AIServiceBackend
The `AIServiceBackend` is the translator and authentication hub for a specific AI provider. It bridges your high-level routing rules (`AIGatewayRoute`) with the actual network destination (`Backend`).

| Field | What it does |
| --- | --- |
| `schema` | Declares the provider API format: OpenAI, AWSBedrock, etc. The gateway uses this to translate requests and normalize responses. |
| `backendRef` | Points to the Kubernetes Service or Backend CRD that is the actual network endpoint. |
| `modelName` | Optional override — forces the gateway to send a specific model name to the provider regardless of what the client requested. |
| `headerMutation` | Optional — lets you add, remove, or modify HTTP headers for requests to this backend only. |

### 3.3 AIGatewayRoute
`AIGatewayRoute` is the top-level policy engine. When you create one, the AI Gateway controller automatically generates several supporting resources:

* An `HTTPRoute` (same name) that binds to the Gateway specified in `parentRefs`.
* An `EnvoyExtensionPolicy` to plug in AI-specific processing (model name extraction from the JSON body).
* An `HTTPRouteFilter` named `ai-eg-host-rewrite-<route>` that rewrites the destination host per provider.
* An `HTTPRouteFilter` for returning a 404-style response when no matching rule is found.

**What you see in the logs:**
```
2026-02-18 | controller.ai-gateway-route | Created HTTPRouteFilter | ai-eg-host-rewrite-llama3-route
2026-02-18 | controller.ai-gateway-route | Created HTTPRouteFilter | ai-eg-route-not-found-response-llama3-route
2026-02-18 | controller.ai-gateway-route | creating HTTPRoute      | llama3-route
```

### 3.4 QuotaPolicy
`QuotaPolicy` enforces AI-native token budgets — unlike standard rate limiting (requests per second), this understands the actual token consumption reported by your AI provider.

* The gateway's External Processor (ExtProc) inspects each JSON response to extract the usage field (prompt tokens + completion tokens).
* Running totals are stored in a cache (such as Redis).
* When a user or application exceeds their quota, the gateway returns `429 Too Many Requests` before the request reaches the AI provider — saving cost.

### 3.5 Security Policies — Upstream vs Downstream
There are two distinct security policy types. Do not confuse them:

| Policy | Direction | Purpose | Auth Methods |
| --- | --- | --- | --- |
| `SecurityPolicy` | Downstream (client → gateway) | Protects the gateway from unauthorized callers | JWT, OIDC, CORS |
| `BackendSecurityPolicy` | Upstream (gateway → AI provider) | Authenticates the gateway to your AI provider | API Keys, AWS SigV4 |

## 4. Installed CRD Reference
After a successful install you should see all of the following CRDs when you run `kubectl get crds`. The table below groups them by origin.

**AI Gateway CRDs (`aigateway.envoyproxy.io`)**

| CRD Name | Purpose |
| --- | --- |
| `aigatewayroutes` | Top-level routing policy for LLM requests |
| `aiservicebackends` | Per-provider translator + auth hub |
| `backendsecuritypolicies`| Credentials for upstream AI providers |
| `gatewayconfigs` | Global AI Gateway controller configuration |
| `mcproutes` | Multi-cloud routing rules |
| `quotapolicies` | Token-based budget enforcement |

**Envoy Gateway CRDs (`gateway.envoyproxy.io`)**

| CRD Name | Purpose |
| --- | --- |
| `backends` | Enhanced network destination with policy hooks |
| `backendtrafficpolicies`| Traffic shaping: retries, timeouts, circuit breaking |
| `clienttrafficpolicies` | Downstream connection tuning |
| `envoyextensionpolicies`| Plug in external processors (ExtProc) |
| `envoypatchpolicies` | Low-level xDS patch escapes |
| `securitypolicies` | Downstream auth: JWT, OIDC, CORS |
| `httproutefilters` | Reusable HTTP header / URL transformations |

**Standard Gateway API CRDs (`gateway.networking.k8s.io`)**

| CRD Name | Purpose |
| --- | --- |
| `gatewayclasses` | Defines the gateway implementation class |
| `gateways` | Represents a running gateway instance |
| `httproutes` | HTTP routing rules |
| `grpcroutes` | gRPC routing rules |
| `tcproutes` / `tlsroutes` / `udproutes` | Layer-4 routing rules |
| `referencegrants` | Cross-namespace reference permissions |
| `backendtlspolicies` | TLS configuration for upstream backends |

## 5. Quick Reference

### Useful kubectl Commands
```bash
# Watch all AI Gateway resources
kubectl get aigatewayroutes,aiservicebackends,backendsecuritypolicies -A

# Check the AI Gateway controller logs
kubectl logs -n envoy-ai-gateway-system \
  deployment/ai-gateway-controller --follow

# Check the Envoy Gateway logs
kubectl logs -n envoy-gateway-system \
  deployment/envoy-gateway --follow

# Describe a gateway to see status and events
kubectl describe gateway <gateway-name> -n <namespace>

# List all installed CRDs from these projects
kubectl get crds | grep -E 'aigateway|envoyproxy|networking.k8s'
```

### OCI Registry
All Helm charts are published to Docker Hub under the `envoyproxy` organisation:

```bash
# AI Gateway CRDs chart
oci://docker.io/envoyproxy/ai-gateway-crds-helm

# AI Gateway Controller chart
oci://docker.io/envoyproxy/ai-gateway-helm

# Envoy Gateway chart
oci://docker.io/envoyproxy/gateway-helm

# Browse all images
https://hub.docker.com/u/envoyproxy
```

### Key Concepts Glossary

| Term | Definition |
| --- | --- |
| xDS | Envoy Discovery Service protocol — used by the AI Gateway controller to dynamically push configuration (listeners, clusters, routes) to Envoy without a restart. |
| ExtProc | External Processor — a gRPC sidecar called by Envoy for every request/response. AI Gateway uses it for model name extraction and token counting. |
| InferencePool | A CNCF Gateway API extension that abstracts a pool of LLM/inference servers and enables objective-driven routing (latency, availability). |
| InferenceObjective| A policy attached to an InferencePool that defines routing goals such as a target P95 latency. |
| SigV4 | AWS Signature Version 4 — the signing protocol used to authenticate requests to AWS services like Bedrock. BackendSecurityPolicy handles this automatically. |
| Token Quota | AI-native rate limiting counted in LLM tokens rather than HTTP requests. Enforced by QuotaPolicy + Redis. |

## 6. Manifests

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    model.aibrix.ai/name: deepseek-r1-distill-llama-8b # Note: The label value `model.aibrix.ai/name` here must match with the service name.
    model.aibrix.ai/port: "8000"
  name: deepseek-r1-distill-llama-8b
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      model.aibrix.ai/name: deepseek-r1-distill-llama-8b
      model.aibrix.ai/port: "8000"
  template:
    metadata:
      labels:
        model.aibrix.ai/name: deepseek-r1-distill-llama-8b
        model.aibrix.ai/port: "8000"
    spec:
      containers:
        - command:
            - python3
            - -m
            - vllm.entrypoints.openai.api_server
            - --host
            - "0.0.0.0"
            - --port
            - "8000"
            - --uvicorn-log-level
            - warning
            - --model
            - deepseek-ai/DeepSeek-R1-Distill-Llama-8B
            - --served-model-name
            # Note: The `--served-model-name` argument value must also match the Service name and the Deployment label `model.aibrix.ai/name`
            - deepseek-r1-distill-llama-8b
            - --max-model-len
            - "12288" # 24k length, this is to avoid "The model's max seq len (131072) is larger than the maximum number of tokens that can be stored in KV cache" issue.
          image: rocm/vllm:latest
          imagePullPolicy: IfNotPresent
          name: vllm-openai
          ports:
            - containerPort: 8000
              protocol: TCP
          resources:
            limits:
              amd.com/gpu: "1"
            requests:
              amd.com/gpu: "1"
          livenessProbe:
            httpGet:
              path: /health
              port: 8000
              scheme: HTTP
            failureThreshold: 3
            periodSeconds: 5
            successThreshold: 1
            timeoutSeconds: 1
          readinessProbe:
            httpGet:
              path: /health
              port: 8000
              scheme: HTTP
            failureThreshold: 5
            periodSeconds: 5
            successThreshold: 1
            timeoutSeconds: 1
          startupProbe:
            httpGet:
              path: /health
              port: 8000
              scheme: HTTP
            failureThreshold: 30
            periodSeconds: 5
            successThreshold: 1
            timeoutSeconds: 1
          volumeMounts:
            - mountPath: /root/.cache/huggingface
              name: hf-cache
      volumes:
        - name: hf-cache
          persistentVolumeClaim:
            claimName: hf-cache-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: deepseek-r1-distill-llama-8b
  namespace: default
  labels:
    model.aibrix.ai/name: deepseek-r1-distill-llama-8b
spec:
  selector:
    model.aibrix.ai/name: deepseek-r1-distill-llama-8b
  ports:
    - name: http
      port: 8000
      targetPort: 8000
  type: ClusterIP
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: hf-cache-pvc
  namespace: default
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 200Gi
---
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: Backend
metadata:
  name: deepseek-r1-distill-llama-8b-backend
  namespace: envoy-gateway-system
spec:
  endpoints:
    - fqdn:
        hostname: deepseek-r1-distill-llama-8b.default.svc.cluster.local
        port: 8000
---
apiVersion: aigateway.envoyproxy.io/v1alpha1
kind: AIServiceBackend
metadata:
  name: deepseek-r1-distill-llama-8b
  namespace: envoy-gateway-system
spec:
  schema:
    name: OpenAI
    version: v1       # deprecated but harmless for OpenAI
    prefix: /v1       # vLLM API prefix
  backendRef:
    name: deepseek-r1-distill-llama-8b-backend   # references the Backend resource above
    namespace: envoy-gateway-system
    kind: Backend
    group: gateway.envoyproxy.io
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: allow-envoy-gateway-to-default
  namespace: default
spec:
  from:
    - group: gateway.networking.k8s.io
      kind: Gateway
      namespace: envoy-gateway-system
  to:
    - group: ""
      kind: Service
---
apiVersion: v1
kind: Secret
metadata:
  name: valid-api-keys
  namespace: envoy-gateway-system
type: Opaque
stringData:
  premium-key: "premium-key"
  free-key: "free-key"
---
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: SecurityPolicy
metadata:
  name: api-key-auth
  namespace: envoy-gateway-system
spec:
  targetRefs:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: aibrix-ai-gateway
  apiKeyAuth:
    credentialRefs:
      - name: valid-api-keys
        namespace: envoy-gateway-system
    extractFrom:
      - headers:
          - Authorization
          - x-api-key
---
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: SecurityPolicy
metadata:
  name: auth0-jwt-auth
  namespace: envoy-gateway-system
spec:
  targetRefs:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: aibrix-ai-gateway
  jwt:
    providers:
      - name: auth0
        issuer: https://dev-xtsht1rd77wbvbyp.us.auth0.com/        # e.g. https://myapp.us.auth0.com/
        audiences:
          - https://dev-xtsht1rd77wbvbyp.us.auth0.com/api/v2/     # e.g. https://my-ai-gateway
        remoteJWKS:
          uri: https://dev-xtsht1rd77wbvbyp.us.auth0.com/.well-known/jwks.json
        claimToHeaders:
          - claim: sub
            header: x-user-id                    # forwards Auth0 user ID to backend
          - claim: permissions
            header: x-user-permissions
---
apiVersion: aigateway.envoyproxy.io/v1alpha1
kind: AIGatewayRoute
metadata:
  name: llama3-route
  namespace: envoy-gateway-system
spec:
  parentRefs:
    - name: aibrix-ai-gateway
      kind: Gateway
      group: gateway.networking.k8s.io
  rules:
    - matches:
        - headers:
            - type: Exact
              name: x-ai-eg-model
              value: meta-llama/Llama-3.2-1B-Instruct
      backendRefs:
        - name: vllm-llama3-1b   
    - matches:
        - headers:
            - type: Exact
              name: x-ai-eg-model
              value: deepseek-r1-distill-llama-8b
      backendRefs:
        - name: deepseek-r1-distill-llama-8b
    - backendRefs:
        - name: vllm-llama3-1b
---
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: BackendTrafficPolicy
metadata:
  name: token-quota-policy
  namespace: envoy-gateway-system
spec:
  targetRefs:
    - name: aibrix-ai-gateway
      kind: Gateway
      group: gateway.networking.k8s.io
  rateLimit:
    type: Global
    global:
      rules:
        - limit:
            requests: 500
            unit: Minute
          cost:
            request:
              from: Number
              number: 0
            response:
              from: Metadata
              metadata:
                namespace: io.envoy.ai_gateway
                key: llm_total_token
---
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: envoy-gateway-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
        - name: redis
          image: redis:7
          ports:
            - containerPort: 6379
---
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: envoy-gateway-system
spec:
  selector:
    app: redis
  ports:
    - port: 6379
      targetPort: 6379
EOF
```

### Envoy Gateway config

```yaml
    controllerName: gateway.envoyproxy.io/gatewayclass-controller
    rateLimit:
      backend:
        type: Redis
        redis:
          url: redis://redis.envoy-gateway-system.svc.cluster.local:6379
```

## 7. Curl Request Commands

### With JWT Token
```bash
curl http://134.199.201.56/v1/chat/completions \
 -H "Authorization: Bearer $TOKEN" \
 -H "Content-Type: application/json" \
 -d '{"model": "deepseek-r1-distill-llama-8b", "messages": [{"role": "user", "content": "Hello"}], "max_tokens": 50}'
```

### Without JWT Token (Open Request)
```bash
curl http://134.199.201.56/v1/chat/completions \
 -H "Content-Type: application/json" \
 -d '{"model": "deepseek-r1-distill-llama-8b", "messages": [{"role": "user", "content": "Hello"}], "max_tokens": 50}'
```

### List Models
```bash
curl http://134.199.201.56/v1/models \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```
**Response Example:**
```json
{"data":[{"id":"meta-llama/Llama-3.2-1B-Instruct","created":1771411592,"object":"model","owned_by":"Envoy AI Gateway"},{"id":"deepseek-r1-distill-llama-8b","created":1771411592,"object":"model","owned_by":"Envoy AI Gateway"},{"id":"qwen-coder-1-5b-instruct","created":1771411592,"object":"model","owned_by":"Envoy AI Gateway"}],"object":"list"}
```

### Chat Completion Request
```bash
curl -X POST http://134.199.201.56/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "model": "deepseek-r1-distill-llama-8b",
    "messages": [{"role": "user", "content": "Write a 300 word essay on the history of AI."}]
  }'
```

### Script to Test Requests Repeatedly
```bash
for i in {1..4}; do \
  curl -s -o /dev/null -w "%{http_code}\n" \
    -X POST http://134.199.201.56/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{"model":"deepseek-r1-distill-llama-8b","messages":[{"role":"user","content":"hi"}]}'; \
done
```
