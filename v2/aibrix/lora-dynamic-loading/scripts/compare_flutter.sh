#!/bin/bash

GATEWAY="http://GATEWAY_LB/v1/chat/completions"

PROMPT="Create a Flutter widget for a login form with email and password validation."

MODELS=(
  "qwen-coder-1-5b-instruct"
  "qwen-code-flutter-dev-lora"
)

for MODEL in "${MODELS[@]}"; do
  echo
  echo "===== $MODEL ====="

  curl -s "$GATEWAY" \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"$MODEL\",
      \"messages\": [
        {\"role\": \"user\", \"content\": \"$PROMPT\"}
      ],
      \"max_tokens\": 700
    }" | jq -r '.choices[0].message.content'
done
