---
phase: quick-260616-qxe
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/ai/application/anti_ai_scent_processor.dart
  - lib/features/ai/application/anti_ai_scent_lexicon.dart
autonomous: true
requirements: []
must_haves:
  truths:
    - "anti_ai_scent_processor.dart 主文件行数落到 ~560 行区间（< 800 红线）"
    - "anti_ai_scent_test.dart 590 行契约零回归（flutter test 全绿）"
    - "flutter analyze 零错误（与重构前基线一致）"
    - "8+ 消费方导入路径与公共类型导出完全不变（git diff 不触及消费方）"
    - "13 个数据表内容逐字不变（仅 static 关键字移除 + 位置迁移到 part 文件）"
  artifacts:
    - path: "lib/features/ai/application/anti_ai_scent_lexicon.dart"
      provides: "同库顶级私有常量（part of anti_ai_scent_processor.dart）"
      contains: "part of 'anti_ai_scent_processor.dart';"
    - path: "lib/features/ai/application/anti_ai_scent_processor.dart"
      provides: "瘦身后处理器（仅留枚举/值类/类/方法体）"
      contains: "part 'anti_ai_scent_lexicon.dart';"
  key_links:
    - from: "lib/features/ai/application/anti_ai_scent_processor.dart"
      to: "lib/features/ai/application/anti_ai_scent_lexicon.dart"
      via: "part / part of 同库机制"
      pattern: "part 'anti_ai_scent_lexicon.dart';"
---

<objective>
纯机械抽取：把 `anti_ai_scent_processor.dart`（1091 行，违反 03-flutter-standards.md「最大 800 行」红线）中混入类体内的 13 个 static 数据表搬到新建 part 文件 `anti_ai_scent_lexicon.dart`，转成同库顶级私有常量。零行为变更、零调用点改动、零消费方影响。

Purpose: 解决文件大小红线违规（1091 → ~560 行），数据/逻辑分离，便于后续维护（词库扩充不动处理器代码）。这是 quick 纯机械重构，不是设计变更。

Output:
- 新建 `lib/features/ai/application/anti_ai_scent_lexicon.dart`（~530 行数据表）
- 主文件 `lib/features/ai/application/anti_ai_scent_processor.dart` 缩到 ~560 行
</objective>

<execution_context>
@/home/re/code/MuseFlow/.claude/get-shit-done/workflows/execute-plan.md
@/home/re/code/MuseFlow/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@/home/re/code/MuseFlow/CLAUDE.md
@/home/re/code/MuseFlow/.planning/STATE.md
@/home/re/code/MuseFlow/.claude/rules/03-flutter-standards.md
@/home/re/code/MuseFlow/lib/features/ai/application/anti_ai_scent_processor.dart
@/home/re/code/MuseFlow/test/features/ai/application/anti_ai_scent_test.dart

<interfaces>
<!-- 重构涉及的关键契约边界。executor 无需探索代码库。 -->

主文件保留（不动）：
- L1-9: library doc + `library;` 指令
- L11: `import 'dart:math' as math;` （保留，`_sentenceRhythmUniformity` 仍用 math）
- L13-32: `enum HighlightType`, `enum ReviewSignalSeverity`
- L34-100: `class ReviewSignal`, `class TextHighlight`, `class ProcessingResult`
- L102-126: `class AntiAIScentProcessor` 头 + `static List<String> get synonymKeys` getter
- L666-1091: 全部方法体（process / _apply* / _buildReviewSignals / _countPhraseHits / _sentenceLengths / _sentenceRhythmUniformity 等）

要抽取的 13 个数据表（精确行号，逐字搬运到 part 文件，仅去掉 `static` 关键字、保留 `_` 前缀、保留所有中文注释/分隔线）：

