#!/usr/bin/env python3
"""Build long-form crossfaded sleep masters from reviewed short CC0 sources.

The short source files live under tools/source_audio/ and are not bundled in the
app. This script creates 25-minute masters at the existing bundled asset paths
and updates duration, SHA-256 and science-policy metadata in the catalog.
"""

from __future__ import annotations

import hashlib
import json
import math
import subprocess
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
CATALOG_PATH = PROJECT_ROOT / "assets" / "content" / "audio_catalog.json"
TARGET_SECONDS = 25 * 60
CROSSFADE_SECONDS = 8.0

MASTERS = {
    "music-first-light": {
        "source": PROJECT_ROOT / "tools" / "source_audio" / "music-first-light-source.m4a",
        "output": PROJECT_ROOT / "assets" / "audio" / "music-first-light.m4a",
        "subtitle": "柔和钢琴与安静铺底，整理为约 25 分钟连续版本，段落之间使用柔和交叉淡化。",
        "shortLabel": "轻音乐 · 约25分钟",
    },
    "music-contemplation": {
        "source": PROJECT_ROOT / "tools" / "source_audio" / "music-contemplation-source.m4a",
        "output": PROJECT_ROOT / "assets" / "audio" / "music-contemplation.m4a",
        "subtitle": "缓慢铺开的环境音乐，整理为约 25 分钟连续版本，尽量减少短循环的注意力提示。",
        "shortLabel": "环境音乐 · 约25分钟",
    },
}


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
    value = _run(
        "ffprobe",
        "-v",
        "error",
        "-show_entries",
        "format=duration",
        "-of",
        "default=noprint_wrappers=1:nokey=1",
        str(path),
    )
    return float(value)


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _build_master(source: Path, output: Path) -> None:
    source_seconds = _duration(source)
    if not 20 <= source_seconds <= 5 * 60:
        raise ValueError(
            f"Expected a reviewed short source (20-300s), got {source_seconds:.1f}s: {source}"
        )
    if source_seconds <= CROSSFADE_SECONDS + 5:
        raise ValueError(f"Source too short for crossfade: {source}")

    effective = source_seconds - CROSSFADE_SECONDS
    copies = max(2, math.ceil((TARGET_SECONDS - CROSSFADE_SECONDS) / effective))
    split_labels = "".join(f"[s{i}]" for i in range(copies))
    filters = [f"[0:a]asplit={copies}{split_labels}"]
    for index in range(copies):
        filters.append(
            f"[s{index}]atrim=0:{source_seconds:.4f},asetpts=PTS-STARTPTS[a{index}]"
        )

    previous = "a0"
    for index in range(1, copies):
        out = f"x{index}"
        filters.append(
            f"[{previous}][a{index}]acrossfade=d={CROSSFADE_SECONDS}:c1=tri:c2=tri[{out}]"
        )
        previous = out

    fade_out_start = TARGET_SECONDS - 12
    filters.append(
        f"[{previous}]atrim=0:{TARGET_SECONDS},"
        "asetpts=PTS-STARTPTS,"
        "afade=t=in:st=0:d=3,"
        f"afade=t=out:st={fade_out_start}:d=12[out]"
    )

    output.parent.mkdir(parents=True, exist_ok=True)
    temp = output.with_suffix(".master.tmp.m4a")
    subprocess.run(
        [
            "ffmpeg",
            "-hide_banner",
            "-loglevel",
            "error",
            "-y",
            "-i",
            str(source),
            "-filter_complex",
            ";".join(filters),
            "-map",
            "[out]",
            "-c:a",
            "aac",
            "-b:a",
            "64k",
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
        raise RuntimeError(
            f"Unexpected master duration {built_seconds:.2f}s for {source.name}"
        )
    temp.replace(output)


def main() -> None:
    with CATALOG_PATH.open("r", encoding="utf-8") as handle:
        catalog = json.load(handle)

    by_id = {item["id"]: item for item in catalog.get("items", [])}
    for item_id, config in MASTERS.items():
        source = config["source"]
        output = config["output"]
        if not source.is_file():
            raise FileNotFoundError(
                f"Missing preserved short source {source}. See content-lab workflow."
            )
        _build_master(source, output)

        item = by_id[item_id]
        tags = [tag for tag in item.get("tags", []) if tag != "needs_long_form_master"]
        if "long_form_master" not in tags:
            tags.append("long_form_master")
        item["tags"] = tags
        item["durationSeconds"] = TARGET_SECONDS
        item["loop"] = False
        item["sha256"] = _sha256(output)
        item["subtitle"] = config["subtitle"]
        item["shortLabel"] = config["shortLabel"]
        license_name = str(item.get("licenseName") or "")
        if "25-minute crossfade master" not in license_name:
            item["licenseName"] = f"{license_name} · 25-minute crossfade master"

    catalog["schemaVersion"] = max(int(catalog.get("schemaVersion", 1)), 6)
    catalog["updatedAt"] = "2026-08-15"
    with CATALOG_PATH.open("w", encoding="utf-8") as handle:
        json.dump(catalog, handle, ensure_ascii=False, indent=2)
        handle.write("\n")

    for item_id, config in MASTERS.items():
        output = config["output"]
        print(f"{item_id}: {_duration(output):.1f}s sha256={_sha256(output)}")


if __name__ == "__main__":
    main()
