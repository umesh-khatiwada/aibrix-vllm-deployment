#!/bin/zsh

# setup_auth0.sh
# This script helps you configure your Auth0 credentials for AIBrix

if [[ -z "$1" || -z "$2" || -z "$3" ]]; then
  echo "Usage: ./setup_auth0.sh <AUTH0_DOMAIN> <CLIENT_ID> <CLIENT_SECRET>"
  echo "Example: ./setup_auth0.sh dev-xxx.auth0.com client_123 secret_abc"
  exit 1
fi

DOMAIN=$1
CLIENT_ID=$2
CLIENT_SECRET=$3

# 1. Update the Kubernetes Secret for the Gateway
export KUBECONFIG=k.yaml
echo "Updating AI Gateway Secret..."
kubectl create secret generic oidc-client-secret -n aibrix-system \
  --from-literal=client-secret="$CLIENT_SECRET" \
  --dry-run=client -o yaml | kubectl apply -f -

# 2. Update the Open WebUI Manifest
echo "Updating manifests/open-webui.yaml..."
# Use | as delimiter for sed to avoid issues with URLs containing /
sed -i '' "s|YOUR_AUTH0_DOMAIN|$DOMAIN|g" manifests/open-webui.yaml
sed -i '' "s|YOUR_AUTH0_CLIENT_ID|$CLIENT_ID|g" manifests/open-webui.yaml
sed -i '' "s|YOUR_AUTH0_CLIENT_SECRET|$CLIENT_SECRET|g" manifests/open-webui.yaml

# 3. Update the OIDC Security Policy
echo "Updating manifests/oidc-security-policy.yaml..."
sed -i '' "s|YOUR_AUTH0_DOMAIN|$DOMAIN|g" manifests/oidc-security-policy.yaml
sed -i '' "s|YOUR_AUTH0_CLIENT_ID|$CLIENT_ID|g" manifests/oidc-security-policy.yaml

echo "Applying manifests..."
kubectl apply -f manifests/oidc-security-policy.yaml
kubectl apply -f manifests/open-webui.yaml

echo "Done! Authentication is now configured and applied."
echo ""
echo "Note: You may need to restart the Open WebUI pod if it was already running:"
echo "kubectl rollout restart deployment/open-webui"
