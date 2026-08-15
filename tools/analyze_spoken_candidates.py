#!/usr/bin/env python3
"""Acoustically screen research-only spoken candidates for low-arousal delivery.

This does not claim that a voice causes sleep. It measures a few proxies that are
useful for rejecting obviously animated/high-variance material before a human
full-listening review: pitch movement, median pitch, intensity movement and
voiced-frame continuity. The final product decision must still be made by ear
and by user feedback.
"""

from __future__ import annotations

import json
import math
import shutil
import subprocess
import tempfile
import urllib.request
from pathlib import Path
from typing import Any

import numpy as np
import parselmouth

PROJECT_ROOT = Path(__file__).resolve().parents[1]
SOURCE_PATH = PROJECT_ROOT / "tools" / "spoken_candidate_sources.json"
REPORT_PATH = PROJECT_ROOT / "docs" / "spoken_candidate_analysis.md"
BASELINE_PATH = PROJECT_ROOT / "assets" / "audio" / "spoken-mosquito-life-zh.m4a"
ANALYSIS_START_SECONDS = 45
ANALYSIS_SECONDS = 300


def _download(url: str, destination: Path) -> None:
    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": "StillowContentAudit/1.0 (https://github.com/newtv-ai/stillow)"
        },
    )
    with urllib.request.urlopen(request, timeout=180) as response, destination.open(
        "wb"
    ) as output:
        shutil.copyfileobj(response, output)


def _to_wav(source: Path, destination: Path, *, start: int = ANALYSIS_START_SECONDS) -> None:
    subprocess.run(
        [
            "ffmpeg",
            "-hide_banner",
            "-loglevel",
            "error",
            "-y",
            "-ss",
            str(start),
            "-t",
            str(ANALYSIS_SECONDS),
            "-i",
            str(source),
            "-vn",
            "-ac",
            "1",
            "-ar",
            "16000",
            "-c:a",
            "pcm_s16le",
            str(destination),
        ],
        check=True,
    )


def _percentile_span(values: np.ndarray, low: float = 10, high: float = 90) -> float:
    if values.size == 0:
        return float("nan")
    return float(np.percentile(values, high) - np.percentile(values, low))


def _analyze_wav(path: Path) -> dict[str, float]:
    sound = parselmouth.Sound(str(path))
    pitch = sound.to_pitch_ac(
        time_step=0.02,
        pitch_floor=65,
        pitch_ceiling=420,
        very_accurate=False,
    )
    f0 = pitch.selected_array["frequency"]
    voiced = f0[f0 > 0]
    if voiced.size < 50:
        raise ValueError(f"Too few voiced pitch frames in {path}")

    median_pitch = float(np.median(voiced))
    semitones = 12.0 * np.log2(voiced / median_pitch)
    pitch_span = _percentile_span(semitones)
    pitch_sd = float(np.std(semitones))

    intensity = sound.to_intensity(minimum_pitch=65, time_step=0.02)
    db = intensity.values.reshape(-1)
    db = db[np.isfinite(db)]
    if db.size == 0:
        raise ValueError(f"No intensity frames in {path}")
    active_threshold = float(np.percentile(db, 95) - 35.0)
    active_db = db[db >= active_threshold]
    intensity_span = _percentile_span(active_db)

    voiced_ratio = float(np.count_nonzero(f0 > 0) / max(1, f0.size))

    # Lower is calmer/flatter. This is a ranking heuristic, not a medical score.
    high_pitch_penalty = max(0.0, median_pitch - 220.0) / 25.0
    low_arousal_proxy = pitch_span + 0.45 * intensity_span + high_pitch_penalty

    return {
        "medianPitchHz": median_pitch,
        "pitchP10P90Semitones": pitch_span,
        "pitchSdSemitones": pitch_sd,
        "intensityP10P90Db": intensity_span,
        "voicedFrameRatio": voiced_ratio,
        "lowArousalProxy": low_arousal_proxy,
    }


def _fmt(value: float, digits: int = 1) -> str:
    if math.isnan(value):
        return "n/a"
    return f"{value:.{digits}f}"


