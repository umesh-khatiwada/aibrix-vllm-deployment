# Core Concepts
# AIMs Catalog

The **AIMs Catalog** lists all available AMD Inference Microservice containers. Every AIM is pre-built, AMD-optimized, and ready to pull and deploy. All containers are hosted on Docker Hub under `docker.io/amdenterpriseai/`.

Current version: **0.10.0**

---

## Cohere Labs

### CohereLabs/command-a-reasoning-08-2025
**Status:** stable | **Size:** 111B parameters

111B parameter language model with configurable reasoning and tool use capabilities.

```bash
docker pull docker.io/amdenterpriseai/aim-coherelabs-command-a-reasoning-08-2025:0.10.0
```

---

## Meta Llama

### meta-llama/Llama-3.1-405B-Instruct
**Status:** stable | **Size:** 405B parameters

Multilingual 405B parameter instruction-tuned language model for dialogue use cases.

```bash
docker pull docker.io/amdenterpriseai/aim-meta-llama-llama-3-1-405b-instruct:0.10.0
```

### meta-llama/Llama-3.1-8B-Instruct
**Status:** stable | **Size:** 8B parameters

Multilingual 8B parameter instruction-tuned language model for dialogue use cases.

```bash
docker pull docker.io/amdenterpriseai/aim-meta-llama-llama-3-1-8b-instruct:0.10.0
```

### meta-llama/Llama-3.2-1B-Instruct
**Status:** stable | **Size:** 1B parameters

Multilingual 1B parameter instruction-tuned language model for dialogue and on-device use cases.

```bash
docker pull docker.io/amdenterpriseai/aim-meta-llama-llama-3-2-1b-instruct:0.10.0
```

### meta-llama/Llama-3.2-3B-Instruct
**Status:** stable | **Size:** 3B parameters

Multilingual 3B parameter instruction-tuned language model for dialogue and on-device use cases.

```bash
docker pull docker.io/amdenterpriseai/aim-meta-llama-llama-3-2-3b-instruct:0.10.0
```

### meta-llama/Llama-3.3-70B-Instruct
**Status:** stable | **Size:** 70B parameters

Multilingual 70B parameter instruction-tuned language model for dialogue use cases.

```bash
docker pull docker.io/amdenterpriseai/aim-meta-llama-llama-3-3-70b-instruct:0.10.0
```

---

## Mistral AI

### mistralai/Ministral-3-14B-Instruct-2512
**Status:** stable | **Size:** 14B parameters

14B parameter instruction-tuned language model with vision and function calling capabilities.

```bash
docker pull docker.io/amdenterpriseai/aim-mistralai-ministral-3-14b-instruct-2512:0.10.0
```

### mistralai/Mistral-Large-3-675B-Instruct-2512
**Status:** stable | **Size:** 675B total / 41B active (MoE)

675B parameter granular MoE multimodal model with 41B active parameters and vision capabilities.

```bash
docker pull docker.io/amdenterpriseai/aim-mistralai-mistral-large-3-675b-instruct-2512:0.10.0
```

### mistralai/Mistral-Small-3.2-24B-Instruct-2506
**Status:** stable | **Size:** 24B parameters

24B parameter instruction-tuned language model with vision and function calling capabilities.

```bash
docker pull docker.io/amdenterpriseai/aim-mistralai-mistral-small-3-2-24b-instruct-2506:0.10.0
```

### mistralai/Mixtral-8x22B-Instruct-v0.1
**Status:** stable | **Size:** 141B total (8 experts, sparse MoE)

Sparse MoE language model with 141B total parameters across 8 experts and function calling support.

```bash
docker pull docker.io/amdenterpriseai/aim-mistralai-mixtral-8x22b-instruct-v0-1:0.10.0
```

### mistralai/Mixtral-8x7B-Instruct-v0.1
**Status:** stable | **Size:** 47B total (8 experts, sparse MoE)

Sparse MoE language model with 47B total parameters across 8 experts.

```bash
docker pull docker.io/amdenterpriseai/aim-mistralai-mixtral-8x7b-instruct-v0-1:0.10.0
```

---

## OpenAI (Open-weight)

### openai/gpt-oss-120b
**Status:** stable | **Size:** 117B total / 5.1B active (MoE)

Open-weight 117B parameter MoE model with 5.1B active parameters and configurable reasoning.

```bash
docker pull docker.io/amdenterpriseai/aim-openai-gpt-oss-120b:0.10.0
```

### openai/gpt-oss-20b
**Status:** stable | **Size:** 21B total / 3.6B active (MoE)

Open-weight 21B parameter MoE model with 3.6B active parameters for lower-latency use cases.

```bash
docker pull docker.io/amdenterpriseai/aim-openai-gpt-oss-20b:0.10.0
```

---

## Qwen

### Qwen/Qwen3-235B-A22B
**Status:** stable | **Size:** 235B total / 22B active (MoE)

235B parameter MoE language model with 22B active parameters and dual thinking modes.

```bash
docker pull docker.io/amdenterpriseai/aim-qwen-qwen3-235b-a22b:0.10.0
```

### Qwen/Qwen3-32B
**Status:** stable | **Size:** 32.8B parameters (dense)

32.8B parameter dense language model with dual thinking modes and multilingual support.

