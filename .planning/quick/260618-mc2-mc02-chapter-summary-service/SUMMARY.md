---
quick_id: 260618-mc2
slug: mc02-chapter-summary-summarization-service
status: complete
date: 2026-06-18
commit: pending
---

# MC-02 slice 1：章节摘要 AI 概括服务（纯逻辑先行）

## 交付
STATE「MC-02 章节摘要自动刷新」slice 1——按项目「纯逻辑先行、wiring 后续」先例（260614-ci1→260616-ci2）交付**概括能力**：
- `domain/chapter_summary.dart`：纯 Dart 不可变实体（id/chapterId/manuscriptId/summary/sourceWordCount/createdAt/updatedAt）+ copyWith + fromJson/toJson + 按 id 相等。sourceWordCount 供 slice 2 陈旧度检测。
- `application/chapter_summarization_service.dart`：调 `AIAdapter.createStream` 概括一章 → ChapterSummary（maxTokens 200 + prompt 120 字软上限 + system「只输出概括」）。

## 应用既有可靠性课
- wma：createStream 自带 retryStream 早失败重试 → service 直接用，不自写重试（单一咽喉）。
- 0ae：严格输出契约（system 约束 + 字数上限），AIException **rethrow 不静默吞**（deviation 的 catch(_) 是反例）。

## 验证
- TDD 3 GREEN：①summarize 累积流→正确 id/chapterId/sourceWordCount + prompt 有界含内容 ②AIException rethrow 不吞 ③toJson/fromJson 往返。
- `flutter analyze` **0 issues**（2 文件）。零回归（仅新增文件，不触既有代码）。

## slice 2（后续，未做）
Hive 持久化（ChapterSummaryAdapter + repository + hive_adapters 注册）→ PromptContext.previousChapterSummary 从 stored summary 注入（替代 journey 手动截断 100 字）→ 章节内容变更自动刷新（sourceWordCount 陈旧度触发）。

## 注
本次未跑真实 GLM smoke（slice 1 纯逻辑，FakeAdapter 覆盖；真实链路由既有 createStream/adapter 保证，slice 2 wiring 后再端到端）。
