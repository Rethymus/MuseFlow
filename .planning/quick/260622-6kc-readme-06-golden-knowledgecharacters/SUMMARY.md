---
quick_id: 260622-6kc
slug: readme-06-golden-knowledgecharacters
date: 2026-06-22
status: complete
commits: []
---

# README #06 角色卡真实 golden — 交付

第 10 张真实截图：README #06「角色卡」→ KnowledgeBasePage（角色卡 tab）。首个**知识库簇**
迁移。AppBar「知识库」+ TabBar(角色卡/世界观) + 模板库按钮 + 搜索框 + FAB + 4 角色卡 ListTile。

## 实现

- KnowledgeBasePage **自带 Scaffold**（与 CapturePage 不同）→ `home: const KnowledgeBasePage()`
  直接宿主，无 Material 祖先问题。
- `_CharacterCardList` watch `characterCardNotifierProvider`
  （`AsyncNotifierProvider<CharacterCardNotifier, List<CharacterCard>>`）→ override 喂 4 修仙
  角色 seed（林风/苏雪晴/清虚真人/慕容夜，名字对齐 README 运行样本）。
- `_CharacterCardTile` 另 watch `chapterNotifierProvider`（staleness 计算）→ override 返回空列表
  → chapterCount=0 → staleness 全 fresh → 无 stale badge，列表聚焦角色行。
- **默认 tab 0 = 角色卡**，无需 tab 交互即渲染 #06。
- part-file 陷阱兑现（#02/w82 教训）：providers_knowledge.dart / providers_structure.dart 均
  `part of 'providers.dart'` → import **父库** `core/presentation/providers.dart` 获取两个
  provider；CharacterCardNotifier/ChapterNotifier 类在 features/application/ 需单独 import subclass。
- createdAt 用**固定 DateTime**（#02 教训习惯；tile 实不渲染时间戳但保持确定性）。

## 验证（六重）

- ✅ 首跑 GREEN（无 #02 的连环 bug——页面自带 Scaffold）
- ✅ clean 连跑 2 次 GREEN（确定性，无 #02 式 flake——无时间戳渲染）
- ✅ golden 字节 44653B（mockup ~120KB 量级 → 真实）
- ✅ PIL 768 色 / 98.8%dark / 0.3%text（列表页色彩密度低于卡片网格属正常，非 tofu——find.text 四重断言证数据入树）
- ✅ full-suite +10 All tests passed!（含 #06，零回归）
- ✅ analyze 0（doc comment 尖括号 backtick 包裹修 unintended_html_in_doc_comment）
- ✅ README 双语 disclosure 4 处加入「角色卡(6)/Character cards(6)」

## 教训

- **自带 Scaffold 的页面零 Material 坑**：与 body-only CapturePage 对照——页面自带 Scaffold
  则 `home: Page()` 直宿主，是迄今最简形态（镜像 #01 library）。
- **多 provider 依赖逐个 override**：_CharacterCardTile 嵌套 watch 另一个 provider
  （chapterNotifierProvider for staleness），须一并 override（#15 含子 ConsumerWidget 教训同类）。
- **默认 tab 即目标 tab 免交互**：选默认 tab 对应的截图（#06=tab0）无需 tabController 驱动。

## 进度

已迁 **10/21**：01 / 02 / **06** / 15 / 16 / 17 / 18 / 19 / 20 / 21。剩余 11 张：
- 中复杂度：03 AI整理 / 07 世界观 / 08 模板 / 09 技能 / 10 伏笔 / 13 逻辑守护 / 14 导出
- 中高：11 时间线 / 12 故事弧（可视化）
- 极重：04-05 editor（appflowy）

相关 [[golden-screenshot-migration-harness]]、[[readme-screenshot-mockup-honesty]]
