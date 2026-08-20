#!/usr/bin/env python3
"""Build a 20-minute optional breathing-pacer asset from a reviewed CC0 loop.

The source is Wikimedia Commons File:Gong55.ogg, described by its creator as a
10-second sound-loop base for 5-second inhale / 5-second exhale coherent
breathing. Stillow treats it only as a pacing aid, not a treatment claim.
"""

from __future__ import annotations

import hashlib
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
CATALOG_PATH = PROJECT_ROOT / "assets" / "content" / "audio_catalog.json"
SOURCE_PATH = PROJECT_ROOT / "tools" / "source_audio" / "coherent-breathing-gong.ogg"
OUTPUT_PATH = PROJECT_ROOT / "assets" / "audio" / "coherent-breathing-gong.m4a"
TARGET_SECONDS = 20 * 60
ITEM_ID = "breathing-coherent-gong"


def _run(*args: str) -> str:
    completed = subprocess.run(
        args,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return completed.stdout.strip()


def _duration(path: Path) -> float:
    return float(
        _run(
            "ffprobe",
            "-v",
            "error",
            "-show_entries",
            "format=duration",
            "-of",
            "default=noprint_wrappers=1:nokey=1",
            str(path),
        )
    )


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _build_audio() -> None:
    if not SOURCE_PATH.is_file():
        raise FileNotFoundError(
            f"Missing {SOURCE_PATH}; content-lab must preserve the reviewed CC0 source."
        )
    source_seconds = _duration(SOURCE_PATH)
    if not 8 <= source_seconds <= 12:
        raise ValueError(
            f"Expected the reviewed ~10s breathing loop, got {source_seconds:.2f}s"
        )

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    temp = OUTPUT_PATH.with_suffix(".tmp.m4a")
    subprocess.run(
        [
            "ffmpeg",
            "-hide_banner",
            "-loglevel",
            "error",
            "-y",
            "-stream_loop",
            "-1",
            "-i",
            str(SOURCE_PATH),
            "-t",
            str(TARGET_SECONDS),
            "-af",
            "afade=t=in:st=0:d=2,afade=t=out:st=1188:d=12",
            "-c:a",
            "aac",
            "-b:a",
            "48k",
            "-ar",
            "44100",
            "-movflags",
            "+faststart",
            str(temp),
        ],
        check=True,
    )
    built_seconds = _duration(temp)
    if not TARGET_SECONDS - 1 <= built_seconds <= TARGET_SECONDS + 1:
        temp.unlink(missing_ok=True)
        raise RuntimeError(f"Unexpected breathing-pacer duration: {built_seconds:.2f}s")
    temp.replace(OUTPUT_PATH)


def _catalog_item() -> dict[str, object]:
    return {
        "id": ITEM_ID,
        "enabled": True,
        "regions": ["CN", "INTL"],
        "provider": "wikimediaCommons",
        "playbackType": "assetAudio",
        "assetPath": "assets/audio/coherent-breathing-gong.m4a",
        "sha256": _sha256(OUTPUT_PATH),
        "adFree": True,
        "rightsStatus": "cc0",
        "playbackUrl": "https://upload.wikimedia.org/wikipedia/commons/2/2c/Gong55.ogg",
        "sourcePage": "https://commons.wikimedia.org/wiki/File:Gong55.ogg",
        "sourceTitle": "Gong55.ogg · 5-second inhale / 5-second exhale loop base",
        "creator": "stephan",
        "licenseName": "CC0 1.0 · 20-minute AAC breathing-pacer master",
        "licenseUrl": "https://creativecommons.org/publicdomain/zero/1.0/",
        "title": "慢慢呼吸 · 5 秒吸 / 5 秒呼",
        "subtitle": "低沉锣声提供约 20 分钟的缓慢节拍。保持自然呼吸；出现头晕、气短或其他不适时暂停播放。",
        "shortLabel": "呼吸节拍 · 约20分钟",
        "kind": "breathingPacer",
        "languageCode": "zxx",
        "tags": [
            "quiet_mind",
            "relax_body",
            "breathing",
            "minimal",
            "low_stimulus",
            "role_breathing_pacer"
        ],
        "durationSeconds": TARGET_SECONDS,
        "loop": False,
        "priority": 86
    }


def _update_catalog() -> None:
    with CATALOG_PATH.open("r", encoding="utf-8") as handle:
        root = json.load(handle)
    items = root.get("items")
    if not isinstance(items, list):
        raise ValueError("audio_catalog.json items must be a list")

    replacement = _catalog_item()
    for index, raw in enumerate(items):
        if isinstance(raw, dict) and raw.get("id") == ITEM_ID:
            items[index] = replacement
            break
    else:
        # Keep the breathing aid near other active support interventions and
        # ahead of comfort-only spoken material.
        insertion_index = min(4, len(items))
        items.insert(insertion_index, replacement)

    root["schemaVersion"] = max(int(root.get("schemaVersion", 1)), 7)
    root["updatedAt"] = datetime.now(timezone.utc).date().isoformat()
    with CATALOG_PATH.open("w", encoding="utf-8") as handle:
        json.dump(root, handle, ensure_ascii=False, indent=2)
        handle.write("\n")


def main() -> None:
    _build_audio()
    _update_catalog()
    print(
        f"{ITEM_ID}: {_duration(OUTPUT_PATH):.1f}s "
        f"sha256={_sha256(OUTPUT_PATH)}"
    )


if __name__ == "__main__":
    main()
