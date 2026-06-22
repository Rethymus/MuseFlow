---
quick_id: 260622-14e
slug: readme-14-golden-exportcleanup
date: 2026-06-22
status: complete
commits: []
---

# README #14 整理与导出真实 golden — 交付

第 14 张真实截图：README #14「整理与导出」→ StoryStructurePage tab4 _FinishExportSection。
结构簇第 2 张。section 是**纯静态**（图标+标题+描述+预览清理 FilledButton+导出稿件 OutlinedButton），
渲染路径**零 provider watch**（dialog 仅 tap 时 ref.read）——迄今最简 section。

## 实现

- StoryStructurePage 默认 tab0=伏笔，#14 需 tab4 → `tester.tap(find.text('整理与导出'))`
  + pumpAndSettle 驱动 TabBarView 从 tab0 滑到 tab4。
- **同时 override foreshadowingNotifierProvider**（喂 2 seed）让初始 tab0 帧干净（滑动期间 tab0
  短暂可见）。tab4 静态无需 provider，但 tab0 不 override 会显 loading/error 帧。
- 跨 4 个中间 tab（剧情线/弧线图/守护）滑动——各 section AsyncValue.when 守护，error 进 AsyncValue
  不抛异常；TabBarView settle 到 tab4 后中间 tab 不在画面。clean 连跑 2 次证确定性。

## 验证（六重）

- ✅ analyze 0
- ✅ 首跑 GREEN
- ✅ clean 连跑 2 次 GREEN（**跨 4 中间 tab 滑动确定性**）
- ✅ golden 41849B（mockup → 真实，静态 section 色彩较少但 859 色含按钮+图标）
- ✅ PIL 859 色 / 99.1%dark / 0.6%text（find.text 三重断言：整理成可交付的稿件/预览清理/导出稿件）
- ✅ full-suite +14 All tests passed!
- ✅ README 双语 disclosure 4 处加入「整理与导出(14)/Finish & export(14)」

## 教训

- **纯静态 section（零 provider）只需切 tab**：_FinishExportSection 渲染不 watch 任何 provider，
  dialog 才 ref.read——截图零 override（除 tab0 初始帧清洁的 foreshadowing override）。
- **跨多 tab 滑动可确定性**：tap 远端 tab + pumpAndSettle，中间 tab AsyncValue 守护不崩，settle
  后画面是目标 tab。foreshadowing override 保 tab0 初始帧干净。

## 进度

已迁 **14/21**：01 / 02 / 06 / 07 / 09 / 10 / **14** / 15 / 16 / 17 / 18 / 19 / 20 / 21。
结构簇 2/5（10/14）。剩余 7 张：03 AI整理 / 08 模板 / 11 时间线 / 12 故事弧 / 13 逻辑守护
（#11-13 同页 viz 可能含自定义绘制）/ 04-05 editor（极重 appflowy）。

相关 [[golden-screenshot-migration-harness]]、[[readme-screenshot-mockup-honesty]]
