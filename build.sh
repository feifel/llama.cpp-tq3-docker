#!/usr/bin/env bash
set -euo pipefail

BUILD_IMAGE="turboquant:build"
FINAL_IMAGE="turboquant:latest"
CONTAINER_NAME="turboquant"
REPO_URL="https://github.com/turbo-tan/llama.cpp-tq3.git"
REPO_DIR="/workspace/llama-cpp-turboquant"

echo "==> Building build image"
docker build -f Dockerfile -t "${BUILD_IMAGE}" .

echo "==> Removing old temporary container if present"
docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

echo "==> Starting GPU-enabled build container"
docker run -dit --gpus all --name "${CONTAINER_NAME}" "${BUILD_IMAGE}" bash

echo "==> Verifying GPU visibility"
docker exec "${CONTAINER_NAME}" bash -lc 'nvidia-smi'
docker exec "${CONTAINER_NAME}" bash -lc 'ldconfig -p | grep libcuda.so.1 || true'

echo "==> Cloning turbo-tan/llama.cpp-tq3 repo"
docker exec "${CONTAINER_NAME}" bash -lc "
  rm -rf ${REPO_DIR} &&
  git clone ${REPO_URL} ${REPO_DIR} &&
  cd ${REPO_DIR} 
"

echo "==> Configuring build"
docker exec "${CONTAINER_NAME}" bash -lc "
  cd ${REPO_DIR} &&
  cmake -B build \
    -DGGML_CUDA=ON \
    -DCMAKE_BUILD_TYPE=Release
"

echo "==> Building"
docker exec "${CONTAINER_NAME}" bash -lc "
  cd ${REPO_DIR} &&
  cmake --build build -j
"

echo "==> Sanity check built binaries"
docker exec "${CONTAINER_NAME}" bash -lc "
  ls -lah ${REPO_DIR}/build/bin &&
  ${REPO_DIR}/build/bin/llama-cli --help >/dev/null 2>&1 || true &&
  ${REPO_DIR}/build/bin/llama-server --help >/dev/null 2>&1 || true
"

echo "==> Committing build container to final image"
docker commit "${CONTAINER_NAME}" "${FINAL_IMAGE}"

echo "==> Cleaning up temporary container"
docker rm -f "${CONTAINER_NAME}"

echo "==> Done"
echo "Built image: ${FINAL_IMAGE}"
