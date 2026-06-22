---
quick_id: 260622-11p
slug: readme-11-golden-plottimeline
date: 2026-06-22
status: complete
commits: []
---

# README #11 剧情线真实 golden — 交付

第 16 张真实截图：README #11「剧情线」→ StoryStructurePage tab1 PlotTimeline。结构簇第 4 张。
迁移前探针 `grep CustomPainter|AnimationController|Tween` PlotTimeline **零命中**——确认是章节分组
ListView（非自定义绘制 viz），可确定性截图。

## 实现

- PlotTimeline ConsumerWidget watch plotNodeNotifierProvider（AsyncNotifierProvider<PlotNodeNotifier,
  List<PlotNode>>）；_GroupedTimeline 按章节分组 → ListView；_PlotNodeCard 渲染 title+_RoleChip+
  _StatusChip+summary+涉及角色。渲染路径零额外 provider watch（_PlotNodeCard 仅数据）。
- override plotNodeNotifierProvider 喂 5 跨章节 plot node（ch1/12/35/50/68，混 setup/development/
  turn/climax/resolution × complete/drafting/notStarted/needsRevision，真实展示 role/status chip
  多样性），对齐 README 修仙运行样本（古剑觉醒→入门考验→弃剑峰之行→雾海探秘→旧约揭晓）。
- override foreshadowingNotifierProvider 保 tab0 初始帧干净。
- tap '剧情线'(tab1) + pumpAndSettle。
- PlotNode required 仅 id/title/chapter/createdAt（其余 enum 有默认 notStarted/setup），seed 简洁。
- 固定 DateTime createdAt。

## 验证（六重）

- ✅ analyze 0
- ✅ 首跑 GREEN
- ✅ clean 连跑 2 次 GREEN（章节分组 ListView 确定性，无 viz/动画）
- ✅ golden 92997B（mockup → 真实，章节分组+5 卡片色彩较富）
- ✅ PIL 967 色 / 98.5%dark / 0.6%text（role/status chip+章节头+summary，find.text 三重断言证入树）
- ✅ full-suite +16 All tests passed!
- ✅ README 双语 disclosure 4 处加入「剧情线(11)/Plot timeline(11)」

## 教训

- **viz 疑虑先 grep 探针**：PlotTimeline 疑似自定义绘制，但 `grep CustomPainter|AnimationController|
  Tween` 零命中→确认 ListView 可行。迁移前对 viz 类页面（时间线/图）必先探针排除自定义绘制，
  有 CustomPainter 的页面 golden 像素非确定需另案（如 #12 故事弧）。
- **章节分组 ListView = 分组键 fold**：_GroupedTimeline 按 chapter 分组，seed 跨多章节即得分组渲染。

## 进度

已迁 **16/21**：01 / 02 / 06 / 07 / 09 / 10 / **11** / 13 / 14 / 15 / 16 / 17 / 18 / 19 / 20 / 21。
**结构簇 4/5**（10/11/13/14，仅剩 12 故事弧 viz）。剩余 5 张：03 AI整理 synthesis动画 / 08 模板
重模型 / 12 故事弧（StoryArcGraph 自定义绘制 viz，golden 非确定风险）/ 04-05 editor appflowy 极重。

相关 [[golden-screenshot-migration-harness]]、[[readme-screenshot-mockup-honesty]]
