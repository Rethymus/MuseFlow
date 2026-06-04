# Phase 8: 开篇引导 (Onboarding Guide) - Research

**Researched:** 2026-06-04
**Domain:** Flutter first-run wizard, go_router redirect guard, AI opening generation, super_editor text insertion
**Confidence:** HIGH

## Summary

Phase 8 introduces a first-run onboarding wizard that guides new users through a 4-step creative flow: pick a genre template, create a world setting, create a character, and generate an AI opening paragraph. The wizard reuses Phase 7's `WorldTemplateRepository` for genre selection and `TemplateInstantiationService` for entity creation. The AI opening generator must also be accessible from the editor toolbar outside the wizard, producing 3 distinct opening styles (scene-led, character-led, suspense-led). First-run detection uses go_router's `redirect` callback reading a Hive `appSettings` key.

The project uses **super_editor** (not appflowy_editor as mentioned in some CLAUDE.md boilerplate) for rich text editing. Text insertion uses `InsertTextRequest` and `InsertNodeRequest` via `editor.execute()`. The existing `EditorAINotifier` pattern provides a proven model for AI streaming with diff-based accept/reject, but the opening generator will use a simpler flow since it generates new text rather than modifying existing text.

**Primary recommendation:** Use go_router `redirect` for first-run detection (reading `onboarding_completed` key from the encrypted `settings` Hive box). Build the wizard with Flutter's built-in `PageView` + `PageController`. Reuse Phase 7's `WorldTemplateRepository` and `TemplateInstantiationService` for the first two wizard steps. Create a new `OpeningGeneratorService` that produces 3 styled openings via a single AI call returning structured JSON. Insert the selected opening into the editor using `InsertNodeRequest` with `ParagraphNode`.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ONBD-01 | First-run detection via go_router redirect guard | `GoRouterRedirect` typedef verified: `FutureOr<String?> Function(BuildContext, GoRouterState)`. Use `redirect` callback on GoRouter constructor to check Hive `settings` box for `onboarding_completed` key. |
| ONBD-02 | 4-step wizard flow: pick genre, create world, create character, AI opening; each step skippable | PageView + PageController pattern. Steps map to: (1) TemplateGalleryPage subset, (2) world setting form, (3) character card form, (4) AI opening generator. Skip buttons set step as completed without saving. |
| ONBD-03 | Interrupted wizard can resume, remembering completed steps | Persist wizard progress to Hive `settings` box as `onboarding_progress` key containing `{currentStep: int, completedSteps: List<int>, templateId: String?}`. Resume reads this on wizard re-entry. |
| ONBD-04 | AI opening generator accessible outside wizard (editor toolbar), generates 3 styles (scene-led, character-led, suspense-led) | New `OpeningGeneratorService` using existing `OpenAIAdapter` streaming. Single prompt returns JSON with 3 opening variants. Accessible via a new button in `EditorToolbar`. |
| ONBD-05 | User selects one of 3 generated openings, inserts into editor | Selection UI shows 3 cards. On selection, insert into editor via `InsertNodeRequest` appending `ParagraphNode` at document end, or `InsertTextRequest` at cursor position. |
| ONBD-06 | Onboarding completion flag persisted, no auto-trigger after completion | Write `onboarding_completed: true` to Hive `settings` box when wizard finishes (all steps done or user exits). go_router `redirect` checks this and returns `null` (no redirect). |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| First-run detection | Presentation (router) | Infrastructure (Hive) | go_router redirect is a presentation concern; Hive is the data source |
| Wizard step navigation | Presentation | -- | PageView is purely UI state |
| Genre selection step | Presentation | Infrastructure (WorldTemplateRepository) | Reuses Phase 7's repository; UI renders template cards |
| World/character creation | Application (TemplateInstantiationService) | Infrastructure (repositories) | Business logic for entity creation lives in application layer |
| AI opening generation | Application (OpeningGeneratorService) | Infrastructure (OpenAIAdapter) | Service orchestrates prompt building and AI streaming |
| Opening selection/insertion | Presentation (EditorPage) | Domain (super_editor API) | Editor text insertion is a UI operation |
| Wizard progress persistence | Infrastructure (SettingsRepository) | -- | Simple key-value storage in existing Hive settings box |
| Onboarding completion flag | Infrastructure (SettingsRepository) | Presentation (redirect guard) | Persisted flag read by redirect callback |

