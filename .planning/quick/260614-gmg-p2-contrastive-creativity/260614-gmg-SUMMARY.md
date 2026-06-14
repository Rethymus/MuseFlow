---
phase: quick-260614-gmg
plan: 01
subsystem: ai/prompt + ai/sampling + settings
tags: [style, ai-prompt, anti-ai-scent, nlp, sampling]
requires: [P2-author-style-fingerprint, Phase 18-19 anti-AI-scent]
provides:
  - ContrastiveSubtractionMiddleware (CoPA 4-模式分解式反AI味 prompt 层)
  - CreativityLevel 枚举 + creativityLevelProvider (用户级创意度→温度)
  - SettingsRepository.getCreativityLevel/saveCreativityLevel 持久化
  - PromptContext.creativityLevel 字段 (生成调用点温度覆盖通道)
affects:
  - synthesis + editor 两个 PromptPipeline (新增对比减法中间件)
  - synthesis_notifier + editor_ai_notifier createStream temperature 参数
  - 设置页 AI 段新增创意度 SegmentedButton
tech-stack:
  added: []
  patterns: [const PromptMiddleware 子类, 持久化 NotifierProvider, SegmentedButton 三档控件, scrollUntilVisible 测试模式]
key-files:
  created:
    - lib/features/ai/application/prompt_middlewares/contrastive_subtraction_middleware.dart
    - lib/features/ai/domain/creativity_level.dart
    - test/features/ai/application/contrastive_subtraction_middleware_test.dart
    - test/features/ai/domain/creativity_level_test.dart
    - test/core/presentation/creativity_level_provider_test.dart
  modified:
    - lib/features/ai/application/prompt_pipeline.dart
    - lib/features/editor/application/editor_prompt_pipeline.dart
    - lib/core/infrastructure/settings_repository.dart
    - lib/core/presentation/providers.dart
    - lib/features/settings/presentation/settings_page.dart
    - lib/features/editor/application/editor_ai_notifier.dart
    - lib/features/ai/presentation/synthesis_notifier.dart
    - test/features/settings/presentation/settings_page_stats_test.dart
decisions:
  - D-gmg-01: ContrastiveSubtractionMiddleware 与 BannedListMiddleware 正交（bannedPhrases 空时仍注入）
  - D-gmg-02: 对比减法块带幂等守卫（含 blockTitle 则不重复注入）
  - D-gmg-03: 单一合并提交——prompt_pipeline.dart 同时承载 AA-02 接入与 AA-03 PromptContext 字段，无法用非交互 git 拆分；按 260613-edreview 单提交惯例处理
  - D-gmg-04: settings_page_stats_test 加 scrollUntilVisible（创意度控件把"清除写作统计"推出 600px 测试视口，ListView 懒构建）
metrics:
  duration: ~50 min
  completed: 2026-06-14
  baseline_tests: 1550
  final_tests: 1571
  new_tests: 21
  regressions: 0
---

# Phase quick-260614-gmg Plan 01: P2 反AI味生成质量升级（AA-02 对比减法 + AA-03 创意度）Summary

延续 P2 深化（Author Writing Sheet 词汇签名 260614-1tp、AI 评审团 260613-edreview 之后），推进 Phase 26「多信号反AI味 + 温度优化」的**生成侧**两项研究驱动功能。AA-01 多信号「检测」侧已由 Phase 19 style_deviation_detector（5 维 + aiScentScore）覆盖，本任务聚焦「生成」侧——让 AI 在产出时主动减去机器味（prompt 层）并以更高温度采样（采样层）。

## AA-02 — 对比减法 ContrastiveSubtractionMiddleware（CoPA, Fang et al. EMNLP 2025）

新增 `ContrastiveSubtractionMiddleware`（const PromptMiddleware 子类），在 system 消息注入分解式「**对比减法 — 主动减去机器味**」指令块，命名 4 个具体机器味模式并给出可执行的减法指令：

1. **句长**：避免均匀句式长度，主动交替长短句，保持不均匀节奏感（人类 burstiness）
2. **逻辑链**：避免过度完美的因果闭环，允许跳跃、留白、非线性推进
3. **过渡词**：避免「然而/此外/综上所述/不仅……而且/值得一提的是」等机械化连接，改用情境/动作/对话衔接
4. **节奏**：允许情绪驱动的节奏突变，不匀速推进

