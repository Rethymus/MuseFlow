# Alex Novel Platform Evaluation Findings

## Scope

- Competitor: <https://github.com/Alex663028/Alex-Novel-Platform>
- Reviewed commit: `5ac3b372737b8b6060cd45fdda0c5596870fa69b`
- Review date: 2026-07-11
- MuseFlow boundary: the author remains in control; this work does not add
  one-click whole-book generation.

The review focused on evaluation and quality-control code, especially the
evaluation runners, prompt optimizer, style guardrails, anti-AI metrics, audit
service, and learning loop.

## Adopted Ideas

The strongest transferable pattern is a repeatable evaluation loop rather
than another generation feature:

1. Keep a fixed, versioned evaluation corpus.
2. Score multiple quality dimensions through one harness.
3. Compare parameter candidates under explicit constraints.
4. Persist the accepted quality baseline.
5. Fail CI when quality metrics or the recommended configuration drift.

MuseFlow already had sentence-level AI-scent signals and five-dimensional
author-style deviation analysis. The missing layer was a reproducible bridge
from those detectors to parameter calibration and regression control.

## MuseFlow Design

The implementation is deterministic and requires no model API:

- `quality/literary_quality_corpus.json` contains labeled human-like and
  AI-like Chinese prose plus a stable author-style profile.
- `LiteraryQualityEvaluator` combines existing style-deviation and
  sentence-level signals, then reports recall, false-positive rate, accuracy,
  balanced accuracy, and score separation.
- `LiteraryQualityBalancer` performs a stable grid search. Feasible candidates
  must meet recall and false-positive constraints before metric ranking.
- `quality/literary_quality_baseline.json` records the accepted configuration,
  metrics, corpus version, and quality floors.
- `tool/quality_eval.dart` exposes explicit check, balance, and baseline-update
  operations.
- CI runs both the baseline check and deterministic balance verification.

The balanced settings are also the production defaults in the existing
detectors. This keeps runtime behavior and CI measurement on the same ruler.

## Rejected Ideas

- Automatic end-to-end novel generation: conflicts with MuseFlow's
  author-led product model.
- Online self-learning in CI: introduces nondeterminism, privacy concerns, and
  API cost.
- Optimizing against a single aggregate score: can hide false positives on
  human prose. MuseFlow uses constraint-first selection instead.
- Silent baseline updates: would normalize regressions. Baselines change only
  through the explicit `--update-baseline` command and code review.

## Commands

```bash
dart run tool/quality_eval.dart --check
dart run tool/quality_eval.dart --balance
dart run tool/quality_eval.dart --update-baseline
```

`--update-baseline` is intended only for reviewed corpus or detector changes.
