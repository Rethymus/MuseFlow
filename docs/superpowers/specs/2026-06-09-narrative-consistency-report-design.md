# Narrative Consistency Report Design

Date: 2026-06-09

## Context

MuseFlow already verifies the 100-chapter journey and provides a knowledge-base consistency report. Current evidence shows the remaining functional risk is not basic generation, export, or Web build support. The weak point is report usefulness for real authors: the existing consistency analysis mostly counts whether entity names and keywords appear in chapters.

External research and current product positioning point in the same direction. AI-assisted fiction tools are most useful when they preserve author agency, make long-form memory visible, explain consistency risks, and reduce generic AI style. MuseFlow should therefore avoid claiming that it can prove whether text is AI-written. It should instead help the author find chapters that need human revision and explain why.

## Goal

Upgrade the consistency report from a presence counter into a creator-facing diagnostic report.

The report should answer:

- Which chapters are most likely to feel thin, generic, or detached from the manuscript's knowledge base?
- Which risk signals caused that judgment?
- What should the author review without letting the tool rewrite the story for them?

## Scope

This change is limited to the reports feature:

- Extend `ConsistencyReport` with narrative quality signals.
- Add deterministic local heuristics in `ConsistencyAnalysisService`.
- Show the signals on `ConsistencyReportPage`.
- Export the signals in Markdown.
- Cover the service, domain, page, and export paths with focused tests.

No new AI calls are introduced. The feature stays local-first, lightweight, and deterministic.

## Data Model

Add two domain types:

- `NarrativeQualitySignal`
  - `chapterIndex`
  - `category`
  - `title`
  - `evidence`
  - `suggestion`
  - `severity`
- `NarrativeQualitySnapshot`
  - `immersionScore`
  - `characterAnchoringScore`
  - `antiAiScentScore`
  - `signals`

Add `narrativeQuality` to `ConsistencyReport`.

Scores use `0.0..1.0`, where higher means healthier. Signals are author-review prompts, not automatic edits.

## Heuristics

The service scans sorted chapters and knowledge-base entities:

- Immersion risk: low density of sensory, action, and scene detail terms.
- Character anchoring risk: character appears but lacks nearby behavior, emotion, relation, or voice clues.
- AI-scent risk: common generic transition or summary phrases appear.
- Setting drift risk: setting name appears without supporting rules, factions, geography, or technical terms for several chapters.

The goal is explainability, not perfect literary judgment. The UI must frame results as "复查建议" rather than truth.

## UI

On the consistency report page:

- Keep the existing overall cards and drift chart.
- Add a "叙事质量复查" section with three score cards.
- List the highest-priority signals with chapter number, severity, evidence, and suggestion.
- Keep empty states concise when there are no signals.

## Export

`ReportExportService.buildConsistencyMarkdown()` adds a "叙事质量复查" section with:

- Three score rows.
- Signal list grouped as review items.
- Evidence and author-facing suggestions.

## Testing

Focused verification:

- Domain tests for new snapshot and signal models.
- Service tests for immersion, character anchoring, AI-scent, and setting drift signals.
- Export test for the new Markdown section.
- Page test for the new section and signal display.

Regression commands:

- `dart format --set-exit-if-changed` on touched Dart files.
- `flutter test test/features/reports`.
- `flutter analyze lib/features/reports`.

## Non-Goals

- No AI detector.
- No automatic rewriting.
- No new storage schema or Hive migration.
- No broad planning metadata cleanup in this implementation slice.
