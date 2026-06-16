---
phase: quick-260616-wao
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/app.dart
  - lib/app_routes.dart
autonomous: true
requirements: []
---

<objective>
抽取 `lib/app.dart` 的 `_createRouter()`（210 行 GoRouter 路由表，行 58-268）到独立 part 文件 `lib/app_routes.dart`，复刻本仓库 uho/vdw 模式（同库 part + 私有 extension 承载方法）。主文件 307→~95 行，零行为变更。

Purpose: 消除 app.dart 体积压力（路由表占 68% 文件），让路由配置与 redirect guard 分离，路由表改动不再触碰主 widget 文件。
Output: 新建 `lib/app_routes.dart`（part of 'app.dart'，extension `on MuseFlowApp` 承载 createRouter()）；主文件加 `library;` + `part 'app_routes.dart';`，build() 调 createRouter()，删除路由表体。
</objective>

<execution_context>
@/home/re/code/MuseFlow/.claude/get-shit-done/workflows/execute-plan.md
@/home/re/code/MuseFlow/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@/home/re/code/MuseFlow/CLAUDE.md
@/home/re/code/MuseFlow/lib/app.dart
@/home/re/code/MuseFlow/lib/features/manuscript/presentation/editor_with_sidebar_layout.dart
@/home/re/code/MuseFlow/lib/features/ai/presentation/provider_management_page_layout.dart

<interfaces>
<!-- 关键差异点（与 uho/vdw 模式对比）-->

uho/vdw 模式（StatefulWidget）：
```dart
extension _EditorWithSidebarStateLayout on _EditorWithSidebarState { ... }
```

本任务（ConsumerWidget，无 State 类）：
```dart
extension _MuseFlowAppRoutes on MuseFlowApp { ... }
```

MuseFlowApp 类签名（lib/app.dart:41）：
```dart
class MuseFlowApp extends ConsumerWidget {
  const MuseFlowApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) { ... }
  GoRouter _createRouter() { ... }              // 行 58-268，待搬
  Future<String?> _handleRedirect(...) { ... }  // 行 277-305，留主文件
}
```

build() 调用点（lib/app.dart:46）：
```dart
final router = _createRouter();
```
重命名为 createRouter() 后，extension-on-this 机制让 build() 内裸调用 `_createRouter()` → `createRouter()` 解析到 extension 成员（uho 已验证可行）。

_handleRedirect 引用点（lib/app.dart:61）：
```dart
redirect: _handleRedirect,
```
_handleRedirect 留主文件作为 MuseFlowApp 的私有方法，extension 内通过同库 part 可见性访问（part of 文件共享主文件的库作用域）。

消费者（零影响）：
- lib/main.dart:8 import 'package:museflow/app.dart'; → 仅引用 MuseFlowApp 类，路由提取对其透明
- test/app/token_audit_route_test.dart:6 → 仅 pumpWidget(MuseFlowApp())，不引用 _createRouter

part 文件 import 规则（Dart 强制）：part 文件不能有 import 语句。所有页面 import（app.dart 行 5-35 共 31 个 import）必须留在主文件 app.dart 的 library 范围内，part 文件共享这些导入。
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: 创建 app_routes.dart part 文件，承载路由表 extension</name>
  <files>lib/app_routes.dart</files>
  <action>
新建 `lib/app_routes.dart`，文件结构（严格按序）：

1. 首行：`part of 'app.dart';`（part of 指令必须是文件首条语句，part of 后为字符串字面量指向主文件）

2. 文档注释块（/// 开头），复刻 uho/vdw 文档模式说明：
   - "Routes table for MuseFlowApp."
   - 说明从 app.dart 抽取以满足 03-flutter-standards.md 文件大小上限
   - 说明 Dart 不允许跨文件拆分单个类体，故 GoRouter 构造与路由表放在私有 extension
   - 说明 MuseFlowApp.build() 经 extension-on-this 解析裸调用 createRouter()，调用点零改动
   - 说明 _handleRedirect 留主文件，extension 内 redirect: _handleRedirect 通过同库 part 可见性访问

3. extension 声明：`extension _MuseFlowAppRoutes on MuseFlowApp {`（注意：MuseFlowApp 非 State 类，extension 直接 on MuseFlowApp 本身，而非某个 _State 类——这是与 uho/vdw 模式的关键差异）

4. 把 app.dart 行 58-268 的 `_createRouter()` 方法体（从 `GoRouter _createRouter() {` 到对应右大括号 `}`）原样搬入 extension，方法名从 `_createRouter` 改为 `createRouter`（去掉前导下划线：extension 方法需为库内可见名，build() 裸调用解析到 extension 成员）。方法体内容零改动——GoRouter 构造、initialLocation、redirect: _handleRedirect、routes 数组（含 5 个顶级 GoRoute + StatefulShellRoute.indexedStack 含 6 个 StatefulShellBranch + 全部嵌套 GoRoute）原样保留。

5. extension 右大括号闭合。

不要在 part 文件写任何 import 语句（Dart 强制：part 文件 import 由主库承担）。
不要改动路由表任何内容（路径、builder、页面类、参数解析）。
不要在 part 文件重复 _handleRedirect（它留主文件）。
  </action>
  <verify>
    <automated>test -f lib/app_routes.dart && head -1 lib/app_routes.dart | grep -q "part of 'app.dart';" && grep -q "extension _MuseFlowAppRoutes on MuseFlowApp" lib/app_routes.dart && grep -q "GoRouter createRouter()" lib/app_routes.dart && grep -q "redirect: _handleRedirect" lib/app_routes.dart && ! grep -q "^import " lib/app_routes.dart</automated>
  </verify>
  <done>lib/app_routes.dart 存在；首行 part of 'app.dart'；含 extension _MuseFlowAppRoutes on MuseFlowApp；含 GoRouter createRouter() 方法（路由表体原样）；含 redirect: _handleRedirect 引用；零 import 语句。</done>
