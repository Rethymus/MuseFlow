---
phase: 16-analysis-reports
plan: 01
subsystem: reports
tags: [dart, flutter, riverpod, domain-models, markdown-export, go-router]

# Dependency graph
requires:
  - phase: 12-token-audit
    provides: TokenAuditRecord, AuditOperationType, TokenAuditSnapshot
  - phase: 14-world-building
    provides: DeviationSeverity, character/world-setting repositories
provides:
  - "4 report domain models: TokenCostReport, PainPointReport, BlindReadResult, ConsistencyReport"
  - "ReportExportService with 4 Markdown builders"
  - "ReportsHubPage with 4 ReportCard widgets"
  - "5 route constants and GoRoute registration under /stats/reports"
  - "WritingStatsPage navigation entry to reports hub"
affects: [16-02, 16-03]

# Tech tracking
tech-stack:
  added: []
  patterns: [report-domain-model, markdown-export-service, report-hub-navigation]

key-files:
  created:
    - lib/features/reports/domain/token_cost_report.dart
    - lib/features/reports/domain/pain_point_report.dart
    - lib/features/reports/domain/blind_read_result.dart
    - lib/features/reports/domain/consistency_report.dart
    - lib/features/reports/domain/domain.dart
    - lib/features/reports/application/report_export_service.dart
    - lib/features/reports/presentation/reports_hub_page.dart
    - lib/features/reports/presentation/report_card.dart
  modified:
    - lib/shared/constants/app_constants.dart
    - lib/app.dart
    - lib/features/stats/presentation/writing_stats_page.dart

key-decisions:
  - "BlindReadExcerpt.copyWith uses simple bool? for humanVerdict (cannot distinguish unset vs null, but use case only sets null->true/false)"
  - "ConsistencyFlag.severity reuses DeviationSeverity from deviation_detection_service (low/medium/clear)"
  - "PainPointReport severity counts are computed getters, not stored fields"
  - "Report detail routes use SizedBox.shrink() placeholders (detail pages in Plans 02/03)"
  - "ReportsHubPage page title appears in both AppBar and ListView body (follows WritingStatsPage pattern)"

patterns-established:
  - "Report domain model pattern: immutable class with const constructor, copyWith, equality"
  - "Report export pattern: StringBuffer-based Markdown builder methods in stateless service"
  - "Report hub pattern: ListView with ReportCard widgets, each navigating via context.go()"

requirements-completed: [REPORT-01, REPORT-02, REPORT-03, REPORT-04]

# Metrics
duration: 12min
completed: 2026-06-08
---

# Phase 16 Plan 01: Reports Foundation Summary

**4 report domain models (TokenCost, PainPoint, BlindRead, Consistency) with Markdown export service, ReportsHubPage navigation hub, and route registration under /stats/reports**

## Performance

- **Duration:** 12 min
- **Started:** 2026-06-08T12:32:42Z
- **Completed:** 2026-06-08T12:45:00Z
- **Tasks:** 2
- **Files modified:** 14

## Accomplishments
- 4 immutable domain models with copyWith, equality, and const constructors
- ReportExportService generating structured Markdown for all 4 report types
- ReportsHubPage with 4 navigable report cards accessible from WritingStatsPage
- 5 route constants and GoRoute tree registered (hub + 4 detail placeholders)
- 37 tests passing across 6 test files

## Task Commits

Each task was committed atomically with TDD (RED/GREEN):

1. **Task 1 (RED): Report domain model and export service tests** - `bcccce6` (test)
2. **Task 1 (GREEN): Report domain models and ReportExportService** - `d1bcb0d` (feat)
3. **Task 2 (RED): ReportsHubPage and ReportCard widget tests** - `73bbfbb` (test)
4. **Task 2 (GREEN): ReportsHubPage, ReportCard, routes, navigation** - `14328b2` (feat)

