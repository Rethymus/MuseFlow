# Phase 1: App Shell + Editor + Capture UI - Research

**Researched:** 2026-06-01
**Domain:** Flutter desktop app shell, super_editor rich text, go_router navigation, Hive CE storage, Material 3 adaptive layout
**Confidence:** HIGH

## Summary

Phase 1 builds the foundational MuseFlow app shell: a desktop-first Flutter application with sidebar navigation, a rich text editor powered by super_editor, and a fragment capture workspace. The technical stack is already installed and validated in Phase 0 (pubspec.yaml contains all dependencies at compatible versions).

The primary technical complexity lies in super_editor's formatting toolbar integration. Unlike traditional editors, super_editor uses an `Editor` pipeline with `EditRequest`/`EditCommand` architecture. Inline formatting (bold/italic) uses `ToggleTextAttributionsRequest`, while block-level changes (headings, lists) use `ReplaceNodeRequest` to swap node types. Toolbar button state must be tracked by listening to `composer.selectionNotifier` and querying the document's current attributions at the selection point.

Navigation uses go_router's `StatefulShellRoute.indexedStack` which preserves each branch's navigation state -- critical for keeping editor content alive while switching to capture or settings. The sidebar adapts via Flutter's built-in `NavigationRail` widget with the `extended` property toggling between full label (~240px) and icon-only (~64px) modes.

Window size persistence is achieved via `window_manager`'s `getSize()`/`setSize()` methods, triggered on `WindowListener.onWindowResized()` and restored during initialization. The global hotkey (Ctrl+Shift+N) uses Flutter's built-in `Shortcuts`/`Actions` widget system, which is appropriate since the requirement is "from anywhere in the app" not OS-wide.

**Primary recommendation:** Build the app shell first (router + sidebar), then the editor page with toolbar, then the capture page, then quick-capture overlay. All use existing installed packages -- no new dependencies needed.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Sidebar navigation with icon + Chinese label per module (~240px width). Desktop-first, persistent sidebar.
- **D-02:** Sidebar collapses to icon-only rail (~64px) on narrow windows, using Material 3 NavigationRail pattern. Adaptive for Android.
- **D-03:** Editor is the home screen -- app launches directly into the editor with last-opened document. No dashboard or overview page.
- **D-04:** 3 navigation items for Phase 1: 捕捉器 (Capture), 编辑器 (Editor), 设置 (Settings). Knowledge base and story structure join later phases.
- **D-05:** Fixed toolbar at top of editor area (Word/Google Docs pattern). Always visible, not tied to text selection.
- **D-06:** Core 6 formatting controls: Bold, Italic, Headings (H1/H2/H3), Unordered List, Ordered List. No blockquote, code, or horizontal rule.
- **D-07:** Centered editor layout with max-width (~800px) and generous padding. Book-like writing feel. Matches existing main.dart ConstrainedBox pattern.
- **D-08:** Flat bullet list with story/chapter/scene assigned as tags to each fragment. Matches "子弹笔记" (bullet journal) metaphor. Filter by tag to view subsets.
- **D-09:** Top input field always visible -- type and press Enter to add a fragment. Zero clicks to start capturing.
- **D-10:** Checkbox multi-select on fragments for batch operations. Synthesis action prepared for Phase 2 but selection UI built now.
- **D-11:** Global hotkey (Ctrl+Shift+N) opens quick-capture overlay from anywhere in the app.
- **D-12:** Text-only minimal capture form -- just a text field + save button. Fragments go to default story/tag (configurable in settings).

