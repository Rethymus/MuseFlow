#!/usr/bin/env python3
"""Audit the generated novel for repetition / padding / LLM artifacts.

For each chapter under docs/novel-journey/chapters/, score:
  - title-echo artifact (first body line re-states the chapter heading)
  - exact duplicate sentences
  - most-repeated CJK 4-gram and 8-gram (padding tell)
  - lexical diversity (unique CJK / total CJK; low = repetitive vocab)
  - garbled characters (U+FFFD / isolated broken chars)

Prints chapters worst-first so the polish pass knows what to rewrite.
"""

from __future__ import annotations

import os
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
NOVEL_DIR_NAME = os.environ.get("NOVEL_DIR", "novel-journey")
CHAPTERS = ROOT / "docs" / NOVEL_DIR_NAME / "chapters"
CJK = re.compile(r"[一-鿿㐀-䶵]")


def cjk_chars(s: str) -> list[str]:
    return CJK.findall(s)


def ngrams(seq: list[str], n: int) -> Counter:
    return Counter(tuple(seq[i : i + n]) for i in range(len(seq) - n + 1))


def audit_file(path: Path) -> dict:
    raw = path.read_text(encoding="utf-8")
    lines = raw.splitlines()
    body = "\n".join(lines[1:]).strip()
    title = lines[0][2:].strip() if lines and lines[0].startswith("# ") else path.stem
    chars = cjk_chars(body)
    total = len(chars)
    if total == 0:
        return {"file": path.name, "total": 0}

    # Title-echo: first body line repeats the heading.
    first_line = body.splitlines()[0] if body else ""
    title_echo = bool(
        re.search(r"本章《|第\d+章.*第\d+章", first_line)
    ) or first_line.strip().lstrip("#").strip() == title

    # Duplicate sentences (split on terminal punctuation).
    sentences = [s.strip() for s in re.split(r"[。！？!?]", body) if len(s.strip()) >= 8]
    dup_sentences = sum(c - 1 for c in Counter(sentences).values() if c > 1)

    # Repeated n-grams (padding). Use char n-grams over CJK only.
    top4 = ngrams(chars, 4).most_common(1)
    top4_count = top4[0][1] if top4 else 0
    top8 = ngrams(chars, 8).most_common(1)
    top8_count = top8[0][1] if top8 else 0

    # Lexical diversity.
    diversity = len(set(chars)) / total if total else 0

    # Garbled chars.
    garbled = raw.count("�")

    # Repetition score: combine dup sentences + n-gram repeats + low diversity.
    # Higher = worse.
    score = (
        dup_sentences * 3
        + max(0, top4_count - 8) * 1.5
        + max(0, top8_count - 4) * 4
        + max(0, 0.62 - diversity) * 120  # diversity below 0.62 is repetitive
        + (10 if title_echo else 0)
        + garbled * 5
    )
    return {
        "file": path.name,
        "title_echo": title_echo,
        "dup_sentences": dup_sentences,
        "top4": top4_count,
        "top8": top8_count,
        "diversity": round(diversity, 3),
        "garbled": garbled,
        "total": total,
        "score": round(score, 1),
    }


def main() -> int:
    files = sorted(CHAPTERS.glob("第*章-*.md"))
    rows = [audit_file(p) for p in files]
    rows.sort(key=lambda r: r["score"], reverse=True)
    print(f"{'score':>6} {'dup':>4} {'4gr':>4} {'8gr':>4} {'div':>5} {'echo':>5} {'garb':>4}  chapter")
    print("-" * 70)
    for r in rows[:35]:
        echo = "Y" if r["title_echo"] else "."
        print(
            f"{r['score']:>6} {r['dup_sentences']:>4} {r['top4']:>4} {r['top8']:>4} "
            f"{r['diversity']:>5} {echo:>5} {r['garbled']:>4}  {r['file']}"
        )
    flagged = [r for r in rows if r["score"] >= 12 or r["title_echo"] or r["garbled"] > 0]
    echo_n = sum(1 for r in rows if r["title_echo"])
    garb_n = sum(1 for r in rows if r["garbled"] > 0)
    print(f"\n共 {len(rows)} 章；标题回声 {echo_n} 章；乱码 {garb_n} 章；需润色(score≥12 或 echo/乱码) {len(flagged)} 章")
    print("需润色章节号:", [int(re.search(r'第0*(\d+)章', r['file']).group(1)) for r in flagged])
    return 0


if __name__ == "__main__":
    sys.exit(main())
