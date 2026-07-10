---
quick_id: 260711-lqe
slug: literary-quality-evaluation-balance
date: 2026-07-11
status: complete
commits: []
---

# Literary Quality Evaluation and Balance - Delivery

## Research

- Reviewed Alex-Novel-Platform at commit
  `5ac3b372737b8b6060cd45fdda0c5596870fa69b`.
- Documented the useful pattern: a fixed evaluation set, multi-metric scoring,
  deterministic candidate comparison, persisted baselines, and regression
  gates. Rejected one-click whole-book generation to preserve MuseFlow's
  author-led workflow.

## Implementation

- Added a versioned 16-sample Chinese literary-quality corpus and author style
  profile.
- Added shared evaluation over the existing sentence AI-scent and five-axis
  style deviation detectors, including confusion-matrix metrics and baseline
  drift checks.
- Added deterministic constraint-first grid search across 80 configurations.
- Calibrated the production defaults to the selected configuration and added a
  test that locks evaluator defaults to the production detectors.
- Added `tool/quality_eval.dart` with explicit `--check`, `--balance`, and
  `--update-baseline` modes.
- Added CI gates for baseline stability and deterministic balance selection.

## Accepted Baseline

- Balanced accuracy: `0.9375`
- AI-like recall: `0.875`
- Human false-positive rate: `0.0`
- Accuracy: `0.9375`
- Score separation: `33.0`
- Confusion matrix (TP/FN/TN/FP): `7/1/8/0`

Quality constraints are balanced accuracy >= `0.85`, recall >= `0.75`, and
false-positive rate <= `0.1`.

## Verification

- `dart format --set-exit-if-changed .`: 553 files, no changes.
- `flutter analyze`: no issues.
- Focused editor quality tests: 38 passed before the final default-contract
  assertion was added; the affected test file was rerun after that edit.
- `dart run tool/quality_eval.dart --check`: passed.
- `dart run tool/quality_eval.dart --balance`: passed with the committed
  configuration selected from 80 candidates.
- Repository validation scripts: all passed.
- Full `flutter test`: 1777 passed, 28 expected skips, exit code 0.

GitHub Actions itself and CI build/integration smoke jobs were not executed
locally. The newly added deterministic quality gates and the complete local
unit/journey suite passed.
