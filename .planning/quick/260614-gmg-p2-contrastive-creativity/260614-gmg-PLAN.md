---
phase: quick-260614-gmg
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/ai/application/prompt_middlewares/contrastive_subtraction_middleware.dart
  - lib/features/ai/application/prompt_pipeline.dart
  - lib/features/editor/application/editor_prompt_pipeline.dart
  - lib/features/ai/domain/creativity_level.dart
  - lib/core/infrastructure/settings_repository.dart
  - lib/core/presentation/providers.dart
  - lib/features/settings/presentation/settings_page.dart
  - lib/features/editor/application/editor_ai_notifier.dart
  - lib/features/ai/presentation/synthesis_notifier.dart
  - test/features/ai/application/contrastive_subtraction_middleware_test.dart
  - test/features/ai/domain/creativity_level_test.dart
  - test/core/presentation/creativity_level_provider_test.dart
autonomous: true
requirements: [P2-AA-02, P2-AA-03]
tags: [style, ai-prompt, anti-ai-scent, nlp, sampling]

must_haves:
  truths:
    - "ContrastiveSubtractionMiddleware 在 system 消息注入分解式「减去机器味」指令块，含 4 个 CoPA 模式：均匀句长/过度完美逻辑/机械化过渡词/情绪驱动节奏"
    - "对比减法与 BannedListMiddleware 正交：bannedPhrases 为空时仍注入（对比减法不依赖词库，是不同维度的反AI味）"
    - "现有 dynamic_persona 反AI味 anchor（核心要求/AI生成的痕迹）保持不变（additive，不替换）"
    - "注入块出现在 banned_list 之后（pipeline 顺序：BannedListMiddleware → ContrastiveSubtractionMiddleware）"
    - "CreativityLevel 三档枚举（保守0.6/平衡0.8默认/灵动0.95）映射到 temperature"
    - "creativityLevelProvider 持久化到 SettingsRepository，默认平衡"
    - "editor_ai_notifier + synthesis_notifier 调用点：creativityLevel != null 时用它覆盖 provider.temperature"
    - "设置页新增创意度 SegmentedButton 控件，用户可切换三档"
    - "flutter analyze 零错误，flutter test 全绿（基线 + 新增测试，零回归）"
  artifacts:
    - path: "lib/features/ai/application/prompt_middlewares/contrastive_subtraction_middleware.dart"
      provides: "ContrastiveSubtractionMiddleware — 注入 CoPA 4 模式分解式反AI味指令（const 构造，PromptMiddleware）"
      contains: "class ContrastiveSubtractionMiddleware"
    - path: "lib/features/ai/domain/creativity_level.dart"
      provides: "CreativityLevel 枚举（conservative/balanced/expressive）+ temperature getter + fromJson/toJson + label"
      contains: "enum CreativityLevel"
    - path: "lib/core/infrastructure/settings_repository.dart"
      provides: "getCreativityLevel() / saveCreativityLevel() 持久化"
      contains: "getCreativityLevel"
    - path: "lib/core/presentation/providers.dart"
      provides: "creativityLevelProvider + CreativityLevelNotifier（持久化 Riverpod）"
      contains: "creativityLevelProvider"
  key_links:
    - from: "lib/features/ai/application/prompt_pipeline.dart"
      to: "lib/features/ai/application/prompt_middlewares/contrastive_subtraction_middleware.dart"
      via: "withDefaultMiddlewares 在 BannedListMiddleware 之后加 const ContrastiveSubtractionMiddleware()"
      pattern: "ContrastiveSubtractionMiddleware"
    - from: "lib/features/editor/application/editor_prompt_pipeline.dart"
      to: "lib/features/ai/application/prompt_middlewares/contrastive_subtraction_middleware.dart"
      via: "EditorPromptPipeline 在 BannedListMiddleware 之后加 const ContrastiveSubtractionMiddleware()"
      pattern: "ContrastiveSubtractionMiddleware"
    - from: "lib/features/editor/application/editor_ai_notifier.dart"
      to: "lib/features/ai/domain/creativity_level.dart"
      via: "createStream temperature 参数：creativityLevel?.temperature ?? provider.temperature"
      pattern: "creativityLevel\\?\\.temperature"
---

# Phase quick-260614-gmg Plan 01: P2 反AI味生成质量升级（AA-02 对比减法 + AA-03 创意度）

## 目标

延续 P2 深化（Author Writing Sheet 词汇签名 260614-1tp、AI 评审团 260613-edreview 之后），
推进 Phase 26（多信号反AI味 + 温度优化）的两项研究驱动功能：

- **AA-02 对比减法**（CoPA, Fang et al. EMNLP 2025）：在生成 prompt 中注入分解式
  「减去机器味」指令块，明确要求 AI 减去 4 个具体机器味模式（均匀句长 / 过度完美逻辑 /
  机械化过渡词 / 缺乏人类突发性），并引入情绪驱动的节奏突变。这与词库（BannedListMiddleware）
  正交——词库是「禁止说某些词」，对比减法是「禁止以机器的方式组织句子」，是不同维度。
- **AA-03 创意度维度**（TempParaphraser, Huang et al. EMNLP 2025，检测率降 82.5%）：
  把深埋在 provider 配置里的 temperature 提升为用户可见的「创意度」三档（保守/平衡/灵动），
  在生成调用点用它覆盖 provider.temperature。

