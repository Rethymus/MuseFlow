# Phase 15: Full Manuscript & Story Structure - Pattern Map

**Mapped:** 2026-06-08
**Files analyzed:** 8 (4 new, 4 modified/extended)
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `test/journey/foreshadowing_lifecycle_test.dart` | test | CRUD | `test/journey/serial_generation_test.dart` | role-match |
| `test/journey/format_cleaning_test.dart` | test | transform | `test/journey/automated_ui_evidence_test.dart` | role-match |
| `test/journey/export_validation_test.dart` | test | transform | `test/journey/automated_ui_evidence_test.dart` | role-match |
| `test/journey/statistics_accuracy_test.dart` | test | CRUD | `test/journey/serial_generation_test.dart` | role-match |
| `test/journey/helpers/story_outline.dart` | test (helper) | config | `test/journey/helpers/story_outline.dart` (itself) | exact |
| `test/journey/helpers/stage_prompts.dart` | test (helper) | config | `test/journey/helpers/xianxia_fixtures.dart` | role-match |
| `test/journey/serial_generation_test.dart` | test | CRUD+streaming | `test/journey/serial_generation_test.dart` (itself) | exact |
| `test/journey/full_journey_test.dart` | test | CRUD+streaming | `test/journey/full_journey_test.dart` (itself) | exact |

## Pattern Assignments

### `test/journey/foreshadowing_lifecycle_test.dart` (test, CRUD)

**Analog:** `test/journey/serial_generation_test.dart`

This new test file validates JOURNEY-07 (foreshadowing lifecycle: plant, track, resolve across 100 chapters). Follow the serial_generation_test.dart structure for setup/teardown, container creation, and the deterministic-vs-real-GLM skip pattern.

**Imports pattern** -- copy from `test/journey/serial_generation_test.dart` lines 1-22:
```dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';

import 'helpers/journey_container.dart';
import 'helpers/xianxia_fixtures.dart';
```

**Test setup/teardown pattern** -- copy from `test/journey/serial_generation_test.dart` lines 24-48:
```dart
void main() {
  final apiKey = Platform.environment['GLM_API_KEY'];
  final baseUrl =
      Platform.environment['GLM_BASE_URL'] ??
      'https://open.bigmodel.cn/api/paas/v4';
  final model = Platform.environment['GLM_MODEL'] ?? 'glm-4-flash';

  ProviderContainer? container;

  setUp(() async {
    if (apiKey == null) return;
    container = await createJourneyContainer(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
    );
  });

  tearDown(() async {
    final activeContainer = container;
    container = null;
    if (activeContainer != null) {
      await cleanupJourneyContainer(activeContainer);
    }
  });
```

**Core foreshadowing CRUD pattern** -- use `lib/features/story_structure/application/foreshadowing_notifier.dart` lines 20-57:
```dart
// Create entries
final notifier = container.read(foreshadowingNotifierProvider.notifier);
await notifier.add(ForeshadowingEntry(
  id: 'fs-mysterious-origin',
  title: '神秘身世',
  mode: ForeshadowingMode.detailed,
  status: ForeshadowingStatus.planted,
  plantedChapter: 3,
  targetResolutionChapter: 90,
  sourceExcerpt: '...',
  createdAt: DateTime.now(),
));

// Transition to developing
await notifier.save(entry.copyWith(status: ForeshadowingStatus.developing));

// Resolve
await notifier.markResolved(entry.id, resolvedChapter: 92);
```

**Reminder service pattern** -- use `lib/features/story_structure/application/foreshadowing_reminder_service.dart` lines 52-101:
```dart
final service = container.read(foreshadowingReminderServiceProvider);
final entries = await container.read(foreshadowingNotifierProvider.future);
final reminders = service.findReminders(
  entries: entries,
  currentChapter: 85,
  defaultThreshold: 30,
);
```

---

### `test/journey/format_cleaning_test.dart` (test, transform)

**Analog:** `test/journey/automated_ui_evidence_test.dart`

