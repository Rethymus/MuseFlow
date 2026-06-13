---
phase: quick-260614-1tp
plan: 01
subsystem: editor/style-analysis + ai/prompt
tags: [style, ai-prompt, nlp, cjk]
requires: [P2-author-style-fingerprint (AuthorStyleProfile, StyleAnalyzer, DynamicPersonaMiddleware)]
provides:
  - LexicalSignature + LexicalTerm value objects (pure Dart domain)
  - CjkStopwords functional-word set
  - LexicalSignatureExtractor pure n-gram function
  - AuthorStyleProfile.lexicalSignature field (backward-compatible)
  - DynamicPersonaMiddleware vocabulary injection
affects:
  - AuthorStyleProfile JSON schema (additive, backward-compat)
  - generation prompt persona text
tech-stack:
  added: []
  patterns: [pure-function n-gram extraction, CJK sliding window, salience weighting, backward-compat fromJson]
key-files:
  created:
    - lib/features/editor/domain/lexical_signature.dart
    - lib/features/editor/infrastructure/cjk_stopwords.dart
    - lib/features/editor/application/lexical_signature_extractor.dart
    - test/features/editor/domain/lexical_signature_test.dart
    - test/features/editor/application/lexical_signature_extractor_test.dart
    - test/features/ai/application/dynamic_persona_middleware_test.dart
  modified:
    - lib/features/editor/domain/author_style_profile.dart
    - lib/features/editor/application/style_analyzer.dart
    - lib/features/ai/application/prompt_middlewares/dynamic_persona_middleware.dart
    - test/features/editor/domain/style_profile_test.dart
    - test/features/editor/application/style_analyzer_test.dart
decisions:
  - D-1tp-01: Stopword filter is per-character, not per-gram (see Decisions Made)
  - D-1tp-02: No substring dedup of n-grams (bigrams + trigrams both retained)
  - D-1tp-03: take(10) for prompt injection, phrased as "自然融入" guidance
metrics:
  duration: ~35 min
  completed: 2026-06-14
---

# Phase quick-260614-1tp Plan 01: Author Vocabulary (Lexical Signature) Summary

Added a sixth style dimension — author characteristic CJK n-grams (bigram + trigram) — to `AuthorStyleProfile`, extracted via a pure-function n-gram pipeline and injected into the generation prompt as "自然融入作者表达倾向" guidance so the AI internalizes the author's actual vocabulary palette instead of a generic "comparable vocabulary level" scalar.

## What Was Built

**3 new source files:**
- `lib/features/editor/domain/lexical_signature.dart` — `LexicalSignature` + `LexicalTerm` immutable value objects (pure Dart, no Flutter import), with `empty` sentinel, `isEmpty`, `copyWith`, `fromJson`/`toJson`, value equality, `Object.hashAll` hashCode.
- `lib/features/editor/infrastructure/cjk_stopwords.dart` — `CjkStopwords.grams` static `Set<String>` (~84 functional/grammatical grams: single-char particles + multi-char function phrases). Content words (剑意, 凌厉, etc.) deliberately excluded.
- `lib/features/editor/application/lexical_signature_extractor.dart` — `LexicalSignatureExtractor.extract(text, {maxTerms})` pure function: CJK segment → bigram/trigram sliding window → frequency count → stopword-char filter → salience ranking (trigram ×1.5 > bigram ×1.0) → truncate.

**3 integrated files:**
- `author_style_profile.dart` — added `lexicalSignature` field (default `const LexicalSignature()`), wired through constructor / copyWith / fromJson (backward-compat: missing key → empty signature) / toJson.
- `style_analyzer.dart` — `analyze()` calls `LexicalSignatureExtractor.extract(allText)` before constructing the returned profile; early-return path uses the field's empty default.
- `dynamic_persona_middleware.dart` — `_buildDynamicPersona` injects top-10 terms as `作者常用表达：…` with `（请在创作中自然融入作者的表达倾向，不要机械堆砌这些词）` after the emotional-tone guidance and before the anti-AI-scent anchor (anchor preserved verbatim).

## Algorithm Decisions

**D-1tp-01 — Stopword filter granularity: per-character, not per-gram.**
The plan's `<action>` step 4 said "discard `CjkStopwords.grams.contains(gram)`" (exact-match per-gram), but the plan's `<behavior>` test 2 and the critical_design_notes narrative said "若 n-gram 含任一停用词字符...则丢弃" (discard if the n-gram *contains any* stopword character). The exact-match filter leaked stopword-only n-grams like "的了" (both 的 and 了 are stopword single-chars, but "的了" the bigram is not in the set). I resolved this in favor of the **per-character** filter (`_containsStopwordChar`): an n-gram is discarded if any of its constituent CJK characters is a single-char stopword. This is safe because genuine author-characteristic content n-grams (剑意/凌厉/拔剑) never contain functional chars, so the filter never strips real author signal. This makes the `<behavior>` test 2 pass and matches the plan's stated intent. Record: this is a deliberate deviation from the literal `<action>` text to honor the `<behavior>` and critical_design_notes.

**D-1tp-02 — No substring dedup of n-grams.**
The plan's `<action>` step 7 proposed optional near-overlap deduplication (skip a candidate that is a substring of an already-selected term with length-difference ≤1). However `<behavior>` test 3 requires *both* bigrams (拔剑, 剑四, 四顾) and trigrams (拔剑四, 剑四顾) to coexist in the result for "拔剑四顾". A substring dedup would drop 拔剑 (substring of 拔剑四, length-diff 1). The plan's own note warned "不要过度去重把'拔剑'和'拔剑四'都砍掉". I removed dedup entirely: salience ranking (trigram ×1.5 > bigram ×1.0) naturally orders them, `maxTerms` bounds the count, and both bigram and trigram surface forms are preserved as distinct author-characteristic signals.

