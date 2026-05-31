# MuseFlow 灵韵

> 想象力为骨，AI为翼。

人机协作、去流水线化、轻量跨平台的创作辅助工具。不是替代你写故事的"打字机"，而是帮你理顺思绪、打磨文字的"磨刀石"。

**技术栈**: Flutter (Windows/Android) | Dart | Hive | 多AI模型适配

---

## 三插件架构

本项目集成 OMC（主）、ECC（辅）、GSD（辅）三个 Claude Code 插件，按职责分工互不冲突。

### 职责划分

| 插件 | 定位 | 核心能力 |
|------|------|---------|
| **OMC** | 编排引擎 | 多代理协调、并行执行、会话管理 |
| **ECC** | 知识库 | Flutter/Dart 专业审查、TDD、安全审查 |
| **GSD** | 规格驱动 | 上下文防腐、spec→plan→execute |

### Agent 路由表

遇到同名 agent 时，按此优先级路由：

| 场景 | 负责插件 | Agent |
|------|---------|-------|
| 架构设计 | OMC | `architect` |
| 代码审查 | OMC | `code-reviewer` |
| 安全审查 | ECC | `security-reviewer` |
| 任务规划 | OMC | `planner` |
| TDD 引导 | ECC | `tdd-guide` |
| Flutter 审查 | ECC | `flutter-reviewer` |
| Dart 构建 | ECC | `dart-build-resolver` |
| 规格驱动开发 | GSD | `gsd-planner`, `gsd-executor` |
| 多代理并行 | OMC | `ultrawork`, `team` |
| 快速执行 | OMC | `autopilot`, `ralph` |

### Command 路由

| 命令 | 来源 | 用途 |
|------|------|------|
| `/plan` | OMC | 交互式规划 |
| `/autopilot` | OMC | 自动驾驶 |
| `/ultrawork` | OMC | 并行执行 |
| `/verify` | OMC | 验证实现 |
| `/code-review` | ECC | 代码审查 |
| `/tdd` | ECC | TDD 工作流 |
| `/gsd` | GSD | 规格驱动开发（含 discuss/plan/execute） |

### Hook 策略

精选保留，避免叠加：

- **OMC**: 全部 hooks 保留（编排核心）
- **ECC**: 仅保留 `config-protection`、`governance-capture`、`doc-file-warning`、`suggest-compact`
- **GSD**: 仅保留 `gsd-context-monitor`、`gsd-prompt-guard`、`gsd-validate-commit`

---

## 推荐工作流

### 新功能开发

```
/gsd discuss → /gsd plan → /gsd execute → /code-review → /verify
```

### 快速迭代

```
/autopilot "描述" → /verify
```

### 大型重构

```
/plan → /ultrawork → /code-review → /verify
```

### Bug 修复

```
/gsd debug → 修复 → /verify
```

---

## 编码标准

- **语言**: Dart，遵循官方规范
- **状态管理**: Riverpod
- **架构**: Clean Architecture（domain → application → infrastructure → presentation）
- **不可变性**: 所有数据类使用 `copyWith`，禁止 mutation
- **错误处理**: 使用 `Result<T>` 类型，全面 try-catch
- **测试**: TDD，覆盖率 ≥ 90%
- **格式化**: `flutter format` + `flutter analyze` 零错误

## 性能目标

| 指标 | 目标 |
|------|------|
| 启动时间 | < 3秒 |
| 安装包 (Windows) | < 100MB |
| 内存占用 | < 200MB |
| 帧率 | 60fps |

---

*Version: 2.0 | Updated: 2026-05-31 | 三插件架构*
