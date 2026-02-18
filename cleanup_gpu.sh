#!/bin/bash

# GPU Cleanup Utility
# Use this when vLLM crashes but keeps holding VRAM

echo "🧹 Cleaning up rogue vLLM processes..."

# Kill Python-based vLLM entrypoints
pkill -9 -f "vllm.entrypoints" || true

# Kill EngineCore processes
pkill -9 -f "VLLM::EngineCore" || true

# Kill Model Registry
pkill -9 -f "vllm.model_executor" || true

echo "✅ Processes cleared."
echo "-----------------------------------"
nvidia-smi
echo "-----------------------------------"
echo "💡 If VRAM is still high, try: docker system prune -af"
