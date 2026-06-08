---
phase: 16-analysis-reports
plan: 02
subsystem: reports
tags: [flutter, dart, riverpod, fl_chart, reports, token-audit]

requires:
  - phase: 16-analysis-reports
    provides: Reports domain models, export markdown builders, hub navigation
provides:
  - Token cost aggregation service with 50万字 projection and optimization suggestions
  - Pain point catalog service for Phase 14/15 issue logs
  - Token cost and pain point report detail pages with export actions
  - Cost projection bar chart and severity indicator widgets
affects: [phase-16-analysis-reports, report-pages, token-audit, validation-reports]

tech-stack:
  added: []
  patterns:
    - Manual Riverpod AsyncNotifier providers for report generation
    - Read-only report services generated on demand without persistence caching
    - Flutter report pages using AsyncValue.when and reusable stat cards

key-files:
  created:
    - lib/features/reports/application/token_cost_report_service.dart
    - lib/features/reports/application/pain_point_report_service.dart
    - lib/features/reports/providers.dart
    - lib/features/reports/presentation/token_cost_report_page.dart
    - lib/features/reports/presentation/pain_point_report_page.dart
    - lib/features/reports/presentation/charts/cost_projection_chart.dart
    - lib/features/reports/presentation/severity_indicator.dart
    - test/features/reports/application/token_cost_report_service_test.dart
    - test/features/reports/application/pain_point_report_service_test.dart
    - test/features/reports/presentation/token_cost_report_page_test.dart
    - test/features/reports/presentation/pain_point_report_page_test.dart
  modified:
    - lib/app.dart
    - lib/features/stats/presentation/charts/operation_type_pie_chart.dart

key-decisions:
  - "Used manual Riverpod AsyncNotifier providers to avoid code generation overhead for this report plan."
  - "Extended OperationTypePieChart to accept pre-aggregated costByType data while preserving existing record-based usage."
  - "Kept pain point data hardcoded from Phase 14/15 issue logs because automated issue detection was explicitly out of scope."

patterns-established:
  - "Report detail pages consume report providers with AsyncValue.when and expose Markdown export actions."
  - "Token projections include low/high multiplier range rather than a single long-form estimate."

requirements-completed: [REPORT-01, REPORT-02]

duration: 23min
completed: 2026-06-08
---

# Phase 16 Plan 02: Token Cost and Pain Point Reports Summary

**Token cost analytics with 50万字 projection plus a structured Phase 14/15 pain point report, both wired into Flutter report detail pages with Markdown export actions.**

## Performance

- **Duration:** 23 min
- **Started:** 2026-06-08T13:32:59Z
- **Completed:** 2026-06-08T13:56:00Z
- **Tasks:** 2
- **Files modified:** 13

## Accomplishments

- Built `TokenCostReportService` to aggregate token audit totals, group by operation type/chapter, compute manuscript word count, and extrapolate to 500,000 characters with low/high ranges.
- Built `PainPointReportService` with the six known Phase 14 issues and zero Phase 15 issues, categorized and severity-sorted for REPORT-02.
- Added Riverpod report providers, token cost and pain point report pages, projection chart, severity indicator, and `/stats/reports/*` route wiring.
- Added focused application and widget tests covering report generation, rendering, chart labels, severity colors, and export controls.

## Task Commits

Each task was committed atomically:

1. **Task 1: Build TokenCostReportService and PainPointReportService with providers** - `e5e391a` (feat)
2. **Task 2: Build TokenCostReportPage, PainPointReportPage, CostProjectionChart, and SeverityIndicator** - `24fa7d5` (feat)

**Plan metadata:** pending final metadata commit

## Files Created/Modified

