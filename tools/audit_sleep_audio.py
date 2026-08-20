#!/usr/bin/env python3
"""Audit Stillow sleep-audio metadata, roles, and bundled-file integrity.

This is a product-content gate, not a clinical efficacy test. It enforces the
repository's evidence-role boundaries so generic readings and masking sounds do
not silently drift into the core sleep-support recommendation pool.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from collections import Counter
from pathlib import Path
from typing import Any

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CATALOG = PROJECT_ROOT / "assets" / "content" / "audio_catalog.json"
DEFAULT_STUDY = PROJECT_ROOT / "assets" / "content" / "study_drowsy_catalog.json"
DEFAULT_CANDIDATES = PROJECT_ROOT / "assets" / "content" / "audio_candidates.json"

ROLE_TAGS = {
    "role_guided_relaxation",
    "role_trial_aligned_music",
    "role_supporting_music",
    "role_breathing_pacer",
    "role_masking_only",
    "role_comfort_only",
}

CORE_GOAL_TAGS = {
    "quiet_mind",
    "relax_body",
    "not_sleepy",
    "sleep_pressure",
    "night_awake",
}

REUSABLE_RIGHTS = {
    "publicDomain",
    "cc0",
    "ccBy",
    "ccBySa",
    "usGovernmentPublicDomain",
}


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError(f"{path}: root must be an object")
    return value


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def audit_catalog(root: dict[str, Any], project_root: Path) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    items = root.get("items")
    if not isinstance(items, list) or not items:
        return ["audio_catalog.json has no items"], warnings

    if root.get("sciencePolicyVersion") != 1:
        errors.append("sciencePolicyVersion must be 1")

    seen_ids: set[str] = set()
    for raw in items:
        if not isinstance(raw, dict):
            errors.append("catalog item is not an object")
            continue

        item_id = str(raw.get("id") or "<missing-id>")
        if item_id in seen_ids:
            errors.append(f"{item_id}: duplicate id")
        seen_ids.add(item_id)

        tags = set(raw.get("tags") or [])
        roles = tags & ROLE_TAGS
        if len(roles) != 1:
            errors.append(
                f"{item_id}: expected exactly one evidence role, got {sorted(roles)}"
            )
            continue
        role = next(iter(roles))
        kind = raw.get("kind")
        duration = raw.get("durationSeconds")
        duration = duration if isinstance(duration, int) else 0

        if "study_drowsy" in tags:
            errors.append(
                f"{item_id}: study_drowsy content belongs in study_drowsy_catalog.json"
            )

        if role == "role_trial_aligned_music":
            if kind != "music":
                errors.append(f"{item_id}: trial-aligned role requires kind=music")
            for required in ("instrumental", "low_stimulus"):
                if required not in tags:
                    errors.append(
                        f"{item_id}: trial-aligned music missing tag {required}"
                    )
            if duration < 10 * 60:
                if "needs_long_form_master" not in tags:
                    errors.append(
                        f"{item_id}: short trial-aligned source must be marked "
                        "needs_long_form_master"
                    )
                warnings.append(
                    f"{item_id}: source is {duration}s; build/listen-review a "
                    "20–30 minute long-form master before treating it as a mature "
                    "sleep intervention"
                )

        elif role == "role_guided_relaxation":
            if kind != "guidedVoice":
                errors.append(f"{item_id}: guided relaxation requires guidedVoice")
            if "guided" not in tags or "low_stimulus" not in tags:
                errors.append(
                    f"{item_id}: guided relaxation must be tagged guided + low_stimulus"
                )
            if duration < 10 * 60:
                warnings.append(
                    f"{item_id}: guided relaxation is under 10 minutes; confirm that "
                    "the shorter duration is intentional"
                )

        elif role == "role_breathing_pacer":
            if kind != "breathingPacer":
                errors.append(f"{item_id}: breathing pacer requires kind=breathingPacer")
            for required in ("breathing", "low_stimulus"):
                if required not in tags:
                    errors.append(f"{item_id}: breathing pacer missing tag {required}")
            forbidden = tags & {"mask_noise", "not_sleepy", "sleep_pressure", "night_awake"}
            if forbidden:
                errors.append(
                    f"{item_id}: breathing pacer has unrelated goal tags {sorted(forbidden)}"
                )
            if duration < 10 * 60:
                errors.append(f"{item_id}: breathing pacer must be at least 10 minutes")

        elif role == "role_supporting_music":
            if kind != "music":
                errors.append(f"{item_id}: supporting music requires kind=music")
            if "instrumental" not in tags:
                errors.append(f"{item_id}: supporting music must be instrumental")
            if duration < 60 and "short_loop_risk" not in tags:
                errors.append(
                    f"{item_id}: music under 60s must be tagged short_loop_risk"
                )
            if "needs_long_form_master" in tags:
                warnings.append(
                    f"{item_id}: supporting music still needs a long-form master"
                )

        elif role == "role_masking_only":
            if "mask_noise" not in tags:
                errors.append(f"{item_id}: masking-only audio must include mask_noise")
            forbidden = tags & {"quiet_mind", "relax_body", "not_sleepy", "sleep_pressure"}
            if forbidden:
                errors.append(
                    f"{item_id}: masking-only audio has non-masking goal tags "
                    f"{sorted(forbidden)}"
                )
            if duration < 120:
                warnings.append(
                    f"{item_id}: masking source is only {duration}s; listen for audible "
                    "loop repetition before release"
                )

        elif role == "role_comfort_only":
            forbidden = tags & CORE_GOAL_TAGS
            if forbidden:
                errors.append(
                    f"{item_id}: comfort-only content must not claim core goal tags "
                    f"{sorted(forbidden)}"
                )

        if raw.get("enabled") is True and raw.get("playbackType") == "assetAudio":
            asset_path = raw.get("assetPath")
            expected_sha = raw.get("sha256")
            if not isinstance(asset_path, str) or not asset_path:
                errors.append(f"{item_id}: bundled audio missing assetPath")
            else:
                file_path = project_root / asset_path
                if not file_path.is_file():
                    errors.append(f"{item_id}: missing bundled file {asset_path}")
                elif not isinstance(expected_sha, str) or len(expected_sha) != 64:
                    errors.append(f"{item_id}: missing/invalid sha256 metadata")
                else:
                    actual_sha = sha256_file(file_path)
                    if actual_sha != expected_sha.lower():
                        errors.append(
                            f"{item_id}: sha256 mismatch: metadata={expected_sha} "
                            f"actual={actual_sha}"
                        )

    return errors, warnings


def audit_study_catalog(root: dict[str, Any]) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    items = root.get("items")
    if not isinstance(items, list) or not items:
        return ["study_drowsy_catalog.json has no items"], warnings

    seen_ids: set[str] = set()
    for raw in items:
        if not isinstance(raw, dict):
            errors.append("study catalog item is not an object")
            continue

        item_id = str(raw.get("id") or "<missing-id>")
        if item_id in seen_ids:
            errors.append(f"{item_id}: duplicate study id")
        seen_ids.add(item_id)

        tags = set(raw.get("tags") or [])
        roles = tags & ROLE_TAGS
        if roles != {"role_comfort_only"}:
            errors.append(
                f"{item_id}: study content must be role_comfort_only, got {sorted(roles)}"
            )
        for required in ("study_drowsy", "spoken_content", "low_stimulus"):
            if required not in tags:
                errors.append(f"{item_id}: missing study tag {required}")
        forbidden = tags & CORE_GOAL_TAGS
        if forbidden:
            errors.append(
                f"{item_id}: personalized study content must not claim core goals "
                f"{sorted(forbidden)}"
            )

        if raw.get("kind") not in {"lecture", "narrative"}:
            errors.append(f"{item_id}: study content must be lecture or narrative")
        duration = raw.get("durationSeconds")
        if not isinstance(duration, int) or duration < 15 * 60:
            errors.append(f"{item_id}: study content must be at least 15 minutes")
        if raw.get("playbackType") != "directAudio":
            errors.append(f"{item_id}: study content must use directAudio")
        if raw.get("adFree") is not True:
            errors.append(f"{item_id}: study content must be ad-free")
        if raw.get("rightsStatus") not in REUSABLE_RIGHTS:
            errors.append(f"{item_id}: study content lacks reusable commercial rights")

        for field in ("playbackUrl", "sourcePage", "licenseUrl"):
            value = raw.get(field)
            if not isinstance(value, str) or not value.startswith("https://"):
                errors.append(f"{item_id}: {field} must be HTTPS")

        if "low_pitch_screened" not in tags:
            warnings.append(
                f"{item_id}: not marked low_pitch_screened; confirm voice pitch/dynamics"
            )

    return errors, warnings


def audit_candidates(root: dict[str, Any]) -> tuple[list[str], list[str], Counter[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    counts: Counter[str] = Counter()
    items = root.get("items")
    if not isinstance(items, list):
        return ["audio_candidates.json items must be a list"], warnings, counts

    criteria = root.get("criteria")
    if not isinstance(criteria, dict):
        errors.append("audio_candidates.json criteria must be an object")
    else:
        if criteria.get("completeListeningReviewRequired") is not True:
            errors.append("candidate queue must require a complete listening review")
        if criteria.get("automaticPromotionToAudioCatalog") is not False:
            errors.append("candidate queue must disable automatic catalog promotion")

    for raw in items:
        if not isinstance(raw, dict):
            errors.append("candidate item is not an object")
            continue
        item_id = str(raw.get("id") or "<missing-id>")
        raw_kind = str(raw.get("kind") or "unknown")
        counts[raw_kind] += 1

        review_status = raw.get("reviewStatus")
        if review_status not in (None, "unreviewed"):
            warnings.append(
                f"{item_id}: reviewStatus={review_status!r}; promote reviewed material "
                "into an approved catalog instead of leaving it in the candidate queue"
            )

        if raw.get("enabled") is True:
            errors.append(f"{item_id}: candidate queue must not mark items approved")

    return errors, warnings, counts


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--catalog", type=Path, default=DEFAULT_CATALOG)
    parser.add_argument("--study", type=Path, default=DEFAULT_STUDY)
    parser.add_argument("--candidates", type=Path, default=DEFAULT_CANDIDATES)
    parser.add_argument(
        "--skip-files",
        action="store_true",
        help="Audit metadata only. Useful when bundled audio files are not present.",
    )
    args = parser.parse_args()

    catalog_root = load_json(args.catalog)
    project_root = PROJECT_ROOT
    if args.skip_files:
        temp_root = json.loads(json.dumps(catalog_root))
        for item in temp_root.get("items", []):
            if isinstance(item, dict):
                item["playbackType"] = "metadataOnly"
        catalog_root_for_audit = temp_root
    else:
        catalog_root_for_audit = catalog_root

    errors, warnings = audit_catalog(catalog_root_for_audit, project_root)

    study_count = 0
    if args.study.exists():
        study_root = load_json(args.study)
        study_items = study_root.get("items")
        study_count = len(study_items) if isinstance(study_items, list) else 0
        study_errors, study_warnings = audit_study_catalog(study_root)
        errors.extend(study_errors)
        warnings.extend(study_warnings)

    candidate_counts: Counter[str] = Counter()
    if args.candidates.exists():
        candidate_root = load_json(args.candidates)
        candidate_errors, candidate_warnings, candidate_counts = audit_candidates(
            candidate_root
        )
        errors.extend(candidate_errors)
        warnings.extend(candidate_warnings)

    role_counts = Counter()
    for item in catalog_root.get("items", []):
        if not isinstance(item, dict):
            continue
        role_counts.update(set(item.get("tags") or []) & ROLE_TAGS)

    print("Approved catalog roles:")
    for role in sorted(ROLE_TAGS):
        print(f"  {role}: {role_counts[role]}")

    if study_count:
        print(f"Personalized study/drowsy catalog: {study_count}")

    if candidate_counts:
        print("Candidate review queue:")
        for kind, count in sorted(candidate_counts.items()):
            print(f"  {kind}: {count}")

    for warning in warnings:
        print(f"WARNING: {warning}", file=sys.stderr)
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)

    if errors:
        print(f"Audit failed: {len(errors)} error(s), {len(warnings)} warning(s)")
        return 1

    print(f"Audit passed: {len(warnings)} warning(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
