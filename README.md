# melotts-coolify

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![CI](https://img.shields.io/badge/CI-GitHub_Actions-2088FF?logo=github-actions&logoColor=white)](.github/workflows/ci.yml)

Deploy [**MeloTTS**](https://github.com/myshell-ai/MeloTTS) with **Docker Compose**, tuned for [**Coolify**](https://coolify.io) and **Traefik**, with optional **OpenClaw** integration notes for text-to-speech.

## Features

- French-first voices (and other MeloTTS languages) via an image **built from official MeloTTS source** (this repo’s `Dockerfile`).
- **Coolify-ready** Compose file with Traefik labels and an external proxy network.
- **Local compose** variant with a published port (no Traefik).
- **OpenClaw-oriented** docs: Web UI vs local Python `melo.api` (see [docs/openclaw.md](docs/openclaw.md)).

This repository is **configuration, a build wrapper, and documentation** only. The speech engine is [myshell-ai/MeloTTS](https://github.com/myshell-ai/MeloTTS).

### Docker image note

There is **no** reliably available pre-built image such as `ghcr.io/myshell-ai/melotts:latest` (that path is not published as a public package you can pull). This project therefore uses a [Dockerfile](Dockerfile) that follows the upstream instructions: `git clone`, **PyTorch from `TORCH_INDEX_URL`** (CPU by default — avoids huge CUDA resolution on small builders), `pip install -e .`, `python -m unidic download`, `python melo/init_downloads.py`, then `melo/app.py` on port **8888**. See the official [install guide](https://github.com/myshell-ai/MeloTTS/blob/main/docs/install.md) for CLI, Web UI, and Python API usage inside the container or on bare metal.

**First `docker compose up --build`**: expect a substantial build with large downloads and sufficient **RAM/disk** on the builder; CPU PyTorch by default keeps this more predictable than an unconstrained `torch` install from PyPI.

## Requirements

- Docker 24+ and Docker Compose v2 (with build support).
- For Coolify: a running Coolify instance with Traefik (or compatible proxy) and a DNS name.
- For local use: nothing beyond Docker (see below).

## Quick start (Coolify + GitHub)

1. Fork or clone this repo and connect it in Coolify as a **Docker Compose** resource (`docker-compose.yml` at repo root).
2. On the server, find the **external** Docker network used by Traefik (`docker network ls`), then set `TRAEFIK_NETWORK` accordingly.
3. Set variables from [.env.example](.env.example) in the Coolify UI (see [docs/coolify.md](docs/coolify.md) for a full walkthrough).
4. Deploy (build + run) and open `https://${TRAEFIK_SUBDOMAIN}.${DOMAIN}` — you should get the **Gradio** MeloTTS UI.

## Local development (no Traefik)

```bash
cp .env.example .env
# Edit .env if needed (HOST_PORT, OUTPUT_HOST_DIR, MELOTTS_REF, …)

docker compose -f docker-compose.local.yml up --build -d
```

Open `http://localhost:${HOST_PORT:-8888}` (default **8888**).

Stop with:

```bash
docker compose -f docker-compose.local.yml down
```

## Environment variables

| Variable | Description |
| -------- | ----------- |
| `MELOTTS_REPO` | Git URL cloned at **image build** (default upstream MeloTTS). |
| `MELOTTS_REF` | Branch or tag to build (default `main`). |
| `MELOTTS_IMAGE` | Image name:tag after build (default `melotts-coolify:local`). |
| `TORCH_INDEX_URL` | PyTorch wheel index at **image build** (default CPU: `https://download.pytorch.org/whl/cpu`). |
| `SERVICE_NAME` | Container name (`melotts` by default). |
| `TRAEFIK_SUBDOMAIN` | Subdomain for Traefik (e.g. `tts` → `tts.example.com`). |
| `DOMAIN` | Apex domain (e.g. `example.com`). |
| `HOST_PORT` | Host port when using `docker-compose.local.yml` (container listens on **8888**). |
| `OUTPUT_HOST_DIR` | Host directory bind-mounted to `/app/output`. |
| `OUTPUT_DIR` | In-container output path (default `/app/output`). |
| `TRAEFIK_NETWORK` | Real Docker network name Traefik uses (external network in prod compose). |
| `TRAEFIK_BASIC_AUTH_USERS` | **Required** for `docker-compose.yml`: htpasswd line for Traefik Basic Auth (see [docs/access-control.md](docs/access-control.md)). Not used by `docker-compose.local.yml`. |

## OpenClaw

The MeloTTS container exposes a **Gradio UI** on port **8888**; there is **no official stable REST API** in that setup for generic automation. For agents, the recommended path is usually the **local Python** script in `scripts/`. Details: [docs/openclaw.md](docs/openclaw.md).

## Scripts

See [scripts/README.md](scripts/README.md) and [scripts/requirements.txt](scripts/requirements.txt).

## CI

GitHub Actions validates Compose files with `docker compose ... config` (no image build, pull, or TTS inference). Workflow: [.github/workflows/ci.yml](.github/workflows/ci.yml).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). For **AI coding agents** (scope, compose rules, language policy), see [AGENTS.md](AGENTS.md).

## Security

See [SECURITY.md](SECURITY.md). The **Coolify** compose file enables **Traefik
Basic Auth** by default; you must set `TRAEFIK_BASIC_AUTH_USERS`. For stronger
controls (SSO, VPN, IP allowlist), see [docs/access-control.md](docs/access-control.md).

## License

[MIT](LICENSE)

Upstream MeloTTS has its own license — see the [MeloTTS repository](https://github.com/myshell-ai/MeloTTS).

## References

- [MeloTTS](https://github.com/myshell-ai/MeloTTS)
- [MeloTTS install / Docker](https://github.com/myshell-ai/MeloTTS/blob/main/docs/install.md)
- [Coolify](https://coolify.io)
- [Traefik](https://traefik.io)
