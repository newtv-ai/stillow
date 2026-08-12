#!/usr/bin/env python3
"""Build a review queue of sleep-audio links from public, reusable sources.

The generated file is deliberately separate from audio_catalog.json.  Nothing
from this candidate queue is enabled in Stillow until a person has listened to
the complete recording and checked its rights metadata again.

Only the Python standard library is required.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import datetime as dt
import hashlib
import html
import json
import math
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import Counter
from pathlib import Path
from typing import Any, Iterable


SCRIPT_VERSION = "1.0.0"
PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = PROJECT_ROOT / "assets" / "content" / "audio_candidates.json"

WIKIMEDIA_API = "https://commons.wikimedia.org/w/api.php"
WIKIMEDIA_CATEGORY = "Category:Spoken Chinese Wikipedia"
OGA_COLLECTION_URL = "https://opengameart.org/content/cc0-calm-relaxing-music"
INTERNET_ARCHIVE_SEARCH = "https://archive.org/advancedsearch.php"
INTERNET_ARCHIVE_METADATA = "https://archive.org/metadata/"

USER_AGENT = (
    "StilLowAudioCandidateBuilder/1.0 "
    "(+https://github.com/newtv-ai/stillow; public-metadata indexing)"
)

ACCEPTED_LICENSE_LABELS = (
    "CC0",
    "Public Domain",
    "CC BY",
    "CC BY-SA",
)

# These are rejection terms, not a classifier.  They only remove material that
# is conspicuously stimulating or distressing before the listening review.
HIGH_AROUSAL_TERMS = (
    "battle",
    "combat",
    "boss fight",
    "gunfire",
    "gun shot",
    "horror",
    "scary",
    "scream",
    "terror",
    "chase",
    "explosion",
    "intense",
    "energetic",
    "heavy metal",
    "drum and bass",
    "战争",
    "战役",
    "枪击",
    "爆炸",
    "屠杀",
    "谋杀",
    "恐怖袭击",
    "空难",
)

SPOKEN_EXCLUDE_TERMS = HIGH_AROUSAL_TERMS + (
    "half-life",
    "harry potter",
    "wii sports",
    "fuck",
    "profanity",
    "hitler",
    "göring",
    "hurricane",
    "tropical storm",
    "criminal procedure",
    "lgbt",
    "n95口罩",
    "半衰期",
    "哈利·波特",
    "哈利波特",
    "追風箏",
    "追风筝",
    "光復香港",
    "普京",
    "習仲勳",
    "习近平",
    "希特勒",
    "戈林",
    "死亡",
    "刑事诉讼",
    "刑事訴訟",
    "撒钱案",
    "撒錢案",
    "灭绝",
    "滅絕",
    "救援队",
    "救援隊",
    "脱衣",
    "脫衣",
    "膀胱",
    "注射",
    "综合征",
    "綜合徵",
    "奥司他韦",
    "奧司他韋",
    "尼古丁",
    "智障",
    "禁忌詞",
    "禁忌词",
    "傻屌",
    "规则怪谈",
    "規則怪談",
    "热带风暴",
    "熱帶風暴",
    "热带低气压",
    "熱帶低氣壓",
    "飓风",
    "颶風",
    "金融风波",
    "金融風波",
    "土庫曼斯坦關係",
    "春情",
    "dialact",
    "csi效應",
    "csi效应",
    "c開頭的那個詞",
    "豪斯的頭",
    "豪斯的头",
    "尝粪",
    "嘗糞",
    "十字勋章",
    "十字勳章",
    "伤痕",
    "傷痕",
    "难以忽视的真相",
    "難以忽視的真相",
    "好警察壞狗狗",
    "好警察坏狗狗",
    "纯洁的爱情",
    "純潔的愛情",
    "0号元素",
    "0號元素",
    "佛教如來宗",
)

MUSIC_EXCLUDE_TERMS = HIGH_AROUSAL_TERMS + (
    "siren",
    "funky",
    "hip hop",
    "escape",
    "pandemic",
    "rejoicing",
    "king's feast",
    "fusion jazz",
    "get ready",
    "mandatory overtime",
    "speedier",
    "intense bass",
    "cute bass",
    "tribal",
    "techno",
    "circus",
    "harpsichord flurry",
    "strong",
    "upbeat",
)

CALM_TERMS = (
    "ambient",
    "ambience",
    "background",
    "calm",
    "chill",
    "contemplat",
    "dream",
    "gentle",
    "lo-fi",
    "lofi",
    "lullaby",
    "meditat",
    "minimal",
    "night",
    "peaceful",
    "piano",
    "quiet",
    "relax",
    "serene",
    "sleep",
    "slow",
    "soft",
    "soothing",
)

STRONG_CALM_TERMS = (
    "ambient",
    "ambience",
    "calm",
    "chill",
    "contemplat",
    "dream",
    "gentle",
    "lo-fi",
    "lofi",
    "lullaby",
    "meditat",
    "minimal",
    "peaceful",
    "quiet",
    "relax",
    "serene",
    "sleep",
    "slow",
    "soft",
    "soothing",
)

ARCHIVE_NATURE_TERMS = (
    "rain",
    "rainfall",
    "ocean",
    "sea waves",
    "waves",
    "forest",
    "birds",
    "birdsong",
    "creek",
    "stream",
    "river",
    "water",
    "wind",
    "brown noise",
    "pink noise",
    "nature sounds",
    "field recording",
    "fan sound",
)

ARCHIVE_EXCLUDE_TERMS = MUSIC_EXCLUDE_TERMS + (
    "binaural",
    "delta wave",
    "healing frequency",
    "solfeggio",
    "podcast",
    "radio show",
    "interview",
    "audiobook",
    "librivox",
    "sermon",
    "speech",
    "spoken word",
    "clinical",
    "haunted",
    "glitch",
    "video game",
    "soundtrack",
    "simpsons",
    "episode",
    "who shot",
    "pokémon",
    "pokemon",
    "remix",
    "live at",
    "concert",
    "cover song",
    "steam flow",
    "with trains",
    "thunderstorm",
    "sea storm",
    "healing",
    "mantra",
    "sutra",
    "dharani",
    "buddha",
    "vajra",
    "tantra",
    "chanting",
    "osho",
    "vipassana",
    "gibberish",
    "meditation talks",
    "guided meditation",
    "hypnosis",
    "self confidence",
    "podfic",
    "teen wolf",
    "chapter",
    "rebirth",
    "wall rack",
    "sleep column",
    "trombone works",
    "drunk",
    "harassing",
    "nightmare",
    "slick bangs",
    "tunnel bones",
    "stupider",
    "sample library",
    "hits, loops",
    "system audio",
    "groks science show",
    "sleep diet",
)

ARCHIVE_TITLE_CALM_TERMS = (
    "ambient",
    "brown noise",
    "calm",
    "gentle",
    "meditation",
    "nature sounds",
    "ocean sounds",
    "pink noise",
    "quiet",
    "rain sounds",
    "relax",
    "sleep",
    "soft",
    "soothing",
)


class SourceError(RuntimeError):
    """Raised when a public source cannot be read or parsed."""


def _http_get(url: str, *, timeout: int = 20, attempts: int = 2) -> bytes:
    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": USER_AGENT,
            "Accept": "application/json,text/html,application/xhtml+xml,*/*;q=0.8",
        },
    )
    last_error: Exception | None = None
    for attempt in range(attempts):
        try:
            with urllib.request.urlopen(request, timeout=timeout) as response:
                return response.read()
        except (urllib.error.URLError, TimeoutError, OSError) as error:
            last_error = error
            if attempt + 1 < attempts:
                time.sleep(0.6 * (2**attempt))
    raise SourceError(f"Unable to fetch {url}: {last_error}")


def _get_json(url: str) -> dict[str, Any]:
    try:
        return json.loads(_http_get(url).decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise SourceError(f"Invalid JSON from {url}: {error}") from error


def _get_text(url: str) -> str:
    return _http_get(url).decode("utf-8", errors="replace")


def _strip_html(value: str | None) -> str:
    if not value:
        return ""
    without_tags = re.sub(r"<[^>]+>", " ", html.unescape(value))
    return re.sub(r"\s+", " ", without_tags).strip()


def _clean_media_url(url: str) -> str:
    parts = urllib.parse.urlsplit(html.unescape(url))
    return urllib.parse.urlunsplit((parts.scheme, parts.netloc, parts.path, "", ""))


def _stable_id(provider: str, source_page: str) -> str:
    digest = hashlib.sha1(source_page.encode("utf-8"), usedforsecurity=False).hexdigest()[:12]
    return f"{provider}-{digest}"


def _contains_term(text: str, terms: Iterable[str]) -> bool:
    lowered = text.casefold()
    return any(term.casefold() in lowered for term in terms)


def _reject_spoken_title(title: str) -> bool:
    compact = re.sub(r"[\s_-]+", " ", title).strip().casefold()
    if _contains_term(compact, SPOKEN_EXCLUDE_TERMS):
        return True
    if re.fullmatch(r"(?:part|chapter|section|paragraph|部分|第?[一二三四五六七八九十\d]+部分)\s*\d*", compact):
        return True
    if compact in {"yue", "中文维基百科", "中文維基百科", "中文维基百科 2024", "中文維基百科 2024"}:
        return True
    if "dialect" in compact or "spoken wikipedia" in compact:
        return True
    return False


def _classify_license(short_name: str, license_url: str) -> tuple[str, str] | None:
    combined = f"{short_name} {license_url}".casefold()
    if any(marker in combined for marker in ("noncommercial", "by-nc", "-nc-", "no derivatives", "by-nd")):
        return None
    if "cc0" in combined or "/zero/" in combined:
        return ("cc0", "CC0")
    if "public domain" in combined or "/publicdomain/mark/" in combined:
        return ("publicDomain", "Public Domain")
    if "by-sa" in combined or "attribution-share alike" in combined:
        return ("ccBySa", short_name or "CC BY-SA")
    if re.search(r"(?:cc\s*)?by(?:\s|[-/]|$)", combined) or "attribution" in combined:
        return ("ccBy", short_name or "CC BY")
    return None


def _license_url_or_default(
    rights_status: str, license_url: str, license_name: str
) -> str:
    if license_url.strip():
        return license_url.replace("http://", "https://", 1)
    if rights_status == "publicDomain":
        return "https://creativecommons.org/publicdomain/mark/1.0/"
    if rights_status == "cc0":
        return "https://creativecommons.org/publicdomain/zero/1.0/"
    version_match = re.search(r"(\d\.\d)", license_name)
    version = version_match.group(1) if version_match else "4.0"
    if rights_status == "ccBySa":
        return f"https://creativecommons.org/licenses/by-sa/{version}/"
    if rights_status == "ccBy":
        return f"https://creativecommons.org/licenses/by/{version}/"
    raise ValueError(f"No canonical license URL for {rights_status}")


def _meta_value(metadata: dict[str, Any], key: str) -> str:
    value = metadata.get(key, {})
    if isinstance(value, dict):
        return str(value.get("value", ""))
    return ""


def _spoken_language(page_title: str, categories: str) -> str:
    text = f"{page_title} {categories}".casefold()
    if "zh-yue" in text or "cantonese" in text or "粤语" in text or "粵語" in text:
        return "zh-yue"
    if "zh-tw" in text or "taiwan" in text:
        return "zh-Hant"
    return "zh"


def fetch_wikimedia_candidates(
    *, min_duration_seconds: int, max_file_bytes: int
) -> list[dict[str, Any]]:
    candidates: list[dict[str, Any]] = []
    continuation: dict[str, str] = {}

    while True:
        params = {
            "action": "query",
            "generator": "categorymembers",
            "gcmtitle": WIKIMEDIA_CATEGORY,
            "gcmtype": "file",
            "gcmlimit": "max",
            "prop": "videoinfo",
            "viprop": "url|size|mime|mediatype|metadata|extmetadata|derivatives",
            "format": "json",
            "formatversion": "2",
            **continuation,
        }
        url = f"{WIKIMEDIA_API}?{urllib.parse.urlencode(params)}"
        payload = _get_json(url)
        pages = payload.get("query", {}).get("pages", [])

        for page in pages:
            info_items = page.get("videoinfo") or []
            if not info_items:
                continue
            info = info_items[0]
            if info.get("mediatype") != "AUDIO":
                continue

            duration = int(round(float(info.get("duration") or 0)))
            file_size = int(info.get("size") or 0)
            if duration < min_duration_seconds or file_size <= 0 or file_size > max_file_bytes:
                continue

            metadata = info.get("extmetadata") or {}
            short_license = _strip_html(_meta_value(metadata, "LicenseShortName"))
            license_url = _strip_html(_meta_value(metadata, "LicenseUrl"))
            license_info = _classify_license(short_license, license_url)
            if license_info is None:
                continue

            object_name = _strip_html(_meta_value(metadata, "ObjectName"))
            raw_title = object_name or str(page.get("title", ""))
            title = re.sub(r"^(?:File:)?(?:zh(?:-[a-z]+)?[-_])?", "", raw_title, flags=re.I)
            title = re.sub(r"\.(?:ogg|oga|wav|mp3|flac)$", "", title, flags=re.I).strip()
            if not title or _reject_spoken_title(title):
                continue

            categories = _strip_html(_meta_value(metadata, "Categories"))
            language_code = _spoken_language(str(page.get("title", "")), categories)
            source_page = str(info.get("descriptionurl") or "")
            mp3_derivative = next(
                (
                    derivative.get("src")
                    for derivative in (info.get("derivatives") or [])
                    if str(derivative.get("type") or "").startswith("audio/mpeg")
                ),
                None,
            )
            playback_url = _clean_media_url(
                str(mp3_derivative or info.get("url") or "")
            )
            if not source_page or not playback_url:
                continue

            rights_status, normalized_license = license_info
            license_url = _license_url_or_default(
                rights_status, license_url, normalized_license
            )
            duration_minutes = duration / 60
            score = 60
            if 15 <= duration_minutes <= 60:
                score += 18
            elif 8 <= duration_minutes < 15:
                score += 12
            elif 60 < duration_minutes <= 120:
                score += 10
            else:
                score += 4
            if language_code == "zh":
                score += 7
            elif language_code == "zh-Hant":
                score += 5
            if rights_status in {"cc0", "publicDomain"}:
                score += 3

            creator = _strip_html(_meta_value(metadata, "Artist")) or "Wikimedia Commons contributor"
            candidates.append(
                {
                    "id": _stable_id("wikimedia", source_page),
                    "provider": "wikimediaCommons",
                    "sourceCollection": WIKIMEDIA_CATEGORY,
                    "sourcePage": source_page,
                    "playbackUrl": playback_url,
                    "title": title,
                    "creator": creator,
                    "kind": "spokenKnowledge",
                    "languageCode": language_code,
                    "durationSeconds": duration,
                    "fileSizeBytes": file_size,
                    "rightsStatus": rights_status,
                    "licenseName": normalized_license,
                    "licenseUrl": license_url,
                    "regions": ["CN", "INTL"],
                    "adFreeSource": True,
                    "loopCandidate": False,
                    "selectionScore": score,
                    "selectionReasons": [
                        "public Chinese spoken-word collection",
                        f"duration {duration_minutes:.1f} minutes",
                        "accepted reusable license metadata",
                    ],
                    "reviewStatus": "unreviewed",
                    "requiredReview": [
                        "listen to the complete recording",
                        "confirm voice tone and recording noise",
                        "prefer a gentle female voice or a pleasant low-stimulation male voice",
                        "confirm attribution and license at source",
                        "download and bundle before enabling for mainland users",
                    ],
                }
            )

        if "continue" not in payload:
            break
        continuation = {
            key: str(value) for key, value in payload["continue"].items()
        }

    return candidates


def _first_match(pattern: str, text: str, *, flags: int = re.I | re.S) -> str:
    match = re.search(pattern, text, flags)
    return _strip_html(match.group(1)) if match else ""


def _int_match(pattern: str, text: str) -> int:
    value = _first_match(pattern, text)
    try:
        return int(value.replace(",", ""))
    except ValueError:
        return 0


def _oga_item_links(collection_html: str) -> list[str]:
    links = re.findall(
        r'class=["\']art-preview-title["\'][^>]*>\s*<a\s+href=["\'](/content/[^"\']+)',
        collection_html,
        re.I | re.S,
    )
    return list(dict.fromkeys(urllib.parse.urljoin(OGA_COLLECTION_URL, link) for link in links))


def _oga_original_files(page_html: str) -> list[tuple[str, int]]:
    results: list[tuple[str, int]] = []
    anchors = re.findall(r"<a\b[^>]*>", page_html, re.I | re.S)
    for anchor in anchors:
        url_match = re.search(
            r'href=["\']([^"\']+\.(?:mp3|ogg|oga|wav|flac)(?:\?[^"\']*)?)["\']',
            anchor,
            re.I,
        )
        if not url_match:
            continue
        raw_url = url_match.group(1)
        url = _clean_media_url(urllib.parse.urljoin("https://opengameart.org", raw_url))
        if "/audio_preview/" in url:
            continue
        size_match = re.search(r"length=(\d+)", anchor, re.I)
        size = int(size_match.group(1)) if size_match else 0
        if (url, size) not in results:
            results.append((url, size))
    if results:
        return results

    preview_urls = re.findall(
        r'data-(?:mp3|ogg)-url=["\']([^"\']+)["\']', page_html, re.I
    )
    return [(_clean_media_url(url), 0) for url in dict.fromkeys(preview_urls)]


def _url_exists(url: str, *, timeout: int = 20) -> bool:
    headers = {"User-Agent": USER_AGENT, "Accept": "audio/*,*/*;q=0.5"}
    head_request = urllib.request.Request(url, headers=headers, method="HEAD")
    try:
        with urllib.request.urlopen(head_request, timeout=timeout) as response:
            return 200 <= response.status < 400
    except urllib.error.HTTPError as error:
        if error.code not in {403, 405}:
            return False
    except (urllib.error.URLError, TimeoutError, OSError):
        return False

    # A few public hosts reject HEAD.  Read one byte and close the response so
    # that a successful fallback does not download the full audio file.
    get_request = urllib.request.Request(
        url,
        headers={**headers, "Range": "bytes=0-0"},
        method="GET",
    )
    try:
        with urllib.request.urlopen(get_request, timeout=timeout) as response:
            response.read(1)
            return 200 <= response.status < 400
    except (urllib.error.URLError, TimeoutError, OSError):
        return False


def validate_playback_links(
    candidates: list[dict[str, Any]], *, workers: int
) -> list[dict[str, Any]]:
    checked_at = dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat()
    # Wikimedia's API returns the canonical media URL together with current
    # file metadata.  Re-checking hundreds of those URLs individually causes
    # avoidable CDN throttling, so the API response itself is the link check.
    api_checked = [
        item for item in candidates if item.get("provider") == "wikimediaCommons"
    ]
    for item in api_checked:
        item["linkCheckedAt"] = checked_at
        item["linkCheckMethod"] = "sourceApi"

    needs_request = [
        item for item in candidates if item.get("provider") != "wikimediaCommons"
    ]
    reachable: list[dict[str, Any]] = list(api_checked)
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as executor:
        future_to_item = {
            executor.submit(_url_exists, str(item["playbackUrl"])): item
            for item in needs_request
        }
        for future in concurrent.futures.as_completed(future_to_item):
            item = future_to_item[future]
            try:
                exists = future.result()
            except Exception:
                exists = False
            if exists:
                item["linkCheckedAt"] = checked_at
                item["linkCheckMethod"] = "http"
                reachable.append(item)
    return reachable


def _fetch_oga_item(source_page: str, max_file_bytes: int) -> dict[str, Any] | None:
    page_html = _get_text(source_page)
    title = _first_match(r'<h1[^>]+id=["\']page-title["\'][^>]*>(.*?)</h1>', page_html)
    if not title:
        title = _first_match(r'<meta[^>]+property=["\']og:title["\'][^>]+content=["\']([^"\']+)', page_html)
    if not title:
        return None

    author = _first_match(
        r'field-name-author(?:-submitter)?\b.*?<div class=["\']field-items["\']>.*?<a[^>]*>(.*?)</a>',
        page_html,
    ) or "OpenGameArt contributor"
    license_names = [
        _strip_html(value)
        for value in re.findall(r'class=["\']license-name["\']>(.*?)</div>', page_html, re.I | re.S)
    ]
    license_links = re.findall(
        r'class=["\']license-icon["\']>\s*<a\s+href=["\']([^"\']+)', page_html, re.I | re.S
    )
    license_pairs = list(zip(license_names, license_links))
    accepted = next(
        (
            (_classify_license(name, link), name, link)
            for name, link in license_pairs
            if _classify_license(name, link) is not None
        ),
        None,
    )
    if accepted is None:
        return None
    license_info, license_name, license_url = accepted
    assert license_info is not None
    rights_status, normalized_license = license_info
    license_url = _license_url_or_default(
        rights_status, license_url, normalized_license
    )

    tags = [
        _strip_html(value)
        for value in re.findall(
            r'field_art_tags_tid[^>]*>(.*?)</a>', page_html, re.I | re.S
        )
    ]
    screening_text = " ".join([title, *tags])
    if _contains_term(screening_text, MUSIC_EXCLUDE_TERMS):
        return None

    files = _oga_original_files(page_html)
    files = [item for item in files if item[1] <= 0 or item[1] <= max_file_bytes]
    if not files:
        return None
    files.sort(key=lambda item: (not item[0].lower().endswith(".mp3"), -item[1]))
    playback_url, file_size = files[0]

    favorites = _int_match(
        r'field-name-favorites\b.*?<div class=["\']field-items["\']>.*?<div class=["\']field-item[^"\']*["\']>([\d,]+)',
        page_html,
    )
    downloads = _int_match(r'class=["\']dlcount-number["\'][^>]*>([\d,]+)', page_html)
    positive_hits = sorted(
        {term for term in CALM_TERMS if term.casefold() in screening_text.casefold()}
    )
    strong_calm_hits = {
        term for term in STRONG_CALM_TERMS if term.casefold() in screening_text.casefold()
    }
    # The public collection is useful but broad.  Require either explicit calm
    # metadata or a modest amount of public curation signal before retaining a
    # track as a Stillow candidate.
    if not strong_calm_hits and favorites < 5:
        return None
    score = 64
    score += min(18, len(positive_hits) * 3)
    score += min(8, int(math.log10(favorites + 1) * 5))
    score += min(6, int(math.log10(downloads + 1) * 2))
    if rights_status in {"cc0", "publicDomain"}:
        score += 4

    return {
        "id": _stable_id("oga", source_page),
        "provider": "openGameArt",
        "sourceCollection": "CC0 - Calm / Relaxing Music",
        "sourcePage": source_page,
        "playbackUrl": playback_url,
        "title": title,
        "creator": author,
        "kind": "music",
        "languageCode": "zxx",
        "durationSeconds": None,
        "fileSizeBytes": file_size or None,
        "rightsStatus": rights_status,
        "licenseName": normalized_license or license_name,
        "licenseUrl": license_url,
        "regions": ["CN", "INTL"],
        "adFreeSource": True,
        "loopCandidate": True,
        "selectionScore": score,
        "selectionReasons": [
            "member of a public calm/relaxing collection",
            "accepted reusable license metadata",
            *([f"calm tags: {', '.join(positive_hits[:6])}"] if positive_hits else []),
            *([f"{favorites} OpenGameArt favorites"] if favorites else []),
            *([f"{downloads} downloads"] if downloads else []),
        ],
        "publicSignals": {"favorites": favorites, "downloads": downloads},
        "reviewStatus": "unreviewed",
        "requiredReview": [
            "listen to the complete recording",
            "measure duration, loudness, peaks, and loop seam",
            "reject abrupt intros, endings, and high-frequency events",
            "confirm attribution and license at source",
            "download and bundle before enabling for mainland users",
        ],
    }


def fetch_opengameart_candidates(*, max_file_bytes: int, workers: int) -> list[dict[str, Any]]:
    collection_html = _get_text(OGA_COLLECTION_URL)
    links = _oga_item_links(collection_html)
    if not links:
        raise SourceError("OpenGameArt collection contained no item links")

    candidates: list[dict[str, Any]] = []
    errors: list[str] = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as executor:
        future_to_url = {
            executor.submit(_fetch_oga_item, link, max_file_bytes): link for link in links
        }
        for future in concurrent.futures.as_completed(future_to_url):
            source_page = future_to_url[future]
            try:
                candidate = future.result()
                if candidate is not None:
                    candidates.append(candidate)
            except Exception as error:  # keep the rest of the public collection usable
                errors.append(f"{source_page}: {error}")

    if not candidates:
        detail = errors[0] if errors else "all entries were filtered"
        raise SourceError(f"No usable OpenGameArt candidates: {detail}")
    if errors:
        print(
            f"warning: skipped {len(errors)} OpenGameArt pages that could not be read",
            file=sys.stderr,
        )
    return candidates


def _as_text(value: Any) -> str:
    if isinstance(value, list):
        return " ".join(str(part) for part in value)
    return str(value or "")


def _parse_duration(value: Any) -> int:
    if value is None or value == "":
        return 0
    try:
        return int(round(float(value)))
    except (TypeError, ValueError):
        pass
    parts = str(value).strip().split(":")
    try:
        numbers = [float(part) for part in parts]
    except ValueError:
        return 0
    if len(numbers) == 2:
        return int(round(numbers[0] * 60 + numbers[1]))
    if len(numbers) == 3:
        return int(round(numbers[0] * 3600 + numbers[1] * 60 + numbers[2]))
    return 0


def _archive_search_documents(rows: int) -> list[dict[str, Any]]:
    query = (
        'mediatype:audio AND licenseurl:* AND '
        '(title:"nature sounds" OR title:"rain sounds" OR '
        'title:"ocean sounds" OR title:"brown noise" OR '
        'title:ambient OR title:calm OR title:meditation OR '
        'title:relaxing OR title:sleep)'
    )
    params: list[tuple[str, str]] = [
        ("q", query),
        ("rows", str(rows)),
        ("page", "1"),
        ("sort[]", "downloads desc"),
        ("output", "json"),
    ]
    for field in (
        "identifier",
        "title",
        "creator",
        "description",
        "subject",
        "licenseurl",
        "downloads",
        "avg_rating",
        "num_reviews",
    ):
        params.append(("fl[]", field))
    payload = _get_json(f"{INTERNET_ARCHIVE_SEARCH}?{urllib.parse.urlencode(params)}")
    return list(payload.get("response", {}).get("docs", []))


def _archive_document_is_relevant(document: dict[str, Any]) -> bool:
    license_url = _as_text(document.get("licenseurl"))
    if _classify_license("", license_url) is None:
        return False
    title = _as_text(document.get("title"))
    text = " ".join(_as_text(document.get(key)) for key in ("title", "subject", "description"))
    if _contains_term(text, ARCHIVE_EXCLUDE_TERMS):
        return False
    return _contains_term(title, ARCHIVE_NATURE_TERMS + ARCHIVE_TITLE_CALM_TERMS)


def _archive_audio_files(
    files: list[dict[str, Any]],
    *,
    min_duration_seconds: int,
    max_file_bytes: int,
) -> list[dict[str, Any]]:
    usable: list[dict[str, Any]] = []
    for file_info in files:
        name = str(file_info.get("name") or "")
        file_format = str(file_info.get("format") or "")
        lowered = f"{name} {file_format}".casefold()
        if not re.search(r"\.(?:mp3|ogg|oga|m4a)$", name, re.I):
            continue
        if any(marker in lowered for marker in ("spectrogram", "thumbnail", "sample", "_files.xml")):
            continue
        duration = _parse_duration(file_info.get("length"))
        try:
            size = int(file_info.get("size") or 0)
        except (TypeError, ValueError):
            size = 0
        if duration < min_duration_seconds or duration > 4 * 60 * 60:
            continue
        if size <= 0 or size > max_file_bytes:
            continue
        usable.append(
            {
                "name": name,
                "format": file_format,
                "duration": duration,
                "size": size,
                "title": _as_text(file_info.get("title")),
            }
        )

    # Prefer MP3 for broad tooling support and avoid listing the OGG derivative
    # of the same recording as a separate candidate.
    usable.sort(
        key=lambda item: (
            not item["name"].casefold().endswith(".mp3"),
            -item["duration"],
            item["name"].casefold(),
        )
    )
    selected: list[dict[str, Any]] = []
    seen_stems: set[str] = set()
    for item in usable:
        stem = re.sub(r"\.(?:mp3|ogg|oga|m4a)$", "", item["name"], flags=re.I)
        stem = re.sub(r"(?:_vbr|_64kb|_128kb)$", "", stem, flags=re.I).casefold()
        if stem in seen_stems:
            continue
        seen_stems.add(stem)
        selected.append(item)
        if len(selected) == 6:
            break
    return selected


def _fetch_archive_item(
    document: dict[str, Any],
    *,
    min_duration_seconds: int,
    max_file_bytes: int,
) -> list[dict[str, Any]]:
    identifier = str(document.get("identifier") or "")
    if not identifier:
        return []
    metadata_url = INTERNET_ARCHIVE_METADATA + urllib.parse.quote(identifier, safe="")
    payload = _get_json(metadata_url)
    metadata = payload.get("metadata") or {}
    license_url = _as_text(metadata.get("licenseurl") or document.get("licenseurl"))
    license_info = _classify_license("", license_url)
    if license_info is None:
        return []

    item_title = _strip_html(_as_text(metadata.get("title") or document.get("title")))
    creator = _strip_html(_as_text(metadata.get("creator") or document.get("creator")))
    subjects = _as_text(metadata.get("subject") or document.get("subject"))
    description = _strip_html(_as_text(metadata.get("description") or document.get("description")))
    screening_text = " ".join((item_title, subjects, description))
    if _contains_term(screening_text, ARCHIVE_EXCLUDE_TERMS):
        return []
    is_nature = _contains_term(item_title, ARCHIVE_NATURE_TERMS)
    if not is_nature and not _contains_term(item_title, ARCHIVE_TITLE_CALM_TERMS):
        return []

    files = _archive_audio_files(
        list(payload.get("files") or []),
        min_duration_seconds=min_duration_seconds,
        max_file_bytes=max_file_bytes,
    )
    if not files:
        return []

    rights_status, license_name = license_info
    license_url = _license_url_or_default(
        rights_status, license_url, license_name
    )
    source_page = f"https://archive.org/details/{urllib.parse.quote(identifier, safe='')}"
    try:
        downloads = int(document.get("downloads") or metadata.get("downloads") or 0)
    except (TypeError, ValueError):
        downloads = 0
    try:
        rating = float(document.get("avg_rating") or 0)
    except (TypeError, ValueError):
        rating = 0.0
    try:
        reviews = int(document.get("num_reviews") or 0)
    except (TypeError, ValueError):
        reviews = 0

    results: list[dict[str, Any]] = []
    for file_info in files:
        file_title = _strip_html(file_info["title"])
        if not file_title:
            file_title = Path(file_info["name"]).stem.replace("_", " ").strip()
        title = item_title if len(files) == 1 else f"{item_title} · {file_title}"
        file_text = f"{title} {file_info['name']}"
        if _contains_term(file_text, ARCHIVE_EXCLUDE_TERMS):
            continue
        playback_url = (
            f"https://archive.org/download/{urllib.parse.quote(identifier, safe='')}/"
            f"{urllib.parse.quote(file_info['name'], safe='/')}"
        )
        duration_minutes = file_info["duration"] / 60
        score = 62
        score += min(12, int(math.log10(downloads + 1) * 3))
        if rating >= 4 and reviews >= 2:
            score += 8
        elif rating >= 3.5:
            score += 4
        if 15 <= duration_minutes <= 90:
            score += 10
        elif duration_minutes > 90:
            score += 5
        if rights_status in {"cc0", "publicDomain"}:
            score += 4

        results.append(
            {
                "id": _stable_id("archive", playback_url),
                "provider": "internetArchive",
                "sourceCollection": "Internet Archive reusable calm/nature audio search",
                "sourcePage": source_page,
                "playbackUrl": playback_url,
                "title": title,
                "creator": creator or "Internet Archive contributor",
                "kind": "soundscape" if is_nature else "music",
                "languageCode": "zxx",
                "durationSeconds": file_info["duration"],
                "fileSizeBytes": file_info["size"],
                "rightsStatus": rights_status,
                "licenseName": license_name,
                "licenseUrl": license_url,
                "regions": ["CN", "INTL"],
                "adFreeSource": True,
                "loopCandidate": True,
                "selectionScore": score,
                "selectionReasons": [
                    "calm or nature metadata",
                    f"duration {duration_minutes:.1f} minutes",
                    "accepted reusable license metadata",
                    *([f"{downloads} downloads"] if downloads else []),
                    *([f"rating {rating:g} from {reviews} reviews"] if reviews else []),
                ],
                "publicSignals": {
                    "downloads": downloads,
                    "rating": rating,
                    "reviews": reviews,
                },
                "reviewStatus": "unreviewed",
                "requiredReview": [
                    "listen to the complete recording",
                    "reject speech, health claims, abrupt events, and distracting wildlife",
                    "measure loudness, peaks, and loop seam",
                    "confirm attribution and license at source",
                    "download and bundle before enabling for mainland users",
                ],
            }
        )
    return results


def fetch_internet_archive_candidates(
    *,
    max_documents: int,
    min_duration_seconds: int,
    max_file_bytes: int,
    workers: int,
) -> list[dict[str, Any]]:
    documents = [
        document
        for document in _archive_search_documents(max_documents * 3)
        if _archive_document_is_relevant(document)
    ][:max_documents]
    if not documents:
        raise SourceError("Internet Archive search produced no reusable calm/nature items")

    candidates: list[dict[str, Any]] = []
    errors = 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as executor:
        futures = [
            executor.submit(
                _fetch_archive_item,
                document,
                min_duration_seconds=min_duration_seconds,
                max_file_bytes=max_file_bytes,
            )
            for document in documents
        ]
        for future in concurrent.futures.as_completed(futures):
            try:
                candidates.extend(future.result())
            except Exception:
                errors += 1
    if errors:
        print(f"warning: skipped {errors} Internet Archive metadata records", file=sys.stderr)
    if not candidates:
        raise SourceError("No Internet Archive files passed duration and file checks")
    return candidates


def select_balanced(candidates: list[dict[str, Any]], limit: int) -> list[dict[str, Any]]:
    def sort_key(item: dict[str, Any]) -> tuple[Any, ...]:
        duration = item.get("durationSeconds") or 0
        return (-int(item.get("selectionScore") or 0), -duration, str(item.get("title", "")).casefold())

    spoken = sorted((item for item in candidates if item["kind"] == "spokenKnowledge"), key=sort_key)
    music = sorted((item for item in candidates if item["kind"] == "music"), key=sort_key)
    soundscapes = sorted((item for item in candidates if item["kind"] == "soundscape"), key=sort_key)

    if soundscapes:
        spoken_target = min(len(spoken), max(1, round(limit * 0.45)))
        music_target = min(len(music), max(1, round(limit * 0.30)))
        soundscape_target = min(
            len(soundscapes), max(1, limit - spoken_target - music_target)
        )
    else:
        music_target = min(len(music), max(1, round(limit * 0.35)))
        spoken_target = min(len(spoken), limit - music_target)
        soundscape_target = 0
    selected = (
        spoken[:spoken_target]
        + music[:music_target]
        + soundscapes[:soundscape_target]
    )

    if len(selected) < limit:
        selected_ids = {item["id"] for item in selected}
        remainder = sorted(
            (item for item in candidates if item["id"] not in selected_ids),
            key=sort_key,
        )
        selected.extend(remainder[: limit - len(selected)])

    return sorted(
        selected,
        key=lambda item: (item["kind"], -int(item["selectionScore"]), item["title"].casefold()),
    )


def build_payload(candidates: list[dict[str, Any]], *, limit: int, args: argparse.Namespace) -> dict[str, Any]:
    selected = select_balanced(candidates, limit)
    providers = Counter(item["provider"] for item in selected)
    kinds = Counter(item["kind"] for item in selected)
    return {
        "schemaVersion": 1,
        "generatedAt": dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat(),
        "generator": {
            "script": "tools/build_audio_candidates.py",
            "version": SCRIPT_VERSION,
        },
        "purpose": "Review queue only; the app must not load or play this file directly.",
        "criteria": {
            "acceptedLicenses": list(ACCEPTED_LICENSE_LABELS),
            "minimumSpokenDurationSeconds": args.min_spoken_minutes * 60,
            "maximumFileBytes": args.max_file_mb * 1024 * 1024,
            "highArousalTitleFilter": True,
            "completeListeningReviewRequired": True,
            "automaticPromotionToAudioCatalog": False,
            "playbackLinksChecked": args.check_links,
        },
        "sourceLists": [
            {
                "provider": "wikimediaCommons",
                "url": "https://commons.wikimedia.org/wiki/Category:Spoken_Chinese_Wikipedia",
                "use": "long Chinese spoken-word candidates",
            },
            {
                "provider": "openGameArt",
                "url": OGA_COLLECTION_URL,
                "use": "calm reusable music candidates",
            },
            {
                "provider": "internetArchive",
                "url": "https://archive.org/advancedsearch.php",
                "use": "long reusable calm and nature-audio candidates",
            },
        ],
        "summary": {
            "selected": len(selected),
            "availableBeforeLimit": len(candidates),
            "byProvider": dict(sorted(providers.items())),
            "byKind": dict(sorted(kinds.items())),
        },
        "items": selected,
    }


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--limit", type=int, default=300, help="maximum selected candidates")
    parser.add_argument(
        "--min-spoken-minutes",
        type=int,
        default=8,
        help="minimum duration for Chinese spoken-word candidates",
    )
    parser.add_argument(
        "--max-file-mb",
        type=int,
        default=80,
        help="reject unusually large individual source files",
    )
    parser.add_argument(
        "--archive-items",
        type=int,
        default=80,
        help="maximum Internet Archive records to inspect",
    )
    parser.add_argument("--workers", type=int, default=12, help="parallel public metadata requests")
    parser.add_argument(
        "--check-links",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="verify every direct audio URL before writing (default: enabled)",
    )
    parser.add_argument(
        "--minimum-results",
        type=int,
        default=100,
        help="do not replace the output if fewer candidates are available",
    )
    parser.add_argument(
        "--source",
        action="append",
        choices=("wikimedia", "opengameart", "internetarchive"),
        help="source to query; repeat as needed (default: all)",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    if (
        args.limit <= 0
        or args.min_spoken_minutes <= 0
        or args.max_file_mb <= 0
        or args.archive_items <= 0
    ):
        raise SystemExit("limit, durations, and file sizes must be positive")
    if args.minimum_results < 0 or args.workers <= 0:
        raise SystemExit("minimum-results cannot be negative and workers must be positive")

    requested_sources = set(
        args.source or ("wikimedia", "opengameart", "internetarchive")
    )
    max_file_bytes = args.max_file_mb * 1024 * 1024
    candidates: list[dict[str, Any]] = []

    if "wikimedia" in requested_sources:
        print("Reading Wikimedia Chinese spoken-word metadata...", file=sys.stderr)
        candidates.extend(
            fetch_wikimedia_candidates(
                min_duration_seconds=args.min_spoken_minutes * 60,
                max_file_bytes=max_file_bytes,
            )
        )
    if "opengameart" in requested_sources:
        print("Reading OpenGameArt calm-music metadata...", file=sys.stderr)
        candidates.extend(
            fetch_opengameart_candidates(
                max_file_bytes=max_file_bytes,
                workers=args.workers,
            )
        )
    if "internetarchive" in requested_sources:
        print("Reading Internet Archive calm/nature metadata...", file=sys.stderr)
        candidates.extend(
            fetch_internet_archive_candidates(
                max_documents=args.archive_items,
                min_duration_seconds=5 * 60,
                max_file_bytes=max_file_bytes,
                workers=args.workers,
            )
        )

    deduplicated = {item["id"]: item for item in candidates}
    candidates = list(deduplicated.values())
    if args.check_links:
        print(f"Checking {len(candidates)} direct audio links...", file=sys.stderr)
        unchecked_count = len(candidates)
        candidates = validate_playback_links(candidates, workers=args.workers)
        skipped = unchecked_count - len(candidates)
        if skipped:
            print(f"warning: removed {skipped} unreachable audio links", file=sys.stderr)
    selected_count = min(args.limit, len(candidates))
    if selected_count < args.minimum_results:
        raise SystemExit(
            f"Refusing to replace output: only {selected_count} candidates passed; "
            f"minimum is {args.minimum_results}."
        )

    payload = build_payload(candidates, limit=args.limit, args=args)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    temporary = args.output.with_suffix(args.output.suffix + ".tmp")
    temporary.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    temporary.replace(args.output)
    print(
        f"Wrote {payload['summary']['selected']} candidates to {args.output} "
        f"({payload['summary']['byProvider']})."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
