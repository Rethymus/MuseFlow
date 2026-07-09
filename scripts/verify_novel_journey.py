#!/usr/bin/env python3
"""Reproducible audit for docs/novel-journey canonical chapters.

This script is deliberately narrow:
  1. verify current local canonical chapter stats;
  2. compare those stats against docs/novel-journey/metrics.json;
  3. report exact duplicate lines / paragraphs in canonical prose;
  4. count common declarative-summary phrases per chapter;
  5. optionally verify every Notion page against the local Markdown body.

It exists so review findings can be re-run from the repo instead of relying on
conversation memory.

Examples:

  python3 scripts/verify_novel_journey.py
  NOTION_TOKEN=... python3 scripts/verify_novel_journey.py --notion
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import socket
import sys
import time
import urllib.error
import urllib.request
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
NOVEL = ROOT / "docs" / "novel-journey"
CHAPTERS = NOVEL / "chapters"
INDEX = NOVEL / "notion_index.json"
METRICS = NOVEL / "metrics.json"
NOTION_VERSION = "2022-06-28"
NOTION_API = "https://api.notion.com/v1"
CHUNK = 1900
DEFAULT_SAMPLE_CHAPTERS = (1, 17, 30, 55, 72, 75, 84, 95, 100)

CJK_RANGES = ((0x4E00, 0x9FFF), (0x3400, 0x4DBF))
DECLARATIVE_PATTERNS = (
    re.compile(r"忽然明白|终于明白"),
    re.compile(r"\b[他她]\s*知道"),
    re.compile(r"很清楚|清清楚楚"),
    re.compile(r"所谓"),
    re.compile(r"不是[^。！？!?\n]{0,40}而是"),
    re.compile(r"从这一刻起|到这一刻"),
    re.compile(r"原来"),
)


def is_cjk(ch: str) -> bool:
    cp = ord(ch)
    return any(start <= cp <= end for start, end in CJK_RANGES)


def chapter_no_from_name(name: str) -> int:
    match = re.search(r"第0*(\d+)章", name)
    if not match:
        raise ValueError(f"cannot parse chapter number from {name}")
    return int(match.group(1))


def canonical_paths() -> list[Path]:
    paths = [
        path
        for path in CHAPTERS.glob("第*章-*.md")
        if not path.name.endswith(".polished.md")
    ]
    return sorted(paths, key=lambda path: chapter_no_from_name(path.name))


def read_body(path: Path) -> str:
    raw = path.read_text(encoding="utf-8")
    lines = raw.splitlines()
    if lines and lines[0].startswith("# "):
        lines = lines[1:]
    return "\n".join(lines).strip()


def cjk_count(text: str) -> int:
    return sum(1 for ch in text if is_cjk(ch))


def split_paragraph_pieces(body: str) -> list[str]:
    pieces: list[str] = []
    for para in re.split(r"\n{2,}", body):
        para = para.strip()
        if not para:
            continue
        while len(para) > CHUNK:
            cut = max(
                (
                    para.rfind(sep, 0, CHUNK)
                    for sep in "。！？；，、 "
                    if para.rfind(sep, 0, CHUNK) > CHUNK // 2
                ),
                default=-1,
            )
            if cut <= 0:
                cut = CHUNK
            else:
                cut += 1
            pieces.append(para[:cut].strip())
            para = para[cut:].strip()
        if para:
            pieces.append(para)
    return pieces


def load_index() -> list[dict]:
    return json.loads(INDEX.read_text(encoding="utf-8"))


def load_metrics() -> dict:
    return json.loads(METRICS.read_text(encoding="utf-8"))


def local_stats(paths: list[Path]) -> dict:
    counts: list[tuple[int, Path]] = []
    line_positions: dict[str, list[str]] = defaultdict(list)
    para_positions: dict[str, list[str]] = defaultdict(list)
    declarative_hits: list[tuple[int, str, int]] = []
    chapter_rows: list[dict] = []

    total_cjk = 0
    for path in paths:
        body = read_body(path)
        count = cjk_count(body)
        counts.append((count, path))
        total_cjk += count

        chapter_no = chapter_no_from_name(path.name)
        hits = sum(len(pattern.findall(body)) for pattern in DECLARATIVE_PATTERNS)
        declarative_hits.append((chapter_no, path.name, hits))
        tail = "\n".join(body.splitlines()[-10:])
        tail_hits = sum(
            len(pattern.findall(tail)) for pattern in DECLARATIVE_PATTERNS
        ) + len(re.findall(r"真正", tail))
        dialogue_count = body.count("“")
        exclamation_count = sum(body.count(ch) for ch in "!?？！")

        flags = []
        if count < 1400:
            flags.append("severe_short")
        elif count < 1600:
            flags.append("short")
        if hits >= 6:
            flags.append("high_declarative")
        elif hits >= 4:
            flags.append("declarative")
        if tail_hits >= 3:
            flags.append("tail_summary_high")
        elif tail_hits >= 2:
            flags.append("tail_summary")
        if dialogue_count <= 12:
            flags.append("low_dialogue")

        chapter_rows.append(
            {
                "chapter_no": chapter_no,
                "file": path.name,
                "cjk": count,
                "declarative_hits": hits,
                "tail_summary_hits": tail_hits,
                "dialogue_count": dialogue_count,
                "exclamation_count": exclamation_count,
                "flags": flags,
            }
        )

        for idx, line in enumerate(body.splitlines(), start=1):
            normalized = line.strip()
            if len(normalized) >= 18:
                line_positions[normalized].append(f"{path.name}:{idx}")

        for para_idx, para in enumerate(re.split(r"\n{2,}", body), start=1):
            normalized = para.strip()
            if len(normalized) >= 30:
                para_positions[normalized].append(f"{path.name}:para{para_idx}")

    counts.sort(key=lambda item: item[0])
    declarative_hits.sort(key=lambda item: (-item[2], item[0]))

    dup_lines = [
        {"text": text, "locations": locs}
        for text, locs in line_positions.items()
        if len(locs) > 1
    ]
    dup_paras = [
        {"text": text, "locations": locs}
        for text, locs in para_positions.items()
        if len(locs) > 1
    ]

    return {
        "chapter_count": len(counts),
        "total_cjk": total_cjk,
        "avg_cjk": round(total_cjk / len(counts), 2) if counts else 0,
        "min": {"cjk": counts[0][0], "file": counts[0][1].name} if counts else None,
        "max": {"cjk": counts[-1][0], "file": counts[-1][1].name} if counts else None,
        "under_7000_count": sum(1 for count, _ in counts if count < 7000),
        "duplicate_line_count": len(dup_lines),
        "duplicate_paragraph_count": len(dup_paras),
        "duplicate_line_samples": dup_lines[:5],
        "duplicate_paragraph_samples": dup_paras[:5],
        "top_declarative_hits": [
            {"chapter_no": no, "file": name, "hits": hits}
            for no, name, hits in declarative_hits[:15]
        ],
        "per_chapter": chapter_rows,
    }


def compare_metrics(actual: dict, declared: dict) -> dict:
    length = declared.get("length", {})
    return {
        "declared_total_cjk": length.get("totalCjkChars"),
        "declared_avg_cjk": length.get("avgCjkCharsPerChapter"),
        "declared_min_cjk": length.get("minCjkChars"),
        "declared_max_cjk": length.get("maxCjkChars"),
        "actual_total_cjk": actual["total_cjk"],
        "actual_avg_cjk": actual["avg_cjk"],
        "actual_min_cjk": actual["min"]["cjk"] if actual["min"] else None,
        "actual_max_cjk": actual["max"]["cjk"] if actual["max"] else None,
    }


def notion_request(token: str, path: str) -> dict:
    req = urllib.request.Request(
        f"{NOTION_API}{path}",
        headers={
            "Authorization": f"Bearer {token}",
            "Notion-Version": NOTION_VERSION,
        },
    )
    last_error = None
    for attempt in range(1, 7):
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                return json.loads(resp.read().decode())
        except urllib.error.HTTPError as err:
            if err.code in (429, 500, 502, 503, 504) and attempt < 6:
                time.sleep(2**attempt)
                continue
            detail = err.read().decode()[:300]
            raise RuntimeError(f"NOTION GET {path} -> {err.code}: {detail}") from None
        except (urllib.error.URLError, TimeoutError, socket.timeout) as err:
            last_error = err
            if attempt < 6:
                time.sleep(2**attempt)
                continue
            break
    raise RuntimeError(f"NOTION GET {path} failed after retries: {last_error}") from None


def fetch_page_blocks(page_id: str, token: str) -> list[tuple[str, str]]:
    blocks: list[tuple[str, str]] = []
    cursor = None
    while True:
        query = f"?start_cursor={cursor}" if cursor else ""
        data = notion_request(token, f"/blocks/{page_id}/children{query}")
        for block in data.get("results", []):
            block_type = block.get("type", "")
            if block_type != "paragraph":
                blocks.append((block_type, ""))
                continue
            texts = []
            for rich_text in block["paragraph"].get("rich_text", []):
                if rich_text.get("type") == "text":
                    texts.append(rich_text["text"].get("content", ""))
                else:
                    texts.append(rich_text.get("plain_text", ""))
            blocks.append((block_type, "".join(texts)))
        if not data.get("has_more"):
            break
        cursor = data.get("next_cursor")
        time.sleep(0.15)
    return blocks


def notion_parity(index_entries: list[dict], sample_chapters: set[int]) -> dict:
    token = os.environ.get("NOTION_TOKEN")
    if not token:
        raise RuntimeError("NOTION_TOKEN is required for --notion")

    mismatches = []
    non_paragraph_total = 0
    sample_hashes = []

    for entry in index_entries:
        body = read_body(CHAPTERS / entry["file"])
        expected = split_paragraph_pieces(body)
        actual_blocks = fetch_page_blocks(entry["page_id"], token)
        actual = []
        for block_type, content in actual_blocks:
            if block_type != "paragraph":
                non_paragraph_total += 1
                actual.append((block_type, content))
            else:
                actual.append(content)

        if actual != expected:
            mismatches.append(
                {
                    "chapter_no": entry["chapterNo"],
                    "file": entry["file"],
                    "expected_blocks": len(expected),
                    "actual_blocks": len(actual),
                }
            )

        if entry["chapterNo"] in sample_chapters:
            digest = hashlib.sha256("\n".join(expected).encode()).hexdigest()[:16]
            sample_hashes.append(
                {
                    "chapter_no": entry["chapterNo"],
                    "hash": digest,
                    "match": actual == expected,
                }
            )
        time.sleep(0.15)

    return {
        "checked_chapters": len(index_entries),
        "mismatches": mismatches,
        "non_paragraph_total": non_paragraph_total,
        "sample_hashes": sample_hashes,
    }


def print_human_report(actual: dict, metrics_comparison: dict, notion: dict | None) -> None:
    print("== Local Canonical Stats ==")
    print(f"chapters: {actual['chapter_count']}")
    print(f"total_cjk: {actual['total_cjk']}")
    print(f"avg_cjk: {actual['avg_cjk']}")
    print(f"min: {actual['min']['file']} -> {actual['min']['cjk']}")
    print(f"max: {actual['max']['file']} -> {actual['max']['cjk']}")
    print(f"under_7000_count: {actual['under_7000_count']}")
    print(f"duplicate_lines: {actual['duplicate_line_count']}")
    print(f"duplicate_paragraphs: {actual['duplicate_paragraph_count']}")
    print()

    print("== Metrics Drift ==")
    for key in (
        "declared_total_cjk",
        "declared_avg_cjk",
        "declared_min_cjk",
        "declared_max_cjk",
        "actual_total_cjk",
        "actual_avg_cjk",
        "actual_min_cjk",
        "actual_max_cjk",
    ):
        print(f"{key}: {metrics_comparison[key]}")
    print()

    print("== Declarative Summary Hotspots ==")
    for row in actual["top_declarative_hits"][:10]:
        print(f"ch{row['chapter_no']:>3} hits={row['hits']:>2} {row['file']}")
    print()

    print("== Chapter Heatmap Hotspots ==")
    for row in actual["per_chapter"]:
        if not row["flags"]:
            continue
        print(
            f"ch{row['chapter_no']:>3} cjk={row['cjk']:>4} "
            f"decl={row['declarative_hits']:>2} tail={row['tail_summary_hits']:>2} "
            f"dialogue={row['dialogue_count']:>2} flags={','.join(row['flags'])}"
        )
    print()

    if notion is not None:
        print("== Notion Parity ==")
        print(f"checked_chapters: {notion['checked_chapters']}")
        print(f"mismatch_count: {len(notion['mismatches'])}")
        print(f"non_paragraph_total: {notion['non_paragraph_total']}")
        print("sample_hashes:")
        for row in notion["sample_hashes"]:
            print(
                f"  ch{row['chapter_no']:>3} hash={row['hash']} match={row['match']}"
            )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--notion",
        action="store_true",
        help="verify every Notion page against the local canonical Markdown body",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="print machine-readable JSON instead of the human summary",
    )
    parser.add_argument(
        "--samples",
        default=",".join(str(no) for no in DEFAULT_SAMPLE_CHAPTERS),
        help="comma-separated sample chapter list for hash evidence",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = canonical_paths()
    actual = local_stats(paths)
    metrics_comparison = compare_metrics(actual, load_metrics())

    notion = None
    exit_code = 0
    if args.notion:
        sample_chapters = {
            int(value) for value in args.samples.split(",") if value.strip()
        }
        notion = notion_parity(load_index(), sample_chapters)
        if notion["mismatches"] or notion["non_paragraph_total"]:
            exit_code = 1

    payload = {
        "local": actual,
        "metrics_comparison": metrics_comparison,
        "notion": notion,
    }
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print_human_report(actual, metrics_comparison, notion)
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
