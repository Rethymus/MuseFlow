---
phase: quick
plan: 260616-uho
subsystem: manuscript-editor
tags: [refactor, dart-part, mechanical-split, redline-elimination]
requires:
  - TECH-DEBT-800-REDLINE
  - qxe-anti-ai-scent-split
  - rj4-providers-split
provides:
  - editor_with_sidebar < 800 lines (redline eliminated)
  - reusable extension-on-State + same-library part pattern
affects:
  - lib/features/manuscript/presentation/editor_with_sidebar.dart
tech-stack:
  added: []
  patterns:
    - "Dart part/part of same-library mechanism"
    - "extension on _StateClass for cross-file method split (Dart has no partial class)"
key-files:
  created:
    - lib/features/manuscript/presentation/editor_with_sidebar_intents.dart
    - lib/features/manuscript/presentation/editor_with_sidebar_layout.dart
  modified:
    - lib/features/manuscript/presentation/editor_with_sidebar.dart
decisions:
  - "Use private extension _EditorWithSidebarStateLayout to host layout helpers — Dart's same-library extension-on-this resolves bare calls in build() with zero call-site changes"
  - "Keep all 23 imports in main library file (part files forbid imports, per Dart rule and qxe/rj4 precedent)"
metrics:
  duration: ~15min
  completed: 2026-06-16
  tasks_completed: 2
  files_changed: 3
---

# Phase quick Plan 260616-uho: editor_with_sidebar.dart Part-Split Summary

机械拆分 `editor_with_sidebar.dart`（887 → 640 行）消除 `03-flutter-standards.md` 800 行红线——qxe/rj4 "800 行红线消除" 战役收尾的最后一步，拆分后全仓零文件违反行数红线。

## What Changed

### 主文件 `editor_with_sidebar.dart`（887 → 640 行，-247）
- 顶部新增 `library;` 块 + doc comment（unnamed implicit library，与 qxe/rj4 一致）
- 最后一个 import 后新增 2 个 part 指令
- 删除已搬走的声明：`_buildManuscriptStylesheet` 函数、4 个 layout 辅助方法、7 个 `_XxxIntent` 类、`_SelectionLeadersLayerBuilder` 类
- 保留：23 个 import、`EditorWithSidebar` 公共类、`_EditorWithSidebarState` 类（initState/dispose/lifecycle/章节管理/自动保存/build + 编辑器快捷键 `_toggleBold`/`_toggleItalic`/`_undoLastAIChange`）
- `build()` 内的裸调用 `_buildDesktopLayout(...)` / `_buildMobileLayout(...)` / `_buildEditorArea(...)` / `_buildManuscriptStylesheet(...)` / `const _PreviousChapterIntent()` 等**零改动**——Dart 同库语义自动解析

### 新建 `editor_with_sidebar_intents.dart`（82 行）
- `_buildManuscriptStylesheet(BuildContext)` 顶层函数
- 7 个 Intent 类：`_PreviousChapterIntent`/`_NextChapterIntent`/`_NewChapterIntent`/`_BoldIntent`/`_ItalicIntent`/`_UndoAIIntent`/`_QuickInsertIntent`
- `_SelectionLeadersLayerBuilder` 类

### 新建 `editor_with_sidebar_layout.dart`（196 行）
- `extension _EditorWithSidebarStateLayout on _EditorWithSidebarState` 承载 4 个 layout 辅助方法
- 方法体逐字符搬入，未改动

## Key Mechanism

Dart 不支持 partial class，单个 `State` 类体无法跨文件拆分。本任务采用**私有扩展** `extension _EditorWithSidebarStateLayout on _EditorWithSidebarState` 承载 layout 辅助方法——同库 part 机制下，`build()` 内的裸调用经 Dart 同库 extension-on-this 解析为零改动（与 rj4 part 间 provider 互引裸名解析同理）。

## Verification Results

| Gate | Result |
|------|--------|
| 主文件行数 < 800 | ✅ 640 行 |
| `library;` + 2 part 指令就位 | ✅ |
| part 文件首行 `part of 'editor_with_sidebar.dart';` | ✅ 两文件均符合 |
| part 文件零 import/export | ✅ |
| 已搬声明从主文件消失 | ✅ |
| **`flutter analyze` 全仓** | ✅ **No issues found! (5.1s)** |
| **`flutter test` 全仓** | ✅ **1647 passed + 12 skipped, exit 0** |
| diff 仅触动 3 文件 | ✅ 主文件改 + 2 新 part |
| 消费方零改动 | ✅ `lib/app.dart` + `test/features/manuscript/presentation/editor_with_sidebar_test.dart` 零 diff |

## Commits

| Task | Hash | Description |
|------|------|-------------|
| 1 | `6211bd3` | 抽取 intents/layout 到 2 个 part 文件（278 insertions） |
| 2 | `159d58a` | 主文件接入 library/part 指令并删除已搬声明（+10/-257） |

## Consumer Impact

零改动。2 个消费方均导入主库文件路径：
- `lib/app.dart:9` — `import '...editor_with_sidebar.dart';`
- `test/features/manuscript/presentation/editor_with_sidebar_test.dart:13` — 同上

公共类 `EditorWithSidebar` 签名/语义零变更。

## Deviations from Plan

None - plan executed exactly as written. 零偏差，零 Rule 1-3 触发。

## Threat Model Compliance

T-uho-01 (Tampering / 重构正确性): 双重验证门均通过——`flutter analyze` 0 issues 静态捕获 part 配对/extension 解析/import 完整性，`flutter test` 1647 passed 动态行为等价证明。

## Campaign Context

qxe/rj4/uho "800 行红线消除" 战役完成：
- **qxe** (commit f204855): `anti_ai_scent_processor.dart` 1091 → 555 行
- **rj4** (commits 0cc2180..e2fe3ef): `providers.dart` 856 → 103 行
- **uho** (本次): `editor_with_sidebar.dart` 887 → 640 行

全仓零文件违反 `03-flutter-standards.md` 800 行红线。

## Self-Check

- [x] `lib/features/manuscript/presentation/editor_with_sidebar.dart` 存在，640 行
- [x] `lib/features/manuscript/presentation/editor_with_sidebar_intents.dart` 存在，82 行
- [x] `lib/features/manuscript/presentation/editor_with_sidebar_layout.dart` 存在，196 行
- [x] commit `6211bd3` 存在于 git log
- [x] commit `159d58a` 存在于 git log
- [x] `flutter analyze` No issues found
- [x] `flutter test` 1647 passed + 12 skipped

## Self-Check: PASSED
