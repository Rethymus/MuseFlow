# Phase 13: Automation Test Harness - Pattern Map

**Mapped:** 2026-06-07
**Files analyzed:** 14 new/modified files
**Analogs found:** 13 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/features/ai/domain/ai_adapter.dart` | model (interface) | streaming | `lib/features/ai/infrastructure/openai_adapter.dart` | exact |
| `lib/features/ai/infrastructure/openai_adapter.dart` | infrastructure | streaming | itself (refactor target) | exact |
| `lib/core/presentation/providers.dart` | config | request-response | itself (type change only) | exact |
| `test/automation/helpers/fake_adapter.dart` | test helper | streaming | `lib/features/ai/infrastructure/openai_adapter.dart` | role-match |
| `test/automation/helpers/test_container.dart` | test helper | request-response | `test/helpers/hive_test_helper.dart` | role-match |
| `test/automation/fixtures/xianxia_content.dart` | test fixture | transform | `lib/features/stats/domain/audit_operation_type.dart` | partial |
| `test/automation/fixtures/manuscript_fixtures.dart` | test fixture | CRUD | `lib/features/manuscript/domain/manuscript.dart` | partial |
| `test/automation/core_flow_test.dart` | test | CRUD + streaming | `test/features/stats/infrastructure/token_audit_repository_test.dart` | role-match |
| `test/automation/helpers/fake_adapter_test.dart` | test | streaming | `test/features/stats/infrastructure/token_audit_repository_test.dart` | role-match |
| `integration_test/manuscript_flow_test.dart` | test (integration) | request-response | `integration_test/app_test.dart` | exact |
| `lib/features/manuscript/presentation/manuscript_create_dialog.dart` | component (modify) | request-response | itself (key additions) | exact |
| `lib/features/manuscript/presentation/chapter_sidebar.dart` | component (modify) | request-response | itself (key addition) | exact |
| `lib/features/manuscript/presentation/chapter_create_dialog.dart` | component (modify) | request-response | itself (key addition) | exact |
| `lib/features/editor/presentation/floating_toolbar.dart` | component (modify) | request-response | itself (key addition) | exact |
| `lib/features/story_structure/presentation/export_dialog.dart` | component (modify) | request-response | itself (key addition) | exact |

## Pattern Assignments

### `lib/features/ai/domain/ai_adapter.dart` (model/interface, streaming)

**Analog:** `lib/features/ai/infrastructure/openai_adapter.dart`

This is an interface extracted from OpenAIAdapter. The `createStream` method signature must match exactly.

**Imports pattern** (from openai_adapter.dart lines 1-16):
```dart
import 'dart:async';
import 'package:openai_dart/openai_dart.dart';
```

**Core interface pattern** (extracted from openai_adapter.dart lines 43-52):
```dart
/// Abstract interface for AI streaming adapters.
///
/// Implementations: OpenAIAdapter (production), FakeAdapter (testing).
/// Per D-01: Extracted from OpenAIAdapter to enable test doubles.
abstract class AIAdapter {
  /// Creates a stream of text deltas from an AI API.
  ///
  /// Parameters match OpenAIAdapter.createStream exactly.
  Stream<String> createStream({
    required String apiKey,
    required String baseUrl,
    required String model,
    required List<ChatMessage> messages,
    double? temperature,
    double? topP,
    int? maxTokens,
    void Function(Usage?)? onUsage,
  });
}
```

**Note:** The interface does NOT include `fetchModelList`, `dispose`, or `isActive` -- those are OpenAIAdapter-specific concerns. Per CONTEXT D-01, only `createStream()` is on the interface.

---

### `lib/features/ai/infrastructure/openai_adapter.dart` (infrastructure, streaming)

**Analog:** itself (refactor -- add `implements AIAdapter`)

**Change pattern** (line 23):
```dart
// Before:
class OpenAIAdapter {
// After:
class OpenAIAdapter implements AIAdapter {
```

**Required import addition** (top of file):
```dart
import 'package:museflow/features/ai/domain/ai_adapter.dart';
```

No other changes needed -- `createStream` already has the correct signature. The class just needs to declare conformance.

---

### `lib/core/presentation/providers.dart` (config, request-response)

**Analog:** itself (type change at lines 179-185)

**Change pattern** (lines 179-185):
```dart
// Before:
/// Provides a singleton [OpenAIAdapter] for streaming AI completions.
final openaiAdapterProvider = Provider<OpenAIAdapter>((ref) {
  return OpenAIAdapter();
});

// After:
/// Provides a singleton [AIAdapter] for streaming AI completions.
///
/// Per D-01: Typed as [AIAdapter] so tests can override with FakeAdapter.
final openaiAdapterProvider = Provider<AIAdapter>((ref) {
  return OpenAIAdapter();
});
```

**Required import addition** (top of file):
```dart
import 'package:museflow/features/ai/domain/ai_adapter.dart';
```

**Downstream impact:** All consumers already use `ref.read(openaiAdapterProvider)` and call `createStream()` -- they are unaffected because the interface method signature is identical.

---

### `test/automation/helpers/fake_adapter.dart` (test helper, streaming)

**Analog:** `lib/features/ai/infrastructure/openai_adapter.dart`

**Imports pattern** (from openai_adapter.dart):
```dart
import 'dart:async';
import 'package:museflow/features/ai/domain/ai_adapter.dart';
import 'package:openai_dart/openai_dart.dart';
```

**Core pattern** -- mirror OpenAIAdapter's createStream signature and onUsage behavior (from openai_adapter.dart lines 43-92):

Key behaviors to replicate:
1. `async*` generator yielding characters (openai_adapter.dart line 73: `client.chat.completions.createStream().map()`)
2. `onUsage` called on stream completion (openai_adapter.dart lines 84-91: `StreamTransformer.handleDone` calls `onUsage?.call(accumulator.usage)`)
3. Error classification into AIException (openai_adapter.dart lines 97-133: `classifyException`)

**FakeAdapter skeleton** (based on CONTEXT D-03 and UI-SPEC output contract):
```dart
class FakeAdapter implements AIAdapter {
  final double? errorRate;
  final String? errorText;
  final bool emptyResponse;