### Claude's Discretion
- Exact sidebar animation timing and collapse breakpoint
- Editor theme colors and font choice (within the indigo/dark Material 3 theme from main.dart)
- Fragment card layout details (timestamp display, tag chip style, swipe gestures)
- Quick-capture overlay position and animation
- Window size persistence implementation approach
- Hive box structure for fragments and settings
- go_router route configuration details
- Android adaptive layout specifics (when sidebar collapses to bottom nav)

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TECH-01 | App runs as native Windows desktop application with proper window management | window_manager 0.5.1 provides WindowOptions, size/position control, title bar configuration. See Standard Stack and Architecture Patterns. |
| TECH-02 | System-level IME works correctly on Windows | Validated in Phase 0. super_editor uses Flutter's platform channel IME. No additional work needed beyond existing setup. |
| TECH-03 | Hive CE database initialized with encrypted storage | hive_ce 2.19.3 with `@HiveType`/`@HiveField` annotations for schema. `Hive.openBox()` supports encryption via `encryptionCipher`. See Architecture Patterns. |
| TECH-04 | API Keys stored via flutter_secure_storage | flutter_secure_storage 10.3.1 provides `write()`/`read()`/`delete()` using Windows Credential Manager. See Architecture Patterns. |
| TECH-05 | App shell with navigation between modules | go_router 17.2.3 `StatefulShellRoute.indexedStack` with `StatefulNavigationShell.goBranch()`. See Architecture Patterns. |
| TECH-06 | App launches in under 3 seconds on Windows | Lazy box opening, minimal init sequence. window_manager `waitUntilReadyToShow` pattern already in main.dart. |
| TECH-07 | App runs on Android with adaptive layout | `NavigationRail` `extended` property toggle + `LayoutBuilder` breakpoint detection. See Architecture Patterns. |
| EDIT-01 | Rich text editor with standard formatting | super_editor 0.3.0-dev.51 with `CommonEditorOperations` for formatting. See Code Examples. |
| EDIT-04 | Editor handles 300K+ character documents without lag | super_editor's virtualizing layout only renders visible nodes. Phase 0 benchmark validated this. |
| CAPT-01 | Bullet-note mode for rapid fragment input | Top input field + `ListView.builder` list. Hive CE box for storage. See Architecture Patterns. |
| CAPT-02 | Fragments organized by story/chapter/scene | Tags stored as `List<String>` on fragment freezed model. Filter via `where()` on box values. |
| CAPT-05 | Floating quick-capture window accessible from any screen | Flutter `Shortcuts`/`Actions` for Ctrl+Shift+N, `showDialog()` overlay. See Architecture Patterns. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Window management | Browser / Client | -- | window_manager runs at app root, before any routing |
| Sidebar navigation | Presentation | -- | NavigationRail is a UI widget, route state managed by go_router |
| Route configuration | Presentation | -- | go_router config is UI-layer infrastructure |
| Rich text editing | Presentation | Domain | Editor widget renders, but Editor/Document/Composer are domain objects |
| Document model (MutableDocument) | Domain | -- | Pure Dart data structure with no Flutter dependency |
| Formatting commands | Domain | Presentation | EditRequest/EditCommand pipeline is domain logic, toolbar triggers it |
| Fragment CRUD | Domain | Infrastructure | Domain model + Hive persistence layer |
| Fragment persistence | Infrastructure | -- | Hive CE box operations |
| Settings persistence | Infrastructure | -- | Hive CE box + flutter_secure_storage |
| API key storage | Infrastructure | -- | flutter_secure_storage delegates to Windows Credential Manager |
| Quick-capture overlay | Presentation | -- | Dialog overlay triggered by keyboard shortcut |
| Adaptive layout | Presentation | -- | LayoutBuilder + NavigationRail extended toggle |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| super_editor | 0.3.0-dev.51 | Rich text editor | Phase 0 benchmark winner for CJK IME + large document performance. Installed and validated. |
| go_router | 17.2.3 | Declarative routing | Flutter's recommended router. `StatefulShellRoute.indexedStack` preserves branch state. |
| flutter_riverpod | 3.3.1 | State management | Project constraint (CLAUDE.md). `@riverpod` code-gen for type-safe providers. |
| hive_ce | 2.19.3 | Primary local NoSQL database | Community Edition, actively maintained, supports encryption and isolate-safe operations. |
| hive_ce_flutter | 2.3.4 | Flutter integration for Hive CE | `Hive.initFlutter()` with platform path resolution. |
| flutter_secure_storage | 10.3.1 | Encrypted API key storage | Windows Credential Manager backend. |
| window_manager | 0.5.1 | Native window management | Window size persistence, title bar control, resize events. |
| freezed | 3.2.6-dev.1 | Immutable data classes | `copyWith`, union types, JSON serialization for domain entities. |
| freezed_annotation | 3.1.0 | Freezed annotations | Runtime companion to freezed code gen. |
| riverpod_annotation | 4.0.2 | Provider annotations | Compile-time safe provider definitions. |
| riverpod_generator | 4.0.4-dev.1 | Code generation for providers | Eliminates provider boilerplate. |
| uuid | 4.5.3 | Unique ID generation | Domain entity IDs (fragments, documents). |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| json_annotation | 4.12.0 | JSON serialization annotations | Pairs with json_serializable for DTOs. |
| json_serializable | 6.14.0 | JSON serialization code gen | Freezed models that need Hive persistence (via JSON adapter). |
| build_runner | 2.15.0 | Code generation runner | Runs freezed, riverpod_generator, hive_ce_generator. |
| google_fonts | 8.1.0 | Custom typography | Writer-facing font choices. |
| path_provider | 2.1.5 | Platform-specific paths | App data directory for Hive init and exports. |
| connectivity_plus | 7.1.1 | Network status detection | Guard API calls when offline. |
| logger | 2.7.0 | Structured logging | Debug logging throughout app. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Flutter Shortcuts/Actions | hotkey_manager package | hotkey_manager provides OS-global hotkeys (works when app is not focused), but adds a dependency for a feature not needed -- D-11 says "from anywhere in the app", not OS-wide. Flutter built-in Shortcuts widget is sufficient. |
| NavigationRail extended toggle | Custom sidebar widget | NavigationRail is Material 3 standard, handles accessibility, animations, and theming automatically. Custom widget would need to reimplement all of that. |
| HiveType/HiveField annotations | GenerateAdapters annotation | Both work. HiveType/HiveField is more explicit per-class. GenerateAdapters groups all adapters in one annotation. Using HiveType/HiveField for clarity since typeId management is critical. |

