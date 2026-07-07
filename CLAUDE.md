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
- **格式化**: `dart format --set-exit-if-changed .` + `flutter analyze` 零错误

### 仓库验证脚本

修改 README、CI、平台支持、存储边界、AI adapter 注入、`.claude` 配置或 shell 脚本时，优先运行对应的轻量 guard：

```bash
scripts/check_readme_assets.sh
scripts/check_repo_hygiene.sh
scripts/check_shell_scripts.sh
scripts/check_ai_adapter_wiring.sh
scripts/check_editor_docs.sh
scripts/check_dependency_docs.sh
scripts/check_storage_architecture.sh
scripts/validate_platform_support.sh
```

## 性能目标

| 指标 | 目标 |
|------|------|
| 启动时间 | < 3秒 |
| 安装包 (Windows) | < 100MB |
| 内存占用 | < 200MB |
| 帧率 | 60fps |

---

*Version: 2.0 | Updated: 2026-05-31 | 三插件架构*

<!-- GSD:project-start source:PROJECT.md -->
## Project

**MuseFlow 灵韵**

MuseFlow 灵韵是一个人机协作的小说创作辅助工具，面向"有故事但拙于表达"的创作者。它不是AI代写的打字机，而是一块磨刀石——帮助作者将脑中混乱的画面理顺、润色、连缀成文，同时确保每一行文字都带有"人"的温度。

基于Flutter实现Windows/Android跨平台，采用"碎片捕捉→AI整理→精细打磨"的三段式创作流程，配合知识库自动注入和故事结构守护，解决从灵感碎片到成稿的完整链路。

**Core Value:** **让AI帮你写好故事，但让读者看不出AI的痕迹。** 反AI味是产品灵魂，不是附加功能。

### Constraints

