#!/usr/bin/env python3
"""Publish the generated long novel to Notion as one page per chapter.

Automated upload (the user delegates platform choice + automation). Notion is
chosen over 语雀 because its REST API supports programmatic page creation with
full read/write for personal workspaces, while 语雀's API is gated behind team
accounts.

Setup (one-time, ~5 minutes):
  1. Create a free Notion account and a parent page, e.g. "剑道苍穹（MuseFlow 实测）".
  2. https://www.notion.so/profile/integrations → "Develop your own
     integrations" → "Create new integration" → copy the Internal Integration
     Secret (starts with secret_ or ntn_).
  3. Open the parent page → ••• → Connections → add the integration you just
     created (this shares the page — and its future children — with the token).
  4. (Optional, for public README links) ••• → Share → "Share to web" with
     "Anyone with the link" = Can read. Child pages inherit and become
     viewable without login.

Usage:
  NOTION_TOKEN=secret_xxx NOTION_PARENT_PAGE_ID=xxxxxxxx \
      python3 scripts/publish_novel_to_notion.py

The token NEVER enters the repo — it is read from the environment and used
only for these HTTP calls. The script writes docs/novel-journey/notion_index.json
mapping each chapter file to its Notion URL so the README can link to it.

Re-running is incremental: chapters already present in notion_index.json are
skipped, so you can resume if the run is interrupted.
"""

from __future__ import annotations

import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

NOTION_VERSION = "2022-06-28"
API = "https://api.notion.com/v1"
CHUNK = 1900  # Notion rich_text content limit is 2000 chars; stay under it.
MAX_BLOCKS = 100  # Notion children-per-request cap.
ROOT = Path(__file__).resolve().parent.parent
# NOVEL_DIR lets a second novel (e.g. "novel-go") reuse this script without
# touching the original "novel-journey" (xianxia) artifacts. Default unchanged.
NOVEL_DIR = os.environ.get("NOVEL_DIR", "novel-journey")
CHAPTERS_DIR = ROOT / "docs" / NOVEL_DIR / "chapters"
INDEX_PATH = ROOT / "docs" / NOVEL_DIR / "notion_index.json"

# Lines that are clearly structural rather than prose get their own block type.
_HEADING = re.compile(r"^#{1,3}\s+")


def _request(method: str, path: str, token: str, body: dict | None = None) -> dict:
    url = f"{API}{path}"
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(
        url,
        data=data,
        method=method,
        headers={
            "Authorization": f"Bearer {token}",
            "Notion-Version": NOTION_VERSION,
            "Content-Type": "application/json",
        },
    )
    for attempt in range(1, 5):
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                return json.loads(resp.read().decode())
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < 4:
                wait = 2 ** attempt
                print(f"  rate-limited, waiting {wait}s (attempt {attempt})", file=sys.stderr)
                time.sleep(wait)
                continue
            detail = e.read().decode()[:500]
            raise RuntimeError(f"NOTION {method} {path} -> {e.code}: {detail}") from None
    raise RuntimeError("unreachable")


def _split_text(text: str) -> list[str]:
    """Split prose into ≤CHUNK-char pieces at paragraph / sentence boundaries."""
    pieces: list[str] = []
    for para in re.split(r"\n{2,}", text):
        para = para.strip()
        if not para:
            continue
        while len(para) > CHUNK:
            cut = _best_cut(para, CHUNK)
            pieces.append(para[:cut].strip())
            para = para[cut:].strip()
        if para:
            pieces.append(para)
    return pieces


def _best_cut(text: str, limit: int) -> int:
    for sep in ("。", "！", "？", "；", ".", "!", "?", ";", "，", ",", " "):
        idx = text.rfind(sep, 0, limit)
        if idx > limit // 2:
            return idx + len(sep)
    return limit