- `lib/features/reports/application/token_cost_report_service.dart` - Aggregates audit data, manuscript word counts, projections, and optimization suggestions.
- `lib/features/reports/application/pain_point_report_service.dart` - Produces the structured Phase 14/15 pain point report.
- `lib/features/reports/providers.dart` - Registers report services and AsyncNotifier providers.
- `lib/features/reports/presentation/token_cost_report_page.dart` - Renders REPORT-01 summary cards, operation distribution, projection, suggestions, and export action.
- `lib/features/reports/presentation/pain_point_report_page.dart` - Renders REPORT-02 severity summaries and categorized issue cards with export action.
- `lib/features/reports/presentation/charts/cost_projection_chart.dart` - Displays actual vs projected token/call grouped bars.
- `lib/features/reports/presentation/severity_indicator.dart` - Maps 高/中/低 severities to Material color scheme indicators.
- `lib/features/stats/presentation/charts/operation_type_pie_chart.dart` - Accepts pre-aggregated `costByType` maps while preserving existing record input.
- `lib/app.dart` - Replaces report route placeholders with actual detail pages.
- `test/features/reports/application/token_cost_report_service_test.dart` - Verifies token report aggregation and projection behavior.
- `test/features/reports/application/pain_point_report_service_test.dart` - Verifies pain point counts, categories, severities, statuses, and sorting.
- `test/features/reports/presentation/token_cost_report_page_test.dart` - Verifies REPORT-01 page and projection chart rendering.
- `test/features/reports/presentation/pain_point_report_page_test.dart` - Verifies REPORT-02 page and severity indicator rendering.

## Decisions Made

- Used manual Riverpod AsyncNotifier providers instead of `@riverpod` generation to keep the implementation small and avoid build runner churn.
- Extended the existing operation pie chart to support report-ready aggregate maps instead of duplicating chart UI.
- Used fixed report export filenames (`token-cost-report.md`, `pain-point-report.md`) to satisfy the threat model requirement of no user-controlled path input.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected plan issue-count mismatch**
- **Found during:** Task 1 (PainPointReportService tests)
- **Issue:** The plan simultaneously listed six issues but expected `3 功能缺陷, 1 体验摩擦, 2 缺失需求` and `1 高, 3 中, 2 低`; the source issue list actually contains 2 功能缺陷, 1 体验摩擦, 3 缺失需求 and 1 高, 4 中, 1 低.
- **Fix:** Implemented and tested counts based on the concrete six Issue Log entries from the plan context.
- **Files modified:** `lib/features/reports/application/pain_point_report_service.dart`, `test/features/reports/application/pain_point_report_service_test.dart`
- **Verification:** `flutter test` report application tests passed.
- **Committed in:** `e5e391a`

**2. [Rule 3 - Blocking] Repaired chart API compatibility for report data**
- **Found during:** Task 2 (TokenCostReportPage implementation)
- **Issue:** Existing `OperationTypePieChart` only accepted raw audit records, while the report domain exposes aggregated `costByType` data.
- **Fix:** Added optional `costByType` input while preserving the original `records` flow.
- **Files modified:** `lib/features/stats/presentation/charts/operation_type_pie_chart.dart`
- **Verification:** Widget tests and `flutter analyze` passed.
- **Committed in:** `24fa7d5`

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking)
**Impact on plan:** Both fixes were required for correctness and compatibility; no architectural scope change.

## Issues Encountered

- TDD RED tests failed as expected before service files existed.
- Initial widget assertions missed off-screen lazy `ListView` content; tests were adjusted to scroll before checking lower sections.
- Analyzer reported style-only issues, fixed before Task 2 commit.

## Verification

- `flutter test test/features/reports/application/token_cost_report_service_test.dart test/features/reports/application/pain_point_report_service_test.dart --timeout 60s` passed.
- `flutter test test/features/reports/application/token_cost_report_service_test.dart test/features/reports/application/pain_point_report_service_test.dart test/features/reports/presentation/token_cost_report_page_test.dart test/features/reports/presentation/pain_point_report_page_test.dart --timeout 120s` passed.
- `flutter analyze lib/features/reports lib/app.dart` passed with no issues.

## Known Stubs

None.

## Threat Flags

None.

## User Setup Required

None - no external service configuration required.

## Self-Check: PASSED

- Created files exist in the worktree.
- Task commits `e5e391a` and `24fa7d5` exist in git history.
- SUMMARY.md is being committed in the final metadata commit.

## Next Phase Readiness

REPORT-01 and REPORT-02 are available from the reports hub and ready for verifier review. Remaining Phase 16 plans can build REPORT-03/REPORT-04 on the same report-provider and export-page patterns.

---
*Phase: 16-analysis-reports*
*Completed: 2026-06-08*
