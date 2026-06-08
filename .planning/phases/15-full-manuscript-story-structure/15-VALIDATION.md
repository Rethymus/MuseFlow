---
phase: 15
slug: full-manuscript-story-structure
status: complete
nyquist_compliant: true
wave_0_complete: true
updated: 2026-06-08
---

# Phase 15 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter test (`flutter_test`, `integration_test`) |
| **Config file** | `pubspec.yaml` dev dependencies |
| **Quick run command** | `flutter test test/journey/ -j 1` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~15-120 seconds locally for deterministic journey subset; GLM-backed tests skip when `GLM_API_KEY` is absent |

---

## Sampling Rate

- **After every task commit:** Run targeted plan command from the corresponding PLAN verify block.
- **After every plan wave:** Run `flutter test test/journey/ -j 1`.
- **Before `/gsd:verify-work`:** Full relevant journey suite must be green.
- **Max feedback latency:** 120 seconds for deterministic local checks; GLM-backed checks are optional/manual due external API latency.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 15-01-01 | 01 | 1 | JOURNEY-07/08/09/10 | T-15-01, T-15-02 | Static test fixtures only; no secrets or mutable production state | fixture/unit | `dart analyze test/journey/helpers/story_outline.dart test/journey/helpers/stage_prompts.dart` | ✅ | ✅ green |
| 15-02-01 | 02 | 2 | JOURNEY-07 | T-15-03, T-15-04 | GLM key sanitized; deterministic path runs without credentials; temp Hive cleanup | journey/integration | `flutter test test/journey/serial_generation_test.dart -j 1 --plain-name "deterministic 100-chapter journey" --timeout 600s` | ✅ | ✅ green |
| 15-03-01 | 03 | 2 | JOURNEY-07 | T-15-05 | Foreshadowing data isolated in temp Hive boxes | journey/integration | `flutter test test/journey/foreshadowing_lifecycle_test.dart -j 1 --timeout 120s` | ✅ | ✅ green |
| 15-04-01 | 04 | 2 | JOURNEY-08 | T-15-06 | Pure Dart format-cleaning service; no external I/O | journey/unit | `flutter test test/journey/format_cleaning_test.dart -j 1 --timeout 120s` | ✅ | ✅ green |
| 15-04-02 | 04 | 2 | JOURNEY-09 | T-15-06 | ExportService uses no-op FileWriter in tests; no filesystem writes | journey/unit | `flutter test test/journey/export_validation_test.dart -j 1 --timeout 120s` | ✅ | ✅ green |
| 15-05-01 | 05 | 2 | JOURNEY-10 | T-15-07 | Token audit uses temp Hive storage and explicit flush before read | journey/integration | `flutter test test/journey/statistics_accuracy_test.dart -j 1 --timeout 300s` | ✅ | ✅ green |
| 15-06-01 | 06 | 3 | JOURNEY-07, JOURNEY-10 | T-15-08, T-15-09, T-15-10 | GLM errors sanitized; issue log warns against secret capture | journey/e2e | `flutter test test/journey/full_journey_test.dart -j 1 --plain-name "should complete deterministic full xianxia journey to 100 chapters" --timeout 600s` | ✅ | ✅ green |
| 15-07-01 | 07 | 3 | JOURNEY-07/08/09/10 | T-15-11 | Automated evidence uses FakeAdapter and no external services | journey/evidence | `flutter test test/journey/automated_ui_evidence_test.dart -j 1 --timeout 300s` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Requirement Coverage

| Requirement | Automated Coverage | Evidence | Status |
|-------------|--------------------|----------|--------|
| JOURNEY-07 | 100-chapter serial generation; stage prompts; previous-summary injection; foreshadowing lifecycle; deviation detection; deterministic E2E | `test/journey/serial_generation_test.dart`, `test/journey/foreshadowing_lifecycle_test.dart`, `test/journey/full_journey_test.dart`, `test/journey/automated_ui_evidence_test.dart` | ✅ COVERED |
| JOURNEY-08 | 100-chapter FormatCleaner validation for Markdown residue, CJK/ASCII punctuation, layout anomalies, idempotency | `test/journey/format_cleaning_test.dart`, `test/journey/automated_ui_evidence_test.dart` | ✅ COVERED |
| JOURNEY-09 | Markdown/TXT/JSON export validation across 100 chapters, metadata, content consistency, file size range | `test/journey/export_validation_test.dart`, `test/journey/automated_ui_evidence_test.dart` | ✅ COVERED |
| JOURNEY-10 | 100-chapter writing stats, AI usage ratio, writing speed, token audit count/totals/per-record fields | `test/journey/statistics_accuracy_test.dart`, `test/journey/full_journey_test.dart`, `test/journey/automated_ui_evidence_test.dart` | ✅ COVERED |

