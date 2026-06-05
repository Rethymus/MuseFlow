---
phase: 08-onboarding-guide
plan: 05
subsystem: onboarding, editor, ai-ui
tags: [opening-generator, wizard, bottom-sheet, editor-insertion, provenance]

# Dependency graph
requires:
  - phase: 08-onboarding-guide plan 04
    provides: OpeningVariant model and OpeningGeneratorService
  - phase: 08-onboarding-guide plans 01-03
    provides: onboarding wizard shell, genre/world/character steps
  - phase: 03-editor-ai-toolbar
    provides: super_editor document mutation and AI provenance patterns
provides:
  - OpeningVariantCard reusable result card
  - OpeningStepPage wizard step 4 using OpeningGeneratorService
  - OpeningGeneratorSheet editor toolbar entry point
  - openingGeneratorServiceProvider registration
  - Shared opening text insertion helper with AI provenance
affects: [08 phase completion]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "ConsumerStatefulWidget UI for async AI generation"
    - "Shared super_editor insertion helper with aiProvenanceAttribution"
    - "Modal bottom sheet editor action entry point"

key-files:
  created:
    - lib/features/onboarding/presentation/opening_variant_card.dart
    - lib/features/onboarding/presentation/wizard_steps/opening_step_page.dart
    - lib/features/onboarding/presentation/opening_generator_sheet.dart
    - lib/features/onboarding/presentation/opening_text_insertion.dart
    - test/features/onboarding/presentation/opening_variant_card_test.dart
    - test/features/onboarding/application/opening_insertion_test.dart
  modified:
    - lib/core/presentation/providers.dart
    - lib/features/editor/presentation/editor_toolbar.dart
    - lib/features/onboarding/presentation/onboarding_wizard_page.dart

key-decisions:
  - "Aligned implementation with current super_editor stack, not the stale appflowy_editor wording in the plan."
  - "Extracted insertion into opening_text_insertion.dart to avoid duplicating editor mutation code across wizard and sheet."
  - "Fallback insertion appends to the first text node when no active selection exists, preserving onboarding completion value."

requirements-completed: [ONBD-04, ONBD-05]

# Metrics
duration: current session
completed: 2026-06-04
---

# Phase 8 Plan 05: Opening Generator UI Integration Summary

Completed the AI opening generator UI and editor integration.

## Accomplishments

- Added `OpeningVariantCard` with style badge, preview text, selection visual state, and select button.
- Added wizard step 4 via `OpeningStepPage`, including story concept input, loading state, retryable error state, and variant selection.
- Added `OpeningGeneratorSheet` as the editor toolbar bottom-sheet entry point.
- Registered `openingGeneratorServiceProvider` in shared providers using the existing active AI provider/API key pattern.
- Added `Icons.auto_stories` toolbar button with tooltip `开篇生成`.
- Wired selected wizard opening insertion before onboarding completion navigation.
- Added `insertOpeningText` helper for cursor insertion, selection replacement, no-selection fallback append, and AI provenance attribution.
- Added focused widget/unit tests for opening card display/interaction and editor insertion behavior.

## Verification

- `flutter test test/features/onboarding/` — passed, 89 tests.
- `flutter test test/features/editor/formatting_test.dart test/features/onboarding/application/opening_insertion_test.dart test/features/onboarding/presentation/opening_variant_card_test.dart` — passed, 18 tests.
- `flutter analyze` — ran; no new compile errors, but existing unrelated warnings/infos remain across the repo.

## Notes

- The original plan mentions `InsertNodeRequest`, but this repo's existing `super_editor` usage did not contain a proven append-node pattern. The implemented fallback appends to the first text node instead, which is safer and covered by tests.
- AI generation still requires an active configured provider and API key at runtime.

---
*Phase: 08-onboarding-guide*
*Completed: 2026-06-04*
