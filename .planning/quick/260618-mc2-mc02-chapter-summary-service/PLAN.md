---
quick_id: 260618-mc2
slug: mc02-chapter-summary-summarization-service
status: in-progress
date: 2026-06-18
---

# MC-02 slice 1：章节摘要 AI 概括服务（纯逻辑先行）

## 背景
STATE 命名「MC-02 章节摘要自动刷新（需新建摘要 domain，纯代码无人工依赖）」为 v1.5 下一步。现状：`PromptContext.previousChapterSummary/nextChapterSummary` 是临时 String（journey 里手动截断 100 字），**无 ChapterSummary 实体/存储/AI 概括**。长篇上下文质量（核心 v1.4 价值）依赖人工截断，质量差。

## 本切片范围（slice 1：纯逻辑，闭环可交付）
按项目「纯逻辑先行、wiring 后续」先例（260614-ci1 DialogueActClassifier 纯逻辑 → 260616-ci2 middleware wiring），本切片交付**概括能力**，不含持久化/UI/wiring：
- `domain/chapter_summary.dart`：纯 Dart 不可变实体（id/chapterId/manuscriptId/summary/sourceWordCount/createdAt/updatedAt）+ copyWith + fromJson/toJson + 按 id 相等。sourceWordCount 供 slice 2 陈旧度检测（镜像 KbStalenessChecker lastVerifiedChapter）。
- `application/chapter_summarization_service.dart`：调 `AIAdapter.createStream` 概括一章 documentContent → 返回 ChapterSummary。严格输出契约（system「只输出概括」+ user 上限 120 字）+ **不静默吞错**（AIException rethrow，让调用方处理，应用 0ae 课）。

## 应用既有可靠性课
- wma：adapter.createStream 已自带 retryStream 早失败重试 → service 直接用，无需自写重试。
- 0ae：真实 LLM 输出契约要严格（system 约束 + 字数上限），避免寒暄/解释污染摘要。

## 任务
- T1：domain ChapterSummary + 相等/fromJson 往返。
- T2：service summarize 累积流→ChapterSummary（正确 id/chapterId/sourceWordCount）+ prompt 有界含内容。
- T3：service 概括错误时 **rethrow AIException 不静默吞**（FakeAdapter 抛 AIStreamException → throwsA）。

## 验证
- TDD：targeted service 测试 GREEN；analyze 0；零回归（不触既有文件）。

## slice 2（后续，记 STATE）
Hive 持久化（ChapterSummaryAdapter + repository）+ PromptContext 注入 previousChapterSummary from stored summary + 章节内容变更自动刷新触发（sourceWordCount 陈旧度）。
