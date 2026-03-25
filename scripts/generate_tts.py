#!/usr/bin/env python3
"""
Generate speech audio from text using the MeloTTS Python API.

Use this on any machine where OpenClaw (or another orchestrator) runs and
where MeloTTS is installed — not necessarily the same host as the Docker stack.

Example:
    python generate_tts.py --text "Hello" --output hello.wav
"""

from __future__ import annotations

import argparse
import sys


def generate_tts(
    text: str,
    output_path: str = "output.wav",
    language: str = "FR",
) -> str:
    """
    Synthesize an audio file from input text using MeloTTS.

    Args:
        text: Source text.
        output_path: Path for the generated audio file.
        language: MeloTTS language code (e.g. FR, EN, ES).

    Returns:
        Path to the generated file (same as output_path).
    """
    try:
        from melo.api import TTS
    except ImportError as err:
        raise ImportError(
            "The 'melo' package is not installed. Install MeloTTS with: "
            "pip install -r requirements.txt (see scripts/requirements.txt) "
            "or follow https://github.com/myshell-ai/MeloTTS"
        ) from err

    model = TTS(language=language, device="auto")
    model.tts_to_file(
        text=text,
        speaker_ids=model.hps.data.spk2id[language],
        speed=1.0,
        file_path=output_path,
    )
    return output_path


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate TTS audio with MeloTTS (local Python API).",
    )
    parser.add_argument(
        "--text",
        type=str,
        required=True,
        help="Text to synthesize.",
    )
    parser.add_argument(
        "--output",
        type=str,
        default="output.wav",
        help="Output audio file path (default: output.wav).",
    )
    parser.add_argument(
        "--language",
        type=str,
        default="FR",
        help="Language code: FR, EN, ES, etc. (default: FR).",
    )
    args = parser.parse_args()

    try:
        path = generate_tts(args.text, args.output, args.language)
        print(f"OK: wrote {path}")
    except ImportError as e:
        print(f"Error: {e}", file=sys.stderr)
        raise SystemExit(1) from e
    except (OSError, KeyError, ValueError, RuntimeError) as e:
        print(f"Error: {e}", file=sys.stderr)
        raise SystemExit(1) from e


if __name__ == "__main__":
    main()
