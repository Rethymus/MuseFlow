---
phase: 15
slug: full-manuscript-story-structure
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-08
---

# Phase 15 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Test fixtures -> production services | Static journey story outline and stage prompts are consumed by journey tests that invoke production services. | Test-only prose and prompt strings; no secrets |
| E2E tests -> GLM API | Credentialed serial/full journey paths may call the real GLM API when `GLM_API_KEY` is present. | API key from environment; prompt/response test content |
| Journey tests -> Hive temp storage | Tests create manuscripts, chapters, foreshadowing entries, stats, and token audit records in isolated temp Hive directories. | Local test data; no user manuscripts |
| Issue log -> execution artifacts | Markdown issue log records findings and command output excerpts from Phase 15 validation. | Test evidence; potentially sensitive output if not redacted |
| Format/export tests -> pure services | FormatCleaner and ExportService are invoked locally; export tests use no-op file writer. | Deterministic test content only |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-15-01 | Tampering | `story_outline.dart` test data | accept | Static const test-only data; immutable; no user input or secret patterns found. | closed |
| T-15-02 | Information Disclosure | `stage_prompts.dart` prompt content | accept | Static const test-only prompt strings; no API keys or secrets found. | closed |
| T-15-03 | Information Disclosure | GLM API key in serial generation output | mitigate | `_safeExceptionDiagnostic()` sanitizes authorization, bearer, and `api_key` values; serial generation error paths call it before logging. | closed |
| T-15-04 | Denial of Service | Hive temp directory leak in serial generation tests | mitigate | `createJourneyContainer()` and `cleanupJourneyContainer()` are used with teardown cleanup; generation failures rethrow after sanitized diagnostics. | closed |
| T-15-05 | Tampering | Hive stale data in foreshadowing lifecycle tests | mitigate | Per-test journey container and teardown cleanup isolate foreshadowing Hive data. | closed |
| T-15-06 | Tampering | Hive stale data in format/export tests | mitigate | Format cleaning is pure Dart; export validation uses no-op file writer; container cleanup is present where Hive-backed helpers are used. | closed |
| T-15-07 | Tampering | Hive stale data in statistics/token audit tests | mitigate | Per-container cleanup plus explicit `auditService.flush()` / stats flush before reading snapshots. | closed |
| T-15-08 | Information Disclosure | GLM API key in full journey output | mitigate | `_safeExceptionDiagnostic()` sanitizes authorization, bearer, and `api_key` values; full journey chapter error path uses sanitized diagnostics. | closed |
| T-15-09 | Information Disclosure | Phase 15 issue log may contain sensitive test output | mitigate | `15-ISSUE-LOG.md` evidence hygiene forbids `GLM_API_KEY` or any secret and requires redaction. | closed |
| T-15-10 | Denial of Service | Hive temp directory leak in full E2E failure | mitigate | Full journey setup/teardown uses per-container temp directories and `cleanupJourneyContainer()`; chapter failures rethrow after safe diagnostics. | closed |
| T-15-11 | Tampering | Hive stale data in automated UI evidence test | mitigate | Existing automated evidence test creates an isolated journey container and cleans it in teardown. | closed |
| T-15-SC | Tampering | npm/pip/cargo installs | n/a | Security audit found no package install commands or related manifest changes in Phase 15 implementation/artifacts. | closed |

*Status: open · closed*  
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Verification Evidence

| Threat ID | Evidence |
|-----------|----------|
| T-15-01 | `test/journey/helpers/story_outline.dart` uses static const test-only story data; no secret patterns found. |
| T-15-02 | `test/journey/helpers/stage_prompts.dart` uses static const prompt content; no secret patterns found. |
| T-15-03 | `test/journey/serial_generation_test.dart` contains `_safeExceptionDiagnostic()` and uses it on serial generation error paths. |
| T-15-04 | `test/journey/serial_generation_test.dart` uses journey container setup/cleanup and rethrows failures after cleanup-safe diagnostics. |
| T-15-05 | `test/journey/foreshadowing_lifecycle_test.dart` uses per-test journey containers and cleanup. |
| T-15-06 | `test/journey/format_cleaning_test.dart` and `test/journey/export_validation_test.dart` avoid external writes; export service uses no-op writer in validation. |
| T-15-07 | `test/journey/statistics_accuracy_test.dart` cleans containers and flushes audit/stats before snapshot reads. |
| T-15-08 | `test/journey/full_journey_test.dart` contains `_safeExceptionDiagnostic()` and uses it on full journey chapter error paths. |
| T-15-09 | `.planning/phases/15-full-manuscript-story-structure/15-ISSUE-LOG.md` contains evidence hygiene forbidding secrets and requiring redaction. |
| T-15-10 | `test/journey/full_journey_test.dart` uses per-container setup/teardown cleanup and safe error handling. |
| T-15-11 | `test/journey/automated_ui_evidence_test.dart` uses isolated journey container setup and teardown cleanup. |
| T-15-SC | No npm/pip/cargo install commands or package manifest changes were identified in Phase 15 implementation/artifacts. |

---

## Summary Threat Flags

Phase 15 summaries reported no unresolved security flags:

- `15-03-SUMMARY.md`: Threat Flags — None
- `15-04-SUMMARY.md`: Threat Flags — None
- `15-06-SUMMARY.md`: Threat Flags — None
- Other Phase 15 summaries contain no open security blockers.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-15-01 | T-15-01 | Static immutable test fixture data is test-only, contains no secrets, and is required for deterministic 100-chapter validation. | GSD security audit | 2026-06-08 |
| AR-15-02 | T-15-02 | Static immutable prompt fixture content is test-only, contains no secrets, and does not cross a user-facing boundary. | GSD security audit | 2026-06-08 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-08 | 12 | 12 | 0 | gsd-security-auditor |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-08