def _paragraph_blocks(pieces: list[str]) -> list[dict]:
    blocks = []
    for piece in pieces:
        # A single paragraph may still exceed CHUNK after splitting; slice it.
        for i in range(0, len(piece), CHUNK):
            chunk = piece[i : i + CHUNK]
            blocks.append(
                {
                    "object": "block",
                    "type": "paragraph",
                    "paragraph": {
                        "rich_text": [{"type": "text", "text": {"content": chunk}}]
                    },
                }
            )
    return blocks


def _chapter_blocks(body: str) -> list[dict]:
    """Turn a chapter body into Notion blocks, respecting ≤MAX_BLOCKS per page."""
    blocks: list[dict] = []
    for piece in _split_text(body):
        blocks.extend(_paragraph_blocks([piece]))
    # Notion allows ≤100 blocks in a create-page call. Trim defensively; the
    # append-children path tops up the rest.
    return blocks[:MAX_BLOCKS]


def _overflow_blocks(body: str) -> list[dict]:
    blocks = _chapter_blocks(body)
    return blocks[MAX_BLOCKS:]


def parse_chapter(path: Path) -> tuple[str, str, int]:
    raw = path.read_text(encoding="utf-8")
    lines = raw.splitlines()
    title = path.stem  # "第001章-凡人少年"
    if lines and lines[0].startswith("# "):
        title = lines[0][2:].strip()
    body = "\n".join(lines[1:]).strip()
    m = re.search(r"第0*(\d+)章", path.stem)
    chapter_no = int(m.group(1)) if m else 0
    return title, body, chapter_no


def publish_chapter(path: Path, token: str, parent_id: str) -> dict:
    title, body, chapter_no = parse_chapter(path)
    initial = _chapter_blocks(body)
    payload = {
        "parent": {"page_id": parent_id},
        "properties": {
            "title": [{"type": "text", "text": {"content": title}}]
        },
        "children": initial,
    }
    created = _request("POST", "/pages", token, payload)
    page_id = created["id"]
    overflow = _overflow_blocks(body)
    if overflow:
        _request("PATCH", f"/blocks/{page_id}/children", token, {"children": overflow})
    url = created.get("url", "")
    public_url = created.get("public_url") or ""
    print(f"  ✓ 第{chapter_no:>3}章 {title} -> {url}")
    return {
        "chapterNo": chapter_no,
        "file": path.name,
        "title": title,
        "url": url,
        "public_url": public_url,
        "page_id": page_id,
    }


def main() -> int:
    token = os.environ.get("NOTION_TOKEN")
    parent_id = os.environ.get("NOTION_PARENT_PAGE_ID")
    if not token or not parent_id:
        print(
            "NOTION_TOKEN and NOTION_PARENT_PAGE_ID must be set. See the docstring "
            "at the top of this script for setup steps.",
            file=sys.stderr,
        )
        return 2
    if not CHAPTERS_DIR.is_dir():
        print(f"no chapters dir at {CHAPTERS_DIR}", file=sys.stderr)
        return 2

    files = sorted(CHAPTERS_DIR.glob("第*章-*.md"))
    if not files:
        print(f"no chapter files in {CHAPTERS_DIR}", file=sys.stderr)
        return 2

    index = []
    if INDEX_PATH.exists():
        index = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
    done_files = {entry["file"] for entry in index}

    print(f"publishing {len(files)} chapters to Notion parent {parent_id}")
    for path in files:
        if path.name in done_files:
            continue
        try:
            entry = publish_chapter(path, token, parent_id)
        except Exception as e:  # noqa: BLE001 — keep going on per-chapter errors
            print(f"  ✗ {path.name} failed: {e}", file=sys.stderr)
            continue
        index.append(entry)
        INDEX_PATH.write_text(
            json.dumps(index, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        time.sleep(0.4)  # stay well under Notion's 3 req/s limit

    index.sort(key=lambda e: e["chapterNo"])
    INDEX_PATH.write_text(
        json.dumps(index, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"done: {len(index)} entries in {INDEX_PATH}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