| # | 符号 | 类型 | 主文件行号 |
|---|------|------|-----------|
| 1 | `_synonymMap` | `Map<String,String>` 常量 | 128-468 (含文档注释) |
| 2 | `_highlightOnlyPhrases` | `Set<String>` 常量 | 470-502 (含文档注释) |
| 3 | `_structuralPatterns` | `List<RegExp>` final | 504-529 (含文档注释) |
| 4 | `_transitionCliches` | `List<String>` 常量 | 531-539 |
| 5 | `_xianxiaCliches` | `List<String>` 常量 | 541-550 |
| 6 | `_wuxiaCliches` | `List<String>` 常量 | 552-568 (含文档注释) |
| 7 | `_urbanCliches` | `List<String>` 常量 | 570-582 (含文档注释) |
| 8 | `_scifiCliches` | `List<String>` 常量 | 584-595 (含文档注释) |
| 9 | `_xuanhuanCliches` | `List<String>` 常量 | 597-612 (含文档注释) |
| 10 | `_mannerAdverbStems` | `List<String>` 常量 | 614-630 (含文档注释) |
| 11 | `_formulaicEndings` | `List<String>` 常量 | 632-638 |
| 12 | `_emotionalCliches` | `List<String>` 常量 | 640-652 (含文档注释) |
| 13 | `_descriptionFormulas` | `List<String>` 常量 | 654-664 (含文档注释) |

为何零调用点改动（Dart 语义）：Dart 的 `_` 前缀是库级私有（library-private），不是文件级私有。part 文件与主文件同属一个 library（由 `library;` 指令 + `part/part of` 关联），故 part 中的顶级私有常量对主文件类方法完全可见。方法体内裸名 `_xianxiaCliches`、`_synonymMap.keys`、`_highlightOnlyPhrases.contains(...)`、`for (final p in _structuralPatterns)` 等会自动解析到 part 文件的顶级常量，与原先解析到类 static 成员行为等价。无需任何方法体改动。

为何公共契约不变：2 枚举 + 3 值类 + `AntiAIScentProcessor` 类 + `synonymKeys` getter 全部留在主文件。8+ 消费方（editor_ai_state.dart / status_bar.dart / synthesis_panel.dart / synthesis_notifier.dart / banned_phrase_settings.dart / intent_preservation_analyzer.dart / providers.dart）的 `import .../anti_ai_scent_processor.dart` 路径与所用类型导出完全不变。part 文件不参与 import 解析（消费方无需也无法直接 import part 文件）。
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: 新建 part 文件并机械搬运 13 个数据表</name>
  <files>lib/features/ai/application/anti_ai_scent_lexicon.dart</files>
  <action>
新建 `lib/features/ai/application/anti_ai_scent_lexicon.dart`。

文件首行（必须、无空行前置）：
`part of 'anti_ai_scent_processor.dart';`

随后空一行，加一段简短文档注释说明此 part 文件用途（"Synonym maps, cliche lists, and structural regex patterns for AntiAIScentProcessor. Extracted from the main processor file to satisfy the 03-flutter-standards.md file-size cap. All symbols are library-private top-level constants; the processor class accesses them via bare names."）。

然后从 `anti_ai_scent_processor.dart` 主文件原样搬运以下 13 个数据表（按主文件出现顺序，逐字复制，包括所有中文文档注释、`// ═══` 分隔线、空行），唯一改动是去掉每个声明开头的 `static` 关键字（保留 `const` 或 `final`，保留 `_` 前缀）：

1. `_synonymMap`（主文件 L128-468，约 340 行 Map 字面量）— 把 `static const Map<String, String> _synonymMap = {` 改为 `const Map<String, String> _synonymMap = {`
2. `_highlightOnlyPhrases`（L470-502）— `static const Set<String>` → `const Set<String>`
3. `_structuralPatterns`（L504-529）— `static final List<RegExp>` → `final List<RegExp>`（注意：final 不是 const，因为 RegExp 列表不能 const 化；保持 final）
4. `_transitionCliches`（L531-539）— `static const List<String>` → `const List<String>`
5. `_xianxiaCliches`（L541-550）— 同上
6. `_wuxiaCliches`（L552-568，含文档注释）— 同上
7. `_urbanCliches`（L570-582，含文档注释）— 同上
8. `_scifiCliches`（L584-595，含文档注释）— 同上
9. `_xuanhuanCliches`（L597-612，含文档注释）— 同上
10. `_mannerAdverbStems`（L614-630，含文档注释）— 同上
11. `_formulaicEndings`（L632-638）— 同上
12. `_emotionalCliches`（L640-652，含文档注释）— 同上
13. `_descriptionFormulas`（L654-664，含文档注释）— 同上

关键不变性（重构正确性的硬约束）：
- 数据内容（key/value/元素）逐字不变，包括所有中文注释、emoji、Unicode 分隔线
- 每个声明的类型标注完全不变（`Map<String, String>` / `Set<String>` / `List<RegExp>` / `List<String>`）
- `const` vs `final` 修饰符与原文件一致（`_structuralPatterns` 保持 final，其余 12 个保持 const）
- `_` 前缀保留（同库私有，processor 仍可访问）
- 文档注释（`///`）跟随对应符号一起搬运到 part 文件

