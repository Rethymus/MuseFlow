# Phase 12: Token Audit Infrastructure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-06
**Phase:** 12-Token Audit Infrastructure
**Areas discussed:** 拦截方式, UI 展示, 成本策略, 操作分类, 章节关联, 数据清理

---

## 拦截方式

| Option | Description | Selected |
|--------|-------------|----------|
| Adapter 层拦截 | 在 OpenAIAdapter.createStream() 返回值中附带 usage 数据，所有调用自动经过单一拦截点 | |
| Pipeline 中间件 | 类似现有 PromptPipeline 中间件链，新增 TokenAuditMiddleware，调用方传入操作类型等上下文 | ✓ |
| 各 Service 分散记录 | 在每个调用 AI 的 service/notifier 中手动记录 | |

**User's choice:** Pipeline 中间件
**Notes:** 用户选择不改 adapter 返回类型，而是在已有的 PromptPipeline 中间件链中加入审计中间件。

---

## UI 展示

| Option | Description | Selected |
|--------|-------------|----------|
| 嵌入现有统计页 | 在 WritingStatsPage 底部新增 Token 消耗区域（摘要+图表），与现有统计共存一页 | |
| 独立审计页面 | 新建独立 TokenAuditPage，从统计页 AppBar 导航进入 | |
| 摘要嵌入 + 详情独立 | WritingStatsPage 顶部放摘要卡片，详细图表在独立页面，两层信息分层展示 | ✓ |

**User's choice:** 摘要嵌入 + 详情独立
**Notes:** 摘要卡片（总 token、调用次数）嵌入 WritingStatsPage，详细分布图在独立页面。

---

## 成本策略

| Option | Description | Selected |
|--------|-------------|----------|
| 内置价格表 | 内置主流模型价格，用户选择模型时自动关联价格 | |
| 用户可配置 | 用户在设置中输入每千 token 价格，或选择预设模型自动填充 | |
| 本阶段只展示 token 数 | 只展示 token 数量和分布，不换算货币成本，REPORT-01 再处理成本推算 | ✓ |

**User's choice:** 本阶段只展示 token 数
**Notes:** 货币成本计算推迟到 Phase 16（REPORT-01）。

---

## 操作类型分类

| Option | Description | Selected |
|--------|-------------|----------|
| 固定枚举类型 | synthesis、rewrite、polish 等硬编码枚举 | |
| 功能分组归类 | 按功能入口归类：整理类、编辑类、世界观类、模板类 | ✓ |
| Claude discretion | 只要能区分不同操作且可读就行 | |

**User's choice:** 功能分组归类
**Notes:** 进一步确认为 4 组：整理类(synthesis)、编辑类(rewrite+polish+freeInput)、世界观类(skillGen+opening+deviationDetect)、模板类(templateComplete)。

---

## 章节关联

| Option | Description | Selected |
|--------|-------------|----------|
| 文稿级 + 章节级双维度 | 所有调用关联 manuscriptId，章节相关操作额外关联 chapterId | ✓ |
| 仅 chapterId | 无章节则为 null | |
| Claude discretion | 关联粒度由 Claude 决定 | |

**User's choice:** 文稿级 + 章节级双维度
**Notes:** 无章节上下文的调用（世界观类、模板类）仅关联 manuscriptId。

---

## 数据清理

| Option | Description | Selected |
|--------|-------------|----------|
| 不清理，永久保留 | 100 章规模数据量很小 | |
| 设上限自动清理 | 超过一定条数后自动清理最旧记录 | ✓ |
| Claude discretion | 由 Claude 决定 | |

**User's choice:** 设上限自动清理
**Notes:** 具体上限条数委托 Claude discretion（建议 10000 条）。

---

## Claude's Discretion

- 清理上限条数（建议 10000）
- TokenAuditMiddleware 具体实现方式
- 操作类型枚举命名
- Token 估算方法（API usage 字段 vs TokenBudgetCalculator 回退）
- TokenAuditPage 图表类型选择

## Deferred Ideas

- 货币成本计算 → Phase 16 (REPORT-01)
- Token 精确计数 (stream_options) → Out of Scope