## Standard Stack

### Core (all existing, no new packages)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| go_router | ^17.2.3 | Redirect guard for first-run detection | Project constraint. `GoRouterRedirect` typedef verified in source. [VERIFIED: pub.dev registry] |
| hive_ce | ^2.19.3 | Persist onboarding state and completion flag | Project constraint. Existing `settings` box used for all app state. [VERIFIED: pubspec.yaml] |
| flutter_riverpod | ^3.3.1 | State management for wizard and opening generator | Project constraint. [VERIFIED: pubspec.yaml] |
| super_editor | ^0.3.0-dev.20 | Text insertion for generated openings | Project's chosen editor. `InsertTextRequest` and `InsertNodeRequest` verified in codebase. [VERIFIED: pubspec.yaml] |
| openai_dart | ^6.0.0 | AI streaming for opening generation | Project constraint. `OpenAIAdapter` wraps this. [VERIFIED: pubspec.yaml] |
| freezed | ^3.2.5 | Immutable data classes for wizard state and opening results | Project convention for all domain entities. [VERIFIED: pubspec.yaml] |

### Supporting (existing)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| uuid | ^4.5.1 | Generate unique IDs for created entities | When creating WorldSetting and CharacterCard entities |
| flutter_secure_storage | ^10.3.1 | Encrypts Hive settings box keys | Indirectly used via existing `SettingsRepository` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| PageView wizard | introduction_screen package | STATE.md decision: "Onboarding uses built-in PageView (not introduction_screen package)" -- already locked |
| Stepper widget | PageView | Codebase has SkillGenerationWizard using Stepper, but PageView gives swipe gesture, better visual flow, and per-step skip control |
| go_router onEnter | go_router redirect | `onEnter` (new in v17) is more powerful but `redirect` is simpler for a single boolean check. `redirect` runs once per navigation cycle, sufficient for first-run detection. [VERIFIED: go_router 17.2.3 source] |

**Installation:** No new packages required. All dependencies already in pubspec.yaml.

**Version verification:**
```
go_router: 17.2.3 (locked in pubspec.lock)
hive_ce: 2.19.3 (in pubspec.yaml)
super_editor: 0.3.0-dev.20 (in pubspec.yaml)
openai_dart: 6.0.0 (in pubspec.yaml)
```

## Package Legitimacy Audit

No new packages are installed in this phase. All dependencies are pre-existing from v1.0 and v1.1 milestones.

| Package | Registry | Status |
|---------|----------|--------|
| (no new packages) | -- | All existing, no audit needed |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
App Launch
    |
    v
go_router.redirect()
    |-- reads Hive settings['onboarding_completed']
    |-- if null/false --> redirect to /onboarding
    |-- if true --> null (proceed to /editor)
    |
    v
+---------------------------------------+
| OnboardingWizardPage                  |
|  PageView (4 pages)                   |
|  +--------+--------+--------+-------+|
|  | Step 1 | Step 2 | Step 3 | Step 4 ||
|  | Genre  | World  | Char   | AI    ||
|  | Select | Create | Create | Open  ||
|  +--------+--------+--------+-------+|
|     |          |         |        |
|     v          v         v        v
|  TemplateRepo  TemplateInstantiationService
|  (Phase 7)     (Phase 7)     OpeningGeneratorService
|                              (new)
|                                  |
|                                  v
|                           OpenAIAdapter (existing)
|                           --> 3 opening variants (JSON)
|                                  |
+----------------------------------+
    |
    v  (user selects one)
EditorPage.insertOpening(text)
    |
    v
editor.execute([InsertNodeRequest(...)])
    |-- appends ParagraphNode to document


Editor Toolbar (outside wizard):
    |
    v  (user clicks "开篇生成")
OpeningGeneratorBottomSheet
    |-- shows 3 opening cards
    |-- user selects one
    |-- inserts into editor at cursor position