## 论文背书

| 功能 | 论文 | 关键结论 |
|------|------|---------|
| AA-02 对比减法 | CoPA, Fang et al. EMNLP 2025 | 对比学习减去机器味模式，胜率显著提升 |
| AA-01 多信号 | Li & Zhang CCL 2025 | 仅词库远不够，91.8% F1 需多信号（句长均匀度/信息密度/情感曲线/描述均衡/逻辑完美度）|
| AA-03 温度 | TempParaphraser, Huang et al. EMNLP 2025 | 适度高温采样使 AI 文本检测率降 82.5% |

注：AA-01 的多信号「检测」侧已由 Phase 19 style_deviation_detector 实现（5 维 + aiScentScore）。
本任务聚焦「生成」侧的 AA-02（prompt 对比减法）+ AA-03（采样温度）。

## 现状核查（已完成）

- `dynamic_persona_middleware.dart` anchor（line 98-101）：`核心要求：...避免任何AI生成的痕迹，
  包括但不限于套话连接词、公式化句式、过度均衡的描写、过于完美的逻辑。` —— 部分提及但
  **紧凑通用、不可执行**，缺乏 burstiness/机械化过渡词/跳跃留白的具体指令。
- `temperature` 深埋在 `provider_management_page.dart`（全局 provider 配置），无用户层概念；
  `continuation_suggestion_notifier.dart:131` 硬编码 0.8。
- pipeline 装配：`prompt_pipeline.dart:246`（synthesis）+ `editor_prompt_pipeline.dart:41`（editor），
  两处 `BannedListMiddleware()` 之后是注入点。
- `SettingsRepository` / `autoDeviationCheckProvider` / settings_page SwitchListTile 是 AA-03 的精确模板。

## 两个原子提交

### 提交 1：AA-02 对比减法 ContrastiveSubtractionMiddleware

TDD Red → Green → wire → analyze/test → commit。

注入块（中文，4 模式 + 突发性指令）：

```
\n\n**对比减法 — 主动减去机器味**：
人类写作有自然的「不规则突发性」（burstiness），AI 写作倾向机械均衡。请在以下四点主动减去机器味：
1. 句长：避免均匀的句式长度，主动交替使用长短句（短句制造冲击，长句铺陈氛围）。
2. 逻辑链：避免过度完美的因果闭环，允许跳跃、留白、非线性推进——真实叙述有缝隙。
3. 过渡词：避免「然而/此外/综上所述/不仅...而且/值得一提的是」等机械化连接，改用情境与动作自然衔接。
4. 节奏：允许情绪驱动的节奏突变，不要每个段落都匀速推进。
```

关键设计：
- 与 BannedListMiddleware **正交**：bannedPhrases 为空时仍注入（测试覆盖）。
- 保留 dynamic_persona anchor 不变（additive）。
- const 构造，遵循 PromptMiddleware const 子类约定。

### 提交 2：AA-03 创意度 CreativityLevel

TDD Red → Green → wire → UI → analyze/test → commit。

- `CreativityLevel` 枚举：`conservative(0.6) / balanced(0.8 默认) / expressive(0.95)`，
  `temperature` getter + `fromJson`/`toJson` + 中文 `label`。
- `SettingsRepository.getCreativityLevel()` / `saveCreativityLevel()`（Hive key
  `creativity_level`，默认 balanced）。
- `creativityLevelProvider` + `CreativityLevelNotifier`（复刻 autoDeviationCheck 模式）。
- `PromptContext.creativityLevel` 可选字段（穿透 addMessage/replaceSystemMessage）。
- `editor_ai_notifier.dart:187` + `synthesis_notifier.dart:249`：
  `temperature: context.creativityLevel?.temperature ?? provider.temperature`。
- 设置页新增创意度控件（SegmentedButton 三档 + 说明「影响 AI 生成的多样性，灵动档降低机器味」）。

## 验证标准

- `flutter analyze` → No issues found!（零 issue）
- `flutter test` → 全绿，基线（约 1548）+ AA-02 测试 + AA-03 测试，零回归
- AA-02 测试断言：4 模式关键词都在、bannedPhrases 空时仍注入、anchor 保持、注入块在 banned_list 之后
- AA-03 测试断言：三档温度映射正确（0.6/0.8/0.95）、fromJson/toJson 往返、provider 默认 balanced 并持久化
- ECC flutter-reviewer 审查无 HIGH
- kimi-webbridge DOM evaluate 验证创意度控件渲染（CanvasKit 不渲染，用 evaluate 不用 screenshot）

## 威胁模型

- T-1（prompt 注入膨胀）：对比减法块约 200 字，占 token 预算 <2%，可接受；注入固定常量无用户输入污染。
- T-2（向后兼容）：CreativityLevel 默认 balanced(0.8) 与历史 temperature 默认行为一致；旧持久化数据无该 key 时 getCreativityLevel 返回 balanced。
- T-3（覆盖语义）：creativityLevel != null 覆盖 provider.temperature 是显式用户意图（用户在设置页主动选档），非静默改写；保留 null 透传 provider.temperature 的旧路径。
- T-4（pipeline 顺序）：对比减法在 banned_list 之后、knowledge_injection 之前——词库先禁词，再给组织句子的减法指令，顺序合理。