## Files Created/Modified
- `lib/features/reports/domain/token_cost_report.dart` - TokenCostReport + TokenCostProjection data models
- `lib/features/reports/domain/pain_point_report.dart` - PainPointReport + PainPointIssue data models
- `lib/features/reports/domain/blind_read_result.dart` - BlindReadExcerpt + BlindReadResult data models
- `lib/features/reports/domain/consistency_report.dart` - ConsistencyReport + EntityConsistencyResult + ConsistencyFlag
- `lib/features/reports/domain/domain.dart` - Barrel export for domain models
- `lib/features/reports/application/report_export_service.dart` - 4 Markdown builder methods
- `lib/features/reports/presentation/reports_hub_page.dart` - Hub page with 4 report cards
- `lib/features/reports/presentation/report_card.dart` - Reusable navigation card widget
- `lib/shared/constants/app_constants.dart` - 5 new report route constants
- `lib/app.dart` - GoRoute registration for reports hub + 4 detail routes
- `lib/features/stats/presentation/writing_stats_page.dart` - "分析报告" navigation button in AppBar
- `test/features/reports/domain/token_cost_report_test.dart` - 5 tests for token cost models
- `test/features/reports/domain/pain_point_report_test.dart` - 5 tests for pain point models
- `test/features/reports/domain/blind_read_result_test.dart` - 6 tests for blind read models
- `test/features/reports/domain/consistency_report_test.dart` - 6 tests for consistency models
- `test/features/reports/application/report_export_service_test.dart` - 4 tests for export service
- `test/features/reports/presentation/reports_hub_page_test.dart` - 11 tests for hub page and report card

## Decisions Made
- Used simple `bool?` instead of `bool? Function()?` in BlindReadExcerpt.copyWith for cleaner API (Rule 1 auto-fix)
- Reused DeviationSeverity enum from deviation_detection_service for ConsistencyFlag.severity
- Computed severity counts in PainPointReport (totalHigh/totalMedium/totalLow) as getters rather than fields
- Report detail routes use SizedBox.shrink() placeholders since detail pages come in Plans 02/03
- Page title "分析报告" appears in both AppBar and body ListView (matches WritingStatsPage pattern)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed BlindReadExcerpt.copyWith API for nullable bool**
- **Found during:** Task 1 (GREEN phase)
- **Issue:** copyWith used `bool? Function()?` type for humanVerdict, making it impossible to pass `true` directly
- **Fix:** Changed to simple `bool? humanVerdict` parameter with `??` operator
- **Files modified:** lib/features/reports/domain/blind_read_result.dart
- **Verification:** All 6 blind read tests pass
- **Committed in:** d1bcb0d (Task 1 GREEN commit)

**2. [Rule 1 - Bug] Fixed consistency report test assertion for percentage format**
- **Found during:** Task 1 (GREEN phase)
- **Issue:** Test expected raw '0.92' but Markdown output formats as '92.0%'
- **Fix:** Updated test to assert on '92.0%' matching actual export format
- **Files modified:** test/features/reports/application/report_export_service_test.dart
- **Verification:** All 4 export service tests pass
- **Committed in:** d1bcb0d (Task 1 GREEN commit)

**3. [Rule 1 - Bug] Fixed hub page title test for duplicate AppBar text**
- **Found during:** Task 2 (GREEN phase)
- **Issue:** "分析报告" appears in both AppBar title and body, test expected exactly one
- **Fix:** Updated test to findNWidgets(2) and verify body title has headlineMedium fontSize
- **Files modified:** test/features/reports/presentation/reports_hub_page_test.dart
- **Verification:** All 11 widget tests pass
- **Committed in:** 14328b2 (Task 2 GREEN commit)

---

**Total deviations:** 3 auto-fixed (3 Rule 1 bugs)
**Impact on plan:** All auto-fixes were test-implementation issues. No scope creep.

## Issues Encountered
None beyond the auto-fixed items above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All 4 report domain models are defined and ready for Plans 02/03 to build services against
- ReportsHubPage navigation hub is functional with route registration
- ReportExportService contracts established for Markdown export
- Plans 02/03 can proceed to implement detail pages and report generation services

---
*Phase: 16-analysis-reports*
*Completed: 2026-06-08*
