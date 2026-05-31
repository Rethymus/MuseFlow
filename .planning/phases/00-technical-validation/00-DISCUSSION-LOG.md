# Phase 0: Technical Validation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-31
**Phase:** 0-Technical Validation
**Areas discussed:** 编辑器备选方案, Spike 产出形式, IME 测试方式, 流式验证深度

---

## 编辑器备选方案

| Option | Description | Selected |
|--------|-------------|----------|
| 只测 super_editor | 专注验证一个编辑器，spike 更快 | |
| 同时测 super_editor + appflowy_editor | 两个编辑器跑同一套 benchmark，直接对比 | ✓ |
| 先测 super_editor，失败时再测 appflowy_editor | 折中方案 | |

**User's choice:** 同时测 super_editor + appflowy_editor
**Notes:** 工作量翻倍但能拿到完整对比数据，一次 spike 解决选型问题

| Option | Description | Selected |
|--------|-------------|----------|
| IME 兼容性优先 | 谁的 IME 更稳定就选谁 | |
| 大文档性能优先 | 300K+ 字文档流畅度是底线 | |
| 综合评分 | IME 40% + 性能 30% + API 20% + 社区 10% | ✓ |

**User's choice:** 综合评分（加权打分）
**Notes:** 不偏科，全面评估

| Option | Description | Selected |
|--------|-------------|----------|
| 自定义 block 组件 | 伏笔标记、角色注解等 overlay | |
| 浮动工具栏能力 | Phase 3 核心交互 | |
| 文档模型可查询性 | 溯源、标记定位 | |
| 以上全部都要考核 | 三个能力都是核心需求 | ✓ |

**User's choice:** 以上全部都要考核
**Notes:** 自定义 block + 浮动工具栏 + 文档模型可查询性全部纳入 API 可扩展性评分

---

## Spike 产出形式

| Option | Description | Selected |
|--------|-------------|----------|
| 一次性 test harness | 跑完 benchmark 就扔 | |
| 正式项目骨架 | flutter create + 四层结构，Phase 1 直接复用 | ✓ |
| 半正式结构 | 最小项目但按四层组织 | |

**User's choice:** 正式项目骨架
**Notes:** Phase 1 不用重复搭建

| Option | Description | Selected |
|--------|-------------|----------|
| 一步到位装全部依赖 | pubspec 一步到位，顺便验证兼容性 | ✓ |
| 最小化依赖只装 spike 必需 | spike 更纯粹，但后续还得再装 | |

**User's choice:** 一步到位装全部依赖
**Notes:** Phase 0 plan 00-03 (package compatibility matrix) 正好验证

---

## IME 测试方式

| Option | Description | Selected |
|--------|-------------|----------|
| 手动 checklist | 逐项测试，写 checklist 记录 | |
| 自动化 composition 模拟 | widget test 模拟 TextEditingDelta | |
| 自动化 + 手动双重验证 | 先自动化捕捉回归，再手动最终确认 | ✓ |

**User's choice:** 自动化 + 手动双重验证
**Notes:** 双重保障

| Option | Description | Selected |
|--------|-------------|----------|
| 只测 ROADMAP 列出的 3 个 | 搜狗拼音、五笔、微软拼音 | ✓ |
| 扩展到 5 个输入法 | 加微软五笔和手心输入法 | |
| 只测微软拼音 | 系统自带，覆盖主流 | |

**User's choice:** 只测 ROADMAP 列出的 3 个
**Notes:** 搜狗拼音、五笔、微软拼音

---

## 流式验证深度

| Option | Description | Selected |
|--------|-------------|----------|
| 最小化：只验证插入不卡顿 | mock SSE server 发送 token | |
| 中等：mock pipeline + 错误处理 | 验证基本工程可行性 | |
| 完整：真实 AI API 端到端 | 完整跑通发送→流式接收→插入编辑器 | ✓ |

**User's choice:** 完整：真实 AI API 端到端
**Notes:** 连接真实 OpenAI 或 DeepSeek API

| Option | Description | Selected |
|--------|-------------|----------|
| Ollama 本地模型 | 无需 API Key，但需安装 Ollama | |
| OpenAI / DeepSeek API | 真实云端 API | ✓ |
| 两者都支持，优先 Ollama | 灵活但多一步 | |

**User's choice:** OpenAI / DeepSeek API，不测 Ollama
**Notes:** 本地开发环境条件有限，不测试 Ollama 本地模型

---

## Claude's Discretion

- Exact benchmark methodology (document size steps, frame time measurement)
- Chinese test text generation approach
- Automated test structure and naming
- Benchmark result presentation format

## Deferred Ideas

None
