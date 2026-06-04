---
phase: 6
slug: 06-multi-provider-android-polish
status: verified
nyquist_compliant: true
wave_0_complete: true
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
| **Full suite command** | `flutter test test/features/ai/` |
| **Estimated runtime** | ~8 seconds for AI suite |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/features/ai/`
- **After every plan wave:** Run `flutter test test/features/ai/`
- **Before `/gsd:verify-work`:** Phase 6 core validation command and `flutter test test/features/ai/` must be green
- **Max feedback latency:** ~8 seconds for AI suite

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 06-01-01 | 01 | 1 | AI-02 | — | Claude preset uses HTTPS baseUrl | unit | `flutter test test/features/ai/infrastructure/preset_providers_test.dart` | yes | green |
| 06-01-02 | 01 | 1 | AI-02 | — | AiProviderType.claude serializes correctly | unit | `flutter test test/features/ai/domain/ai_provider_test.dart` | yes | green |
| 06-01-03 | 01 | 1 | AI-02 | — | OpenAIAdapter accepts Claude/OpenAI-compatible HTTPS baseUrl and forwards request fields | unit | `flutter test test/features/ai/infrastructure/openai_adapter_test.dart` | yes | green |
| 06-02-01 | 02 | 1 | MODL-03 | — | AIProvider accepts nullable temperature/topP/maxTokens | unit | `flutter test test/features/ai/domain/ai_provider_test.dart` | yes | green |
| 06-02-02 | 02 | 1 | MODL-03 | — | copyWith handles nullable fields including explicit null reset | unit | `flutter test test/features/ai/domain/ai_provider_test.dart` | yes | green |
| 06-02-03 | 02 | 1 | MODL-03 | — | fromJson/toJson roundtrip includes new fields | unit | `flutter test test/features/ai/domain/ai_provider_test.dart` | yes | green |
| 06-02-04 | 02 | 1 | MODL-03 | — | OpenAIAdapter forwards non-null params to request | unit | `flutter test test/features/ai/infrastructure/openai_adapter_test.dart` | yes | green |
| 06-02-05 | 02 | 1 | MODL-03 | T-06-01 | Numeric range validation rejects out-of-range values | unit | `flutter test test/features/ai/presentation/parameter_validation_test.dart` | yes | green |
| 06-02-06 | 02 | 2 | MODL-04 | — | Model list fetching exposes method and returns list-shaped fallback without live network dependency | unit | `flutter test test/features/ai/infrastructure/model_list_fetch_test.dart` | yes | green |
| 06-02-07 | 02 | 2 | MODL-04 | — | Model list fetch failure returns empty list silently | unit | `flutter test test/features/ai/infrastructure/model_list_fetch_test.dart` | yes | green |
| 06-03-01 | 03 | 2 | D-10 | — | Provider settings renders at and below 600px without desktop/mobile layout mismatch | widget | `flutter test test/features/ai/presentation/provider_management_responsive_test.dart` | yes | green |
| 06-03-02 | 03 | 2 | D-11 | — | Core app-flow integration test scaffold exists; local automated gate replaced by deterministic widget/unit tests per D-13/D-14 | manual/integration | `flutter test integration_test/app_test.dart` on supported device | yes | manual |

Status: green · red · flaky · manual

---

## Wave 0 Requirements

- [x] `test/features/ai/presentation/parameter_validation_test.dart` — covers MODL-03 parameter input validation
- [x] `test/features/ai/infrastructure/model_list_fetch_test.dart` — covers MODL-04 model list fallback contract without live network/API key dependency
- [x] `test/features/ai/presentation/provider_management_responsive_test.dart` — covers D-10 responsive layout at and below the 600px breakpoint
- [x] `integration_test/app_test.dart` — integration scaffold exists for supported device/manual CI execution
- [x] `integration_test/test_driver/integration_test.dart` — test driver for integration tests

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Android touch interaction on provider form | D-10 | Requires physical device or emulator with touch input | Run app on Android device, verify form fields accept touch input without overflow |
| Claude API streaming with real credentials | AI-02 | Requires valid Claude API key | Configure Claude preset with real key, verify streaming response in editor |
| Full integration_test execution | D-11 | Current Linux/WSL environment has no supported target device for this Flutter project | On Windows desktop or Android emulator/device, run `flutter test integration_test/app_test.dart` and confirm launch/settings/provider navigation smoke tests pass |

Per `06-CONTEXT.md` D-13 through D-16, these manual checks do not block the local automated Phase 6 validation gate.

---

## Validation Audit 2026-06-04

| Metric | Count |
|--------|-------|
| Phase requirements | 3 |
| Automated coverage groups | 6 |
| Gaps found | 5 |
| Resolved with tests | 5 |
| Escalated to manual UAT | 2 |

Automated gate commands run:

- `flutter test test/features/ai/domain/ai_provider_test.dart test/features/ai/infrastructure/preset_providers_test.dart test/features/ai/infrastructure/openai_adapter_test.dart test/features/ai/presentation/parameter_validation_test.dart test/features/ai/infrastructure/model_list_fetch_test.dart test/features/ai/presentation/provider_management_responsive_test.dart` — passed, 78 tests
- `flutter test test/features/ai/` — passed, 175 tests

Validation changes:

- `test/features/ai/infrastructure/model_list_fetch_test.dart` no longer depends on `httpbin.org` or any live network/API key. It verifies silent fallback using invalid/local endpoints per D-13 and D-15.
- `test/features/ai/presentation/provider_management_responsive_test.dart` now compiles and passes in the current tree, covering 600px desktop breakpoint behavior and below-600px mobile list/form switching.

Residual risks:

- Real Claude streaming and physical Android touch behavior remain manual UAT because they require credentials, network, or device/emulator support.
- `integration_test/app_test.dart` is present but cannot be executed in this Linux/WSL environment without a supported Flutter target device.

---

## Validation Sign-Off

- [x] All tasks have automated verification or documented manual UAT coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 10s for scoped AI suite
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-04
