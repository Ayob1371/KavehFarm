#!/usr/bin/env python3
"""استخراج پیکربندی تعبیه‌شده در چک‌پوینت VITS.

چک‌پوینت‌های آموزش‌شده با Coqui Trainer، پیکربندیِ همان اجرای
آموزش را درون فایل مدل نگه می‌دارند. این اسکریپت آن را بیرون
می‌کشد و به‌جای config.json کنار مدل می‌نویسد تا جفتِ
مدل/پیکربندی همیشه درست باشد.

اجرا:
    cd tools/tts && source venv/bin/activate && python3 extract_config.py
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import torch

# ── مسیرها ──────────────────────────────────────────────

MODULE_DIR = Path(__file__).resolve().parent
MODEL_DIR = MODULE_DIR / "models" / "female-vits"
MODEL_PATH = MODEL_DIR / "best_model.pth"
CONFIG_PATH = MODEL_DIR / "config.json"

# ── ثابت‌ها ─────────────────────────────────────────────

CONFIG_KEY = "config"


def extract_config(checkpoint: dict) -> str:
    """بازگرداندن پیکربندی چک‌پوینت به‌صورت رشته‌ی JSON."""
    raw: Any = checkpoint[CONFIG_KEY]
    if hasattr(raw, "to_json"):
        return str(raw.to_json())
    return json.dumps(raw, ensure_ascii=False, indent=2)


def main() -> None:
    """بارگذاری چک‌پوینت روی CPU و نوشتن پیکربندی کنار مدل."""
    checkpoint = torch.load(MODEL_PATH, map_location="cpu", weights_only=False)
    if CONFIG_KEY not in checkpoint:
        available = ", ".join(sorted(checkpoint.keys()))
        raise SystemExit(
            f"کلید «{CONFIG_KEY}» در چک‌پوینت نیست. کلیدهای موجود: {available}"
        )
    CONFIG_PATH.write_text(extract_config(checkpoint), encoding="utf-8")
    print(f"✔ پیکربندی استخراج و ذخیره شد: {CONFIG_PATH}")


if __name__ == "__main__":
    main()
