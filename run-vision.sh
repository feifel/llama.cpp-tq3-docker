#!/usr/bin/env bash
set -euo pipefail

PORT="8080"
MODEL_DIR="../LLMs"
MODEL_PATH="/models/unsloth/Qwen3.6-35B-A3B-GGUF/Qwen3.6-35B-A3B-UD-IQ3_XXS.gguf"
#MODEL_PATH="/models/YTan2000/Qwen3.6-35B-A3B-TQ3_4S/Qwen3.6-35B-A3B-TQ3_4S.gguf"

docker run --rm -it \
  --gpus all \
  -p ${PORT}:8080 \
  -v "${MODEL_DIR}:/models" \
  "turboquant:latest" \
  /workspace/llama-cpp-turboquant/build/bin/llama-server \
  -m "${MODEL_PATH}" \
  --mmproj "${MMPROJ_PATH}" \
  --host 0.0.0.0 --port 8080 \
  -c 160000 \
  -ngl 99 -np 1 \
  -ctk q4_0 -ctv tq3_0 -fa on \
  --jinja --no-mmproj-offload \
  --reasoning off --reasoning-budget 0 --reasoning-format deepseek
  --metrics
\
