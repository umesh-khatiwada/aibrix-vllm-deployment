curl -s http://localhost:30000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Llama-3.2-1B-Instruct",
    "messages": [{"role": "user", "content": "Hello, tell me about the python server"}],
    "max_tokens": 5000
  }' 