---
phase: quick-260614-mc1
plan: 01
subsystem: knowledge/domain
tags: [knowledge, staleness, nlp, consistency]
requires: [CharacterCard, WorldSetting domain, Phase 20-21 KB injection]
provides:
  - KbStalenessChecker + KbStalenessLevel + KbStalenessResult (陈旧度检测纯逻辑)
  - CharacterCard.lastVerifiedChapter / WorldSetting.lastVerifiedChapter 字段（向后兼容）
metrics:
  duration: ~25 min
  completed: 2026-06-14
  baseline_tests: 1581
  final_tests: 1602
  new_tests: 21
  regressions: 0
---

# Phase quick-260614-mc1: MC-01 动态知识库陈旧度追踪 Summary

推进 P2 🔴P0 项 MC-01（动态知识库，NAACL 2025 DOME 时序冲突分析；research 路线图"命题2：AI要记住我的故事"）。本提交聚焦 MC-01 **核心——陈旧度追踪与检测**：解决"100 章后知识库成为负债、给 AI 喂陈旧上下文"问题。MC-02（章节摘要自动刷新，需新建摘要 domain）与 UI 提醒/编辑 hook 留后续。

## 交付

**1. KbStalenessChecker（纯逻辑，MC-01 检测核心）**
- `KbStalenessLevel` { fresh, stale, veryStale }
- `KbStalenessResult` { level, chaptersSinceVerified, message（中文） }
- `KbStalenessChecker.check(int? lastVerifiedChapter, int currentChapterCount)`
  - fresh: < 10 章（含 null 旧条目——不误 nag，向后兼容）
  - stale: ≥ 10 章（MC-01 "超过 10 章未验证自动提醒"）
  - veryStale: ≥ 20 章（严重过期，⚠️ 急迫 message）
  - 防御性 clamp：verifiedChapter 超过 currentCount（回滚/损坏）→ since 0，永不负

**2. KB 实体加 lastVerifiedChapter 字段（向后兼容）**
- CharacterCard + WorldSetting 各加 `int? lastVerifiedChapter`
- 全套：字段/构造/copyWith/fromJson（`json['lastVerifiedChapter'] as int?`，缺键→null）/toJson/== /hashCode/toString
- 旧持久化数据无该键 → fromJson 返回 null → KbStalenessChecker 视为 fresh（迁移不误报）

## 设计决策

- **null = 旧条目未追踪 → fresh**：避免迁移时对全部历史 KB 条目误报陈旧；与 autoDeviationCheck defaultValue / lexical_signature 向后兼容模式一致。
- **checker 与实体解耦**：`check(int?, int)` 纯函数，不绑定具体实体类型——未来 SkillDocument / 关系实体加同字段即可复用，无需改 checker。
- **阈值常量**：`staleThreshold=10` / `veryStaleThreshold=20` 为 public static const，可被 UI / 报告引用并测试断言。
- **MC-01 完整范围**：本提交是检测+追踪层；"自动提示作者更新"UI、"角色新发展检测"、"刷新所有条目"按钮属后续 UI/编辑 hook 工作。

## 验证

- `flutter analyze`（全项目）→ **No issues found!**
- `flutter test` → 全绿零回归（基线 1581 → +21：checker 13 + CharacterCard 往返 4 + WorldSetting 往返 4）

新增测试 21 个：
- `kb_staleness_checker_test.dart`：13（null→fresh、since 0/9 fresh、10/15 stale、20/50 veryStale、clamp 防、message 非空/含过期词/veryStale 更急、阈值常量）
- CharacterCard `lastVerifiedChapter` 组：4（默认 null、JSON 往返、legacy 缺键→null、参与 == /hashCode）
- WorldSetting `lastVerifiedChapter` 组：4（同上）

## 与既有 KB 注入协同

Phase 20-21 的知识注入中间件把角色卡/世界观注入 prompt；MC-01 让这些条目带上"新鲜度"。下一步（MC-01 UI / MC-02）：当作者写到第 N 章时，UI 提示"角色卡 X 已 15 章未验证，是否回顾"，作者确认后 `copyWith(lastVerifiedChapter: currentChapter)` 刷新。
