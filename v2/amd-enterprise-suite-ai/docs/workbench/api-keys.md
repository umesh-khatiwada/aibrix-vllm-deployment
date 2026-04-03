# API Keys

**API Keys** allow external applications and scripts to authenticate with the platform and call your deployed models programmatically.

---

## Creating an API Key

1. Go to **Workbench → API Keys**
2. Click **Create API Key**
3. Give the key a descriptive name (e.g., `my-app-production`)
4. Copy the key immediately — **it won't be shown again**

!!! danger
    Store your API key securely. Treat it like a password. Do not commit it to version control.

---

## Using Your API Key

The platform exposes an **OpenAI-compatible API**, so you can use the standard OpenAI Python library:

```python
from openai import OpenAI

client = OpenAI(
    api_key="YOUR_API_KEY",
    base_url="https://your-platform-url/v1"
)

response = client.chat.completions.create(
    model="your-deployed-model-name",
    messages=[{"role": "user", "content": "Explain quantum computing simply."}]
)

print(response.choices[0].message.content)
```

### With `requests` directly

```python
import requests

headers = {"Authorization": "Bearer YOUR_API_KEY"}
payload = {
    "model": "your-deployed-model-name",
    "messages": [{"role": "user", "content": "Hello!"}]
}

response = requests.post(
    "https://your-platform-url/v1/chat/completions",
    headers=headers,
    json=payload
)
print(response.json())
```

---

## Managing Keys

| Action | How |
|---|---|
| View all keys | Workbench → API Keys |
| Revoke a key | Click the delete icon next to the key |
| Rename a key | Not supported — delete and recreate |

---

## Best Practices

- Create **one key per application** so you can revoke individual access if needed
- Store keys in environment variables, not in source code:
  ```bash
  export AMD_AI_API_KEY="your-key-here"
  ```
- Rotate keys periodically

---

## Official Reference

 [API Keys Docs](https://enterprise-ai.docs.amd.com/en/latest/workbench/api-keys.html)
