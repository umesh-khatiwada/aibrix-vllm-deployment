#!/bin/bash

GATEWAY="http://134.199.201.56/v1/chat/completions"
PROMPT="Write a TypeScript function to reverse a string with example"

MODELS=(
  "qwen-coder-1-5b-instruct"
  "qwen-code-lora"
  "qwen-code-educational"
  "qwen-code-flutter-dev-lora"
  "qwen-code-n8n-workflow-generator-lora"
  "qwen-code-sql-lora"
  "yugdave-finetuned-query-response"
)

for MODEL in "${MODELS[@]}"; do
  echo "=== Output from $MODEL ==="
  curl -s "$GATEWAY" \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"$MODEL\",
      \"messages\": [{\"role\": \"user\", \"content\": \"$PROMPT\"}],
      \"max_tokens\": 1024
    }" | jq '.choices[0].message.content'
  echo -e "\n"
done
