KV Cache

1. Issue related with the incompatible/no images for the AMD GPU



Issue related with the Aibrix Optimizer based scaling with Mi300x AMD GPu

Blocker 1 — fetcher.go central registry bug (in controller-manager)



The error metric vllm:deployment_replicas not found in central registry comes from fetcher.go inside the distroless controller-manager image. The fetcher calls FetchTypedMetric() which checks an internal Go Metrics registry — and vllm:deployment_replicas is an optimizer metric, not an engine metric, so it's never registered there. This is a confirmed code bug.
The fix is the fetcher.go file we produced — fetchFromGPUOptimizer() needs to make a direct HTTP GET to the optimizer endpoint instead of routing through FetchTypedMetric. That requires rebuilding the controller-manager image.




Blocker 2 — Gateway never writes request traces to Redis



Even after setting AIBRIX_GPU_OPTIMIZER_TRACING_FLAG=true, the gateway only issues GET commands to Redis, never SET. Monitoring Redis confirmed zero SET trace keys. The correct fix per the docs is:
