---
phase: quick
plan: 260616-vdw
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/ai/presentation/provider_management_page.dart
  - lib/features/ai/presentation/provider_management_page_layout.dart
autonomous: true
requirements: [TECH-DEBT-800-REDLINE]
tags: [refactor, dart-part, mechanical-split, uho-pattern]

must_haves:
  truths:
    - "lib/features/ai/presentation/provider_management_page.dart 行数 < 800（消除 03-flutter-standards.md 红线）"
    - "flutter analyze 全仓 0 issues"
    - "flutter test 全仓 1647 passed +12 skipped exit 0（零回归）"
    - "公共类 ProviderManagementPage 签名/语义零变更（消费方 lib/app.dart 与测试零改动）"
    - "新建 part 文件首行为 `part of 'provider_management_page.dart';` 且无 import"
---

<objective>
机械拆分 `lib/features/ai/presentation/provider_management_page.dart`（737 行），按 uho 模式（同库 part + extension-on-State）抽取 layout 辅助方法到独立 part 文件。

目的：复用 260616-uho 验证过的 extension-on-State 同库 part 模式（editor_with_sidebar 887→640 行先例），将 3 个 build helper（_buildMobileSwitcher/_buildLeftPanel/_buildRightPanel）搬入 extension。方法体一行不改。
输出：1 个新建 part 文件 + 主文件改造（加 `library;` + 1 个 part 指令，删除已搬方法），预期主文件 ~296 行。

【机制保证（与 uho 完全一致）】
- Dart part/part of 同库机制：part 文件与主库文件属同一编译单元，所有符号（含私有 `_xxx`）库内互相可见
- part 文件禁止 import — 全部 import 留主库文件
- `_ProviderManagementPageState` 单个 State 类无法跨文件拆类体（Dart 无 partial class），但同库 `extension on _ProviderManagementPageState` 可承载方法：build() 内裸调用经同库 extension-on-this 解析为零改动
- 公共类 `ProviderManagementPage` 不变，消费方 lib/app.dart + provider_management_responsive_test.dart 零改动
</objective>

<tasks>

<task type="auto">
  <name>Task 1: 新建 part 文件 provider_management_page_layout.dart，原样搬入 3 个 build helper</name>
  <files>
    lib/features/ai/presentation/provider_management_page_layout.dart
  </files>
  <action>
    创建新 part 文件，文件内禁止任何 import 语句（part 文件 Dart 规则，与 uho 先例一致）。

    - 第 1 行：`part of 'provider_management_page.dart';`
    - 第 2-4 行：doc comment 说明抽取理由（参考 editor_with_sidebar_layout.dart 样板措辞：从主文件抽取 layout 辅助方法以满足 03-flutter-standards.md 文件行数上限；Dart 无法拆分 State 类体，故 helper 方法放私有 extension；build() 内裸调用经同库 extension-on-this 透明解析，调用点零改动）
    - 定义 `extension _ProviderManagementPageStateLayout on _ProviderManagementPageState { ... }`（私有命名扩展，避免污染同库命名空间）
    - 将以下 3 个方法从主文件 `_ProviderManagementPageState` 类体整段搬入 extension 体（方法签名、参数、方法体、内部空行/缩进 一行不改，只是从类成员变成扩展成员）：
      - `Widget _buildMobileSwitcher(BuildContext context, ProviderManagementState mgmtState)`（主文件 L297-330，约 34 行）
      - `Widget _buildLeftPanel(BuildContext context, ProviderManagementState mgmtState, List<AIProvider> presets)`（主文件 L332-448，约 117 行）
      - `Widget _buildRightPanel(BuildContext context, ProviderManagementState mgmtState)`（主文件 L450-736，约 287 行）
    - 关键：方法体内对 `context/_obscureApiKey/_isEditing/_showList/_selectedType/_editingProviderId/_nameController/_baseUrlController/_apiKeyController/_modelController/_temperatureController/_topPController/_maxTokensController/_clearForm/_fillFromPreset/_fillForEdit/_handleSave/_handleDelete/_handleTestConnection/_handleFetchModels/ref` 等的引用保持原样不动 — extension-on-this 上下文经 Dart 同库语义解析为对 `_ProviderManagementPageState` 实例的成员访问

    此 task 不修改主文件。新文件此时独立存在但还未被主文件 part 指令引用 — 这是预期中间态，Task 2 接入后即消除。

    红线守护：方法体一行不改，仅做位置搬运 + extension 包装。
  </action>
  <verify>
    grep -c "^part of 'provider_management_page.dart';" lib/features/ai/presentation/provider_management_page_layout.dart
    test -z "$(grep -E "^(import|export) " lib/features/ai/presentation/provider_management_page_layout.dart)" && echo "OK: no import/export in part file"
    grep -c "extension _ProviderManagementPageStateLayout on _ProviderManagementPageState" lib/features/ai/presentation/provider_management_page_layout.dart
    grep -c "_buildMobileSwitcher\|_buildLeftPanel\|_buildRightPanel" lib/features/ai/presentation/provider_management_page_layout.dart
  </verify>
  <done>
    - 新文件创建，首行 `part of 'provider_management_page.dart';`
    - 零 import/export
    - extension _ProviderManagementPageStateLayout 包装 3 个 layout 辅助方法
    - 所有搬运内容与主文件原文本逐字符一致
  </done>
