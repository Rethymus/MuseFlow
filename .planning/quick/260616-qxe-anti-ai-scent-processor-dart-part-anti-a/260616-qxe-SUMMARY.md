---
phase: quick-260616-qxe
plan: 01
subsystem: ai
tags: [refactor, file-size, dart-part, anti-ai-scent, mechanical-extraction]
requires:
  - "lib/features/ai/application/anti_ai_scent_processor.dart (1091 行, 13 static 数据表混入类体)"
provides:
  - "lib/features/ai/application/anti_ai_scent_lexicon.dart (546 行 part 文件, 13 同库顶级私有常量)"
  - "lib/features/ai/application/anti_ai_scent_processor.dart (555 行, 落回 03-flutter-standards.md 红线内)"
affects: []
tech-stack:
  added: []
  patterns:
    - "Dart part / part of 同库机制（library-private 符号跨文件可见，无需方法体改动）"
key-files:
  created:
    - "lib/features/ai/application/anti_ai_scent_lexicon.dart"
  modified:
    - "lib/features/ai/application/anti_ai_scent_processor.dart"
decisions:
  - "D-qxe-01: 把数据表抽到 part 文件而非新 library（保持 _ 前缀私有性 + 零调用点改动）"
  - "D-qxe-02: import 在 part 之前（Dart 语法要求 import_directive_after_part_directive；plan 写的 library→part→import 顺序需调整为 library→import→part）"
metrics:
  duration: "~8 分钟"
  completed: "2026-06-16"
  tasks: 2
  files: 2
---

# Phase quick-260616-qxe Plan 01: 抽取 anti_ai_scent_processor 数据表到 part 文件 Summary

纯机械重构：把 1091 行的 `anti_ai_scent_processor.dart`（违反 03-flutter-standards.md「最大 800 行」红线）中混入类体内的 13 个 static 数据表搬到新建 part 文件 `anti_ai_scent_lexicon.dart`，转成同库顶级私有常量。零行为变更、零调用点改动、零消费方影响。

## Changes Made

### Task 1: 新建 part 文件并机械搬运 13 个数据表

- 新建 `lib/features/ai/application/anti_ai_scent_lexicon.dart`（546 行）
- 首行 `part of 'anti_ai_scent_processor.dart';`
- 13 个同库顶级私有常量（去掉 `static` 关键字，保留 `_` 前缀与 `const`/`final` 修饰符）
  - 12 个 `const`（synonymMap / highlightOnlyPhrases / 5 genre cliches / mannerAdverbStems / formulaicEndings / emotionalCliches / descriptionFormulas / transitionCliches / xianxiaCliches）
  - 1 个 `final`（structuralPatterns，RegExp 列表不可 const 化）
- 数据内容（key/value/元素/中文注释/分隔线）逐字搬运，零字符改动
- Commit: `85ae39c`

### Task 2: 主文件接入 part 指令并删除已搬运数据表

- 主文件加 `part 'anti_ai_scent_lexicon.dart';` 指令（放在 `import 'dart:math'` 之后）
- 删除主文件 13 个 static 数据表声明（原 L128-664）
- 方法体零字符改动——所有 `_synonymMap.keys` / `_highlightOnlyPhrases.contains(...)` / `for (final p in _structuralPatterns)` / `_countPhraseHits(text, _xianxiaCliches)` 等裸名引用自动解析到 part 文件顶级私有常量（Dart 同库 library-private 语义）
- `AntiAIScentProcessor` 类 / 2 枚举 / 3 值类 / `synonymKeys` getter 全部保留在主文件，公共契约不变
- 主文件 1091 → 555 行（落回 200-400 推荐区间附近，远低于 800 红线）
- Commit: `c3538f9`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] part 指令位置需调整（Dart 语法约束）**
- **Found during:** Task 2 第一次 analyze
- **Issue:** PLAN.md 指定主文件顺序为 `library; → part 指令 → import`，但 Dart 语法禁止 import 出现在 part 指令之后（`import_directive_after_part_directive` 错误）
- **Fix:** 调整为 `library; → import 'dart:math' as math; → part 'anti_ai_scent_lexicon.dart';`（import 先于 part，符合 Dart 语法）
- **Files modified:** lib/features/ai/application/anti_ai_scent_processor.dart
- **Commit:** c3538f9

注：plan 写的 part 位置不影响功能正确性（同库私有解析不变），仅顺序受语法约束。修正是机械语法层面的，无设计变更。

## Verification Results

全部 6 项验证全绿：

| # | 验证项 | 期望 | 实际 | 状态 |
|---|--------|------|------|------|
| 1 | 主文件行数 < 800 | ~560 | 555 | ✅ |
| 2 | flutter analyze 两文件零错误 | 0 errors | No issues found | ✅ |
| 3 | anti_ai_scent_test.dart 全绿 | 57 测试 | 57 通过 | ✅ |
| 4 | git diff 触及文件 | 仅 2 个 | lexicon.dart + processor.dart | ✅ |
| 5 | part / part of 配对 | 各 1 | 各 1 | ✅ |
| 6 | 数据表数量 | 13 | 13 | ✅ |

## Consumer Impact

8+ 消费方文件零改动（git diff 仅触及主文件 + part 文件）：

- `lib/features/editor/presentation/editor_ai_state.dart`
- `lib/features/editor/presentation/status_bar.dart`
- `lib/features/editor/presentation/synthesis_panel.dart`
- `lib/features/editor/application/synthesis_notifier.dart`
- `lib/features/editor/presentation/banned_phrase_settings.dart`
- `lib/features/ai/application/intent_preservation_analyzer.dart`
- `lib/features/ai/presentation/providers.dart`
- 其他通过 `import .../anti_ai_scent_processor.dart` 引用枚举/值类/处理器的文件

所有公共类型导出（`HighlightType` / `ReviewSignalSeverity` / `ReviewSignal` / `TextHighlight` / `ProcessingResult` / `AntiAIScentProcessor`）完全不变。part 文件不参与 import 解析。

## Success Criteria

- [x] 主文件从 1091 行降至 555 行（< 800 红线）
- [x] `flutter analyze` 零错误（与基线一致）
- [x] `anti_ai_scent_test.dart` 57 行契约全绿
- [x] 8+ 消费方文件零改动（git diff 仅 2 个文件）
- [x] 13 个数据表内容逐字不变（仅 static 关键字移除 + 位置迁移）
- [x] 方法体零字符变更（Dart 自动解析同库顶级私有常量）

## Self-Check: PASSED

- FOUND: lib/features/ai/application/anti_ai_scent_lexicon.dart
- FOUND: lib/features/ai/application/anti_ai_scent_processor.dart
- FOUND: .planning/quick/.../260616-qxe-SUMMARY.md
- FOUND: 85ae39c (Task 1)
- FOUND: c3538f9 (Task 2)
- git status: 仅 SUMMARY.md 未追踪（orchestrator 处理 docs commit，符合约束）
