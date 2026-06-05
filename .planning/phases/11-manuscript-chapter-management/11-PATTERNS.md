# Phase 11: Manuscript & Chapter Management - Pattern Map

**Mapped:** 2026-06-06
**Files analyzed:** 31 (21 new, 10 modified)
**Analogs found:** 31 / 31

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/features/manuscript/domain/manuscript.dart` | model | CRUD | `lib/core/domain/fragment.dart` | exact |
| `lib/features/manuscript/domain/chapter.dart` | model | CRUD | `lib/core/domain/fragment.dart` | exact |
| `lib/features/manuscript/domain/manuscript_genre.dart` | config | transform | `lib/features/story_structure/domain/plot_node.dart` (enums) | partial |
| `lib/features/manuscript/application/manuscript_notifier.dart` | service | CRUD | `lib/features/knowledge/application/character_card_notifier.dart` | exact |
| `lib/features/manuscript/application/chapter_notifier.dart` | service | CRUD | `lib/features/knowledge/application/character_card_notifier.dart` | exact |
| `lib/features/manuscript/application/chapter_auto_save.dart` | service | event-driven | `lib/features/stats/application/writing_stats_collector.dart` | exact |
| `lib/features/manuscript/application/manuscript_sort.dart` | utility | transform | (new pattern, no direct analog) | none |
| `lib/features/manuscript/infrastructure/manuscript_repository.dart` | model | CRUD | `lib/features/knowledge/infrastructure/character_card_repository.dart` | exact |
| `lib/features/manuscript/infrastructure/chapter_repository.dart` | model | CRUD | `lib/features/knowledge/infrastructure/character_card_repository.dart` | exact |
| `lib/features/manuscript/infrastructure/manuscript_purge_service.dart` | service | batch | (new pattern, closest: repository pattern) | partial |
| `lib/features/manuscript/presentation/manuscript_library_page.dart` | component | request-response | `lib/features/knowledge/presentation/knowledge_base_page.dart` | role-match |
| `lib/features/manuscript/presentation/manuscript_card.dart` | component | request-response | (widget, use Material Card pattern) | partial |
| `lib/features/manuscript/presentation/manuscript_create_dialog.dart` | component | request-response | `lib/features/knowledge/presentation/character_card_form.dart` | role-match |
| `lib/features/manuscript/presentation/manuscript_create_page.dart` | component | request-response | `lib/features/templates/presentation/template_draft_page.dart` | role-match |
| `lib/features/manuscript/presentation/manuscript_settings_page.dart` | component | request-response | `lib/features/knowledge/presentation/world_setting_form.dart` | role-match |
| `lib/features/manuscript/presentation/editor_with_sidebar.dart` | component | request-response | `lib/features/editor/presentation/editor_page.dart` | exact |
| `lib/features/manuscript/presentation/chapter_sidebar.dart` | component | request-response | `lib/core/presentation/app_shell.dart` (sidebar pattern) | role-match |
| `lib/features/manuscript/presentation/chapter_sidebar_row.dart` | component | request-response | (list tile widget) | partial |
| `lib/features/manuscript/presentation/chapter_create_dialog.dart` | component | request-response | (dialog pattern, use showDialog) | partial |
| `lib/features/manuscript/presentation/chapter_rename_dialog.dart` | component | request-response | (dialog pattern, use showDialog) | partial |
| `lib/features/manuscript/presentation/chapter_context_menu.dart` | component | request-response | (popup menu pattern) | partial |
| `lib/core/infrastructure/hive_adapters.dart` | config | file-I/O | (self, extend existing) | exact |
| `lib/core/presentation/providers.dart` | config | request-response | (self, extend existing) | exact |
| `lib/app.dart` | route | request-response | (self, extend existing) | exact |
| `lib/main.dart` | config | file-I/O | (self, extend existing) | exact |
| `lib/shared/constants/app_constants.dart` | config | transform | (self, extend existing) | exact |
| `lib/features/story_structure/domain/export_bundle.dart` | model | CRUD | (self, extend existing) | exact |
| `lib/features/editor/presentation/editor_page.dart` | component | request-response | (self, refactor) | exact |
| `lib/features/editor/presentation/editor_provider.dart` | service | CRUD | (self, extend) | exact |
| `lib/features/editor/application/editor_prompt_pipeline.dart` | service | event-driven | (self, extend) | exact |
| `lib/features/templates/application/template_instantiation_service.dart` | service | CRUD | (self, extend) | exact |

## Pattern Assignments

### `lib/features/manuscript/domain/manuscript.dart` (model, CRUD)

**Analog:** `lib/core/domain/fragment.dart`

**Core pattern -- immutable entity with copyWith, fromJson/toJson, equality** (lines 1-86):
```dart
class Fragment {
  final String id;
  final String text;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Fragment({
    required this.id,
    required this.text,
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
  });

