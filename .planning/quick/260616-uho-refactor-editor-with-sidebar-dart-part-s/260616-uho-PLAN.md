---
phase: quick
plan: 260616-uho
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/manuscript/presentation/editor_with_sidebar.dart
  - lib/features/manuscript/presentation/editor_with_sidebar_intents.dart
  - lib/features/manuscript/presentation/editor_with_sidebar_layout.dart
autonomous: true
requirements: [TECH-DEBT-800-REDLINE]
tags: [refactor, dart-part, mechanical-split, redline-elimination]

must_haves:
  truths:
    - "lib/features/manuscript/presentation/editor_with_sidebar.dart 行数 < 800（消除 03-flutter-standards.md 红线）"
    - "flutter analyze 全仓 0 issues（part/part of 配对正确、extension 裸调用解析正确、import 完整）"
    - "flutter test 全仓 1647 passed +12 skipped exit 0（行为等价证明，零回归）"
    - "公共类 EditorWithSidebar 签名/语义零变更（消费方 lib/app.dart 与测试零改动）"
    - "新建 part 文件首行为 `part of 'editor_with_sidebar.dart';` 且无 import（与 qxe/rj4 先例一致）"
  artifacts:
    - path: "lib/features/manuscript/presentation/editor_with_sidebar_intents.dart"
      provides: "_PreviousChapterIntent/_NextChapterIntent/_NewChapterIntent/_BoldIntent/_ItalicIntent/_UndoAIIntent/_QuickInsertIntent + _SelectionLeadersLayerBuilder + 顶层 _buildManuscriptStylesheet 函数"
      contains: "part of 'editor_with_sidebar.dart';"
    - path: "lib/features/manuscript/presentation/editor_with_sidebar_layout.dart"
      provides: "extension on _EditorWithSidebarState 承载 _buildDesktopLayout/_buildMobileLayout/_buildEditorArea/_getMenuPosition"
      contains: "extension _EditorWithSidebarStateLayout on _EditorWithSidebarState"
    - path: "lib/features/manuscript/presentation/editor_with_sidebar.dart"
      provides: "主库文件 — library; + 2 part 指令 + 全部 import + EditorWithSidebar 公共类 + _EditorWithSidebarState 类（build + 章节管理 + 自动保存 + 编辑器快捷键方法）"
      contains: "part 'editor_with_sidebar_intents.dart';"
  key_links:
    - from: "editor_with_sidebar.dart build() 中 _buildDesktopLayout(...) 裸调用"
      to: "editor_with_sidebar_layout.dart 中 extension on _EditorWithSidebarState"
      via: "Dart 同库 extension-on-this 裸名解析"
      pattern: "_buildDesktopLayout\\("
    - from: "editor_with_sidebar.dart build() 中 _buildManuscriptStylesheet(context) 裸调用"
      to: "editor_with_sidebar_intents.dart 中顶层私有函数"
      via: "Dart 同库顶级私有符号可见性"
      pattern: "_buildManuscriptStylesheet\\("
    - from: "editor_with_sidebar.dart Shortcuts map 中 const _PreviousChapterIntent()"
      to: "editor_with_sidebar_intents.dart 中 _PreviousChapterIntent 类"
      via: "Dart 同库私有类可见性"
      pattern: "_PreviousChapterIntent"
---

<objective>
机械拆分 `lib/features/manuscript/presentation/editor_with_sidebar.dart`（887 行）消除 03-flutter-standards.md 800 行红线——qxe/rj4 战役收尾的最后一步。

Purpose: 这是 qxe（anti_ai_scent_processor 1091→555）+ rj4（providers 856→103）"800 行红线消除"战役的第三步、也是全仓最后一个超 800 红线文件。拆分后全仓零文件违反行数红线。
Output: 2 个新建 part 文件（intents/layout）+ 主文件改造（加 `library;` + 2 part 指令，删除已搬声明），预期主文件 ~650 行。

