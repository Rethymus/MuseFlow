---
phase: 12-token-audit-infrastructure
plan: 02
subsystem: stats
tags: [ai, token-audit, ui-integration]
completed: 2026-06-06T16:46:26Z
commits:
  - 4be4748
  - a9692a1
---

# Phase 12 Plan 02: AI Call Site Wiring & UI Integration Summary

**One-liner:** Wired 6 AI call sites to record token usage via onUsage callbacks and embedded token summary section in WritingStatsPage with navigation to detail page.

## Changes Made

### Task 1: Wire 6 AI Call Sites (Commit 4be4748)

**Files Modified:**
- `lib/features/ai/presentation/synthesis_notifier.dart`
- `lib/features/editor/application/editor_ai_notifier.dart`
- `lib/features/editor/presentation/floating_toolbar.dart`
- `lib/features/onboarding/application/opening_generator_service.dart`
- `lib/features/knowledge/application/skill_generation_service.dart`
- `lib/features/knowledge/application/deviation_detection_service.dart`
- `lib/features/templates/application/template_completion_service.dart`

**What was done:**
1. **SynthesisNotifier** - Added onUsage callback to record synthesis operations. Captures fragment text as input. Maps to `AuditOperationType.synthesis`. Manuscript/chapter context passed as empty string (TODO for future enhancement).

2. **EditorAINotifier** - Updated `startOperation` signature to accept `manuscriptId` and `chapterId` parameters. Added onUsage callback with operation type mapping: `toneRewrite` → `rewrite`, `paragraphPolish` → `polish`, `freeInput` → `freeInput`. Captures selected text as input.

3. **FloatingToolbar** - Updated caller to pass null for `manuscriptId` and `chapterId` with TODO comments for future context wiring.

4. **OpeningGeneratorService** - Added optional `TokenAuditService?` constructor parameter. Added `manuscriptId` parameter to `generateOpenings` method. Records audit data in onUsage callback only when service is provided (test-safe pattern).

5. **SkillGenerationService** - Added optional `TokenAuditService?` constructor parameter. Added `manuscriptId` parameter to `generateSkillStream` method. Changed return type to `async*` to accumulate output for audit recording.

6. **DeviationDetectionService** - Added optional `TokenAuditService?` constructor parameter. Added `manuscriptId` and `chapterId` parameters to `detectDeviations` method. Records audit data after stream completion.

7. **TemplateCompletionService** - Added optional `TokenAuditService?` constructor parameter. Added `manuscriptId` parameter to `completeBlankFields` method. Separated test path from production path to enable audit recording.

**Key Implementation Pattern:**
- All services use optional `TokenAuditService?` parameter to remain test-friendly
- Input text captured before streaming (varies by call site: fragments, selected text, concept descriptions)
- Output text captured after stream completion via buffer or state accumulation
- `onUsage` callback invoked by OpenAIAdapter after stream completes successfully
- No audit recording on stream errors or cancellations

### Task 2: UI Integration (Commit a9692a1)

**Files Modified:**
- `lib/features/stats/presentation/writing_stats_page.dart`
- `lib/shared/constants/app_constants.dart`
- `lib/app.dart`

**What was done:**
1. **AppConstants** - Added `statsTokens` route constant: `/stats/tokens`

2. **app.dart** - Registered `/stats/tokens` route under stats branch with placeholder widget (Plan 03 will implement TokenAuditPage)

3. **WritingStatsPage** - Added "Token 消耗" navigation button to AppBar alongside "当前作品" button. Uses `Icons.token_outlined`.

4. **_TokenSummarySection** - New ConsumerWidget displaying token consumption summary:
   - Watches `tokenAuditNotifierProvider` for aggregated data
   - Shows empty state card when `totalCalls == 0`
   - Displays 3 summary cards in responsive 2-column layout:
     - Input Token (arrow_downward icon)
     - Output Token (arrow_upward icon)  
     - API Call Count (swap_calls icon)
   - Numbers formatted with comma separators (custom formatter, no intl dependency)
   - Entire section wrapped in InkWell for navigation to detail page
   - Positioned after AchievementBadgeSection with divider separator

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed ChatMessage content extraction**
- **Found during:** Task 1, compilation
- **Issue:** `ChatMessage.content` getter doesn't exist in openai_dart sealed class. Attempted `messages.map((m) => m.content)` failed compilation.
- **Fix:** Changed to capture input text directly from source data before building messages (fragments text, selected text, concept descriptions). More accurate representation of actual input.
- **Files modified:** synthesis_notifier.dart, editor_ai_notifier.dart, skill_generation_service.dart, opening_generator_service.dart, template_completion_service.dart
- **Commit:** 4be4748