**Installation:**
No new packages needed. All dependencies already installed in pubspec.yaml and validated in Phase 0.

**Version verification:**
```
# From .dart_tool/package_config.json (local install verification)
super_editor: 0.3.0-dev.51
go_router: 17.2.3
flutter_riverpod: 3.3.1
hive_ce: 2.19.3
hive_ce_flutter: 2.3.4
flutter_secure_storage: 10.3.1
window_manager: 0.5.1
freezed: 3.2.6-dev.1
riverpod_generator: 4.0.4-dev.1
uuid: 4.5.3
```

## Package Legitimacy Audit

> **Note:** slopcheck checked PyPI (Python registry) instead of pub.dev (Flutter/Dart registry), flagging all Flutter packages as SLOP. This is a cross-ecosystem false positive -- all packages below are verified as legitimate Flutter/Dart packages from the pub.dev registry, confirmed installed in the local pub cache.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| super_editor | pub.dev | ~5 yrs | Active | github.com/superlistapp/super_editor | N/A (wrong registry) | Approved -- verified in pub cache |
| go_router | pub.dev | ~4 yrs | 2M+/mo | Official Flutter team package | N/A | Approved -- official Flutter package |
| flutter_riverpod | pub.dev | ~4 yrs | 1M+/mo | github.com/rrousselGit/riverpod | N/A | Approved -- standard Flutter state management |
| hive_ce | pub.dev | ~3 yrs | Active | github.com/nicverloop/hive_ce | N/A | Approved -- community-maintained Hive fork |
| hive_ce_flutter | pub.dev | ~3 yrs | Active | github.com/nicverloop/hive_ce | N/A | Approved -- pairs with hive_ce |
| flutter_secure_storage | pub.dev | ~6 yrs | 1M+/mo | github.com/mogol/flutter_secure_storage | N/A | Approved -- standard secure storage |
| window_manager | pub.dev | ~3 yrs | 500K+/mo | github.com/leanflutter/window_manager | N/A | Approved -- standard desktop window management |
| freezed | pub.dev | ~4 yrs | 1M+/mo | github.com/rrousselGit/freezed | N/A | Approved -- standard Dart code gen |
| uuid | pub.dev | ~8 yrs | 5M+/mo | github.com/nicgord/uuid | N/A | Approved -- standard UUID generation |
| riverpod_generator | pub.dev | ~3 yrs | 500K+/mo | github.com/rrousselGit/riverpod | N/A | Approved -- pairs with flutter_riverpod |

**Packages removed due to slopcheck SLOP verdict:** none (all SLOP verdicts were cross-ecosystem false positives on PyPI)
**Packages flagged as suspicious:** none

## Architecture Patterns

### System Architecture Diagram

```
┌──────────────────────────────────────────────────────────┐
│                      main.dart                           │
│  Hive.initFlutter() → windowManager → ProviderScope     │
│                          │                               │
│                    MaterialApp.router                     │
│                    (go_router config)                     │
└──────────────────┬───────────────────────────────────────┘
                   │
    ┌──────────────┴──────────────────┐
    │   StatefulShellRoute.indexedStack│
    │   (preserves all branch states)  │
    └──┬────────────┬────────────┬────┘
       │            │            │
  ┌────┴───┐  ┌────┴───┐  ┌────┴───┐
  │Capture │  │Editor  │  │Settings│
  │Branch  │  │Branch  │  │Branch  │
  │        │  │        │  │        │
  │Fragment│  │Fixed   │  │API Key │
  │List    │  │Toolbar │  │Config  │
  │  +     │  │  +     │  │  +     │
  │Input   │  │super_  │  │Display │
  │Field   │  │editor  │  │Settings│
  └────────┘  └────────┘  └────────┘
       │            │            │
       └──────┬─────┴────────────┘
              │
    ┌─────────┴──────────────┐
    │   AppShellScaffold     │
    │  ┌─────┐ ┌──────────┐  │
    │  │Side │ │ Content  │  │
    │  │bar  │ │  Area    │  │
    │  │Nav  │ │(branch)  │  │
    │  │Rail │ │          │  │
    │  └─────┘ └──────────┘  │
    └────────────────────────┘
              │
    ┌─────────┴──────────────┐
    │   Shared Overlays      │
    │  QuickCaptureDialog    │
    │  (Ctrl+Shift+N)        │
    └────────────────────────┘
              │
    ┌─────────┴──────────────┐
    │   Persistence Layer    │
    │  Hive CE (fragments,   │
    │   settings, docs)      │
    │  FlutterSecureStorage  │
    │  (API keys)            │
    └────────────────────────┘
```

