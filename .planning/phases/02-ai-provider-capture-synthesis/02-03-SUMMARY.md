---
phase: 02-ai-provider-capture-synthesis
plan: 03
subsystem: ai, ui
tags: [riverpod, streaming, super_editor, go_router, hive, synthesis-panel, anti-ai-scent]

# Dependency graph
requires:
  - phase: 02-01
    provides: "AIProvider entity, ProviderService, provider management UI, settings infrastructure"
  - phase: 02-02
    provides: "OpenAIAdapter streaming, PromptPipeline middleware, AntiAIScentProcessor, TokenBudgetCalculator"
  - phase: 01-03
    provides: "CaptureNotifier, selectedFragmentsProvider, CapturePage UI"
  - phase: 01-02
    provides: "EditorPage, createDefaultEditor, super_editor integration"
provides:
  - "SynthesisNotifier state machine for synthesis flow"
  - "SynthesisPanel slide-out UI with streaming display and editing"
  - "BannedPhraseSettings page with persistence via SettingsRepository"
  - "Editor exposure via EditorHolderNotifier for cross-widget text insertion"
  - "Capture-to-synthesis-to-editor end-to-end loop"
affects: [03-editor-ai-toolbar, 05-story-structure]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "StateProvider pattern for exposing widget-local state (Editor) across Riverpod"
    - "Stack layout with positioned overlay for panel UI"
    - "AsyncNotifier with stream subscription for SSE token accumulation"
    - "BannedPhrasesNotifier seeded from AntiAIScentProcessor.synonymKeys"

key-files:
  created:
    - lib/features/ai/presentation/synthesis_notifier.dart
    - lib/features/ai/presentation/synthesis_panel.dart
    - lib/features/ai/presentation/banned_phrase_settings.dart
    - test/features/ai/presentation/synthesis_notifier_test.dart
  modified:
    - lib/features/editor/presentation/editor_page.dart
    - lib/features/capture/presentation/capture_page.dart
    - lib/features/settings/presentation/settings_page.dart
    - lib/core/presentation/providers.dart
    - lib/shared/constants/app_constants.dart
    - lib/app.dart
    - lib/features/ai/application/anti_ai_scent_processor.dart
    - lib/core/infrastructure/settings_repository.dart

key-decisions:
  - "D-18: Editor exposed via EditorHolderNotifier (Notifier<Editor?>) set in initState, cleared in dispose -- works because StatefulShellRoute.indexedStack keeps editor mounted"
  - "D-19: activeProviderProvider and activeApiKeyProvider wrap async FutureProviders for synchronous reads in SynthesisNotifier"
  - "D-20: BannedPhrasesNotifier seeds from AntiAIScentProcessor.synonymKeys on first access, persists via SettingsRepository"

patterns-established:
  - "SynthesisPanel as Stack overlay: CapturePage base layer + positioned panel on right"
  - "Inline error messages in panel (not SnackBar/dialog) per D-14"
  - "Blinking cursor animation for streaming typewriter effect"
  - "updateText method for user edits flowing back into notifier state"

requirements-completed: [CAPT-03, CAPT-04, AI-03, AI-06, AI-08]

# Metrics
duration: 13min
completed: 2026-06-02
---

# Phase 2 Plan 3: Synthesis UX Summary

**End-to-end fragment-to-paragraph synthesis with streaming panel, anti-AI-scent post-processing, editable output, and editor insertion**

## Performance

- **Duration:** 13 min
- **Started:** 2026-06-02T07:40:26Z
- **Completed:** 2026-06-02T07:54:07Z
- **Tasks:** 2
- **Files modified:** 12 (4 created, 8 modified)

## Accomplishments
- Full capture-to-synthesis-to-editor loop works end-to-end: select fragments, stream AI output, edit, insert at cursor
- SynthesisPanel slides out from right side of capture page with typewriter streaming effect, inline errors, and regeneration
- Banned phrase settings page with add/remove, seeded from anti-AI-scent built-in list, persisted via SettingsRepository
- 21 tests covering all SynthesisNotifier state transitions, streaming, errors, and insertion

## Task Commits

Each task was committed atomically:

1. **Task 1: SynthesisNotifier state management and streaming logic** - `e27f37f` (feat)
2. **Task 2: SynthesisPanel UI, capture page integration, banned phrase settings** - `d9d17b6` (feat)

