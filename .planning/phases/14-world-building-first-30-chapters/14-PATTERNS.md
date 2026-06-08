# Phase 14: World-Building & First 30 Chapters - Pattern Map

**Mapped:** 2026-06-07
**Files analyzed:** 9 new files + 0 modified files
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `test/journey/helpers/journey_container.dart` | utility | request-response | `test/automation/helpers/test_container.dart` | exact |
| `test/journey/helpers/xianxia_fixtures.dart` | utility | CRUD | `test/automation/fixtures/manuscript_fixtures.dart` | exact |
| `test/journey/helpers/story_outline.dart` | utility | CRUD | `test/automation/fixtures/xianxia_content.dart` | exact |
| `test/journey/world_building_test.dart` | test | CRUD | `test/automation/core_flow_test.dart` (Segments 1-3) | role-match |
| `test/journey/fragment_synthesis_test.dart` | test | request-response | `test/automation/core_flow_test.dart` (Segments 4-5) | role-match |
| `test/journey/opening_guide_test.dart` | test | request-response | `test/automation/core_flow_test.dart` (Segment 4) | role-match |
| `test/journey/chapter_management_test.dart` | test | CRUD | `test/automation/core_flow_test.dart` (Segments 2-3) | exact |
| `test/journey/serial_generation_test.dart` | test | streaming | `test/automation/core_flow_test.dart` (E2E) | exact |
| `test/journey/full_journey_test.dart` | test | streaming | `test/automation/core_flow_test.dart` (E2E) | exact |

## Pattern Assignments

### `test/journey/helpers/journey_container.dart` (utility, request-response)

**Analog:** `test/automation/helpers/test_container.dart`

**Imports pattern** (analog lines 1-8):
```dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/presentation/providers.dart';
```

**Core pattern** (analog lines 10-24):
```dart
Future<ProviderContainer> createTestContainer() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final tempDir = Directory.systemTemp.createTempSync('automation_test_');
  Hive.init(tempDir.path);

  await Hive.openBox<dynamic>('manuscripts');
  await Hive.openBox<dynamic>('chapters');
  await Hive.openBox<dynamic>('token_audit');
  await Hive.openBox<dynamic>('ai_providers');
  await Hive.openBox<dynamic>('fragments');

  return ProviderContainer(
    overrides: [openaiAdapterProvider.overrideWithValue(FakeAdapter())],
  );
}

Future<void> cleanupTestContainer(ProviderContainer container) async {
  container.dispose();
  await Hive.deleteFromDisk();
}
```

**Journey-specific adaptations required:**
1. Replace `FakeAdapter()` with `OpenAIAdapter()` -- the real adapter for GLM API calls
2. Add 10+ additional Hive boxes required by knowledge/feature providers:
   - `character_cards`, `world_settings`, `skill_documents` (knowledge base)
   - `writing_stats`, `daily_writing_stats`, `achievement_badges` (stats)
   - `plot_nodes`, `foreshadowing_entries`, `graph_positions`, `guardian_annotations` (story structure)
3. Override `activeProviderProvider` with a real `AIProvider` configured for GLM (baseUrl + model)
4. Override `activeApiKeyProvider` with the real GLM API key passed as parameter
5. Do NOT override `settingsRepositoryProvider` -- it requires `SecureStorageService` which fails in test context (Pitfall 6 in RESEARCH.md)
6. Provider IDs to use: `openaiAdapterProvider`, `activeProviderProvider`, `activeApiKeyProvider` (from `lib/core/presentation/providers.dart` lines 163-185)

**Key provider override pattern** (from `lib/core/presentation/providers.dart` lines 163-185):
```dart
final activeProviderProvider = Provider<AIProvider?>((ref) {
  final serviceAsync = ref.watch(providerServiceProvider);
  return serviceAsync.asData?.value.getActiveProvider();
});

final activeApiKeyProvider = Provider<String?>((ref) {
  final apiKeyAsync = ref.watch(apiKeyFutureProvider);
  return apiKeyAsync.asData?.value;
});

final openaiAdapterProvider = Provider<AIAdapter>((ref) {
  return OpenAIAdapter();
});
```

---

### `test/journey/helpers/xianxia_fixtures.dart` (utility, CRUD)

