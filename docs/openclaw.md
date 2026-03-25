# OpenClaw and MeloTTS

There are two practical ways to use MeloTTS from an **OpenClaw** (or similar)
setup. Pick the one that matches where your agent runs and how you expose audio.

## A. Gradio Web UI over HTTPS (human or custom automation)

The container built from this repo’s [Dockerfile](../Dockerfile) (upstream MeloTTS) runs a **Gradio** UI on
**port 8888**. There is **no stable, documented public REST API** in that stock setup for generic HTTP clients.

After you deploy with Coolify (or [docker-compose.local.yml](../docker-compose.local.yml)),
you can open:

```text
https://tts.example.com
```

(or `http://localhost:8888` for local compose) and generate speech in the
browser.

If you automate against Gradio, you must rely on Gradio’s **internal** HTTP
contract (version-specific) or add your own thin HTTP wrapper. For predictable
machine-to-machine access, prefer path (B) or a dedicated API container built on
top of MeloTTS.

## B. Local Python API on the OpenClaw host (recommended for agents)

Run MeloTTS via the official **`melo.api`** Python package on the **same machine**
that runs OpenClaw (or that can run a subprocess / tool invocation).

1. Install dependencies (see [scripts/README.md](../scripts/README.md)):

   ```bash
   cd scripts
   pip install -r requirements.txt
   ```

2. Use [scripts/generate_tts.py](../scripts/generate_tts.py) from a **stable
   absolute path**:

   ```bash
   python /path/to/melotts-coolify/scripts/generate_tts.py \
     --text "Hello from OpenClaw" \
     --output /tmp/openclaw_tts.wav
   ```

3. Point your OpenClaw / tool-runner configuration at that command, and read the
   resulting file path (exact YAML depends on your OpenClaw version — adapt the
   following pattern):

   ```yaml
   # Illustrative only — replace with your real OpenClaw / mcporter schema
   tts:
     command: >
       python /path/to/melotts-coolify/scripts/generate_tts.py
       --text "{text}"
       --output /tmp/tts_output.wav
     output_file: /tmp/tts_output.wav
   ```

This path does **not** require the Docker stack on the same host; it only needs
Python + MeloTTS and enough CPU/GPU resources for inference.

## Summary

| Approach              | Needs              | Best for                          |
| --------------------- | ------------------ | --------------------------------- |
| Gradio URL in browser | Deployed container | Manual checks, demos              |
| `generate_tts.py`     | Local MeloTTS pip  | Agents / OpenClaw on that host    |
| Custom REST wrapper   | Your API layer     | Strict HTTP contracts, clustering |

## Upstream

- [MeloTTS repository](https://github.com/myshell-ai/MeloTTS)
