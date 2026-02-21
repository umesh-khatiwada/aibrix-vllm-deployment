# Auth0 OIDC Integration Guide

This guide explains how to secure your AIBrix deployment using Auth0 OIDC. This setup protects both the AI Gateway (metadata and inference routes) and the Open WebUI.

## 1. Auth0 Application Setup

1.  **Create Application**:
    *   Log in to the Auth0 Dashboard.
    *   Go to **Applications** > **Applications** > **Create Application**.
    *   Name it (e.g., `AIBrix`) and select **Regular Web Application**.
2.  **Configure Settings**:
    *   **Allowed Callback URLs**: 
        ```
        http://localhost:8888/oauth2/callback, http://localhost:3000/oauth2/callback
        ```
    *   **Allowed Logout URLs**:
        ```
        http://localhost:8888, http://localhost:3000
        ```
3.  **Collect Credentials**:
    *   **Domain** (e.g., `dev-xxx.us.auth0.com`)
    *   **Client ID**
    *   **Client Secret**

## 2. Cluster Configuration

Use the provided setup script to patch your manifests and apply the configuration.

```bash
chmod +x scripts/setup_auth0.sh
./scripts/setup_auth0.sh <AUTH0_DOMAIN> <CLIENT_ID> <CLIENT_SECRET>
```

### What the script does:
*   Creates/Updates a Kubernetes Secret `oidc-client-secret` in the `aibrix-system` namespace.
*   Patches `manifests/open-webui.yaml` with OIDC environment variables.
*   Patches `manifests/oidc-security-policy.yaml` with the Auth0 domain and client ID.
*   Applies the manifests to the cluster.

## 3. Security Architecture

The integration uses the **Envoy Gateway SecurityPolicy** to intercept requests.

*   **Discovery (Public)**: The `/v1/models` endpoint is excluded from OIDC protection. This allows Open WebUI to discover available models without a pre-existing token.
*   **Inference (Protected)**: All `POST` requests to `/v1/chat/completions` and other inference routes are protected. Users must authenticate via Auth0 to gain access.

## 4. Verification

### Test Redirect to Auth0
Port-forward the gateway:
```bash
export KUBECONFIG=k.yaml
kubectl -n envoy-gateway-system port-forward service/envoy-aibrix-system-aibrix-eg-903790dc 8888:80
```

Try a protected request:
```bash
curl -v http://localhost:8888/v1/chat/completions
```
You should receive a `302 Found` redirecting to your Auth0 login page.

### Test Model Discovery
```bash
curl http://localhost:8888/v1/models
```
You should receive a `200 OK` with the list of models.

## 5. Troubleshooting

If Open WebUI does not redirect correctly, restart the pod to pick up new environment variables:
```bash
kubectl rollout restart deployment/open-webui
```
