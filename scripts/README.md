# Scripts

Helpers for working with **MeloTTS** alongside this repository. These run on a
machine with Python and the MeloTTS package installed — typically the same host
where **OpenClaw** runs if you use the local-Python integration path (see [docs/openclaw.md](../docs/openclaw.md)).

## `generate_tts.py`

CLI wrapper around the official `melo.api` Python API.

### Setup

```bash
cd scripts
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

Follow [MeloTTS](https://github.com/myshell-ai/MeloTTS) for extra dependencies
(model downloads, system packages, etc.).

### Usage

```bash
python generate_tts.py --text "Hello" --output hello.wav
python generate_tts.py --text "Bonjour" --output bonjour.wav --language FR
```

### Options

| Option       | Description                          | Default      |
| ------------ | ------------------------------------ | ------------ |
| `--text`     | Text to synthesize                   | **required** |
| `--output`   | Output audio path                    | `output.wav` |
| `--language` | MeloTTS language code (FR, EN, …)    | `FR`         |

### OpenClaw

See [docs/openclaw.md](../docs/openclaw.md) for wiring this script into your
OpenClaw / tool runner configuration (absolute paths, output file location).

## Contributing

Improvements welcome via issue or pull request. Repository guidelines:
[CONTRIBUTING.md](../CONTRIBUTING.md).
