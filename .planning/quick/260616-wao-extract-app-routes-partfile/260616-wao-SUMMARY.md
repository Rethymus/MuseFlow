---
phase: quick-260616-wao
plan: 01
subsystem: presentation-routing
tags: [refactor, dart, flutter, go-router, part-file, file-size-cap]
requires:
  - lib/app.dart (MuseFlowApp root widget)
  - lib/features/manuscript/presentation/editor_with_sidebar.dart (uho part-file precedent)
  - lib/features/ai/presentation/provider_management_page.dart (vdw part-file precedent)
provides:
  - lib/app_routes.dart (part of 'app.dart'; extension _MuseFlowAppRoutes on MuseFlowApp 承载 createRouter())
affects:
  - lib/app.dart (307→98 行；library; + part 指令 + build() 调 createRouter())
tech-stack:
  added: []
  patterns:
    - 同库 part + 私有 extension 承载方法（Dart 无 partial class 的解法，复刻 uho/vdw 模式）
    - extension-on-this 解析：build() 裸调用 createRouter() 经同名库内 extension 透明解析
    - ConsumerWidget（非 State 类）的 extension 直接 on MuseFlowApp 本身（与 uho/vdw 的 on _State 差异点）
key-files:
  created:
    - lib/app_routes.dart
  modified:
    - lib/app.dart
decisions:
  - extension 直接 on MuseFlowApp（ConsumerWidget 无 State 类），与 uho/vdw 的 on _State 模式区分
  - createRouter 去 _ 前缀（extension 成员需库内可见名，build() 裸调用解析到 extension 成员）
  - _handleRedirect 留主文件（redirect guard 业务逻辑，不属于路由表声明；extension 内 redirect: _handleRedirect 经同库 part 可见性访问）
metrics:
  duration: ~12 分钟
  completed: 2026-06-16
  tasks: 2
  files: 2 (1 created, 1 modified)
---

# Phase quick-260616-wao Plan 01: 抽取 app.dart 路由表到 app_routes.dart part 文件 Summary

抽取 MuseFlowApp 的 210 行 GoRouter 路由表（_createRouter）到独立 part 文件 app_routes.dart，复刻本仓库 uho/vdw 同库 part + 私有 extension 模式；主文件 307→98 行，零行为变更零消费方影响。

## What Was Built

**Task 1 — 新建 `lib/app_routes.dart` part 文件（commit c94be59）**
- 首行 `part of 'app.dart';`（part of 指令必须是文件首条语句）
- 文档注释块说明：从 app.dart 抽取以满足 03-flutter-standards.md 文件大小上限；Dart 不允许跨文件拆分单个类体，故 GoRouter 构造与路由表放在私有 extension；MuseFlowApp.build() 经 extension-on-this 解析裸调用 createRouter()；_handleRedirect 留主文件，extension 内 redirect: _handleRedirect 通过同库 part 可见性访问
- `extension _MuseFlowAppRoutes on MuseFlowApp`（关键差异：MuseFlowApp 是 ConsumerWidget 无 State 类，extension 直接 on MuseFlowApp 本身，而非 uho/vdw 的 on _State 类）
- `GoRouter createRouter()` 方法（路由表体逐字等价搬入，方法名从 `_createRouter` 去 _ 前缀为 `createRouter`）：5 个顶级 GoRoute + StatefulShellRoute.indexedStack 含 6 个 StatefulShellBranch + 全部嵌套 GoRoute（character/setting/skills/templates/stats/reports/ai-providers 等）
- 零 import 语句（Dart 强制：part 文件 import 由主库 app.dart 承担）
- 文件 226 行

**Task 2 — 主文件 `lib/app.dart` 接入 part 指令并删除路由表（commit e24a8cb）**
- 文件最顶端加 `library;`（Dart 显式 library 声明，part/part of 配对所需）
- import 块后加 `part 'app_routes.dart';`
- build() 内 `_createRouter()` → `createRouter()`（去下划线，extension-on-this 解析到 extension 成员）
- 删除 210 行 `_createRouter()` 路由表体（已搬入 app_routes.dart extension）
- `_handleRedirect` 保留为 MuseFlowApp 私有方法（行 270-305 原样留主文件）
- 35 个 import 全部保留（part 文件共享主库导入）
- 文件 307→98 行（净删 209 行）

## How to Verify

- `flutter analyze lib/app.dart lib/app_routes.dart` → No issues found (2.4s)
- `flutter analyze`（全仓）→ No issues found (5.2s)
- `flutter test` → **All tests passed! 1647 passed, ~12 skipped**（与重构前 1647 基线一致，零回归；skip 为 env-gated 测试如 `GLM_API_KEY not set`）
- `wc -l lib/app.dart` → 98 行（达 200-400 推荐区以下，远低于 800 上限）
- `wc -l lib/app_routes.dart` → 226 行（路由表+文档+extension 壳）
- 结构核查：app.dart 含 `library;` 首行、`part 'app_routes.dart';`、`createRouter()` 调用、`_handleRedirect` 方法；零 `_createRouter` 残留
- app_routes.dart 含 `part of 'app.dart';` 首行、`extension _MuseFlowAppRoutes on MuseFlowApp`、`GoRouter createRouter()` 方法、`redirect: _handleRedirect` 引用；零 import 语句

## Deviations from Plan

None - plan executed exactly as written. 纯代码搬移重构，零行为变更，零消费方改动（main.dart、token_audit_route_test.dart 透明无感知）。

## Key Decisions

1. **extension on MuseFlowApp（非 State 类）**：MuseFlowApp 是 ConsumerWidget，没有对应的 `_MuseFlowAppState` 类，故 extension 直接 on MuseFlowApp 本身。这是与 uho（on `_EditorWithSidebarState`）/ vdw（on `_ProviderManagementPageState`）模式的关键差异点。
2. **createRouter 去 _ 前缀**：extension 成员需要库内可见名，build() 内裸调用经 extension-on-this 解析到 extension 成员（uho 已验证可行）。
3. **_handleRedirect 留主文件**：它是 redirect guard 业务逻辑（读 Hive settings box 判 onboarding 完成），不属于声明式路由表，且 extension 内的 `redirect: _handleRedirect` 通过同库 part 可见性访问它（part of 文件共享主文件库作用域）。

## TDD Gate Compliance

N/A — 此为纯代码搬移重构（type: execute，非 type: tdd），不引入新行为。现有测试套件（1647 tests）作为回归基线全绿。

## Known Stubs

None — 路由表内容逐字等价，无 placeholder/TODO/hardcoded 空值。

## Threat Flags

None — 纯代码搬移重构，零行为变更。STRIDE 威胁面与重构前完全等价（路由表内容原样保留，redirect guard 逻辑未动）。无新增信任边界、无外部输入处理、无新依赖。

## Self-Check: PASSED

- FOUND: lib/app_routes.dart
- FOUND: lib/app.dart
- FOUND: c94be59（Task 1 commit）
- FOUND: e24a8cb（Task 2 commit）
- 最终行数：app.dart 98 行 / app_routes.dart 226 行
