#!/bin/bash

GATEWAY="http://GATEWAY_LB/v1/chat/completions"

PROMPT="Given a table users(id, name, email, created_at), write an optimized SQL query to find duplicate emails."

MODELS=(
  "qwen-coder-1-5b-instruct"
  "qwen-code-sql-lora"
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
      \"max_tokens\": 400
    }" | jq -r '.choices[0].message.content'
done