**Analog:** `test/automation/fixtures/manuscript_fixtures.dart`

**Imports pattern** (analog lines 1-2):
```dart
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
```

**Core fixture pattern** (analog lines 4-37):
```dart
class ManuscriptFixtures {
  static final DateTime _fixedDate = DateTime(2026, 1, 1);

  static Manuscript xianxiaManuscript({String? id}) {
    return Manuscript(
      id: id ?? 'ms-test-001',
      title: '剑道苍穹',
      description: '自动化测试用修仙文稿',
      genre: '修仙',
      targetWordCount: 100000,
      status: '写作中',
      createdAt: _fixedDate,
      updatedAt: _fixedDate,
      coverLetter: '剑',
    );
  }

  static Chapter chapter({
    required String manuscriptId,
    required int number,
    String? content,
  }) {
    return Chapter(
      id: 'ch-$number',
      manuscriptId: manuscriptId,
      title: '第$number章',
      sortOrder: number,
      status: '草稿',
      documentContent: content ?? '',
      createdAt: _fixedDate,
      updatedAt: _fixedDate,
    );
  }
}
```

**Journey-specific fixtures to create (based on domain models):**

CharacterCard fixture -- copy the pattern from `CharacterCard` constructor (`lib/features/knowledge/domain/character_card.dart` lines 27-85):
```dart
import 'package:museflow/features/knowledge/domain/character_card.dart';
// Fixture:
CharacterCard({
  required this.id,
  required this.name,
  this.personality = '',
  this.appearance = '',
  this.backstory = '',
  this.aliases = const [],
  required this.createdAt,
  this.updatedAt,
})
```

WorldSetting fixture -- copy pattern from `WorldSetting` constructor (`lib/features/knowledge/domain/world_setting.dart` lines 29-103):
```dart
import 'package:museflow/features/knowledge/domain/world_setting.dart';
// Fixture:
WorldSetting({
  required this.id,
  required this.name,
  this.description = '',
  this.rules = '',
  this.factions = '',
  this.geography = '',
  this.techLevel = '',
  this.aliases = const [],
  required this.createdAt,
  this.updatedAt,
})
```

SkillDocument fixture -- copy pattern from `SkillDocument` constructor (`lib/features/knowledge/domain/skill_document.dart` lines 155-172):
```dart
import 'package:museflow/features/knowledge/domain/skill_document.dart';
// Fixture:
SkillDocument({
  required this.id,
  required this.name,
  required this.description,
  required this.content,
  required this.sections,
  this.isActive = false,
  required this.createdAt,
  this.updatedAt,
})
```

---

### `test/journey/helpers/story_outline.dart` (utility, CRUD)

**Analog:** `test/automation/fixtures/xianxia_content.dart`

**Core pattern** (analog lines 5-39):
```dart
class XianxiaContent {
  static const List<String> synthesis = [
    '林风立于青云峰巅，剑气纵横三千里。今日筑基大成，他日必证金丹大道。',
    '...',
  ];

  static const Map<String, List<String>> responses = {
    'synthesis': synthesis,
    'rewrite': rewrite,
    'polish': polish,
    'freeInput': freeInput,
  };
}
```

**Journey-specific content:**
Instead of deterministic response strings, this file should provide:
- 30-chapter plot outline: `List<String>` with each entry being a chapter plot point (300-500 chars each)
- Character names and key terms for assertion checks
- Follows the same `static const` pattern but with story data

---

### `test/journey/world_building_test.dart` (test, CRUD)

**Analog:** `test/automation/core_flow_test.dart` (Segments 1-3: Manuscript + Chapter CRUD)

**Test structure pattern** (analog lines 18-28, 29-109):
```dart
void main() {
  late ProviderContainer container;

  setUp(() async {
    container = await createTestContainer();
  });

  tearDown(() async {
    await cleanupTestContainer(container);
  });

  group('Segment 1: Manuscript CRUD', () {
    test('should create, read, update, and delete manuscript', () async {
      final repository = await container.read(
        manuscriptRepositoryProvider.future,
      );
      // ... assertions
    });
  });
}
```

