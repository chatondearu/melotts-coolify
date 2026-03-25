# Deploying on Coolify

This repository ships a **Docker Compose** stack meant to run behind **Traefik**
on a [Coolify](https://coolify.io) instance. Coolify can deploy directly from GitHub.

## Prerequisites

- Coolify with Docker and Traefik (or your reverse proxy) already working.
- A DNS name that resolves to your server (for TLS via Let’s Encrypt).
- The **external** Docker network that Traefik uses (see below).
- **First deploy builds the image** from [Dockerfile](../Dockerfile) (clone MeloTTS, PyTorch CPU wheels by default, `pip install -e .`, model downloads). Default **`TORCH_INDEX_URL`** keeps builds smaller and faster than letting pip resolve CUDA stacks from PyPI. Allow enough **RAM**, **disk**, and **build time** (often several minutes to 20+ depending on the host). There is **no** maintained pre-built `ghcr.io/myshell-ai/melotts` image at the time of writing.

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
   | `MELOTTS_REPO`       | Git URL to clone at image build (default upstream) |
   | `MELOTTS_REF`        | Branch or tag to build (default `main`) |
   | `MELOTTS_IMAGE`      | Name/tag for the built image (optional; set when pushing to a registry) |
   | `TORCH_INDEX_URL`    | PyTorch wheel index at **build** time (default CPU: `https://download.pytorch.org/whl/cpu`). Use a CUDA index only if your builder supports GPU wheels and you need CUDA at runtime. |
   | `TRAEFIK_BASIC_AUTH_USERS` | **Required.** One or more `htpasswd` user digests for Traefik Basic Auth (browser login before Gradio). See [docs/access-control.md](access-control.md). |

5. Deploy. Coolify will **build** the MeloTTS image from this repo’s `Dockerfile`, then start the stack. Set `MELOTTS_IMAGE` if you want Coolify to tag/push the build to your own registry. The public route is protected by **Basic Auth** unless you remove those labels (see access-control doc).

## 3. Traefik labels

The service is exposed with a Traefik `Host()` rule built from `TRAEFIK_SUBDOMAIN` and `DOMAIN` on the
`websecure` entrypoint and the `letsencrypt` certificate resolver, matching a
typical Coolify + Traefik setup. A **Basic Auth** middleware is attached by default
(`TRAEFIK_BASIC_AUTH_USERS`). If your instance uses different entrypoint or
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

## 6. Build exits with code 255 (log stops during `pip install`)

Coolify may report **exit code 255** when the compose build is **stopped externally** before pip finishes—often a **deployment/build timeout** or the helper container hitting **memory limits** during the heavy `pip install -e .` step. The [Dockerfile](../Dockerfile) uses [pip-constraints.txt](../pip-constraints.txt) to pin Gradio and `networkx` so resolution stays fast and needs less RAM; if it still fails:

- Raise the **build timeout** (and builder **memory**) for this resource in Coolify if your plan allows it.
- Retry: transient CDN issues during `init_downloads` can still fail a layer; the image build uses MyShell **S3** mirrors (`use_hf=False` patches in the Dockerfile) instead of Hugging Face for default checkpoints to reduce builder failures.

## References

- [Coolify documentation](https://coolify.io/docs)
- [MeloTTS install guide](https://github.com/myshell-ai/MeloTTS/blob/main/docs/install.md) (upstream; Docker build/run examples)