```bash
docker pull docker.io/amdenterpriseai/aim-qwen-qwen3-32b:0.10.0
```

---

## DeepSeek

### deepseek-ai/DeepSeek-R1
**Status:** stable | **Size:** 671B total / 37B active (MoE) | **Context:** 128K

671B parameter MoE reasoning model with 37B active parameters and 128K context length.

```bash
docker pull docker.io/amdenterpriseai/aim-deepseek-ai-deepseek-r1:0.10.0
```

### deepseek-ai/DeepSeek-R1-0528
**Status:** stable | **Size:** 671B total / 37B active (MoE)

671B parameter MoE reasoning model with 37B active parameters — updated version of DeepSeek-R1.

```bash
docker pull docker.io/amdenterpriseai/aim-deepseek-ai-deepseek-r1-0528:0.10.0
```

### deepseek-ai/DeepSeek-V3.1
**Status:** stable | **Size:** 671B total / 37B active (MoE)

671B parameter MoE model with 37B active parameters supporting thinking and non-thinking modes.

```bash
docker pull docker.io/amdenterpriseai/aim-deepseek-ai-deepseek-v3-1:0.10.0
```

### deepseek-ai/DeepSeek-V3.1-Terminus
**Status:** stable | **Size:** 671B total / 37B active (MoE)

671B parameter MoE model with 37B active parameters, refined for language consistency and agent tasks.

```bash
docker pull docker.io/amdenterpriseai/aim-deepseek-ai-deepseek-v3-1-terminus:0.10.0
```

---

## Quick Reference Table

| Model | Provider | Type | Params (Total) | Active Params |
|---|---|---|---|---|
| command-a-reasoning-08-2025 | Cohere Labs | Dense | 111B | 111B |
| Llama-3.1-405B-Instruct | Meta | Dense | 405B | 405B |
| Llama-3.1-8B-Instruct | Meta | Dense | 8B | 8B |
| Llama-3.2-1B-Instruct | Meta | Dense | 1B | 1B |
| Llama-3.2-3B-Instruct | Meta | Dense | 3B | 3B |
| Llama-3.3-70B-Instruct | Meta | Dense | 70B | 70B |
| Ministral-3-14B-Instruct-2512 | Mistral AI | Dense | 14B | 14B |
| Mistral-Large-3-675B-Instruct-2512 | Mistral AI | MoE | 675B | 41B |
| Mistral-Small-3.2-24B-Instruct-2506 | Mistral AI | Dense | 24B | 24B |
| Mixtral-8x22B-Instruct-v0.1 | Mistral AI | MoE | 141B | — |
| Mixtral-8x7B-Instruct-v0.1 | Mistral AI | MoE | 47B | — |
| gpt-oss-120b | OpenAI | MoE | 117B | 5.1B |
| gpt-oss-20b | OpenAI | MoE | 21B | 3.6B |
| Qwen3-235B-A22B | Qwen | MoE | 235B | 22B |
| Qwen3-32B | Qwen | Dense | 32.8B | 32.8B |
| DeepSeek-R1 | DeepSeek | MoE | 671B | 37B |
| DeepSeek-R1-0528 | DeepSeek | MoE | 671B | 37B |
| DeepSeek-V3.1 | DeepSeek | MoE | 671B | 37B |
| DeepSeek-V3.1-Terminus | DeepSeek | MoE | 671B | 37B |

---

## Choosing a Model

=== "I need a small / fast model"
    - `Llama-3.2-1B-Instruct` — smallest, fastest, good for edge/on-device
    - `Llama-3.2-3B-Instruct` — slightly larger, better quality
    - `Llama-3.1-8B-Instruct` — popular balanced choice
    - `gpt-oss-20b` — OpenAI open-weight, 3.6B active params (MoE efficiency)

=== "I need strong general chat / reasoning"
    - `Llama-3.3-70B-Instruct` — strong multilingual chat
    - `Mistral-Small-3.2-24B-Instruct-2506` — vision + function calling
    - `Qwen3-32B` — dual thinking modes, multilingual

=== "I need frontier-scale reasoning"
    - `DeepSeek-R1` / `DeepSeek-R1-0528` — 128K context, strong reasoning
    - `Qwen3-235B-A22B` — large MoE with thinking modes
    - `command-a-reasoning-08-2025` — configurable reasoning + tool use
    - `gpt-oss-120b` — OpenAI open-weight with configurable reasoning

=== "I need vision / multimodal"
    - `Ministral-3-14B-Instruct-2512` — vision + function calling
    - `Mistral-Small-3.2-24B-Instruct-2506` — vision + function calling
    - `Mistral-Large-3-675B-Instruct-2512` — large multimodal MoE

=== "I need function calling / agents"
    - `DeepSeek-V3.1-Terminus` — refined for agent tasks
    - `command-a-reasoning-08-2025` — tool use capabilities
    - `Mixtral-8x22B-Instruct-v0.1` — function calling support

---

!!! note "MoE Models"
    **MoE (Mixture of Experts)** models have a large total parameter count but only activate a fraction during inference. For example, DeepSeek-R1 has 671B total parameters but only 37B are active per token — making it much more efficient to run than a dense 671B model.

---

## Official Reference

:material-open-in-new: [AIMs Catalog — Official Docs](https://enterprise-ai.docs.amd.com/en/latest/aims/catalog/models.html)
