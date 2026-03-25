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

# Upstream tweaks for modern PyTorch and constrained builders (Coolify, etc.):
# - PyTorch 2.6+ defaults torch.load(..., weights_only=True); MeloTTS checkpoints need full pickle.
# - init_downloads uses Hugging Face by default; many builders hit HF rate limits / egress issues.
#   use_hf=False uses MyShell S3 URLs already defined in melo/download_utils.py.
RUN python <<'PY'
import re
from pathlib import Path

torch_load_snippets = [
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
for path, old, new in torch_load_snippets:
    text = path.read_text(encoding="utf-8")
    if new in text:
        continue
    if old not in text:
        raise SystemExit(f"Expected snippet missing in {path}, cannot patch torch.load")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")

tts_hf_pat = re.compile(r"TTS\(language='([A-Z]{2})', device=device\)")
tts_hf_sub = r"TTS(language='\1', device=device, use_hf=False)"
for rel in ("melo/init_downloads.py", "melo/app.py"):
    path = Path(rel)
    text = path.read_text(encoding="utf-8")
    text2, n = tts_hf_pat.subn(tts_hf_sub, text)
    if n < 1:
        raise SystemExit(f"Expected TTS() calls to patch in {rel}, got {n}")
    path.write_text(text2, encoding="utf-8")

main_py = Path("melo/main.py")
_m = main_py.read_text(encoding="utf-8")
_old = "model = TTS(language=language, device=device)"
_new = "model = TTS(language=language, device=device, use_hf=False)"
if _new not in _m:
    if _old not in _m:
        raise SystemExit("Expected melo/main.py TTS() line missing")
    main_py.write_text(_m.replace(_old, _new, 1), encoding="utf-8")
PY

# Install PyTorch from the official wheel index first so pip does not pull CUDA stacks
# from PyPI (long backtracking / huge downloads that often time out on small builders).
# Override at build time via TORCH_INDEX_URL (e.g. cu121) if you build for GPU.
ARG TORCH_INDEX_URL=https://download.pytorch.org/whl/cpu
# Do not upgrade setuptools to 82+: pkg_resources was removed; librosa imports it (MeloTTS).
RUN pip install --no-cache-dir --upgrade pip wheel \
    && pip install --no-cache-dir "setuptools>=69,<82" \
    && pip install --no-cache-dir torch torchaudio --index-url "${TORCH_INDEX_URL}"

# Use constraints to avoid long Gradio backtracking and torch vs gruut networkx clashes.
RUN pip install --no-cache-dir -e . -c /tmp/pip-constraints.txt
RUN python -m unidic download
RUN python melo/init_downloads.py

EXPOSE 8888

CMD ["python", "./melo/app.py", "--host", "0.0.0.0", "--port", "8888"]