不要做任何"优化"：不要合并相邻常量、不要重排序、不要改中文标点、不要给 `_structuralPatterns` 加 const（会编译错误）。这是逐字搬运。
  </action>
  <verify>
    <automated>grep -c "^part of 'anti_ai_scent_processor.dart';$" lib/features/ai/application/anti_ai_scent_lexicon.dart | grep -q "^1$" && grep -v '^//' lib/features/ai/application/anti_ai_scent_lexicon.dart | grep -E "^(const|final) " | wc -l | grep -q "^13$"</automated>
  </verify>
  <done>
- `lib/features/ai/application/anti_ai_scent_lexicon.dart` 存在
- 首行为 `part of 'anti_ai_scent_processor.dart';`
- 包含 13 个顶级私有常量声明（去掉 static 后）
- 内容与主文件原数据表逐字一致（key/value/注释/类型标注全保留）
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: 主文件接入 part 指令并删除已搬运数据表 + 全量验证</name>
  <files>lib/features/ai/application/anti_ai_scent_processor.dart</files>
  <behavior>
- Test 1 (compile): `flutter analyze lib/features/ai/application/anti_ai_scent_processor.dart lib/features/ai/application/anti_ai_scent_lexicon.dart` returns 0 errors（part/part of 配对正确、13 个符号都解析到 part 顶级常量、所有方法体裸名引用无 unresolved name）
- Test 2 (contract): `flutter test test/features/ai/application/anti_ai_scent_test.dart` 全绿（590 行契约零回归 — synonym 替换、highlight 标记、review signal、5 个 genre cliches、manner adverb、structural regex 全部行为不变）
- Test 3 (size): 主文件行数 < 800（落回 03-flutter-standards.md 红线内，目标 ~560）
- Test 4 (no consumer touched): `git diff --name-only` 仅含主文件 + part 文件，无消费方文件改动
  </behavior>
  <action>
修改 `lib/features/ai/application/anti_ai_scent_processor.dart`：

步骤 A — 加 part 指令：在主文件 `library;` 指令（第 9 行）之后、`import 'dart:math' as math;`（第 11 行）之前，插入：
```dart
part 'anti_ai_scent_lexicon.dart';
```
（保留空行格式：library; 后空一行 → part 指令 → 空一行 → import）

步骤 B — 删除已搬运数据表：删除主文件第 128-664 行的 13 个数据表声明（即从 `_synonymMap` 的文档注释 `/// Fixed synonym map for auto-replacement per D-09.` 开头，到 `_descriptionFormulas` 的闭合 `};` 结束，包括中间所有符号和文档注释）。

保留：
- L1-127 完全不动（library doc / library 指令 / 新加的 part 指令 / dart:math import / 2 枚举 / 3 值类 / `AntiAIScentProcessor` 类头 + `synonymKeys` getter）
- L666+ 完全不动（`process` 方法及之后所有方法体、所有 `_apply*` / `_buildReviewSignals` / `_countPhraseHits` / `_sentenceLengths` / `_sentenceRhythmUniformity` 等）

方法体内的裸名引用（如 `_countPhraseHits(text, _xianxiaCliches)`、`_synonymMap.keys`、`_highlightOnlyPhrases.contains(phrase)`、`for (final pattern in _structuralPatterns)`）**不要改任何字符** — Dart 编译器会自动把这些裸名解析到 part 文件的同库顶级私有常量。

不要做：不要给 `synonymKeys` getter 加注释说"现在引用 part 文件"（多余）；不要重排 import；不要碰任何枚举/值类/方法签名/方法体；不要"顺手"清理别的代码。

完成后立即跑验证三件套（任一失败必须修，不许 defer）：
1. `flutter analyze lib/features/ai/application/anti_ai_scent_processor.dart lib/features/ai/application/anti_ai_scent_lexicon.dart`
2. `flutter test test/features/ai/application/anti_ai_scent_test.dart`
3. `wc -l lib/features/ai/application/anti_ai_scent_processor.dart` 确认 < 800
4. `git diff --name-only` 确认仅 2 个文件改动