**Journey-specific integration points:**
1. Use `createJourneyContainer()` instead of `createTestContainer()`
2. Create WorldSetting via `worldSettingRepositoryProvider` -> `WorldSettingRepository.add()` (`lib/features/knowledge/infrastructure/world_setting_repository.dart` line 21)
3. Create CharacterCards via `characterCardRepositoryProvider` -> `CharacterCardRepository.add()` (`lib/features/knowledge/infrastructure/character_card_repository.dart` line 21)
4. Create SkillDocuments via `skillRepositoryProvider` -> `SkillRepository.add()` (`lib/features/knowledge/infrastructure/skill_repository.dart` line 11)
5. Refresh NameIndex after all entities created: `container.read(nameIndexServiceProvider.notifier).refresh()` (`lib/features/knowledge/application/name_index_service.dart` line 36)
6. Verify knowledge injection works by checking `NameIndex.findMatches()` returns matches for character names

**Repository access pattern** (consistent across all repositories):
```dart
final repo = await container.read(someRepositoryProvider.future);
final entity = await repo.add(SomeEntity(...));
final retrieved = repo.getById(entity.id);
expect(retrieved, isNotNull);
```

---

### `test/journey/fragment_synthesis_test.dart` (test, request-response)

**Analog:** `test/automation/core_flow_test.dart` (Segments 4-5: AI generation)

**AI call pattern** (analog lines 111-130):
```dart
final adapter = container.read(openaiAdapterProvider);
Usage? capturedUsage;

final text = await adapter
    .createStream(
      apiKey: 'fake-key-for-testing',
      baseUrl: 'http://localhost:11434/v1',
      model: 'fake-model',
      messages: [ChatMessage.user('碎片：林风在青云峰悟剑')],
      onUsage: (usage) => capturedUsage = usage,
    )
    .join();
```

**Journey-specific integration:**
1. Use real GLM API credentials from container (apiKey, baseUrl, model)
2. Create fragments via `fragmentRepositoryProvider` -> `FragmentRepository.addFragment()` (`lib/core/infrastructure/fragment_repository.dart` line 19)
3. Use `PromptPipeline` for prompt assembly (`lib/features/ai/application/prompt_pipeline.dart` line 192):
   ```dart
   final pipeline = await container.read(promptPipelineProvider.future);
   final context = PromptContext(fragments: fragments, bannedPhrases: []);
   final messages = pipeline.build(context);
   ```
4. Call real `OpenAIAdapter.createStream()` with pipeline-built messages
5. Record audit via `tokenAuditServiceProvider` -> `TokenAuditService.recordAudit()` (`lib/features/stats/application/token_audit_service.dart` line 35)
6. Verify output contains expected content (not FakeAdapter deterministic strings)
7. Flush audit: `await auditService.flush()` (line 70)

---

### `test/journey/opening_guide_test.dart` (test, request-response)

**Analog:** `test/automation/core_flow_test.dart` (Segment 4: AI generation single chapter)

**OpeningGeneratorService usage pattern** (from `lib/features/onboarding/application/opening_generator_service.dart` lines 75-148):
```dart
final service = await container.read(openingGeneratorServiceProvider.future);
final variants = await service.generateOpenings(
  genreName: '修仙',
  worldDescription: '青云山修仙世界...',
  characterDescription: '林风，凡人少年...',
  storyConcept: '凡人少年入门修仙的成长之路',
  manuscriptId: manuscript.id,
);
expect(variants, hasLength(3));
expect(variants.map((v) => v.style), containsAll(['scene', 'character', 'suspense']));
```

**Key provider** (from `lib/core/presentation/providers.dart` lines 436-450):
```dart
final openingGeneratorServiceProvider = FutureProvider<OpeningGeneratorService>(
  (ref) async {
    final provider = ref.watch(activeProviderProvider);
    final apiKey = ref.watch(activeApiKeyProvider);
    if (provider == null || apiKey == null || apiKey.isEmpty) {
      throw StateError('未配置可用的 AI 模型');
    }
    return OpeningGeneratorService(
      openAIAdapter: ref.watch(openaiAdapterProvider),
      apiKey: apiKey,
      baseUrl: provider.baseUrl,
      model: provider.model,
    );
  },
);
```
Note: This provider requires `activeProviderProvider` and `activeApiKeyProvider` to be non-null -- they must be overridden in the journey container.