This new test validates JOURNEY-08 (format cleaning across 100 chapters). Follow the automated_ui_evidence_test.dart pattern: always-deterministic (no GLM key needed), uses FakeAdapter, group-based test structure.

**Imports pattern** -- copy from `test/journey/automated_ui_evidence_test.dart` lines 1-15:
```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/application/format_cleaner.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';

import 'helpers/journey_container.dart';
```

**Setup without GLM credentials** -- copy from `test/journey/automated_ui_evidence_test.dart` lines 18-31:
```dart
void main() {
  late ProviderContainer container;

  setUp(() async {
    container = await createJourneyContainer(
      apiKey: 'journey-local-test-key',
      baseUrl: 'https://example.com/v1',
      model: 'fake-model',
      aiAdapter: FakeAdapter(),
    );
  });

  tearDown(() async {
    await cleanupJourneyContainer(container);
  });
```

**Core FormatCleaner invocation** -- use `lib/features/story_structure/application/format_cleaner.dart` lines 29-63:
```dart
final cleaner = const FormatCleaner();
final result = cleaner.clean(chapterContent);

// Markdown residue: no heading markers at line start
expect(result.cleanedText, isNot(matches(r'(^|\n)#{1,6}\s')));
// No bold markers
expect(result.cleanedText, isNot(matches(r'\*\*[^*]+\*\*')));
// No code fences
expect(result.cleanedText, isNot(contains('```')));
// CJK punctuation: no ASCII punctuation after Chinese characters
expect(result.cleanedText, isNot(matches(r'[一-鿿][,;:!?]')));
// Layout: no 3+ consecutive blank lines
expect(result.cleanedText, isNot(matches(r'\n{4,}')));
// Idempotent
final secondPass = cleaner.clean(result.cleanedText);
expect(secondPass.changes, isEmpty);
```

---

### `test/journey/export_validation_test.dart` (test, transform)

**Analog:** `test/journey/automated_ui_evidence_test.dart`

This new test validates JOURNEY-09 (three-format export). Same setup pattern as format_cleaning_test.dart. Constructs ExportBundle from 100 chapters, then asserts each format.

**Imports pattern** -- add export-specific imports:
```dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/domain/chapter_export.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/story_structure/application/export_service.dart';
import 'package:museflow/features/story_structure/domain/export_bundle.dart';

import 'helpers/journey_container.dart';
```

**Core ExportService build pattern** -- use `lib/features/story_structure/application/export_service.dart` lines 51-131:
```dart
final exportService = ExportService(fileWriter: (_, __) async {});
final bundle = ExportBundle(
  schemaVersion: '1.0',
  exportedAt: DateTime.now(),
  manuscriptText: fullManuscriptText,
  chapters: chapterExports, // List<ChapterExport> with 100 items
  foreshadowingEntries: [],
  characterCards: [],
  worldSettings: [],
  skillDocuments: [],
);

// Markdown: 100 ## chapter headers
final md = exportService.buildMarkdown(bundle);
final mdChapterHeaders = RegExp(r'^## ', multiLine: true).allMatches(md);
expect(mdChapterHeaders.length, equals(100));

// TXT: no markdown syntax
final txt = exportService.buildTxt(bundle);
expect(txt, isNot(contains('##')));
expect(txt, isNot(contains('**')));

// JSON: parseable with 100 chapters
final json = exportService.buildJson(bundle);
final decoded = jsonDecode(json) as Map<String, dynamic>;
expect(decoded['chapters'], isA<List>());
expect((decoded['chapters'] as List).length, equals(100));
expect(decoded['schemaVersion'], equals('1.0'));
```

**ChapterExport construction** -- use `lib/features/manuscript/domain/chapter_export.dart` lines 5-13:
```dart
final chapterExports = chapters.map((ch) => ChapterExport(
  title: ch.title,
  sortOrder: ch.sortOrder,
  content: ch.documentContent,
)).toList();
```

---

### `test/journey/statistics_accuracy_test.dart` (test, CRUD)

**Analog:** `test/journey/serial_generation_test.dart`

This new test validates JOURNEY-10 (writing statistics accuracy and token audit completeness at 100-chapter scale). Follows the serial_generation_test.dart pattern for container setup and audit reading.

**Imports pattern** -- same as serial_generation_test.dart with stats-specific additions:
```dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/stats/domain/stats_snapshot.dart';

