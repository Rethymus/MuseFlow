---
phase: 02-ai-provider-capture-synthesis
plan: 02
subsystem: ai-engine
tags: [streaming, prompt-pipeline, anti-ai-scent, token-budget, tdd]
dependency_graph:
  requires: [AIProvider entity, AIException hierarchy, ProviderService, Fragment entity, openai_dart]
  provides: [OpenAIAdapter, SynthesisRequest, PromptPipeline, PromptMiddleware, AntiAIScentProcessor, TokenBudgetCalculator]
  affects: [providers, synthesis_notifier (Plan 03)]
tech_stack:
  added: [openai_dart v6 streaming (ChatStreamEvent, textDelta, createStream)]
  patterns: [middleware chain, sealed exception classification, CJK boundary-aware matching, LIFO budget trimming]
key_files:
  created:
    - lib/features/ai/domain/synthesis_request.dart
    - lib/features/ai/infrastructure/openai_adapter.dart
    - lib/features/ai/application/prompt_pipeline.dart
    - lib/features/ai/application/prompt_middlewares/system_prompt_middleware.dart
    - lib/features/ai/application/prompt_middlewares/persona_injection_middleware.dart
    - lib/features/ai/application/prompt_middlewares/banned_list_middleware.dart
    - lib/features/ai/application/prompt_middlewares/user_content_middleware.dart
    - lib/features/ai/application/anti_ai_scent_processor.dart
    - lib/features/ai/application/token_budget_calculator.dart
    - test/features/ai/infrastructure/openai_adapter_test.dart
    - test/features/ai/application/prompt_pipeline_test.dart
    - test/features/ai/application/anti_ai_scent_test.dart
    - test/features/ai/application/token_budget_test.dart
  modified:
    - lib/core/presentation/providers.dart
decisions:
  - D-15: Boundary-aware matching uses CJK both-sides check (not regex word boundary) per Pitfall 5
  - D-16: PromptPipeline middlewares import openai_dart directly (Dart does not re-export transitively)
  - D-17: AntiAIScentProcessor has const constructor on PromptMiddleware to allow const middleware subclasses
metrics:
  duration: 16m
  completed: "2026-06-02"
  tasks: 2
  files_created: 13
  files_modified: 1
  tests: 73
---

# Phase 2 Plan 2: AI Engine Summary

Streaming OpenAI adapter, composable PromptPipeline middleware chain, dual-layer anti-AI-scent processor, and Chinese text token budget calculator.

## What Was Built

**Task 1: OpenAI adapter, SynthesisRequest, and PromptPipeline (TDD)**

- `OpenAIAdapter`: wraps `openai_dart` v6 `OpenAIClient` with streaming via `createStream()`, error classification into `AIException` sealed hierarchy, client caching (one client per apiKey+baseUrl), HTTPS enforcement per T-02-08 with localhost exception for Ollama
- `SynthesisRequest`: immutable value object with `fragments` (List\<Fragment\>), `additionalInstruction` (String?, per D-06), `maxOutputTokens` (default 2000), `temperature` (default 0.7), `copyWith`
- `PromptPipeline`: composable middleware chain with `build(PromptContext)` applying ordered middlewares sequentially
- `PromptContext`: immutable context flowing through middlewares, with `fragments`, `additionalInstruction`, `bannedPhrases`, `messages` accumulator, `tokenBudget`
- `PromptMiddleware`: abstract base class with `apply(PromptContext)` method and `const` constructor
- `SystemPromptMiddleware`: adds base system message "你是一位经验丰富的中文小说作者..."
- `PersonaInjectionMiddleware`: appends "写作风格：自然、有温度、像人写的" per D-11
- `BannedListMiddleware`: appends negative checklist from `bannedPhrases` per D-11
- `UserContentMiddleware`: creates user message with numbered fragment texts and optional instruction
- Providers: `openaiAdapterProvider`, `promptPipelineProvider` registered in `providers.dart`
- 38 tests (16 adapter + 22 pipeline)

**Task 2: Anti-AI-scent processor and token budget calculator (TDD)**

