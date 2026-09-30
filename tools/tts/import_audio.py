#!/usr/bin/env python3
"""ورود تعاملی صداهای تولیدشده با ابزار بیرونی به خط تولید صدا.

حالت خودکار (پیش‌فرض): نام فایل مبدأ یا برابر کلید خط است (مثل
greet_01.mp3) یا عدد ترتیبی (مثل 1.mp3) که به‌ترتیب مدخل‌های
lines.json نگاشت می‌شود.

حالت تعاملی (فلگ -i): هر فایل مبدأ پخش می‌شود و کاربر با شماره یا
نام کلید، خطِ متناظر را انتخاب می‌کند؛ نقشه‌ی انتساب‌ها در
import_map.json ذخیره می‌شود تا کار قطع‌شده قابل ادامه باشد.

خروجی: فایل‌های WAV استاندارد بازی (مونو، ۲۴ کیلوهرتز، بلندی
یکنواخت) در پوشه‌ی صداهای بازی و شناسنامه‌ی voice_manifest.json.

اجرا:
    python3 import_audio.py <پوشه‌ی مبدأ> [نام ابزار] [-i]
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
from datetime import datetime, timezone
from pathlib import Path

# ── مسیرها ──────────────────────────────────────────────

MODULE_DIR = Path(__file__).resolve().parent
LINES_PATH = MODULE_DIR / "lines.json"
MANIFEST_PATH = MODULE_DIR / "voice_manifest.json"
MAP_PATH = MODULE_DIR / "import_map.json"
VOICE_DIR = MODULE_DIR.parents[1] / "game" / "assets" / "audio" / "fa"

# ── ثابت‌ها ─────────────────────────────────────────────

SOURCE_EXTENSIONS = (".mp3", ".wav", ".ogg", ".m4a", ".aac", ".flac")
LOUDNESS_FILTER = "loudnorm=I=-16:TP=-1.5:LRA=11"
SAMPLE_RATE_HZ = 24000
CHANNELS = 1
MENU_TEXT_WIDTH = 48
INPUT_PROMPT = "کلید (شماره/نام | r=پخش دوباره | l=لیست | s=رد | q=ذخیره و خروج): "
PLAYER_CANDIDATES: tuple[tuple[str, tuple[str, ...]], ...] = (
    ("mpv", ("--really-quiet", "--no-video")),
    ("termux-media-player", ()),
)


def load_lines() -> dict[str, str]:
    """خواندن خطوط گفتار از فایل JSON."""
    return json.loads(LINES_PATH.read_text(encoding="utf-8"))


def pick_player() -> tuple[str, tuple[str, ...]]:
    """انتخاب نخستین پخش‌کننده‌ی صوتی موجود روی سیستم."""
    for name, extra_args in PLAYER_CANDIDATES:
        if shutil.which(name) is not None:
            return name, extra_args
    raise SystemExit("پخش‌کننده‌ای پیدا نشد؛ mpv را نصب کنید: pkg install mpv")


def play_file(player: tuple[str, tuple[str, ...]], path: Path) -> None:
    """پخش یک فایل صوتی تا پایان (در mpv با q قطع می‌شود)."""
    name, extra_args = player
    if name == "termux-media-player":
        command = [name, "play", str(path)]
    else:
        command = [name, *extra_args, str(path)]
    subprocess.run(command, check=False)


def convert_to_standard(source: Path, destination: Path) -> None:
    """تبدیل یک فایل مبدأ به WAV استاندارد با بلندی یکنواخت."""
    subprocess.run(
        [
            "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
            "-i", str(source),
            "-af", LOUDNESS_FILTER,
            "-ar", str(SAMPLE_RATE_HZ),
            "-ac", str(CHANNELS),
            "-c:a", "pcm_s16le",
            str(destination),
        ],
        check=True,
    )


def resolve_answer(answer: str, keys: list[str]) -> str | None:
    """تبدیل ورودی کاربر به کلید خط؛ با شماره یا نام مستقیم."""
    if answer in keys:
        return answer
    if answer.isdigit():
        index = int(answer)
        if 1 <= index <= len(keys):
            return keys[index - 1]
    return None


def assign_to_key(mapping: dict[str, str], source_name: str, key: str) -> None:
    """انتساب یک فایل مبدأ به کلید با هشدار در صورت تداخل."""
    previous = next(
        (n for n, assigned in mapping.items() if assigned == key), None
    )
    if previous is not None and previous != source_name:
        print(f"هشدار: «{key}» از «{previous}» به «{source_name}» جابه‌جا شد.")
        del mapping[previous]
    mapping[source_name] = key


def read_map(keys: list[str], source_dir: Path) -> dict[str, str]:
    """خواندن نقشه‌ی انتساب ذخیره‌شده و حذف مدخل‌های نامعتبر."""
    if not MAP_PATH.exists():
        return {}
    saved: dict[str, str] = json.loads(MAP_PATH.read_text(encoding="utf-8"))
    return {
        name: key
        for name, key in saved.items()
        if key in keys and (source_dir / name).exists()
    }


def write_map(mapping: dict[str, str]) -> None:
    """ذخیره‌ی نقشه‌ی انتساب برای ادامه‌ی کار در اجرای بعدی."""
    MAP_PATH.write_text(
        json.dumps(mapping, ensure_ascii=False, indent=4) + "\n",
        encoding="utf-8",
    )


def print_key_menu(keys: list[str], lines: dict[str, str]) -> None:
    """چاپ فهرست شماره‌دار کلیدها با متن کوتاه‌شده."""
    print("کلیدها (شماره = ترتیب مدخل‌های lines.json):")
    for index, key in enumerate(keys, start=1):
        text = lines[key]
        if len(text) > MENU_TEXT_WIDTH:
            text = text[:MENU_TEXT_WIDTH] + "…"
        print(f"  {index:>2}. {key:<20} {text}")


def interactive_assign(
    source_files: list[Path],
    keys: list[str],
    lines: dict[str, str],
    player: tuple[str, tuple[str, ...]],
    mapping: dict[str, str],
) -> dict[str, str]:
    """حلقه‌ی حالت تعاملی: پخش هر فایل و دریافت کلید متناظر."""
    print_key_menu(keys, lines)
    pending = [f for f in source_files if f.name not in mapping]
    total = len(pending)
    for position, source in enumerate(pending, start=1):
        print(f"\nفایل {position} از {total}: {source.name}")
        play_file(player, source)
        while True:
            answer = input(INPUT_PROMPT).strip()
            if answer == "":
                print("ورودی خالی است.")
            elif answer == "r":
                play_file(player, source)
            elif answer == "l":
                print_key_menu(keys, lines)
            elif answer == "s":
                print("رد شد.")
                break
            elif answer == "q":
                return mapping
            else:
                key = resolve_answer(answer, keys)
                if key is None:
                    print(f"ورودی نامعتبر؛ شماره‌ی ۱ تا {len(keys)} یا نام کلید.")
                    continue
                assign_to_key(mapping, source.name, key)
                write_map(mapping)
                print(f"✓ {key} <- {source.name}")
                break
    return mapping


def run_import(
    mapping: dict[str, str],
    keys: list[str],
    source_dir: Path,
    source_tool: str,
    mode: str,
) -> None:
    """تبدیل همه‌ی انتساب‌ها به WAV استاندارد و نوشتن شناسنامه."""
    VOICE_DIR.mkdir(parents=True, exist_ok=True)
    by_key = {key: name for name, key in mapping.items()}
    imports: dict[str, str] = {}
    for key in keys:
        source_name = by_key.get(key)
        if source_name is None:
            continue
        destination = VOICE_DIR / f"{key}.wav"
        convert_to_standard(source_dir / source_name, destination)
        imports[key] = source_name
        print(f"[{key}] <- {source_name}")

    missing = [key for key in keys if key not in imports]
    orphans = sorted(p.name for p in VOICE_DIR.glob("*.wav") if p.stem not in keys)
    if missing:
        print("خطوط بدون صدا: " + ", ".join(missing))
    if orphans:
        print("فایل‌های بی‌کلید در مقصد: " + ", ".join(orphans))

    MANIFEST_PATH.write_text(
        json.dumps(
            {
                "imported_at": datetime.now(timezone.utc).isoformat(),
                "source_tool": source_tool,
                "mode": mode,
                "standard": f"wav / {SAMPLE_RATE_HZ}Hz / mono / {LOUDNESS_FILTER}",
                "files": imports,
            },
            ensure_ascii=False,
            indent=4,
        ) + "\n",
        encoding="utf-8",
    )
    print(f"OK {len(imports)} خط وارد شد؛ شناسنامه: {MANIFEST_PATH}")


def main() -> None:
    """تجزیه‌ی آرگومان‌ها، انتخاب حالت و اجرای ورود صداها."""
    parser = argparse.ArgumentParser(
        description="ورود صدای بیرونی به خط تولید صدا",
    )
    parser.add_argument("source_dir", help="پوشه‌ی فایل‌های صوتی مبدأ")
    parser.add_argument(
        "source_tool", nargs="?", default="unknown", help="نام ابزار مبدأ",
    )
    parser.add_argument(
        "-i", "--interactive", action="store_true",
        help="پخش هر فایل و انتخاب دستی کلید متناظر",
    )
    arguments = parser.parse_args()

    source_dir = Path(arguments.source_dir).expanduser()
    if not source_dir.is_dir():
        raise SystemExit(f"پوشه‌ی مبدأ پیدا نشد: {source_dir}")

    lines = load_lines()
    keys = list(lines.keys())
    source_files = sorted(
        p for p in source_dir.iterdir() if p.suffix.lower() in SOURCE_EXTENSIONS
    )
    if not source_files:
        raise SystemExit(f"فایل صوتی در مبدأ نیست: {source_dir}")

    if arguments.interactive:
        player = pick_player()
        mapping = read_map(keys, source_dir)
        if mapping:
            print(f"ادامه از نقشه‌ی ذخیره‌شده با {len(mapping)} انتساب.")
        mapping = interactive_assign(source_files, keys, lines, player, mapping)
        mode = "interactive"
    else:
        mapping = {}
        for source in source_files:
            key = resolve_answer(source.stem, keys)
            if key is None:
                print(f"? ناشناخته: {source.name}")
                continue
            assign_to_key(mapping, source.name, key)
        mode = "auto"

    if not mapping:
        raise SystemExit("هیچ انتسابی انجام نشد.")
    run_import(mapping, keys, source_dir, arguments.source_tool, mode)


if __name__ == "__main__":
    main()