def main() -> None:
    with SOURCE_PATH.open("r", encoding="utf-8") as handle:
        root: dict[str, Any] = json.load(handle)
    candidates = list(root.get("candidates") or [])

    results: list[dict[str, Any]] = []
    with tempfile.TemporaryDirectory(prefix="stillow_spoken_") as raw_temp:
        temp = Path(raw_temp)

        if BASELINE_PATH.is_file():
            baseline_wav = temp / "baseline.wav"
            _to_wav(BASELINE_PATH, baseline_wav, start=30)
            results.append(
                {
                    "id": "current-mosquito-baseline",
                    "title": "当前素材：蚊子怎样生活",
                    "languageCode": "zh",
                    "subject": "蚊子生活科普（当前正式素材）",
                    "sourcePage": "local bundled baseline",
                    "licenseName": "current catalog",
                    "qualitySignal": "baseline only",
                    "productionNote": "Used only to compare acoustic movement with new candidates.",
                    "metrics": _analyze_wav(baseline_wav),
                }
            )

        for candidate in candidates:
            item_id = str(candidate["id"])
            source = temp / f"{item_id}.source"
            wav = temp / f"{item_id}.wav"
            print(f"Downloading {item_id} ...", flush=True)
            _download(str(candidate["originalUrl"]), source)
            _to_wav(source, wav)
            metrics = _analyze_wav(wav)
            results.append({**candidate, "metrics": metrics})
            print(
                f"  proxy={metrics['lowArousalProxy']:.2f} "
                f"pitch={metrics['medianPitchHz']:.1f}Hz "
                f"span={metrics['pitchP10P90Semitones']:.2f}st",
                flush=True,
            )

    ranked = sorted(results, key=lambda row: row["metrics"]["lowArousalProxy"])
    baseline = next(
        (row for row in results if row["id"] == "current-mosquito-baseline"), None
    )
    baseline_score = (
        baseline["metrics"]["lowArousalProxy"] if baseline is not None else None
    )

    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# Low-arousal spoken-content acoustic screen",
        "",
        "Generated: 2026-08-15",
        "",
        "This is a **pre-screen, not a sleep-efficacy score**. Lower proxy values mean the "
        "sample had less pitch/intensity movement in the analyzed five-minute window. "
        "Semantic interest, pronunciation, artifacts, emotional tone and loop/listening fatigue "
        "still require a full human review and real user feedback.",
        "",
        "## Ranking",
        "",
        "| Rank | Candidate | Lang | Proxy ↓ | Median pitch | Pitch span P10–P90 | Intensity span P10–P90 | Voiced ratio |",
        "|---:|---|---|---:|---:|---:|---:|---:|",
    ]
    for index, row in enumerate(ranked, start=1):
        m = row["metrics"]
        lines.append(
            f"| {index} | {row['title']} | {row.get('languageCode', '')} | "
            f"{_fmt(m['lowArousalProxy'], 2)} | {_fmt(m['medianPitchHz'])} Hz | "
            f"{_fmt(m['pitchP10P90Semitones'], 2)} st | "
            f"{_fmt(m['intensityP10P90Db'], 2)} dB | "
            f"{_fmt(m['voicedFrameRatio'] * 100)}% |"
        )

    lines.extend(
        [
            "",
            "## Candidate notes",
            "",
        ]
    )
    for row in ranked:
        if row["id"] == "current-mosquito-baseline":
            continue
        m = row["metrics"]
        comparison = ""
        if baseline_score is not None:
            delta = m["lowArousalProxy"] - baseline_score
            comparison = (
                f" Acoustically this proxy is {abs(delta):.2f} points "
                f"{'flatter/calmer than' if delta < 0 else 'more variable than'} the current mosquito baseline."
            )
        lines.extend(
            [
                f"### {row['title']}",
                "",
                f"- Subject: {row.get('subject', '')}",
                f"- Source: {row.get('sourcePage', '')}",
                f"- License: {row.get('licenseName', '')} ({row.get('licenseUrl', '')})",
                f"- Quality signal: {row.get('qualitySignal', '')}",
                f"- Production note: {row.get('productionNote', '')}",
                f"- Acoustic note:{comparison or ' baseline comparison unavailable'}",
                "",
            ]
        )

    lines.extend(
        [
            "## Promotion rule",
            "",
            "A spoken candidate should not enter automatic bedtime recommendation just because "
            "it scores well here. It can enter the experimental study/drowsy library after a "
            "full-listening review confirms: no loud intro/outro, no sudden pitch jumps, no "
            "distressing content, no ads, stable technical playback, and verified commercial "
            "reuse rights. Automatic recommendation should require positive personal feedback.",
            "",
        ]
    )
    REPORT_PATH.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {REPORT_PATH}")


if __name__ == "__main__":
    main()
