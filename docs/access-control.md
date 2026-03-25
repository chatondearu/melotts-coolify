# Controlling who can open the MeloTTS URL

The upstream **Gradio** WebUI does **not** enable authentication: anyone who can
reach `https://tts.example.com` can use synthesis unless you add a reverse-proxy
gate. Treat public exposure as **equivalent to running an anonymous compute
endpoint** (DoS, cost, abuse).

## Default in this repository (Coolify stack)

[`docker-compose.yml`](../docker-compose.yml) enables **Traefik Basic Auth** by
default. You **must** set `TRAEFIK_BASIC_AUTH_USERS` (see below). Compose fails at
config time if it is unset (`:?` interpolation).

[`docker-compose.local.yml`](../docker-compose.local.yml) has **no** Traefik
layer (localhost only) — Basic Auth does not apply there.

To **turn off** proxy Basic Auth (not recommended on the public internet), remove
the `traefik.http.routers.melotts.middlewares` label and the
`traefik.http.middlewares.melotts-auth.*` labels from `docker-compose.yml`, and
use another control (SSO, VPN, IP allowlist) if the route stays public.

Below are details and stronger patterns. Prefer **TLS + an identity layer** you
already run (OIDC, SSO) for anything beyond a personal or lab deployment.

## 1. Traefik Basic Auth (default for Coolify)

Put HTTP Basic Authentication **in front of** the service using Traefik
middlewares. Users must send a browser login before Gradio loads. Labels are
already wired in `docker-compose.yml`; you only supply the user digest.

### 1.1 Create a user digest

Generate a **hashed** password (do **not** put plain passwords in Compose):

```bash
docker run --rm httpd:2.4-alpine htpasswd -nbB "myuser" "a-strong-secret-password"
```

Output looks like:

```text
myuser:$2y$05$xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 1.2 Put it in the environment (Coolify / `.env`)

Use a single line. In Docker Compose, every `$` in the hash must be doubled
as `$$` so Compose does not treat it as variable interpolation.

Example (fake hash — use yours):

```env
TRAEFIK_BASIC_AUTH_USERS=myuser:$$2y$$05$$xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

For **multiple** users, separate with a comma (each user still uses `htpasswd` format).

### 1.3 Traefik labels

These are **already present** in [`docker-compose.yml`](../docker-compose.yml).
After setting `TRAEFIK_BASIC_AUTH_USERS`, redeploy; browsers will prompt for
user / password.

**Limits:** shared password, no per-user audit UX, credential leak if HTTP were
ever used (you use `websecure` — good). Rotate the hash if a password is exposed.

## 2. Forward authentication (stronger)

For **SSO**, MFA, or centralized sessions, use a Traefik **ForwardAuth** (or your
Coolify-equivalent) middleware pointing to:

- [OAuth2 Proxy](https://oauth2-proxy.github.io/oauth2-proxy/)
- [Authelia](https://www.authelia.com/)
- [Authentik](https://goauthentik.io/) (proxy provider)

You deploy the IdP/proxy separately, then attach one middleware name to the same
`traefik.http.routers.melotts` router. Exact labels depend on your Traefik version
and provider.

## 3. Network / edge controls

- **Private network only:** do not publish a public `Host()`; access via VPN
  or Tailscale-only DNS.
- **IP allowlist:** Traefik `ipWhiteList` / `IPAllowList` middleware so only
  office or bastion IPs reach the route.
- **Cloudflare Access / Zero Trust** in front of the hostname (no change to this
  compose file if Cloudflare terminates access).

## 4. Gradio `auth=` (upstream code change)

[MeloTTS `melo/app.py`](https://github.com/myshell-ai/MeloTTS/blob/main/melo/app.py)
calls `demo.launch(...)` **without** Gradio’s `auth=` tuple. You could fork or
patch locally to pass `auth=(user, password)` from environment variables, but that
is **duplicative** with Traefik Basic Auth and harder to combine with SSO.
Prefer proxy-level auth unless you have a strong reason to embed it in Python.

## 5. Coolify

Check your Coolify version for **built-in** “protect resource” / SSO / basic
auth features. If Coolify injects its own Traefik labels, align with this
document so you do not define two conflicting routers for the same host.

## Summary

| Approach            | Effort | Typical use case        |
| ------------------- | ------ | ----------------------- |
| Traefik Basic Auth  | Low    | Default on `docker-compose.yml`; small teams |
| ForwardAuth + OIDC  | Medium | Production, real users  |
| VPN / private only  | Medium | Internal tools          |
| Edge (Cloudflare)   | Medium | Already on Cloudflare   |

For this repository, **`docker-compose.yml` ships with Traefik Basic Auth**
(`TRAEFIK_BASIC_AUTH_USERS`). Upgrade to **ForwardAuth** + OIDC for stricter
needs. There is **no pre-configured URL token** in MeloTTS itself.