【机制保证（与 qxe/rj4 同库 part 机制完全一致）】
- Dart part/part of 同库机制：part 文件与主库文件逻辑上属于同一编译单元，所有符号（含私有 `_xxx`）库内互相可见
- part 文件**禁止 import**（Dart 规则）——全部 import 留主库文件，与 rj4 完全一致
- `_EditorWithSidebarState` 是单个 State 类无法跨文件拆类体（Dart 无 partial class），但**同库 `extension on _EditorWithSidebarState` 可承载方法**：build() 内裸调用 `_buildDesktopLayout(...)` 经同库 extension-on-this 解析为零改动（Dart 语义保证）
- 公共类 `EditorWithSidebar` 不变，消费方 `lib/app.dart` + 测试导入路径与公共 API 零变更
</objective>

<execution_context>
@/home/re/code/MuseFlow/.claude/get-shit-done/workflows/execute-plan.md
@/home/re/code/MuseFlow/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@/home/re/code/MuseFlow/.planning/STATE.md
@/home/re/code/MuseFlow/.planning/PROJECT.md
@/home/re/code/MuseFlow/CLAUDE.md
@/home/re/code/MuseFlow/.claude/rules/03-flutter-standards.md

# 重构目标文件（887 行，超 800 红线）
@/home/re/code/MuseFlow/lib/features/manuscript/presentation/editor_with_sidebar.dart

# 先例样板（同库 part 机制 + extension 裸调用）
@/home/re/code/MuseFlow/lib/core/presentation/providers.dart
@/home/re/code/MuseFlow/lib/core/presentation/providers_core.dart
@/home/re/code/MuseFlow/lib/features/ai/application/anti_ai_scent_processor.dart
@/home/re/code/MuseFlow/lib/features/ai/application/anti_ai_scent_lexicon.dart

<interfaces>
<!-- 先例样板的核心模式（直接复用，零创新） -->

## 主库文件结构（参考 providers.dart + anti_ai_scent_processor.dart）

```dart
/// Library doc comment.
///
/// Split across N part files (...) to satisfy the 03-flutter-standards.md
/// file-size cap. All symbols live in the same library — consumers import
/// this file unchanged.
library;

// 全部 import 留这里（part 文件不能有 import）
import 'package:flutter/material.dart';
// ... 等

// export 指令（若有）必须在 part 指令之前（Dart 语法 export_directive_after_part）
// editor_with_sidebar.dart 当前无 export 指令，确认

part 'editor_with_sidebar_intents.dart';
part 'editor_with_sidebar_layout.dart';

// 主库保留：EditorWithSidebar 公共类 + _EditorWithSidebarState 完整类体
```

## Part 文件结构（参考 providers_core.dart + anti_ai_scent_lexicon.dart）

```dart
part of 'editor_with_sidebar.dart';

/// Doc comment explaining extraction rationale.
/// Same library — symbols reference each other via bare names unchanged.

// 禁止 import 语句
// 符号原样搬运（方法体一行不改）
```

## Extension-on-State 模式（本任务关键创新点）

```dart
part of 'editor_with_sidebar.dart';

extension _EditorWithSidebarStateLayout on _EditorWithSidebarState {
  /// Desktop layout: sidebar + divider + editor in a Row.
  Widget _buildDesktopLayout({...}) {
    // 方法体一行不改，从主文件整段搬入
    // context/widget/ref/_currentChapterId/_editor 等全部经 this 解析可见
  }
  // _buildMobileLayout / _buildEditorArea / _getMenuPosition 同理
}
```

## 目标文件行数分布（已勘察）

| 范围 | 内容 | 去向 |
|------|------|------|
| L1-23 | 23 个 import | 主文件保留 |
| L25-44 | 顶层 `_buildManuscriptStylesheet` 函数（20 行） | → intents.dart |
| L46-62 | `EditorWithSidebar` 公共 ConsumerStatefulWidget（17 行） | 主文件保留 |
| L64-609 | `_EditorWithSidebarState` 类前半 + build()（含 Shortcuts/Actions/PopScope/Scaffold） | 主文件保留 |
| L611-794 | `_buildDesktopLayout`/`_buildMobileLayout`/`_buildEditorArea`/`_getMenuPosition`（184 行） | → layout.dart（包入 extension） |
| L796-834 | `_toggleBold`/`_toggleItalic`/`_undoLastAIChange`（39 行） | 主文件保留（类内方法） |
| L837-865 | 7 个 `_XxxIntent` 类（29 行） | → intents.dart |
| L867-887 | `_SelectionLeadersLayerBuilder` 类（21 行） | → intents.dart |