```

### Recommended Project Structure
```
lib/
├── features/
│   └── onboarding/                    # New feature module
│       ├── domain/
│       │   └── opening_variant.dart   # OpeningVariant value object (scene/character/suspense)
│       ├── application/
│       │   ├── opening_generator_service.dart  # AI opening generation with 3 styles
│       │   ├── onboarding_notifier.dart        # Riverpod notifier for wizard state
│       │   └── onboarding_progress.dart        # Progress persistence (Hive read/write)
│       └── presentation/
│           ├── onboarding_wizard_page.dart      # Full-screen wizard with PageView
│           ├── wizard_steps/
│           │   ├── genre_step_page.dart         # Step 1: Genre selection (reuses template cards)
│           │   ├── world_step_page.dart         # Step 2: World setting creation
│           │   ├── character_step_page.dart     # Step 3: Character card creation
│           │   └── opening_step_page.dart       # Step 4: AI opening generation + selection
│           ├── opening_generator_sheet.dart     # Bottom sheet for editor toolbar entry
│           └── opening_variant_card.dart        # Card widget for displaying one opening variant
```

### Pattern 1: go_router redirect guard for first-run detection

**What:** Intercept navigation at app start to redirect to onboarding wizard when `onboarding_completed` flag is not set.
**When to use:** Every app launch until the user completes or skips onboarding.
**Example:**
```dart
// Source: [go_router 17.2.3 source — GoRouterRedirect typedef verified]
// In app.dart _createRouter():

GoRouter(
  initialLocation: AppConstants.editor,
  redirect: (context, state) {
    // Read onboarding completion from Hive settings box
    // This is synchronous because the box is already open by the time
    // the router is created (main() opens it during init)
    final settingsBox = Hive.box('settings');
    final completed = settingsBox.get('onboarding_completed', defaultValue: false) as bool;

    final isOnboardingRoute = state.matchedLocation == '/onboarding';

    if (!completed && !isOnboardingRoute) {
      return '/onboarding';
    }
    if (completed && isOnboardingRoute) {
      return AppConstants.editor;
    }
    return null; // no redirect
  },
  routes: [
    // Add onboarding route OUTSIDE StatefulShellRoute
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingWizardPage(),
    ),
    StatefulShellRoute.indexedStack(
      // ... existing branches
    ),
  ],
);
```

**Critical detail:** The `redirect` callback must guard against infinite loops. Never redirect to the route you're already on. The pattern above checks `isOnboardingRoute` before redirecting. [VERIFIED: go_router 17.2.3 source, redirectLimit defaults to 5]

### Pattern 2: PageView wizard with skip/resume

**What:** Multi-step wizard using PageView for swipeable pages, with skip buttons and progress persistence.
**When to use:** The 4-step onboarding flow.
**Example:**
```dart
// PageView-based wizard
class OnboardingWizardPage extends ConsumerStatefulWidget {
  // ...
}