**D-1tp-03 — take(10) for prompt injection, "自然融入" phrasing.**
Injected the top-10 (not all 15) terms as a comma-joined `作者常用表达` line, followed by a guidance clause `（请在创作中自然融入作者的表达倾向，不要机械堆砌这些词）`. Mechanical stuffing of top words is itself an AI-scent tell and violates the product soul (反AI味); the phrasing frames the list as an expression-tendency to internalize, not a vocabulary to deploy. The existing anti-AI-scent anchor (`核心要求` / `AI生成的痕迹`) is preserved verbatim immediately after.

## Backward Compatibility Verification

`AuthorStyleProfile.fromJson` was verified against legacy JSON lacking the `lexicalSignature` key (Task 2 Test 3): a hand-built legacy JSON object parses successfully and yields `lexicalSignature.isEmpty == true`. No exception, no data loss for existing persisted profiles.

## Anti-AI-Scent Preservation

The `核心要求` anchor block (`模仿上述风格特征，但不要让读者感到刻意...`) is untouched and remains the closing anchor of the persona text. The vocabulary injection is phrased as guidance (自然融入), not a directive, so it does not introduce a new keyword-stuffing AI-scent vector. Verified by Task 3 Test 2 (asserts "自然融入" present) and Task 3 Test 3 (asserts anchor preserved).

## IJCNLP 2025 Author Writing Sheet Correspondence

This implements the characteristic-word extraction + injection contribution of the IJCNLP 2025 Author Writing Sheet approach (reported 78% style win-rate): rather than telling the model "match the author's vocabulary level" (a scalar), the model is given the author's actual characteristic n-grams and asked to blend them naturally. The n-gram frequency + stopword-filter + salience pipeline is the pure-Dart, zero-dependency realization of that idea.

## Final Verification Numbers

- `flutter analyze` → **No issues found!** (ran in 2.9s)
- `flutter test` → **1548 passed, 12 skipped, 0 failed** (baseline 1524; +24 new, no regressions)

New test breakdown:
- `lexical_signature_test.dart`: 7 tests (domain value-object semantics)
- `lexical_signature_extractor_test.dart`: 6 tests (n-gram pipeline: high-freq-ranks-first, stopword filter, bigram/trigram extraction, empty/latin/punctuation, trigram-weight-outranks-bigram, maxTerms truncation)
- `style_profile_test.dart`: +4 tests (default-empty, round-trip, legacy-JSON backward-compat, copyWith-override)
- `style_analyzer_test.dart`: +2 tests (population from chapters, empty-chapters → empty signature)
- `dynamic_persona_middleware_test.dart`: 5 tests (term injection, 自然融入 phrasing, anchor preserved, empty-sig skip, null-passthrough)

## Deviations from Plan

**[Rule 1 - Bug] Resolved stopword-filter granularity conflict.**
- **Found during:** Task 1 GREEN
- **Issue:** Plan `<action>` step 4 (exact gram match) vs `<behavior>` test 2 + critical_design_notes (per-character containment) — the literal action leaked stopword-only n-grams like "的了".
- **Fix:** Implemented per-character stopword containment filter (`_containsStopwordChar`). See D-1tp-01.
- **Files modified:** `lib/features/editor/application/lexical_signature_extractor.dart`
- **Commit:** baac2cc

**[Rule 1 - Bug] Removed substring dedup to honor test contract.**
- **Found during:** Task 1 GREEN
- **Issue:** Plan `<action>` step 7 optional dedup would have dropped bigrams that are substrings of higher-ranked trigrams, breaking `<behavior>` test 3 (拔剑 + 拔剑四 must coexist).
- **Fix:** Removed `_overlapsExisting` dedup; salience ranking + maxTerms suffice. See D-1tp-02.
- **Files modified:** `lib/features/editor/application/lexical_signature_extractor.dart`
- **Commit:** baac2cc

**[Rule 3 - Blocking issue] Fixed `no_leading_underscores_for_local_identifiers` lint.**
- **Found during:** Task 4 analyze
- **Issue:** Local helper `_baseContext` in middleware test violated the lint → `flutter analyze` reported 1 issue, blocking the "No issues found!" hard acceptance criterion.
- **Fix:** Renamed local helper `_baseContext` → `baseContext`. Pure rename, no behavior change.
- **Files modified:** `test/features/ai/application/dynamic_persona_middleware_test.dart`
- **Commit:** 10a58a0

## Authentication Gates

None.

## Known Stubs

None. All new code is fully wired (extractor populates the field; field flows through JSON; middleware reads and injects).

## Threat Flags

None. The new surface (n-gram extraction, JSON field, prompt injection) is covered by the plan's threat model (T-1tp-01 through T-1tp-05) with mitigations applied: pure-function no-IO extractor with graceful empty-fallback (T-1tp-01), backward-compat fromJson (T-1tp-03), and "自然融入" phrasing to prevent keyword stuffing (T-1tp-04).

## Self-Check: PASSED

All 3 new source files and 3 new test files exist on disk; all 4 task commits present in `git log`.

- FOUND: lib/features/editor/domain/lexical_signature.dart
- FOUND: lib/features/editor/infrastructure/cjk_stopwords.dart
- FOUND: lib/features/editor/application/lexical_signature_extractor.dart
- FOUND: test/features/editor/domain/lexical_signature_test.dart
- FOUND: test/features/editor/application/lexical_signature_extractor_test.dart
- FOUND: test/features/ai/application/dynamic_persona_middleware_test.dart
- FOUND: baac2cc (Task 1)
- FOUND: 5a72201 (Task 2)
- FOUND: b938051 (Task 3)
- FOUND: 10a58a0 (Task 4 lint fix)