---

### `test/journey/chapter_management_test.dart` (test, CRUD)

**Analog:** `test/automation/core_flow_test.dart` (Segments 2-3: Chapter CRUD + Sorting)

**Chapter CRUD pattern** (analog lines 52-109):
```dart
group('Segment 2: Chapter CRUD', () {
  test('should create, read, update, and delete chapters', () async {
    final chapterRepository = await container.read(
      chapterRepositoryProvider.future,
    );
    for (var i = 1; i <= 3; i++) {
      await chapterRepository.add(
        ManuscriptFixtures.chapter(manuscriptId: manuscript.id, number: i),
      );
    }
    var chapters = chapterRepository.getByManuscriptId(manuscript.id);
    expect(chapters.map((chapter) => chapter.sortOrder), [1, 2, 3]);
  });
});
```

**Journey-specific operations:**
1. Create 30 chapters in a loop (same pattern, just `i <= 30`)
2. Reorder: update `sortOrder` on chapters via `chapterRepository.update()`
3. Split: create two new chapters from one, delete original
4. Merge: combine two chapters into one, delete the other
5. Copy: create a new chapter with same content
6. Delete: `chapterRepository.delete(id)`
7. All operations via `ChapterRepository` (`lib/features/manuscript/infrastructure/chapter_repository.dart`)
8. Content update: `chapterRepository.updateDocumentContent(id, markdown)` (line 94)

---

### `test/journey/serial_generation_test.dart` (test, streaming)

**Analog:** `test/automation/core_flow_test.dart` (E2E: 100-chapter full flow)

**Serial generation with audit pattern** (analog lines 236-298):
```dart
group('E2E: 100-chapter full flow', () {
  test('should create 100 chapters, generate content, export, and audit',
    () async {
    final adapter = container.read(openaiAdapterProvider);
    final auditService = await container.read(
      tokenAuditServiceProvider.future,
    );
    // Create chapters
    for (var i = 1; i <= 100; i++) {
      final chapter = await chapterRepository.add(/*...*/);
      final output = await _generateAndAudit(/*...*/);
      await chapterRepository.updateDocumentContent(chapter.id, output);
    }
    // Verify
    await auditService.flush();
    final snapshot = await auditRepository.buildSnapshot();
    expect(snapshot.totalCalls, 100);
  }, timeout: const Timeout(Duration(minutes: 5)));
});
```

**Journey-specific adaptations:**
1. Use 30 chapters instead of 100
2. Use real GLM API (not FakeAdapter) -- `adapter.createStream()` with real credentials
3. Add `Future.delayed(Duration(seconds: 3))` between API calls (D-03 rate limiting)
4. Build prompts via `PromptPipeline` for knowledge injection + Skill enforcement
5. Run deviation detection after each chapter: `DeviationDetectionService.detectDeviations()` (`lib/features/knowledge/application/deviation_detection_service.dart` line 65)
6. Stop-on-error: any failure throws immediately (D-04)
7. Flush audit before verification: `await auditService.flush()` (`lib/features/stats/application/token_audit_service.dart` line 70)

**Token audit recording pattern** (analog lines 327-355):
```dart
Future<String> _generateAndAudit({
  required AIAdapter adapter,
  required TokenAuditService auditService,
  required String manuscriptId,
  required String? chapterId,
  required String inputText,
}) async {
  Usage? capturedUsage;
  final output = await adapter
      .createStream(/*...*/)
      .join();

  auditService.recordAudit(
    usage: capturedUsage,
    modelName: 'fake-model',
    operationType: AuditOperationType.synthesis,
    manuscriptId: manuscriptId,
    chapterId: chapterId,
    inputText: inputText,
    outputText: output,
  );
  return output;
}
```

---

### `test/journey/full_journey_test.dart` (test, streaming)

**Analog:** `test/automation/core_flow_test.dart` (E2E: 100-chapter full flow)

This file follows the same E2E pattern as `serial_generation_test.dart` but chains ALL journey phases:
1. World-building (from `world_building_test.dart`)
2. Fragment capture + synthesis (from `fragment_synthesis_test.dart`)
3. Opening guide 3 styles (from `opening_guide_test.dart`)
4. 30 chapter creation + serial AI generation (from `serial_generation_test.dart`)
5. Token audit verification (flush + snapshot assertions)