---

## Wave 0 Requirements

- [x] `test/journey/helpers/story_outline.dart` — 100-chapter outline fixture for JOURNEY-07/08/09/10
- [x] `test/journey/helpers/stage_prompts.dart` — Golden Core / Nascent Soul / Ascension prompt routing for JOURNEY-07
- [x] `test/journey/foreshadowing_lifecycle_test.dart` — JOURNEY-07 lifecycle and deviation detection
- [x] `test/journey/format_cleaning_test.dart` — JOURNEY-08 format-cleaning validation
- [x] `test/journey/export_validation_test.dart` — JOURNEY-09 three-format export validation
- [x] `test/journey/statistics_accuracy_test.dart` — JOURNEY-10 stats and token audit validation
- [x] `test/journey/automated_ui_evidence_test.dart` — `[AUTO_UI]` evidence groups for JOURNEY-07/08/09/10
- [x] `test/journey/full_journey_test.dart` — deterministic 100-chapter E2E journey validation

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions | Status |
|----------|-------------|------------|-------------------|--------|
| Foreshadowing panel visual spot-check | JOURNEY-07 / D-06 | Human judgment on rendered localized labels, icons, and overdue badges | Launch MuseFlow, open story structure → foreshadowing panel, verify 神秘身世 / 师姐的秘密 / 门派禁地 / 远古法器 render with correct planted/developing/resolved labels and overdue badges | HUMAN UI pending |
| Export format visual inspection | JOURNEY-09 | Human judgment on readability in external readers | Export all 3 formats, open Markdown/TXT/JSON in respective readers and inspect formatting quality | Optional manual polish |

Manual-only items are not Nyquist blockers because each associated requirement has automated behavioral coverage; they capture visual/readability judgment beyond deterministic service assertions.

---

## Validation Audit 2026-06-08

| Metric | Count |
|--------|-------|
| Requirements audited | 4 |
| Covered | 4 |
| Partial | 0 |
| Missing | 0 |
| Gaps found | 0 |
| Resolved | 0 |
| Escalated/manual-only | 2 |

### Commands Verified

| Command | Result | Notes |
|---------|--------|-------|
| `flutter test test/journey -j 1` | ✅ pass | 45 passed, 11 skipped; skips are GLM/API-key gated tests when `GLM_API_KEY` is absent |

### Latest Evidence Excerpts

- `serial_generation_test.dart`: deterministic 100-chapter journey generated 100/100 chapters; token audit `totalCalls=100`; D-02 conflict chapter samples found expected character names.
- `foreshadowing_lifecycle_test.dart`: 4 foreshadowing threads created, transitioned, reminded, and resolved; 100-chapter deviation detection completed without exceptions.
- `format_cleaning_test.dart`: all 100 chapters cleaned with no Markdown residue, no CJK/ASCII punctuation mixing, no layout anomalies; second pass idempotent.
- `export_validation_test.dart`: Markdown has 100 headers, TXT has no Markdown residue, JSON has 100 chapters and metadata.
- `statistics_accuracy_test.dart`: 100 generated chapters; total characters 34,571; AI assist ratio 1.000; audit calls 100 with positive token totals.
- `full_journey_test.dart`: deterministic E2E completed through 100 chapters; token audit calls 101.
- `automated_ui_evidence_test.dart`: `[AUTO_UI]` evidence emitted for JOURNEY-07/08/09/10 and Phase 14 regression checks.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or completed Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all previously missing references
- [x] No watch-mode flags
- [x] Feedback latency < 120s for deterministic local suite
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** automated Nyquist coverage complete; human UI spot-check remains as non-blocking manual evidence.
