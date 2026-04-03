#!/bin/bash

GATEWAY="http://GATEWAY_LB/v1/chat/completions"

PROMPT="How can I improve API latency? Give short, actionable and structured points."

MODELS=(
  "qwen-coder-1-5b-instruct"
  "yugdave-finetuned-query-response"
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
      \"max_tokens\": 256
    }" | jq -r '.choices[0].message.content'
done
