---
phase: 6
slug: 06-multi-provider-android-polish
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (unit/widget) + integration_test (integration) |
| **Config file** | none — Flutter test convention |
| **Quick run command** | `flutter test test/features/ai/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/features/ai/`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 06-01-01 | 01 | 1 | AI-02 | — | Claude preset uses HTTPS baseUrl | unit | `flutter test test/features/ai/infrastructure/preset_providers_test.dart` | ✅ extend | ⬜ pending |
| 06-01-02 | 01 | 1 | AI-02 | — | AiProviderType.claude serializes correctly | unit | `flutter test test/features/ai/domain/ai_provider_test.dart` | ✅ extend | ⬜ pending |
| 06-01-03 | 01 | 1 | AI-02 | — | OpenAIAdapter works with Claude baseUrl | unit | `flutter test test/features/ai/infrastructure/openai_adapter_test.dart` | ✅ extend | ⬜ pending |
| 06-02-01 | 02 | 1 | MODL-03 | — | AIProvider accepts nullable temperature/topP/maxTokens | unit | `flutter test test/features/ai/domain/ai_provider_test.dart` | ✅ extend | ⬜ pending |
| 06-02-02 | 02 | 1 | MODL-03 | — | copyWith handles nullable fields (null preservation) | unit | `flutter test test/features/ai/domain/ai_provider_test.dart` | ✅ extend | ⬜ pending |
| 06-02-03 | 02 | 1 | MODL-03 | — | fromJson/toJson roundtrip includes new fields | unit | `flutter test test/features/ai/domain/ai_provider_test.dart` | ✅ extend | ⬜ pending |
| 06-02-04 | 02 | 1 | MODL-03 | — | OpenAIAdapter forwards non-null params to request | unit | `flutter test test/features/ai/infrastructure/openai_adapter_test.dart` | ✅ extend | ⬜ pending |
| 06-02-05 | 02 | 1 | MODL-03 | T-06-01 | Numeric range validation rejects out-of-range values | unit | `flutter test test/features/ai/presentation/parameter_validation_test.dart` | ❌ W0 | ⬜ pending |
| 06-02-06 | 02 | 2 | MODL-04 | — | Model list fetching returns model IDs | unit | `flutter test test/features/ai/infrastructure/model_list_fetch_test.dart` | ❌ W0 | ⬜ pending |
| 06-02-07 | 02 | 2 | MODL-04 | — | Model list fetch failure returns empty list | unit | `flutter test test/features/ai/infrastructure/model_list_fetch_test.dart` | ❌ W0 | ⬜ pending |
| 06-03-01 | 03 | 2 | D-10 | — | Provider settings renders on narrow screens | widget | `flutter test test/features/ai/presentation/provider_management_responsive_test.dart` | ❌ W0 | ⬜ pending |
| 06-03-02 | 03 | 2 | D-11 | — | Core flow integration test (launch, navigate, settings) | integration | `flutter test integration_test/app_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/features/ai/presentation/parameter_validation_test.dart` — covers MODL-03 parameter input validation
- [ ] `test/features/ai/infrastructure/model_list_fetch_test.dart` — covers MODL-04 model list fetching
- [ ] `test/features/ai/presentation/provider_management_responsive_test.dart` — covers D-10 responsive layout
- [ ] `integration_test/app_test.dart` — covers D-11 core flow integration
- [ ] `integration_test/test_driver/integration_test.dart` — test driver for integration tests

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Android touch interaction on provider form | D-10 | Requires physical device or emulator with touch input | Run app on Android device, verify form fields accept touch input without overflow |
| Claude API streaming with real credentials | AI-02 | Requires valid Claude API key | Configure Claude preset with real key, verify streaming response in editor |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
