import requests
import json

def query_aibrix():
    url = "http://localhost:8888/v1/chat/completions"
    headers = {
        "Content-Type": "application/json",
        "routing-strategy": "random"
    }
    
    payload = {
        "model": "deepseek-r1-qwen-1b5",
        "messages": [
            {"role": "user", "content": "Explain Kubernetes pods in one sentence."}
        ],
        "max_tokens": 100
    }

    print(f"📡 Sending request to {url}...")
    try:
        response = requests.post(url, headers=headers, data=json.dumps(payload))
        if response.status_code == 200:
            result = response.json()
            print("\n✨ Response from DeepSeek-R1-1.5B:")
            print("-" * 30)
            print(result['choices'][0]['message']['content'])
            print("-" * 30)
        else:
            print(f"❌ Error: {response.status_code}")
            print(response.text)
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        print("💡 Did you remember to port-forward the gateway?")
        print("   kubectl -n envoy-gateway-system port-forward service/envoy-aibrix-system-aibrix-eg-903790dc 8888:80")

if __name__ == "__main__":
    query_aibrix()
