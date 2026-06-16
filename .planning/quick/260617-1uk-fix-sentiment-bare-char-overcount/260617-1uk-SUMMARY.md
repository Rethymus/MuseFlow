---
phase: quick
plan: 260617-1uk
subsystem: editor/style-deviation
tags: [bugfix, sentiment, ai-scent, tdd]
requires:
  - StyleDeviationDetector._countPositiveSentiment
  - StyleDeviationDetector._countNegativeSentiment
provides:
  - Correct emotionalTone intensity for compound-word-heavy text
  - Two regression tests pinning the bare-char overcount behavior
affects:
  - lib/features/editor/application/style_deviation_detector.dart
  - test/features/editor/application/style_deviation_detector_test.dart
tech-stack:
  added: []
  patterns:
    - "Substring-safe lexicon curation (omit bare single-char needles in String.allMatches loops)"
key-files:
  created: []
  modified:
    - lib/features/editor/application/style_deviation_detector.dart
    - test/features/editor/application/style_deviation_detector_test.dart
decisions:
  - "Removal-only fix (do not import shared infrastructure sentiment_lexicon.dart) to honor application→infrastructure architecture rule"
  - "Add design-rule comments on both Sets rather than restructure matching logic (out of scope per planner)"
metrics:
  duration: 3m50s
  completed: 2026-06-16T17:28:27Z
  tasks_total: 3
  tasks_completed: 3
  files_changed: 2
requirements: [BUGFIX-sentiment-bare-char-overcount]
---

# Phase quick Plan 260617-1uk: Sentiment Bare-Char Overcount Fix Summary

Two-line surgical removal of bare single-char `爱`/`恨` from inline sentiment Sets that `String.allMatches` was substring-matching inside common compounds (`恨不得` eager/positive, `可爱`/`爱好`/`爱情`), inflating warmth/intensity and inverting polarity on the emotionalTone dimension feeding the AI-scent score.

## Root Cause

`_countPositiveSentiment` and `_countNegativeSentiment` (in `lib/features/editor/application/style_deviation_detector.dart`) build `const Set<String>` lexicons and scan text with `for (final word in set) count += word.allMatches(text).length;`. `String.allMatches` performs **substring** matching, not token matching. Two entries were bare single chars:

- `'爱'` (positives) → matched inside `可爱` / `爱好` / `爱情` / `亲爱` → spurious positive hits.
- `'恨'` (negatives) → matched inside `恨不得` (which is eager/positive sense, "dying to do X"), `悔恨`, `愤恨` → spurious negative hits. Worst case is **polarity inversion**: a positive passage measured as negative.

The inflated `positiveCount + negativeCount` feeds `_computeEmotionalTone`'s `intensity` formula, which feeds `textValue` on the `emotionalTone` `DimensionDeviation`, which in turn moves the AI-scent deviation score on a product-soul "反AI味" feature.

## The Fix

Exactly two lines removed plus two concise design-rule comments. No logic change, no new entries, no new imports.

```diff
   int _countPositiveSentiment(String text) {
+    // NOTE: omit bare single-char entries (e.g. 爱) — String.allMatches does
+    // substring matching and would over-count inside compounds such as
+    // 可爱/爱好/爱情/亲爱, distorting warmth/intensity.
     const positives = <String>{ ... '欣慰',
-      '爱',
       '喜欢', '珍惜', };

   int _countNegativeSentiment(String text) {
+    // NOTE: omit bare single-char entries (e.g. 恨) — String.allMatches does
+    // substring matching and would over-count inside compounds such as
+    // 恨不得 (eager/positive sense) / 悔恨/愤恨, inverting polarity.
     const negatives = <String>{ ... '害怕',
-      '恨',
       '厌恶', };
```

Precedent followed: commit `9122b01` (2026-06-17), same file, same methods — prior bug fix converted `const List` → `const Set` and removed duplicates. This change continues that structural, data-only edit pattern.

## Regression Tests

