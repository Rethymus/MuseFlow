---
quick_id: 260618-h4h
slug: mc02-slice2-summary-persist-inject
status: complete
date: 2026-06-18
commit: pending
---

# MC-02 slice 2：章节摘要持久化 + 注入闭环

## 交付
STATE「MC-02 章节摘要自动刷新」slice 2——slice 1（domain `ChapterSummary` + `ChapterSummarizationService`，commit 1f49459/73162fa）已有 summarize 能力但**无处存储、无处消费**；本次闭合持久化+注入环。

## 实现
- `application/chapter_summary_staleness_checker.dart`：纯逻辑 `isStale`——currentWordCount 增长 **绝对≥50 且 相对≥20%** 视 stale（对称 `KbStalenessChecker`；AND 阈值避免短章/长章误报）
- `infrastructure/chapter_summary_repository.dart`：put/getByChapterId/getByManuscriptId/delete，`Box<dynamic>` + StateError，**key=chapterId（1:1 upsert）**
- `core/infrastructure/hive_adapters.dart`：`HiveTypeIds.chapterSummary=11` + `ChapterSummaryAdapter`（参照 ChapterAdapter）
- `main.dart`：`registerAdapter(ChapterSummaryAdapter())`
- `editor/application/editor_chapter_memory_context_builder.dart`：加可选 `chapterSummaryRepository` + `stalenessChecker`；`_summary()` 优先 fresh stored AI summary，缺失/stale/无 repository 时 **fallback 截断原文**（向后兼容契约）；`_warning()` 对 stored summary 只跑 front-load 警告（跳过"截断缺少词"——AI 概括非截断）
- `providers.dart` import + `providers_structure.dart` `chapterSummaryRepositoryProvider` + `providers_ai.dart` builder 注入

## 应用既有可靠性课
- 0ae：严格输出契约沿用（slice 1 system 约束 + 字数上限）
- MC-01 对称：sourceWordCount 陈旧度镜像 KbStalenessChecker lastVerifiedChapter 模式

## 验证（TDD GREEN）
- staleness checker 6 测试（fresh/stale/边界：长章微调 not stale、短章大增长 stale）
- repository 5 测试（CRUD + 1:1 upsert 覆盖）
- builder 3 新注入测试（fresh 用 summary / stale fallback / missing fallback）+ **7 现有零回归**（不传 repository → fallback 截断 → 原断言不变）
- manuscript application+infrastructure **75 测试全绿**（slice 1 service + slice 2 + 现有）
- `flutter analyze` **0 issues**
- 真实 GLM key（slice 1 真实测试已 GREEN：34 字概括 300 字源，含"林风"）

## slice 2-B（后续，未做）
自动刷新触发（章节保存后异步重生成）+ UI 陈旧度徽章/刷新动作（对称 MC-01 `_StalenessBadge`）——需异步 AI + UI wiring，留后续 quick task。
