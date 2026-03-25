# Deploying on Coolify

This repository ships a **Docker Compose** stack meant to run behind **Traefik**
on a [Coolify](https://coolify.io) instance. Coolify can deploy directly from GitHub.

## Prerequisites

- Coolify with Docker and Traefik (or your reverse proxy) already working.
- A DNS name that resolves to your server (for TLS via Let’s Encrypt).
- The **external** Docker network that Traefik uses (see below).

## 1. Find the Traefik network name

The base [docker-compose.yml](../docker-compose.yml) attaches the service to an
**external** network so Traefik can route to MeloTTS.

On your Coolify server, identify the network Traefik is connected to. Names vary
by Coolify version and install path. Examples you might see include network names
containing `traefik` or `coolify`. Use:

```bash
docker network ls
```

Set `TRAEFIK_NETWORK` in your environment (Coolify UI → Environment variables)
to that **exact** name. The compose file uses:

```yaml
networks:
  traefik_network:
    name: ${TRAEFIK_NETWORK:-traefik_network}
    external: true
```

If your Docker network is `coolify-proxy`, set `TRAEFIK_NETWORK=coolify-proxy`.

## 2. Create the Compose resource in Coolify

1. In Coolify, add a new resource from **this GitHub repository**.
2. Choose **Docker Compose** and point it at `docker-compose.yml` in the repo root.
3. Set the branch you want (e.g. `main`).
4. Add environment variables matching [.env.example](../.env.example):

   | Variable             | Purpose |
   | -------------------- | ------- |
   | `SERVICE_NAME`       | Container name |
   | `TRAEFIK_SUBDOMAIN`  | Subdomain part (e.g. `tts` → `tts.example.com`) |
   | `DOMAIN`             | Apex domain (e.g. `example.com`) |
   | `OUTPUT_HOST_DIR`    | Host path for generated audio (bind mount) |
   | `OUTPUT_DIR`         | In-container output path (default `/app/output`) |
   | `TRAEFIK_NETWORK`    | External Traefik Docker network (see step 1) |

5. Deploy. Coolify will pull `ghcr.io/myshell-ai/melotts:latest` and start the stack.

## 3. Traefik labels

The service is exposed with a Traefik `Host()` rule built from `TRAEFIK_SUBDOMAIN` and `DOMAIN` on the
`websecure` entrypoint and the `letsencrypt` certificate resolver, matching a
typical Coolify + Traefik setup. If your instance uses different entrypoint or
resolver names, adjust the labels in `docker-compose.yml` (or use Coolify’s
UI-generated proxy settings if you prefer managing routes there).

## 4. Updates and redeploys

Push to GitHub and trigger a redeploy in Coolify, or configure a deployment
webhook so merges to `main` roll out automatically.

## 5. Resource limits

`deploy.resources.limits.memory` is included for documentation; **plain** `docker compose`
on a single node **may ignore** `deploy` unless you use Swarm or another
orchestrator. For hard limits on one host, set them in Coolify’s UI or your
host policy.

## References

- [Coolify documentation](https://coolify.io/docs)
- [MeloTTS](https://github.com/myshell-ai/MeloTTS) (upstream image and UI)
