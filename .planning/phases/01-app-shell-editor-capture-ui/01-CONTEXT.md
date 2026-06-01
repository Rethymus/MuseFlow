# Phase 1: App Shell + Editor + Capture UI - Context

**Gathered:** 2026-06-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can launch the app, navigate between modules via a sidebar, write in a rich text editor with Chinese IME and formatting, and capture/organize inspiration fragments in bullet-note mode. A global hotkey provides quick-capture from any screen.

**In scope:**
- App shell with sidebar navigation between 捕捉器, 编辑器, 设置
- Native Windows desktop app with window management and remembered size
- Rich text editor (super_editor) with fixed formatting toolbar and centered layout
- Fragment capture workspace with bullet-note mode and tag-based organization
- Quick-capture overlay via global hotkey (text-only, minimal)
- Hive CE database initialization with encrypted storage
- Android adaptive layout (sidebar collapses)

**Out of scope:**
- AI synthesis of fragments (Phase 2)
- Floating AI toolbar on text selection (Phase 3)
- Knowledge base and skill system (Phase 4)
- Story structure tools (Phase 5)
- Claude API adapter and model parameters (Phase 6)
- Any "one-click generate" functionality (product philosophy violation)

</domain>

<decisions>
## Implementation Decisions

### App Shell & Navigation
- **D-01:** Sidebar navigation with icon + Chinese label per module (~240px width). Desktop-first, persistent sidebar.
- **D-02:** Sidebar collapses to icon-only rail (~64px) on narrow windows, using Material 3 NavigationRail pattern. Adaptive for Android.
- **D-03:** Editor is the home screen — app launches directly into the editor with last-opened document. No dashboard or overview page.
- **D-04:** 3 navigation items for Phase 1: 捕捉器 (Capture), 编辑器 (Editor), 设置 (Settings). Knowledge base and story structure join later phases.

### Editor Toolbar & Writing UX
- **D-05:** Fixed toolbar at top of editor area (Word/Google Docs pattern). Always visible, not tied to text selection.
- **D-06:** Core 6 formatting controls: Bold, Italic, Headings (H1/H2/H3), Unordered List, Ordered List. No blockquote, code, or horizontal rule.
- **D-07:** Centered editor layout with max-width (~800px) and generous padding. Book-like writing feel. Matches existing main.dart ConstrainedBox pattern.

### Fragment Capture Layout
- **D-08:** Flat bullet list with story/chapter/scene assigned as tags to each fragment. Matches "子弹笔记" (bullet journal) metaphor. Filter by tag to view subsets.
- **D-09:** Top input field always visible — type and press Enter to add a fragment. Zero clicks to start capturing.
- **D-10:** Checkbox multi-select on fragments for batch operations. Synthesis action prepared for Phase 2 but selection UI built now.

### Quick-Capture Trigger
- **D-11:** Global hotkey (Ctrl+Shift+N) opens a small overlay popup from anywhere in the app. Type → Enter → saves and closes.
- **D-12:** Text-only minimal capture form — just a text field + save button. Fragments go to default story/tag (configurable in settings).

### Claude's Discretion
- Exact sidebar animation timing and collapse breakpoint
- Editor theme colors and font choice (within the indigo/dark Material 3 theme from main.dart)
- Fragment card layout details (timestamp display, tag chip style, swipe gestures)
- Quick-capture overlay position and animation
- Window size persistence implementation approach
- Hive box structure for fragments and settings
- go_router route configuration details
- Android adaptive layout specifics (when sidebar collapses to bottom nav)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Definition
- `.planning/PROJECT.md` — Project vision, core value, constraints, key decisions
- `.planning/REQUIREMENTS.md` — Full v1 requirements; Phase 1 covers TECH-01 through TECH-07, EDIT-01, EDIT-04, CAPT-01, CAPT-02, CAPT-05
- `.planning/ROADMAP.md` §Phase 1 — Success criteria (6 items), risks (Hive encryption, window size persistence), plan list (01-01 to 01-04)
- `.planning/STATE.md` — Current project position (Phase 1, ready to plan)

### Architecture & Standards
- `CLAUDE.md` §Technology Stack — Full dependency list, super_editor confirmed as editor, go_router for navigation
- `CLAUDE.md` §Architecture — Four-layer architecture rules, directory structure
- `.claude/rules/02-museflow-architecture.md` — Layer responsibilities, directory structure, key constraints
- `.claude/rules/03-flutter-standards.md` — Immutability, Widget rules, Riverpod patterns, file size limits

### Prior Phase Context
- `.planning/phases/00-technical-validation/00-CONTEXT.md` — Phase 0 decisions (editor selection, architecture, IME validation results)

### Existing Code
- `lib/main.dart` — Current app entry point with window_manager, Hive init, basic super_editor setup. Phase 1 refactors this into proper app shell.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/main.dart`: Window management (window_manager) and Hive initialization — Phase 1 refactors this into proper shell but keeps the init sequence
- `pubspec.yaml`: All dependencies already installed and compatible (verified in Phase 0). go_router, flutter_riverpod, hive_ce, super_editor, window_manager, flutter_secure_storage all present.
- Four-layer directory structure already scaffolded: `lib/features/editor/`, `lib/features/capture/`, `lib/shared/` etc.

### Established Patterns
- Material 3 dark theme with indigo seed color (from main.dart)
- ProviderScope wrapping at root (Riverpod)
- super_editor with MutableDocument, MutableDocumentComposer, createDefaultDocumentEditor
- ConstrainedBox(maxWidth: 800) for centered editor layout

### Integration Points
- `lib/features/editor/presentation/` — Editor page connects here (refactor from main.dart's EditorHomePage)
- `lib/features/capture/presentation/` — Capture page lives here (new)
- `lib/shared/theme/` — Shared theme and constants (new)
- go_router replaces current MaterialApp direct home routing
- Sidebar navigation widget wraps the router outlet

</code_context>

<specifics>
## Specific Ideas

- The "子弹笔记" (bullet journal) metaphor is key to the capture UX — fragments should feel like quick jots, not formal entries
- Editor should feel like opening a notebook — centered, focused, no distractions
- Quick-capture must be instant — the whole point is catching a fleeting idea before it disappears

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 1-App Shell + Editor + Capture UI*
*Context gathered: 2026-06-01*
