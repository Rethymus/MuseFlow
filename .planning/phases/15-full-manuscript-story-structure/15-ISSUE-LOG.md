# Phase 15 Issue Log: Full Manuscript Story Structure

**Phase:** 15-full-manuscript-story-structure  
**Created:** 2026-06-08  
**Updated:** 2026-06-08

This log captures execution findings for JOURNEY-07/JOURNEY-08/JOURNEY-09/JOURNEY-10: bugs, UX friction, missing needs, 100-chapter story-structure findings, automated evidence, final human-review-only notes, and platform UI observations.

## Summary Statistics

| Metric | Count |
|--------|-------|
| Total issues | 0 |
| High severity | 0 |
| Medium severity | 0 |
| Low severity | 0 |
| 功能缺陷 | 0 |
| 体验摩擦 | 0 |
| 缺失需求 | 0 |

## Issues

| ID | Category (功能缺陷/体验摩擦/缺失需求) | Severity (高/中/低) | Requirement | Title | Reproduction Steps | Expected Behavior | Actual Behavior | Evidence |
|----|--------------------------------------|--------------------|-------------|-------|--------------------|-------------------|-----------------|----------|

Issue IDs follow `P15-XX-YY-ZZ`, where:

| Segment | Meaning | Examples |
|---------|---------|----------|
| `P15` | Phase 15 | `P15` |
| `XX` | Plan number | `06`, `07`, `08` |
| `YY` | Category code | `FUNC`, `UX`, `NEED` |
| `ZZ` | Sequential number | `01`, `02`, `03` |

Requirement values should use `JOURNEY-07`, `JOURNEY-08`, `JOURNEY-09`, or `JOURNEY-10`.

## Verification Checklist

### Automated Verifications

- [ ] JOURNEY-07 foreshadowing lifecycle validation completed
- [ ] JOURNEY-08 format cleaning validation completed
- [ ] JOURNEY-09 three-format export validation completed
- [ ] JOURNEY-10 writing statistics and token audit validation completed
- [ ] Full 100-chapter E2E journey validation completed
- [ ] GLM credentialed paths either passed or skipped with documented reason

### Manual Platform Observations

- [ ] Story structure page reviewed for 100-chapter scale readability
- [ ] Foreshadowing entries display correct status icons and chapter numbers
- [ ] Format clean preview dialog remains usable with full manuscript content
- [ ] Export dialog shows correct 100-chapter count and local-save messaging
- [ ] Writing statistics page displays totals and token charts clearly
- [ ] Native Windows/Android checks recorded if performed

## Severity Classification Guide

| Severity | Definition | Examples |
|----------|------------|----------|
| 高 | Data loss, crash, AI call failure, incorrect content generation, export corruption | 100-chapter generation stops after successful smoke test, chapter save drops content, generated chapter violates required 300-500 bounds, JSON export is not parseable |
| 中 | Noticeable UX friction, missing expected feedback, suboptimal layout, statistics inaccuracy | Toolbar appears in awkward position, operation lacks loading feedback, chapter reorder is confusing, writing stats total does not match generated content |
| 低 | Minor visual inconsistency, nice-to-have, edge case polish | Label alignment issue, copy text wording, rare edge case notes, non-blocking chart readability issue |

## Evidence Hygiene

- Never paste `GLM_API_KEY` or any other secret.
- Prefer command output excerpts that show status markers and counts, not full generated chapter prose.
- For manual UI checks, record concise observations plus screenshot/file paths where available.
- Redact bearer tokens, authorization headers, local personal paths, and provider credentials from logs.
- Use issue IDs in commit messages or test notes when a finding is fixed or deferred.

## RESEARCH.md Open Questions -- Execution Findings

Add findings here when Phase 15 execution answers research questions or exposes new constraints.

### OQ-01: 100-Chapter Sustained Generation Reliability

- **Status:** pending
- **Findings:** Not yet recorded.
- **Impact:** TBD
- **Evidence:** TBD

### OQ-02: Full-Manuscript Story Structure Integrity

- **Status:** pending
- **Findings:** Not yet recorded.
- **Impact:** TBD
- **Evidence:** TBD

### OQ-03: 100-Chapter Export and Statistics Accuracy

- **Status:** pending
- **Findings:** Not yet recorded.
- **Impact:** TBD
- **Evidence:** TBD

## Deferred Verification

Use this section for checks that cannot be completed in the current executor environment.

| ID | Requirement | Reason | Required Environment | Resume Signal |
|----|-------------|--------|----------------------|---------------|
| _none_ | _none_ | _none_ | _none_ | _none_ |