class _OnboardingWizardPageState extends ConsumerState<OnboardingWizardPage> {
  late final PageController _pageController;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    // Resume from saved progress
    final progress = ref.read(onboardingProgressProvider);
    _currentStep = progress?.currentStep ?? 0;
    _pageController = PageController(initialPage: _currentStep);
  }

  void _nextStep() {
    _completeAndAdvance();
  }

  void _skipStep() {
    _completeAndAdvance(); // mark completed but don't save entities
  }

  void _completeAndAdvance() {
    setState(() => _currentStep++);
    _saveProgress();
    if (_currentStep >= 4) {
      _completeOnboarding();
    } else {
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() {
    // Persist completion flag
    ref.read(onboardingProgressProvider.notifier).markCompleted();
    // Navigate to editor
    context.go(AppConstants.editor);
  }

  void _saveProgress() {
    ref.read(onboardingProgressProvider.notifier).saveProgress(
      currentStep: _currentStep,
      templateId: _selectedTemplateId,
    );
  }
}
```

### Pattern 3: AI opening generation with 3 styles

**What:** Single AI call that generates 3 opening variants in one response, parsed from JSON.
**When to use:** Wizard step 4 and editor toolbar entry.
**Example:**
```dart
// Source: Modeled after TemplateCompletionService pattern
class OpeningGeneratorService {
  const OpeningGeneratorService({
    required this.openAIAdapter,
    required this.apiKey,
    required this.baseUrl,
    required this.model,
  });

  final OpenAIAdapter openAIAdapter;
  final String apiKey;
  final String baseUrl;
  final String model;

  /// Generates 3 opening variants for the given context.
  ///
  /// Returns a list of OpeningVariant, one per style:
  /// scene-led, character-led, suspense-led.
  Future<List<OpeningVariant>> generateOpenings({
    required String genreName,
    required String worldDescription,
    required String characterDescription,
    String? storyConcept,
  }) async {
    final messages = _buildMessages(
      genreName: genreName,
      worldDescription: worldDescription,
      characterDescription: characterDescription,
      storyConcept: storyConcept,
    );

    final stream = openAIAdapter.createStream(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      messages: messages,
    );

    final buffer = StringBuffer();
    await for (final chunk in stream) {
      buffer.write(chunk);
    }

    final decoded = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    return _parseVariants(decoded);
  }

  List<ChatMessage> _buildMessages({...}) {
    return [
      ChatMessage.system(
        '你是 MuseFlow 开篇生成助手。根据给定的世界观、角色和故事概念，生成3种不同风格的开篇段落。'
        '只返回严格 JSON，不要返回 Markdown。\n'
        '返回格式: {"openings": [{"style": "scene", "text": "..."}, {"style": "character", "text": "..."}, {"style": "suspense", "text": "..."}]}\n'
        '每种开篇200-400字，风格鲜明：\n'
        '- scene: 场景切入，以环境描写开场，营造氛围\n'
        '- character: 人物切入，以角色动作或心理开场\n'
        '- suspense: 悬念切入，以疑问或紧张感开场',
      ),
      ChatMessage.user(
        jsonEncode({
          'genre': genreName,
          'world': worldDescription,
          'character': characterDescription,
          if (storyConcept != null) 'concept': storyConcept,
        }),
      ),
    ];
  }
}
```

### Pattern 4: Editor text insertion

**What:** Insert generated opening text into the super_editor document.
**When to use:** After user selects one of the 3 opening variants.
**Example:**
```dart
// Source: Verified from codebase — editor_page.dart and editor_ai_notifier.dart
// Pattern matches existing InsertTextRequest usage in quick_insert_dialog.dart

void insertOpeningText(Editor editor, String text) {
  final selection = editor.composer.selection;
  final document = editor.document;

  if (selection != null && !selection.isCollapsed) {
    // Replace selection
    editor.execute([
      DeleteContentRequest(documentRange: selection),
    ]);
  }

  // Determine insertion position: at cursor if collapsed, or at end of document
  final position = selection?.extent ??
    DocumentPosition(
      nodeId: document.nodes.last.id,
      nodePosition: TextNodePosition(
        offset: (document.nodes.last as TextNode).text.length,
      ),
    );

  // If inserting at the end of the last node, we may need to add a new paragraph
  editor.execute([
    InsertTextRequest(
      documentPosition: position,
      textToInsert: text,
      attributions: {aiProvenanceAttribution},
    ),
  ]);
}

// Alternative: append as new paragraph node at end of document
void appendOpeningAsParagraph(Editor editor, String text) {
  final document = editor.document;
  editor.execute([
    InsertNodeRequest(
      nodeIndex: document.nodes.length,
      newNode: ParagraphNode(
        id: DocumentEditor.createNodeId(),
        text: AttributedText(text),
      ),
    ),
  ]);
}
```

### Anti-Patterns to Avoid

- **Anti-pattern: Adding onboarding route inside StatefulShellRoute.** The wizard is a full-screen flow, not a tab branch. It must be a top-level `GoRoute` sibling to the `StatefulShellRoute`, not nested inside it.
- **Anti-pattern: Using `SharedPreferences` for onboarding state.** Project convention is Hive boxes. The `settings` box already exists and is encrypted. Use it.
- **Anti-pattern: Making 3 separate AI calls for 3 opening styles.** One call with structured JSON output is more efficient and provides a consistent experience. Template the response format in the system prompt.
- **Anti-pattern: Blocking the wizard on AI generation failure.** The AI opening step must be skippable. If generation fails, show an error message but allow the user to continue or retry.
- **Anti-pattern: Modifying `AppSettings` domain entity for onboarding.** Don't add onboarding fields to the `AppSettings` class. Use simple Hive box key-value reads/writes via `SettingsRepository` (which already wraps the settings box), keeping onboarding state orthogonal to window geometry and app preferences.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| First-run detection | Custom Navigator observer or splash screen logic | go_router `redirect` callback | Built-in, declarative, runs before any route builds. Handles deep links correctly. |
| Multi-step wizard flow | Custom page transition manager | Flutter `PageView` + `PageController` | Built-in swipe gestures, page snapping, animation. STATE.md decision. |
| Genre template listing | Custom asset loading and parsing | `WorldTemplateRepository` from Phase 7 | Already loads, caches, filters, and searches 14 bundled templates. |
| Entity creation from templates | Manual WorldSetting/CharacterCard construction | `TemplateInstantiationService` from Phase 7 | Handles draft creation, field mapping, and repository save. |
| AI API calls | Raw HTTP client or custom REST wrapper | `OpenAIAdapter` (wraps `openai_dart`) | Handles streaming, error classification, client caching, HTTPS enforcement. |
| Editor text insertion | Direct document node manipulation | `editor.execute([InsertTextRequest(...)])` | Uses super_editor's request system for proper undo/redo support. |
| Settings persistence | New Hive box or new repository | `SettingsRepository` (existing `settings` box) | Box is already open, encrypted, and wrapped by the repository. |

**Key insight:** This phase is primarily about wiring together existing infrastructure (Phase 7 templates, AI adapter, editor, settings storage) into a new user-facing flow. The only genuinely new code is the `OpeningGeneratorService` and its prompt engineering.

## Common Pitfalls

### Pitfall 1: go_router redirect infinite loop
**What goes wrong:** The `redirect` callback redirects to `/onboarding`, which triggers another redirect to `/onboarding`, until `redirectLimit` (5) is exceeded.
**Why it happens:** Not checking whether the current route is already the target redirect route.
**How to avoid:** Always check `state.matchedLocation == '/onboarding'` before redirecting. Return `null` when already on the target route.
**Warning signs:** `Too many redirects` error in debug console, blank screen on app launch.

### Pitfall 2: Hive box not open when redirect runs
**What goes wrong:** go_router `redirect` fires before Hive boxes are fully initialized, causing a null/error.
**Why it happens:** The `redirect` callback is evaluated during router construction, which happens in `build()` of `MuseFlowApp`. The settings box is opened asynchronously in providers.
**How to avoid:** Either (a) open the settings box synchronously in `main()` before `runApp()` (the box is already opened in `main()` via `_readSavedGeometry`), or (b) use `Hive.box('settings')` which returns an already-open box (boxes are singletons by name in Hive). The existing `main()` already calls `Hive.openBox('settings', ...)` before `runApp()`, so `Hive.box('settings')` will work in the redirect callback. However, the redirect approach needs careful testing since the router is created in `build()`, not in `main()`.
**Warning signs:** `Box not found` exception, first-run detection never triggers.

### Pitfall 3: PageView page disposal loses step state
**What goes wrong:** When swiping back to a previous wizard step, user-entered data is lost because PageView disposed the page widget.
**Why it happens:** Default `PageView` with `autoKeepAlive: false` in `PageController`.
**How to avoid:** Wrap each step page in `AutomaticKeepAliveClientMixin` to preserve state across page swipes. Or use a single `AnimatedSwitcher` pattern with explicit state management in the parent.
**Warning signs:** Form fields empty when swiping back.

### Pitfall 4: AI opening JSON parsing failure
**What goes wrong:** The LLM returns markdown-wrapped JSON, or invalid JSON structure, causing parsing to throw.
**Why it happens:** LLMs are unreliable at following strict output format constraints, especially with creative content.
**How to avoid:** (a) Use the same pattern as `TemplateCompletionService` -- catch parse errors and show a retry option. (b) Strip markdown fences (` ```json ... ``` `) before parsing. (c) Provide a graceful fallback: if JSON parsing fails, try to extract whatever text was generated and display it as a single variant.
**Warning signs:** `FormatException` during opening generation, empty results after streaming completes.

### Pitfall 5: Opening text insertion at wrong position
**What goes wrong:** Generated opening is inserted in the middle of existing content or replaces user text.
**Why it happens:** Using cursor position without checking if the document is empty.
**How to avoid:** For the onboarding wizard (new user, empty editor), always append at the end of the document using `InsertNodeRequest` at `document.nodes.length`. For the editor toolbar entry, use the current cursor position (collapsed selection) or replace selection (expanded selection), matching the `QuickInsertDialog._insert()` pattern.
**Warning signs:** User's existing text is overwritten by the opening paragraph.

### Pitfall 6: Wizard not accessible after completion
**What goes wrong:** Users who completed onboarding cannot re-access the AI opening generator from the wizard flow.
**Why it happens:** The redirect guard always sends completed users to the editor.
**How to avoid:** The wizard route (`/onboarding`) should be accessible via deep link or settings entry even after completion. The redirect guard only auto-redirects on first run. The AI opening generator's editor toolbar entry (ONBD-04) is the primary re-access point -- the wizard itself does not need to be re-accessible.
**Warning signs:** Users report "I can't find the opening generator."

## Code Examples

### First-run detection in go_router redirect

```dart
// Source: Verified against go_router 17.2.3 GoRouterRedirect typedef
// typedef GoRouterRedirect = FutureOr<String?> Function(BuildContext, GoRouterState);

// In app.dart, modify _createRouter():
GoRouter _createRouter() {
  return GoRouter(
    initialLocation: AppConstants.editor,
    redirect: _handleRedirect,  // add this
    routes: [
      // NEW: onboarding route at top level, outside StatefulShellRoute
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingWizardPage(),
      ),
      StatefulShellRoute.indexedStack(
        // ... existing branches unchanged
      ),
    ],
  );
}

