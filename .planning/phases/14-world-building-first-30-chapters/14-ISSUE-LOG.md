# Phase 14 Issue Log: World-Building First 30 Chapters

**Phase:** 14-world-building-first-30-chapters  
**Created:** YYYY-MM-DD  
**Updated:** YYYY-MM-DD  

This log captures execution findings for JOURNEY-05/JOURNEY-06: bugs, UX friction, missing needs, GLM compatibility findings, and manual spot-check evidence.

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
| | | | | | | | | |

## RESEARCH.md Open Questions -- Execution Findings

### OQ-01: GLM API Streaming Compatibility

- **Status:** unresolved
- **Findings:** Pending execution of `flutter test test/journey/serial_generation_test.dart -j 1 --plain-name "should pass GLM streaming smoke test" --timeout 120s` with `GLM_API_KEY`.
- **Impact:** If blocked, 30-chapter serial generation cannot validate real provider behavior.
- **Evidence:** Add test output excerpt here. Do not paste API keys.

### OQ-02: Provider Graph Depth with Real API Credentials

- **Status:** unresolved
- **Findings:** Pending execution of serial and full-journey tests. Expected overrides are `openaiAdapterProvider`, `activeProviderProvider`, and `activeApiKeyProvider` from `createJourneyContainer()`.
- **Impact:** Provider resolution failure blocks PromptPipeline, OpeningGeneratorService, DeviationDetectionService, and token audit verification.
- **Evidence:** Add provider resolution notes and any additional overrides required.

### OQ-03: Manual Spot-Check Scope Definition

- **Status:** defined
- **Findings:** Automated verifications are separated from manual-only UI checks below. Manual checks require actual Flutter app interaction.
- **Impact:** Phase 16 pain-point reporting can distinguish executable evidence from subjective UI/UX evidence.
- **Evidence:** Add screenshots, paths, or pasted observations for each manual-only subsection.

## Manual Spot-Check Checklist (JOURNEY-06)

### Automated Verifications

Executed by test scripts and checkable via test output:

- [ ] Character name presence in generated content (serial_generation_test group 4)
- [ ] Deviation detection warnings logged (serial_generation_test group 5)
- [ ] Token audit accuracy: totalCalls >= 30 (serial_generation_test group 6)
- [ ] 30 chapters each 300-500 characters (serial_generation_test group 3, per D-11)
- [ ] Opening guide 3 non-identical variants (opening_guide_test group 3)
- [ ] Fragment synthesis produces non-empty output > 50 chars (fragment_synthesis_test group 3)

### Manual-Only Verifications

Require UI interaction with a running Flutter app and must include evidence paths or pasted observations.

#### Editor Floating Toolbar

- [ ] Select text in any generated chapter -> FloatingToolbar appears below selection
- [ ] "语气改写" operation produces rewritten text via streaming
- [ ] "文段润色" operation produces polished text
- [ ] "自由输入" operation accepts custom instruction and applies it
- [ ] Output does not have obvious AI-scent patterns (no "值得注意的是", "总而言之")
- [ ] Toolbar flips above selection when in bottom 40% of viewport

**Evidence:**

#### Knowledge Injection + Skill Guardian

- [ ] Generated chapters reference character names from knowledge base
- [ ] Character personality/backstory consistent across chapters
- [ ] No Skill rule violations in generated content (no modern tech, no cross-realm abilities)
- [ ] DeviationWarningWidget displays when applicable

**Evidence:**

#### Opening Guide 3 Styles

- [ ] Scene-style (场景切入) opens with environmental/atmospheric description
- [ ] Character-style (人物切入) opens with protagonist action/dialogue
- [ ] Suspense-style (悬念切入) opens with mystery/tension hook
- [ ] All 3 styles produce coherent xianxia prose

**Evidence:**

#### Chapter Operations

- [ ] Reorder chapters via drag-and-drop in sidebar
- [ ] Split chapter at cursor position
- [ ] Merge adjacent chapters
- [ ] Copy chapter creates "(副本)" duplicate
- [ ] Delete chapter with confirmation dialog
- [ ] Sidebar shows correct sort order after operations

**Evidence:**

## Severity Classification Guide

| Severity | Definition | Examples |
|----------|------------|----------|
| 高 | Data loss, crash, AI call failure, incorrect content generation | API call fails after smoke test, chapter save drops content, generated chapter violates required 300-500 bounds |
| 中 | Noticeable UX friction, missing expected feedback, suboptimal layout | Toolbar appears in awkward position, operation lacks loading feedback, chapter reorder is confusing |
| 低 | Minor visual inconsistency, nice-to-have, edge case polish | Label alignment issue, copy text wording, rare edge case notes |

## Evidence Hygiene

- Never paste `GLM_API_KEY` or any other secret.
- Prefer command output excerpts that show status markers and counts, not full generated chapter prose.
- For manual UI checks, record concise observations plus screenshot/file paths where available.
