# TurboQuant
A Docker project for local LLM deployment on consumer grade hardware like Nvidia RTX 4070TI Super with 16GByte VRAM, by using K/V cache compression for long context windows (160000 tokens with YTan2000/Qwen3.6-35B-A3B-TQ3_4S) at 110 t/s.


## Overview
To deploy large models locally on limited RAM, quantization is required. This project shows how to deploy a 25B coding model with a 55K context window on 16 GByte VRAM. The following resources are used for this:
1. Compressed model: https://huggingface.co/cerebras/Qwen3-Coder-REAP-25B-A3B
2. Context compression: https://github.com/turbo-tan/llama.cpp-tq3

---

## Prerequisites
- Linux operating system
- Docker installed and configured
- NVIDIA GPU with the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) installed and configured


## Quick Setup

### Prepare the Environment
1. Make scripts executable:
    ```bash
    chmod +x build.sh run.sh
    ```

2. Download one of the following model pairs from Huggingface and place them in the host directory `../LLMs` (relative to the project root):
    **YTan2000 variant:**
    ```bash
    https://huggingface.co/YTan2000/Qwen3.6-35B-A3B-TQ3_4S/resolve/main/Qwen3.6-35B-A3B-TQ3_4S.gguf?download=true
    https://huggingface.co/YTan2000/Qwen3.6-35B-A3B-TQ3_4S/resolve/main/mmproj-BF16.gguf?download=true
    ```
    **unsloth variant:**
    ```bash
    https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF/resolve/main/Qwen3.6-35B-A3B-UD-IQ3_XXS.gguf?download=true
    https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF/resolve/main/mmproj-F32.gguf?download=true
    ```

3. Configure the model in `run.sh`:
    ```bash
    MODEL_PATH="/models/unsloth/Qwen3.6-35B-A3B-GGUF/Qwen3.6-35B-A3B-UD-IQ3_XXS.gguf"
    #MODEL_PATH="/models/YTan2000/Qwen3.6-35B-A3B-TQ3_4S/Qwen3.6-35B-A3B-TQ3_4S.gguf"
    ```

### Build and Run
We need a 2 step build, because the cmake/TurboQuant build only works when the Docker container is running with GPU access (e.g. via `--gpus all`), therefore we cannot build it during the `docker build` process. This is why we need a build.sh script on top of the Dockerfile.

4. Build the Docker image:
    ```bash
    ./build.sh
    ```

5. Run the server:
    ```bash
    ./run.sh
    ```

## Server Parameters

By default `run.sh` starts the server with the following options:

| Parameter | Description |
|---|---|
| `-m` | Model path (set to `MODEL_PATH` variable) |
| `-ngl 99` | Offload all layers to GPU (no CPU fallback) |
| `-np 1` | Use NUMA partitioning mode |
| `-c 160000` | Context window of 160,000 tokens |
| `-ctk q4_0 -ctv tq3_0` | TurboQuant KV cache compression (Q4_0 for KV, TQ3_0 for self-attention) |
| `-fa on` | Flash attention enabled |
| `--jinja` | Jinja templating enabled |
| `--reasoning off` | Reasoning mode disabled |
| `--reasoning-budget 0` | No reasoning budget |
| `--reasoning-format deepseek` | Reasoning format set to DeepSeek style |
| `--metrics` | Metrics exposed at `/metrics` endpoint http://localhost:8080/metrics.|

## Access

6. Access the llama.cpp web ui at: http://localhost:8080

    Or OpenCode integration `~/.config/opencode/opencode.json`: 
    ```
    {
       "$schema": "https://opencode.ai/config.json",
       "provider": {
          "llama.cpp": {
             "npm": "@ai-sdk/openai-compatible",
             "name": "llama-server (local)",
             "options": {
                "baseURL": "http://127.0.0.1:8080/v1"
             },
             "models": {
                "Qwen3.6-35B-A3B-UD-IQ3_XXS": {
                   "name": "Qwen3.6-35B-A3B-UD-IQ3_XXS",
                   "limit": {
                      "context": 160000,
                      "output": 8192
                   }
                }
             },
             "Qwen3.6-35B-A3B-TQ3_4S": {
                "name": "Qwen3.6-35B-A3B-TQ3_4S",
                "limit": {
                   "context": 160000,
                   "output": 8192
                }
             }
          }
       },
       "model": "abacus-routellm/m2.7"
    }

    ```

### Stopping the Server

7. To stop the server gracefully, use `Ctrl+C` in the terminal where it's running.


### Performance

On my RTX 4070TI Super with 16 GByte VRAM, I reached 110 tokens per second with TurboQuant `-ctk q4_0 -ctv tq3_0 -fa on` with a context size of 160'000 tokens.