  // Default constructor: no errors
  // Error constructor: FakeAdapter(errorRate: 0.5, errorText: '网络异常')

  @override
  Stream<String> createStream({...}) async* {
    // 1. Check error conditions (errorRate, errorText, emptyResponse)
    // 2. Detect operation type from messages content
    // 3. Yield characters from deterministic xianxia responses
    // 4. Call onUsage?.call(usage) AFTER all characters yielded
  }
}
```

**Token estimation formula** (from UI-SPEC):
```dart
int _estimateTokens(String text) {
  return text.replaceAll(RegExp(r'\s'), '').length * 2;
}
```

**onUsage callback pattern** (mirrors openai_adapter.dart lines 84-91):
```dart
// Must be called after stream completes, just like OpenAIAdapter's
// StreamTransformer<String, String>.fromHandlers(handleDone: ...)
if (onUsage != null) {
  onUsage(Usage(
    promptTokens: _estimateTokens(messages.map((m) {
      // Extract content from ChatMessage
    }).join()),
    completionTokens: _estimateTokens(response),
  ));
}
```

**Deterministic response map** (from UI-SPEC FakeAdapter Output Contract):
```dart
static const Map<String, List<String>> _responses = {
  'synthesis': [
    '林风立于青云峰巅，剑气纵横三千里。今日筑基大成，他日必证金丹大道。',
    '破晓时分，灵气如潮涌入丹田。她缓缓睁眼，眸中闪过一道金光——练气九层，终于突破！',
    '古洞深处，一枚玉简静静悬浮。其上篆刻着"九霄剑诀"四字，散发出令人心悸的威压。',
  ],
  'rewrite': [
    '剑光一闪，血溅三尺。他面无表情地收剑入鞘，转身踏入风雪之中。',
    '灵力汇聚掌心，化作一道青色光柱直冲云霄。天地为之变色，雷云滚滚而来。',
  ],
  'polish': [
    '他深吸一口气，缓缓运转《玄天功》。丹田内灵力如江河奔涌，沿着经脉游走周天，最终汇聚于气海。',
    '月华如水，洒在剑身之上。她持剑而立，衣袂飘飘，宛若谪仙临尘。',
  ],
  'freeInput': [
    '此剑名为"斩仙"，乃上古仙人遗留之物。持之者可破万法，斩因果，逆天改命。',
  ],
};
```

---

### `test/automation/helpers/test_container.dart` (test helper, request-response)

**Analog:** `test/helpers/hive_test_helper.dart`

**Imports pattern** (from hive_test_helper.dart):
```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
```

**Core pattern** -- combines Hive setup (from hive_test_helper.dart) with ProviderContainer overrides (from providers.dart lines 179-185):

```dart
/// Creates a ProviderContainer with FakeAdapter override for testing.
///
/// Opens required Hive boxes before creating the container.
/// Caller must call container.dispose() in tearDown.
Future<ProviderContainer> createTestContainer() async {
  // 1. Initialize Hive to temp directory (from hive_test_helper.dart pattern)
  TestWidgetsFlutterBinding.ensureInitialized();
  final tempDir = Directory.systemTemp.createTempSync('automation_test_');
  Hive.init(tempDir.path);

  // 2. Open all required Hive boxes (from providers.dart provider dependencies)
  await Hive.openBox<dynamic>('manuscripts');
  await Hive.openBox<dynamic>('chapters');
  await Hive.openBox<dynamic>('token_audit');
  await Hive.openBox<dynamic>('ai_providers');
  await Hive.openBox<Fragment>('fragments');

  // 3. Create container with FakeAdapter override
  return ProviderContainer(
    overrides: [
      openaiAdapterProvider.overrideWithValue(FakeAdapter()),
    ],
  );
}
```

**Cleanup pattern** (from hive_test_helper.dart lines 14-18):
```dart
Future<void> cleanupTestContainer(ProviderContainer container) async {
  container.dispose();
  await Hive.deleteFromDisk();
}
```

---

### `test/automation/fixtures/xianxia_content.dart` (test fixture, transform)

**Analog:** `lib/features/stats/domain/audit_operation_type.dart`

Follows the same pattern as AuditOperationType -- static const data organized by operation type.

```dart
/// Deterministic xianxia genre test content.
///
/// Per UI-SPEC: Fixed strings for each operation type.
/// Tests assert against known substrings (e.g., '林风', '筑基', '剑光').
class XianxiaContent {
  static const List<String> synthesis = [...];
  static const List<String> rewrite = [...];
  static const List<String> polish = [...];
  static const List<String> freeInput = [...];