主文件预期：887 − 20(stylesheet) − 184(layout) − 29(intents) − 21(layer builder) + 10(library+part 指令+注释) ≈ ~643 行 ✓ 远低于 800
</interfaces>

# 消费方影响分析（已验证）

```
lib/app.dart:9:        import 'package:museflow/features/manuscript/presentation/editor_with_sidebar.dart';
test/.../editor_with_sidebar_test.dart:13: import 'package:museflow/features/manuscript/presentation/editor_with_sidebar.dart';
```

2 个消费方均导入主库文件路径，公共类 `EditorWithSidebar` 签名/语义零变更 → 消费方零改动。
</context>

<tasks>

<task type="auto">
  <name>Task 1: 新建 2 个 part 文件（intents + layout），原样搬运声明零改动</name>
  <files>
    lib/features/manuscript/presentation/editor_with_sidebar_intents.dart
    lib/features/manuscript/presentation/editor_with_sidebar_layout.dart
  </files>
  <action>
    创建两个新 part 文件，文件内**禁止任何 import 语句**（part 文件 Dart 规则，与 qxe/rj4 先例一致）。

    **文件 1：`editor_with_sidebar_intents.dart`**（参考 anti_ai_scent_lexicon.dart 样板）
    - 第 1 行：`part of 'editor_with_sidebar.dart';`
    - 第 2-3 行：doc comment 说明抽取理由（参考 providers_core.dart 的样板措辞："Extracted from editor_with_sidebar.dart to satisfy the 03-flutter-standards.md file-size cap. Same library — symbols reference each other via bare names unchanged."）
    - 原样搬运以下声明（**类体/函数体一行不改**）：
      - 顶层函数 `_buildManuscriptStylesheet(BuildContext context)` 及其上方的 doc comment（当前主文件 L25-44）
      - 7 个 `_XxxIntent` 类：`_PreviousChapterIntent`/`_NextChapterIntent`/`_NewChapterIntent`/`_BoldIntent`/`_ItalicIntent`/`_UndoAIIntent`/`_QuickInsertIntent`（当前主文件 L839-865，含上方 `// --- Keyboard shortcut intents ---` 分组注释）
      - `_SelectionLeadersLayerBuilder` 类及其上方 doc comment（当前主文件 L867-887）

    **文件 2：`editor_with_sidebar_layout.dart`**
    - 第 1 行：`part of 'editor_with_sidebar.dart';`
    - 第 2-3 行：doc comment（同上样板措辞，注明此 part 承载 layout 辅助方法）
    - 定义 `extension _EditorWithSidebarStateLayout on _EditorWithSidebarState { ... }`（私有命名扩展，避免污染同库命名空间）
    - 将以下 4 个方法从主文件 `_EditorWithSidebarState` 类体**整段搬入 extension 体**（方法签名、参数、方法体、doc comment 一行不改，只是从类成员变成扩展成员）：
      - `Widget _buildDesktopLayout({required ColorScheme colorScheme, ...})` 及其 doc comment `/// Desktop layout: sidebar + divider + editor in a Row.`（当前 L611-656）
      - `Widget _buildMobileLayout({required BuildContext context, ...})` 及其 doc comment `/// Mobile layout: editor with drawer for chapter navigation.`（当前 L658-703）
      - `Widget _buildEditorArea(ColorScheme colorScheme, int currentWordCount, int targetWordCount)` 及其 doc comment `/// Builds the main editor area with toolbar, editor, and status bar.`（当前 L705-784）
      - `RelativeRect _getMenuPosition(Chapter chapter)` 及其 doc comment `/// Computes the position for a context menu relative to a chapter row.`（当前 L786-794）
    - 关键：方法体内对 `context`/`widget`/`ref`/`_editor`/`_selectionLinks`/`_currentChapterId`/`_switchChapter`/`_showCreateChapterDialog`/`_handleContextMenuAction`/`_buildManuscriptStylesheet` 等的引用**保持原样不动**——这些在 extension-on-this 上下文中经 Dart 同库语义解析为对 `_EditorWithSidebarState` 实例的成员访问或同库顶级符号引用（与 rj4 part 间 provider 互引同理）。

    **此 task 不修改主文件**（主文件改造在 Task 2）。两个新文件此时独立存在但还未被主文件 part 指令引用，独立 analyze 会报 "part of unused" 警告——这是预期中间态，Task 2 接入后即消除。

    红线守护：方法体/类体/函数体一行不改，仅做位置搬运 + extension 包装。
  </action>
  <verify>
    grep -c "^part of 'editor_with_sidebar.dart';" lib/features/manuscript/presentation/editor_with_sidebar_intents.dart lib/features/manuscript/presentation/editor_with_sidebar_layout.dart | tr '\n' ' '
    # 预期：两个文件各 1 个 part of 指令

    # 确认 part 文件零 import（Dart 规则）
    test -z "$(grep -E "^(import|export) " lib/features/manuscript/presentation/editor_with_sidebar_intents.dart lib/features/manuscript/presentation/editor_with_sidebar_layout.dart)" && echo "OK: no import/export in part files"

    # 确认关键符号已搬入
    grep -c "_SelectionLeadersLayerBuilder" lib/features/manuscript/presentation/editor_with_sidebar_intents.dart
    grep -c "_buildManuscriptStylesheet" lib/features/manuscript/presentation/editor_with_sidebar_intents.dart
    grep -c "extension _EditorWithSidebarStateLayout on _EditorWithSidebarState" lib/features/manuscript/presentation/editor_with_sidebar_layout.dart
    grep -c "_buildDesktopLayout\|_buildMobileLayout\|_buildEditorArea\|_getMenuPosition" lib/features/manuscript/presentation/editor_with_sidebar_layout.dart
  </verify>
  <done>
    - 两个新文件创建，首行均为 `part of 'editor_with_sidebar.dart';`
    - 两文件零 import/export
    - intents.dart 含 _buildManuscriptStylesheet 函数 + 7 个 _XxxIntent 类 + _SelectionLeadersLayerBuilder 类
    - layout.dart 含 extension _EditorWithSidebarStateLayout 包装 4 个 layout 辅助方法
    - 所有搬运内容与主文件原文本逐字符一致（仅位置变化 + extension 包装）
  </done>