  Fragment copyWith({
    String? id,
    String? text,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Fragment(
      id: id ?? this.id,
      text: text ?? this.text,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Fragment.fromJson(Map<String, dynamic> json) {
    return Fragment(
      id: json['id'] as String,
      text: json['text'] as String,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Fragment &&
        other.id == id &&
        other.text == text &&
        _listEquals(other.tags, tags) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(id, text, Object.hashAll(tags), createdAt, updatedAt);
}
```

**Key deviations from analog:**
- Manuscript has more fields: `title`, `description`, `genre`, `targetWordCount`, `status`, `worldSettingId`, `characterCardIds`, `deletedAt`, `coverLetter`
- `deletedAt` for soft delete (nullable DateTime, like Fragment's `updatedAt`)
- `characterCardIds` is `List<String>` (like Fragment's `tags`)
- No `freezed` -- follow the manual immutable pattern used by Fragment

---

### `lib/features/manuscript/domain/chapter.dart` (model, CRUD)

**Analog:** `lib/core/domain/fragment.dart`

**Same immutable entity pattern as Manuscript.** Key deviations:
- `manuscriptId` (foreign key), `sortOrder` (int), `status` (String enum), `documentContent` (String -- serialized Markdown, NOT JSON per RESEARCH.md correction)
- `wordCount` is a computed getter from `documentContent`, not a stored field:
```dart
int get wordCount {
  if (documentContent.isEmpty) return 0;
  return documentContent.replaceAll(RegExp(r'\s'), '').length;
}
```

---

### `lib/features/manuscript/domain/manuscript_genre.dart` (config, transform)

**No close analog.** This is a new utility defining:
- Genre preset list (14 types from Phase 7 templates)
- Genre-to-color mapping
- Custom genre support

Create as a simple class with static constants:
```dart
class ManuscriptGenre {
  static const List<String> presets = [
    '玄幻', '仙侠', '都市', '科幻', '奇幻',
    '武侠', '历史', '军事', '悬疑', '恐怖',
    '言情', '校园', '游戏', '末世',
  ];

  static const Map<String, int> _genreColors = {
    '玄幻': 0xFF6750A4,
    '仙侠': 0xFF7D5260,
    // ... etc
  };

  static int genreColor(String genre) =>
      _genreColors[genre] ?? 0xFF49454F;
}
```

---

### `lib/features/manuscript/application/manuscript_notifier.dart` (service, CRUD)

**Analog:** `lib/features/knowledge/application/character_card_notifier.dart`

**Complete AsyncNotifier CRUD pattern** (lines 1-51):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';

class CharacterCardNotifier extends AsyncNotifier<List<CharacterCard>> {
  @override
  Future<List<CharacterCard>> build() async {
    final repository = await ref.watch(characterCardRepositoryProvider.future);
    return repository.getAll();
  }

  Future<void> add(CharacterCard card) async {
    final repository = await ref.read(characterCardRepositoryProvider.future);
    await repository.add(card);
    ref.invalidateSelf();
  }

  Future<void> save(CharacterCard card) async {
    final repository = await ref.read(characterCardRepositoryProvider.future);
    await repository.update(card);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    final repository = await ref.read(characterCardRepositoryProvider.future);
    await repository.delete(id);
    ref.invalidateSelf();
  }

  List<CharacterCard> searchByName(String query) {
    final cards = state.asData?.value ?? [];
    final lowerQuery = query.toLowerCase();
    return cards.where((card) {
      if (card.name.toLowerCase().contains(lowerQuery)) return true;
      return card.aliases
          .any((alias) => alias.toLowerCase().contains(lowerQuery));
    }).toList();
  }
}
```

**Key deviations for ManuscriptNotifier:**
- Add `softDelete(String id)` method that sets `deletedAt` instead of removing
- Add `purgeDeleted()` method for 30-day auto-purge
- Filter out `deletedAt != null` from `build()` results
- Add sort-aware getter methods

**Provider registration pattern** (from `lib/core/presentation/providers.dart` lines 297-300):
```dart
final characterCardNotifierProvider =
    AsyncNotifierProvider<CharacterCardNotifier, List<CharacterCard>>(
      CharacterCardNotifier.new,
    );
```

---

### `lib/features/manuscript/application/chapter_notifier.dart` (service, CRUD)

**Analog:** `lib/features/knowledge/application/character_card_notifier.dart`

Same AsyncNotifier CRUD pattern. Key deviations:
- `build()` filters by `manuscriptId` and orders by `sortOrder`
- Add `reorder(String manuscriptId, int oldIndex, int newIndex)` with sortOrder recalculation
- Add `splitChapter(String chapterId, int cursorOffset)` and `mergeChapters(String chapterId1, String chapterId2)`
- Add `duplicateChapter(String chapterId)`
- Add `loadDocument(String chapterId)` returning deserialized Markdown as MutableDocument
- After every mutation that changes sortOrder, recalculate all sortOrders to sequential (0, 1, 2, ...)

---

### `lib/features/manuscript/application/chapter_auto_save.dart` (service, event-driven)

**Analog:** `lib/features/stats/application/writing_stats_collector.dart`

**Debounced write pattern** (lines 1-96):
```dart
import 'dart:async';

class WritingStatsCollector {
  WritingStatsCollector(
    this._repository, {
    this.debounceDuration = const Duration(seconds: 30),
  });

  final WritingStatsRepository _repository;
  final Duration debounceDuration;

  Timer? _flushTimer;
  int? _lastTextUnits;
  int _pendingHumanUnits = 0;
  int _pendingAiUnits = 0;
  DateTime? _sessionStartedAt;
  DateTime? _lastActivityAt;
  String? _projectId;
  String? _documentId;

  void recordTextSnapshot(String plainText, {String? projectId, String? documentId}) {
    final units = countWritingUnits(plainText);
    _projectId = projectId ?? _projectId;
    _documentId = documentId ?? _documentId;
    _sessionStartedAt ??= DateTime.now();
    _lastActivityAt = DateTime.now();

    final previous = _lastTextUnits;
    _lastTextUnits = units;
    if (previous == null) return;

    final delta = units - previous;
    if (delta > 0) {
      _pendingHumanUnits += delta;
      _scheduleFlush();
    }
  }

  Future<void> flush() async {
    _flushTimer?.cancel();
    _flushTimer = null;

    final humanUnits = _pendingHumanUnits;
    final aiUnits = _pendingAiUnits;
    if (humanUnits == 0 && aiUnits == 0) return;

    // ... persist ...
    _pendingHumanUnits = 0;
    _pendingAiUnits = 0;
  }

  void dispose() {
    _flushTimer?.cancel();
    _flushTimer = null;
    unawaited(flush());
  }

  void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(debounceDuration, () {
      unawaited(flush());
    });
  }
}
```

**Key deviations for ChapterAutoSave:**
- Change debounce from 30s to 2-3 seconds
- Track `_currentChapterId` and `_pendingMarkdown` (the serialized document)
- Add `forceSave()` method that cancels timer and flushes immediately (for chapter switch, back-to-library, app pause)
- Add `onDocumentChanged(String chapterId, String markdown)` as the entry point
- Use `_isDirty` flag to avoid redundant writes
- Register `WidgetsBindingObserver` for app lifecycle `didChangeAppLifecycleState` to trigger forceSave on pause

**Provider registration pattern** (from `lib/core/presentation/providers.dart` lines 448-455):
```dart
final writingStatsCollectorProvider = FutureProvider<WritingStatsCollector>((ref) async {
  final repository = await ref.watch(writingStatsRepositoryProvider.future);
  final collector = WritingStatsCollector(repository);
  ref.onDispose(collector.dispose);
  return collector;
});
```

---

### `lib/features/manuscript/application/manuscript_sort.dart` (utility, transform)

**No analog.** Create a simple utility:
```dart
enum ManuscriptSortMode {
  recentEdit,
  creationDate,
  titleAlphabetical,
}

int compareManuscripts(Manuscript a, Manuscript b, ManuscriptSortMode mode) {
  return switch (mode) {
    ManuscriptSortMode.recentEdit => b.updatedAt.compareTo(a.updatedAt),
    ManuscriptSortMode.creationDate => b.createdAt.compareTo(a.createdAt),
    ManuscriptSortMode.titleAlphabetical => a.title.compareTo(b.title),
  };
}
```

---

### `lib/features/manuscript/infrastructure/manuscript_repository.dart` (model, CRUD)

**Analog:** `lib/features/knowledge/infrastructure/character_card_repository.dart`

**Complete Hive repository pattern** (lines 1-102):
```dart
import 'package:hive_ce/hive.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:uuid/uuid.dart';

class CharacterCardRepository {
  final Box<dynamic> _box;
  final _uuid = const Uuid();

  CharacterCardRepository(this._box);

  Future<CharacterCard> add(CharacterCard card) async {
    try {
      final id = card.id.isEmpty ? _uuid.v4() : card.id;
      final now = DateTime.now();
      final newCard = CharacterCard(
        id: id,
        name: card.name,
        // ... other fields ...
        createdAt: now,
      );
      await _box.put(id, newCard.toJson());
      return newCard;
    } catch (e) {
      throw StateError('Failed to save character card: $e');
    }
  }

  List<CharacterCard> getAll() {
    try {
      return _box.values
          .map((json) => CharacterCard.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw StateError('Failed to read character cards: $e');
    }
  }

  CharacterCard? getById(String id) {
    try {
      final json = _box.get(id);
      if (json == null) return null;
      return CharacterCard.fromJson(json as Map<String, dynamic>);
    } catch (e) {
      throw StateError('Failed to read character card $id: $e');
    }
  }

  Future<void> update(CharacterCard card) async {
    try {
      final updated = card.copyWith(updatedAt: DateTime.now());
      await _box.put(card.id, updated.toJson());
    } catch (e) {
      throw StateError('Failed to update character card ${card.id}: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw StateError('Failed to delete character card $id: $e');
    }
  }
}
```

**Key deviations for ManuscriptRepository:**
- Use box name `'manuscripts'` (separate box per entity type per established pattern)
- `getAll()` filters out soft-deleted (`deletedAt != null`)
- Add `getAllIncludingDeleted()` for purge service
- Add `softDelete(String id)` that sets `deletedAt` via update
- Add `purgeOlderThan(Duration age)` for 30-day auto-purge

**Provider registration** (from `lib/core/presentation/providers.dart` lines 271-276):
```dart
final characterCardRepositoryProvider = FutureProvider<CharacterCardRepository>(
  (ref) async {
    final box = await Hive.openBox<dynamic>('character_cards');
    return CharacterCardRepository(box);
  },
);
```

---

### `lib/features/manuscript/infrastructure/chapter_repository.dart` (model, CRUD)

**Analog:** `lib/features/knowledge/infrastructure/character_card_repository.dart`

Same Hive repository pattern. Key deviations:
- Use box name `'chapters'`
- `getByManuscriptId(String manuscriptId)` returns chapters filtered and ordered by `sortOrder`
- `updateDocumentContent(String chapterId, String markdown)` updates only the `documentContent` field (called frequently by auto-save, avoids full entity rewrite)
- `deleteByManuscriptId(String manuscriptId)` for cascade delete when manuscript is purged
- After delete, no sortOrder recalculation here -- that is the notifier's responsibility

---

### `lib/features/manuscript/infrastructure/manuscript_purge_service.dart` (service, batch)

**No direct analog.** Create as a simple service class:
```dart
class ManuscriptPurgeService {
  final ManuscriptRepository _manuscriptRepository;
  final ChapterRepository _chapterRepository;

  const ManuscriptPurgeService({
    required ManuscriptRepository manuscriptRepository,
    required ChapterRepository chapterRepository,
  });

  Future<void> purgeExpired({Duration retention = const Duration(days: 30)}) async {
    final cutoff = DateTime.now().subtract(retention);
    final manuscripts = _manuscriptRepository.getAllIncludingDeleted();
    for (final manuscript in manuscripts) {
      if (manuscript.deletedAt != null && manuscript.deletedAt!.isBefore(cutoff)) {
        await _chapterRepository.deleteByManuscriptId(manuscript.id);
        await _manuscriptRepository.hardDelete(manuscript.id);
      }
    }
  }
}
```
Call from `main.dart` on app startup after Hive initialization.

---

### `lib/features/manuscript/presentation/manuscript_library_page.dart` (component, request-response)

**Analog:** `lib/features/knowledge/presentation/knowledge_base_page.dart`

Use `ConsumerWidget` pattern with `ref.watch(manuscriptNotifierProvider)`. Layout: `GridView` with `ManuscriptCard` widgets, empty state when no manuscripts, sort toggle in AppBar.

**Widget pattern** -- use `ConsumerWidget` (from CLAUDE.md / Flutter standards):
```dart
class ManuscriptLibraryPage extends ConsumerWidget {
  const ManuscriptLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manuscriptsAsync = ref.watch(manuscriptNotifierProvider);
    return manuscriptsAsync.when(
      data: (manuscripts) {
        if (manuscripts.isEmpty) return _buildEmptyState(context);
        return _buildCardGrid(context, ref, manuscripts);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
```

**Navigation pattern** -- tap card navigates to editor (from RESEARCH.md route structure):
```dart
context.go('/manuscript/${manuscript.id}/editor');
```

---

### `lib/features/manuscript/presentation/manuscript_card.dart` (component, request-response)

**No direct analog.** Create as a `ConsumerWidget` displaying:
- Genre-colored background (from `ManuscriptGenre.genreColor(manuscript.genre)`)
- Cover letter overlay (max 2 chars)
- Title, word count / target word count with progress bar
- Last edited time, status badge

Use Material `Card` widget with `InkWell` for tap handling.

---

### `lib/features/manuscript/presentation/manuscript_create_dialog.dart` (component, request-response)

**Analog dialog pattern** -- use `showDialog` with `AlertDialog`:
```dart
void _showCreateDialog(BuildContext context, WidgetRef ref) {
  showDialog<void>(
    context: context,
    builder: (_) => const ManuscriptCreateDialog(),
  );
}
```
Quick create dialog: `TextField` for title + genre dropdown + create button. On confirm, call `ref.read(manuscriptNotifierProvider.notifier).add(...)` and navigate to editor.

---

### `lib/features/manuscript/presentation/manuscript_create_page.dart` (component, request-response)

**Analog:** `lib/features/templates/presentation/template_draft_page.dart`

Full-page form with: title, genre, description, target word count, linked WorldSetting/CharacterCard selection. On save, create manuscript + one empty chapter.

---

### `lib/features/manuscript/presentation/manuscript_settings_page.dart` (component, request-response)

**Analog:** `lib/features/knowledge/presentation/world_setting_form.dart`

Form page for editing manuscript metadata. Use `ConsumerStatefulWidget` with form fields bound to manuscript entity.

---

### `lib/features/manuscript/presentation/editor_with_sidebar.dart` (component, request-response)

**Analog:** `lib/features/editor/presentation/editor_page.dart`

This is the refactored editor page that replaces the current `EditorPage` when inside a manuscript. Layout pattern from `lib/core/presentation/app_shell.dart` (lines 103-121) -- Row with fixed sidebar + vertical divider + expanded content:

```dart
Row(
  children: [
    SizedBox(width: 260, child: ChapterSidebar(manuscriptId: widget.manuscriptId)),
    VerticalDivider(width: 1, thickness: 1, color: colorScheme.outline),
    Expanded(child: EditorArea(manuscriptId: widget.manuscriptId)),
  ],
)
```

**Editor lifecycle pattern** from `editor_page.dart` (lines 46-76):
```dart
class _EditorPageState extends ConsumerState<EditorPage> {
  late final Editor _editor;
  late final SelectionLayerLinks _selectionLinks;

  @override
  void initState() {
    super.initState();
    _editor = createDefaultEditor();
    _selectionLinks = SelectionLayerLinks();
    // ... listeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editorProvider.notifier).setEditor(_editor);
    });
  }

  @override
  void dispose() {
    // ... cleanup
    ref.read(editorProvider.notifier).setEditor(null);
    _editor.composer.dispose();
    super.dispose();
  }
}
```

**Key deviations:**
- Accept `manuscriptId` parameter
- Load initial chapter from ChapterNotifier on initState
- On chapter switch: serialize current document (forced save) -> load new chapter's Markdown -> swap document into existing Editor (do NOT recreate Editor widget)
- Register `WidgetsBindingObserver` for app lifecycle to trigger forceSave
- Hide bottom nav (this is a top-level route, not inside StatefulShellRoute)

---

### `lib/features/manuscript/presentation/chapter_sidebar.dart` (component, request-response)

**Analog sidebar pattern** from `lib/core/presentation/app_shell.dart` (lines 103-116 -- Row with sidebar + divider + expanded):
```dart
// Desktop layout: sidebar + content in Row
Row(
  children: [
    AdaptiveSidebar(
      currentIndex: widget.navigationShell.currentIndex,
      onDestinationSelected: (index) { ... },
    ),
    const VerticalDivider(width: 1, thickness: 1),
    Expanded(child: widget.navigationShell),
  ],
)
```

**Chapter sidebar structure:**
```dart
class ChapterSidebar extends ConsumerWidget {
  final String manuscriptId;
  // Build: Column with manuscript title header + ReorderableListView of ChapterSidebarRow + "new chapter" button
}
```

Use Flutter SDK `ReorderableListView` for drag-and-drop reordering. On reorder, call `chapterNotifier.reorder(manuscriptId, oldIndex, newIndex)`.

---

### `lib/features/manuscript/presentation/chapter_sidebar_row.dart` (component, request-response)

**No direct analog.** Simple `ConsumerWidget`:
```dart
class ChapterSidebarRow extends StatelessWidget {
  final Chapter chapter;
  final bool isActive;
  final VoidCallback onTap;
  // Build: ListTile or custom row with title + right-aligned word count + highlight when active
}
```

---

### `lib/features/manuscript/presentation/chapter_create_dialog.dart` (component, request-response)

Dialog with `TextField` for chapter title. On confirm, call `chapterNotifier.add(...)` with next sortOrder.

---

### `lib/features/manuscript/presentation/chapter_rename_dialog.dart` (component, request-response)

Dialog with `TextField` pre-filled with current title. On confirm, call `chapterNotifier.save(chapter.copyWith(title: newTitle))`.

---

### `lib/features/manuscript/presentation/chapter_context_menu.dart` (component, request-response)

`PopupMenuButton` or `showMenu` with options: rename, split at cursor, merge with next, duplicate, delete. Each option calls the corresponding ChapterNotifier method.

---

### `lib/core/infrastructure/hive_adapters.dart` -- EXTEND (config, file-I/O)

**Self-extension.** Add `ManuscriptAdapter` and `ChapterAdapter` following the exact pattern of existing adapters (lines 28-50):

```dart
/// Type ID registry -- add chapter ID
abstract class HiveTypeIds {
  // ... existing IDs ...
  static const int manuscript = 2;  // already reserved
  static const int chapter = 9;     // next available slot
}

/// Manual Hive TypeAdapter for [Manuscript].
class ManuscriptAdapter extends TypeAdapter<Manuscript> {
  @override
  final int typeId = HiveTypeIds.manuscript;

  @override
  Manuscript read(BinaryReader reader) {
    final json = reader.readMap() as Map<String, dynamic>;
    return Manuscript.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, Manuscript obj) {
    writer.writeMap(obj.toJson());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManuscriptAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
```

Same pattern for `ChapterAdapter` with `typeId = HiveTypeIds.chapter`.

---

### `lib/core/presentation/providers.dart` -- EXTEND (config, request-response)

**Self-extension.** Add manuscript/chapter repository and notifier providers following the exact pattern:

**Repository provider** (lines 271-276):
```dart
final characterCardRepositoryProvider = FutureProvider<CharacterCardRepository>(
  (ref) async {
    final box = await Hive.openBox<dynamic>('character_cards');
    return CharacterCardRepository(box);
  },
);
```

**Notifier provider** (lines 297-300):
```dart
final characterCardNotifierProvider =
    AsyncNotifierProvider<CharacterCardNotifier, List<CharacterCard>>(
      CharacterCardNotifier.new,
    );
```

Add imports for new manuscript module files. Add:
- `manuscriptRepositoryProvider`
- `chapterRepositoryProvider`
- `manuscriptNotifierProvider`
- `chapterNotifierProvider`
- `chapterAutoSaveProvider`
- `manuscriptPurgeServiceProvider`

---

### `lib/app.dart` -- EXTEND (route, request-response)

**Self-extension.** Key changes:

1. Add top-level manuscript editor routes OUTSIDE `StatefulShellRoute` (per RESEARCH.md Pitfall 4):
```dart
GoRoute(
  path: '/manuscript/:id/editor',
  builder: (context, state) {
    final manuscriptId = state.pathParameters['id']!;
    return EditorWithSidebar(manuscriptId: manuscriptId);
  },
),
GoRoute(
  path: '/manuscript/:id/settings',
  builder: (context, state) {
    final manuscriptId = state.pathParameters['id']!;
    return ManuscriptSettingsPage(manuscriptId: manuscriptId);
  },
),
```

2. Change Branch 1 to show `ManuscriptLibraryPage` instead of `EditorPage`:
```dart
// Branch 1: Library (was Editor, now ManuscriptLibraryPage)
StatefulShellBranch(
  routes: [
    GoRoute(
      path: AppConstants.editor, // keep path for compatibility
      builder: (context, state) => const ManuscriptLibraryPage(),
    ),
  ],
),
```

3. Add imports for new manuscript pages.

---

### `lib/main.dart` -- EXTEND (config, file-I/O)

**Self-extension.** Register new TypeAdapters following the pattern (lines 64-71):
```dart
Hive.registerAdapter(FragmentAdapter());
Hive.registerAdapter(AppSettingsAdapter());
// ... existing adapters ...
Hive.registerAdapter(ManuscriptAdapter());
Hive.registerAdapter(ChapterAdapter());
```

Add purge call after Hive init:
```dart
// Purge soft-deleted manuscripts older than 30 days
final purgeService = ... // create purge service
await purgeService.purgeExpired();
```

---

### `lib/shared/constants/app_constants.dart` -- EXTEND (config, transform)

**Self-extension.** Add route constants:
```dart
static const String manuscriptEditor = '/manuscript/:id/editor';
static const String manuscriptSettings = '/manuscript/:id/settings';
```

---

### `lib/features/story_structure/domain/export_bundle.dart` -- EXTEND (model, CRUD)

**Self-extension.** Add `chapters` field to ExportBundle following the existing list field pattern (lines 23-43):

```dart
// Add to class fields:
final List<ChapterExport> chapters;

// Update constructor to include chapters with default const []
// Update fromJson/toJson to handle chapters list
// manuscriptText becomes computed: chapters.map((c) => c.content).join('\n\n')

// New class (can live in this file or separate):
class ChapterExport {
  final String title;
  final int sortOrder;
  final String content;
  // ... fromJson/toJson/equality
}
```

---

### `lib/features/editor/presentation/editor_page.dart` -- REFACTOR (component, request-response)

**Self-refactor.** The existing `EditorPage` will be replaced by `ManuscriptLibraryPage` in Branch 1. The editor functionality moves to `EditorWithSidebar` in the manuscript feature module. The existing `EditorPage` may be kept as a fallback or removed entirely depending on migration strategy.

Key change: `EditorHolderNotifier` and `editorProvider` (lines 22-33) should remain accessible -- they may be moved or kept in this file since cross-widget code references them.

---

### `lib/features/editor/presentation/editor_provider.dart` -- EXTEND (service, CRUD)

**Self-extension.** The `createDefaultEditor()` function (lines 1-19) needs a variant that accepts a pre-built Document:
```dart
Editor createEditorWithDocument(MutableDocument document) {
  return createDefaultDocumentEditor(document: document);
}
```

This enables chapter switching to create an Editor with a specific chapter's document.

---

### `lib/features/editor/application/editor_prompt_pipeline.dart` -- EXTEND (service, event-driven)

**Self-extension.** Add a new middleware for adjacent chapter context injection. Follow the pattern of existing middlewares like `ContextAnchorMiddleware`:

```dart
class ChapterContextMiddleware extends PromptMiddleware {
  const ChapterContextMiddleware();

  @override
  PromptContext apply(PromptContext context) {
    final previousChapterSummary = context.previousChapterSummary;
    final nextChapterSummary = context.nextChapterSummary;

    final buffer = StringBuffer();
    if (previousChapterSummary != null) {
      buffer.write('上一章节摘要：\n$previousChapterSummary\n\n');
    }
    if (nextChapterSummary != null) {
      buffer.write('下一章节摘要：\n$nextChapterSummary\n\n');
    }
    // ... inject into system message
    return context;
  }
}
```

Add to `EditorPromptPipeline` middleware list (line 43, before `EditorOperationMiddleware`).

---

### `lib/features/templates/application/template_instantiation_service.dart` -- EXTEND (service, CRUD)

**Self-extension.** Extend `saveDraft()` (lines 47-64) to also create chapter skeleton entities. The method currently creates WorldSetting + CharacterCards. Add chapter creation:

```dart
Future<TemplateCreationResult> saveDraft(TemplateDraft draft) async {
  // ... existing world + character creation ...

  // New: create chapter skeleton
  final chapters = <Chapter>[];
  for (final chapterTitle in draft.chapterTitles) {
    final chapter = Chapter(
      id: _uuid.v4(),
      manuscriptId: manuscriptId, // needs to be passed in
      title: chapterTitle,
      sortOrder: chapters.length,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await chapterRepository.add(chapter);
    chapters.add(chapter);
  }

  return TemplateCreationResult(
    worldSetting: createdWorld,
    characterCards: createdCharacters.cast(),
    chapters: chapters,  // new field
  );
}
```

Requires injecting `ChapterRepository` into the service constructor.

## Shared Patterns

### Immutable Entity Pattern
**Source:** `lib/core/domain/fragment.dart`
**Apply to:** `manuscript.dart`, `chapter.dart`, `manuscript_genre.dart` (partial)
```dart
class EntityName {
  final String id;
  // ... fields ...
  final DateTime createdAt;
  final DateTime? updatedAt;

  const EntityName({required this.id, /* ... */ required this.createdAt, this.updatedAt});

  EntityName copyWith({/* nullable params */}) => EntityName(/* id ?? this.id, ... */);

  factory EntityName.fromJson(Map<String, dynamic> json) => EntityName(/* parse */);
  Map<String, dynamic> toJson() => {/* serialize */};

  @override
  bool operator ==(Object other) => /* field-by-field comparison */;
  @override
  int get hashCode => Object.hash(/* all fields */);
}
```

### Hive Repository Pattern
**Source:** `lib/features/knowledge/infrastructure/character_card_repository.dart`
**Apply to:** `manuscript_repository.dart`, `chapter_repository.dart`
```dart
class EntityRepository {
  final Box<dynamic> _box;
  final _uuid = const Uuid();

  EntityRepository(this._box);

  Future<Entity> add(Entity item) async {
    try {
      final id = item.id.isEmpty ? _uuid.v4() : item.id;
      final newItem = /* assign id and timestamps */;
      await _box.put(id, newItem.toJson());
      return newItem;
    } catch (e) {
      throw StateError('Failed to save entity: $e');
    }
  }

  List<Entity> getAll() { /* _box.values.map(fromJson).toList() */ }
  Entity? getById(String id) { /* _box.get(id) */ }
  Future<void> update(Entity item) async { /* _box.put(item.id, updated.toJson()) */ }
  Future<void> delete(String id) async { /* _box.delete(id) */ }
}
```

### AsyncNotifier Provider Registration
**Source:** `lib/core/presentation/providers.dart`
**Apply to:** All new providers
```dart
// Repository provider
final entityRepositoryProvider = FutureProvider<EntityRepository>((ref) async {
  final box = await Hive.openBox<dynamic>('entity_box_name');
  return EntityRepository(box);
});

// Notifier provider
final entityNotifierProvider =
    AsyncNotifierProvider<EntityNotifier, List<Entity>>(
      EntityNotifier.new,
    );
```

### Hive TypeAdapter Pattern
**Source:** `lib/core/infrastructure/hive_adapters.dart`
**Apply to:** ManuscriptAdapter, ChapterAdapter
```dart
class EntityAdapter extends TypeAdapter<Entity> {
  @override
  final int typeId = HiveTypeIds.entity; // centralized ID

  @override
  Entity read(BinaryReader reader) {
    final json = reader.readMap() as Map<String, dynamic>;
    return Entity.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, Entity obj) {
    writer.writeMap(obj.toJson());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntityAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
```

### Debounced Write Pattern
**Source:** `lib/features/stats/application/writing_stats_collector.dart`
**Apply to:** `chapter_auto_save.dart`
```dart
class AutoSaveService {
  final Repository _repository;
  final Duration debounceDuration;
  Timer? _flushTimer;
  bool _isDirty = false;

  void onContentChanged(String id, String content) {
    _isDirty = true;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, _flush);
  }

  Future<void> forceSave() async {
    _debounceTimer?.cancel();
    await _flush();
  }

  Future<void> _flush() async {
    if (!_isDirty) return;
    _isDirty = false;
    // persist...
  }

  void dispose() {
    _flushTimer?.cancel();
    unawaited(forceSave());
  }
}
```

### ConsumerWidget / ConsumerStatefulWidget Pattern
**Source:** `lib/features/editor/presentation/editor_page.dart`
**Apply to:** All presentation files
```dart
// Stateless widget with Riverpod access
class MyWidget extends ConsumerWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(someProvider);
    return dataAsync.when(
      data: (data) => /* build UI */,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// Stateful widget with Editor lifecycle
class MyEditorWidget extends ConsumerStatefulWidget {
  const MyEditorWidget({super.key});
  @override
  ConsumerState<MyEditorWidget> createState() => _MyEditorWidgetState();
}
```

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/features/manuscript/application/manuscript_sort.dart` | utility | transform | No sort utility exists yet; create simple enum + comparator |
| `lib/features/manuscript/infrastructure/manuscript_purge_service.dart` | service | batch | No batch purge service exists; create new service following repository injection pattern |
| `lib/features/manuscript/presentation/manuscript_card.dart` | component | request-response | No card-grid widget exists; create using Material Card pattern |
| `lib/features/manuscript/presentation/chapter_sidebar_row.dart` | component | request-response | No list-tile-with-highlight widget exists; create simple ConsumerWidget |
| `lib/features/manuscript/presentation/chapter_create_dialog.dart` | component | request-response | No create-only dialog exists; use standard showDialog + AlertDialog pattern |
| `lib/features/manuscript/presentation/chapter_rename_dialog.dart` | component | request-response | Same as above |
| `lib/features/manuscript/presentation/chapter_context_menu.dart` | component | request-response | No context menu exists; use PopupMenuButton pattern |

## Metadata

**Analog search scope:** `lib/core/`, `lib/features/knowledge/`, `lib/features/editor/`, `lib/features/stats/`, `lib/features/story_structure/`, `lib/features/templates/`, `lib/shared/`
**Files scanned:** 14 canonical reference files
**Pattern extraction date:** 2026-06-06
