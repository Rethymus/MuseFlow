---
phase: quick-260614-ci1
plan: 01
subsystem: ai/interaction
tags: [dialogue, interaction, nlp, classification]
requires: [Phase 22 multi-turn conversation]
provides:
  - DialogueAct 枚举（5 PATHs 行为 + 中文 label）
  - DialogueActClassifier（关键词信号分类，纯逻辑）+ DialogueActClassification（act/置信度/匹配词）
metrics:
  duration: ~15 min
  completed: 2026-06-14
  baseline_tests: 1602
  final_tests: 1611
  new_tests: 9
  regressions: 0
---

# Phase quick-260614-ci1: CI-01 PATHs 对话行为识别 Summary

推进 P2 项 CI-01（Mysore et al. EMNLP 2025 SAC Highlight；research "命题：创作交互增强"）。人机创作协作可归纳为 5 种反复出现的对话行为；识别当前行为让 AI **适配响应策略**而非每轮等同对待。

## 交付（纯逻辑，零依赖）

**DialogueAct 枚举（5 行为 + 中文 label）**
- `styleAdjustment`（风格调整）："改语气/换风格" → 克制改写
- `contentExploration`（内容探索）："如果…会怎样" → 提供分支备选
- `intentRevision`（意图修订）："不对，我要的是…" → 停下重新对齐意图
- `followUp`（追问深入）："为什么/展开" → 提供深度，不造新内容
- `injection`（内容注入）："加一段/补充" → 忠实插入所求内容

**DialogueActClassifier（关键词信号分类）**
- 每行为一组信号短语，计分=该行为distinct匹配数；最高分胜出
- 平局按固定优先级（injection > styleAdjustment > contentExploration > intentRevision）破结，倾向更具可操作性的解读
- 无匹配 → 默认 followUp（对歧义轮最安全的非破坏性响应是"给更多深度"）
- `DialogueActClassification` 含 act + matchedKeywords（可解释）+ confidence（匹配密度 [0,1]）

## 设计决策

- **纯逻辑、零依赖**：响应策略适配的 wiring（把 act 注入 multi-turn conversation 流程 / editor_ai_notifier 的 conversation history）留后续——本沙箱无真实 API 无法端到端验证适配效果，纯分类器已可被未来流程消费。
- **关键词信号而非 LLM 分类**：零额外 token 成本、确定性、可测试；PATHs 的 5 行为在中文创作语境有清晰词汇指纹（改/语气/如果/不对/为什么/加入）。若未来需更高准确率，可在本接口后接轻量 LLM 分类，外部不变。
- **默认 followUp 而非 injection**：歧义消息误判为"注入新内容"会污染正文；误判为"追问深入"只多说几句，可逆。

## 验证

- `flutter analyze` → No issues found!
- `flutter test` → 全绿零回归（基线 1602 → +9）

9 测试覆盖：5 行为各自识别（风格调整/内容探索/意图修订/追问深入/内容注入各 2 例）、歧义默认 followUp、匹配词可解释、置信度 [0,1]、每行为有中文 label。

## 与 Phase 22 协同

Phase 22 多轮对话（5 轮内存态）+ 续写引导（3 方向）是交互基础设施；CI-01 在其上增加**意图感知**——识别用户每轮的协作行为类型。下一步 wiring：在 editor_ai_notifier 处理用户指令时 `classify(instruction)`，按 act 选择不同 system prompt 模板（如 intentRevision → 先复述理解确认，injection → 严格锚定选区）。
