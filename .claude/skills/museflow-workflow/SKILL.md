---
name: museflow-workflow
description: MuseFlow 开发工作流速查 — 功能开发/Bug修复/重构的 GSD+TDD 步骤序列与提交规范。规划这三类工作时加载，按需调用对应插件命令。
when_to_use: 规划新功能开发、bug 修复、重构时；需要确认提交流程或工作流步骤时
---

# MuseFlow 开发工作流

本 skill 承载 procedure 型工作流步骤（按需加载）。每轮强制的事实型约束（提交规范、禁止事项）仍在 `.claude/rules/04-workflow.md`。三插件协作：GSD(规格驱动) + OMC(编排) + ECC(Flutter/Dart 审查)。

## 功能开发（推荐）

```
/gsd discuss   → /gsd plan → /tdd → /gsd execute → /code-review → /verify → git commit
```
1. `/gsd discuss` — 需求讨论, 明确规格
2. `/gsd plan` — 生成实施计划
3. `/tdd` — 编写测试（先写测试！ECC 引导）
4. `/gsd execute` — 实现功能
5. `/code-review` — 代码审查（ECC flutter-reviewer）
6. `/verify` — 验证实现
7. `git commit` — 提交变更

## 快速迭代

```
/autopilot "描述" → /verify → git commit
```

## Bug 修复

```
定位根因 → 编写失败测试(RED) → 修复代码(GREEN) → /verify → git commit
```
1. 描述问题 → 定位根因（可用 `/gsd debug`）
2. 编写失败测试（RED）
3. 修复代码（GREEN）
4. `/verify` — 验证修复
5. `git commit`

## 重构

1. 确认测试覆盖率 ≥ 90%
2. 每次只改一个关注点
3. 小步前进, 每步运行测试
4. `/code-review` — 审查
5. `git commit`

## 大型重构

```
/plan → /ultrawork → /code-review → /verify
```
