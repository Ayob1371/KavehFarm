#!/usr/bin/env python3
"""تولید فایل‌های صوتی فارسی بازی «مزرعه کاوه».

جمله‌ها را از lines.json می‌خواند، نام کودک را جایگزین می‌کند و
با مدل VITS محلی (بدون اینترنت) برای هر خط یک wav می‌سازد.

اجرا:
    cd tools/tts && source venv/bin/activate && python3 generate_audio.py
"""

from __future__ import annotations

import json
from pathlib import Path

from TTS.api import TTS

# ── مسیرها ──────────────────────────────────────────────

MODULE_DIR = Path(__file__).resolve().parent
MODEL_DIR = MODULE_DIR / "models" / "female-vits"
MODEL_PATH = MODEL_DIR / "best_model.pth"
CONFIG_PATH = MODEL_DIR / "config.json"
LINES_PATH = MODULE_DIR / "lines.json"
OUTPUT_DIR = MODULE_DIR.parents[1] / "game" / "assets" / "audio" / "fa"

# ── ثابت‌ها ─────────────────────────────────────────────

CHILD_NAME = "کاوه"
NAME_PLACEHOLDER = "{name}"


def load_lines() -> dict[str, str]:
    """خواندن خطوط گفتار از فایل JSON."""
    return json.loads(LINES_PATH.read_text(encoding="utf-8"))


def render_text(template: str) -> str:
    """جایگزینی نام کودک در الگوی جمله."""
    return template.replace(NAME_PLACEHOLDER, CHILD_NAME)


def main() -> None:
    """ساخت مدل یک بار و تولید همه‌ی خطوط به‌ترتیب کلید."""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    engine = TTS(model_path=str(MODEL_PATH), config_path=str(CONFIG_PATH))

    for key, template in load_lines().items():
        text = render_text(template)
        destination = OUTPUT_DIR / f"{key}.wav"
        print(f"[{key}] {text}")
        engine.tts_to_file(text=text, file_path=str(destination))

    print(f"✔ همه‌ی صداها در {OUTPUT_DIR} ساخته شدند.")


if __name__ == "__main__":
    main()
