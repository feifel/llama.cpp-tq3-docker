# AGENTS.md

## Architecture

This is a Docker-only project (no app source code) that wraps `llama.cpp` with TurboQuant KV-cache compression to run ~35B parameter models on consumer GPUs (~16 GB VRAM).

The repo does **not** contain `llama.cpp` source — `build.sh` clones `turbo-tan/llama.cpp-tq3` at build time and compiles it inside a container.

## Developer commands

```bash
chmod +x build.sh run.sh        # one-time
./build.sh                      # build Docker image (must run with GPU access — CUDA build fails during docker build)
./run.sh                        # start server on :8080 (env vars MODEL_DIR/MODEL_FILE not used; values hardcoded in run.sh)
```

## Key gotchas

- **Two-step build**: The Docker image is built in two phases because the cmake/CUDA build only works inside a running container with GPU access, not during `docker build`. The intermediate container is committed to the final image.
- **`--cache-type-k turbo3 --cache-type-v turbo3`** works; `iso3`/`iso3` does not (causes 100% GPU, infinite context growth, crash). See README for details.
- **Image name**: The built image is tagged `turboquant:latest` (not `turboquant:build`).
- **Model path in container**: `build.sh` clones to `/workspace/llama-cpp-turboquant`; the server binary is at `build/bin/llama-server`. `run.sh` maps host `models/` to `/models` inside the container.
- **run.sh line 18**: `-ctk q4_0 -ctv tq3_0 -fa on` — this is the TurboQuant cache config used at inference time.
- **run.sh line 17**: `-ngl 99` (offload all layers), `-c 160000` (context window).

## File ownership

| File | Role |
|---|---|
| `Dockerfile` | Base image: nvidia/cuda:12.4.1-devel-ubuntu22.04 with build tools |
| `build.sh` | Two-phase build: container → clone → cmake → compile → commit |
| `run.sh` | Docker run wrapper for `llama-server` with GPU + model volume |
| `README.md` | Setup steps, quirks, performance notes |

No test, lint, CI, or lockfile — this is a deployment wrapper only.
