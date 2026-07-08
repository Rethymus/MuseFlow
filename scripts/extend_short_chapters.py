#!/usr/bin/env python3
"""Extend any generated chapter that fell below the 7000-CJK-char floor.

The lean per-chapter segment cap (5) plus GLM output variance means a small
number of chapters can land below the 6500-char lower tolerance. This script
scans docs/novel-journey/chapters/*.md and continuation-extends any chapter
whose CJK count is under [target] (default 7000) until it reaches the target,
then trims back to ≤9000. It rewrites the Markdown files in place.

Decoupled from the Dart harness: it calls GLM directly via urllib and edits the
chapter files, so it can run after the generator finishes without the Hive
container. Only the chapter prose is affected; metrics.json records the
originally-generated counts and is left untouched (the README reports both the
generation metric and the post-extend compliance pass).

Usage:
  GLM_API_KEY=... python3 scripts/extend_short_chapters.py [--target 7000] [--dry-run]
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CHAPTERS = ROOT / "docs" / "novel-journey" / "chapters"
API = "https://open.bigmodel.cn/api/paas/v4/chat/completions"
MODEL = "glm-4-flash"
CJK = re.compile(r"[一-鿿㐀-䶵]")

PERSONA = (
    "你是一位技艺精湛的中文修仙小说家，文笔凝练、画面感强、善用留白与节奏。"
    "以动作、感官、白描推进；不堆砌副词叠词，不用套话转场。只输出正文。"
)
WORLD = (
    "世界观：青云宗修仙界。主角林风（凡人出身，修无名功法，契约灵狐白灵）；"
    "苏雪晴（大师姐，藏上古剑修血脉）；赵天磊（同门，先敌后友）；"
    "清虚真人（师尊，上古大能转世）；王磊（内门反派，勾结暗影门）。"
)


def cjk_count(s: str) -> int:
    return len(CJK.findall(s))


def call_glm(messages: list[dict], key: str) -> str:
    body = json.dumps(
        {"model": MODEL, "messages": messages, "temperature": 0.8, "max_tokens": 4096}
    ).encode()
    req = urllib.request.Request(
        API,
        data=body,
        headers={
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
        },
    )
    for attempt in range(1, 5):
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                data = json.loads(resp.read().decode())
            return data["choices"][0]["message"]["content"].strip()
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < 4:
                time.sleep(2 ** attempt)
                continue
            raise RuntimeError(f"GLM {e.code}: {e.read().decode()[:300]}") from None
    raise RuntimeError("GLM unreachable")


def trim_to_range(text: str, lo: int = 7000, hi: int = 9000) -> str:
    if cjk_count(text) <= hi:
        return text
    boundaries = "。！？!?\n"
    runes = list(text)
    running = 0
    best_end = -1
    last_end = -1
    for i, ch in enumerate(runes):
        if CJK.match(ch):
            running += 1
        if ch in boundaries:
            last_end = i + 1
            if lo <= running <= hi:
                best_end = i + 1
        if running > hi:
            break
    end = best_end if best_end > 0 else last_end
    return text[:end] if end > 0 else text


def extend_chapter(path: Path, target: int, key: str, dry_run: bool) -> bool:
    raw = path.read_text(encoding="utf-8")
    lines = raw.splitlines()
    head = lines[0] if lines and lines[0].startswith("# ") else f"# {path.stem}"
    body = "\n".join(lines[1:]).strip()
    if cjk_count(body) >= target:
        return False
    rounds = 0
    while cjk_count(body) < target and rounds < 4:
        rounds += 1
        tail = body[-1500:]
        messages = [
            {"role": "system", "content": f"{PERSONA}\n\n{WORLD}"},
            {
                "role": "user",
                "content": (
                    f"以下是小说《剑道苍穹》一章正文的结尾部分：\n\"\"\"\n{tail}\n\"\"\"\n"
                    "请紧接上文续写约2000字，展开新的场景细节、对话、动作与心理，"
                    "保持文风与人称一致。不要复述、不要写“续”或“接上”、不要收尾总结。"
                    "（硬性要求：本段不少于1800中文字，不足请继续写到1800字以上。）"
                ),
            },
        ]
        chunk = call_glm(messages, key)
        if not chunk:
            break
        body = trim_to_range(body + "\n" + chunk)
    final = f"{head}\n\n{body}\n"
    print(f"  {path.name}: {cjk_count(raw)} -> {cjk_count(final)} CJK ({rounds} 轮)")
    if not dry_run:
        path.write_text(final, encoding="utf-8")
    return True


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--target", type=int, default=7000)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    key = __import__("os").environ.get("GLM_API_KEY")
    if not key:
        print("GLM_API_KEY required", file=sys.stderr)
        return 2
    if not CHAPTERS.is_dir():
        print(f"no chapters dir {CHAPTERS}", file=sys.stderr)
        return 2
    files = sorted(CHAPTERS.glob("第*章-*.md"))
    short = [p for p in files if cjk_count(p.read_text(encoding="utf-8")) < args.target]
    print(f"{len(short)}/{len(files)} chapters below {args.target} CJK — extending")
    changed = 0
    for p in short:
        try:
            if extend_chapter(p, args.target, key, args.dry_run):
                changed += 1
        except Exception as e:  # noqa: BLE001
            print(f"  {p.name} FAILED: {e}", file=sys.stderr)
        time.sleep(1.0)
    print(f"done: {changed} chapters extended{' (dry-run)' if args.dry_run else ''}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