import 'helpers/journey_container.dart';
```

**Core audit flush + read pattern** -- use `test/journey/serial_generation_test.dart` lines 239-241:
```dart
await auditService.flush();
final auditRepository = await container.read(tokenAuditRepositoryProvider.future);
final snapshot = await auditRepository.buildSnapshot();

expect(snapshot.totalCalls, greaterThanOrEqualTo(100));
expect(snapshot.totalInputTokens, greaterThan(0));
expect(snapshot.totalOutputTokens, greaterThan(0));
```

**Per-record validation pattern** -- use `lib/features/stats/infrastructure/token_audit_repository.dart` lines 66-87:
```dart
final records = snapshot.records;
for (final record in records) {
  expect(record.inputTokens, greaterThan(0));
  expect(record.outputTokens, greaterThan(0));
  expect(record.operationType, isNotNull);
  expect(record.timestamp, isNotNull);
}
```

---

### `test/journey/helpers/story_outline.dart` (test helper, config) -- EXTEND

**Analog:** `test/journey/helpers/story_outline.dart` (itself)

Extend the existing `StoryOutline.chapters` list from 30 entries to 100 entries. The existing pattern at lines 8-41 shows the format: each entry is a 200-400 character plot summary string starting with the chapter number.

**Existing pattern to extend** -- `test/journey/helpers/story_outline.dart` lines 8-41:
```dart
class StoryOutline {
  static const List<String> chapters = [
    '第1章 凡人少年：林风是青云山脚下偏远山村的凡人少年...',
    // ... 30 existing entries ...
    '第30章 筑基：月光如水的夜晚，林风在青云峰顶服下筑基丹...',
    // ADD chapters 31-100 below following the same format
  ];

  static const List<String> characterNames = [
    '林风',
    '清虚真人',
    '苏雪晴',
    '赵天磊',
  ];
}
```

New chapters should follow the three-stage structure from D-01:
- Ch 31-60: Golden Core stage (with failed Core Formation attempt, retry)
- Ch 61-90: Nascent Soul stage (tribulation, inner demons)
- Ch 91-100: Ascension ending

---

### `test/journey/helpers/stage_prompts.dart` (test helper, config) -- NEW

**Analog:** `test/journey/helpers/xianxia_fixtures.dart`

A new helper file defining stage-specific prompt constants. Follow the static-const-class pattern from xianxia_fixtures.dart.

**Pattern to copy** -- `test/journey/helpers/xianxia_fixtures.dart` lines 10-13:
```dart
/// Stage-specific prompts for 100-chapter generation.
///
/// Per D-01: Three-stage story arc.
/// Per D-03: Each stage sets scene/theme for its chapter block.
class StagePrompts {
  /// Golden Core stage prompt for chapters 31-60.
  static const String goldenCore = '...';

  /// Nascent Soul stage prompt for chapters 61-90.
  static const String nascentSoul = '...';

  /// Ascension ending stage prompt for chapters 91-100.
  static const String ascension = '...';

