# Aibrix Integration with Envoy AI Gateway Deployment Guide

This guide walks you through deploying a multi-model AI inference gateway using Envoy AI Gateway, Gateway API Inference Extension, and custom Aibrix-branded routing rules.

> **Important:** This guide applies to deployments using **Envoy AI Gateway as a standalone gateway**. It does not apply to the AIBrix Gateway with Envoy sidecar plugin, which uses different CRDs and configuration.

## Folder Structure

This example contains the following files:

```
first-example/
├── aiservicebackend.yaml         # AIServiceBackend resource for DeepSeek model
├── aigatewayrroute.yaml          # AIGatewayRoute for routing requests to the model
├── backend.yaml                  # Backend service definition
├── backendtrafficpolicy.yaml     # Rate limiting and token quota policy
├── deepseek-model-amd.yaml       # Deployment, Service, and PVC for DeepSeek model
├── quotapolicy.yaml              # Quota policy for AIServiceBackend
├── referencegrant.yaml           # ReferenceGrant for cross-namespace access
├── securitypolicy-jwt.yaml       # JWT-based authentication policy (Auth0)
├── securitypolicy.yaml           # API key authentication and secret
```

## Prerequisites
- Kubernetes cluster (v1.24+)
- kubectl configured
- helm v3.8+
- Internet access to pull images from docker.io and GitHub

## Architecture Overview

```
Client Request
     ↓
[Envoy Gateway] ← SecurityPolicy enforced here (API Key or JWT)
     ↓
[AIGatewayRoute] ← model routing via x-ai-eg-model header
     ↓
[AIServiceBackend] ← OpenAI schema translation
     ↓
[Backend / vLLM Pod]
```

The `SecurityPolicy` targets the **Gateway** directly, so authentication is enforced automatically on all routes — no changes are needed to `AIGatewayRoute`, `AIServiceBackend`, or `Backend` resources.

## Installation Steps

### 1. Install Aibrix Custom Application (Optional)
If you have an internal Aibrix Helm chart:

```sh
helm install aibrix dist/chart \
  -n aibrix-system --create-namespace \
  --set gateway.enable=false
```

> **Note:** If you are using an internal Aibrix Helm chart, you must set `gateway.enable: false` in `values.yaml`.
> This is critical because Steps 2–5 below will install the AI Gateway controller and Envoy data plane independently. Enabling the built-in gateway here would cause resource conflicts or duplicate deployments.

```yaml
gateway:
  enable: false  # ← Set this to false to skip internal gateway deployment
```

### 2. Install AI Gateway CRDs
```sh
helm upgrade -i aieg-crd oci://docker.io/envoyproxy/ai-gateway-crds-helm \
  --version v0.0.0-latest \
  --namespace envoy-ai-gateway-system \
  --create-namespace
```
For more details, see the official installation guide for AI Gateway CRDs.

### 3. Install AI Gateway Controller
```sh
helm upgrade -i aieg oci://docker.io/envoyproxy/ai-gateway-helm \
  --version v0.0.0-latest \
  --namespace envoy-ai-gateway-system \
  --create-namespace
```
For more details, see the official installation guide for AI Gateway Resources.

Wait for the controller to be ready:
```sh
kubectl wait --timeout=2m -n envoy-ai-gateway-system deployment/ai-gateway-controller --for=condition=Available
```

### 4. Install Gateway API Inference Extension (EPP Framework)
```sh
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/releases/download/v1.0.1/manifests.yaml
```
For more details, see the official installation guide for Gateway API Inference Extension.

This deploys: CRDs (InferencePool, InferenceObjective), RBAC, webhooks, and core controllers.

### 5. Install Envoy Gateway (Data Plane)
```sh
helm upgrade -i eg oci://docker.io/envoyproxy/gateway-helm \
  --version v0.0.0-latest \
  --namespace envoy-gateway-system \
  --create-namespace \
  -f https://raw.githubusercontent.com/envoyproxy/ai-gateway/main/manifests/envoy-gateway-values.yaml \
  -f https://raw.githubusercontent.com/envoyproxy/ai-gateway/main/examples/inference-pool/envoy-gateway-values-addon.yaml
```
For more details, see the official installation guide for Envoy Gateway.

## Deploy Aibrix AI Gateway Resources
Apply your custom gateway and routing configuration:

```sh
cd first-example

# Deploy model infrastructure
kubectl apply -f deepseek-model-amd.yaml

# Deploy gateway routing resources
kubectl apply -f backend.yaml
kubectl apply -f aiservicebackend.yaml
kubectl apply -f aigatewayrroute.yaml

# Deploy policies
kubectl apply -f backendtrafficpolicy.yaml
kubectl apply -f quotapolicy.yaml
kubectl apply -f referencegrant.yaml

# Deploy authentication (choose one or both — see Authentication section below)
kubectl apply -f securitypolicy.yaml        # API key auth
kubectl apply -f securitypolicy-jwt.yaml    # JWT / Auth0 auth
```

## Authentication

Authentication is enforced at the **Gateway level** via `SecurityPolicy`. Because `SecurityPolicy` targets the Gateway directly, no changes are required to `AIGatewayRoute`, `AIServiceBackend`, or `Backend` resources.

