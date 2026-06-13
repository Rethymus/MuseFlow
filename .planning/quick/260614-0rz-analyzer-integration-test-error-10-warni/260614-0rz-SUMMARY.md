---
phase: quick
plan: 260614-0rz
subsystem: testing
tags: [analyzer, tech-debt, regression-fix, flutter-test, dead-code]

# Dependency graph
requires:
  - phase: v1.5-docx-export
    provides: "ExportDialog.onExport named-param signature {textContent, binaryContent} (commit 7fa2ad2)"
provides:
  - "flutter analyze 全量零 issue 基线恢复（11 → 0）"
  - "integration_test onExport 回调与权威签名一致（命名参数）"
  - "测试文件死代码/未用 import 清理（9 imports + 1 class + 1 helper 简化）"
affects: [v1.5, integration-test, flutter-analyze-baseline]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "ExportDialog.onExport 双通道回调：text 格式走 textContent，binary 格式（DOCX）走 binaryContent"

key-files:
  created: []
  modified:
    - "integration_test/manuscript_flow_test.dart"
    - "test/features/editor/presentation/editor_shortcuts_test.dart"
    - "test/features/reports/application/editorial_review_service_test.dart"
    - "test/features/story_structure/application/export_service_test.dart"

key-decisions:
  - "删除 _NoOpAuditService 类后连带删除 4 个变未用 import（token_audit_service/audit_operation_type/token_audit_record/openai_dart），保证该文件 analyze 零 issue"
  - "集成测试 headless 跑不通为 SecureStorage KeyringLocked 环境限制，非代码回归；编译通过即视为 Task 1 达标"

patterns-established:
  - "测试文件清理 dead class 时必须 grep 确认连带 import 是否变 unused，否则留下新 warning"

requirements-completed: [TECH-DEBT-ANALYZER]

# Metrics
duration: 16min
completed: 2026-06-14
---

# Quick Task 260614-0rz: Analyzer Regression + Test Dead-Code Cleanup Summary

**修复 DOCX 导出签名变更导致的集成测试编译回归（1 error）并清理 v1.5 迭代遗留的 10 个 warning，恢复 `flutter analyze` "No issues found!" 基线（11→0），`flutter test` 维持 1524 passed / 0 failed 无回归。**

## Performance

- **Duration:** ~16 min
- **Started:** 2026-06-13T16:37:50Z
- **Completed:** 2026-06-13T16:54:00Z
- **Tasks:** 4 (3 fixes + 1 verification)
- **Files modified:** 4

## Accomplishments
- 修复集成测试 `onExport` 回调签名回归（`argument_type_not_assignable` error），改用命名参数 `{textContent, binaryContent}`，markdown 文本断言走 `textContent`
- `flutter analyze` 全量（lib + test + integration_test）从 11 issues 回到 **"No issues found!"**
- `flutter test` 全量套件维持 **1524 passed / 0 failed**（+12 skipped），零回归
- 清理 3 个测试文件死代码：9 个未用 import + 1 个 dead `_NoOpAuditService` class + 1 个恒真类型检查 + 1 个死分支

## Verification Evidence

### Task 4 硬指标（全部满足）

| 指标 | 目标 | 实际结果 | 状态 |
|------|------|----------|------|
| `flutter analyze` | "No issues found!" | `No issues found! (ran in 2.0s)` | PASS (11→0) |
| `flutter test` | 1524 passed / 0 failed | `+1524 ~12: All tests passed!` | PASS (无回归) |
| 集成测试编译 | 无 analyzer error | 编译通过，运行时报 `KeyringLocked`（环境限制） | PASS（编译通过即达标） |

### analyze 输出（基线对照）

修复前（11 issues）：
```
1 error  • argument_type_not_assignable @ integration_test/manuscript_flow_test.dart:155:25
5 warning • unused_import @ editor_shortcuts_test.dart:10,11,12,13,19
1 warning • unused_element (_NoOpAuditService) @ editor_shortcuts_test.dart:103:7
2 warning • unused_import @ editorial_review_service_test.dart:9,12
1 warning • unnecessary_type_check @ export_service_test.dart:16:7
1 warning • dead_code @ export_service_test.dart:19:3
11 issues found.
```

修复后：
```
Analyzing MuseFlow...
No issues found! (ran in 2.0s)
```

### 集成测试环境限制说明

`flutter test integration_test/manuscript_flow_test.dart` 编译通过（Task 1 核心：无 analyzer error），但运行时全部用例在 `setUp` 阶段失败，报错：
```
PlatformException(KeyringLocked, KeyringLocked, null, null)
```
该错误来自 `integration_test/manuscript_flow_test.dart:329` 的 `SecureStorageService().saveApiKey(...)` —— headless Linux 环境无解锁的 GNOME keyring / Windows Credential Manager，`flutter_secure_storage` 无法写入。这是**基础设施限制，非代码回归**：
- 发生在 `setUp` → `_initializeTestStorage`，先于任何导出逻辑
- 与本任务 `onExport` 签名修复无关（签名问题修复前同样会在 setUp 阶段失败）
- 计划已预见："headless 环境可能跑不完，编译通过无 analyzer error 即视为 Task 1 通过"