  /// Returns the active stage prompt for the given chapter index (0-based).
  static String forChapterIndex(int index) {
    if (index < 30) return '';
    if (index < 60) return goldenCore;
    if (index < 90) return nascentSoul;
    return ascension;
  }
}
```

---

### `test/journey/serial_generation_test.dart` (test, CRUD+streaming) -- EXTEND

**Analog:** `test/journey/serial_generation_test.dart` (itself)

Extend the existing 30-chapter generation to support 100 chapters. Key changes:
1. Add a new test that generates chapters 31-100 (70 chapters) with stage prompts + previous-chapter summary injection
2. Update `_DeterministicJourneyAdapter._chapterText()` to use extended StoryOutline (100 entries instead of 30)
3. Add previous-chapter summary injection to `generateChapter()`

**Previous-chapter summary injection pattern** -- new code based on D-04:
```dart
// Inside generateChapter(), before building PromptContext:
String? previousSummary;
if (index > 0) {
  final chapters = chapterRepository.getByManuscriptId(manuscriptId);
  final sorted = chapters..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  if (index - 1 < sorted.length && sorted[index - 1].documentContent.isNotEmpty) {
    final prevContent = sorted[index - 1].documentContent;
    previousSummary = prevContent.length > 100
        ? '${prevContent.substring(0, 100)}...'
        : prevContent;
  }
}

final plotPoint = StoryOutline.chapters[index];
final stagePrompt = StagePrompts.forChapterIndex(index);
final contextText = [
  if (stagePrompt.isNotEmpty) stagePrompt,
  if (previousSummary != null) '上一章概要：$previousSummary',
  plotPoint,
].join('\n\n');
```

**Deterministic adapter update** -- modify `test/journey/serial_generation_test.dart` lines 446-452:
```dart
// Change from:
final chapterNo = (index % StoryOutline.chapters.length) + 1;
// To:
final chapterNo = index + 1;  // StoryOutline now has 100 entries, no wrap needed
```

**Safe error diagnostic** -- reuse existing pattern from `test/journey/serial_generation_test.dart` lines 287-306:
```dart
String _safeExceptionDiagnostic(Object error) {
  final sanitized = error
      .toString()
      .replaceAll(
        RegExp(r'authorization\s*[:=]\s*bearer\s+[^\s,}]+', caseSensitive: false),
        'Auth header [REDACTED]',
      )
      .replaceAll(
        RegExp(r'bearer\s+[^\s,}]+', caseSensitive: false),
        'Auth token [REDACTED]',
      )
      .replaceAll(
        RegExp(r'(api[_-]?key\s*[:=]\s*)[^\s,}]+', caseSensitive: false),
        r'$1[REDACTED]',
      );
  return '${error.runtimeType}: $sanitized';
}
```

---

### `test/journey/full_journey_test.dart` (test, CRUD+streaming) -- EXTEND

**Analog:** `test/journey/full_journey_test.dart` (itself)

Extend the E2E full journey test to cover 100 chapters. Same structural changes as serial_generation_test.dart: extend `_createThirtyChapters` to `_createHundredChapters`, update `_phaseDSerialGeneration` loop from 30 to 100, update timeout and assertions.

**Existing E2E phase structure to extend** -- `test/journey/full_journey_test.dart` lines 102-270:
- `_phaseAWorldBuilding()` -- unchanged
- `_phaseBFragmentSynthesis()` -- unchanged
- `_phaseCOpeningGuide()` -- unchanged
- `_phaseDSerialGeneration()` -- extend loop from 30 to 100, add stage prompt + summary injection
- `_phaseETokenAudit()` -- change assertion from `greaterThanOrEqualTo(31)` to `greaterThanOrEqualTo(101)`

**Deterministic adapter update** -- modify `test/journey/full_journey_test.dart` lines 406-412:
```dart
// Change from:
final chapterNo = (index % StoryOutline.chapters.length) + 1;
// To:
final chapterNo = index + 1;  // StoryOutline now has 100 entries
```

## Shared Patterns

### Journey Test Container Setup
**Source:** `test/journey/helpers/journey_container.dart`
**Apply to:** All 4 new test files

Every test file uses the same container lifecycle:
```dart
setUp(() async {
  container = await createJourneyContainer(
    apiKey: 'journey-local-test-key',  // deterministic path
    baseUrl: 'https://example.com/v1',
    model: 'fake-model',
    aiAdapter: FakeAdapter(),  // or real adapter for GLM tests
  );
});