</task>

<task type="auto">
  <name>Task 2: 主文件加 library + part 指令并删除已搬方法，跑 analyze + test 验证零回归</name>
  <files>
    lib/features/ai/presentation/provider_management_page.dart
  </files>
  <action>
    修改主库文件接入 part（参考 editor_with_sidebar.dart L1-7 + L33 样板）。

    步骤 1：在文件最顶部加 library 块（在所有 import 之前）：
      ```
      /// AI Provider management settings page.
      ///
      /// Split across 1 part file (provider_management_page_layout.dart) to
      /// satisfy the 03-flutter-standards.md file-size cap. All symbols live
      /// in the same library — consumers import this file unchanged.
      library;
      ```

    步骤 2：保留全部 9 个 import 不动。

    步骤 3：在最后一个 import 之后、`/// AI Provider management settings page.` 公共类 doc comment 之前加 part 指令：
      ```
      part 'provider_management_page_layout.dart';
      ```

    步骤 4：删除已搬走的声明（Task 1 已原样搬到 part 文件）：
    - 删除 `_ProviderManagementPageState` 类体内的 3 个 layout 辅助方法（原 L297-736，约 440 行）：`_buildMobileSwitcher`/`_buildLeftPanel`/`_buildRightPanel`
      - 删除从 `Widget _buildMobileSwitcher(` 开始到 `_buildRightPanel` 方法闭合 `}` 结束
      - build() 方法体本身保留不动（类体内 build() 之后直接接 `}` 闭合类）

    步骤 5：build() 方法内对 `_buildMobileSwitcher(...)`/`_buildLeftPanel(...)`/`_buildRightPanel(...)` 的裸调用保持原样不动 — Dart 同库 extension-on-this 自动解析

    步骤 6：验证门（必跑，按顺序）
    1. `wc -l lib/features/ai/presentation/provider_management_page.dart` → 预期 < 800（目标 ~296）
    2. `flutter analyze` 全仓 → 预期 0 issues（关键门）
    3. `flutter test` 全仓 → 预期 1647 passed +12 skipped exit 0
    4. `git diff --stat` → 预期仅触动 2 个文件

    红线守护：方法体一行不改；公共类 ProviderManagementPage 签名零变更；消费方零改动。
  </action>
  <verify>
    LINECOUNT=$(wc -l < lib/features/ai/presentation/provider_management_page.dart)
    echo "main file lines: $LINECOUNT"
    [ "$LINECOUNT" -lt 800 ] || { echo "FAIL: line count $LINECOUNT >= 800"; exit 1; }
    grep -c "^library;" lib/features/ai/presentation/provider_management_page.dart
    grep -c "^part 'provider_management_page_layout.dart';" lib/features/ai/presentation/provider_management_page.dart
    flutter analyze 2>&1 | tail -5
    git diff --stat HEAD -- lib/features/ai/presentation/
  </verify>
  <done>
    - 主文件行数 < 800（目标 ~296）
    - 主文件含 `library;` + 1 个 part 指令 + 全部 9 个 import + ProviderManagementPage 公共类 + _ProviderManagementPageState 类（无 layout 辅助方法）
    - flutter analyze 全仓 0 issues
    - flutter test 全仓 1647 passed +12 skipped exit 0
    - git diff --stat 仅触动 2 文件
    - 消费方 lib/app.dart 与 provider_management_responsive_test.dart 零改动
  </done>
</task>

</tasks>

<verification>
1. **行数门**：`wc -l provider_management_page.dart` < 800
2. **静态门**：`flutter analyze` 全仓 0 issues
3. **行为门**：`flutter test` 全仓 1647 passed +12 skipped exit 0
4. **diff 红线**：`git diff --stat` 仅 2 文件（主文件改 + 1 新 part）
5. **消费方零影响**：`git diff HEAD -- lib/app.dart test/features/ai/presentation/provider_management_responsive_test.dart` 空 diff
6. **part 文件零 import**：part 文件 grep `^(import|export) ` 为空
</verification>

<success_criteria>
- ✅ provider_management_page.dart 行数 < 800
- ✅ flutter analyze 全仓 0 issues
- ✅ flutter test 全仓 1647 passed +12 skipped exit 0（零回归）
- ✅ git diff 仅触 2 文件
- ✅ 消费方零改动
- ✅ 方法体一行不改（机械拆分，零行为变更）
- ✅ 1 个 part 文件首行 `part of 'provider_management_page.dart';` 且零 import
</success_criteria>

<output>
Create `.planning/quick/260616-vdw-refactor-provider-management-page-dart-p/260616-vdw-SUMMARY.md` when done (不 commit，留 orchestrator)。

Summary 记录：主文件 737→~296 行、1 个新建 part 文件、extension-on-State 同库 part 机制（uho 模式精确复刻）、1647 tests 零回归 analyze 0。
</output>
