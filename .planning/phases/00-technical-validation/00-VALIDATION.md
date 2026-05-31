---
phase: 0
slug: technical-validation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-31
---

# Phase 0 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter test (built-in) + flutter_test_robots (super_editor companion) |
| **Config file** | None — Flutter test conventions |
| **Quick run command** | `flutter test` |
| **Full suite command** | `flutter test --coverage` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test`
- **After every plan wave:** Run `flutter test --coverage`
- **Before `/gsd:verify-work`:** Full suite must be green + manual IME testing pass + benchmark results documented
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 00-01-01 | 01 | 1 | EDIT-04 (spike) | — | N/A | Performance benchmark | `flutter test test/benchmark/` | ❌ W0 | ⬜ pending |
| 00-01-02 | 01 | 1 | EDIT-01 (spike) | — | N/A | API extensibility eval | Manual + doc output | ❌ W0 | ⬜ pending |
| 00-02-01 | 02 | 1 | TECH-02 (spike) | — | N/A | Widget test | `flutter test test/ime/` | ❌ W0 | ⬜ pending |
| 00-02-02 | 02 | 1 | TECH-02 (spike) | — | N/A | Manual (Sogou/Wubi/MSPinyin) | Manual test protocol | ❌ W0 | ⬜ pending |
| 00-03-01 | 03 | 1 | (spike) | — | N/A | Build verification | `flutter pub get` | N/A | ⬜ pending |
| 00-03-02 | 03 | 2 | AI-03 (spike) | T-00-01 | Validate SSE chunk structure before document insertion | Integration test | `flutter test test/streaming/` | ❌ W0 | ⬜ pending |
| 00-03-03 | 03 | 2 | (spike) | T-00-02 | API key via flutter_secure_storage only | Build verification | `flutter test` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/benchmark/` — large document performance benchmark stubs
- [ ] `test/ime/` — automated IME composition test stubs
- [ ] `test/streaming/` — SSE streaming integration test stubs
- [ ] Flutter SDK installed — already present (3.44.0 stable / Dart 3.5.4)
- [ ] `flutter_test_robots` — comes with super_editor dependency

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Sogou Pinyin IME composition in editor | TECH-02 | Requires physical keyboard + installed IME | 1. Open test app 2. Switch to Sogou Pinyin 3. Type pinyin syllables 4. Verify composing underline + candidate window + committed text |
| Wubi IME composition in editor | TECH-02 | Requires physical keyboard + installed IME | 1. Open test app 2. Switch to Wubi 3. Type stroke codes 4. Verify composing + committed text |
| Microsoft Pinyin IME composition in editor | TECH-02 | Requires physical keyboard + installed IME | 1. Open test app 2. Switch to Microsoft Pinyin 3. Type pinyin 4. Verify composing + committed text |
| Editor scroll smoothness at 100K+ chars | EDIT-04 | Subjective frame quality + DevTools profiling | 1. Load 100K char Chinese document 2. Scroll continuously 3. Observe no visible jank 4. Check Flutter DevTools performance overlay < 16ms |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
