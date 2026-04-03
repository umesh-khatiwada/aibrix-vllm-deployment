| Metric                         | Type      | Example `targetValue` | Notes / Scaling Logic                                                               |
| ------------------------------ | --------- | --------------------- | ----------------------------------------------------------------------------------- |
| `num_requests_running`         | Gauge     | `"5"`                 | Scale up if average pod handles >5 concurrent requests.                             |
| `kv_cache_usage_perc`          | Gauge     | `"0.5"`               | Scale if KV cache usage exceeds 50% of capacity.                                    |
| `prefix_cache_queries`         | Counter   | `"100"` (rate/sec)    | Scale if cache query rate per pod exceeds 100 req/sec. Convert Counter → rate.      |
| `prefix_cache_hits`            | Counter   | `"80"` (rate/sec)     | Optional: scale based on cache hit rate, if relevant.                               |
| `prompt_tokens_total`          | Counter   | `"5000"` (rate/sec)   | Scale if number of input tokens processed per pod exceeds threshold.                |
| `generation_tokens_total`      | Counter   | `"5000"` (rate/sec)   | Scale if output generation tokens exceed threshold.                                 |
| `request_success_total`        | Counter   | `"10"` (rate/sec)     | Scale based on completed requests per second per pod.                               |
| `request_prompt_tokens`        | Histogram | `"1024"`              | Scale if input prompt length exceeds 1k tokens per request (use avg or percentile). |
| `request_generation_tokens`    | Histogram | `"1024"`              | Scale if output generation exceeds 1k tokens per request.                           |
| `time_to_first_token_seconds`  | Histogram | `"0.5"`               | Scale if TTFT exceeds 0.5s (sluggish response).                                     |
| `inter_token_latency_seconds`  | Histogram | `"0.05"`              | Scale if latency between tokens >50ms.                                              |
| `e2e_request_latency_seconds`  | Histogram | `"1.0"`               | Scale if end-to-end request latency >1s.                                            |
| `request_prefill_time_seconds` | Histogram | `"0.3"`               | Scale if prefill stage >300ms per request.                                          |
| `request_decode_time_seconds`  | Histogram | `"0.5"`               | Scale if decode stage >500ms per request.                                           |
