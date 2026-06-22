---
quick_id: 260622-10f
slug: readme-10-golden-foreshadowing
date: 2026-06-22
status: complete
commits: []
---

# README #10 伏笔管理真实 golden — 交付

第 13 张真实截图：README #10「伏笔管理」→ StoryStructurePage 伏笔 tab。**结构簇首张**。
StoryStructurePage 是 **5-Tab 页**（伏笔/剧情线/弧线图/守护/整理与导出 = #10-14），默认 tab0=伏笔
→ _ForeshadowingSection 渲染伏笔列表 + FAB，无需 tab 交互（同 KnowledgeBasePage 模式）。

## 实现

- StoryStructurePage 自带 Scaffold + AppBar + TabBar(length 5) + TabBarView + FAB。
- _ForeshadowingSection watch foreshadowingNotifierProvider → override 喂 5 修仙伏笔 seed
  （古剑低鸣之谜/苏雪晴禁地线索/弃剑峰旧约/问心石断裂剑印/雾海旧宗主令，对齐 README 运行样本）。
- **_ForeshadowingTile 渲染路径无 provider watch**（仅 delete action 用 ref.read）→ 仅 override
  单一 provider（比 #06 还简，无 chapterNotifier staleness）。
- seed 混 status（planted/developing/resolved）+ mode（simple/detailed）真实展示状态图标多样性。
- 默认 tab0，TabBarView 不预构建邻居 tab → 仅伏笔 section build，无邻居 provider 干扰。
- 固定 DateTime createdAt。

## 验证（六重）

- ✅ analyze 0
- ✅ 首跑 GREEN
- ✅ clean 连跑 2 次 GREEN（确定性）
- ✅ golden 86070B（mockup ~129KB → 真实，5 卡片列表色彩较富）
- ✅ PIL 682 色 / 98.4%dark / 0.5%text（状态图标+卡片，find.text 三重断言证入树）
- ✅ full-suite +13 All tests passed!
- ✅ README 双语 disclosure 4 处加入「伏笔管理(10)/Foreshadowing(10)」

## 教训

- **StoryStructurePage 5-Tab 页同 KnowledgeBasePage 模式**：默认 tab0 对应 #10 免交互；
  #11-14 可同 #07 模式（tap tab + pumpAndSettle）逐 tab 迁移（结构簇可批量推进）。
- **Tile 渲染路径无 provider watch 时仅 override 父 list provider**（_ForeshadowingTile
  无 staleness 依赖，比 _CharacterCardTile 还简）。
- **TabBarView 不预构建邻居 tab** → 当前 tab 截图不受邻居 section provider 影响（安全）。

## 进度

已迁 **13/21**：01 / 02 / 06 / 07 / 09 / **10** / 15 / 16 / 17 / 18 / 19 / 20 / 21。
结构簇首张（10 伏笔）。剩余 8 张：03 AI整理 / 08 模板 / 11 时间线 / 12 故事弧 / 13 逻辑守护 /
14 导出（#11-14 同页可批量）/ 04-05 editor。

相关 [[golden-screenshot-migration-harness]]、[[readme-screenshot-mockup-honesty]]
