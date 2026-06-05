# Phase 11: 文稿库与章节管理 - Research

**Researched:** 2026-06-06
**Domain:** Flutter multi-document management, SuperEditor document switching, Hive data modeling
**Confidence:** HIGH

## Summary

Phase 11 transforms MuseFlow from a single-editor tool into a multi-manuscript management platform. The core technical challenge is managing per-chapter SuperEditor `Document` instances with clean serialization, switching, and auto-save guarantees. The existing codebase already has all the building blocks: SuperEditor with `MutableDocument` nodes, Hive TypeAdapter pattern with reserved type IDs (manuscript=2, chapter slot needed), debounced write pattern from `WritingStatsCollector`, and `ExportBundle` that needs chapter-aware extension.

No new external packages are required. The phase uses Flutter SDK's built-in `ReorderableListView` for drag-and-drop, and the existing `super_editor` package's Markdown serialization (via `super_editor_markdown` which needs to be added) for document persistence. All UI components follow existing Material 3 dark indigo patterns.

**Primary recommendation:** Build a `lib/features/manuscript/` feature module with clean architecture layers, storing each Chapter's editor content as serialized Markdown in a dedicated Hive box. Use `super_editor_markdown` for serialization. Extend `EditorPage` into `EditorWithSidebar` that swaps `Document` instances on chapter switch with forced-save guarantees.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Each Chapter owns its own SuperEditor `Document` (serialized as JSON). Switching chapters loads a different Document into the editor.
- **D-02:** Manuscript is a container entity that owns multiple Chapters via ordered list. Chapters are ordered by `sortOrder` (integer), not array position.
- **D-03:** Manuscript entity fields: `id`, `title`, `description`, `genre`, `targetWordCount`, `status` (构思中/写作中/已完成), `worldSettingId` (one WorldSetting), `characterCardIds` (many CharacterCards), `createdAt`, `updatedAt`, `deletedAt` (soft delete), `coverLetter` (max 2 chars for card display). All fields immutable with `copyWith`.
- **D-04:** Chapter entity fields: `id`, `manuscriptId`, `title`, `sortOrder`, `status` (草稿/初稿/精修/定稿), `wordCount` (computed, not stored), `documentJson` (SuperEditor Document serialized), `createdAt`, `updatedAt`. Immutable with `copyWith`.
- **D-05:** Chapter status transitions are guided but flexible -- UI suggests next logical status but user can skip or set any status freely.
- **D-06:** Manuscript library replaces the editor as the home screen (Branch 1 in StatefulShellRoute). Bottom nav "编辑器" label stays unchanged.
- **D-07:** Library layout is a card grid. Each card shows: genre-colored background with customizable cover letter (max 2 chars, default = first char of title), title, word count, target word count with progress bar, last edited time, status badge.
- **D-08:** Library supports multiple sort options: recent edit (default), creation date, title alphabetical.
- **D-09:** Manuscript genres: preset list (reuse Phase 7's 14 novel types as base) + user can add custom genres.
- **D-10:** Empty state: illustrated guide with step-by-step instructions.
- **D-11:** Two-level navigation: Library -> tap manuscript card -> enter Editor (full screen, bottom nav hidden) -> AppBar back button returns to Library.
- **D-12:** Bottom navigation keeps all 6 items. When inside a manuscript's editor, bottom nav is hidden and replaced with a back-to-library AppBar.
- **D-13:** Left sidebar panel is always visible within the editor (not collapsible). Fixed width ~240-280px.
- **D-14:** Each chapter row in sidebar displays: title + right-aligned word count. Currently active chapter is visually highlighted.
- **D-15:** Chapter reordering via drag & drop in sidebar. After drop, `sortOrder` values are recalculated.
- **D-16:** Chapter operations: create, delete (with confirmation), rename, reorder (drag & drop), split (at cursor position), merge (adjacent), duplicate.
- **D-17:** Two creation flows: (1) Quick create -- dialog with title + genre selection. (2) Detailed create -- full page with title, genre, description, target word count, linked WorldSetting/CharacterCard selection.
- **D-18:** Manuscript metadata editing via dedicated settings page.
- **D-19:** Chapter content auto-saves with dual guarantee: (1) Debounced save (2-3 seconds) + (2) Forced save on chapter switch, back-to-library navigation, and app lifecycle pause.
- **D-20:** Template integration: auto-creates WorldSetting + CharacterCards + preset chapter skeleton.
- **D-21:** Soft delete for manuscripts: `deletedAt` timestamp. Recoverable for 30 days. Auto-purge on app launch.
- **D-22:** Chapter deletion: immediate hard delete with confirmation. Adjacent chapters' sortOrder recalculated.
- **D-23:** Export supports flexible selection: whole manuscript or user-selected chapters. ExportBundle updated to include chapter-level structure.
- **D-24:** AI operations inject adjacent chapter summaries as context.
- **D-25:** Manuscript word count progress visualized in library card and editor status bar.
- **D-26:** Chapter navigation keyboard shortcuts (Ctrl+Up/Down, Ctrl+Shift+N). Shortcuts customizable.

### Claude's Discretion
Planners may choose implementation details for:
- SuperEditor Document JSON serialization format (use SuperEditor's built-in `Document.fromJson`/`toJson`)
- Drag & drop package selection (e.g., `reorderable_grid_view` or custom `Draggable`/`DragTarget`)
- Genre color palette mapping
- Soft delete auto-purge trigger mechanism
- Adjacent chapter summary generation (truncation vs AI-generated)
- Keyboard shortcut customization storage format

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SC-1 | User can create, view, edit, soft-delete manuscripts from a library homepage (card grid) | Manuscript/Chapter entities with Hive TypeAdapters; ManuscriptLibraryPage with GridView; ManuscriptCard widget |
| SC-2 | User can create, rename, reorder, split, merge, duplicate, delete chapters | Chapter CRUD via ChapterNotifier; ReorderableListView for reordering; SuperEditor node split/merge operations |
| SC-3 | Editor switches chapter documents when user selects a different chapter | Document swap pattern: serialize current -> load new Document from Markdown -> set on Editor |
| SC-4 | Chapter content auto-saves with debounced + forced-save guarantees | WritingStatsCollector debounced pattern; WidgetsBindingObserver for app lifecycle |
| SC-5 | Manuscript creation from template auto-creates WorldSetting + CharacterCards + chapter skeleton | TemplateInstantiationService extension |
| SC-6 | Export supports chapter-aware structure | ExportBundle extension with chapters field |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Manuscript/Chapter data modeling | Domain | -- | Pure Dart entities, no Flutter dependency. Immutable with copyWith. |
| Manuscript/Chapter CRUD operations | Application | -- | AsyncNotifier pattern with repository layer. |
| Manuscript/Chapter persistence | Infrastructure | -- | Hive boxes + TypeAdapters for serialization. |
| Library card grid UI | Presentation | -- | GridView with genre-colored cards. |
| Chapter sidebar + reordering | Presentation | -- | ReorderableListView in fixed-width panel. |
| Document switching + auto-save | Presentation | Infrastructure | EditorPage manages Document instances; auto-save writes via ChapterRepository. |
| Export with chapter structure | Application | Presentation | ExportBundle domain model extended; ExportService builds chapter-aware output. |
| Template chapter skeleton | Application | -- | TemplateInstantiationService creates Chapter entities alongside WorldSetting/CharacterCards. |
| AI context with chapter summaries | Application | Presentation | EditorPromptPipeline middleware injects adjacent chapter summaries. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter SDK | 3.44.0 (stable) | Cross-platform UI | Project constraint. Shipped with Dart 3.5.4. |
| flutter_riverpod | ^3.3.1 | State management | Project constraint. AsyncNotifier for CRUD operations. |
| super_editor | ^0.3.0-dev.20 | Rich text editor | Already in use. Document model for chapter content. |
| hive_ce | ^2.19.3 | Local NoSQL storage | Already in use. Manuscript/Chapter persistence. |
| go_router | ^17.2.3 | Navigation | Already in use. Library->Editor route structure. |

### Supporting (New)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| super_editor_markdown | (matching super_editor) | Document serialization | Chapter content serialization to/from Markdown for persistence. |

### Supporting (Existing)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| freezed | ^3.2.5 | Immutable data classes | Manuscript and Chapter domain entities. |
| uuid | latest | Unique IDs | Manuscript and Chapter ID generation. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| super_editor_markdown | Custom JSON serialization of Document nodes | Markdown is human-readable, debuggable, and officially supported. Custom JSON is fragile across super_editor version updates. |
| ReorderableListView (SDK) | reorderables package | SDK widget is sufficient for vertical list reordering. No need for external package. |
| Hive box per entity type | Single box with all data | Separate boxes follow established pattern (fragments, character_cards, world_settings, etc.). |

**Installation:**
```bash
flutter pub add super_editor_markdown
```

**Note:** Only one new dependency required (`super_editor_markdown`). Everything else uses existing project dependencies. [VERIFIED: pubspec.yaml contains super_editor ^0.3.0-dev.20; super_editor_markdown is the official companion package from Context7 docs.]

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| super_editor_markdown | pub.dev | 4+ yrs | High | github.com/superlistapp/super_editor | [ASSUMED] | Approved (official companion package) |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

*slopcheck was not installed in this environment. super_editor_markdown is marked [ASSUMED] but is the official companion package from the same publisher (superlistapp) as super_editor, which is already a project dependency with a high Context7 benchmark score (97).*

## Architecture Patterns

### System Architecture Diagram

```
User taps manuscript card
       |
       v
ManuscriptLibraryPage  -->  GoRouter navigates to /manuscript/:id/editor
                                   |
                                   v
                          EditorWithSidebar (hides bottom nav)
                           /              \
                          /                \
                         v                  v
                 ChapterSidebar        SuperEditor area
                 (260px fixed)         (toolbar + editor + status)
                       |
            tap chapter row --> forced save current chapter
                       |
                       v
            ChapterNotifier.loadDocument(manuscriptId, chapterId)
                       |
                       v
            Deserialize Markdown -> MutableDocument -> swap into Editor
                       |
              +--------+--------+
              |                  |
              v                  v
        [edit content]    [debounced save]
              |                  |
              v                  v
        Editor listener     Timer(2-3s) -> serialize to Markdown -> Hive put
              |
              +-- chapter switch --> forced save --> load next
              |
              +-- back to library --> forced save --> navigate
              |
              +-- app pause --> forced save
```

### Recommended Project Structure
```
lib/features/manuscript/
├── domain/
│   ├── manuscript.dart          # Manuscript entity (immutable, copyWith, toJson/fromJson)
│   ├── chapter.dart             # Chapter entity (immutable, copyWith, toJson/fromJson)
│   └── manuscript_genre.dart    # Genre enum/constants + color mapping
├── application/
│   ├── manuscript_notifier.dart # AsyncNotifier for manuscript CRUD
│   ├── chapter_notifier.dart    # AsyncNotifier for chapter CRUD + document management
│   ├── chapter_auto_save.dart   # Auto-save service (debounced + forced)
│   └── manuscript_sort.dart     # Sort mode enum + comparator logic
├── infrastructure/
│   ├── manuscript_repository.dart  # Hive box wrapper for manuscripts
│   ├── chapter_repository.dart     # Hive box wrapper for chapters
│   └── manuscript_purge_service.dart # Soft-delete auto-purge job
└── presentation/
    ├── manuscript_library_page.dart    # New home screen (card grid)
    ├── manuscript_card.dart            # Genre-colored card widget
    ├── manuscript_create_dialog.dart   # Quick create dialog
    ├── manuscript_create_page.dart     # Detailed create page
    ├── manuscript_settings_page.dart   # Metadata editing page
    ├── editor_with_sidebar.dart        # Editor + ChapterSidebar wrapper
    ├── chapter_sidebar.dart            # Fixed-width sidebar with reorderable list
    ├── chapter_sidebar_row.dart        # Chapter row widget
    ├── chapter_create_dialog.dart      # New chapter dialog
    ├── chapter_rename_dialog.dart      # Rename dialog
    └── chapter_context_menu.dart       # Context menu popup
```

### Pattern 1: Immutable Entity with Hive TypeAdapter
**What:** Domain entities are immutable classes with `copyWith`, `toJson`, `fromJson`, and manual Hive TypeAdapters.
**When to use:** All new domain entities (Manuscript, Chapter).
**Example:**
```dart
// Source: Verified from lib/core/domain/fragment.dart and lib/core/infrastructure/hive_adapters.dart

class Manuscript {
  final String id;
  final String title;
  final String? description;
  final String genre;
  final int targetWordCount;
  final String status; // 构思中/写作中/已完成
  final String? worldSettingId;
  final List<String> characterCardIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String coverLetter; // max 2 chars

  const Manuscript({
    required this.id,
    required this.title,
    this.description,
    required this.genre,
    this.targetWordCount = 0,
    this.status = '构思中',
    this.worldSettingId,
    this.characterCardIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.coverLetter,
  });

  Manuscript copyWith({...}) => Manuscript(...);
  factory Manuscript.fromJson(Map<String, dynamic> json) => Manuscript(...);
  Map<String, dynamic> toJson() => {...};
}

// TypeAdapter follows existing pattern in hive_adapters.dart
class ManuscriptAdapter extends TypeAdapter<Manuscript> {
  @override
  final int typeId = HiveTypeIds.manuscript; // = 2, already reserved!

  @override
  Manuscript read(BinaryReader reader) {
    final json = reader.readMap() as Map<String, dynamic>;
    return Manuscript.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, Manuscript obj) {
    writer.writeMap(obj.toJson());
  }
}
```

### Pattern 2: AsyncNotifier with Hive Repository
**What:** Riverpod AsyncNotifier manages async CRUD state backed by Hive box.
**When to use:** ManuscriptNotifier, ChapterNotifier.
**Example:**
```dart
// Source: Verified from lib/features/knowledge/application/character_card_notifier.dart pattern

final manuscriptNotifierProvider =
    AsyncNotifierProvider<ManuscriptNotifier, List<Manuscript>>(
      ManuscriptNotifier.new,
    );

class ManuscriptNotifier extends AsyncNotifier<List<Manuscript>> {
  @override
  Future<List<Manuscript>> build() async {
    final repo = await ref.watch(manuscriptRepositoryProvider.future);
    return repo.getAll();
  }

  Future<void> create(Manuscript manuscript) async {
    final repo = await ref.read(manuscriptRepositoryProvider.future);
    await repo.add(manuscript);
    ref.invalidateSelf();
  }
  // ... update, softDelete, purge
}
```

### Pattern 3: Debounced Auto-Save with Forced-Save Triggers
**What:** Timer-based debounced save (2-3s) with immediate save on chapter switch, navigation, and app lifecycle pause.
**When to use:** Chapter content auto-save.
**Example:**
```dart
// Source: Adapted from lib/features/stats/application/writing_stats_collector.dart pattern
// (30s debounced writes, already established in codebase)

class ChapterAutoSave {
  final ChapterRepository _repository;
  final Duration debounceDuration;

  Timer? _debounceTimer;
  String? _currentChapterId;
  String? _pendingMarkdown;
  bool _isDirty = false;

  void onDocumentChanged(String chapterId, String markdown) {
    _currentChapterId = chapterId;
    _pendingMarkdown = markdown;
    _isDirty = true;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, _flush);
  }

  Future<void> forceSave() async {
    _debounceTimer?.cancel();
    await _flush();
  }

  Future<void> _flush() async {
    if (!_isDirty || _currentChapterId == null) return;
    _isDirty = false;
    await _repository.updateDocumentContent(_currentChapterId!, _pendingMarkdown!);
  }

  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }
}
```

### Pattern 4: Document Serialization via Markdown
**What:** SuperEditor documents are serialized to/from Markdown for persistence. The CONTEXT.md says "JSON" but the actual serialization format for SuperEditor is Markdown via `super_editor_markdown`.
**When to use:** Storing and loading chapter content.
**Example:**
```dart
// Source: Context7 /superlistapp/super_editor docs - Markdown serialization

import 'package:super_editor/super_editor.dart';
import 'package:super_editor_markdown/super_editor_markdown.dart';

// Serialize current document to Markdown string
String serializeDocument(Document document) {
  return serializeDocumentToMarkdown(document);
}

// Deserialize Markdown string back to MutableDocument
MutableDocument deserializeDocument(String markdown) {
  return deserializeMarkdownToDocument(markdown);
}
```

**IMPORTANT CORRECTION:** CONTEXT.md D-04 says `documentJson` and Claude's discretion says "SuperEditor's built-in `Document.fromJson`/`toJson`". However, SuperEditor does NOT have native `Document.fromJson`/`toJson` methods. The official serialization path is via `super_editor_markdown`: `serializeDocumentToMarkdown()` and `deserializeMarkdownToDocument()`. The Chapter entity field should store serialized Markdown (or JSON-wrapped Markdown) rather than expecting a Document JSON format. This is a factual correction the planner must account for. [VERIFIED: Context7 super_editor docs confirm Markdown is the serialization path.]

### Pattern 5: EditorWithSidebar Layout
**What:** Row layout with fixed-width ChapterSidebar + VerticalDivider + expanded Editor area. Hides bottom nav via conditional rendering in AppShellScaffold.
**When to use:** Manuscript editing mode.
**Example:**
```dart
// Layout follows existing AppShellScaffold Row pattern

class EditorWithSidebar extends ConsumerStatefulWidget {
  final String manuscriptId;
  const EditorWithSidebar({super.key, required this.manuscriptId});
  // ...
}

// Build method layout:
Row(
  children: [
    SizedBox(width: 260, child: ChapterSidebar(manuscriptId: widget.manuscriptId)),
    VerticalDivider(width: 1, thickness: 1, color: colorScheme.outline),
    Expanded(child: EditorArea(manuscriptId: widget.manuscriptId)),
  ],
)
```

### Anti-Patterns to Avoid
- **Storing SuperEditor Document as raw JSON:** SuperEditor's internal node structure is not designed for stable JSON serialization across versions. Use `super_editor_markdown` for persistence. The field name in the Chapter entity should be `documentContent` (Markdown string), not `documentJson` as stated in D-04. The planner should store Markdown.
- **Creating a single Hive box for manuscripts and chapters:** Follow the existing pattern of one box per entity type (`manuscripts` and `chapters` boxes separately).
- **Rebuilding the entire Editor widget on chapter switch:** Only swap the `Document` inside the existing `Editor` instance. The Editor, Composer, and toolbar should remain mounted.
- **Mutating Manuscript/Chapter entities directly:** Always use `copyWith` pattern. The entities are immutable per D-03/D-04.
- **Using the editor's Document node IDs as stable references:** SuperEditor node IDs are generated with `Editor.createNodeId()` and are not stable across serialization/deserialization cycles. Do not store node IDs externally.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Document serialization | Custom JSON serialization of Document nodes | `super_editor_markdown` package | Official companion package. Handles all node types (paragraphs, lists, images, headers, horizontal rules). Custom serialization breaks across super_editor version updates. |
| Drag-and-drop reordering | Custom Draggable/DragTarget widgets | Flutter SDK `ReorderableListView` | Built-in Material reorder animations, accessibility, keyboard support. No external package needed. |
| Debounced saving | Custom Timer + callback system | Adapt `WritingStatsCollector` pattern | Already established 30s debounced write pattern in codebase. Chapter auto-save follows the same Timer-based approach. |
| TypeAdapter registration | Auto-registration via code generation | Manual TypeAdapter pattern (existing) | All existing adapters are manual (FragmentAdapter, CharacterCardAdapter, etc.). Consistency matters more than automation here. |
| Genre color mapping | Hardcoded color maps scattered in widgets | `ManuscriptGenreColors` utility class | Centralized, testable, reusable. Follows `GraphColor` pattern from Phase 10. |
| App lifecycle detection | Custom platform channel | `WidgetsBindingObserver` | Flutter's built-in lifecycle observer. `didChangeAppLifecycleState` for paused/inactive states. |

**Key insight:** The codebase already has every pattern this phase needs. The debounced write, TypeAdapter, AsyncNotifier, and export bundle patterns are all established. The phase is primarily about composition and extension, not invention.

## Common Pitfalls

### Pitfall 1: SuperEditor Document Swap Loses State
**What goes wrong:** When switching chapters, replacing the entire `Editor` widget causes toolbar, selection, and overlay state to reset. User sees a flash and loses undo history.
**Why it happens:** `Editor` is stateful and tightly coupled to its `Document`. Creating a new `Editor` on every chapter switch is the naive approach.
**How to avoid:** Keep the same `Editor` instance. Only swap the `Document` by replacing nodes in the existing `MutableDocument` (or creating a new `MutableDocument` and reconfiguring the `Editor`). The Editor's `Composer` selection should be cleared/reset on swap.
**Warning signs:** Toolbar flickers, undo history disappears, floating toolbar position jumps on chapter switch.

### Pitfall 2: Hive Type ID Collision
**What goes wrong:** Using a `typeId` that's already registered causes deserialization failures and data corruption.
**Why it happens:** The `HiveTypeIds` registry already has entries 0-8. `manuscript = 2` is already reserved (but unused). A new `chapter` type ID must be assigned a new slot.
**How to avoid:** Use `HiveTypeIds.manuscript = 2` (already reserved). Add `HiveTypeIds.chapter = 9` (next available slot). Register both adapters in `main.dart`.
**Warning signs:** Hive read errors on app restart, `TypeError` when casting deserialized objects.

### Pitfall 3: Auto-Save Race Condition
**What goes wrong:** Debounced save timer fires at the same time as a forced save (e.g., user switches chapters right as the debounce timer fires).
**Why it happens:** Two save paths (debounce + forced) can overlap if not properly coordinated.
**How to avoid:** Cancel the debounce timer before executing forced save. Use a single `_flush()` method that both paths call. Set a `_isSaving` flag to prevent concurrent writes.
**Warning signs:** Occasional data loss, stale content loaded on chapter switch.

### Pitfall 4: StatefulShellRoute Conflicts with Sub-Routes
**What goes wrong:** Adding `/manuscript/:id/editor` as a sub-route inside a `StatefulShellBranch` causes the bottom navigation to persist when it should be hidden.
**Why it happens:** `StatefulShellRoute.indexedStack` preserves all branches. Sub-routes within a branch share the branch's shell.
**How to avoid:** The manuscript editor route should be a top-level `GoRoute` (outside `StatefulShellRoute`) so it can fully control the scaffold (hide bottom nav, show AppBar back button). The library page stays as Branch 1 default. Navigating to the editor uses `context.go('/manuscript/:id/editor')` which exits the shell.
**Warning signs:** Bottom nav visible inside manuscript editor, back button doesn't work, branch state lost.

### Pitfall 5: sortOrder Recalculation Gaps
**What goes wrong:** After deleting or reordering chapters, `sortOrder` values have gaps (0, 2, 5, 7) causing incorrect insertion positions for new chapters.
**Why it happens:** ReorderableListView only reports old/new index. Naive implementation just swaps two sortOrder values without compacting.
**How to avoid:** After every reorder, delete, or split operation, recalculate all sortOrder values to be sequential (0, 1, 2, 3...). This is a simple iteration over the sorted chapter list.
**Warning signs:** New chapters appear in wrong position, drag-and-drop behaves unpredictably.

### Pitfall 6: Large Document Markdown Serialization Performance
**What goes wrong:** Serializing a large chapter (50k+ characters) to Markdown on every debounced save causes UI jank.
**Why it happens:** `serializeDocumentToMarkdown()` iterates all document nodes synchronously on the main isolate.
**How to avoid:** The 2-3 second debounce naturally limits serialization frequency. For very large chapters, consider computing the diff (check if document actually changed) before serializing. Monitor performance; the current single-editor setup suggests chapters won't exceed practical limits.
**Warning signs:** UI stutters after typing, debounced save takes >16ms.

### Pitfall 7: Data Migration from Single-Editor Model
**What goes wrong:** Existing users have editor content stored implicitly (in the Editor's MutableDocument, not persisted to Hive). After the upgrade, their existing content disappears.
**Why it happens:** The current `EditorPage` creates a new `MutableDocument` with placeholder text each time. There's no persisted manuscript data to migrate.
**How to avoid:** On first launch after upgrade, create a default manuscript titled something like "我的文稿" and move any in-memory editor content into it. However, since the current editor starts with placeholder text each session, there's likely no real user content to preserve. The migration should focus on creating a welcoming first manuscript, not data migration. Verify this assumption during planning.
**Warning signs:** Users report lost content after upgrade.

## Code Examples

### Chapter Entity with Markdown Content Storage
```dart
// Source: Follows lib/core/domain/fragment.dart pattern

class Chapter {
  final String id;
  final String manuscriptId;
  final String title;
  final int sortOrder;
  final String status; // 草稿/初稿/精修/定稿
  final String documentContent; // Serialized Markdown (NOT JSON)
  final DateTime createdAt;
  final DateTime updatedAt;

  const Chapter({
    required this.id,
    required this.manuscriptId,
    required this.title,
    required this.sortOrder,
    this.status = '草稿',
    this.documentContent = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Word count is computed from documentContent, not stored.
  int get wordCount {
    if (documentContent.isEmpty) return 0;
    // Chinese text: count characters excluding whitespace
    return documentContent.replaceAll(RegExp(r'\s'), '').length;
  }

  Chapter copyWith({
    String? id,
    String? manuscriptId,
    String? title,
    int? sortOrder,
    String? status,
    String? documentContent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chapter(
      id: id ?? this.id,
      manuscriptId: manuscriptId ?? this.manuscriptId,
      title: title ?? this.title,
      sortOrder: sortOrder ?? this.sortOrder,
      status: status ?? this.status,
      documentContent: documentContent ?? this.documentContent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
    id: json['id'] as String,
    manuscriptId: json['manuscriptId'] as String,
    title: json['title'] as String,
    sortOrder: json['sortOrder'] as int,
    status: json['status'] as String? ?? '草稿',
    documentContent: json['documentContent'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'manuscriptId': manuscriptId,
    'title': title,
    'sortOrder': sortOrder,
    'status': status,
    'documentContent': documentContent,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
```

### Chapter Split Operation
```dart
// Source: SuperEditor Context7 docs - node manipulation API

/// Splits a chapter at the current cursor position into two chapters.
/// The content before the cursor stays in the current chapter,
/// content after goes into a new chapter.
Chapter splitChapterAtCursor(
  Chapter original,
  Document editorDocument,
  DocumentPosition cursorPosition,
) {
  // 1. Serialize full document to Markdown
  final fullMarkdown = serializeDocumentToMarkdown(editorDocument);

  // 2. Find cursor offset in plain text
  // (Simplified -- actual implementation needs node + offset mapping)
  final plainText = _documentToPlainText(editorDocument);
  final splitOffset = _positionToOffset(editorDocument, cursorPosition);

  // 3. Split the Markdown content at the offset
  final beforeMarkdown = plainText.substring(0, splitOffset).trimRight();
  final afterMarkdown = plainText.substring(splitOffset).trimLeft();

  // 4. Return modified original + new chapter
  // The caller updates the original and creates the new chapter
  return original.copyWith(documentContent: afterMarkdown);
  // original gets updated with beforeMarkdown via separate copyWith
}
```

### ExportBundle Chapter-Aware Extension
```dart
// Source: Extends lib/features/story_structure/domain/export_bundle.dart

class ChapterExport {
  final String title;
  final int sortOrder;
  final String content; // Markdown or plain text

  const ChapterExport({
    required this.title,
    required this.sortOrder,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'sortOrder': sortOrder,
    'content': content,
  };
}

// Add to ExportBundle:
// final List<ChapterExport> chapters;
// manuscriptText becomes computed: chapters.map((c) => c.content).join('\n\n')
```

### Route Structure for Library -> Editor
```dart
// Source: Extends lib/app.dart GoRouter pattern

GoRouter _createRouter() {
  return GoRouter(
    initialLocation: AppConstants.manuscriptLibrary,
    routes: [
      // Top-level manuscript editor (outside StatefulShellRoute for full-screen)
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
      // StatefulShellRoute with Branch 1 now showing ManuscriptLibraryPage
      StatefulShellRoute.indexedStack(
        branches: [
          // Branch 0: Capture (unchanged)
          // Branch 1: Library (was Editor, now ManuscriptLibraryPage)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/editor', // keep path for compatibility
                builder: (context, state) => const ManuscriptLibraryPage(),
              ),
            ],
          ),
          // ... other branches unchanged
        ],
      ),
    ],
  );
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| SuperEditor 0.2.x single widget | SuperEditor 0.3.0 separated Editor/Document/Composer | super_editor 0.3.0 | Editor instance is now independent from Document. Document can be swapped without recreating the entire editor widget tree. |
| Single flat manuscriptText | Chapter-aware structured export | Phase 11 | ExportBundle gains `chapters` field. manuscriptText becomes computed property. |
| Editor as home screen | Library as home screen | Phase 11 | Branch 1 default route changes. Editor moves to a top-level route outside shell. |

**Deprecated/outdated:**
- `Document.fromJson`/`toJson` (mentioned in CONTEXT.md Claude's Discretion): SuperEditor does not have these methods natively. Use `super_editor_markdown` for serialization. [VERIFIED: Context7 docs show only Markdown and Quill Delta serialization paths.]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `super_editor_markdown` package is compatible with `super_editor: ^0.3.0-dev.20` and can be added without version conflicts | Standard Stack | Need to verify pub resolution. If incompatible, alternative is to serialize Document nodes manually. |
| A2 | No existing user content needs migration -- current editor creates placeholder text each session | Pitfall 7 | If users have modified the placeholder text and expect it preserved, a migration step is needed. |
| A3 | `ReorderableListView` (Flutter SDK) handles all drag-and-drop requirements for chapter reordering without external packages | Architecture Patterns | If `ReorderableListView` doesn't support required customization (e.g., custom drag handle position), may need `reorderables` package. |
| A4 | Chinese character count (excluding whitespace) is a sufficient word count metric for progress tracking | Code Examples | If users expect mixed-language counting (e.g., English words + Chinese characters), the counting algorithm needs adjustment. |
| A5 | The existing `Editor` instance can have its `Document` swapped without recreating the entire widget tree | Pitfall 1 | If SuperEditor 0.3.0-dev doesn't support clean Document swap, the EditorPage may need to be fully rebuilt on chapter switch, causing UX degradation. |

## Open Questions

1. **SuperEditor Document Swap Mechanism**
   - What we know: SuperEditor 0.3.0 separates Editor/Document/Composer. The Editor takes a `document` parameter.
   - What's unclear: Can we replace the `Document` reference in an existing `Editor` without disposing and recreating it? Or do we need to create a new `Editor` with the new `Document`?
   - Recommendation: The planner should create a small proof-of-concept task early (Wave 1) to verify Document swap behavior. If the Editor must be recreated, use `Key`-based widget rebuild with `ValueKey(chapterId)`.

2. **`super_editor_markdown` Version Compatibility**
   - What we know: `super_editor_markdown` is the official companion package. It's referenced in Context7 docs.
   - What's unclear: The exact version that's compatible with `super_editor: ^0.3.0-dev.20`.
   - Recommendation: Run `flutter pub add super_editor_markdown` and verify resolution succeeds. If there's a conflict, pin a compatible version.

3. **Bottom Nav Hiding Strategy**
   - What we know: CONTEXT.md says bottom nav is hidden when inside a manuscript editor.
   - What's unclear: Whether to use a top-level GoRoute (outside StatefulShellRoute) or a nested navigator within Branch 1 with a conditional scaffold.
   - Recommendation: Use a top-level GoRoute for `/manuscript/:id/editor`. This gives full control over the scaffold (no bottom nav). The library page stays inside StatefulShellRoute Branch 1. This matches the pattern described in Pitfall 4.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All | Yes | 3.44.0 (stable) | -- |
| Dart SDK | All | Yes | 3.5.4 | -- |
| super_editor | Editor | Yes | ^0.3.0-dev.20 | -- |
| super_editor_markdown | Chapter serialization | No (needs install) | -- | Manual node serialization (fragile) |
| hive_ce | Storage | Yes | ^2.19.3 | -- |
| flutter_riverpod | State management | Yes | ^3.3.1 | -- |
| go_router | Navigation | Yes | ^17.2.3 | -- |

**Missing dependencies with no fallback:**
- `super_editor_markdown` must be added for chapter content serialization. Without it, chapter persistence would require fragile manual Document node serialization that breaks across super_editor version updates.

**Missing dependencies with fallback:**
- None.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK) |
| Config file | pubspec.yaml (flutter_test dev dependency) |
| Quick run command | `flutter test test/features/manuscript/` |
| Full suite command | `flutter test` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SC-1 | Manuscript CRUD operations | unit | `flutter test test/features/manuscript/application/manuscript_notifier_test.dart` | No -- Wave 0 |
| SC-1 | Manuscript soft delete + purge | unit | `flutter test test/features/manuscript/infrastructure/manuscript_purge_service_test.dart` | No -- Wave 0 |
| SC-2 | Chapter CRUD + reorder + sortOrder recalculation | unit | `flutter test test/features/manuscript/application/chapter_notifier_test.dart` | No -- Wave 0 |
| SC-3 | Chapter document serialization roundtrip | unit | `flutter test test/features/manuscript/domain/chapter_serialization_test.dart` | No -- Wave 0 |
| SC-4 | Auto-save debounce + forced save | unit | `flutter test test/features/manuscript/application/chapter_auto_save_test.dart` | No -- Wave 0 |
| SC-5 | Template chapter skeleton creation | unit | `flutter test test/features/manuscript/application/template_chapter_test.dart` | No -- Wave 0 |
| SC-6 | Chapter-aware export bundle | unit | `flutter test test/features/manuscript/domain/chapter_export_test.dart` | No -- Wave 0 |
| SC-1 | Library page renders manuscript cards | widget | `flutter test test/features/manuscript/presentation/manuscript_library_page_test.dart` | No -- Wave 0 |
| SC-2 | Chapter sidebar reorder interaction | widget | `flutter test test/features/manuscript/presentation/chapter_sidebar_test.dart` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/features/manuscript/`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/features/manuscript/application/manuscript_notifier_test.dart` -- covers SC-1
- [ ] `test/features/manuscript/application/chapter_notifier_test.dart` -- covers SC-2
- [ ] `test/features/manuscript/domain/chapter_serialization_test.dart` -- covers SC-3
- [ ] `test/features/manuscript/application/chapter_auto_save_test.dart` -- covers SC-4
- [ ] `test/features/manuscript/application/template_chapter_test.dart` -- covers SC-5
- [ ] `test/features/manuscript/domain/chapter_export_test.dart` -- covers SC-6
- [ ] `test/features/manuscript/presentation/manuscript_library_page_test.dart` -- covers SC-1 UI
- [ ] `test/features/manuscript/presentation/chapter_sidebar_test.dart` -- covers SC-2 UI
- [ ] Package install: `flutter pub add super_editor_markdown` -- needs verification

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No auth -- local-only app |
| V3 Session Management | No | No sessions -- local-only app |
| V4 Access Control | No | Single-user local app |
| V5 Input Validation | Yes | Validate manuscript title, chapter title, genre inputs. Max lengths enforced. |
| V6 Cryptography | No | Hive encryption already configured via HiveAesCipher. No new crypto needed. |

### Known Threat Patterns for Flutter/Hive Local Storage

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Data loss on storage corruption | Denial of Service | Auto-save with debouncing + forced save. Soft delete with 30-day recovery. |
| Malicious input in manuscript metadata | Tampering | Input validation on title length (reasonable max), genre from preset list, status from enum. |

## Sources

### Primary (HIGH confidence)
- Codebase analysis: `lib/core/infrastructure/hive_adapters.dart` -- TypeAdapter pattern, HiveTypeIds registry (typeId 2 reserved for manuscript)
- Codebase analysis: `lib/features/editor/presentation/editor_page.dart` -- Editor instance management, document plain text extraction, stats integration
- Codebase analysis: `lib/features/editor/presentation/editor_provider.dart` -- `createDefaultEditor()` creates MutableDocument with placeholder
- Codebase analysis: `lib/features/stats/application/writing_stats_collector.dart` -- Debounced write pattern (30s Timer)
- Codebase analysis: `lib/features/story_structure/domain/export_bundle.dart` -- Current flat manuscriptText structure
- Codebase analysis: `lib/features/story_structure/presentation/story_structure_page.dart` -- _buildExportBundle reads editor document directly
- Codebase analysis: `lib/app.dart` -- StatefulShellRoute.indexedStack with 6 branches
- Codebase analysis: `lib/core/presentation/app_shell.dart` -- Sidebar + content Row pattern
- Context7 /superlistapp/super_editor -- Document serialization (Markdown), node manipulation API, Editor/Document/Composer separation

### Secondary (MEDIUM confidence)
- Codebase analysis: `lib/features/templates/application/template_instantiation_service.dart` -- Template instantiation for WorldSetting + CharacterCards (extension point for chapter skeleton)

### Tertiary (LOW confidence)
- super_editor_markdown version compatibility with super_editor ^0.3.0-dev.20 -- needs pub resolution verification

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All packages already in use except super_editor_markdown (official companion). No new patterns needed.
- Architecture: HIGH - Follows established four-layer clean architecture. Feature module structure matches existing features/editor, features/knowledge.
- Pitfalls: HIGH - Derived from deep codebase analysis of existing patterns (Hive adapters, Editor lifecycle, route structure, export bundle).
- Serialization: MEDIUM - super_editor_markdown is the correct approach but exact version compatibility and Document swap mechanism need verification.

**Research date:** 2026-06-06
**Valid until:** 2026-07-06 (stable -- Flutter/SuperEditor APIs don't change frequently)
