# Agent instructions — melotts-coolify

Concise context for AI coding agents working in this repository.

## What this repo is

- **Docker Compose + docs + small Python helpers** around MeloTTS, installed via root [Dockerfile](Dockerfile) (**clone + build** at image build time; there is no official pre-built `ghcr.io/myshell-ai/melotts` image).
- **Not** the MeloTTS engine source tree checked into this repo: do not copy upstream app code here. Bugfixes and features belong in [myshell-ai/MeloTTS](https://github.com/myshell-ai/MeloTTS).

## Layout

| Path | Role |
| ---- | ---- |
| `Dockerfile` | Builds MeloTTS from `MELOTTS_REPO` / `MELOTTS_REF` on **`python:3.9-slim-bookworm`**. Installs **`torch` / `torchaudio` first** from **`TORCH_INDEX_URL`**, then **`pip install -e . -c /tmp/pip-constraints.txt`**. After clone, patches **`torch.load`** (`weights_only=False`) and **`TTS(..., use_hf=False)`** in **`init_downloads.py`**, **`app.py`**, **`main.py`** so weights load from MyShell S3 (not Hugging Face) during build and at WebUI startup. |
| `pip-constraints.txt` | Pip constraint file copied into the image; keep in sync with what a clean `pip install -e .` resolves for `gradio`, `gradio-client`, and `networkx` (<3 for gruut). |
| `docker-compose.yml` | Coolify / Traefik stack; external proxy network `TRAEFIK_NETWORK`; backend port **8888** (MeloTTS default). |
| `docker-compose.local.yml` | Standalone local stack; publishes `HOST_PORT` → container **8888**. |
| `.env.example` | Authoritative list of env vars (comments **English**). |
| `docs/coolify.md` | Coolify deploy walkthrough. |
| `docs/openclaw.md` | OpenClaw / TTS integration (Gradio vs local `melo.api`). |
| `docs/access-control.md` | Locking the public URL (Traefik auth, SSO, VPN). |
| `scripts/` | CLI using `melo.api`; `requirements.txt` pins `melotts`. |

## Language

- All **user-facing** markdown, `.env.example` comments, and Python **docstrings / CLI messages** must stay in **English**.
- Do not add large README duplicates; **link** to `docs/*.md` and `.env.example` instead.

## Conventions when editing

1. **Ports**: The process inside the container listens on **8888**. `HOST_PORT` is only for the **host** side in `docker-compose.local.yml`. Traefik `loadbalancer.server.port` must remain **8888** unless the upstream image changes.
2. **Volumes**: Use `OUTPUT_HOST_DIR` on the host and `OUTPUT_DIR` inside the container; do not reuse one variable for both paths.
3. **Compose**: After edits, ensure CI-equivalent validation passes:
   ```bash
   SERVICE_NAME=melotts TRAEFIK_SUBDOMAIN=tts DOMAIN=example.com \
     OUTPUT_HOST_DIR=./output OUTPUT_DIR=/app/output TRAEFIK_NETWORK=traefik_network \
     TRAEFIK_BASIC_AUTH_USERS='ciuser:$apr1$qZ2lDl9/$Yj5X2.Zpp9aGEO1HANtHi/' \
     docker compose -f docker-compose.yml config --quiet
   OUTPUT_HOST_DIR=./output OUTPUT_DIR=/app/output HOST_PORT=8888 \
     docker compose -f docker-compose.local.yml config --quiet
   ```
4. **Scripts**: Prefer small, dependency-light changes; align with [CONTRIBUTING.md](CONTRIBUTING.md). Avoid `melo-api` or wrong PyPI names — use `scripts/requirements.txt` (`melotts`).

## Security & scope

- Never commit `.env` or secrets (see [.gitignore](.gitignore)).
- Prefer documenting risky behaviors (public Gradio, weak Basic Auth passwords) in [SECURITY.md](SECURITY.md) / [docs/access-control.md](docs/access-control.md) rather than silently widening attack surface.

## CI

- Workflow: [.github/workflows/ci.yml](.github/workflows/ci.yml) runs `docker compose config` on both compose files. Keep it **fast**: no `docker build` or MeloTTS image pull in default CI unless explicitly required.