## Files Created/Modified
- `lib/features/ai/presentation/synthesis_notifier.dart` - SynthesisState, SynthesisNotifier, activeProviderProvider, activeApiKeyProvider, synthesisProvider
- `lib/features/ai/presentation/synthesis_panel.dart` - Slide-out panel with streaming display, editing, regeneration, error handling
- `lib/features/ai/presentation/banned_phrase_settings.dart` - BannedPhrasesNotifier, BannedPhraseSettingsPage with add/remove
- `test/features/ai/presentation/synthesis_notifier_test.dart` - 21 tests covering state, streaming, errors, regeneration, insertion
- `lib/features/editor/presentation/editor_page.dart` - EditorHolderNotifier exposing Editor via provider
- `lib/features/capture/presentation/capture_page.dart` - Stack layout with panel overlay, AI trigger button
- `lib/features/settings/presentation/settings_page.dart` - Navigation to banned phrase settings
- `lib/core/presentation/providers.dart` - editorProvider export, all AI-related providers registered
- `lib/shared/constants/app_constants.dart` - bannedPhrases route constant
- `lib/app.dart` - Banned phrases route in GoRouter
- `lib/features/ai/application/anti_ai_scent_processor.dart` - synonymKeys static getter for seeding
- `lib/core/infrastructure/settings_repository.dart` - getBannedPhrases/saveBannedPhrases methods

## Decisions Made
- **D-18:** Editor exposed via EditorHolderNotifier (Notifier<Editor?>) -- set in EditorPage.initState, cleared in dispose. Works because StatefulShellRoute.indexedStack keeps the editor widget mounted even when navigating to capture page.
- **D-19:** activeProviderProvider and activeApiKeyProvider wrap async FutureProviders for synchronous reads, since SynthesisNotifier runs synchronous state transitions. Tests can override these directly.
- **D-20:** BannedPhrasesNotifier seeds from AntiAIScentProcessor.synonymKeys on first access, then persists user changes via SettingsRepository.getBannedPhrases/saveBannedPhrases.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed unused imports in synthesis_notifier.dart**
- **Found during:** Task 1 (prior work assessment)
- **Issue:** Two unused imports (token_budget_calculator.dart, openai_adapter.dart) flagged by flutter analyze
- **Fix:** Removed unused imports -- types are accessed via provider return values, not directly
- **Files modified:** lib/features/ai/presentation/synthesis_notifier.dart
- **Verification:** flutter analyze zero issues, 21 tests pass
- **Committed in:** e27f37f (Task 1 commit)

**2. [Rule 1 - Bug] Fixed AsyncValue.valueOrNull to asData?.value**
- **Found during:** Task 2 (new code)
- **Issue:** Riverpod 3.x uses `asData?.value` not `valueOrNull` on AsyncValue
- **Fix:** Changed all occurrences in banned_phrase_settings.dart and synthesis_notifier.dart
- **Files modified:** lib/features/ai/presentation/banned_phrase_settings.dart, lib/features/ai/presentation/synthesis_notifier.dart
- **Verification:** flutter analyze zero issues, 21 tests pass
- **Committed in:** d9d17b6 (Task 2 commit)

**3. [Rule 1 - Bug] Removed unused imports in test file**
- **Found during:** Task 2 (full project analysis)
- **Issue:** Three unused imports (anti_ai_scent_processor, prompt_pipeline, token_budget_calculator) in test file
- **Fix:** Removed unused imports
- **Files modified:** test/features/ai/presentation/synthesis_notifier_test.dart
- **Verification:** flutter analyze zero issues, 21 tests pass
- **Committed in:** d9d17b6 (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (3 bugs)
**Impact on plan:** All auto-fixes were minor import/API corrections. No scope creep.

## Issues Encountered
None - plan executed smoothly on top of prior work foundation.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 2 is now complete (3/3 plans). The core creative loop works: capture fragments, select, AI synthesize, edit, insert into editor.
- Phase 3 (Editor AI Toolbar) can build on SynthesisNotifier pattern for floating toolbar AI actions
- AntiAIScentProcessor.synonymKeys provides seed data for user customization
- EditorHolderNotifier pattern can be extended for editor text selection access in Phase 3

---
*Phase: 02-ai-provider-capture-synthesis*
*Completed: 2026-06-02*

## Self-Check: PASSED
