#!/bin/bash

GATEWAY="http://GATEWAY_LB/v1/chat/completions"

PROMPT="Describe an n8n workflow that fetches data from a REST API and saves it into a PostgreSQL database."

MODELS=(
  "qwen-coder-1-5b-instruct"
  "qwen-code-n8n-workflow-generator-lora"
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