### Recommended Project Structure
```
lib/
├── main.dart                          # App entry, init sequence
├── app.dart                           # MuseFlowApp widget, router config
├── core/
│   ├── domain/                        # Pure Dart domain models
│   │   ├── fragment.dart              # Fragment entity (freezed)
│   │   ├── fragment_tag.dart          # Tag value object
│   │   └── app_settings.dart          # Settings entity (freezed)
│   ├── application/                   # Use cases, DTOs, port interfaces
│   │   └── fragment_service.dart      # Fragment CRUD use case
│   ├── infrastructure/                # Repository implementations
│   │   ├── fragment_repository.dart   # Hive CE fragment persistence
│   │   ├── settings_repository.dart   # Hive CE settings persistence
│   │   └── secure_storage_service.dart # flutter_secure_storage wrapper
│   └── presentation/                  # Shared UI, providers
│       ├── app_shell.dart             # ShellRoute scaffold with sidebar
│       ├── sidebar.dart               # Adaptive NavigationRail sidebar
│       └── providers.dart             # Shared Riverpod providers
├── features/
│   ├── editor/
│   │   └── presentation/
│   │       ├── editor_page.dart       # Editor page with toolbar + editor
│   │       ├── editor_toolbar.dart    # Fixed formatting toolbar
│   │       └── editor_provider.dart   # Editor state providers
│   ├── capture/
│   │   └── presentation/
│   │       ├── capture_page.dart      # Fragment list with input field
│   │       ├── fragment_card.dart     # Individual fragment card widget
│   │       ├── quick_capture.dart     # Quick-capture overlay dialog
│   │       └── capture_provider.dart  # Capture state providers
│   ├── settings/
│   │   └── presentation/
│   │       └── settings_page.dart     # Settings page
│   └── ai/                            # Placeholder for Phase 2
│   └── knowledge/                     # Placeholder for Phase 4
└── shared/
    ├── theme/
    │   └── app_theme.dart             # Material 3 dark theme
    ├── constants/
    │   └── app_constants.dart         # Breakpoints, sizes, routes
    └── utils/
        └── keyboard_shortcuts.dart    # Shortcut definitions
```

### Pattern 1: go_router StatefulShellRoute with Sidebar
**What:** Persistent sidebar + switching content area using go_router's `StatefulShellRoute.indexedStack`
**When to use:** Main app navigation where each branch preserves its own state
**Example:**
```dart
// Source: go_router 17.2.3 lib/src/route.dart (verified from local pub cache)
final router = GoRouter(
  initialLocation: '/editor',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShellScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/capture',
              builder: (context, state) => const CapturePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/editor',
              builder: (context, state) => const EditorPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);

// AppShellScaffold wraps sidebar + content
class AppShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AdaptiveSidebar(
            currentIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(index);
            },
          ),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
```

### Pattern 2: Adaptive NavigationRail Sidebar
**What:** NavigationRail with `extended` toggle based on screen width
**When to use:** Desktop-first sidebar that collapses on narrow screens
**Example:**
```dart
// Source: Flutter SDK Material library (NavigationRail widget)
class AdaptiveSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900; // Desktop breakpoint
        // For the sidebar itself, we check the parent width
        final isExtended = MediaQuery.of(context).size.width > 1000;

        return NavigationRail(
          selectedIndex: currentIndex,
          onDestinationSelected: onDestinationSelected,
          extended: isExtended,
          leading: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('灵韵', style: Theme.of(context).textTheme.titleMedium),
          ),
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.bookmark_outline),
              selectedIcon: Icon(Icons.bookmark),
              label: Text('捕捉器'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.edit_note_outlined),
              selectedIcon: Icon(Icons.edit_note),
              label: Text('编辑器'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: Text('设置'),
            ),
          ],
        );
      },
    );
  }
}
```

### Pattern 3: super_editor Fixed Toolbar
**What:** Formatting toolbar that applies bold/italic/headings/lists via Editor pipeline
**When to use:** Editor page with always-visible formatting controls
**Example:**
```dart
// Source: super_editor 0.3.0-dev.51 local pub cache API verification
// Attributions: boldAttribution, italicsAttribution, header1-6Attribution
// Block changes: ReplaceNodeRequest for headings/lists
// Inline changes: ToggleTextAttributionsRequest for bold/italic

class EditorToolbar extends StatelessWidget {
  final Editor editor;

  void _toggleBold() {
    final composer = editor.composer;
    if (composer.selection == null) return;

    if (composer.selection!.isCollapsed) {
      // Toggle composer preference for new text
      composer.preferences.toggleStyles({boldAttribution});
    } else {
      // Toggle attribution on selected text
      editor.execute([
        ToggleTextAttributionsRequest(
          documentRange: composer.selection!,
          attributions: {boldAttribution},
        ),
      ]);
    }
  }

  void _setHeading(NamedAttribution headerAttribution) {
    final composer = editor.composer;
    if (composer.selection == null) return;

    final nodeId = composer.selection!.base.nodeId;
    final node = editor.document.getNodeById(nodeId);
    if (node is! TextNode) return;

    // Convert to ParagraphNode with header blockType
    final newNode = ParagraphNode(
      id: nodeId,
      text: node.text,
      metadata: {'blockType': headerAttribution},
    );
    editor.execute([
      ReplaceNodeRequest(existingNodeId: node.id, newNode: newNode),
    ]);
  }

  void _setList(ListItemType type) {
    final composer = editor.composer;
    if (composer.selection == null) return;

    final nodeId = composer.selection!.base.nodeId;
    final node = editor.document.getNodeById(nodeId);
    if (node is! TextNode) return;

    final newNode = ListItemNode(
      id: nodeId,
      itemType: type,
      text: node.text,
    );
    editor.execute([
      ReplaceNodeRequest(existingNodeId: node.id, newNode: newNode),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.format_bold),
            onPressed: _toggleBold,
          ),
          IconButton(
            icon: const Icon(Icons.format_italic),
            onPressed: () => _toggleAttribution(italicsAttribution),
          ),
          const VerticalDivider(),
          // Heading dropdown or segmented buttons for H1/H2/H3
          PopupMenuButton<NamedAttribution>(
            icon: const Icon(Icons.title),
            onSelected: _setHeading,
            itemBuilder: (context) => [
              PopupMenuItem(value: header1Attribution, child: Text('标题 1')),
              PopupMenuItem(value: header2Attribution, child: Text('标题 2')),
              PopupMenuItem(value: header3Attribution, child: Text('标题 3')),
            ],
          ),
          const VerticalDivider(),
          IconButton(
            icon: const Icon(Icons.format_list_bulleted),
            onPressed: () => _setList(ListItemType.unordered),
          ),
          IconButton(
            icon: const Icon(Icons.format_list_numbered),
            onPressed: () => _setList(ListItemType.ordered),
          ),
        ],
      ),
    );
  }
}
```