tearDown(() async {
  await cleanupJourneyContainer(container);
});
```

Key detail from `journey_container.dart` lines 43-95: The helper opens 14 Hive boxes, registers 11 TypeAdapters, overrides 4 providers (openaiAdapterProvider, worldTemplateRepositoryProvider, activeProviderProvider, activeApiKeyProvider). New tests do NOT need to modify this helper.

### API Key Skip Pattern
**Source:** `test/journey/serial_generation_test.dart` lines 50-57
**Apply to:** foreshadowing_lifecycle_test.dart, statistics_accuracy_test.dart (any test that needs real GLM)

```dart
test(
  'test description',
  () async { /* ... */ },
  skip: apiKey == null ? 'GLM_API_KEY not set' : null,
  timeout: const Timeout(Duration(minutes: 20)),
);
```

Tests that only test deterministic services (FormatCleaner, ExportService, ForeshadowingNotifier) should NOT use the skip pattern -- they always run with FakeAdapter.

### Error Diagnostic Sanitization
**Source:** `test/journey/serial_generation_test.dart` lines 287-306
**Apply to:** All test files that catch and log exceptions

```dart
String _safeExceptionDiagnostic(Object error) {
  final sanitized = error
      .toString()
      .replaceAll(RegExp(r'authorization\s*[:=]\s*bearer\s+[^\s,}]+', caseSensitive: false), 'Auth header [REDACTED]')
      .replaceAll(RegExp(r'bearer\s+[^\s,}]+', caseSensitive: false), 'Auth token [REDACTED]')
      .replaceAll(RegExp(r'(api[_-]?key\s*[:=]\s*)[^\s,}]+', caseSensitive: false), r'$1[REDACTED]');
  return '${error.runtimeType}: $sanitized';
}
```

### Chapter Creation Helper
**Source:** `test/journey/serial_generation_test.dart` lines 343-365
**Apply to:** Any test that needs to create chapters in the repository

```dart
Future<List<Chapter>> _createChapters(
  dynamic chapterRepository,
  String manuscriptId,
  int count,  // was hardcoded to 30, now parameterized
) async {
  final chapters = <Chapter>[];
  for (var i = 1; i <= count; i++) {
    final plotPoint = StoryOutline.chapters[i - 1];
    final titleEnd = min(10, plotPoint.length);
    final chapter = await chapterRepository.add(
      Chapter(
        id: '',
        manuscriptId: manuscriptId,
        title: '第$i章 ${plotPoint.substring(0, titleEnd)}',
        sortOrder: i,
        documentContent: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    chapters.add(chapter);
  }
  return chapters;
}
```

### Audit Flush Before Read
**Source:** `test/journey/serial_generation_test.dart` line 239
**Apply to:** statistics_accuracy_test.dart, serial_generation_test.dart (extended)

```dart
// CRITICAL: Always flush before reading audit data
await auditService.flush();
final auditRepository = await container.read(tokenAuditRepositoryProvider.future);
final snapshot = await auditRepository.buildSnapshot();
```

### enforceD11Bounds Post-Processing
**Source:** `test/journey/helpers/d11_bounds.dart`
**Apply to:** serial_generation_test.dart and full_journey_test.dart (extended)

```dart
import 'helpers/d11_bounds.dart';
// ...
final boundedOutput = enforceD11Bounds(output);
```

Every chapter generated (deterministic or real GLM) must go through enforceD11Bounds per inherited D-11. The function is 48 lines, pure Dart, no changes needed.

## No Analog Found

All 8 files have strong analogs in the existing codebase. No files require patterns from RESEARCH.md alone.

## Metadata

**Analog search scope:** `test/journey/`, `test/automation/helpers/`, `lib/features/story_structure/`, `lib/features/stats/`, `lib/features/knowledge/`, `lib/features/manuscript/`, `lib/features/ai/`
**Files scanned:** 18 (8 test files + 10 production service/entity files)
**Pattern extraction date:** 2026-06-08