Both tests go through the public `analyze()` API and assert on `deviations.firstWhere((d) => d.dimension == StyleDimension.emotionalTone).textValue < 0.6`. No private method is exercised directly.

### Test A — `should not inflate negative sentiment via bare 恨 inside 恨不得 when text is dominated by eager 恨不得`

Fixture: `'他恨不得立刻出发。她恨不得马上跑去。两人恨不得飞过去。'`

- **Why this reproduces RED:** three `恨不得` occurrences in a short ~21-CJK-char passage. Pre-fix, the bare `'恨'` needle matches all three → `negativeCount = 3`, `intensity = (3)/(21*0.03+1)*0.5 + 0.5 = (3/1.63)*0.5 + 0.5 ≈ 1.42`, clamped to **1.0**. Test asserts `< 0.6` → fails loudly (actual = 1.0).
- **Post-fix:** no genuine negative words present → `negativeCount = 0` → `intensity = 0.5`. GREEN.

### Test B — `should not inflate positive sentiment via bare 爱 inside 可爱/爱好 compounds when no genuine positives are present`

Fixture: `'小女孩可爱极了。这是她的爱好。她相信爱情。'`

- **Why this reproduces RED:** three `爱`-containing compounds (`可爱`, `爱好`, `爱情`) in a short ~17-CJK-char passage. Pre-fix, the bare `'爱'` needle matches all three → `positiveCount = 3`, `intensity = (3)/(17*0.03+1)*0.5 + 0.5 ≈ 1.48`, clamped to **1.0**. Test asserts `< 0.6` → fails loudly (actual = 1.0). Note none of `可爱`/`爱好`/`爱情` are listed positives — the *only* positive signal pre-fix is the false substring hit.
- **Post-fix:** `positiveCount = 0` → `intensity = 0.5`. GREEN.

Both fixtures were verified RED on the unfixed source before applying the fix (Task 1 commit `06b3838`); after the fix both are GREEN (Task 2 commit `034b529`).

## Test Counts

| Scope                        | Before fix | After fix | Delta |
| ---------------------------- | ---------- | --------- | ----- |
| Targeted detector test file  | 13 pass    | 15 pass   | +2    |
| Full project suite           | 1,647 pass | 1,649 pass (+12 skipped) | +2    |
| `flutter analyze`            | 0 errors   | 0 errors  | —     |

Zero regressions across the entire 1,649-test baseline. Pre-existing detector tests use shape/explanation assertions and do not pin exact sentiment counts, so removing the two entries does not affect them.

## Architecture Compliance

- No new imports added to `style_deviation_detector.dart`.
- The shared lexicon `lib/features/editor/infrastructure/sentiment_lexicon.dart` was **not** imported. Per `.claude/rules/02-museflow-architecture.md`, the application layer (`features/editor/application/`) MUST NOT depend on the infrastructure layer (`features/editor/infrastructure/`). The inline Set is the architecturally correct placement; only its bad entries were removed.
- No restructuring of the Sets or matching loop — removal-only, matching planner scope rule.

## Deviations from Plan

None — plan executed exactly as written. All three tasks (RED tests → GREEN fix → full-suite gate) completed in order with the prescribed commit message conventions (`test(quick-260617-1uk):` and `fix(quick-260617-1uk):`).

## Self-Check: PASSED

- `lib/features/editor/application/style_deviation_detector.dart` — FOUND (modified, 2 lines removed + 6 comment lines added)
- `test/features/editor/application/style_deviation_detector_test.dart` — FOUND (+65 lines, regression group)
- Commit `06b3838` — FOUND (`test(quick-260617-1uk): add failing regression tests for 恨/爱 substring overcount`)
- Commit `034b529` — FOUND (`fix(quick-260617-1uk): remove bare 爱/恨 from inline sentiment Sets`)
- `grep sentiment_lexicon lib/features/editor/application/style_deviation_detector.dart` → no matches (architecture intact)