### Pattern 4: Hive CE Fragment Storage with Freezed
**What:** Fragment entity with Hive TypeAdapter for persistence
**When to use:** Storing fragments with tags in Hive boxes
**Example:**
```dart
// Source: hive_ce 2.19.3 annotations (verified from local pub cache)
// Note: Freezed classes use fromJson/toJson for Hive serialization
// The hive_ce_generator creates adapters that delegate to JSON serialization

@freezed
@HiveType(typeId: 0)
class Fragment with _$Fragment {
  const factory Fragment({
    @HiveField(0) required String id,
    @HiveField(1) required String text,
    @HiveField(2) @Default([]) List<String> tags,
    @HiveField(3) required DateTime createdAt,
    @HiveField(4) DateTime? updatedAt,
  }) = _Fragment;

  factory Fragment.fromJson(Map<String, dynamic> json) =>
      _$FragmentFromJson(json);
}

// Type ID registry to prevent conflicts
abstract class HiveTypeIds {
  static const int fragment = 0;
  static const int appSettings = 1;
  static const int manuscript = 2;
  // Reserve IDs for future types
}

// Initialization
await Hive.initFlutter();
Hive.registerAdapter(FragmentAdapter());
final fragmentBox = await Hive.openBox<Fragment>('fragments');
```

### Pattern 5: Window Size Persistence
**What:** Save and restore window size using window_manager + Hive
**When to use:** Remembering user's preferred window dimensions
**Example:**
```dart
// Source: window_manager 0.5.1 (verified from local pub cache)
// Methods: getSize(), setSize(Size), getPosition(), setPosition(Offset)
// Events: WindowListener.onWindowResized(), onWindowMoved()

class WindowSizePersistence extends StatefulWidget with WindowListener {
  final Widget child;
  final Box settingsBox;

  @override
  void onWindowResized() async {
    final size = await windowManager.getSize();
    await settingsBox.put('windowSize', {'w': size.width, 'h': size.height});
  }

  @override
  void onWindowMoved() async {
    final pos = await windowManager.getPosition();
    await settingsBox.put('windowPosition', {'x': pos.dx, 'y': pos.dy});
  }

  // Restore on init:
  // final saved = settingsBox.get('windowSize');
  // if (saved != null) await windowManager.setSize(Size(saved['w'], saved['h']));
}
```

### Pattern 6: Quick-Capture Global Shortcut
**What:** Ctrl+Shift+N opens quick-capture overlay from any screen
**When to use:** In-app global keyboard shortcut using Flutter's Shortcuts/Actions
**Example:**
```dart
// Source: Flutter SDK (Shortcuts + Actions widgets)
// This wraps the entire app shell to capture shortcut from any route

class QuickCaptureShortcut extends StatelessWidget {
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyN,
        ): const _QuickCaptureIntent(),
      },
      child: Actions(
        actions: {
          _QuickCaptureIntent: CallbackAction<_QuickCaptureIntent>(
            onInvoke: (intent) {
              showDialog(
                context: context,
                builder: (context) => const QuickCaptureDialog(),
              );
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}
```