**Structure:** Single large test with sequential phases, `timeout: Timeout(Duration(minutes: 10))`.

---

## Shared Patterns

### ProviderContainer Setup with Real API
**Source:** `test/automation/helpers/test_container.dart` + `lib/core/presentation/providers.dart`
**Apply to:** `journey_container.dart`
```dart
// Pattern: Override activeProvider + activeApiKey so all dependent services work
return ProviderContainer(
  overrides: [
    openaiAdapterProvider.overrideWithValue(OpenAIAdapter()),
    activeProviderProvider.overrideWithValue(AIProvider(
      id: 'glm-journey',
      name: 'GLM',
      baseUrl: baseUrl,    // from parameter
      model: model,        // from parameter
      temperature: 0.8,
      topP: 0.9,
    )),
    activeApiKeyProvider.overrideWithValue(apiKey),  // from parameter
  ],
);
```

### Hive Box Initialization
**Source:** `test/automation/helpers/test_container.dart` lines 13-19 + `lib/core/presentation/providers.dart`
**Apply to:** `journey_container.dart`
```dart
// Phase 13 opens 5 boxes. Phase 14 needs all boxes used by providers.dart.
final boxes = [
  'manuscripts', 'chapters', 'token_audit', 'ai_providers', 'fragments',
  'character_cards', 'world_settings', 'skill_documents',
  'writing_stats', 'daily_writing_stats', 'achievement_badges',
  'plot_nodes', 'foreshadowing_entries', 'graph_positions',
  'guardian_annotations',
];
for (final name in boxes) {
  await Hive.openBox<dynamic>(name);
}
```

### Repository Access via ProviderContainer
**Source:** `test/automation/core_flow_test.dart` (consistent across all segments)
**Apply to:** All test files
```dart
// Async providers must be awaited
final repo = await container.read(repositoryProvider.future);
// Sync operations on the repository
final entity = await repo.add(Entity(...));
final retrieved = repo.getById(entity.id);
expect(retrieved, isNotNull);
```

### Error Handling (Stop-on-Error)
**Source:** `test/automation/core_flow_test.dart` (E2E test pattern)
**Apply to:** `serial_generation_test.dart`, `full_journey_test.dart`
```dart
// D-04: Any failure stops the entire process
for (var i = 0; i < 30; i++) {
  try {
    // ... AI call + save
  } catch (e) {
    // Log error and rethrow (stop-on-error)
    print('[ERROR] Chapter ${i + 1} failed: $e');
    rethrow;
  }
  await Future.delayed(Duration(seconds: 3)); // D-03 rate limit
}
```

### Token Audit Flush Before Verification
**Source:** `lib/features/stats/application/token_audit_service.dart` lines 70-81
**Apply to:** All tests that verify audit data
```dart
// ALWAYS flush before reading snapshot
await auditService.flush();
final snapshot = await auditRepository.buildSnapshot();
expect(snapshot.totalCalls, expectedCount);
expect(snapshot.totalInputTokens, greaterThan(0));
```

### NameIndex Refresh After Entity Creation
**Source:** `lib/features/knowledge/application/name_index_service.dart` lines 36-38
**Apply to:** `world_building_test.dart`, any test that creates knowledge entities
```dart
// After creating character cards, world settings, and skill documents:
container.read(nameIndexServiceProvider.notifier).refresh();
// Now KnowledgeInjectionMiddleware will find matches
```

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| (none) | -- | -- | All files have strong analogs in Phase 13's test infrastructure |

All 9 files have exact or role-match analogs in the existing codebase. The primary adaptation is replacing `FakeAdapter` with real `OpenAIAdapter` + GLM API configuration.

## Metadata

**Analog search scope:** `test/automation/`, `lib/core/presentation/`, `lib/features/ai/`, `lib/features/knowledge/`, `lib/features/manuscript/`, `lib/features/stats/`, `lib/features/onboarding/`, `lib/features/templates/`
**Files scanned:** 22 source files
**Pattern extraction date:** 2026-06-07
