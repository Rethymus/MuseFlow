---
phase: quick
plan: 260616-vdw
subsystem: ai-presentation
tags: [refactor, dart-part, mechanical-split, uho-pattern, redline-elimination]
requires:
  - 260616-uho（同库 part + extension-on-State 模式先例）
provides:
  - provider_management_page_layout.dart（layout helper part 文件）
affects:
  - lib/features/ai/presentation/provider_management_page.dart
tech-stack:
  added: []
  patterns:
    - "同库 extension-on-State part（uho 模式精确复刻）"
    - "State 类内私有 setState wrapper helper（应对 protected member lint）"
key-files:
  created:
    - lib/features/ai/presentation/provider_management_page_layout.dart
  modified:
    - lib/features/ai/presentation/provider_management_page.dart
decisions:
  - "D-1: 复用 uho 同库 extension-on-State 模式（vs uho 多 part / qxe 数据表 part）— _ProviderManagementPageState 单 State 类，3 个 build helper 唯一拆分目标"
  - "D-2 (Rule 1): extension 不能合法调用 setState（invalid_use_of_protected_member lint），新增 4 个 State 类内私有 helper 包装 setState，extension 改调 helper — 行为等价，零状态字段变更"
metrics:
  duration: "~25 min"
  completed: 2026-06-16
  tasks_completed: 2
  files_changed: 2
  main_file_lines_before: 737
  main_file_lines_after: 329
---

# Phase quick Plan 260616-vdw: Refactor provider_management_page.dart Summary

按 260616-uho 验证过的同库 part + extension-on-State 模式，机械拆分 `provider_management_page.dart`，将 3 个 build helper（`_buildMobileSwitcher`/`_buildLeftPanel`/`_buildRightPanel`）抽取到独立 part 文件 `_ProviderManagementPageStateLayout` 私有扩展，主文件 737→329 行，消除 03-flutter-standards.md 800 行红线，零行为变更。

## What Built

**新建 `lib/features/ai/presentation/provider_management_page_layout.dart`**（452 行）
- 首行 `part of 'provider_management_page.dart';`，零 import（Dart part 规则）
- doc comment 说明抽取理由（参考 uho layout part 措辞）
- `extension _ProviderManagementPageStateLayout on _ProviderManagementPageState` 包装 3 个方法
- 方法体从主文件原样搬运（仅位置 + extension 包装）

**改造 `lib/features/ai/presentation/provider_management_page.dart`**（737→329 行）
- 文件顶部加 `library;` 块 + doc comment（参考 uho editor_with_sidebar.dart L1-7）
- 最后 import 后加 `part 'provider_management_page_layout.dart';`
- 删除已搬走的 3 个 build helper（原 L297-736，440 行）
- build() 内裸调用保持原样（Dart 同库 extension-on-this 解析）

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] setState 在 extension 内触发 invalid_use_of_protected_member**

- **Found during:** Task 2 验证门（flutter analyze）
- **Issue:** flutter analyze 报 4 个 `invalid_use_of_protected_member` 警告（layout part 的 setState 调用，违反 CLAUDE.md "flutter analyze 零错误" 硬约束）。uho 先例（editor_with_sidebar_layout.dart）不含 setState 调用，所以样板未暴露此问题；vdw 拆出的 3 个 helper 内含 4 处 setState。
- **Fix:** 在主文件 `_ProviderManagementPageState` 类内新增 4 个私有 setState wrapper helper：
  - `_showListOnNarrow()` → `setState(() => _showList = true)`
  - `_selectCustomProviderType()` → `setState(() { _selectedType = AiProviderType.custom; _showList = false; })`
  - `_selectProviderType(type)` → `setState(() => _selectedType = type)`
  - `_toggleApiKeyVisibility()` → `setState(() => _obscureApiKey = !_obscureApiKey)`
  - extension 内对应位置改调这些 helper
- **行为等价：** 仅是将 `setState(() => ...)` 字面量替换为同效果的私有方法调用，状态字段、状态值、状态变更时机零变化。
- **Files modified:**
  - `lib/features/ai/presentation/provider_management_page.dart`（新增 4 helper，+32 行净）
  - `lib/features/ai/presentation/provider_management_page_layout.dart`（4 处 setState 调用替换为 helper 调用）
- **Commit:** afc9e23

无其他 deviation。Task 1 严格按 PLAN 执行（无 setState 问题，因 helper 在 part 文件原样搬运时即已存在，本应在 Task 2 接入后暴露）。

## Verification Results

| Gate | Expected | Actual |
|------|----------|--------|
| 主文件行数 < 800 | < 800 | **329** ✓ |
| 主文件含 `library;` | 1 | 1 ✓ |
| 主文件含 `part '..._layout.dart';` | 1 | 1 ✓ |
| part 文件首行 `part of` | 1 | 1 ✓ |
| part 文件 import 数 | 0 | 0 ✓ |
| part 文件 setState 残留 | 0 | 0 ✓（Rule 1 fix 后） |
| flutter analyze | No issues | **No issues found! (2.4s)** ✓ |
| flutter test | 1647 passed +12 skipped exit 0 | **+1647 ~12 All tests passed!** ✓ exit 0 |
| git diff --stat 文件数 | 2（主改 + 1 新 part） | 2 ✓ |
| 消费方零改动 | empty | empty ✓（lib/app.dart + provider_management_responsive_test.dart） |

## Consumer Impact Analysis

2 个消费方均导入主库文件路径，公共类 `ProviderManagementPage` 签名/语义零变更：

```
lib/app.dart:7:        import 'package:museflow/features/ai/presentation/provider_management_page.dart';
test/features/ai/presentation/provider_management_responsive_test.dart:9: import 'package:museflow/features/ai/presentation/provider_management_page.dart';
```

`git diff HEAD -- lib/app.dart test/...responsive_test.dart` → empty（零改动）。

## Pattern Reuse

精确复刻 260616-uho（editor_with_sidebar.dart 887→640 行）模式：
- 同库 part/part of 机制
- `extension _<StateName>Layout on _<StateName>` 私有命名扩展
- 主文件 `library;` 块 + import 后 part 指令
- 公共类签名零变更，消费方零改动

唯一与 uho 的实质差异：vdw 搬出的 helper 含 setState 调用，uho 不含。故 vdw 引入"State 类内私有 setState wrapper helper"模式补充 uho（后续若再遇到含 setState 的 State helper 拆分可直接复用）。

## Self-Check: PASSED

- [x] `lib/features/ai/presentation/provider_management_page.dart` 存在，329 行
- [x] `lib/features/ai/presentation/provider_management_page_layout.dart` 存在，452 行
- [x] commit f056b0f 存在（Task 1）
- [x] commit afc9e23 存在（Task 2）
- [x] `git log --oneline -3` 顶部为 afc9e23 → f056b0f → 2005f17