- **技术栈**: Flutter (Dart) — Windows/Android跨平台
- **状态管理**: Riverpod
- **本地存储**: Hive数据库 + JSON导出
- **原生输入法**: 必须调用系统级IME，禁止应用内嵌入输入框（确保五笔、搜狗等输入法兼容）
- **安装包**: Windows < 100MB
- **启动速度**: < 3秒
- **数据隐私**: 配置与文稿仅存本地；API Key 通过平台安全存储加密保存，不写入 Hive 数据库
- **防滥用**: UI设计不提供"一键生成"按钮，强制分段交互
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## Overview
## Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Flutter SDK | 3.44.0 (stable) | Cross-platform UI framework | Project baseline in `.planning/PROJECT.md`. Windows desktop + Android. IME support via TSF on Windows is mature since 3.x. |
| Dart SDK | ^3.12.0 | Language | Matches the `environment.sdk` constraint in `pubspec.yaml`; ships with Flutter and is required for current language features. |
| flutter_riverpod | ^3.3.1 | State management | Project baseline in `.planning/PROJECT.md`. Code-gen based providers with `@riverpod` annotation. AsyncNotifier for LLM streaming. |
| riverpod_annotation | ^4.0.2 | Provider annotations | Pairs with riverpod_generator. Compile-time safe provider definitions. |
| riverpod_generator | ^4.0.3 | Code generation for providers | Eliminates boilerplate. Generates `_$NotifierName` base classes. |
| freezed | ^3.2.5 | Immutable data classes | Union types for Result/Either, copyWith generation, JSON serialization. Critical for domain entities. |
| freezed_annotation | ^3.1.0 | Freezed annotations | Runtime companion to freezed code gen. |
| build_runner | latest | Code generation runner | Required by riverpod_generator and freezed. Run with `dart run build_runner watch -d`. |
## Editor Stack
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **super_editor** | ^0.3.0-dev.20 | Rich text editor | Current implementation and Phase 0 benchmark winner. Used by editor, manuscript, onboarding, diff/provenance, and story-structure surfaces. Supports document-model editing, custom overlays/layers, and desktop text workflows. |
### Why super_editor over flutter_quill
| Criterion | super_editor | flutter_quill |
|-----------|----------------|---------------|
| Editor integration | `SuperEditor` plus `Editor`/`MutableDocument` are already wired across production and tests | Migration would replace existing editor contracts |
| Custom overlays | Layer builders are used for selection leaders, context anchors, and diff overlays | Custom embeds via Delta, more complex |
| Document model | Mutable document nodes are structured enough for story tracking and targeted insertion | Delta-based flat operation log, harder to query |
| Regression coverage | Existing editor, onboarding insertion, and SSE insertion tests import `super_editor` directly | No equivalent local coverage |
## AI Integration
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **openai_dart** | ^6.0.0 | OpenAI API client + OpenAI-compatible providers | Type-safe Dart client. Supports custom `baseUrl` -- covers DeepSeek and Ollama (both expose OpenAI-compatible endpoints). Streaming via `createChatCompletionStream()`. |
| **anthropic_sdk_dart** | ^4.0.0 | Claude API client | Dedicated Dart SDK for Anthropic's Messages API with streaming and tool use. Claude has a non-OpenAI-compatible API, so a separate client is necessary. |
| **ollama_dart** | ^2.2.0 | Ollama local LLM client | Dedicated client for Ollama's REST API. Provides model listing, chat, generation. Use alongside openai_dart for Ollama (Ollama supports both its native API and OpenAI-compatible endpoints; ollama_dart gives richer model management). |
### Multi-Model Adapter Architecture
## Local Storage
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **hive_ce** | ^2.19.3 | Primary local NoSQL database | Community Edition of Hive. Actively maintained (original Hive 2.2.3 hasn't had meaningful updates). Supports encryption (AES-256 CBC), isolate-safe via `IsolatedHive`, automatic TypeAdapter generation with `@GenerateAdapters`, DevTools inspector. |
| **hive_ce_flutter** | ^2.3.4 | Flutter integration for Hive CE | Provides `Hive.initFlutter()` with proper path resolution on all platforms including Windows. |
| **flutter_secure_storage** | ^10.3.1 | Encrypted API key storage | Uses platform-specific secure storage (Windows Credential Manager via `flutter_secure_storage_windows`). For API keys that must never be in plaintext. |
### Why hive_ce over original Hive
| Criterion | hive_ce (2.19.3) | hive (2.2.3) |
|-----------|-------------------|---------------|
| Last updated | Active, frequent releases | Stale, minimal updates |
| TypeAdapter generation | `@GenerateAdapters` annotation, auto-registers | Manual or hive_generator (less maintained) |
| Isolate support | `IsolatedHive` built-in | Limited |
| Flutter Web WASM | Supported | Not supported |
| DevTools inspector | Built-in | None |
| Encryption | AES-256 CBC, same as original | AES-256 CBC |
### Storage Design
## Windows Desktop Support
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **window_manager** | ^0.5.1 | Native window management | Control window size, title bar, minimization behavior. Essential for a desktop-first writing app. |
### Windows IME (Input Method Editor)
- **No special package needed** -- Flutter's built-in `TextInputPlugin` on Windows handles IME composition
- **super_editor** integrates with Flutter text input and is the active editor dependency in `pubspec.yaml`
- The `TextEditingValue` and `TextEditingDelta` APIs handle composing text (the underlined in-progress text during IME input)
- **Constraint from `.planning/PROJECT.md`**: "Must use system-level IME, must not embed in-app input fields" -- this is satisfied by default Flutter behavior on Windows
## Navigation & Routing
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **go_router** | ^17.2.3 | Declarative routing | Flutter's recommended router. Deep linking, nested routes, redirect guards. Handles Windows desktop + Android navigation patterns. |
## Supporting Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| uuid | latest | Generate unique IDs for entities | All domain entities (manuscripts, chapters, characters, plot nodes) |
| logger | latest | Structured logging | Debug and development logging. Use `debugPrint` per project rules for UI debugging. |
| google_fonts | latest | Custom typography | Writer-facing app needs readable, tuned typography across editor and shell UI. |
| markdown | latest | Markdown parsing/rendering | Import/export of fragments and chapters in Markdown format. |
| path_provider | latest | Platform-specific paths | Locate app data directory for Hive initialization and export files. |
| share_plus | latest | Share functionality | Export and share manuscripts from Android. |
| file_picker | latest | File selection | Import/export files on Windows and Android. |
| url_launcher | latest | Open external URLs | Help links, license links, etc. |
| connectivity_plus | latest | Network status detection | Detect offline state for local-first behavior and API call guards. |
| json_annotation | latest | JSON serialization annotations | Pairs with `json_serializable` for DTO serialization. |
## Code Generation & Dev Tools
| Tool | Version | Purpose |
|------|---------|---------|
| build_runner | latest | Runs all code generators |
| json_serializable | latest | JSON serialization for DTOs |
| flutter_lints | latest | Lint rules (project uses strict analysis) |
## What NOT to Use
| Technology | Why NOT | What to Use Instead |
|------------|---------|-------------------|
| **sqflite / drift** | Overkill for a document-oriented writing app. Relational schema adds friction for flexible story structure. | hive_ce for NoSQL document storage |
| **Isar** | From the same author as Hive but heavier. Adds native binary dependencies. Hive CE is sufficient and lighter. | hive_ce |
| **firebase** | `.planning/PROJECT.md` explicitly excludes cloud sync for MVP. Adds Google dependency, privacy concerns for a creative writing tool. | hive_ce (local-only) |
| **supabase** | Same as firebase -- cloud backend excluded from MVP scope. | hive_ce (local-only) |
| **get_it / injectable** | Riverpod handles dependency injection natively. Adding a separate DI framework creates dual IoC containers. | Riverpod providers for DI |
| **bloc / cubit** | `.planning/PROJECT.md` mandates Riverpod. Bloc and Riverpod serve the same role. Mixing them is counterproductive. | Riverpod AsyncNotifier |
| **provider** | Legacy state management. Riverpod is the evolution. Using both causes confusion. | Riverpod |
| **shared_preferences** | Inappropriate for structured data. Only useful for trivial key-value settings. Hive boxes handle settings storage better. | hive_ce boxes |
| **flutter_quill** | Delta-based model harder to query for story structure, and the app already uses `super_editor` document/editor contracts. | super_editor |
| **dart_openai** | Older, less maintained OpenAI wrapper. `openai_dart` is the modern, type-safe alternative with broader OpenAI-compatible API support. | openai_dart |
| **http** (raw) | Low-level HTTP client. All LLM SDKs handle their own HTTP. Only needed if building a custom API from scratch. | LLM SDKs (openai_dart, anthropic_sdk_dart, ollama_dart) |
## Installation
# Create Flutter project (if not already scaffolded)
# Core framework
# Editor
# AI Integration
# Storage
# Desktop
# Navigation
# Supporting
# Dev dependencies
## Platform-Specific Notes
### Windows Desktop
- `window_manager` for native window control (size, title, minimize behavior)
- Flutter's TSF integration handles Chinese/Japanese/Korean IME natively
- `flutter_secure_storage` uses Windows Credential Manager for API key encryption
- Target: install package < 100MB (`.planning/PROJECT.md` constraint)
- File export/import via `file_picker` and `path_provider`
### Android
- Standard Flutter Android embedding
- `flutter_secure_storage` uses Android Keystore for API key encryption
- Share via `share_plus`
- `connectivity_plus` for network state awareness
## Sources
| Source | Confidence | What It Verified |
|--------|------------|------------------|
| pub.dev API (live queries) | HIGH | All package versions verified current as of 2026-05-31 |
| Local pubspec + source imports | HIGH | `super_editor ^0.3.0-dev.20` is the active editor dependency and production editor import |
| Context7 / Riverpod docs | HIGH | AsyncNotifier, code generation, @riverpod annotation patterns |
| Context7 / openai_dart docs | HIGH | Custom baseUrl for OpenAI-compatible APIs (DeepSeek, Ollama, Groq, Azure) |
| Context7 / hive_ce docs | HIGH | Encryption, adapter generation, isolate support, transactions |
| Context7 / Flutter docs | MEDIUM | Windows TSF/IME integration, TextInputClient API |
| Local Flutter SDK | HIGH | Flutter 3.44.0 stable with `pubspec.yaml` requiring Dart `^3.12.0` |
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

Project skills currently live in `.claude/skills/`:

| Skill | Purpose |
|-------|---------|
| `museflow-workflow` | On-demand MuseFlow development workflow reference for feature work, bug fixes, refactors, and commit conventions. |
| `run-museflow` | Launch and verification recipe for MuseFlow Flutter targets, including install, codegen, run, and secure-storage notes. |
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
