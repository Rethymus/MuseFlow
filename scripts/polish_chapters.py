#!/usr/bin/env python3
"""Polish-rewrite generated chapters to remove repetition/padding and lift prose.

Each chapter is rewritten in contiguous ~2000-CJK-char chunks: every chunk is
handed to GLM together with the rewritten-so-far tail, with a brief to delete
repetition, pursue inventive prose, let dialogue carry edge / dry humor, and
allow rare, restrained fourth-wall touches. Plot, canon and foreshadowing are
preserved. Output stays in the 7000–9000 CJK range.

Usage:
  GLM_API_KEY=... python3 scripts/polish_chapters.py --chapters 39 --preview
  GLM_API_KEY=... python3 scripts/polish_chapters.py --all --model glm-4-plus

--preview writes 第NNN章-名.polished.md next to the original (no overwrite);
without it the original chapter file is replaced in place.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
NOVEL_DIR_NAME = os.environ.get("NOVEL_DIR", "novel-journey")
CHAPTERS = ROOT / "docs" / NOVEL_DIR_NAME / "chapters"
API = "https://open.bigmodel.cn/api/paas/v4/chat/completions"
CJK = re.compile(r"[一-鿿㐀-䶵]")

# Theme presets: each polish run targets one novel. Select via --theme.
# Add a new novel by adding a preset here (title + persona + style).
THEMES: dict[str, dict[str, str]] = {
    "xianxia": {
        "title": "剑道苍穹",
        "persona": (
            "你是一位才华横溢、风格独具的中文修仙小说家，师承余华、王小波一路的当代汉语，"
            "善用白描、短句与冷锋。你正在把一段AI初稿彻底重写——不是润色，是重写。"
        ),
        "style": (
            "【重写要求】\n"
            "1. 删除一切重复、注水、套话与机械对话；情节与因果保留，语言焕然一新。\n"
            "2. 文笔求突破：画面具体、感官落地、节奏多变、句子有锋芒；忌排比堆砌、忌陈词滥调。\n"
            "3. 对话要活：贴合人物、有潜台词、可带冷幽默或机锋，拒绝工具人台词。\n"
            "4. 整体仍是修仙长篇的厚重质感；极少数关键时刻可轻触第四面墙"
            "（角色对'天数''命数''此章''剧情'的微妙自觉），但必须自然、克制、为效果服务，不滥用。\n"
            "5. 严守世界观与人物设定，不得OOC；伏笔不变。\n"
            "6. 只输出正文，不要标题、不要分点、不要解释、不要复述初稿、不要'接上'之类提示。\n"
            "7. 篇幅保持：重写每一段后字数不少于原段——删的是重复注水，可补新的细节、感官、"
            "对话机锋来填补，绝不缩水概括，绝不重复任何已写场景或句子。"
        ),
    },
    "go": {
        "title": "俗手",
        "persona": (
            "你是一位风格凌厉、独具辨识度的中文小说家，擅现代奇诡喜剧与冷幽默，"
            "师承余华、王小波一路的当代汉语，善用白描、短句与冷锋。"
            "你正在把一段AI初稿彻底重写——不是润色，是重写。"
        ),
        "style": (
            "【重写要求】\n"
            "1. 删除一切重复、注水、套话、抽象复述与机械对话；情节、因果与伏笔保留，语言焕然一新。\n"
            "2. 文笔求突破：画面具体、感官落地、节奏多变、句子有锋芒；"
            "忌排比堆砌、忌陈词滥调、忌'心中充满了…''仿佛…''一种…的力量'之类空洞抒情。\n"
            "3. 对话要活：贴合人物、有潜台词、可带冷幽默或机锋；师傅纪百川的怪话须似非而是、"
            "有伏笔或主题依据，不得随机抖机灵；拒绝工具人台词。\n"
            "4. 严守现代写实底色（江南城市、棋社、围棋），绝不出现修仙/法术/系统面板；"
            "极少数关键时刻可轻触第四面墙（对'章节''系统''此局'的微妙自觉），须自然克制。\n"
            "5. 严守人物设定，不得OOC；伏笔不变。\n"
            "6. 只输出正文，不要标题、不要分点、不要解释、不要复述初稿、不要'接上'之类提示。\n"
            "7. 修复一切语病与残片标点（如'他，试图''老纪，他''陆衡的，他''陆衡地'之类断裂），"
            "重写为通顺自然的中文。\n"
            "8. 篇幅保持：重写每一段后字数不少于原段——删的是重复注水，可补新的细节、感官、"
            "对话机锋来填补，绝不缩水概括，绝不重复任何已写场景或句子。"
        ),
    },
}


def cjk_count(s: str) -> int:
    return len(CJK.findall(s))


def dedup_paragraphs(body: str) -> str:
    """Drop later verbatim-duplicate paragraphs (continuation loops sometimes
    re-emit a whole paragraph). Keeps order and first occurrence."""
    paras = re.split(r"\n{1,}", body)
    seen: set[str] = set()
    kept: list[str] = []
    for p in paras:
        p = p.strip()
        if not p:
            continue
        key = re.sub(r"\s+", "", p)
        if key in seen:
            continue
        seen.add(key)
        kept.append(p)
    return "\n\n".join(kept)


def call_glm(messages: list[dict], key: str, model: str) -> str:
    """Stream a completion. Streaming keeps the connection alive as tokens
    arrive, avoiding the read-timeouts the non-streaming endpoint hit on long
    outputs."""
    body = json.dumps(
        {"model": model, "messages": messages, "temperature": 0.85, "max_tokens": 4096,
         "stream": True}
    ).encode()
    headers = {
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json",
        "Accept": "text/event-stream",
    }
    for attempt in range(1, 5):
        try:
            req = urllib.request.Request(API, data=body, headers=headers)
            buf = []
            with urllib.request.urlopen(req, timeout=180) as resp:
                for raw in resp:
                    line = raw.decode("utf-8", "ignore").strip()
                    if not line or not line.startswith("data:"):
                        continue
                    payload = line[5:].strip()
                    if payload == "[DONE]":
                        break
                    try:
                        delta = json.loads(payload)["choices"][0].get("delta", {})
                    except (json.JSONDecodeError, KeyError, IndexError):
                        continue
                    if delta.get("content"):
                        buf.append(delta["content"])
            result = "".join(buf).strip()
            if result:
                return result
            # empty result — retry once
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < 4:
                time.sleep(2 ** attempt)
                continue
            raise RuntimeError(f"GLM {e.code}: {e.read().decode()[:300]}") from None
        except (urllib.error.URLError, TimeoutError, OSError) as e:
            if attempt < 4:
                time.sleep(3 * attempt)
                continue
            raise RuntimeError(f"GLM network error: {e}") from None
    return ""


def chunk_draft(body: str, target: int = 2000) -> list[str]:
    paras = [p.strip() for p in re.split(r"\n{1,}", body) if p.strip()]
    chunks: list[str] = []
    buf = ""
    for p in paras:
        if buf and cjk_count(buf) + cjk_count(p) > target:
            chunks.append(buf)
            buf = p
        else:
            buf = f"{buf}\n{p}" if buf else p
    if buf:
        chunks.append(buf)
    return chunks


def trim_to_range(text: str, lo: int = 7000, hi: int = 9000) -> str:
    if cjk_count(text) <= hi:
        return text
    boundaries = "。！？!?\n"
    best_end = -1
    last_end = -1
    running = 0
    for i, ch in enumerate(text):
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


def strip_title_echo(body: str, title: str) -> str:
    """Remove the leading title-echo artifact (e.g. a first line that re-states
    '本章《…》第N章 …' or duplicates the chapter heading)."""
    lines = body.splitlines()
    while lines:
        first = lines[0].strip()
        if not first:
            lines.pop(0)
            continue
        is_echo = (
            first.startswith("本章《")
            or re.search(r"第\d+章.*第\d+章", first)
            or first.lstrip("#").strip() == title
        )
        if is_echo:
            lines.pop(0)
        else:
            break
    return "\n".join(lines).strip()


EXPAND_HINTS = [
    "展开本章核心场景的细节、对话与人物心理，让画面与人物立体起来",
    "推进本章的核心冲突或转折，加深张力，让情节往前走",
    "深化人物关系、铺陈环境，或引入一个小转折、一个新角色反应",
    "把本章推向一个情绪或情节的落点，但不必闭合所有线索",
    "收束本章，干净利落，留白或一丝余韵，不要公式化悬念",
    "完成最后的余波与定格，为本章画上句点",
]


def rewrite_chapter(path: Path, key: str, model: str, preview: bool, theme: dict) -> tuple[str, str, int]:
    title_book = theme["title"]
    persona = theme["persona"]
    style = theme["style"]
    raw = path.read_text(encoding="utf-8")
    lines = raw.splitlines()
    head = lines[0] if lines and lines[0].startswith("# ") else f"# {path.stem}"
    title = head[2:].strip() if head.startswith("# ") else path.stem
    draft = strip_title_echo("\n".join(lines[1:]).strip(), title)
    # Pass 1 (local): strip the verbatim-paragraph loop-padding the original
    # continuation run produced. This leaves the clean core.
    core = dedup_paragraphs(draft)
    # Pass 2 (GLM): rewrite the core's prose — lift the mechanical dialogue,
    # fix broken punctuation, add edge/subtext — while preserving its plot and
    # length. (Plus follows length instructions far better than flash.)
    rewrite_user = (
        f"下面是《{title_book}》本章的情节初稿（AI 所写，语言平庸、有语病）。请以你自己的风格"
        "**彻底重写**这段开篇——重组句子、替换表达、注入你的节奏与画面感，让对话锋利、"
        "有潜台词，极少数关键时刻可轻触第四面墙。只保留情节骨架与人物设定，**语言要全新，"
        "不要保留原句**；善用代词、身份称谓与动作主语，避免频繁重复人物全名。"
        f"重写后约{cjk_count(core)}字（与原稿相当），不得整段重复。\n\n"
        f"【初稿】\n{core}\n\n{style}"
    )
    rewritten_core = call_glm(
        [{"role": "system", "content": persona}, {"role": "user", "content": rewrite_user}],
        key,
        model,
    )
    expanded = dedup_paragraphs(rewritten_core or core)
    print(f"  …core 改写 {cjk_count(core)}→{cjk_count(expanded)} CJK", flush=True)
    # Pass 3 (GLM): expand to a full chapter. Each segment has a
    # DISTINCT narrative purpose (progression hints) so it cannot loop back to
    # earlier scenes; the full text-so-far as context + per-segment dedup are
    # the backstop. Style brief drives the prose lift.
    expanded = core
    seg = 0
    while cjk_count(expanded) < 7200 and seg < len(EXPAND_HINTS):
        hint = EXPAND_HINTS[seg]
        seg += 1
        tail = expanded[-1500:]
        user = (
            f"下面是《{title_book}》本章已写正文的结尾部分。现在请进入下一步：**{hint}**。"
            "紧接上文续写约2200字——文笔求突破，对话带机锋，极少数关键时刻可轻触第四面墙。"
            "**只往前推进新内容，不要复述、不要重复上文的场景或句子。**"
            "\n（硬性要求：本段正文不少于1800中文字，若不足请继续写到1800字以上方可停止；不要提前收尾。）"
            "\n\n"
            f"【已写正文结尾】\n{tail}\n\n{style}"
        )
        out = call_glm(
            [{"role": "system", "content": persona}, {"role": "user", "content": user}],
            key,
            model,
        )
        if not out:
            break
        expanded = dedup_paragraphs((expanded + "\n" + out).strip())
        expanded = trim_to_range(expanded, lo=4000, hi=9000)
        print(f"  …seg {seg}/{len(EXPAND_HINTS)} → {cjk_count(expanded)} CJK", flush=True)
        time.sleep(0.5)
    expanded = trim_to_range(expanded)
    out_path = path.with_suffix(".polished.md") if preview else path
    out_path.write_text(f"{head}\n\n{expanded}\n", encoding="utf-8")
    return path.name, out_path.name, cjk_count(expanded)


def chapter_files(selection: list[int] | None) -> list[Path]:
    files = sorted(CHAPTERS.glob("第*章-*.md"))
    if selection is None:
        return [f for f in files if not f.name.endswith(".polished.md")]
    out = []
    for no in selection:
        m = [f for f in files if re.search(rf"第0*{no}章", f.name) and not f.name.endswith(".polished.md")]
        out.extend(m)
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--chapters", type=str, help="comma-separated chapter numbers, e.g. 39,47")
    g.add_argument("--all", action="store_true")
    ap.add_argument("--model", default="glm-4-flash")
    ap.add_argument("--preview", action="store_true", help="write .polished.md instead of overwriting")
    ap.add_argument(
        "--theme",
        default="xianxia",
        choices=sorted(THEMES.keys()),
        help="which novel's persona/style/title to apply",
    )
    args = ap.parse_args()
    key = os.environ.get("GLM_API_KEY")
    if not key:
        print("GLM_API_KEY required", file=sys.stderr)
        return 2
    theme = THEMES[args.theme]
    sel = [int(x) for x in args.chapters.split(",")] if args.chapters else None
    files = chapter_files(sel)
    print(f"polishing {len(files)} chapters with {args.model} theme={args.theme} dir={NOVEL_DIR_NAME} (preview={args.preview})")
    for p in files:
        try:
            name, out, wc = rewrite_chapter(p, key, args.model, args.preview, theme)
            print(f"  ✓ {name} -> {out} ({wc} CJK)")
        except Exception as e:  # noqa: BLE001
            print(f"  ✗ {p.name} failed: {e}", file=sys.stderr)
        time.sleep(1.0)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
