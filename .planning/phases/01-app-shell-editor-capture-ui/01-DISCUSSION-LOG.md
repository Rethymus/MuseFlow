# Phase 1: App Shell + Editor + Capture UI - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-01
**Phase:** 1-App Shell + Editor + Capture UI
**Areas discussed:** App Shell & Navigation, Editor Toolbar & Writing UX, Fragment Capture Layout, Quick-Capture Trigger

---

## App Shell & Navigation

### Desktop navigation structure

| Option | Description | Selected |
|--------|-------------|----------|
| Sidebar nav | Left sidebar with icon + label per module. Classic desktop writing app pattern (Notion, Obsidian). Persistent, always visible. Collapses to icons on narrow screens. | ✓ |
| Bottom tab bar | Bottom navigation bar with 3-4 items. Mobile-first pattern. Wastes vertical space on desktop. | |
| Top tab bar | Top tab bar across the app. Unusual for desktop writing tools, takes header space. | |

**User's choice:** Sidebar nav
**Notes:** Desktop writing app pattern is the right fit.

### Home screen

| Option | Description | Selected |
|--------|-------------|----------|
| Editor as home | User goes straight into writing. Sidebar shows modules, main area is editor with last-opened document. | ✓ |
| Dashboard as home | Dashboard shows recent documents, quick stats, entry points. Extra step before writing. | |

**User's choice:** Editor as home
**Notes:** Feels like opening a notebook.

### Navigation items

| Option | Description | Selected |
|--------|-------------|----------|
| 3 items | Capture + Editor + Settings only. Minimal — other modules join in later phases. | ✓ |
| All 5 items | Include Knowledge and Story Structure as disabled/placeholder items. May confuse users. | |
| Claude decides | | |

**User's choice:** 3 items — 捕捉器, 编辑器, 设置

### Sidebar behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Icon + label, collapsible | ~240px with icon + label. Collapses to icon-only rail (~64px) on narrow windows. Material 3 NavigationRail pattern. | ✓ |
| Always expanded | Always shows icon + text, never collapses. Wastes space on small screens. | |
| Claude decides | | |

**User's choice:** Icon + label, collapsible

---

## Editor Toolbar & Writing UX

### Formatting control placement

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed toolbar at top | Toolbar bar above the editor (Word/Google Docs pattern). Always visible, familiar. | ✓ |
| Floating on selection | Toolbar appears only when text selected (Medium pattern). Cleaner surface but hidden controls. | |
| Both | Fixed for formatting + floating on selection for AI actions later. Two UI patterns to maintain. | |

**User's choice:** Fixed toolbar at top

### Formatting controls

| Option | Description | Selected |
|--------|-------------|----------|
| Core 6 | Bold, Italic, Headings (H1/H2/H3), Unordered list, Ordered list. Minimal toolbar. | ✓ |
| Extended | Core 6 + Blockquote, Code block, Horizontal rule. More options but heavier for creative writing. | |
| Claude decides | | |

**User's choice:** Core 6 — B / I / H1-H3 / UL / OL

### Editor layout

| Option | Description | Selected |
|--------|-------------|----------|
| Centered, max-width | Content centered with max-width (~800px). Book-like. Reduces eye strain on wide monitors. | ✓ |
| Full-width | Editor fills full content area. Long lines hard to read on wide screens. | |
| Claude decides | | |

**User's choice:** Centered, max-width (~800px)

---

## Fragment Capture Layout

### Organization model

| Option | Description | Selected |
|--------|-------------|----------|
| Flat bullet list + tags | Each fragment is a bullet point. Organize by assigning story/chapter/scene tags. Matches 子弹笔记 metaphor. | ✓ |
| Tree structure | Nested: Story → Chapter → Scene → Fragments. Powerful but heavier UI, more setup. | |
| Nested accordion | Accordion panels per story/chapter. Visual hierarchy without tree widget. | |

**User's choice:** Flat bullet list + tags
**Notes:** 子弹笔记 (bullet journal) metaphor is key.

### Adding fragments

| Option | Description | Selected |
|--------|-------------|----------|
| Top input field | Text input pinned at top. Type and press Enter. Zero clicks to start. | ✓ |
| FAB + dialog | Floating action button opens dialog. Extra tap but keeps list clean. | |
| Claude decides | | |

**User's choice:** Top input field

### Multi-select for synthesis

| Option | Description | Selected |
|--------|-------------|----------|
| Checkbox multi-select | Checkbox next to each fragment. Check multiple → action bar with "合成" button. | ✓ |
| Long-press selection | Long-press/right-click to enter selection mode. More mobile-native but less discoverable. | |

**User's choice:** Checkbox multi-select
**Notes:** Synthesis action itself is Phase 2, but selection UI built now.

---

## Quick-Capture Trigger

### Trigger mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Global hotkey overlay | Ctrl+Shift+N opens small overlay popup. Type → Enter → saves → closes. Instant. | ✓ |
| Persistent FAB | Small floating button always visible. Takes screen space. | |
| Both FAB + hotkey | FAB as visual cue + hotkey as power-user shortcut. | |

**User's choice:** Global hotkey overlay (Ctrl+Shift+N)

### Capture form content

| Option | Description | Selected |
|--------|-------------|----------|
| Text only, minimal | Just text field + save. Fragment goes to default story/tag. Fastest — two steps: type → save. | ✓ |
| Text + tag assignment | Text field + story/chapter/scene dropdowns. More control but slower. | |
| Claude decides | | |

**User's choice:** Text only, minimal

---

## Claude's Discretion

- Exact sidebar animation timing and collapse breakpoint
- Editor theme colors and font choice (within indigo/dark Material 3 theme)
- Fragment card layout details (timestamp display, tag chip style, swipe gestures)
- Quick-capture overlay position and animation
- Window size persistence implementation approach
- Hive box structure for fragments and settings
- go_router route configuration details
- Android adaptive layout specifics (when sidebar collapses to bottom nav)

## Deferred Ideas

None — discussion stayed within phase scope.
