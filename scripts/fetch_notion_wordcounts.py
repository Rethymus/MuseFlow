#!/usr/bin/env python3
"""Fetch each chapter's REAL word count from Notion (count CJK in actual page content).

For each page in a notion_index.json, GET its child blocks, concatenate all
rich_text content, count CJK chars (excludes punctuation). This is the
"真实字数" as it appears on Notion — which differs from repo .md files when
the repo holds excerpts (xianxia) or pre/post-polish versions.

Usage:
  NOTION_TOKEN=... python3 scripts/fetch_notion_wordcounts.py
  # processes both novel-go and novel-journey; writes notion_wordcounts.json each.
"""
from __future__ import annotations
import json, os, re, sys, time, urllib.request, urllib.error
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOKEN = os.environ["NOTION_TOKEN"]
CJK = re.compile(r"[一-鿿㐀-䶵]")
API = "https://api.notion.com/v1"
HDR = {"Authorization": f"Bearer {TOKEN}", "Notion-Version": "2022-06-28"}
NOVELS = {
    "novel-go": ROOT / "docs" / "novel-go",
    "novel-journey": ROOT / "docs" / "novel-journey",
}


def req(method: str, path: str) -> dict:
    url = f"{API}{path}"
    for attempt in range(1, 6):
        try:
            r = urllib.request.Request(url, method=method, headers=HDR)
            with urllib.request.urlopen(r, timeout=30) as resp:
                return json.loads(resp.read().decode())
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < 5:
                time.sleep(2 ** attempt); continue
            raise
        except (urllib.error.URLError, TimeoutError, OSError) as e:
            if attempt < 5:
                time.sleep(3 * attempt); continue
            raise


def block_text(block: dict) -> str:
    """Concatenate all rich_text content from a block (paragraph/heading/etc)."""
    parts = []
    for btype, bdata in block.items():
        if not isinstance(bdata, dict):
            continue
        rt = bdata.get("rich_text") or bdata.get("text")
        if isinstance(rt, list):
            for seg in rt:
                if isinstance(seg, dict):
                    t = seg.get("plain_text")
                    if t:
                        parts.append(t)
    return "".join(parts)


def page_cjk(page_id: str) -> int:
    total = 0
    cursor = None
    for _ in range(20):  # paginate (100/page; chapters rarely exceed 2 pages)
        qs = f"?page_size=100" + (f"&start_cursor={cursor}" if cursor else "")
        d = req("GET", f"/blocks/{page_id}/children{qs}")
        for block in d.get("results", []):
            total += len(CJK.findall(block_text(block)))
        if not d.get("has_more"):
            break
        cursor = d.get("next_cursor")
    return total


def fetch_novel(name: str, novel_dir: Path) -> list[dict]:
    idx_path = novel_dir / "notion_index.json"
    out_path = novel_dir / "notion_wordcounts.json"
    index = json.loads(idx_path.read_text(encoding="utf-8"))
    existing = {}
    if out_path.exists():
        existing = {e["chapterNo"]: e for e in json.loads(out_path.read_text(encoding="utf-8"))}
    results = []
    for i, e in enumerate(sorted(index, key=lambda x: x["chapterNo"])):
        no = e["chapterNo"]
        if no in existing:
            results.append(existing[no]); continue
        try:
            c = page_cjk(e["page_id"])
            results.append({"chapterNo": no, "title": e["title"],
                            "public_url": e.get("public_url") or e.get("url", ""),
                            "cjk": c})
            print(f"  [{name}] 第{no:>3}章 {c} CJK", flush=True)
        except Exception as ex:
            print(f"  [{name}] 第{no}章 FAILED: {ex}", file=sys.stderr, flush=True)
            results.append({"chapterNo": no, "title": e["title"],
                            "public_url": e.get("public_url") or e.get("url", ""), "cjk": -1})
        # incremental save every 5 chapters
        if no % 5 == 0:
            out_path.write_text(json.dumps(sorted(results, key=lambda x: x["chapterNo"]),
                                            ensure_ascii=False, indent=2), encoding="utf-8")
        time.sleep(0.35)  # stay under Notion ~3 req/s
    results.sort(key=lambda x: x["chapterNo"])
    out_path.write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
    ok = [r["cjk"] for r in results if r["cjk"] >= 0]
    if ok:
        print(f"[{name}] done: {len(ok)}/{len(results)} ok · 总{sum(ok)} 均{sum(ok)//len(ok)} "
              f"区间[{min(ok)},{max(ok)}]", flush=True)
    return results


if __name__ == "__main__":
    for name, d in NOVELS.items():
        if (d / "notion_index.json").exists():
            print(f"=== {name} ===", flush=True)
            fetch_novel(name, d)