FutureOr<String?> _handleRedirect(BuildContext context, GoRouterState state) {
  final isOnboarding = state.matchedLocation == '/onboarding';
  final completed = Hive.box('settings').get('onboarding_completed', defaultValue: false) as bool;

  if (!completed && !isOnboarding) return '/onboarding';
  if (completed && isOnboarding) return AppConstants.editor;
  return null;
}
```

### Onboarding progress persistence

```dart
// Source: Modeled after existing SettingsRepository pattern
// Uses the same encrypted 'settings' Hive box

class OnboardingProgress {
  const OnboardingProgress({
    required this.currentStep,
    this.completedSteps = const [],
    this.selectedTemplateId,
    this.worldName,
    this.characterName,
  });

  final int currentStep;
  final List<int> completedSteps;
  final String? selectedTemplateId;
  final String? worldName;
  final String? characterName;

  factory OnboardingProgress.fromJson(Map<String, dynamic> json) =>
    OnboardingProgress(
      currentStep: json['currentStep'] as int? ?? 0,
      completedSteps: (json['completedSteps'] as List?)?.cast<int>() ?? const [],
      selectedTemplateId: json['selectedTemplateId'] as String?,
      worldName: json['worldName'] as String?,
      characterName: json['characterName'] as String?,
    );

  Map<String, dynamic> toJson() => {
    'currentStep': currentStep,
    'completedSteps': completedSteps,
    if (selectedTemplateId != null) 'selectedTemplateId': selectedTemplateId,
    if (worldName != null) 'worldName': worldName,
    if (characterName != null) 'characterName': characterName,
  };
}
```

### Editor toolbar entry for opening generator

```dart
// Source: Modeled after existing EditorToolbar and FloatingToolbar pattern
// Add a new button to EditorToolbar

