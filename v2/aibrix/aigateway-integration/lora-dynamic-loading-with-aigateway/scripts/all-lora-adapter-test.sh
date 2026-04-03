#!/bin/bash

GATEWAY="http://134.199.201.56/v1/chat/completions"

MODELS=(
  "qwen-coder-1-5b-instruct"
  "qwen-code-lora"
  "qwen-code-educational"
  "qwen-code-flutter-dev-lora"
  "qwen-code-n8n-workflow-generator-lora"
  "qwen-code-sql-lora"
  "yugdave-finetuned-query-response"
)

PROMPTS=(
  "Write a TypeScript function to reverse a string with an example."

  "Explain closures in TypeScript like you are teaching a beginner developer. Include a simple example."

  "Create a Flutter widget that shows a login form with email and password validation."

  "Create an n8n workflow description to fetch data from a REST API and store the result into a database."

  "Given a table users(id, name, email, created_at), write an optimized SQL query to find duplicate emails."

  "Design a REST API endpoint in Node.js (TypeScript) to create a user. Include request and response examples."

  "Given this question: 'How can I improve API latency?', provide a structured, short and actionable answer."
)

for PROMPT in "${PROMPTS[@]}"; do
  echo
  echo "############################################################"
  echo "PROMPT:"
  echo "$PROMPT"
  echo "############################################################"
  echo

  for MODEL in "${MODELS[@]}"; do
    echo "=== Model: $MODEL ==="

    curl -s "$GATEWAY" \
      -H "Content-Type: application/json" \
      -d "{
        \"model\": \"$MODEL\",
        \"messages\": [
          {\"role\": \"user\", \"content\": \"$PROMPT\"}
        ],
        \"max_tokens\": 1024
      }" | jq -r '.choices[0].message.content'

    echo
    echo "------------------------------------------------------------"
  done
done
