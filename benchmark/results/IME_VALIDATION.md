# IME Validation Report

**Phase:** 0 - Technical Validation
**Plan:** 00-02
**Date:** 2026-06-01
**Toolchain:** Flutter 3.44.0 (stable) / Dart 3.12.0 / Windows (WSL2)
**Status:** Automated tests complete; manual testing PENDING

---

## Section 1: Automated Test Results

| Test Scenario | super_editor Result | appflowy_editor Result | Notes |
|---|---|---|---|
| Pinyin composing -> single char commit ("jin" -> "今") | **PASS** | **ERROR** | appflowy_editor 6.2.0 fails to compile with Flutter 3.44.0 |
| Multi-character commit ("jintian" -> "今天") | **PASS** | **ERROR** | `DeltaTextInputService` missing `TextInputClient.onFocusReceived` |
| Composition cancellation (backspace during composing) | **PASS** | **ERROR** | Flutter 3.44.0 added `onFocusReceived` to `TextInputClient` interface |
| Mixed Chinese and ASCII ("hello" + "nihao" -> "hello你好") | **PASS** | **ERROR** | appflowy_editor git main branch also has this issue |

### super_editor Details

- **Version:** 0.3.0-dev.51 (resolved from ^0.3.0-dev.20 constraint)
- **Tests:** 4/4 passed
- **Test approach:** Direct document model manipulation via `Editor.execute()` with `InsertTextRequest` and `DeleteContentRequest`
- **All composing-to-committed lifecycle transitions handled correctly**

### appflowy_editor Details

- **Version:** 6.2.0 (latest available on pub.dev)
- **Tests:** 0/4 -- compilation failure
- **Root cause:** `appflowy_editor 6.2.0` class `DeltaTextInputService` extends `TextInputService with DeltaTextInputClient`, but `TextInputClient` interface in Flutter 3.44.0 requires `onFocusReceived()` method which appflowy_editor does not implement
- **Git main branch:** Same issue exists in the latest git main (commit 6fbe7ba)
- **Impact:** appflowy_editor 6.2.0 is **INCOMPATIBLE** with Flutter 3.44.0 / Dart 3.12.0
- **Resolution needed:** Either (a) downgrade Flutter to a version where appflowy_editor compiles, or (b) wait for appflowy_editor to release a compatible version

---

## Section 2: Known Bug Verification Checklist

| Bug | Editor | Status | Notes |
|---|---|---|---|
| #2588 IME candidate window wrong position on Windows | super_editor | **Requires Manual Testing** | Automated tests verify text content only; candidate window position needs physical keyboard testing |
| #2728 Chinese composing crash when deleting at end of text | super_editor | **Automated: PASS** | Cancellation test deletes composing text without crash (via document model API, not live IME) |
| #696 Sogou garbled character order | appflowy_editor | **BLOCKED** | Cannot test -- appflowy_editor fails to compile on Flutter 3.44.0 |

---

## Section 3: Manual Test Protocol

Per D-08 (dual validation) and D-09 (3 input methods: Sogou Pinyin, Wubi, Microsoft Pinyin).

### 3.1 Test Combinations

| # | Editor | Input Method | Launch Command |
|---|---|---|---|
| 1 | super_editor | Sogou Pinyin | `cd benchmark/ime_super_editor_app && flutter run -d windows` |
| 2 | super_editor | Wubi | `cd benchmark/ime_super_editor_app && flutter run -d windows` |
| 3 | super_editor | Microsoft Pinyin | `cd benchmark/ime_super_editor_app && flutter run -d windows` |
| 4 | appflowy_editor | Sogou Pinyin | `cd benchmark/ime_appflowy_editor_app && flutter run -d windows` |
| 5 | appflowy_editor | Wubi | `cd benchmark/ime_appflowy_editor_app && flutter run -d windows` |
| 6 | appflowy_editor | Microsoft Pinyin | `cd benchmark/ime_appflowy_editor_app && flutter run -d windows` |

**NOTE:** Combinations 4-6 are BLOCKED due to appflowy_editor 6.2.0 compile failure on Flutter 3.44.0.

### 3.2 Per-Combination Test Steps

For each combination above:

1. **Launch** the IME test app using the command in the table
2. **Switch** to the target input method
3. **Type the test phrase** (see table below)
4. **Verify:**
   - Composing underline appears during input
   - Candidate window appears near cursor
   - Committed text is correct (no garbled characters)
5. **Explicitly check:** IME candidate window position -- is it below the cursor or in the wrong position? (per super_editor #2588)
6. **Test deletion during composing:** Type pinyin, press backspace during composing, verify clean cancellation
7. **Test selection during composing:** Type pinyin, use arrow keys to select alternative candidate, verify correct character committed

### 3.3 Test Phrases per Input Method

| Input Method | Type | Expected Result |
|---|---|---|
| Sogou Pinyin | `jintian tianqi bucuo` | 今天天气不错 |
| Wubi | `wgkq` | 今天 (Wubi code: wg=jt, kq=tian -- verify correct Wubi encoding) |
| Microsoft Pinyin | `women shi zhongguo ren` | 我们是中国人 |

### 3.4 Scoring Guide

| Score | Meaning |
|---|---|
| 5 | Perfect -- composing underline, correct candidates, correct commit, candidate window in right position |
| 4 | Minor cosmetic issue -- text correct, slight position offset |
| 3 | Usable with minor issues -- text commits correctly but candidate window position is noticeably off |
| 2 | Usable with significant issues -- text usually correct but occasional glitches |
| 1 | Broken -- garbled text, crashes, or characters out of order |

---

## Section 4: IME Scoring Template

Per D-02 (40% weight for IME compatibility in final scorecard).

### super_editor IME Scores

| Criterion | Score | Notes |
|---|---|---|
| Sogou Pinyin | PENDING MANUAL TESTING | |
| Wubi | PENDING MANUAL TESTING | |
| Microsoft Pinyin | PENDING MANUAL TESTING | |
| IME candidate window position | PENDING MANUAL TESTING | Check against #2588 |
| **Average IME score (super_editor)** | **PENDING** | |

### appflowy_editor IME Scores

| Criterion | Score | Notes |
|---|---|---|
| Sogou Pinyin | PENDING MANUAL TESTING | Blocked by compile failure |
| Wubi | PENDING MANUAL TESTING | Blocked by compile failure |
| Microsoft Pinyin | PENDING MANUAL TESTING | Blocked by compile failure |
| IME candidate window position | PENDING MANUAL TESTING | Blocked by compile failure |
| **Average IME score (appflowy_editor)** | **PENDING** | |

### Compile Compatibility Score

| Editor | Compiles on Flutter 3.44.0 | Score |
|---|---|---|
| super_editor (0.3.0-dev.51) | Yes | 5 |
| appflowy_editor (6.2.0) | **No** | 1 |

**This is a critical finding for the editor selection decision (D-04).**

---

## Critical Finding: appflowy_editor Incompatibility

appflowy_editor 6.2.0 (the latest published version) does not compile on Flutter 3.44.0 due to a missing `TextInputClient.onFocusReceived` implementation in `DeltaTextInputService`. The same issue exists on the git main branch.

This means:
1. **Manual IME testing for appflowy_editor is BLOCKED** until a compatible version is released
2. **appflowy_editor scores 1/5 on compile compatibility** -- it cannot be used as-is
3. The editor selection decision (D-04) may be determined by this incompatibility alone

**Plan 00-03 should note this finding when consolidating scores into SCORECARD.md.**

---

*Report generated: 2026-06-01*
*These IME scores are standalone; Plan 00-03 will consolidate into the final weighted SCORECARD.md*