**关键设计**：
- 与 `BannedListMiddleware` **正交**——词库是「禁止说某些词」，对比减法是「禁止以机器的方式组织句子」，是不同维度的反AI味。`bannedPhrases` 为空时**仍注入**（测试覆盖），确保无词库用户也获得句法层反AI味。
- **幂等守卫**：system 内容已含 `对比减法` 标题则不重复注入。
- **additive**：保留 `dynamic_persona` 现有反AI味 anchor（`核心要求…AI生成的痕迹`）不变。
- 接入 synthesis（`prompt_pipeline.dart`）+ editor（`editor_prompt_pipeline.dart`）两个 PromptPipeline，位于 `BannedListMiddleware` 之后、知识注入之前——先禁词，再给组织句子的减法指令。

## AA-03 — 创意度 CreativityLevel（TempParaphraser, Huang et al. EMNLP 2025）

把深埋在 provider 配置里的 sampling temperature 提升为用户可见的「创意度」三档：

| 档位 | temperature | 定位 |
|------|------------|------|
| 保守 conservative | 0.6 | 紧致、可预测 |
| 平衡 balanced（默认） | 0.8 | 比 AI 默认 0.7 更多样 |
| 灵动 expressive | 0.95 | 最大多样性，机器味足迹最低 |

TempParaphraser 证明适度高温采样使 AI 文本检测率降 **82.5%**。所有档位 ≤ 1.0 以保持连贯性。

**接线**：
- `CreativityLevel` 枚举（temperature getter + fromJson/toJson + 中文 label）；fromJson 对 null/未知值安全降级为 balanced（向后兼容，复刻 autoDeviationCheck defaultValue 模式）。
- `SettingsRepository.getCreativityLevel/saveCreativityLevel`（Hive key `creativity_level`）。
- `creativityLevelProvider` + `CreativityLevelNotifier`（持久化 NotifierProvider，复刻 autoDeviationCheck 模式）。
- `PromptContext.creativityLevel` 可选字段（穿透 addMessage/withMessages/replaceSystemMessage）。
- `editor_ai_notifier` + `synthesis_notifier` createStream：`temperature: context.creativityLevel?.temperature ?? provider.temperature`——用户显式选档覆盖 provider 默认，null 透传保留旧路径。
- 设置页 AI 段新增创意度 `SegmentedButton`（三档）+ 说明「影响 AI 生成的多样性，灵动档可降低机器味」。

## 验证证据

- `flutter analyze`（全项目）→ **No issues found!**（4.0s）
- `flutter test` → **1571 passed, 12 skipped, 0 failed**（基线 1550 → +21 新增，零回归）

新增测试 21 个：
- `contrastive_subtraction_middleware_test.dart`：9（标题注入 / 4 模式各自断言 / bannedPhrases 空仍注入的正交性 / 追加非替换 / 空消息建 system / 幂等不重复）
- `creativity_level_test.dart`：9（三档温度 0.6/0.8/0.95 / ≤1.0 边界 / 中文 label / toJson=name / fromJson 往返 / fromJson(null)→balanced / fromJson(garbage)→balanced）
- `creativity_level_provider_test.dart`：3（默认 balanced / 读取已持久化档位 / set 即时更新+持久化跨会话）

## 与 4 个 CoPA 模式的对应

本实现是 CoPA「对比减法」思想的纯 prompt 层、零依赖落地：不是抽象地告诉模型「避免 AI 味」（v1.4 anchor 已有），而是**分解命名 4 个具体机器味维度并给出可执行减法指令**（制造长短句交替 / 允许跳跃留白 / 替换机械化连接词 / 允许情绪节奏突变）。配合 AA-03 高温采样，从 prompt + 采样两个生成侧维度主动减去机器味，补充 AA-01（Phase 19）的检测侧。

## 偏离计划

**[Rule 3 - Blocking] settings_page_stats_test 回归失败 → 加 scrollUntilVisible。**
- **发现于**：全量回归第 4 步
- **问题**：创意度控件（ListTile ~72px + SegmentedButton ~56px）把「清除写作统计」tile 推出 600px 测试视口；`ListView(children:)` 在 Scaffold 内懒构建，视口外子项不构建 → `find.text('清除写作统计')` 返回 0 → tap 失败。
- **修复**：在两处 `tester.tap` 前加 `tester.scrollUntilVisible(find.text('清除写作统计'), 100.0)`（Flutter 长列表标准测试模式）。见 D-gmg-04。

## Authentication Gates

无。

## Known Stubs

无。全部新代码已接通（中间件接入两 pipeline；温度覆盖接通两调用点；持久化闭环）。

## Threat Flags

无。PLAN T-1~T-4 全部兑现：注入块固定常量无用户输入污染（T-1）、CreativityLevel 默认 balanced 与历史行为一致（T-2）、覆盖是显式用户意图非静默改写（T-3）、pipeline 顺序词库→对比减法合理（T-4）。

## Self-Check: PASSED

2 新源文件 + 1 新枚举 + 3 新测试文件存在；7 修改文件落地；analyze 0 issue；test 1571 全绿零回归。