// In editor_toolbar.dart, add before the list buttons:
_FormatToggleButton(
  icon: Icons.auto_stories,
  tooltip: '开篇生成',
  isActive: false,
  onPressed: () => _showOpeningGenerator(context),
),

void _showOpeningGenerator(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => const OpeningGeneratorSheet(),
  );
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| go_router `redirect` only | go_router `onEnter` + `redirect` | go_router 17.x | `onEnter` provides richer control (can block navigation, access both current and next state), but `redirect` remains simpler for boolean checks |
| Stepper for multi-step flows | PageView with swipe gestures | STATE.md decision | PageView provides better UX for a creative app -- swipeable, visual progress bar, per-step skip control |
| Per-style AI calls | Single AI call with structured JSON output | This phase's design | Reduces latency from 3 sequential calls to 1, provides consistent comparison |

**Deprecated/outdated:**
- `introduction_screen` package: STATE.md explicitly chose PageView over this. Do not introduce it.
- `GoRoute.redirect` at individual route level: The top-level `redirect` on `GoRouter` constructor is sufficient for this use case. Route-level redirects add unnecessary complexity.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Hive `settings` box is open and available when go_router `redirect` callback runs | Pattern 1, Pitfall 2 | App crashes on first launch. Mitigation: `main()` opens the settings box before `runApp()`, and Hive returns singleton boxes by name. |
| A2 | `Hive.box('settings')` (no await) works in the redirect callback because the box is already opened in `main()` | Pattern 1 | Same as A1. Verified by reading `main()`: `_readSavedGeometry()` calls `Hive.openBox('settings', ...)` before `runApp()`. |
| A3 | `InsertNodeRequest` with `ParagraphNode` works for appending text at the end of a super_editor document | Pattern 4 | Text not inserted or inserted at wrong position. Verified by web search finding: use `document.nodes.length` as `nodeIndex`. [ASSUMED] |
| A4 | AI models can reliably return structured JSON with 3 Chinese opening paragraphs in a single call | Pattern 3 | Fallback to regex extraction or single-variant display needed. Mitigated by existing `TemplateCompletionService` pattern that handles JSON parse failures. |

