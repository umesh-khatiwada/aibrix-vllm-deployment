#!/bin/bash

# AIBrix Setup Script for K3s
# Version: v0.5.0

set -e

KUBECONFIG_PATH="./k.yaml"
if [ ! -f "$KUBECONFIG_PATH" ]; then
    echo "❌ Error: k.yaml not found in current directory."
    exit 1
fi

export KUBECONFIG=$KUBECONFIG_PATH

echo "🧹 Cleaning up conflicting CRDs and resources..."
# Delete problematic CRDs that often cause versioning/manager conflicts
kubectl delete crd \
  backendtlspolicies.gateway.networking.k8s.io \
  backendlbpolicies.gateway.networking.k8s.io \
  gatewayclasses.gateway.networking.k8s.io \
  gateways.gateway.networking.k8s.io \
  httproutes.gateway.networking.k8s.io \
  referencegrants.gateway.networking.k8s.io \
  tcproutes.gateway.networking.k8s.io \
  tlsroutes.gateway.networking.k8s.io \
  udproutes.gateway.networking.k8s.io \
  grpcroutes.gateway.networking.k8s.io \
  --ignore-not-found=true

# Delete conflicting deployment if it exists (managed by a different tool like helm)
kubectl delete deployment envoy-gateway -n envoy-gateway-system --ignore-not-found=true

echo "📦 Installing AIBrix Dependencies (Envoy Gateway, CRDs)..."
kubectl apply --server-side --force-conflicts -f https://github.com/vllm-project/aibrix/releases/download/v0.5.0/aibrix-dependency-v0.5.0.yaml

echo "⚙️ Installing AIBrix Core Components..."
kubectl apply --server-side --force-conflicts -f https://github.com/vllm-project/aibrix/releases/download/v0.5.0/aibrix-core-v0.5.0.yaml

echo "📡 Waiting for AIBrix System Pods..."
kubectl get pods -n aibrix-system
