---
quick_id: 260711-lqe
slug: literary-quality-evaluation-balance
date: 2026-07-11
status: complete
---

# Literary Quality Evaluation and Balance

## Goal

Turn the competitor evaluation research into a deterministic MuseFlow quality
loop: fixed corpus, shared detector scoring, constrained parameter search,
persisted baseline, regression tests, and CI gates.

## Work

- Make existing sentence and style detectors accept calibrated defaults while
  preserving their public APIs.
- Add corpus parsing, confusion-matrix metrics, baseline drift checks, and a
  deterministic balancer.
- Commit a versioned Chinese prose corpus and accepted baseline.
- Add `--check`, `--balance`, and explicit `--update-baseline` CLI modes.
- Document adopted and rejected competitor ideas.
- Verify focused tests, full tests, analysis, formatting, quality gates, and
  repository checks.

## Acceptance

- Human-like false-positive rate is at most 10%.
- AI-like recall is at least 75%.
- Balanced accuracy is at least 85%.
- Repeated balance runs select the same committed production configuration.
- CI fails on metric, corpus-version, or recommended-config drift.
