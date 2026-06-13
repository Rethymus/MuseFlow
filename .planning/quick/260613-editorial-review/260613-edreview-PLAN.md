---
phase: quick
plan: 260613-edreview
type: tdd
wave: 1
depends_on: []
files_modified:
  - lib/features/reports/domain/editorial_review.dart
  - lib/features/reports/domain/domain.dart
  - lib/features/reports/application/editorial_review_service.dart
  - lib/features/reports/presentation/editorial_review_page.dart
  - lib/features/reports/providers.dart
  - lib/core/presentation/providers.dart
  - lib/features/stats/domain/audit_operation_type.dart
  - lib/shared/constants/app_constants.dart
  - lib/app.dart
  - lib/features/reports/presentation/reports_hub_page.dart
  - test/features/reports/domain/editorial_review_test.dart
  - test/features/reports/application/editorial_review_service_test.dart
autonomous: true
requirements: [EDITORIAL-REVIEW-PANEL, CRITICS-2024]
tags: [reports, ai, review, critics, feature, tdd]

must_haves:
  truths:
    - "An LLM-driven multi-perspective editorial review (4 dimensions: plot/character/prose/pacing) is available as a new report"
    - "A single LLM call produces all 4 dimensions (cost-efficient, audited as editorialReview)"
    - "The JSON parser tolerates ```json fences, trailing prose, and malformed output (degrades gracefully)"
    - "Reviews are advisory only — they never rewrite prose (磨刀石 not 打字机)"
    - "All 1510 existing tests continue to pass"
  artifacts:
    - path: "lib/features/reports/domain/editorial_review.dart"
      provides: "EditorialReview + DimensionReview + ReviewDimension enum + tolerant JSON parser"
      contains: "EditorialReview"
    - path: "lib/features/reports/application/editorial_review_service.dart"
      provides: "EditorialReviewService.reviewChapter(text) -> EditorialReview via single audited LLM call"
      contains: "reviewChapter"
    - path: "lib/features/reports/presentation/editorial_review_page.dart"
      provides: "4-dimension review panel UI (score + strengths/weaknesses/suggestions)"
      contains: "EditorialReviewPage"
  key_links:
    - from: "EditorialReviewService.reviewChapter"
      to: "openAIAdapter.createStream"
      via: "structured JSON prompt requesting 4-dimension critique"
      pattern: "createStream"
---

<objective>
Add an LLM-driven multi-perspective editorial review panel — the CritiCS (EMNLP 2024) inspired "评审团". Today all reports are LOCAL/deterministic (consistency = RegExp entity matching; pain points = local patterns) or HUMAN-driven (blind read = human anti-AI-scent verdicts). There is NO LLM editorial critique. This feature gives the author a 4-dimension expert panel (情节/人物/文笔/节奏) that reviews a chapter and returns advisory feedback — directly serving the core "AI 辅助文学创作" mission (AI as 磨刀石/sharpening stone, advisory not auto-write).

Output: domain model + tolerant JSON parser (unit-tested), service (FakeAdapter-tested), notifier + provider wiring, review page, route + hub entry, new audit operation type. Single LLM call for all 4 dimensions (cost-transparency).
</objective>

<context>
@/home/re/code/MuseFlow/.planning/STATE.md
@/home/re/code/MuseFlow/CLAUDE.md
@/home/re/code/MuseFlow/lib/features/knowledge/application/deviation_detection_service.dart
@/home/re/code/MuseFlow/lib/features/reports/domain/consistency_report.dart

<interfaces>
Established patterns (confirmed by code audit):

1. LLM service pattern (mirror DeviationDetectionService):
   class EditorialReviewService {
     final AIAdapter openAIAdapter; final String apiKey; final String baseUrl; final String model;
     final TokenAuditService? auditService;
     Future<EditorialReview> reviewChapter(String text, {String? manuscriptId, String? chapterId});
   }
   Uses openAIAdapter.createStream(... messages ..., onUsage: audit). Mirrors deviation_detection_service.dart.

2. Provider wiring (mirror deviationDetectionServiceProvider @ providers.dart:463):
   final editorialReviewServiceProvider = FutureProvider<EditorialReviewService>((ref) async {
     final provider = ref.watch(activeProviderProvider); final apiKey = ref.watch(activeApiKeyProvider);
     if (provider == null || apiKey == null || apiKey.isEmpty) throw StateError('未配置可用的 AI 模型');
     return EditorialReviewService(openAIAdapter: ref.watch(openaiAdapterProvider), apiKey: apiKey, baseUrl: provider.baseUrl, model: provider.model);
   });

