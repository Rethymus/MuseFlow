# 插件路由规则

> 当多个插件提供相同能力时，按此规则路由。

## Agent 冲突解决

以下同名 agent 按优先级选择（前者优先）：

- **architect** → OMC（统一视图，擅长系统设计）
- **code-reviewer** → OMC（质量更高，支持 severity 分级）
- **planner** → OMC（有 interview 交互流程）
- **security-reviewer** → ECC（更专业，OWASP Top 10 全覆盖）

## 使用 ECC 专用 Agent 的场景

当遇到以下任务时，使用 ECC 的专用 agent：

- Flutter/Dart 代码审查 → `ecc/flutter-reviewer`
- Dart 构建错误 → `ecc/dart-build-resolver`
- TDD 引导 → `ecc/tdd-guide`
- 重构清理 → `ecc/refactor-cleaner`

## 使用 GSD Agent 的场景

GSD agent 全部 `gsd-` 前缀，无冲突。适用场景：

- 规格驱动开发（新功能）→ `gsd-planner` → `gsd-executor` → `gsd-verifier`
- 代码库探索 → `gsd-codebase-mapper`
- 调试 → `gsd-debugger`
- 安全审计 → `gsd-security-auditor`

## Command 路由

| 需求 | 使用 |
|------|------|
| 交互式规划 | `/plan`（OMC）|
| 快速执行 | `/autopilot`（OMC）|
| 并行任务 | `/ultrawork`（OMC）|
| 验证 | `/verify`（OMC）|
| 代码审查 | `/code-review`（ECC）|
| TDD | `/tdd`（ECC）|
| 规格驱动开发 | `/gsd`（GSD）|
| 上下文监控 | GSD context-monitor 自动运行 |
