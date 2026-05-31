# API Extensibility Evaluation

**Evaluated:** 2026-06-01
**Editors:** super_editor 0.3.0-dev.20 vs appflowy_editor 6.2.0
**Source:** Editor source code from pub cache + RESEARCH.md analysis

---

## Evaluation Criteria (per D-03)

Each capability rated 1-5:
- **5**: Production-ready built-in API, minimal effort
- **4**: Good API exists, moderate integration effort
- **3**: API exists but requires significant adaptation
- **2**: Partial API, substantial custom work needed
- **1**: No API, must build from scratch

---

## 1. Custom Block Components (Story Structure Overlays)

### super_editor (0.3.0-dev.20)

**API Surface:**
- `ComponentBuilder` abstract class (`layout_single_column/_presenter.dart:365`)
- Concrete implementations: `ParagraphComponentBuilder`, `ImageComponentBuilder`, `HorizontalRuleComponentBuilder`, `BlockquoteComponentBuilder`, `ListItemComponentBuilder`, `TaskComponentBuilder`
- Registration via `componentBuilders` parameter on `SuperEditor` widget
- Custom blocks implement `ComponentBuilder` to provide their own widget rendering

**Story structure overlay feasibility:**
A story structure overlay (e.g., a "scene boundary" block, a "character note" inline annotation) would be implemented as a custom `ComponentBuilder`. The API follows a Chain of Responsibility pattern -- each builder gets a chance to handle a document node type. The builder returns a widget that can render arbitrary UI. This is well-suited for story structure overlays.

**Rating: 4/5** -- Clean API, but dev-channel only (no stability guarantee). Must pin exact version. No built-in "overlay on top of text" pattern -- overlays would be separate blocks, not annotations on existing text.

### appflowy_editor (6.2.0)

**API Surface:**
- `BlockComponentBuilder` abstract class (`editor_component/service/renderer/block_component_service.dart:27`)
- Registration via `blockComponentBuilders` parameter on `AppFlowyEditor` widget
- Uses `standardBlockComponentBuilderMap` as default, extendable via map merge: `{...standardBlockComponentBuilderMap, 'my_block': MyBuilder()}`
- Custom blocks have full control over rendering via `BlockComponentBuilder.build()`

**Story structure overlay feasibility:**
The block component system is very clean. Custom blocks are registered by type string. AppFlowy itself uses this for tables, grids, dividers, etc. A story structure block would be a custom type with its own renderer. The system also supports `BlockComponentRenderer`, which gives control over the widget subtree. Additionally, `Node.attributes` can store custom metadata (provenance, markers, scene IDs).

**Rating: 5/5** -- Production-ready API, well-documented patterns from AppFlowy's own usage, stable release. Block attribute system naturally supports metadata.

---

## 2. Floating Toolbar API (AI Action Menu)

### super_editor (0.3.0-dev.20)

**API Surface:**
- No built-in floating toolbar widget
- Uses `overlord` package (dependency) for overlay positioning (`Follower` widget)
- Would need to build a custom floating toolbar using `OverlayPortal` + `Follower`
- `documentOverlayBuilders` parameter on `SuperEditor` accepts overlay layers
- Selection changes can be observed to trigger toolbar show/hide

**Implementation effort:**
Building a floating toolbar requires:
1. Listening to selection changes
2. Computing selection rectangle position
3. Showing/hiding an overlay positioned near the selection
4. Handling toolbar item tap actions that modify the document

Estimated effort: 2-3 days for a functional toolbar. The `overlord` package handles positioning, but all toolbar UI and logic must be custom.

**Rating: 2/5** -- No built-in floating toolbar. Must build from scratch. `overlord` helps with positioning but significant custom work needed.

### appflowy_editor (6.2.0)

**API Surface:**
- **Built-in `FloatingToolbar` widget** (`toolbar/desktop/floating_toolbar.dart:32`)
- Constructor: `FloatingToolbar(items: [...], editorState: ..., editorScrollController: ..., child: ...)`
- Configurable via `ToolbarItem` list -- pick from standard items or create custom ones
- Standard items available: `paragraphItem`, `headingItem`, `quoteItem`, `bulletedListItem`, `numberListItem`, `linkItem`, `colorItem`, `highlightItem`
- Custom items: create `ToolbarItem` with custom callback for AI actions
- Style customization via `FloatingToolbarStyle` (height, padding, decoration)

**Implementation effort:**
Adding AI action items to the floating toolbar:
1. Import `FloatingToolbar` and wrap editor
2. Add custom `ToolbarItem`s for AI actions (e.g., "AI Polish", "AI Expand", "AI Compress")
3. Each item gets an `onTap` callback that triggers the AI pipeline

Estimated effort: 0.5-1 day. The toolbar infrastructure is complete; only the AI-specific items need to be defined.

**Rating: 5/5** -- Production-ready floating toolbar with configurable items. Adding AI actions is trivial.

---

## 3. Document Model Queryability (Provenance Tracking)

### super_editor (0.3.0-dev.20)

**API Surface:**
- `MutableDocument` implements `Iterable<DocumentNode>`
- `getNodeById(String nodeId)` -- direct node lookup
- `getNodeAt(int index)` -- index-based access
- `DocumentNode` has `id`, and specific subclasses like `ParagraphNode` have `text` (AttributedText)
- `AttributedText` supports attribute spans at arbitrary ranges
- No built-in custom metadata on nodes beyond text attributions

**Provenance tracking feasibility:**
Provenance tracking (which AI generated which text, when) would require:
1. Using `AttributedText` spans to mark AI-generated regions with a custom attribution
2. OR wrapping nodes in a custom subclass that carries metadata
3. Querying requires iterating nodes and checking attribution ranges

The `AttributedText` system can store custom attributions (e.g., `ai-generated` attribution with a value of the model name). This is functional but not designed for rich metadata. Node-level metadata (scene ID, character reference) is not natively supported.

**Rating: 3/5** -- Attributions support basic provenance but lack structured metadata. Custom node subclasses possible but not idiomatic. Query API is functional but limited.

### appflowy_editor (6.2.0)

**API Surface:**
- `Document` with `Node` tree structure
- `Node.attributes` is `Map<String, dynamic>` -- arbitrary key-value metadata
- `Node.type` is a string, queryable
- `Node.children` for nested structures
- `Delta` on text nodes supports operations with attributes
- `Path` system for precise node location
- `EditorState.transaction` for batch document operations
- `Document.isEmpty`, `Document.root`, node iteration via `Node.children`

**Provenance tracking feasibility:**
Provenance is naturally supported:
1. Text-level: `Delta` operations can carry attributes (e.g., `{ 'ai-generated': true, 'model': 'deepseek-v3' }`)
2. Node-level: `Node.attributes['provenance']` can store structured metadata
3. Query: iterate children of root, filter by `node.attributes['provenance']`
4. The block-based model makes it easy to query "which paragraphs have AI content"

The JSON-compatible attribute system means provenance data is serializable and queryable without custom code.

**Rating: 5/5** -- Rich attribute system with JSON-compatible metadata. Delta-level and node-level provenance both supported. Block-based model is inherently queryable.

---

## Summary Scores

| Capability | super_editor | appflowy_editor |
|-----------|:-----------:|:---------------:|
| Custom Block Components | 4 | **5** |
| Floating Toolbar API | 2 | **5** |
| Document Model Queryability | 3 | **5** |
| **Average** | **3.0** | **5.0** |

**Verdict:** appflowy_editor dominates in API extensibility across all three capabilities. The built-in `FloatingToolbar` alone saves significant development time. The JSON-compatible attribute system makes provenance tracking straightforward.
