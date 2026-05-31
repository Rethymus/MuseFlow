---
phase: 00-technical-validation
plan: 01
subsystem: editor-benchmark
tags: [spike, editor-comparison, performance, api-evaluation]
dependency_graph:
  requires: []
  provides: [editor-benchmark-apps, api-extensibility-evaluation, weighted-scorecard]
  affects: [00-02, 00-03]
tech_stack:
  added:
    - super_editor 0.3.0-dev.20 (benchmark only)
    - appflowy_editor 6.2.0 (benchmark only)
    - window_manager 0.5.1
  patterns:
    - SchedulerBinding.addTimingsCallback for frame timing
    - Deterministic Chinese text generation with seeded Random
key_files:
  created:
    - benchmark/shared/test_text_generator.dart
    - benchmark/super_editor_app/pubspec.yaml
    - benchmark/super_editor_app/lib/main.dart
    - benchmark/super_editor_app/lib/benchmark_runner.dart
    - benchmark/appflowy_editor_app/pubspec.yaml
    - benchmark/appflowy_editor_app/lib/main.dart
    - benchmark/appflowy_editor_app/lib/benchmark_runner.dart
    - benchmark/results/API_EXTENSIBILITY.md
    - benchmark/results/PERFORMANCE_DATA.md
    - benchmark/results/SCORECARD.md
  modified: []
decisions:
  - Dart SDK upgraded from 3.5.4 to 3.12.0 via flutter upgrade -- all CLAUDE.md aspirational versions now work
  - appflowy_editor 6.2.0 used (not 6.0.0) since Dart 3.12.0 supports the latest version
  - super_editor pinned to exact 0.3.0-dev.20 per RESEARCH.md Pitfall 4 (no caret syntax for dev channel)
  - Separate Flutter projects for each editor per RESEARCH.md Pitfall 2 (editors cannot coexist in same pubspec)
  - Shared test text generator copied into each project (separate pubspecs cannot share lib sources)
metrics:
  duration: 20m
  completed: 2026-06-01
  tasks_total: 3
  tasks_completed: 2
  tasks_remaining: 1 (checkpoint:human-verify)
  files_created: 10
  files_modified: 0
  commits: 2
---

# Phase 0 Plan 01: Editor Benchmark Spike Summary

API extensibility evaluation strongly favors appflowy_editor (5.0/5 vs 3.0/5) with built-in FloatingToolbar and JSON-compatible node attributes. Final recommendation pending IME validation (Plan 00-02) and manual performance benchmarking on Windows.

## Completed Tasks

### Task 1: Create separate benchmark apps for both editors
- **Commit:** 607f79a
- **Key files:** benchmark/super_editor_app/, benchmark/appflowy_editor_app/, benchmark/shared/test_text_generator.dart
- **Result:** Two separate Flutter projects that pass `dart analyze` with zero errors. Dependencies resolve successfully.

### Task 2: Run performance benchmarks and produce weighted scorecard
- **Commit:** 5e196a3
- **Key files:** benchmark/results/API_EXTENSIBILITY.md, PERFORMANCE_DATA.md, SCORECARD.md
- **Result:** API extensibility evaluation complete (source code verified). Performance data framework ready (actual measurements require Windows desktop execution).

## Key Findings

### Dart Version Upgrade
Flutter 3.44.0 was shipping Dart 3.5.4. After `flutter upgrade`, Dart is now 3.12.0. This resolves the entire version compatibility gap documented in RESEARCH.md. All CLAUDE.md aspirational package versions are now compatible.

### API Extensibility (20% weight -- COMPLETE)

| Capability | super_editor | appflowy_editor |
|-----------|:-----------:|:---------------:|
| Custom Block Components | 4/5 | **5/5** |
| Floating Toolbar API | 2/5 | **5/5** |
| Document Model Queryability | 3/5 | **5/5** |
| **Average** | **3.0** | **5.0** |

**appflowy_editor** dominates in all three capabilities:
- Built-in `FloatingToolbar` widget with configurable `ToolbarItem` list
- `Node.attributes` is `Map<String, dynamic>` -- JSON-compatible metadata for provenance tracking
- `BlockComponentBuilder` registration via simple map merge pattern

### Community Activity (10% weight -- COMPLETE)

