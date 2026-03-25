# Contributing

Thanks for helping improve **melotts-coolify**.

## Scope

This repo hosts Docker Compose configuration, docs, and small helper scripts
around the upstream [MeloTTS](https://github.com/myshell-ai/MeloTTS) image.
Changes that belong upstream (model code, Gradio app, image build) should go
to the MeloTTS project instead.

## How to contribute

1. **Issues** — Open an issue for bugs, unclear docs, or Coolify/Traefik edge cases.
2. **Pull requests** — Keep changes focused; match existing style (English for docs
   and user-facing messages).
3. **CI** — Pull requests must pass the Compose validation workflow (see
   `.github/workflows/ci.yml`).

## Local checks

```bash
docker compose -f docker-compose.yml config
docker compose -f docker-compose.local.yml config
```

Use the environment variables documented in `.env.example` (or export minimal
values as in CI).

## Badges

The README links to the workflow file under `.github/workflows/`. After you fork,
optionally replace that with a passing-status badge for your repo if you prefer.
