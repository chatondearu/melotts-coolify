# MeloTTS has no official pre-built image on ghcr.io / Docker Hub.
# This Dockerfile mirrors the upstream repo instructions: clone, pip install -e ., unidic, init_downloads.
# See: https://github.com/myshell-ai/MeloTTS/blob/main/docs/install.md

FROM python:3.9-slim-bookworm

WORKDIR /app

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    libsndfile1 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# From this repo (not the MeloTTS clone); tightens pip resolution for Gradio / networkx.
COPY pip-constraints.txt /tmp/pip-constraints.txt

ARG MELOTTS_REPO=https://github.com/myshell-ai/MeloTTS.git
# Shallow clone: use a branch name (e.g. main) or a tag name known on the remote.
ARG MELOTTS_REF=main

RUN git clone --depth 1 --branch "${MELOTTS_REF}" "${MELOTTS_REPO}" .

# PyTorch 2.6+ defaults torch.load(..., weights_only=True). MeloTTS checkpoints are full
# pickles; loading them fails without weights_only=False. See melo/download_utils.py and
# melo/utils.py upstream.
RUN python <<'PY'
from pathlib import Path

replacements = [
    (
        Path("melo/download_utils.py"),
        "return torch.load(ckpt_path, map_location=device)",
        "return torch.load(ckpt_path, map_location=device, weights_only=False)",
    ),
    (
        Path("melo/utils.py"),
        'checkpoint_dict = torch.load(checkpoint_path, map_location="cpu")',
        'checkpoint_dict = torch.load(checkpoint_path, map_location="cpu", weights_only=False)',
    ),
]
for path, old, new in replacements:
    text = path.read_text()
    if new in text:
        continue
    if old not in text:
        raise SystemExit(f"Expected snippet missing in {path}, cannot patch torch.load")
    path.write_text(text.replace(old, new, 1))
PY

# Install PyTorch from the official wheel index first so pip does not pull CUDA stacks
# from PyPI (long backtracking / huge downloads that often time out on small builders).
# Override at build time via TORCH_INDEX_URL (e.g. cu121) if you build for GPU.
ARG TORCH_INDEX_URL=https://download.pytorch.org/whl/cpu
RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
    && pip install --no-cache-dir torch torchaudio --index-url "${TORCH_INDEX_URL}"

# Use constraints to avoid long Gradio backtracking and torch vs gruut networkx clashes.
RUN pip install --no-cache-dir -e . -c /tmp/pip-constraints.txt
RUN python -m unidic download
RUN python melo/init_downloads.py

EXPOSE 8888

CMD ["python", "./melo/app.py", "--host", "0.0.0.0", "--port", "8888"]