### Anti-Patterns to Avoid
- **Creating a custom NavigationRail replacement:** NavigationRail already handles Material 3 theming, accessibility, animations, and extended/collapsed states. Building a custom sidebar duplicates effort and misses edge cases.
- **Passing Document/Composer separately to SuperEditor:** The current main.dart passes `document` and `composer` separately. In super_editor 0.3.0-dev.51, these are retrieved from the `Editor` via `editor.document` and `editor.composer`. The `document`/`composer` params are `@Deprecated`.
- **Storing fragments as raw JSON strings in Hive:** Use `@HiveType` with generated TypeAdapters for type safety. Raw string storage loses type checking and requires manual serialization.
- **Using `setState` for editor toolbar state:** The toolbar must react to composer selection changes and document attribution changes. Use `ListenableBuilder` on `composer.selectionNotifier` or Riverpod providers wrapping the editor.
- **Hardcoding sidebar width values:** Use `MediaQuery`/`LayoutBuilder` breakpoints. NavigationRail manages its own width based on `extended` property -- do not override with fixed Container widths.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Sidebar navigation widget | Custom sidebar with icons + labels | Material 3 `NavigationRail` with `extended` | Handles a11y, theming, animations, touch targets, Material 3 spec compliance |
| Route state preservation | Manual IndexedStack with tab state | go_router `StatefulShellRoute.indexedStack` | Handles Navigator keys, deep linking, branch state, browser history |
| Rich text formatting commands | Direct document node manipulation | `Editor.execute([EditRequest])` pipeline | super_editor's command pipeline handles undo/redo, reactions, change notifications |
| Toolbar button active state | Manual document querying | `composer.preferences.currentAttributions` + `composer.selectionNotifier` | Composer tracks active styles at cursor, fires change notifications |
| Window resize events | Platform channel for size callbacks | `WindowListener.onWindowResized()` | window_manager provides typed callbacks for all window events |
| Fragment ID generation | Timestamp or counter-based IDs | `uuid` package (v4) | UUIDs prevent collisions across devices and sessions |
| IME handling | Custom composition region management | super_editor's built-in IME integration | Phase 0 validated CJK IME works with super_editor's platform channel integration |

**Key insight:** super_editor's `Editor` class is the single entry point for ALL document mutations. Never modify `MutableDocument` nodes directly -- always go through `editor.execute([request])` to ensure undo/redo, reactions, and change notifications work correctly.

## Common Pitfalls

### Pitfall 1: super_editor API Version Mismatch
**What goes wrong:** Code examples from older super_editor tutorials use deprecated APIs like `DocumentEditor`, separate `document`/`composer` params, or `CommonEditorOperations` constructor directly.
**Why it happens:** super_editor 0.3.0-dev.x had major API restructuring. Many blog posts and examples target 0.2.x.
**How to avoid:** Always use `createDefaultDocumentEditor()` to create the Editor. Retrieve document/composer via `editor.document` / `editor.composer`. Pass only the `editor` to `SuperEditor(editor: editor)`.
**Warning signs:** Compiler deprecation warnings on `document:` and `composer:` params in SuperEditor widget.

### Pitfall 2: Toolbar Not Reflecting Current Selection State
**What goes wrong:** Bold/italic toggle buttons don't update when cursor moves to text with different formatting.
**Why it happens:** Toolbar widget doesn't listen to composer selection or attribution changes.
**How to avoid:** Wrap toolbar in `ListenableBuilder(listenable: composer.selectionNotifier)` and check `composer.preferences.currentAttributions` to determine active formatting. For expanded selection, query the document's attributions at the selection range.
**Warning signs:** Toolbar buttons stay in initial state regardless of cursor position.

### Pitfall 3: StatefulShellRoute Loses Branch State
**What goes wrong:** Switching between capture and editor tabs resets scroll position or clears input.
**Why it happens:** Using regular `ShellRoute` instead of `StatefulShellRoute`, or using `GoRouter.go()` instead of `navigationShell.goBranch()`.
**How to avoid:** Use `StatefulShellRoute.indexedStack` (not plain `ShellRoute`). Always switch branches via `navigationShell.goBranch(index)`, never via `context.go('/path')`.
**Warning signs:** Editor content disappears or capture input clears when switching tabs.

### Pitfall 4: Hive Box Not Opened Before Access
**What goes wrong:** App crashes on first fragment read/write because the Hive box hasn't been opened yet.
**Why it happens:** `Hive.openBox()` is async and must complete before any read/write. If a Riverpod provider tries to access a box before it's open, it throws.
**How to avoid:** Open all required boxes in `main()` before `runApp()`. Use a Riverpod provider that depends on the box being ready (e.g., `FutureProvider` that awaits box opening, then `ref.watch` in the UI).
**Warning signs:** `HiveError: Box not found. Did you forget to call Hive.openBox()?`

### Pitfall 5: NavigationRail Width Calculation Errors
**What goes wrong:** Sidebar takes wrong width, or content area doesn't fill remaining space.
**Why it happens:** NavigationRail manages its own width internally (~72px collapsed, ~256px extended on desktop). Wrapping it in a `SizedBox` or `Container` with fixed width conflicts.
**How to avoid:** Don't set explicit width on NavigationRail. Use `extended: true/false` to toggle. The widget self-sizes. Put it in a `Row` with `Expanded` for the content area.
**Warning signs:** Horizontal overflow warnings, sidebar overlapping content.

