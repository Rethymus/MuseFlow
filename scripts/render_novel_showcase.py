#!/usr/bin/env python3
"""Render the README "用户旅程实测" markdown fragment from run artifacts.

Reads:
  docs/novel-journey/metrics.json        (written by long_novel_journey_test.dart)
  docs/novel-journey/notion_index.json   (written by publish_novel_to_notion.py)
  docs/novel-journey/chapters/*.md       (for excerpt selection)

Writes:
  docs/novel-journey/showcase.md         (README-ready fragment)

Cost is an ESTIMATE using the pricing assumptions in PRICING (CNY per million
tokens). These are publicly known ballparks; the README labels them as such
and the authoritative metric is the recorded token count, not the cost.
"""

from __future__ import annotations

import json
import os
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
# NOVEL_DIR lets a second novel (e.g. "novel-go") reuse this renderer. Default
# unchanged so the original "novel-journey" (xianxia) showcase is unaffected.
NOVEL_DIR_NAME = os.environ.get("NOVEL_DIR", "novel-journey")
NOVEL = ROOT / "docs" / NOVEL_DIR_NAME
METRICS = NOVEL / "metrics.json"
INDEX = NOVEL / "notion_index.json"
CHAPTERS = NOVEL / "chapters"
OUT = NOVEL / "showcase.md"

# CNY per 1,000,000 tokens. Clearly an assumption; tune as official pricing moves.
PRICING = {
    "glm-4-flash": {"input": 0.1, "output": 0.1},
    "glm-4-plus": {"input": 50.0, "output": 50.0},
}

# Curated "highlight" chapters for excerpting in the README — the narrative
# spine: opening, each arc's climax, and the finale. Override per novel via the
# HIGHLIGHTS env var (comma-separated), e.g. HIGHLIGHTS=1,12,33,50,66,88,99,100
# for the Go novel's three-arc climaxes.
HIGHLIGHTS = [
    int(x) for x in os.environ.get("HIGHLIGHTS", "1,30,50,75,85,100").split(",")
    if x.strip()
]

CJK = re.compile(r"[一-鿿㐀-䶵]")


def cjk_count(s: str) -> int:
    return len(CJK.findall(s))


def markdown_body(raw: str) -> str:
    lines = raw.splitlines()
    if lines and lines[0].startswith("# "):
        return "\n".join(lines[1:]).strip()
    return raw.strip()


def canonical_chapter_paths() -> list[Path]:
    return sorted(
        p for p in CHAPTERS.glob("第*章-*.md") if not p.name.endswith(".polished.md")
    )


def display_title(title: str) -> str:
    """Strip a leading "第N章 " prefix — the chapter title carries it, but the
    renderer adds its own chapter number, so we'd otherwise print it twice."""
    return (re.sub(r'^第\d+章\s*', '', title).strip()) or title


def fmt(n) -> str:
    return f"{n:,}"


def cost_breakdown(metrics: dict) -> tuple[float, list[str]]:
    lines = []
    total = 0.0
    by_model = metrics.get("tokens", {}).get("byModel", {})
    for model, vals in by_model.items():
        rate = PRICING.get(model, {"input": 0.0, "output": 0.0})
        inp = vals.get("input", 0)
        out = vals.get("output", 0)
        c = inp / 1_000_000 * rate["input"] + out / 1_000_000 * rate["output"]
        total += c
        lines.append(
            f"| {model} | {fmt(vals.get('calls', 0))} | {fmt(inp)} | {fmt(out)} "
            f"| ¥{rate['input']:.2f} / ¥{rate['output']:.2f} | ¥{c:.2f} |"
        )
    return total, lines


def load_chapter(chapter_no: int) -> tuple[str, str] | None:
    if not CHAPTERS.is_dir():
        return None
    for p in CHAPTERS.glob(f"第{chapter_no:03d}章-*.md"):
        raw = p.read_text(encoding="utf-8")
        lines = raw.splitlines()
        title = lines[0][2:].strip() if lines and lines[0].startswith("# ") else p.stem
        body = markdown_body(raw)
        return title, body
    return None