</task>

<task type="auto">
  <name>Task 2: 主文件 app.dart 接入 part 指令、删除路由表、build 调 createRouter</name>
  <files>lib/app.dart</files>
  <action>
修改 `lib/app.dart`：

1. 文件最顶端（在所有 import 之前）加 `library;` 指令（Dart 显式 library 声明，part/part of 配对所需；放在第一行，import 在其后）。

2. import 块（行 1-35）全部保留——part 文件 app_routes.dart 共享这些导入，页面类（OnboardingWizardPage/EditorWithSidebar/ManuscriptSettingsPage 等）在 createRouter() 路由表中被引用。零改动。

3. 在 import 块结束（最后一个 import 之后、MuseFlowApp 类声明之前）加 part 指令：`part 'app_routes.dart';`

4. MuseFlowApp.build() 行 46：`final router = _createRouter();` → `final router = createRouter();`（去下划线，解析到 extension 成员）。build() 其余零改动。

5. 删除行 58-268 的整个 `_createRouter()` 方法（从 `GoRouter _createRouter() {` 到对应右大括号 `}`）。该体已搬到 app_routes.dart 的 extension。

6. `_handleRedirect`（行 270-305）保留在主文件 MuseFlowApp 类内——它是 redirect guard 业务逻辑（读 Hive settings box 判 onboarding），不属于路由表声明，且 extension 内的 redirect: _handleRedirect 通过同库 part 可见性访问它。零改动。

7. 不删除任何 import（即使看起来 createRouter 已搬走，但 part 文件共享主库 import，所有页面 import 必须留在主文件）。

预期 app.dart 行数：307 → ~95（删 210 行路由表 + 加 2 行 library/part 指令 - 1 行改名净删 ~210）。
  </action>
  <verify>
    <automated>flutter analyze lib/app.dart lib/app_routes.dart 2>&1 | tail -5 && grep -c "GoRouter _createRouter" lib/app.dart | grep -q "^0$" && head -1 lib/app.dart | grep -q "^library;\s*$" && grep -q "^part 'app_routes.dart';" lib/app.dart && grep -q "createRouter()" lib/app.dart && grep -q "_handleRedirect" lib/app.dart</automated>
  </verify>
  <done>flutter analyze lib/app.dart lib/app_routes.dart 零 issue；app.dart 首行 library;；含 part 'app_routes.dart'; 指令；含 createRouter() 调用（去下划线）；零 _createRouter 残留；_handleRedirect 保留；所有 import 保留。</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>
抽取 app.dart 路由表到 app_routes.dart part 文件（uho/vdw 模式复刻），主文件 307→~95 行。纯声明式路由配置搬移，零行为变更，零消费方改动。
  </what-built>
  <how-to-verify>
1. 静态分析（必跑）：
   ```
   flutter analyze
   ```
   预期：0 issues（与重构前基线一致）。

2. 全量测试（必跑，零回归基线）：
   ```
   flutter test
   ```
   预期：1647 tests pass（与重构前基线一致，零回归）。重点观察 test/app/token_audit_route_test.dart（pumpWidget MuseFlowApp 走真实路由表）与 test/features/onboarding/application/onboarding_redirect_test.dart（虽是模拟 redirect 逻辑，确认仍绿）。

3. 文件大小核查：
   ```
   wc -l lib/app.dart lib/app_routes.dart
   ```
   预期：app.dart ~95 行（达 200-400 推荐区以下），app_routes.dart ~230 行（含路由表+文档+extension 壳）。

4. 结构核查（grep）：
   - app.dart 含 `library;` 首行、`part 'app_routes.dart';`、`createRouter()` 调用、`_handleRedirect` 方法
   - app.dart 零 `_createRouter` 残留
   - app_routes.dart 含 `part of 'app.dart';` 首行、`extension _MuseFlowAppRoutes on MuseFlowApp`、`GoRouter createRouter()` 方法
  </how-to-verify>
  <resume-signal>Type "approved" 或描述 analyze/test 回归问题</resume-signal>
</task>

</tasks>

<threat_model>
纯代码搬移重构，零行为变更，无新增信任边界、无外部输入处理、无新依赖。STRIDE 威胁面与重构前完全等价（路由表内容原样保留，redirect guard 逻辑未动）。无新增威胁条目。
</threat_model>

<verification>
- flutter analyze 全仓 0 issues
- flutter test 1647 tests 全绿（零回归）
- app.dart 行数 ~95（从 307 降）
- app_routes.dart 含完整路由表（5 顶级 GoRoute + StatefulShellRoute.indexedStack 6 branch + 全部嵌套）
- 路由表内容逐字等价（路径、builder、页面类、参数解析零改动）
- _handleRedirect 留主文件且仍被 extension 内 redirect: _handleRedirect 引用
</verification>

<success_criteria>
- app.dart 307→~95 行
- app_routes.dart 新建，part of 'app.dart' + extension on MuseFlowApp 承载 createRouter()
- flutter analyze 0 / flutter test 1647 零回归
- 零行为变更（路由表、redirect、所有页面 builder 原样）
- 消费方（main.dart、token_audit_route_test.dart）零改动
</success_criteria>

<output>
Create `.planning/quick/260616-wao-extract-app-routes-partfile/260616-wao-SUMMARY.md` when done
</output>
