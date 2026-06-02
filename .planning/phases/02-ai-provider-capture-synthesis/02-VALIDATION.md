---
phase: 2
slug: ai-provider-capture-synthesis
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-02
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (built-in) |
| **Config file** | `pubspec.yaml` (flutter_test dependency) |
| **Quick run command** | `flutter test test/features/ai/ test/features/capture/ --no-pub` |
| **Full suite command** | `flutter test --no-pub` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/features/ai/ test/features/capture/ --no-pub`
- **After every plan wave:** Run `flutter test --no-pub`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | AI-01 | — | N/A | unit | `flutter test test/features/ai/` | ❌ W0 | ⬜ pending |
| 02-01-02 | 01 | 1 | AI-03 | — | N/A | unit | `flutter test test/features/ai/` | ❌ W0 | ⬜ pending |
| 02-02-01 | 02 | 1 | MODL-01, MODL-02 | T-2-01 | API keys encrypted via SecureStorage | unit | `flutter test test/features/settings/` | ❌ W0 | ⬜ pending |
| 02-03-01 | 03 | 2 | AI-04, AI-05, AI-06 | — | N/A | unit | `flutter test test/features/ai/` | ❌ W0 | ⬜ pending |
| 02-04-01 | 04 | 2 | CAPT-03, CAPT-04, AI-07, AI-08 | — | N/A | integration | `flutter test test/features/capture/ test/features/ai/` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/features/ai/domain/` — AI adapter interface tests, provider entity tests
- [ ] `test/features/ai/infrastructure/` — OpenAI-compatible adapter tests (mock HTTP)
- [ ] `test/features/ai/application/` — PromptPipeline tests, anti-AI-scent tests
- [ ] `test/features/settings/presentation/` — Provider management UI widget tests
- [ ] `test/features/capture/presentation/` — Synthesis panel widget tests
- [ ] `test/helpers/mocks.dart` — Shared mock providers for AI services

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Streaming SSE displays typewriter effect in synthesis panel | AI-03 | Requires real network SSE stream + visual verification | Configure a real provider, select fragments, trigger synthesis, observe streaming text |
| Anti-AI-scent reduces AI clichés in Chinese prose | AI-05, AI-06 | Requires LLM judgment of output quality | Generate 5+ synthesis results, check for banned phrases, verify replacements |
| Chinese IME works in synthesis panel edit area | CAPT-04 | Platform-specific IME behavior | Type with Sogou/Wubi in synthesis panel, verify composition works |
| Provider "测试连接" gives immediate feedback | D-03 | Requires real API call with valid/invalid keys | Add provider with valid key → success toast; invalid key → error message |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