def pick_excerpt(body: str, target: int = 320) -> str:
    """Pick a single readable ~target-char passage (one or two vivid paragraphs)."""
    paras = [p.strip() for p in re.split(r"\n{2,}", body) if p.strip()]
    paras = [p for p in paras if len(p) > 40]  # drop dialogue fragments
    if not paras:
        return body[:target]
    # Prefer a paragraph that contains a strong sensory verb / dialogue marker.
    candidates = [
        p for p in paras[1:] if any(k in p for k in ("，", "。", "——", "：「", "」"))
    ] or paras[1:]
    pick = candidates[0] if candidates else paras[0]
    if cjk_count(pick) > target + 80:
        # Cut at a sentence boundary near the target length.
        for i, ch in enumerate(pick):
            if ch in "。！？" and cjk_count(pick[: i + 1]) >= target - 80:
                pick = pick[: i + 1]
                break
    return pick


def notion_url(index: list[dict], chapter_no: int) -> str:
    for e in index:
        if e.get("chapterNo") == chapter_no:
            return e.get("public_url") or e.get("url") or ""
    return ""


def main() -> int:
    if not METRICS.exists():
        print("metrics.json not found — run the generator first", flush=True)
        return 2
    metrics = json.loads(METRICS.read_text(encoding="utf-8"))
    index = json.loads(INDEX.read_text(encoding="utf-8")) if INDEX.exists() else []

    length = metrics.get("length", {})
    timing = metrics.get("timing", {})
    tokens = metrics.get("tokens", {})
    anti = metrics.get("antiAi", {})
    dev = metrics.get("deviation", {})
    fore = metrics.get("foreshadowing", {})
    strat = metrics.get("modelStrategy", {})

    cost_total, cost_lines = cost_breakdown(metrics)

    # Final length stats from the chapter files on disk (after the optional
    # compliance pass that extends sub-floor chapters). Authoritative for the
    # "in spec" claim.
    files_on_disk = canonical_chapter_paths() if CHAPTERS.is_dir() else []
    final_counts = [
        cjk_count(markdown_body(p.read_text(encoding="utf-8")))
        for p in files_on_disk
    ]
    if final_counts:
        f_total, f_avg = sum(final_counts), sum(final_counts) // len(final_counts)
        f_min, f_max = min(final_counts), max(final_counts)
        under_7000 = sum(1 for c in final_counts if c < 7000)
    else:
        f_total = length.get("totalCjkChars", 0)
        f_avg = length.get("avgCjkCharsPerChapter", 0)
        f_min = length.get("minCjkChars", 0)
        f_max = length.get("maxCjkChars", 0)
        under_7000 = 0

    md = []
    md.append("### 规模与字数\n")
    ending_note = metrics.get(
        "endingNote", "未完结于百章内、于第 100 章飞升收束"
    )
    md.append(
        f"- **章节数**：{metrics.get('chapterCount', 0)} 章（当前仓库托管正文，{ending_note}）\n"
    )
    md.append(
        f"- **总字数（去标点 CJK）**：{fmt(f_total)} 字 · 平均 {fmt(f_avg)} 字/章 "
        f"· 区间 [{fmt(f_min)}, {fmt(f_max)}]\n"
    )
    md.append(
        f"- **当前正文分布**：{under_7000}/{len(final_counts) or metrics.get('chapterCount', 0)} 章低于 7000 CJK；"
        "章节字数统计直接取自仓库当前正文。\n"
    )

    md.append("\n### 耗时与成本\n")
    md.append(
        f"- **总耗时**：{timing.get('wallClockHuman', '?')}（平均 "
        f"{timing.get('avgSecondsPerChapter', '?')} 秒/章）\n"
    )
    md.append(
        f"- **Token 消耗**：输入 {fmt(tokens.get('input', 0))} · "
        f"输出 {fmt(tokens.get('output', 0))} · 合计 {fmt(tokens.get('total', 0))} "
        f"（{fmt(tokens.get('totalCalls', 0))} 次 API 调用）\n"
    )
    md.append("- **模型搭配**（高性能＋低开销混用）：")
    md.append(
        f"  {strat.get('highPerf','glm-4-plus')} 用于 {len(strat.get('keyChaptersOpenedWithHighPerf', []))} "
        f"个关键章（开篇/高潮/收束）的开篇；"
        f"{strat.get('lowCost','glm-4-flash')} 承担其余开篇与全部续写、守护、摘要\n"
    )
    md.append("\n| 模型 | 调用次数 | 输入 token | 输出 token | 单价(输入/输出,¥/百万) | 估算成本 |\n")
    md.append("|---|---:|---:|---:|---|---:|\n")
    md.extend(line + "\n" for line in cost_lines)
    md.append(f"| **合计** | **{fmt(tokens.get('totalCalls', 0))}** | "
              f"**{fmt(tokens.get('input', 0))}** | **{fmt(tokens.get('output', 0))}** | — | "
              f"**¥{cost_total:.2f}** |\n")
    md.append("\n> 成本为按公开定价假设的估算（见脚本 `PRICING`），以智谱官方为准；"
              "权威指标为实测 Token 数。\n")

    md.append("\n### 反 AI 味 · 一致性守护 · 伏笔填坑\n")
    md.append(
        f"- **反 AI 味**：全册标记 {fmt(anti.get('totalHighlights', 0))} 处 AI 腔征兆，"
        f"其中 {fmt(anti.get('totalAutoReplaced', 0))} 处由同义词表自动净化，"
        f"其余进入作者复核信号\n"
    )
    top = anti.get("topSignals", [])[:5]
    if top:
        md.append("  - 高频信号：" + "、".join(f"{s['signal']}（{s['count']}）" for s in top) + "\n")
    md.append(
        f"- **Skill 守护（设定一致性）**：全册触发 {fmt(dev.get('totalWarnings', 0))} "
        f"条偏离告警，由偏差检测在生成侧即时拦截\n"
    )
    md.append(
        f"- **伏笔填坑**：埋设 {fore.get('planted', 0)} 条长线伏笔，"
        f"回收 {fore.get('resolved', 0)} 条，"
        f"填坑率 {float(fore.get('fillRate', 0))*100:.0f}%，"
        f"平均 {fore.get('avgChaptersToResolve', '?')} 章回收\n"
    )

    md.append("\n### 精选章节摘录（文笔/高潮）\n")
    md.append("从叙事脊梁（开篇 / 各弧高潮 / 飞升）中各挑一段，完整正文见下方目录。\n\n")
    for ch in HIGHLIGHTS:
        loaded = load_chapter(ch)
        url = notion_url(index, ch)
        if not loaded:
            continue
        title, body = loaded
        excerpt = pick_excerpt(body)
        link = f"（[Notion 全文]({url})）" if url else ""
        md.append(f"> **第{ch}章 · {display_title(title)}**{link}\n>\n")
        for line in excerpt.splitlines():
            md.append(f"> {line}\n")
        md.append("\n")

    md.append("### 章节目录与正文\n")
    md.append("每章正文以独立 Notion 页面托管，亦可阅读仓库 Markdown。\n\n")
    md.append("| 章 | 标题 | 字数 | 正文 |\n|---:|---|---:|---|\n")
    if CHAPTERS.is_dir():
        notion_by_no = {e.get("chapterNo"): e for e in index}
        for p in canonical_chapter_paths():
            m = re.search(r"第0*(\d+)章", p.stem)
            no = int(m.group(1)) if m else 0
            raw = p.read_text(encoding="utf-8")
            lines = raw.splitlines()
            title = lines[0][2:].strip() if lines and lines[0].startswith("# ") else p.stem
            wc = cjk_count(markdown_body(raw))
            repo = f"[Markdown](docs/{NOVEL_DIR_NAME}/chapters/{p.name})"
            extra = ""
            e = notion_by_no.get(no)
            if e:
                url = e.get("public_url") or e.get("url")
                if url:
                    extra = f" · [Notion]({url})"
            md.append(f"| {no} | {display_title(title)} | {fmt(wc)} | {repo}{extra} |\n")

    OUT.write_text("".join(md), encoding="utf-8")
    print(f"wrote {OUT} ({len(index)} notion links, cost ¥{cost_total:.2f})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