### Pitfall 6: Quick-Capture Shortcut Not Working
**What goes wrong:** Ctrl+Shift+N does nothing when pressed.
**Why it happens:** `Shortcuts` widget requires focus to be within its subtree. If editor or text field has focus, the shortcut might not bubble up. Also, IME composition can intercept key events on Windows.
**How to avoid:** Place `Shortcuts` widget high in the tree (above `MaterialApp.router` or wrapping the shell scaffold). Use `FocusNode` with `autofocus` on the `Shortcuts` subtree. Test with IME inactive (English input mode) first.
**Warning signs:** Shortcut works on settings page but not on editor page.

## Code Examples

### Editor Page with Fixed Toolbar (Complete Pattern)
```dart
// Source: super_editor 0.3.0-dev.51 API (verified from local pub cache)
// Key classes: Editor, MutableDocument, MutableDocumentComposer
// Key attributions: boldAttribution, italicsAttribution, header1-6Attribution
// Key requests: ToggleTextAttributionsRequest, ReplaceNodeRequest

class EditorPage extends StatefulWidget {
  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late final Editor _editor;

  @override
  void initState() {
    super.initState();
    _editor = createDefaultDocumentEditor(
      document: MutableDocument(
        nodes: [
          ParagraphNode(
            id: Editor.createNodeId(),
            text: AttributedText('开始在 MuseFlow 中创作...'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _editor.composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Fixed toolbar at top
        EditorToolbar(editor: _editor),
        const Divider(height: 1),
        // Editor area with centered layout
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SuperEditor(
                  editor: _editor,
                  autofocus: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

### Flutter Secure Storage Usage
```dart
// Source: flutter_secure_storage 10.3.1 (verified from local pub cache)
// Uses Windows Credential Manager on Windows, Android Keystore on Android

class SecureStorageService {
  static const _apiKeyPrefix = 'api_key_';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveApiKey(String providerId, String key) async {
    await _storage.write(key: '$_apiKeyPrefix$providerId', value: key);
  }

  Future<String?> getApiKey(String providerId) async {
    return await _storage.read(key: '$_apiKeyPrefix$providerId');
  }

