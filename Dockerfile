# MeloTTS has no official pre-built image on ghcr.io / Docker Hub.
# This Dockerfile mirrors the upstream repo instructions: clone, pip install -e ., unidic, init_downloads.
# See: https://github.com/myshell-ai/MeloTTS/blob/main/docs/install.md

FROM python:3.9-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

ARG MELOTTS_REPO=https://github.com/myshell-ai/MeloTTS.git
# Shallow clone: use a branch name (e.g. main) or a tag name known on the remote.
ARG MELOTTS_REF=main

RUN git clone --depth 1 --branch "${MELOTTS_REF}" "${MELOTTS_REPO}" .

RUN pip install --no-cache-dir -e .
RUN python -m unidic download
RUN python melo/init_downloads.py

EXPOSE 8888

CMD ["python", "./melo/app.py", "--host", "0.0.0.0", "--port", "8888"]