</task>

<task type="auto">
  <name>Task 2: 主文件加 library + part 指令并删除已搬声明，跑 analyze + test 验证零回归</name>
  <files>
    lib/features/manuscript/presentation/editor_with_sidebar.dart
  </files>
  <action>
    修改主库文件 `editor_with_sidebar.dart` 接入两个 part（参考 rj4 providers.dart L1-6 + L99-103 样板 + qxe anti_ai_scent_processor.dart L1-13 样板）。

    **步骤 1：在文件最顶部加 library 指令**（在所有 import 之前，参考 anti_ai_scent_processor.dart L1-9）
    - 文件第 1 行起加 doc comment + `library;`（implicit unnamed library，与 qxe/rj4 一致，**不要**加 library 名称）：
      ```
      /// Manuscript editor with chapter sidebar.
      ///
      /// Wraps SuperEditor with chapter management. Split across 2 part files
      /// (editor_with_sidebar_intents/layout.dart) to satisfy the
      /// 03-flutter-standards.md file-size cap. All symbols live in the same
      /// library — consumers import this file unchanged.
      library;
      ```
    - 当前文件第 1 行是 `import 'package:flutter/material.dart';`，将上述 library 块插入到第 1 行之前。

    **步骤 2：保留全部 23 个 import 不动**（part 文件不能有 import，所有 import 必须留在主库文件，与 rj4 一致）。

    **步骤 3：在最后一个 import 之后、`_buildManuscriptStylesheet` 函数之前加 part 指令**（参考 providers.dart L99-103）
    - 当前主文件无 export 指令（已 grep 确认），故 part 指令直接放在 import 之后即可。
    - 插入：
      ```
      part 'editor_with_sidebar_intents.dart';
      part 'editor_with_sidebar_layout.dart';
      ```

    **步骤 4：删除已搬走的声明**（这些声明在 Task 1 已原样搬到 part 文件）
    - 删除顶层 `_buildManuscriptStylesheet` 函数及其 doc comment（原 L25-44，约 20 行）
    - 删除 `_EditorWithSidebarState` 类体内的 4 个 layout 辅助方法及其 doc comment（原 L611-794，约 184 行）：`_buildDesktopLayout`/`_buildMobileLayout`/`_buildEditorArea`/`_getMenuPosition`
      - 注意保留方法之间的分组注释边界清晰：删除从 `/// Desktop layout: sidebar...` 开始到 `_getMenuPosition` 方法闭合 `}` 结束
      - 紧随其后的 `// --- Editor Shortcuts ---` 分组注释及 `_toggleBold`/`_toggleItalic`/`_undoLastAIChange` 三个方法**保留在主文件类体内**（不搬走）
    - 删除文件末尾的 7 个 `_XxxIntent` 类（原 L837-865）+ `_SelectionLeadersLayerBuilder` 类（原 L867-887）及其上方 `// --- Keyboard shortcut intents ---` 分组注释

    **步骤 5：build() 方法内的裸调用零改动**
    - `_buildDesktopLayout(...)`/`_buildMobileLayout(...)`/`_buildEditorArea(...)` 的裸调用保持原样不动——Dart 同库 extension-on-this 自动解析（与 rj4 part 间 provider 互引裸名解析同理）
    - `_buildManuscriptStylesheet(context)` 裸调用保持原样——Dart 同库顶级私有符号自动解析
    - `const _PreviousChapterIntent()` 等 Intent 构造裸调用保持原样——Dart 同库私有类自动解析

    **步骤 6：验证门（必跑，按顺序）**
    1. `wc -l lib/features/manuscript/presentation/editor_with_sidebar.dart` → 预期 < 800（目标 ~643）
    2. `flutter analyze` 全仓 → 预期 0 issues（验证 part/part of 配对、extension 裸调用解析、import 完整、未定义符号）。**这是关键门**：若 extension 裸调用解析失败，analyze 会报 "undefined name '_buildDesktopLayout'" 等，需回查 extension 是否正确定义/方法是否正确搬入。
    3. `flutter test` 全仓 → 预期 1647 passed +12 skipped exit 0（行为等价证明）。基线来自 STATE.md last_activity（qxe commit f204855 后 1647 tests）。
    4. `git diff --stat` → 预期仅触动 3 个文件（主文件 + 2 新 part）。

    红线守护：方法体/类体/函数体一行不改；公共类 EditorWithSidebar 签名零变更；消费方零改动。
  </action>
  <verify>
    # 1. 行数门（< 800 红线）
    LINECOUNT=$(wc -l < lib/features/manuscript/presentation/editor_with_sidebar.dart)
    echo "main file lines: $LINECOUNT"
    [ "$LINECOUNT" -lt 800 ] || { echo "FAIL: line count $LINECOUNT >= 800"; exit 1; }

    # 2. library + part 指令就位
    grep -c "^library;" lib/features/manuscript/presentation/editor_with_sidebar.dart
    grep -c "^part 'editor_with_sidebar_intents.dart';" lib/features/manuscript/presentation/editor_with_sidebar.dart
    grep -c "^part 'editor_with_sidebar_layout.dart';" lib/features/manuscript/presentation/editor_with_sidebar.dart

    # 3. 已搬声明从主文件消失（应各为 0）
    grep -v '^\s*//' lib/features/manuscript/presentation/editor_with_sidebar.dart | grep -c "_buildManuscriptStylesheet" | grep -q "^0$" || echo "WARN: _buildManuscriptStylesheet 仍在主文件（需确认是裸调用还是定义）"
    # 注意：_buildManuscriptStylesheet(context) 裸调用应在 _buildEditorArea 内（layout.dart），主文件不应再有；但为防 grep 误报，以 analyze 为准

    # 4. 关键门：analyze 0 issues
    flutter analyze 2>&1 | tail -5

    # 5. 行为等价门：test 全绿
    flutter test 2>&1 | tail -10

    # 6. diff 红线：仅 3 文件
    git diff --stat HEAD -- lib/features/manuscript/presentation/
  </verify>
  <done>
    - 主文件行数 < 800（目标 ~643）
    - 主文件含 `library;` + 2 个 part 指令 + 全部 23 个 import + EditorWithSidebar 公共类 + _EditorWithSidebarState 类（initState/dispose/lifecycle/章节管理/自动保存/build/编辑器快捷键，无 layout 辅助方法）
    - flutter analyze 全仓 0 issues（关键门：证明 part 配对、extension 裸调用解析、import 完整、零未定义符号）
    - flutter test 全仓 1647 passed +12 skipped exit 0（行为等价证明，零回归）
    - git diff --stat 仅触动 lib/features/manuscript/presentation/ 下 3 个文件（主文件改 + 2 新 part）
    - 消费方 lib/app.dart 与测试文件零改动（公共类 EditorWithSidebar 签名/语义零变更）
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| 无新增信任边界 | 纯机械重构，零行为变更，零新增外部输入/输出路径。所有信任边界（用户输入→editor、editor→Hive 持久化、editor→AI pipeline）均已存在且未被触碰。 |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-uho-01 | Tampering | 代码完整性（重构正确性） | mitigate | 双重验证门：flutter analyze 0 issues（静态捕获未定义符号/import 错误/part 配对错误）+ flutter test 1647 passed（动态行为等价证明）。机械重构零逻辑改动，能编译+测试全绿即行为等价。 |
| T-uho-02 | Information Disclosure | 不适用 | accept | 纯代码组织重构，不涉及数据流/Pii/secrets。无新暴露面。 |
| T-uho-03 | Denial of Service | 不适用 | accept | 不涉及外部服务/网络/资源消耗。 |
| T-uho-SC | Tampering | 无新增 npm/pip/cargo 安装 | accept | 本任务零新增依赖，纯 Dart 文件重组。qxe/rj4 先例已验证 part 机制安全性。 |
</threat_model>