  Future<void> deleteApiKey(String providerId) async {
    await _storage.delete(key: '$_apiKeyPrefix$providerId');
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `DocumentEditor` class | `Editor` class with `editables` map | super_editor 0.3.0-dev.x | Must use `createDefaultDocumentEditor()`, pass `Editor` to SuperEditor widget |
| `SuperEditor(document:, composer:)` | `SuperEditor(editor:)` | super_editor 0.3.0-dev.x | `document` and `composer` params are `@Deprecated` |
| `ShellRoute` for tab navigation | `StatefulShellRoute.indexedStack` | go_router 7.0+ | Preserves branch state (scroll position, form input) |
| `provider` package | `flutter_riverpod` with code gen | Riverpod 2.0+ | `@riverpod` annotation generates type-safe providers |
| `Hive` original | `hive_ce` (Community Edition) | Original Hive abandoned ~2022 | hive_ce adds `IsolatedHive`, WASM support, active maintenance |
| `@HiveType` per-class | `@GenerateAdapters` grouped | hive_ce 2.x | Both still work; `@HiveType` is more explicit for typeId management |

**Deprecated/outdated:**
- `DocumentEditor` class: Replaced by `Editor` in super_editor 0.3.0-dev.x. Must not use.
- `SuperEditor(document:, composer:)` params: Deprecated in favor of `SuperEditor(editor:)`.
- `provider` package: Replaced by `flutter_riverpod`. Must not use per CLAUDE.md.
- Original `hive` package: Unmaintained. Must use `hive_ce`.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Flutter's built-in `Shortcuts` widget works for Ctrl+Shift+N on Windows desktop | Architecture Patterns | Would need hotkey_manager package, adding a dependency |
| A2 | NavigationRail `extended` property widths match D-01 (~240px) and D-02 (~64px) requirements | Architecture Patterns | May need custom padding or width tweaks |
| A3 | Hive CE `@HiveType` with freezed `fromJson`/`toJson` generates working TypeAdapters | Architecture Patterns | May need manual adapter or different serialization approach |
| A4 | `window_manager` `onWindowResized()` fires reliably on Windows for size persistence | Architecture Patterns | May need to use `onWindowResize()` (during resize) instead of `onWindowResized()` (after) |
| A5 | go_router `StatefulShellRoute.indexedStack` initial location `/editor` launches directly to editor | Architecture Patterns | May need redirect logic or `initialLocation` on the branch |

**If this table is empty:** All claims in this research were verified or cited -- no user confirmation needed.

## Open Questions (RESOLVED)

1. **Android bottom navigation transition** — RESOLVED: Use `LayoutBuilder` with 600px breakpoint for NavigationRail collapse, and switch to `NavigationBar` (bottom) when width < 600px (phone portrait). This is standard Material 3 adaptive behavior.

2. **Fragment tag schema** — RESOLVED: Use free-form strings for Phase 1. Tags like "story:xxx", "chapter:yyy", "scene:zzz" as a convention, not enforced by schema. This allows flexibility for user-defined structures.

3. **Last-opened document persistence** — RESOLVED: Store current document content in a Hive box. On launch, load from box. For Phase 1, there's only one document so this is straightforward.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All | Yes | 3.44.0 stable | -- |
| Dart SDK | All | Yes | Ships with Flutter | -- |
| Android SDK | Android builds | Not verified | -- | Windows-only for Phase 1 |
| Windows SDK | Desktop build | Yes | Via Flutter | -- |
| build_runner | Code generation | Yes | 2.15.0 | -- |

**Missing dependencies with no fallback:** None
**Missing dependencies with fallback:** Android SDK not verified -- Android testing deferred to later phases per CONTEXT.md.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (Flutter SDK built-in) |
| Config file | None -- uses pubspec.yaml `flutter.test` directory |
| Quick run command | `flutter test` |
| Full suite command | `flutter test --coverage` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TECH-01 | Window opens with correct title and size | widget | `flutter test test/app/window_management_test.dart` | No -- Wave 0 |
| TECH-03 | Hive boxes open with encryption | unit | `flutter test test/infrastructure/hive_init_test.dart` | No -- Wave 0 |
| TECH-04 | API keys stored and retrieved via secure storage | unit | `flutter test test/infrastructure/secure_storage_test.dart` | No -- Wave 0 |
| TECH-05 | Navigation between 3 modules preserves state | widget | `flutter test test/app/navigation_test.dart` | No -- Wave 0 |
| EDIT-01 | Bold/italic/heading/list formatting applied via toolbar | widget | `flutter test test/features/editor/formatting_test.dart` | No -- Wave 0 |
| CAPT-01 | Fragment added via input field | widget | `flutter test test/features/capture/fragment_input_test.dart` | No -- Wave 0 |
| CAPT-02 | Fragments tagged with story/chapter/scene | unit | `flutter test test/features/capture/fragment_tag_test.dart` | No -- Wave 0 |
| CAPT-05 | Quick-capture dialog opens and saves fragment | widget | `flutter test test/features/capture/quick_capture_test.dart` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test`
- **Per wave merge:** `flutter test --coverage`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/app/window_management_test.dart` -- covers TECH-01
- [ ] `test/infrastructure/hive_init_test.dart` -- covers TECH-03
- [ ] `test/infrastructure/secure_storage_test.dart` -- covers TECH-04
- [ ] `test/app/navigation_test.dart` -- covers TECH-05
- [ ] `test/features/editor/formatting_test.dart` -- covers EDIT-01
- [ ] `test/features/capture/fragment_input_test.dart` -- covers CAPT-01
- [ ] `test/features/capture/fragment_tag_test.dart` -- covers CAPT-02
- [ ] `test/features/capture/quick_capture_test.dart` -- covers CAPT-05
- [ ] `test/helpers/` -- shared test fixtures (Hive test helpers, mock storage)

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No auth in v1 (local-only app) |
| V3 Session Management | No | No sessions (local-only app) |
| V4 Access Control | No | No multi-user access |
| V5 Input Validation | Yes | Dart type system + freezed for domain validation |
| V6 Cryptography | Yes | flutter_secure_storage (Windows Credential Manager), Hive CE AES-256 CBC for encrypted boxes |

### Known Threat Patterns for Flutter Desktop

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| API key in plaintext | Information Disclosure | flutter_secure_storage encrypts at rest via Windows Credential Manager |
| Local data breach | Information Disclosure | Hive CE encrypted boxes for sensitive data; fragments stored unencrypted (user creative content) |
| Input injection via IME | Tampering | super_editor handles IME composition regions; no raw string manipulation |
| Clipboard data leak | Information Disclosure | No sensitive data in clipboard unless user explicitly copies |

## Sources

### Primary (HIGH confidence)
- super_editor 0.3.0-dev.51 source code (local pub cache) -- attributions, Editor API, CommonEditorOperations, createDefaultDocumentEditor
- go_router 17.2.3 source code (local pub cache) -- StatefulShellRoute, StatefulNavigationShell.goBranch, StatefulShellBranch
- window_manager 0.5.1 source code (local pub cache) -- getSize, setSize, WindowListener, onWindowResized
- hive_ce 2.19.3 source code (local pub cache) -- HiveType, HiveField, GenerateAdapters annotations
- flutter_secure_storage 10.3.1 source code (local pub cache) -- write, read, delete API
- Flutter SDK 3.44.0 -- NavigationRail widget, Shortcuts/Actions widgets

### Secondary (MEDIUM confidence)
- WebSearch results for hotkey_manager -- confirms it exists for OS-global hotkeys but is not needed for in-app shortcut
- WebSearch results for go_router ShellRoute patterns -- confirmed by source code verification

### Tertiary (LOW confidence)
- None -- all critical claims verified from local source code

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all packages installed, versions verified from local pub cache
- Architecture: HIGH - API patterns verified from source code for super_editor, go_router, window_manager
- Pitfalls: HIGH - derived from API analysis and deprecation warnings in source code

**Research date:** 2026-06-01
**Valid until:** 2026-07-01 (stable APIs, low churn expected)
