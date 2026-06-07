# Phase 13: Automation Test Harness - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-07
**Phase:** 13-automation-test-harness
**Areas discussed:** FakeAdapter 架构, TEST-01 测试结构, TEST-02 覆盖范围

---

## FakeAdapter 架构

### 问题 1: FakeAdapter 如何与现有 OpenAIAdapter 关联？

| Option | Description | Selected |
|--------|-------------|----------|
| 提取接口 | 从 OpenAIAdapter 抽出抽象类 AIAdapter，FakeAdapter 和 OpenAIAdapter 都实现它。改动现有代码，但 provider override 最干净，类型安全。 | ✓ |
| Duck-typing override | FakeAdapter 是独立类，override openaiAdapterProvider 时放宽类型。不改生产代码，但类型安全弱。 | |
| Override 下游 services | 不修改 openaiAdapterProvider，改为 override 下游 service providers。隔离性好但 override 点多。 | |

**User's choice:** 提取接口 (Recommended)

### 问题 2: 接口命名

| Option | Description | Selected |
|--------|-------------|----------|
| AIAdapter | 名称简洁通用，与项目中其他 adapter 命名风格一致。 | ✓ |
| AIStreamAdapter | 强调流式输出特性，但未来如果添加非流式方法会显得不准确。 | |
| AIProviderAdapter | 强调"提供商"角色，但 OpenAIAdapter 不叫 OpenAIProvider，风格不一致。 | |

**User's choice:** AIAdapter (Recommended)

### 问题 3: 重构范围

| Option | Description | Selected |
|--------|-------------|----------|
| 仅 OpenAIAdapter | 只改 OpenAIAdapter + providers.dart，风险最小。 | ✓ |
| 所有 adapter 统一 | 同时为 Claude/Ollama 预留接口位置（空实现）。 | |

**User's choice:** 仅 OpenAIAdapter (Recommended)

### 问题 4: FakeAdapter 错误支持

| Option | Description | Selected |
|--------|-------------|----------|
| 可配置错误参数 | FakeAdapter 接受可选配置：errorRate、errorText、emptyResponse。 | ✓ |
| 多个 FakeAdapter 子类 | 为每种错误场景创建独立子类。 | |
| 固定序列行为 | 通过 _callCount 控制行为，第 N 次调用返回错误。 | |

**User's choice:** 可配置错误参数 (Recommended)

---

## TEST-01 测试结构

### 问题 5: 测试粒度

| Option | Description | Selected |
|--------|-------------|----------|
| 5 段 + 1 E2E | create_manuscript、create_100_chapters、ai_generation、export、token_audit + 1 full_flow_e2e。 | |
| 8 段 + 1 E2E | 更细分：文稿 CRUD、章节 CRUD、章节排序、AI 单章、AI 批量、导出 Markdown、导出验证、token 审计 + 1 E2E。 | ✓ |
| 单一端到端 | 一个 test() 从头跑到尾。 | |

**User's choice:** 8 段 + 1 E2E

### 问题 6: E2E 规模

| Option | Description | Selected |
|--------|-------------|----------|
| 100 章 | 创建文稿→100章→100次AI调用→导出→验证。需 5 分钟超时。 | ✓ |
| 10 章 | 更快完成，但无法验证大规模数据。 | |
| 30 章 | 匹配 Phase 14 的实际章节规模。 | |

**User's choice:** 100 章 (Recommended)

### 问题 7: 导出测试策略

| Option | Description | Selected |
|--------|-------------|----------|
| Override ExportService | 注入内存 writer，不触碰生产代码。 | |
| 真实文件 + 临时目录 | 创建真实临时文件，导出后读取验证。更接近真实。 | ✓ |
| 仅验证 UI 流程 | 只验证导出 UI 交互，不验证文件内容。 | |

**User's choice:** 真实文件 + 临时目录

---

## TEST-02 覆盖范围

### 问题 8: 错误场景

| Option | Description | Selected |
|--------|-------------|----------|
| 仅 Happy path | 只验证正常流程。 | |
| Happy path + 边界情况 | 额外覆盖空状态、取消操作、异常文本。 | |
| 含错误场景 | 完全覆盖错误路径。 | ✓ |

**User's choice:** 含错误场景

**错误场景选择（multiSelect）:** 空状态/无配置, AI返回异常内容, 删除后导航, 快速重复操作（全部 4 项）

### 问题 9: 集成测试 Hive 初始化

| Option | Description | Selected |
|--------|-------------|----------|
| 复用现有 helper | 复用 hive_test_helper.dart（Directory.systemTemp + deleteFromDisk）。 | ✓ |
| 新建专用 helper | 创建 integration_test/helpers/ 目录。 | |

**User's choice:** 复用现有 helper (Recommended)

---

## Claude's Discretion

- AIAdapter 抽象接口的具体文件位置
- 8 段分段测试的函数命名和断言粒度
- FakeAdapter 错误参数的 API 设计（构造函数 vs 配置方法）
- E2E 测试中 100 章 AI 调用的并发策略
- 集成测试的错误场景测试函数数量和分组
- test_container.dart 中 ProviderContainer 工厂的 override 列表

## Deferred Ideas

None — discussion stayed within phase scope.