- `AntiAIScentProcessor`: dual-layer post-processing system per AI-05/AI-06
  - Auto-replacement: 15 seeded Chinese AI cliches with synonym map per D-09 ("然而" -> "但是", "综上所述" -> delete, etc.)
  - Boundary-aware matching: CJK both-sides check prevents replacement inside longer words (e.g., "自然而然" not matched) per Pitfall 5
  - Structural highlighting: 3 regex patterns ("不仅...而且", "随着...的发展", etc.) wrapped with 【】 markers per D-10
  - `ProcessingResult`: processedText + List\<TextHighlight\> with start, end, originalText, type (bannedWord | structuralPattern)
  - Supports additional `bannedPhrases` from parameter for user customization
- `TokenBudgetCalculator`: Chinese text token estimation and budget management per AI-07
  - `estimateTokens`: 1.8x multiplier for CJK chars, 0.25x for ASCII, 10% safety margin
  - `calculateBudget`: subtracts system prompt + persona + banned list + reserved output from context window
  - `selectFragmentsWithinBudget`: LIFO removal per D-13, returns `BudgetResult` with included/excluded counts
- 35 tests (20 anti-AI-scent + 15 token budget)

## Decisions Made

1. **D-15: CJK both-sides boundary check**: Initial approach used regex word-boundary matching, which was too strict for Chinese text where phrases naturally sit between CJK and non-CJK characters. The correct check: only block replacement when BOTH sides of the match are CJK characters (phrase embedded in a longer word like "自然而然")
2. **D-16: Direct openai_dart imports in middlewares**: Dart does not re-export transitively. Each middleware file must import `openai_dart` directly to use `ChatMessage.system()` and `ChatMessage.user()`
3. **D-17: Const constructor on PromptMiddleware**: Subclass `const` constructors (e.g., `const SystemPromptMiddleware()`) require a `const` super constructor on the abstract base class

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed CJK boundary-aware matching logic**
- **Found during:** Task 2 test run
- **Issue:** Initial regex-based boundary matching (`_boundaryBefore`/`_boundaryAfter`) incorrectly treated single characters as regex matches, causing both false positives and false negatives
- **Fix:** Replaced with CJK code point range check (`_isCjkChar`) and both-sides boundary logic: only block replacement when both preceding AND following characters are CJK ideographs
- **Files modified:** `lib/features/ai/application/anti_ai_scent_processor.dart`
- **Commit:** 588cf8e

**2. [Rule 1 - Bug] Fixed PromptMiddleware const constructor**
- **Found during:** Task 1 compilation
- **Issue:** `const UserContentMiddleware()` failed because `PromptMiddleware` had no const constructor
- **Fix:** Added `const PromptMiddleware()` constructor to abstract class
- **Files modified:** `lib/features/ai/application/prompt_pipeline.dart`
- **Commit:** 235ca40

**3. [Rule 3 - Blocking] Added openai_dart imports to middleware files**
- **Found during:** Task 1 compilation
- **Issue:** Middleware files couldn't access `ChatMessage` because Dart doesn't transitively re-export imports
- **Fix:** Added `import 'package:openai_dart/openai_dart.dart'` to each middleware file
- **Files modified:** All 4 middleware files
- **Commit:** 235ca40

## Test Results

- 114/114 tests passing (across Plan 01 + Plan 02)
- Plan 02 new tests: 73
  - OpenAIAdapter: 16 tests (streaming, error classification, client caching, HTTPS validation)
  - PromptPipeline: 22 tests (SynthesisRequest, PromptContext, all 4 middlewares, pipeline ordering)
  - AntiAIScentProcessor: 20 tests (auto-replacement, boundary awareness, structural highlighting, edge cases)
  - TokenBudgetCalculator: 15 tests (token estimation, budget calculation, LIFO fragment selection)

## Verification

- `flutter test test/features/ai/` -- 114 tests pass
- `flutter analyze` -- zero errors, zero warnings

## Self-Check: PASSED

All 13 created files and 1 modified file verified present. All 5 commits (6d3b913, 235ca40, 540ac7b, 588cf8e, 2dfcb3c) verified in git log.
