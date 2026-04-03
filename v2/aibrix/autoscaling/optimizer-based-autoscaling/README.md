 aibrix_benchmark -m qwen-coder-1-5b-instruct -o qwen_benchmark_output.jsonl




aibrix_gen_profile qwen-coder-1-5b-instruct   --benchmark ./qwen_benchmark_clean.jsonl   --cost 0.15   --e2e 100000   --percentile 99   -o "redis://localhost:6379/?model=qwen-coder-1-5b-instruct"

aibrix_gen_profile qwen-coder-1-5b-instruct   --benchmark ./qwen_benchmark_output.jsonl   --cost 0.15   --e2e 100000   --percentile 99   -o "redis://localhost:6379/?model=qwen-coder-1-5b-instruct"