  /// Assertable substrings per operation type (from UI-SPEC assertion patterns).
  static const Map<String, List<String>> assertableSubstrings = {
    'synthesis': ['林风', '筑基'],
    'rewrite': ['剑光'],
    'polish': ['灵力', '月华'],
  };
}
```

---

### `test/automation/fixtures/manuscript_fixtures.dart` (test fixture, CRUD)

**Analog:** `lib/features/manuscript/domain/manuscript.dart` and `lib/features/manuscript/domain/chapter.dart`

Follows the same constructor pattern as Manuscript and Chapter entities.

```dart
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';

class ManuscriptFixtures {
  static Manuscript xianxiaManuscript({String? id}) => Manuscript(
    id: id ?? 'ms-test-001',
    title: '剑道苍穹',
    genre: '修仙',
    targetWordCount: 100000,
    status: '写作中',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  static Chapter chapter({
    required String manuscriptId,
    required int number,
    String? content,
  }) => Chapter(
    id: 'ch-$number',
    manuscriptId: manuscriptId,
    title: '第${number}章',
    sortOrder: number,
    status: '草稿',
    documentContent: content ?? '',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}
```

---

### `test/automation/core_flow_test.dart` (test, CRUD + streaming)

**Analog:** `test/features/stats/infrastructure/token_audit_repository_test.dart`

**Imports pattern** (from token_audit_repository_test.dart):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
```

**Test structure pattern** (from token_audit_repository_test.dart lines 7-22):
```dart
void main() {
  setUp(() async {
    // Initialize Hive + create ProviderContainer
  });

  tearDown(() async {
    // Dispose container + Hive.deleteFromDisk()
  });

  group('Segment 1: Manuscript CRUD', () {
    test('should create and retrieve manuscript', () async {
      // Arrange: use ManuscriptFixtures
      // Act: call repository.add()
      // Assert: repository.getAll() returns manuscript
    });
  });

  // ... 7 more segments + 1 E2E test
}
```

**E2E test timeout pattern** (from CONTEXT D-05):
```dart
test('E2E: 100-chapter full flow', () async {
  // ... create manuscript -> 100 chapters -> 100 AI calls -> export -> audit verify
}, timeout: const Timeout(Duration(minutes: 5)));
```

**Repository access pattern** (from providers.dart):
```dart
// All repositories are FutureProvider, so:
final manuscriptRepo = await container.read(manuscriptRepositoryProvider.future);
final chapterRepo = await container.read(chapterRepositoryProvider.future);
final auditRepo = await container.read(tokenAuditRepositoryProvider.future);
```

**Export verification pattern** (from export_service.dart lines 108-122):
```dart
final exportService = container.read(exportServiceProvider);
final bundle = ExportBundle(
  schemaVersion: '1.0',
  manuscriptText: '',
  chapters: chapters.map((c) => ChapterExport(
    title: c.title,
    sortOrder: c.sortOrder,
    content: c.documentContent,
  )).toList(),
);
final markdown = exportService.buildMarkdown(bundle);
expect(markdown, contains('## 第1章'));
expect(markdown, contains('## 第100章'));
```

**Token audit verification pattern** (from token_audit_repository.dart lines 22-31):
```dart
// Must flush TokenAuditService before reading (30s debounce)
final auditService = await container.read(tokenAuditServiceProvider.future);
await auditService.flush();

final snapshot = await auditRepo.buildSnapshot();
expect(snapshot.totalCalls, 100);
expect(snapshot.totalInputTokens, greaterThan(0));
expect(snapshot.totalOutputTokens, greaterThan(0));
```

---

### `test/automation/helpers/fake_adapter_test.dart` (test, streaming)

**Analog:** `test/features/stats/infrastructure/token_audit_repository_test.dart`

Same test structure pattern. Tests FakeAdapter in isolation:

```dart
void main() {
  group('FakeAdapter', () {
    test('should return deterministic synthesis text', () async {
      final adapter = FakeAdapter();
      final tokens = <String>[];
      await for (final token in adapter.createStream(
        apiKey: 'test', baseUrl: 'https://test', model: 'test',
        messages: [ChatMessage(...)], // with '碎片' content
        onUsage: null,
      )) {
        tokens.add(token);
      }
      expect(tokens.join(), contains('林风'));
    });

    test('should call onUsage after stream completes', () async {
      Usage? capturedUsage;
      final adapter = FakeAdapter();
      await for (final _ in adapter.createStream(
        ...,
        onUsage: (u) => capturedUsage = u,
      )) {}
      expect(capturedUsage, isNotNull);
      expect(capturedUsage!.promptTokens, greaterThan(0));
    });

    test('should return error text when configured', () async {
      final adapter = FakeAdapter(errorRate: 1.0, errorText: '网络异常');
      // ...assert error behavior
    });
  });
}
```

---

### `integration_test/manuscript_flow_test.dart` (test integration, request-response)

**Analog:** `integration_test/app_test.dart`

**Imports pattern** (from app_test.dart lines 1-9):
```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:integration_test/integration_test.dart';
import 'package:museflow/app.dart';
import 'package:museflow/core/infrastructure/hive_adapters.dart';
```

**Integration test setup pattern** (from app_test.dart lines 11-58):
```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await _initializeTestStorage(); // Hive init + adapter registration
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  testWidgets('TEST-02: Create manuscript and verify UI flow', (tester) async {
    // Per UI-SPEC: pump app with ProviderScope overrides
    // Then follow the 6-step sequence from UI-SPEC Integration Test Flow Contract
  });
}
```

**Key difference from app_test.dart:** TEST-02 needs `ProviderScope` with overrides, not `MuseFlowApp` directly. The existing app_test.dart pumps `MuseFlowApp()` without overrides (lines 43-46). TEST-02 must wrap with ProviderScope:

```dart
// Existing pattern (app_test.dart line 44):
await tester.pumpWidget(const MuseFlowApp());

// TEST-02 pattern:
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      openaiAdapterProvider.overrideWithValue(FakeAdapter()),
    ],
    child: const MuseFlowApp(),
  ),
);
await tester.pumpAndSettle();
```

**Error scenario test pattern** (from CONTEXT D-08):
```dart
group('Empty states', () {
  testWidgets('shows empty manuscript library', (tester) async {
    // No manuscripts created -- verify empty state
    expect(find.text('创建你的第一部作品'), findsOneWidget);
  });
});

group('AI anomalies', () {
  testWidgets('handles AI error gracefully', (tester) async {
    // Use FakeAdapter(errorRate: 1.0)
    // Trigger AI and verify error message in UI
  });
});
```

---

### Widget key additions (6 files, minor modifications)

**Analog:** existing key usage in `manuscript_create_dialog.dart` line 82:
```dart
DropdownButtonFormField<String>(
  key: const Key('manuscript-create-genre-dropdown'),
  // ...
)
```

The project already uses `Key('...')` pattern. Add the following keys:

#### `manuscript_create_dialog.dart` (lines 66-79)

Add `key: const Key('manuscript_title')` to the title TextField:
```dart
TextField(
  key: const Key('manuscript_title'),  // ADD THIS
  controller: _titleController,
  // ... rest unchanged
)
```

Add `key: const Key('manuscript_genre')` to the custom genre TextField (lines 107-118):
```dart
TextField(
  key: const Key('manuscript_genre'),  // ADD THIS
  controller: _customGenreController,
  // ... rest unchanged
)
```

#### `chapter_sidebar.dart` (line 136-141)

Add `key: const Key('add_chapter_button')` to the "新建章节" button:
```dart
OutlinedButton.icon(
  key: const Key('add_chapter_button'),  // ADD THIS
  onPressed: onNewChapter,
  icon: const Icon(Icons.add, size: 18),
  label: const Text('新建章节'),
)
```

#### `chapter_create_dialog.dart` (line 56)

Add `key: const Key('chapter_title_field')` to the title TextField:
```dart
TextField(
  key: const Key('chapter_title_field'),  // ADD THIS
  controller: _titleController,
  // ... rest unchanged
)
```

#### `floating_toolbar.dart` (lines 322-327)

Add `key: const Key('ai_synthesis_button')` to the first AI action button (tone rewrite) or to the `_ToolbarContent` container. The UI-SPEC says "AI toolbar button" for triggering synthesis. The most natural target is the first action button in `_ToolbarContent`:

```dart
_ActionButton(
  key: const Key('ai_synthesis_button'),  // ADD THIS
  icon: Icons.auto_fix_high,
  label: '语气改写',
  onTap: () => onStartOperation(EditorAIOperation.toneRewrite),
),
```

#### `export_dialog.dart` (lines 286-289)

Add `key: const Key('export_button')` to the export ElevatedButton:
```dart
ElevatedButton(
  key: const Key('export_button'),  // ADD THIS
  onPressed: _selectedPath != null && !_isExporting ? _doExport : null,
  child: const Text('导出'),
),
```

---

## Shared Patterns

### Hive Test Setup
**Source:** `test/helpers/hive_test_helper.dart`
**Apply to:** All test files in `test/automation/` and `integration_test/`
```dart
// Setup
TestWidgetsFlutterBinding.ensureInitialized();
final tempDir = Directory.systemTemp.createTempSync('hive_test_');
Hive.init(tempDir.path);

// Teardown
await Hive.deleteFromDisk();
```

### ProviderContainer + Overrides
**Source:** `lib/core/presentation/providers.dart` (lines 179-185, 652-665)
**Apply to:** `test/automation/helpers/test_container.dart`, `integration_test/manuscript_flow_test.dart`
```dart
final container = ProviderContainer(
  overrides: [
    openaiAdapterProvider.overrideWithValue(FakeAdapter()),
  ],
);
addTearDown(container.dispose);

// Access async providers:
final repo = await container.read(manuscriptRepositoryProvider.future);
```

### Repository CRUD Pattern
**Source:** `lib/features/manuscript/infrastructure/manuscript_repository.dart`
**Apply to:** All test segments that interact with repositories
```dart
// Create
final saved = await manuscriptRepo.add(Manuscript(...));
// Read
final all = manuscriptRepo.getAll();
// Read single
final found = manuscriptRepo.getById(id);
// Update
await manuscriptRepo.update(entity.copyWith(title: 'new'));
// Delete
await manuscriptRepo.delete(id);
```

### Error Handling (AIException hierarchy)
**Source:** `lib/features/ai/domain/ai_exception.dart`
**Apply to:** `test/automation/helpers/fake_adapter.dart` (for simulating errors)
```dart
// Sealed hierarchy -- exhaustive switch
sealed class AIException implements Exception { ... }
class AIAuthException extends AIException { ... }
class AIRateLimitException extends AIException { ... }
class AINetworkException extends AIException { ... }
class AIStreamException extends AIException { ... }
```

### Export Verification Pattern
**Source:** `lib/features/story_structure/application/export_service.dart` (lines 108-122)
**Apply to:** Export test segment in core_flow_test.dart
```dart
// Build export content (no file I/O needed)
final markdown = exportService.buildMarkdown(bundle);
// Assert structure
expect(markdown, contains('## {title}'));
// Assert order (from export_service.dart line 91: sort by sortOrder)
final firstIdx = markdown.indexOf('## 第一章');
final secondIdx = markdown.indexOf('## 第二章');
expect(firstIdx, lessThan(secondIdx));
```

### Token Audit Flush Pattern
**Source:** `lib/features/stats/application/token_audit_service.dart` (lines 70-81)
**Apply to:** Token audit verification in core_flow_test.dart
```dart
// TokenAuditService uses 30s debounce. Must force flush before reading:
final auditService = await container.read(tokenAuditServiceProvider.future);
await auditService.flush(); // Force write buffered records to Hive

// Then read via repository
final snapshot = await auditRepo.buildSnapshot();
expect(snapshot.totalCalls, expectedCount);
```

### Integration Test Hive Adapter Registration
**Source:** `integration_test/app_test.dart` (lines 12-41)
**Apply to:** `integration_test/manuscript_flow_test.dart`
```dart
// Must register all Hive type adapters before opening boxes
if (!Hive.isAdapterRegistered(HiveTypeIds.fragment)) {
  Hive.registerAdapter(FragmentAdapter());
}
// ... repeat for all adapters used by the app
```

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| None | -- | -- | All files have sufficient analogs in the codebase. The closest gap is FakeAdapter (no existing test double), but its pattern is directly derived from OpenAIAdapter's interface. |

## Metadata

**Analog search scope:** `lib/`, `test/`, `integration_test/`
**Files scanned:** 30+
**Pattern extraction date:** 2026-06-07