## Task Commits

每个任务原子提交：

1. **Task 1: 修复集成测试 onExport 回调签名回归** - `6fce67a` (fix)
2. **Task 2+3: 清理测试文件未用 import 与死代码** - `67c7b14` (chore)
   - （Task 2 与 Task 3 同属 test/ 目录、零冲突，按 constraints 合并为单个 chore 提交）

**Plan metadata：** 由 orchestrator 在 Step 8 统一提交 docs（SUMMARY/STATE/PLAN），本 executor 不提交 docs 产物。

## Files Created/Modified
- `integration_test/manuscript_flow_test.dart` - `onExport` 回调改命名参数 `{textContent, binaryContent}`，markdown 断言走 `textContent`（+2/-2 行）
- `test/features/editor/presentation/editor_shortcuts_test.dart` - 删除 9 个未用 import + dead `_NoOpAuditService` 类（净 -44 行区域）
- `test/features/reports/application/editorial_review_service_test.dart` - 删除 2 个未用 import（`editorial_review.dart`、`token_audit_record.dart`）
- `test/features/story_structure/application/export_service_test.dart` - `_decodeFile` 简化为单行 `utf8.decode(f.content)`，移除恒真类型检查与死分支

## Decisions Made
- **连带 import 删除（Task 2 偏差）**：删除 `_NoOpAuditService` 后，`token_audit_service.dart`、`audit_operation_type.dart`、`token_audit_record.dart`、`openai_dart.dart` 四个 import 失去唯一引用。计划 Task 2 只列了 5 个原始未用 import + `_NoOpAuditService` 类，未提及这 4 个连带 import。按 Rule 3（blocking issue）自动删除——否则留下 4 个新 `unused_import` warning，无法满足该文件 "analyze 零 issue" done criteria 与 Task 4 "No issues found!" 目标。grep 确认这 4 个符号在文件其余部分无任何引用。
- **集成测试 headless 失败归类**：`KeyringLocked` 为环境限制，编译通过即视为 Task 1 达标（计划已预见）。

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] 删除 `_NoOpAuditService` 后连带清理 4 个变未用的 import**
- **Found during:** Task 2 (editor_shortcuts_test 死代码清理)
- **Issue:** 计划要求删除 `_NoOpAuditService` 类，但该类是 `TokenAuditService`/`AuditOperationType`/`TokenAuditRecord`/`Usage`(openai_dart) 四个 import 的唯一引用源。删除类后这 4 个 import 立即变为 `unused_import`，会产生 4 个新 warning，破坏 "该文件 analyze 零 issue" done criteria 与 Task 4 "No issues found!" 目标。
- **Fix:** grep 确认 4 个符号在文件其余部分无引用后，一并删除这 4 个 import。
- **Files modified:** `test/features/editor/presentation/editor_shortcuts_test.dart`
- **Verification:** `flutter analyze test/features/editor/presentation/editor_shortcuts_test.dart` → "No issues found!"
- **Committed in:** `67c7b14` (Task 2+3 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** 必要的连带清理，无 scope creep。最终 editor_shortcuts_test.dart 从 13 个 import 精简到 4 个（仅保留 material/services/flutter_test/editor_ai_state），所有保留的 8 个 label 测试逻辑不变。

## Issues Encountered
- 集成测试 headless 环境跑不通（`PlatformException(KeyringLocked)`）—— `flutter_secure_storage` 在无桌面 keyring 的 Linux 上无法工作。这是已知环境限制，非本任务引入，编译通过即视为达标。

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `flutter analyze` 零 issue 基线恢复，后续提交可继续以此为准入门槛
- 集成测试签名回归已修复，真实 Windows/Android 桌面环境应可完整跑通（需有可用 keyring）
- 集成测试在 headless CI 跑不通属预存环境问题，建议后续在 CI 加 `--exclude-tags integration` 或 mock SecureStorage（超出本 quick 任务范围）

## Self-Check: PASSED

- 4 modified files: all FOUND
  - `integration_test/manuscript_flow_test.dart` ✓
  - `test/features/editor/presentation/editor_shortcuts_test.dart` ✓
  - `test/features/reports/application/editorial_review_service_test.dart` ✓
  - `test/features/story_structure/application/export_service_test.dart` ✓
- 2 task commits: all FOUND in git log
  - `6fce67a` (fix: onExport signature) ✓
  - `67c7b14` (chore: dead-code cleanup) ✓
- SUMMARY.md: FOUND

---
*Phase: quick (260614-0rz)*
*Completed: 2026-06-14*
