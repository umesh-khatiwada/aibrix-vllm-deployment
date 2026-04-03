#!/bin/bash

GATEWAY="http://165.245.138.223/v1/chat/completions"

PROMPT="Explain closures in TypeScript for a beginner. Use a simple example."

MODELS=(
  "qwen-coder-1-5b-instruct"
  "qwen-code-educational"
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
      \"max_tokens\": 512
    }" | jq -r '.choices[0].message.content'
done
