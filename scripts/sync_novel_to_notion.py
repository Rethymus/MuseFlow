#!/usr/bin/env python3
"""Sync polished chapter content into existing Notion pages.

After `polish_chapters.py --all` overwrites the in-repo Markdown, run this to
push the new content to the corresponding Notion pages created earlier by
`publish_novel_to_notion.py`. For each chapter it:
  1. archives every existing child block of the page (clears old content), and
  2. appends the polished prose as fresh paragraph blocks.

Notion block text is capped at 2000 chars and a children request at 100 blocks,
so long chapters are split into ≤1900-char paragraph pieces, chunked into
batches of 100 appends.

Usage:
  NOTION_TOKEN=... python3 scripts/sync_novel_to_notion.py
  NOTION_TOKEN=... python3 scripts/sync_novel_to_notion.py --chapters 39,67
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
ROOT = Path(__file__).resolve().parent.parent
# NOVEL_DIR lets a second novel (e.g. "novel-go") reuse this script. Default
# unchanged so the original "novel-journey" (xianxia) pipeline is unaffected.
NOVEL_DIR = os.environ.get("NOVEL_DIR", "novel-journey")
CHAPTERS = ROOT / "docs" / NOVEL_DIR / "chapters"
INDEX = ROOT / "docs" / NOVEL_DIR / "notion_index.json"
CHUNK = 1900
BLOCK_BATCH = 100


def _req(method: str, path: str, token: str, body: dict | None = None) -> dict:
    url = f"{API}{path}"
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(
        url, data=data, method=method,
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
                time.sleep(2 ** attempt)
                continue
            raise RuntimeError(f"NOTION {method} {path} -> {e.code}: {e.read().decode()[:300]}") from None
    raise RuntimeError("unreachable")


def clear_page(page_id: str, token: str) -> int:
    """Archive every existing child block of the page. Returns count archived."""
    archived = 0
    cursor = None
    while True:
        qs = f"?start_cursor={cursor}" if cursor else ""
        data = _req("GET", f"/blocks/{page_id}/children{qs}", token)
        for block in data.get("results", []):
            try:
                _req("PATCH", f"/blocks/{block['id']}", token, {"archived": True})
                archived += 1
                time.sleep(0.12)  # stay under Notion's ~3 req/s
            except RuntimeError as e:
                print(f"    archive block failed: {e}", file=sys.stderr)
        if not data.get("has_more"):
            break
        cursor = data.get("next_cursor")
    return archived


def _pieces(body: str) -> list[str]:
    out = []
    for para in re.split(r"\n{2,}", body):
        para = para.strip()
        if not para:
            continue
        while len(para) > CHUNK:
            cut = max(
                (para.rfind(sep, 0, CHUNK) for sep in "。！？；，、 " if para.rfind(sep, 0, CHUNK) > CHUNK // 2),
                default=-1,
            )
            if cut <= 0:
                cut = CHUNK
            else:
                cut += 1
            out.append(para[:cut].strip())
            para = para[cut:].strip()
        if para:
            out.append(para)
    return out


def append_content(page_id: str, body: str, token: str) -> int:
    blocks = [
        {
            "object": "block",
            "type": "paragraph",
            "paragraph": {"rich_text": [{"type": "text", "text": {"content": piece}}]},
        }
        for piece in _pieces(body)
    ]
    appended = 0
    for i in range(0, len(blocks), BLOCK_BATCH):
        batch = blocks[i : i + BLOCK_BATCH]
        _req("PATCH", f"/blocks/{page_id}/children", token, {"children": batch})
        appended += len(batch)
        time.sleep(0.4)
    return appended


def sync_chapter(path: Path, page_id: str, token: str) -> tuple[int, int]:
    raw = path.read_text(encoding="utf-8")
    lines = raw.splitlines()
    body = "\n".join(lines[1:]).strip()
    cleared = clear_page(page_id, token)
    appended = append_content(page_id, body, token)
    return cleared, appended


def main() -> int:
    token = os.environ.get("NOTION_TOKEN")
    if not token:
        print("NOTION_TOKEN required", file=sys.stderr)
        return 2
    if not INDEX.exists():
        print(f"missing {INDEX} (run publish_novel_to_notion.py first)", file=sys.stderr)
        return 2
    index = json.loads(INDEX.read_text(encoding="utf-8"))
    sel = None
    if "--chapters" in sys.argv:
        sel = set(int(x) for x in sys.argv[sys.argv.index("--chapters") + 1].split(","))

    by_no = {e["chapterNo"]: e for e in index}
    targets = []
    for no in sorted(by_no):
        if sel and no not in sel:
            continue
        e = by_no[no]
        p = CHAPTERS / e["file"]
        if not p.exists():
            print(f"  skip ch{no}: file missing {e['file']}", file=sys.stderr)
            continue
        targets.append((no, e, p))

    print(f"syncing {len(targets)} chapters to Notion")
    for no, e, p in targets:
        try:
            cleared, appended = sync_chapter(p, e["page_id"], token)
            print(f"  ✓ ch{no:>3} {e['file'][:24]}  cleared={cleared} appended={appended}")
        except Exception as ex:  # noqa: BLE001
            print(f"  ✗ ch{no} failed: {ex}", file=sys.stderr)
        time.sleep(0.5)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