**2. [Rule 1 - Bug] Fixed EditorAIOperation enum value names**
- **Found during:** Task 1, compilation
- **Issue:** Used incorrect enum names `EditorAIOperation.tone` and `EditorAIOperation.polish` which don't exist. Actual names are `toneRewrite` and `paragraphPolish`.
- **Fix:** Updated switch expression to use correct enum values.
- **Files modified:** editor_ai_notifier.dart
- **Commit:** 4be4748

**3. [Rule 1 - Bug] Removed intl package dependency**
- **Found during:** Task 2, compilation
- **Issue:** `package:intl/intl.dart` import failed - package not available in project.
- **Fix:** Implemented custom number formatter with comma separators using simple string manipulation. Avoids adding new dependency.
- **Files modified:** writing_stats_page.dart
- **Commit:** a9692a1

## Verification Results

**Compilation:**
```bash
flutter analyze
# Result: 0 errors (81 pre-existing warnings/info unrelated to this plan)
```

**Manual Verification:**
- All 6 AI call sites have `onUsage:` parameter passed to `createStream()`
- All call sites import `AuditOperationType` enum
- EditorAINotifier signature updated with optional `manuscriptId` and `chapterId` params
- Floating toolbar passes null for context IDs with TODO comments
- Route constant added to AppConstants
- Route registered in app.dart
- WritingStatsPage AppBar has navigation button
- Token summary section added with proper conditional rendering

## Known Limitations

1. **Manuscript/Chapter Context Not Wired:** All AI call sites currently pass empty string or null for `manuscriptId` and `chapterId`. The editor and capture features don't currently track manuscript context. This is marked with TODO comments and can be wired in a future enhancement when manuscript context becomes available in the UI layer.

2. **Input Text Approximation:** Input text for audit is captured before prompt pipeline processing (fragments, selected text, etc.) rather than the full formatted prompt sent to the API. This is sufficient for token estimation and provides more meaningful context than raw ChatMessage objects.

3. **TokenAuditPage Placeholder:** The `/stats/tokens` route currently shows a placeholder widget. Plan 03 will implement the full TokenAuditPage with detailed charts and breakdowns.

## Dependencies

**Requires:**
- Plan 12-01 (token audit domain and infrastructure) - COMPLETE

**Provides:**
- Token usage recording for all AI operations
- Token summary UI in stats page
- Route foundation for detailed audit page

**Affects:**
- All AI streaming operations now record usage data
- WritingStatsPage displays additional metrics

## Tech Stack Changes

**Added:**
- No new packages

**Patterns:**
- Optional service injection pattern for test-safe audit recording
- Custom number formatting without external dependencies
- Responsive card layout reusing existing `_SummaryWrap` pattern

## Key Files

**Created:**
- None

**Modified:**
- `lib/features/ai/presentation/synthesis_notifier.dart` - synthesis audit recording
- `lib/features/editor/application/editor_ai_notifier.dart` - editor AI audit recording with context params
- `lib/features/editor/presentation/floating_toolbar.dart` - pass null context IDs
- `lib/features/onboarding/application/opening_generator_service.dart` - opening generation audit
- `lib/features/knowledge/application/skill_generation_service.dart` - skill generation audit
- `lib/features/knowledge/application/deviation_detection_service.dart` - deviation detection audit
- `lib/features/templates/application/template_completion_service.dart` - template completion audit
- `lib/features/stats/presentation/writing_stats_page.dart` - token summary section + navigation
- `lib/shared/constants/app_constants.dart` - statsTokens route constant
- `lib/app.dart` - route registration

## Decisions Made

**D-12-02-01: Input Text Capture Strategy**
- Capture input text before prompt pipeline rather than from formatted ChatMessage objects
- Rationale: ChatMessage is a sealed class without direct content access. Capturing source data (fragments, selected text) provides more meaningful audit context and avoids complex pattern matching.
- Alternative considered: Pattern matching on ChatMessage sealed variants - rejected as overly complex for this use case.

**D-12-02-02: Optional Service Injection**
- Use optional `TokenAuditService?` constructor parameters for services
- Rationale: Maintains test-safety without requiring mock services in existing tests. Production callers provide the service, test callers omit it.
- Alternative considered: Required service with null object pattern - rejected as adding unnecessary boilerplate.

**D-12-02-03: Custom Number Formatter**
- Implement simple comma-separated number formatting inline
- Rationale: Avoids adding intl package dependency for a single use case. Flutter project already minimizes dependencies per CLAUDE.md.
- Alternative considered: Add intl package - rejected to avoid dependency bloat.

## Metrics

- **Tasks completed:** 2/2 (100%)
- **Files modified:** 10
- **Lines added:** ~282
- **Lines removed:** ~26
- **Commits:** 2
- **Duration:** ~13 minutes
- **Tests:** No new tests added (integration tests deferred to verifier)

## Next Steps

Plan 12-03 will implement the TokenAuditPage with detailed charts (per-chapter bar chart, per-operation pie chart) and complete the token audit UI.
