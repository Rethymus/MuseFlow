---
quick_id: 260622-8t
slug: readme-08-golden-templategallery
date: 2026-06-22
status: complete
commits: []
---

# README #08 模板库真实 golden — 交付

第 17 张真实截图：README #08「模板库」→ TemplateGalleryPage（AppBar「世界观模板库」+
SegmentedButton 全部/男频/女频 + 搜索框 + 4 模板卡 CircleAvatar+displayTitle+description+channel tag+tags）。
**knowledge 簇第 4 张，簇全闭合（06/07/08/09）**。

## 实现（新形态：fake repository override）

- **与 provider-watch 页不同**：TemplateGalleryPage 在 initState 直读 repo
  `_templatesFuture = ref.read(worldTemplateRepositoryProvider).getAll()` + FutureBuilder。
  故 override `worldTemplateRepositoryProvider`（Provider<WorldTemplateRepository>）为 fake
  subclass `_SeededTemplateRepository extends WorldTemplateRepository` 重写 getAll() 返回 seed，
  绕过 asset loadLibrary() 链。**新 harness 形态：concrete repo subclass override getAll**。
- WorldTemplate **13 必填**含嵌套：world（WorldTemplateWorld 7 字段）/ review（TemplateReviewMetadata
  sourceNote+reviewedAt+qualityChecks）/ characters/foreshadowingArcs/openingSamples（list 可空）。
  全 const 可构造；唯 review.reviewedAt 是 runtime DateTime（DateTime 无 const ctor）→ 模板 list
  用 `final` 非 `const`，reviewedAt 固定 DateTime 保确定性。
- 嵌套对象最小化（world 仅 name，其余空串；3 list 空 const）——_TemplateCard 只渲染 displayTitle
  (genreName｜subtitle)/description/channel tag/tags/icon，嵌套富字段不显示故最小化。
- iconName 用真实 _iconFor 映射值（terrain/travel_explore/account_balance/location_city）保 icon 忠实。
- 4 模板混 male/female channel + 多 genre（仙侠/奇幻/悬疑/都市），对齐 README 运行样本。

## 验证（六重）

- ✅ analyze 0（修 import：WorldTemplateRepository 在 infrastructure/ 非 domain/；final 非 const list）
- ✅ 首跑 GREEN
- ✅ clean 连跑 2 次 GREEN（确定性）
- ✅ golden 97339B（mockup → 真实，SegmentedButton+4 卡片色彩较富）
- ✅ PIL 985 色 / 97.9%dark / 0.6%text（icon+tag+channel chip+displayTitle，find.text 三重断言证入树）
- ✅ full-suite +17 All tests passed!
- ✅ README 双语 disclosure 4 处加入「模板库(8)/Template gallery(8)」

## 教训

- **concrete repo subclass override getAll()** 是第 4 种 harness 形态（前 3：override AsyncNotifier /
  withSnapshot 测试构造函数 / 纯静态 0-provider）。页面若直读 repo（非 watch provider）用此形态。
- **重模型 seed 最小化**：13 必填+嵌套对象，但 card 只渲染顶层展示字段→嵌套最小化（world 仅 name、
  list 空 const），避免冗余构造。唯一 runtime DateTime 字段（reviewedAt）用 `final` list + 固定值。
- **import 路径按实际文件位置**：WorldTemplateRepository 在 infrastructure/（非 domain/ 与 model 同文件），
  遇 Type not found 先 grep 实际 class 文件位置。

## 进度

已迁 **17/21**：01 / 02 / 06 / 07 / **08** / 09 / 10 / 11 / 13 / 14 / 15 / 16 / 17 / 18 / 19 / 20 / 21。
**knowledge 簇全闭合**（06/07/08/09）+ structure 4/5 + capture。剩余 4 张均为 headless golden 硬壁垒：
03 AI整理（synthesis AnimatedContainer+TextController 动画）/ 12 故事弧（自定义边缘渲染 viz 像素非确定）/
04-05 editor（appflowy，WSL2 CanvasKit 渲染边界 + 需 Windows 真机 UAT，headless 不可靠捕获）。

相关 [[golden-screenshot-migration-harness]]、[[readme-screenshot-mockup-honesty]]