<verification>
## 阶段性总验证

1. **行数门**：`wc -l lib/features/manuscript/presentation/editor_with_sidebar.dart` < 800（消除 03-flutter-standards.md 红线）
2. **静态门**：`flutter analyze` 全仓 0 issues（关键——证明 extension 裸调用解析、part/part of 配对、import 完整性、零未定义符号）
3. **行为门**：`flutter test` 全仓 1647 passed +12 skipped exit 0（行为等价证明，与 qxe commit f204855 基线一致）
4. **diff 红线**：`git diff --stat HEAD -- lib/features/manuscript/presentation/` 仅 3 文件（主文件改 + 2 新 part）
5. **消费方零影响**：`git diff HEAD -- lib/app.dart test/features/manuscript/presentation/editor_with_sidebar_test.dart` 空 diff
6. **part 文件零 import**：两 part 文件 grep `^(import|export) ` 为空
</verification>

<success_criteria>
- ✅ editor_with_sidebar.dart 行数 < 800（消除全仓最后一个 800 红线）
- ✅ flutter analyze 全仓 0 issues
- ✅ flutter test 全仓 1647 passed +12 skipped exit 0（零回归）
- ✅ git diff 仅触 3 文件（lib/features/manuscript/presentation/ 内）
- ✅ 消费方零改动（lib/app.dart + 测试）
- ✅ 方法体/类体/函数体一行不改（机械拆分，零行为变更）
- ✅ 2 个 part 文件首行 `part of 'editor_with_sidebar.dart';` 且零 import（与 qxe/rj4 先例一致）
</success_criteria>

<output>
Create `.planning/quick/260616-uho-refactor-editor-with-sidebar-dart-part-s/260616-uho-SUMMARY.md` when done.

Summary 应记录：主文件 887→~643 行（消除 800 红线）、2 个新建 part 文件、extension-on-State 同库 part 机制的创新应用（解决单个 State 类无法跨文件拆类体的 Dart 限制）、1647 tests 零回归 analyze 0、qxe/rj4/uho 战役收尾（全仓零文件违反行数红线）。
</output>