| Metric | super_editor | appflowy_editor |
|--------|:-----------:|:---------------:|
| Score | **4/5** | 3/5 |

super_editor has more stars (1,924 vs 652) and very active dev-channel commits, but no stable release. appflowy_editor has stable releases backed by AppFlowy.

### Partial Score (30% of total)

| Editor | API (20%) | Community (10%) | Partial Total |
|--------|:---------:|:---------------:|:------------:|
| super_editor | 0.60 | 0.40 | **1.00** |
| appflowy_editor | 1.00 | 0.30 | **1.30** |

### Pending Scores (70% of total)

- **IME Compatibility (40%):** Filled by Plan 00-02
- **Performance (30%):** Filled after manual Windows desktop execution

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed Dart SDK version discrepancy**
- **Found during:** Task 1 (flutter upgrade step)
- **Issue:** RESEARCH.md assumed Dart 3.5.4 and recommended downgraded package versions. Actual Dart is 3.12.0 after upgrade.
- **Fix:** Used CLAUDE.md aspirational versions (appflowy_editor ^6.2.0) instead of RESEARCH.md fallback versions (6.0.0). Updated super_editor pubspec SDK constraint to ^3.12.0.
- **Files modified:** Both pubspec.yaml files
- **Commit:** 607f79a

**2. [Rule 1 - Bug] Fixed API mismatches in benchmark code**
- **Found during:** Task 1 (dart analyze)
- **Issue:** Multiple compile errors -- wrong API names (`createDefaultEditor` vs `createDefaultDocumentEditor`), wrong method signatures (`deleteNode(DocumentNode)` vs `deleteNode(String)`), missing imports (`ScrollController`, `Curves`).
- **Fix:** Corrected all API calls by reading source from pub cache. Added `flutter/widgets.dart` import. Made `loadText` public for external access.
- **Files modified:** benchmark_runner.dart, main.dart (both editors)
- **Commit:** 607f79a

**3. [Rule 1 - Bug] Fixed test_text_generator.dart type error**
- **Found during:** Task 1 (dart analyze)
- **Issue:** Dart record type `(String, String)` cannot be used in const list literal.
- **Fix:** Changed `List<(String, String)>` to `List<List<String>>` and updated access from `pair.$1`/`pair.$2` to `pair[0]`/`pair[1]`.
- **Files modified:** benchmark/shared/test_text_generator.dart
- **Commit:** 607f79a

**4. [Rule 3 - Blocking] Fixed shared import across separate pubspecs**
- **Found during:** Task 1 (code review)
- **Issue:** `../../shared/test_text_generator.dart` import won't resolve in separate Flutter projects.
- **Fix:** Copied shared generator into each project's lib directory.
- **Files modified:** Added test_text_generator.dart to both app lib/ directories
- **Commit:** 607f79a

## Known Stubs

| File | Line | Description | Reason |
|------|------|-------------|--------|
| PERFORMANCE_DATA.md | All result tables | Performance data fields are `--` placeholders | Requires manual execution on Windows desktop (WSL2 cannot run Windows GUI apps) |
| SCORECARD.md | IME section | IME scores marked `PENDING` | Filled by Plan 00-02 per plan design |
| SCORECARD.md | Performance section | Performance scores marked `PENDING` | Filled after manual benchmark execution |

## Threat Flags

No new security-relevant surface introduced beyond what the plan's threat model covers. The benchmark apps are standalone Flutter projects with no network access, no user data handling, and no authentication.

## Self-Check

- [x] benchmark/shared/test_text_generator.dart exists
- [x] benchmark/super_editor_app/pubspec.yaml exists
- [x] benchmark/super_editor_app/lib/main.dart exists
- [x] benchmark/super_editor_app/lib/benchmark_runner.dart exists
- [x] benchmark/appflowy_editor_app/pubspec.yaml exists
- [x] benchmark/appflowy_editor_app/lib/main.dart exists
- [x] benchmark/appflowy_editor_app/lib/benchmark_runner.dart exists
- [x] benchmark/results/API_EXTENSIBILITY.md exists (150 lines)
- [x] benchmark/results/PERFORMANCE_DATA.md exists (111 lines)
- [x] benchmark/results/SCORECARD.md exists (128 lines)
- [x] Commit 607f79a exists in git log
- [x] Commit 5e196a3 exists in git log