## Open Questions (RESOLVED)

1. **Onboarding route placement**
   - **RESOLVED**: Plan 08-01 Task 2 implements top-level GoRoute sibling to StatefulShellRoute. No routing conflicts expected as go_router supports multiple top-level routes.
   - What we know: Must be outside `StatefulShellRoute` for full-screen display. go_router requires a route matching `/` in the routes list, which is currently satisfied by the `StatefulShellRoute`.
   - What's unclear: Whether adding a top-level `/onboarding` route alongside `StatefulShellRoute.indexedStack` causes any routing conflicts.
   - Recommendation: Test that `/onboarding` resolves correctly as a sibling route. The existing pattern in the codebase uses nested routes under `StatefulShellBranch`, so this is a new top-level route.

2. **Editor access for opening generator when no provider configured**
   - **RESOLVED**: Plan 08-05 Task 4 shows button always, displays error message on tap if no provider (matches EditorAINotifier pattern).
   - What we know: `EditorAINotifier` shows "未配置 AI 模型" error when no provider is set.
   - What's unclear: Should the opening generator button be hidden when no provider is configured, or shown with an error?
   - Recommendation: Show the button always (consistent with other AI features), display error message on tap if no provider. This matches the existing `EditorAINotifier` pattern.

3. **Opening variant display in onboarding vs editor**
   - What we know: In the wizard, the opening generator is step 4 with full-page display. In the editor, it's a bottom sheet or dialog.
   - **RESOLVED**: Plan 08-04 creates OpeningGeneratorService (shared), Plan 08-05 Task 1 creates OpeningVariantCard (shared), Task 2 creates OpeningStepPage (wizard container), Task 3 creates OpeningGeneratorSheet (bottom sheet container).
   - What's unclear: Whether the same `OpeningGeneratorService` + selection UI is shared between both contexts.
   - Recommendation: Share `OpeningGeneratorService` and `OpeningVariantCard` widget. Use different container widgets (wizard page vs bottom sheet).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Build | Available | 3.44.0 stable | -- |
| Dart SDK | Build | Available | 3.12.0 | -- |
| Hive boxes (settings) | State persistence | Available | 2.19.3 | -- |
| go_router | Navigation | Available | 17.2.3 | -- |
| super_editor | Text editing | Available | 0.3.0-dev.20 | -- |
| OpenAI adapter | AI generation | Available | 6.0.0 | -- |
| flutter test | Testing | Available | bundled | -- |

