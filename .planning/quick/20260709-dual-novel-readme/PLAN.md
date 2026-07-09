# Quick Task: README 双小说重构 + 字数修正

## 目标
README（中+英）"用户旅程实测"段重构为同时展示两部百章长篇，凸显"既能辅传统、又能启想象"双重能力；修正字数标注与实际不符。

## 字数修正（根因）
- 围棋《俗手》metrics.json 曾是润色前旧值(805015/min4490) → 已刷新为润色后实际(816011/8160/[6612,8994])。
- 修仙《剑道苍穹》render 读的是截断摘录.md(~2000/章,180k) → 真实全文815984 CJK(metrics.json权威值, 全本.md/Notion/.polished.md)。README 用 metrics.json 权威值。

## 双小说数据（权威）
| | 修仙《剑道苍穹》 | 围棋《俗手》 |
|字数|815,984 均8,159|816,011 均8,160|
|耗时|10h4m 4.2M token|9h51m 1.35M token|
|成本|¥3.69|¥3.69|
|反AI|8368标/8032净|4544标/4310净|
|伏笔|12/12 100%|12/12 100%|

## 步骤
1. README: 替换 Go-only 段为 dual（intro+对比表+修仙分述+围棋分述+Go目录内联Notion+修仙链全本/Notion）
2. README.en: 同步 dual 英文版
3. guard 验证 (check_readme_assets/check_repo_hygiene)
4. 原子 commit + SUMMARY.md + STATE.md