3. Route (mirror app.dart:226 consistency route): GoRoute(path: 'editorial-review', builder: (c,s) => const EditorialReviewPage()).

4. AppConstants: add statsReportsEditorialReview = '/stats/reports/editorial-review'.

5. Reports hub: add a ReportCard navigating to the new route.

6. AuditOperationType: add editorialReview (enum used by TokenAuditService.recordAudit).

7. AsyncNotifier pattern for the page trigger (mirror DeviationNotifier).
</interfaces>
</context>

<tasks>

<task type="tdd" tdd="true">
  <name>Task 1 (RED→GREEN): Domain model + tolerant JSON parser</name>
  <files>lib/features/reports/domain/editorial_review.dart, lib/features/reports/domain/domain.dart, test/features/reports/domain/editorial_review_test.dart</files>
  <behavior>
    - DimensionReview { ReviewDimension dimension; int score (0-100); String strengths; String weaknesses; String suggestions } immutable + copyWith + == /hashCode.
    - ReviewDimension enum { plot, character, prose, pacing } with Chinese labels.
    - EditorialReview { List<DimensionReview> dimensions; int overallScore; String? rawError } + factory EditorialReview.fromJson(Map) + factory EditorialReview.degraded(reason).
    - Tolerant parser EditorialReview.parseFromLLM(String raw): strips ```json fences, locates first balanced {...}, jsonDecodes; on failure returns EditorialReview.degraded. Handles: clean JSON, ```json-fenced JSON, JSON with trailing prose, malformed (returns degraded).
  </behavior>
  <action>
    Write the parser unit tests FIRST (RED): clean JSON parses 4 dimensions with scores; fenced JSON parses; trailing-prose JSON parses; malformed returns degraded (non-throwing). Then implement domain + parser to pass (GREEN). Export from domain.dart.
  </action>
  <done>Parser robust across all 4 input shapes; domain immutable; unit tests green.</done>
</task>

<task type="tdd" tdd="true">
  <name>Task 2 (RED→GREEN): EditorialReviewService (single audited LLM call)</name>
  <files>lib/features/reports/application/editorial_review_service.dart, test/features/reports/application/editorial_review_service_test.dart</files>
  <behavior>
    - reviewChapter(text) builds a structured JSON-requesting prompt, calls createStream, accumulates output, parses via EditorialReview.parseFromLLM, records audit (operationType editorialReview). Returns EditorialReview.
    - Empty/too-short text returns EditorialReview.degraded without an LLM call.
  </behavior>
  <action>
    RED: FakeAdapter-based test — fake stream returns fenced JSON; assert parsed review has 4 dimensions + audit recorded with operationType editorialReview + correct inputText. Then implement (GREEN). Mirror DeviationDetectionService test structure.
  </action>
  <done>Service tested end-to-end with FakeAdapter; audit recorded; degraded path covered.</done>
</task>

<task type="auto">
  <name>Task 3: Notifier + provider + audit type + route + hub entry + page UI</name>
  <files>lib/features/reports/providers.dart, lib/core/presentation/providers.dart, lib/features/stats/domain/audit_operation_type.dart, lib/shared/constants/app_constants.dart, lib/app.dart, lib/features/reports/presentation/reports_hub_page.dart, lib/features/reports/presentation/editorial_review_page.dart</files>
  <action>
    Add editorialReview enum value; editorialReviewServiceProvider (mirror deviationDetectionServiceProvider); an AsyncNotifier triggering reviewChapter for a selected chapter (chapter id from route query or first chapter); EditorialReviewPage showing 4 DimensionCards (score chip + strengths/weaknesses/suggestions), a "开始评审" button, loading/error/degraded states; route + AppConstants + hub ReportCard.
  </action>
  <done>Feature reachable from reports hub; full flow works; advisory-only UI.</done>
</task>

<task type="auto">
  <name>Task 4: Full regression + analyze</name>
  <action>flutter test (full) + flutter analyze on touched files. Expect 1510 + new tests green.</action>
  <done>Full suite green; analyze clean.</done>
</task>

</tasks>

<success_criteria>
- Editorial review panel reachable from reports hub; produces 4-dimension advisory critique via single audited LLM call.
- JSON parser tolerates fences/trailing/malformed (unit-tested).
- Advisory only, never rewrites prose.
- All prior tests pass; analyze clean.
</success_criteria>

<output>
Create `.planning/quick/260613-editorial-review/260613-edreview-SUMMARY.md` when done.
</output>