若 analyze 报 "undefined name" 类错误：检查是否漏搬了某个符号、或搬了符号但主文件还有残留声明导致重复定义。若 test 红了：几乎不可能（纯机械搬运），若发生则 diff 主文件改动确认没有意外修改方法体。
  </action>
  <verify>
    <automated>flutter analyze lib/features/ai/application/anti_ai_scent_processor.dart lib/features/ai/application/anti_ai_scent_lexicon.dart && flutter test test/features/ai/application/anti_ai_scent_test.dart && test "$(wc -l < lib/features/ai/application/anti_ai_scent_processor.dart)" -lt 800 && [ "$(git diff --name-only)" = $'lib/features/ai/application/anti_ai_scent_lexicon.dart\nlib/features/ai/application/anti_ai_scent_processor.dart' ] || [ "$(git diff --name-only)" = $'lib/features/ai/application/anti_ai_scent_processor.dart\nlib/features/ai/application/anti_ai_scent_lexicon.dart' ]</automated>
  </verify>
  <done>
- `flutter analyze` 在两文件上零错误（与重构前基线一致）
- `flutter test test/features/ai/application/anti_ai_scent_test.dart` 全绿（590 行契约不变）
- 主文件行数 < 800（目标 ~560，落回 03-flutter-standards.md 推荐/红线区间）
- `git diff --name-only` 仅触及主文件 + 新建 part 文件（8+ 消费方零改动）
- 方法体零字符变更（裸名引用自动解析到 part 顶级常量）
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| (无新增) | 本次为纯机械内部重构，不引入新的信任边界。文件读取/数据处理逻辑完全不变。 |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-qxe-01 | Tampering | 数据表内容完整性（13 个词库/正则/cliche 列表） | mitigate | Task 1 verify 用 grep 数顶级常量声明数（== 13）；Task 2 verify 用 flutter test 590 行契约兜底（任何数据表内容篡改/漏搬会触发 test 失败） |
| T-qxe-02 | Information Disclosure | (N/A) | accept | 重构不涉及任何 PII、API key、外部数据流；纯静态词库搬位置 |
| T-qxe-03 | Denial of Service | (N/A) | accept | 重构不改变运行时性能特征（顶级常量 vs static 成员访问等价，Dart 编译期常量折叠行为不变） |
</threat_model>

<verification>
1. **文件大小红线**：`wc -l lib/features/ai/application/anti_ai_scent_processor.dart` → 期望 ~560 行（< 800 红线，落回 200-400 推荐/最大区间）
2. **静态分析**：`flutter analyze lib/features/ai/application/anti_ai_scent_processor.dart lib/features/ai/application/anti_ai_scent_lexicon.dart` → 0 errors（与重构前基线一致）
3. **行为契约**：`flutter test test/features/ai/application/anti_ai_scent_test.dart` → 全绿（590 行，覆盖 synonym 替换 / highlight 标记 / review signal / 5 genre cliches / manner adverb / structural regex）
4. **消费方零影响**：`git diff --name-only` → 仅 `lib/features/ai/application/anti_ai_scent_processor.dart` + `lib/features/ai/application/anti_ai_scent_lexicon.dart` 两个文件
5. **part 配对**：`grep -c "part of 'anti_ai_scent_processor.dart';" lib/features/ai/application/anti_ai_scent_lexicon.dart` → 1；`grep -c "part 'anti_ai_scent_lexicon.dart';" lib/features/ai/application/anti_ai_scent_processor.dart` → 1
6. **数据表数量**：`grep -E "^(const|final) " lib/features/ai/application/anti_ai_scent_lexicon.dart | wc -l` → 13
</verification>

<success_criteria>
- [x] 主文件从 1091 行降至 ~560 行（< 800 红线）
- [x] `flutter analyze` 零错误（与基线一致）
- [x] `anti_ai_scent_test.dart` 590 行契约全绿
- [x] 8+ 消费方文件零改动（git diff 仅 2 个文件）
- [x] 13 个数据表内容逐字不变（仅 static 关键字移除 + 位置迁移）
- [x] 方法体零字符变更（Dart 自动解析同库顶级私有常量）
</success_criteria>

<output>
Create `.planning/quick/260616-qxe-anti-ai-scent-processor-dart-part-anti-a/260616-qxe-SUMMARY.md` when done.
Commit message: `refactor(ai): 抽取 anti_ai_scent_processor 数据表到 part 文件（1091→~560 行，消除 800 行红线）`
</output>
