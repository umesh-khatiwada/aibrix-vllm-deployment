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

echo "📦 Installing AIBrix Dependencies (Envoy Gateway, CRDs)..."
kubectl create -f https://github.com/vllm-project/aibrix/releases/download/v0.5.0/aibrix-dependency-v0.5.0.yaml --ignore-not-found=true

echo "⚙️ Installing AIBrix Core Components..."
kubectl create -f https://github.com/vllm-project/aibrix/releases/download/v0.5.0/aibrix-core-v0.5.0.yaml --ignore-not-found=true

echo "📡 Waiting for AIBrix System Pods..."
kubectl get pods -n aibrix-system -w