### Option 1 — API Key Authentication

Clients pass an API key via the `Authorization` or `x-api-key` header.

```yaml
# securitypolicy.yaml
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
```

Example request:
```sh
curl http://<GATEWAY_IP>/v1/chat/completions \
  -H "x-api-key: free-key" \
  -H "x-ai-eg-model: deepseek-r1-distill-llama-8b" \
  -H "Content-Type: application/json" \
  -d '{"model": "deepseek-r1-distill-llama-8b", "messages": [{"role": "user", "content": "Hello"}]}'
```

### Option 2 — JWT Authentication (Auth0)

Clients pass a Bearer JWT token. Validated claims are forwarded as headers to the backend.

```yaml
# securitypolicy-jwt.yaml
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
        issuer: https://dev-xxx.us.auth0.com/
        audiences:
          - https://dev-xxx.us.auth0.com/api/v2/
        remoteJWKS:
          uri: https://dev-xxx.us.auth0.com/.well-known/jwks.json
        claimToHeaders:
          - claim: sub
            header: x-user-id
          - claim: permissions
            header: x-user-permissions
```

Example request:
```sh
curl http://<GATEWAY_IP>/v1/chat/completions \
  -H "Authorization: Bearer <your-jwt-token>" \
  -H "x-ai-eg-model: deepseek-r1-distill-llama-8b" \
  -H "Content-Type: application/json" \
  -d '{"model": "deepseek-r1-distill-llama-8b", "messages": [{"role": "user", "content": "Hello"}]}'
```

With JWT auth, the extracted claims (`x-user-id`, `x-user-permissions`) are forwarded to your vLLM backend, which is useful for per-user rate limiting or audit logging in AIBrix.

### Auth Comparison

| | API Key Auth | JWT (Auth0) Auth |
|---|---|---|
| Client sends | `x-api-key: <key>` or `Authorization: <key>` | `Authorization: Bearer <jwt>` |
| Identity propagation | None | `x-user-id`, `x-user-permissions` forwarded to backend |
| Secret management | Kubernetes Secret | Auth0 manages keys externally |
| Best for | Internal/simple clients | User-facing apps with Auth0 login |

## AIGatewayRoute

The `AIGatewayRoute` routes requests to the correct `AIServiceBackend` based on the `x-ai-eg-model` request header.

```yaml
# aigatewayrroute.yaml
apiVersion: aigateway.envoyproxy.io/v1alpha1
kind: AIGatewayRoute
metadata:
  name: deepseek-r1-distill-llama-8b-route
  namespace: aibrix-system
spec:
  schema:
    name: OpenAI
    version: v1
  parentRefs:
    - name: aibrix-ai-gateway
      namespace: envoy-gateway-system
      kind: Gateway
  rules:
    - matches:
        - headers:
            - type: Exact
              name: x-ai-eg-model
              value: deepseek-r1-distill-llama-8b
      backendRefs:
        - name: deepseek-r1-distill-llama-8b
          namespace: aibrix-system
          kind: AIServiceBackend
          group: aigateway.envoyproxy.io
```

> **Note:** The `x-ai-eg-model` header value must match the `--served-model-name` argument in the vLLM Deployment (`deepseek-r1-distill-llama-8b`).

## Verify Deployment Status
After installation, verify that all components are running correctly.

**Pods in aibrix-system**
```sh
kubectl get pods -n aibrix-system
```

**Pods in envoy-ai-gateway-system**
```sh
kubectl get pods -n envoy-ai-gateway-system
```

**Pods in envoy-gateway-system**
```sh
kubectl get pods -n envoy-gateway-system
```

**Gateway and routes**
```sh
kubectl get gateway -n envoy-gateway-system
kubectl get aigatewayrroute -n aibrix-system
kubectl get aiservicebackend -n aibrix-system
kubectl get securitypolicy -n envoy-gateway-system
```

## Test the Setup
Once all pods are ready, test routing via curl:

```sh
curl -v http://<GATEWAY_IP>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "x-ai-eg-model: deepseek-r1-distill-llama-8b" \
  -H "x-api-key: free-key" \
  -d '{
        "model": "deepseek-r1-distill-llama-8b",
        "messages": [{"role": "user", "content": "Say this is a test!"}],
        "temperature": 0.7
      }'
```

Replace `<GATEWAY_IP>` with:
- `localhost:8080` if using port-forward:
  ```sh
  kubectl port-forward -n envoy-gateway-system svc/envoy-default-aibrix-ai-gateway-588291e8 8080:80
  ```
- Or the external IP of the `eg-envoy` Service if exposed via LoadBalancer:
  ```sh
  kubectl get svc -n envoy-gateway-system
  ```

## References
- [Envoy AI Gateway](https://gateway.envoyproxy.io/)
- [Gateway API Inference Extension](https://github.com/kubernetes-sigs/gateway-api-inference-extension)
- [Envoy Gateway Security Policy](https://gateway.envoyproxy.io/docs/tasks/security/api-key-auth/)
- [Envoy Gateway JWT Authentication](https://gateway.envoyproxy.io/docs/tasks/security/jwt-authentication/)