**Missing dependencies with no fallback:** None
**Missing dependencies with fallback:** None

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (bundled with SDK) |
| Config file | None -- test structure follows convention |
| Quick run command | `flutter test test/features/onboarding/` |
| Full suite command | `flutter test` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ONBD-01 | Redirect to /onboarding when onboarding_completed is false | unit | `flutter test test/features/onboarding/application/onboarding_redirect_test.dart` | Wave 0 |
| ONBD-01 | No redirect when onboarding_completed is true | unit | `flutter test test/features/onboarding/application/onboarding_redirect_test.dart` | Wave 0 |
| ONBD-02 | 4-step wizard flow completes end-to-end | widget | `flutter test test/features/onboarding/presentation/onboarding_wizard_test.dart` | Wave 0 |
| ONBD-02 | Each step is skippable | widget | `flutter test test/features/onboarding/presentation/onboarding_wizard_test.dart` | Wave 0 |
| ONBD-03 | Progress persists on interruption and resumes correctly | unit | `flutter test test/features/onboarding/application/onboarding_progress_test.dart` | Wave 0 |
| ONBD-04 | AI opening generator produces 3 distinct styles | unit | `flutter test test/features/onboarding/application/opening_generator_service_test.dart` | Wave 0 |
| ONBD-04 | Opening generator accessible from editor toolbar | widget | `flutter test test/features/onboarding/presentation/opening_generator_sheet_test.dart` | Wave 0 |
| ONBD-05 | Selected opening inserts into editor | unit | `flutter test test/features/onboarding/application/opening_insertion_test.dart` | Wave 0 |
| ONBD-06 | Completion flag prevents auto-trigger | unit | `flutter test test/features/onboarding/application/onboarding_redirect_test.dart` | Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/features/onboarding/`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/features/onboarding/application/` -- directory and all test files
- [ ] `test/features/onboarding/presentation/` -- directory and all widget test files
- [ ] `test/features/onboarding/domain/` -- directory for OpeningVariant tests
- [ ] Test infrastructure: shared test helpers for mock OpenAIAdapter streaming (pattern exists in `test/features/ai/infrastructure/openai_adapter_test.dart`)

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No user auth in scope |
| V3 Session Management | no | No sessions |
| V4 Access Control | no | Local-only app |
| V5 Input Validation | yes | JSON parse errors in AI opening generation handled gracefully; user input (story concept) length-limited |
| V6 Cryptography | yes | Hive settings box uses AES-256 encryption via existing `SettingsRepository` |

### Known Threat Patterns for Flutter/Dart

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| AI prompt injection via story concept input | Tampering | Input length limit (500 chars), no raw user input in system prompt, structured JSON output parsing with error handling |
| AI response parsing crash (malformed JSON) | Denial of Service | Try-catch around JSON decode, graceful fallback display |

## Sources

### Primary (HIGH confidence)
- go_router 17.2.3 source code (`.pub-cache`) -- `GoRouterRedirect` typedef, `redirect` parameter, `redirectLimit` default 5
- Project codebase -- `app.dart`, `main.dart`, `editor_page.dart`, `editor_ai_notifier.dart`, `providers.dart`, `world_template_repository.dart`, `template_instantiation_service.dart`, `template_completion_service.dart`, `quick_insert_dialog.dart`, `settings_repository.dart`, `pubspec.yaml`
- Phase 7 summaries (07-01, 07-02, 07-03) -- verified existing infrastructure

### Secondary (MEDIUM confidence)
- [go_router pub.dev](https://pub.dev/packages/go_router) -- redirect documentation, features list
- [go_router API docs](https://pub.dev/documentation/go_router/latest/go_router/GoRouter-class.html) -- constructor parameters, `onEnter` vs `redirect` ordering
- [Super Editor guides](https://supereditor.dev/super-editor/guides/) -- document node insertion patterns

### Tertiary (LOW confidence)
- [I Wrote This Blog Post With Super Editor (Medium)](https://andrewzuo.com/i-wrote-this-blog-post-with-super-editor-1762820403e2) -- `insertNodeAt(document.nodes.length, initialNode)` pattern for appending [ASSUMED -- verify during implementation]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all packages already in pubspec.yaml, verified in codebase
- Architecture: HIGH - go_router redirect pattern verified in source, PageView is standard Flutter
- Pitfalls: HIGH - based on direct codebase analysis and verified go_router behavior
- AI prompt engineering: MEDIUM - pattern follows existing `TemplateCompletionService`, but LLM output reliability is inherently uncertain
- Editor text insertion: MEDIUM - `InsertTextRequest` usage verified in codebase, `InsertNodeRequest` for appending at end needs implementation verification

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 (30 days -- stable stack, no new packages)
