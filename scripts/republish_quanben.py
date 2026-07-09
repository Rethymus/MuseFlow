#!/usr/bin/env python3
"""Re-publish the FULL 剑道苍穹 text (from 全本.md) to its Notion pages.

The xianxia Notion pages currently hold ~1800-char excerpts; the full novel
(821k CJK) lives in 剑道苍穹-全本.md. This splits 全本 by `# 第N章 标题`
markers and pushes each full chapter to the matching Notion page (clear +
append), so the Notion content matches the real novel and word counts are
accurate.

Usage:
  NOTION_TOKEN=... python3 scripts/republish_quanben.py
  NOTION_TOKEN=... python3 scripts/republish_quanben.py --chapters 1,2,3
"""
from __future__ import annotations
import json, os, re, sys, time, urllib.error, urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOKEN = os.environ["NOTION_TOKEN"]
API = "https://api.notion.com/v1"
HDR = {"Authorization": f"Bearer {TOKEN}", "Notion-Version": "2022-06-28", "Content-Type": "application/json"}
QUANBEN = ROOT / "docs" / "novel-journey" / "剑道苍穹-全本.md"
INDEX = ROOT / "docs" / "novel-journey" / "notion_index.json"
CHUNK = 1900
BATCH = 100


def req(method: str, path: str, body=None):
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(f"{API}{path}", data=data, method=method, headers=HDR)
    for att in range(1, 6):
        try:
            with urllib.request.urlopen(r, timeout=60) as resp:
                return json.loads(resp.read().decode())
        except urllib.error.HTTPError as e:
            if e.code == 429 and att < 5:
                time.sleep(2 ** att); continue
            raise RuntimeError(f"{method} {path} -> {e.code}: {e.read().decode()[:200]}")
        except (urllib.error.URLError, TimeoutError, OSError) as e:
            if att < 5:
                time.sleep(3 * att); continue
            raise


def split_quanben() -> dict[int, str]:
    """Return {chapter_no: chapter_body_text} split by `# 第N章 标题` markers."""
    text = QUANBEN.read_text(encoding="utf-8")
    # Find all chapter heading positions: lines like "# 第1章 凡人少年"
    marks = [(m.start(), int(m.group(1))) for m in re.finditer(r"^#\s*第(\d+)章", text, re.M)]
    marks.sort()
    out = {}
    for i, (pos, no) in enumerate(marks):
        end = marks[i + 1][0] if i + 1 < len(marks) else len(text)
        body = text[pos:end]
        # Drop the leading "# 第N章 标题" heading line (Notion page already has the title)
        body = re.sub(r"^#\s*第\d+章[^\n]*\n+", "", body, count=1).strip()
        out[no] = body
    return out


def clear_page(page_id: str) -> int:
    archived = 0
    cursor = None
    while True:
        qs = f"?page_size=100" + (f"&start_cursor={cursor}" if cursor else "")
        d = req("GET", f"/blocks/{page_id}/children{qs}")
        for b in d.get("results", []):
            try:
                req("PATCH", f"/blocks/{b['id']}", {"archived": True})
                archived += 1
                time.sleep(0.1)
            except RuntimeError as e:
                print(f"    archive failed: {e}", file=sys.stderr)
        if not d.get("has_more"):
            break
        cursor = d.get("next_cursor")
    return archived


def pieces(body: str) -> list[str]:
    out = []
    for para in re.split(r"\n{2,}", body):
        para = para.strip()
        if not para:
            continue
        while len(para) > CHUNK:
            cut = max((para.rfind(s, 0, CHUNK) for s in "。！？；，、 " if para.rfind(s, 0, CHUNK) > CHUNK // 2), default=-1)
            cut = cut + 1 if cut > 0 else CHUNK
            out.append(para[:cut].strip()); para = para[cut:].strip()
        if para:
            out.append(para)
    return out


def append(page_id: str, body: str) -> int:
    blocks = [{"object": "block", "type": "paragraph",
               "paragraph": {"rich_text": [{"type": "text", "text": {"content": p}}]}} for p in pieces(body)]
    n = 0
    for i in range(0, len(blocks), BATCH):
        req("PATCH", f"/blocks/{page_id}/children", {"children": blocks[i:i + BATCH]})
        n += len(blocks[i:i + BATCH]); time.sleep(0.4)
    return n


def main():
    chapters = split_quanben()
    index = json.loads(INDEX.read_text(encoding="utf-8"))
    by_no = {e["chapterNo"]: e for e in index}
    sel = None
    if "--chapters" in sys.argv:
        sel = set(int(x) for x in sys.argv[sys.argv.index("--chapters") + 1].split(","))
    # Resume support: skip chapters already pushed (progress file).
    PROG = ROOT / "docs" / "novel-journey" / "republish_progress.json"
    done = set()
    if PROG.exists():
        done = set(json.loads(PROG.read_text(encoding="utf-8")).get("done", []))
    targets = sorted(n for n in by_no if (sel is None or n in sel) and n not in done)
    print(f"republishing 全本 -> {len(targets)} xianxia Notion pages (skipping {len(done)} already done)")
    for no in targets:
        e = by_no[no]
        body = chapters.get(no, "")
        if not body:
            print(f"  ch{no}: 全本未找到该章，跳过", file=sys.stderr); continue
        try:
            cleared = clear_page(e["page_id"])
            appended = append(e["page_id"], body)
            import re as _re
            cjk = len(_re.findall(r"[一-鿿㐀-䶵]", body))
            print(f"  ✓ ch{no:>3} cleared={cleared} appended={appended} ({cjk} CJK)", flush=True)
            done.add(no)
            PROG.write_text(json.dumps({"done": sorted(done)}), encoding="utf-8")
        except Exception as ex:
            print(f"  ✗ ch{no} failed: {ex}", file=sys.stderr, flush=True)
        time.sleep(0.5)
    print(f"done; {len(done)}/100 pushed", flush=True)


if __name__ == "__main__":
    raise SystemExit(main())
