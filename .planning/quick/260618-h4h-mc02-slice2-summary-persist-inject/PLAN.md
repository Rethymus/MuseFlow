---
quick_id: 260618-h4h
slug: mc02-slice2-summary-persist-inject
status: planning
date: 2026-06-18
goal: MC-02 章节摘要持久化 + 注入闭环
---

# MC-02 slice 2：章节摘要持久化 + 注入闭环

## 背景
STATE「MC-02 章节摘要自动刷新」slice 1（domain `ChapterSummary` + `ChapterSummarizationService` + 真实 GLM 测试，已 GREEN）已交付（commit 1f49459 / 73162fa）。slice 2 做持久化 + 注入闭环——兑现 SUMMARY 列的前两项 + 陈旧度可检测。

slice 1 `ChapterSummarizationService.summarize()` 已能生成 `ChapterSummary`（含 `sourceWordCount` 陈旧度字段），但**无处存储、无处消费**：相邻章节上下文（`EditorChapterMemoryContextBuilder._summary()`）仍截断章节原文。本 slice 闭合该环。

## 范围（纯逻辑层闭环，零 UI 依赖，可 TDD）

### 1. Hive 持久化
- `HiveTypeIds.chapterSummary = 11`（下一个可用 typeId，tokenAuditRecord=10）
- `ChapterSummaryAdapter`（手动 TypeAdapter，read/write via toJson/fromJson，参照 `ChapterAdapter` @ hive_adapters.dart:293）
- `lib/main.dart`：`Hive.registerAdapter(ChapterSummaryAdapter())` + `openBox('chapter_summaries')`

### 2. Repository + 陈旧度
- `ChapterSummaryRepository`（infrastructure）：`put` / `getByChapterId` / `getByManuscriptId` / `delete`，`Box<dynamic>` + StateError 包装，参照 `ChapterRepository`
- `ChapterSummaryStalenessChecker`（application 纯逻辑，对称 `KbStalenessChecker`）：`isStale(summary, currentWordCount)`——currentWordCount 增长 **绝对 ≥50 且 相对 ≥20%** 视为 stale；currentWordCount ≤ source 视为 fresh（章节未增长）

### 3. 注入改造（向后兼容关键）
`EditorChapterMemoryContextBuilder`：
- 加可选 `ChapterSummaryRepository? chapterSummaryRepository` + `ChapterSummaryStalenessChecker`（默认 const）
- `_summary(chapter)` 改为：repository != null 且存在 fresh（!isStale）summary → 返回 `summary.summary`（AI 概括，已天然有界）；否则 **fallback 现有截断逻辑**（line 85-91 不变）
- **现有测试不传 repository → repository==null → fallback 截断 → 零破坏**（editor_chapter_memory_context_builder_test.dart:43-44 断言）

### 4. Provider wiring
`providers_ai.dart:176` `editorChapterMemoryContextBuilderProvider`：加 `chapterSummaryRepositoryProvider` 依赖（对称 chapterRepositoryProvider），注入 builder

## TDD 计划（RED → GREEN）

### 新增测试
- `chapter_summary_staleness_checker_test.dart`：fresh（未增长）/ stale（绝对≥50 且相对≥20%）/ 边界（长章微调 not stale / 短章大增长 stale）
- `chapter_summary_repository_test.dart`：put→getByChapterId 往返 / getByManuscriptId 过滤 / delete / StateError 包装（参照 chapter_repository_test 风格，hive_test_helper）

### 扩展测试
- `editor_chapter_memory_context_builder_test.dart` 新 group「stored summary injection」：
  - fresh summary → previousChapterSummary == AI 概括（非截断原文）
  - stale summary（章节增长超阈值）→ fallback 截断原文
  - 缺失 summary → fallback 截断原文
  - repository==null → fallback 截断原文（现有行为，零回归）

## 验证
- TDD RED（编译/断言失败）→ GREEN
- `flutter analyze` 0 issues
- 回归：chapter_summarization_service_test（5）+ editor_chapter_memory_context_builder_test（既有+新增）+ manuscript feature 全量 零回归
- 真实 GLM key 端到端：summarize → put → builder.build 注入 fresh AI summary（替代截断），验证注入链路

## 不做（slice 2-B 后续）
- 自动刷新触发（章节保存后异步重生成）+ UI 陈旧度徽章/刷新动作（对称 MC-01 _StalenessBadge）——需异步 AI + UI wiring，scope 更大，留后续 quick task
