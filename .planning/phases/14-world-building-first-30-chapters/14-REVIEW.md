---
phase: 14-world-building-first-30-chapters
reviewed: 2026-06-07T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - test/journey/chapter_management_test.dart
  - test/journey/fragment_synthesis_test.dart
  - test/journey/full_journey_test.dart
  - test/journey/helpers/journey_container.dart
  - test/journey/helpers/story_outline.dart
  - test/journey/helpers/xianxia_fixtures.dart
  - test/journey/opening_guide_test.dart
  - test/journey/serial_generation_test.dart
  - test/journey/world_building_test.dart
findings:
  critical: 1
  warning: 3
  info: 2
  total: 6
status: issues_found
---

# Phase 14: Code Review Report

**Reviewed:** 2026-06-07T00:00:00Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Reviewed the listed Dart journey test files and helpers for correctness, security, and test reliability. The main risk is that the shared Hive setup uses global fixed box names and global cleanup, which makes the journey suite unsafe under Dart’s default parallel test execution. Several tests also assert against stale values or skip deterministic coverage behind an unrelated GLM API key.

## Critical Issues

### CR-01: Journey tests share global Hive state and can corrupt each other under parallel execution

**File:** `test/journey/helpers/journey_container.dart:27-47,73-76`

**Issue:** `createJourneyContainer` calls global `Hive.init(tempDir.path)` and opens fixed box names such as `manuscripts`, `chapters`, and `fragments`. `cleanupJourneyContainer` then calls `Hive.deleteFromDisk()` globally. Dart test files run concurrently by default, so two journey test files can initialize/open/delete the same global Hive boxes at the same time. One suite can delete boxes while another suite is still reading or writing them, causing nondeterministic failures or cross-test data loss.

**Fix:** Serialize these integration tests or isolate Hive state per test process. At minimum, add a test runner configuration for the journey suite with concurrency disabled, and close/delete boxes deterministically.

## Warnings

### WR-01: Copy test verifies stale pre-update content instead of copied persisted content

**File:** `test/journey/chapter_management_test.dart:320-345`

**Issue:** The test updates chapter 3 via `updateDocumentContent`, but then creates the copied chapter from the stale local `ch3.documentContent`. Because `ch3` was captured before the update, its `documentContent` is still the original empty/default value. The final assertion compares the copied content against the same stale value, so the test can pass even if copying updated chapter content is broken.

**Fix:** Re-read the updated source chapter before copying and assert against the intended updated text.

### WR-02: Deterministic world-building repository tests are skipped when GLM_API_KEY is absent

**File:** `test/journey/world_building_test.dart:10-32,55-99`

**Issue:** The world-building tests only exercise local repositories, fixtures, and `NameIndex` refresh behavior, but every test is skipped when `GLM_API_KEY` is missing. This hides deterministic local regressions behind an unrelated external API credential and reduces CI coverage.

**Fix:** Do not gate non-network repository tests on `GLM_API_KEY`. Use a dummy API key for the container, as already done in `chapter_management_test.dart`.

### WR-03: Live LLM output length assertions make serial generation tests flaky

**File:** `test/journey/serial_generation_test.dart:144-150`

**Issue:** The test asserts every live GLM-generated chapter is between 300 and 500 characters. Live model output is nondeterministic and can legitimately drift outside that range due to provider behavior, model updates, retries, prompt changes, or Chinese character/token differences. This makes the test suite flaky even when the application pipeline works.

**Fix:** Move strict length validation to deterministic prompt/unit tests with a fake adapter, and keep the live journey test to smoke-level invariants, or enforce the 300-500 range in application code and test that enforcement with a fake adapter.

## Info

### IN-01: Tests use `print` despite project convention requiring `debugPrint`

**File:** `test/journey/fragment_synthesis_test.dart:190-198,260-281`

**Issue:** The project standard says to use `debugPrint` instead of `print`. This file suppresses `avoid_print` and prints streaming errors, synthesis lengths, and knowledge warnings directly.

**Fix:** Replace `print(...)` with `debugPrint(...)` and import `package:flutter/foundation.dart` where needed.

### IN-02: Opening guide tests use `print` despite project convention requiring `debugPrint`

**File:** `test/journey/opening_guide_test.dart:86-95,134-137`

**Issue:** The project standard says to use `debugPrint` instead of `print`. This file suppresses `avoid_print` for opening previews and style output.

**Fix:** Replace `print(...)` with `debugPrint(...)` and import `package:flutter/foundation.dart`.

---

_Reviewed: 2026-06-07T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
