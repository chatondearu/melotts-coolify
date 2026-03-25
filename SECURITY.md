# Security policy

## Supported versions

Security-sensitive fixes are considered for the **default branch** of this
repository (Compose files, docs, and scripts). The MeloTTS **container image** is
maintained upstream; report engine and dependency issues to
[myshell-ai/MeloTTS](https://github.com/myshell-ai/MeloTTS).

## Reporting a vulnerability

Please **do not** open a public issue for undisclosed security problems.

Instead, contact the maintainers privately (e.g. GitHub **Security advisories**
for this repository, if enabled, or the contact method you publish on your fork’s
profile). Include:

- A short description of the issue and suspected impact.
- Steps to reproduce (if safe to share).
- Affected versions or commits, if known.

We aim to acknowledge reports within a few days; timelines depend on maintainer
availability.

## Hardening notes

- Never commit real `.env` files or secrets.
- Exposing MeloTTS on the public internet should always use **TLS** and your
  org’s authentication/access policies — the stock Gradio UI is not a
  multi-tenant product by itself.
