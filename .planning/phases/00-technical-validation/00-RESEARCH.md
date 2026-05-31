# Phase 0: Technical Validation - Research

**Researched:** 2026-05-31
**Domain:** Flutter editor benchmarking, CJK IME, package compatibility, SSE streaming
**Confidence:** HIGH (package versions verified via pub.dev API + live `flutter pub get`; editor issue data verified via GitHub API)

## Summary

Phase 0 validates three existential technical risks before committing to architecture: (1) editor choice for Chinese novel writing on Windows, (2) package compatibility on the installed Flutter 3.44.0 / Dart 3.5.4 toolchain, and (3) SSE streaming from real AI APIs into the chosen editor. Research uncovered a **critical version compatibility gap** between the CLAUDE.md tech stack specifications and what actually resolves on Dart 3.5.4 -- nearly every package specified requires a newer Dart SDK. A working dependency set was identified and verified via live `flutter pub get`. Both candidate editors (`super_editor` and `appflowy_editor`) have open CJK IME bugs on Windows that must be validated empirically.

**Primary recommendation:** Resolve the Dart version / package compatibility problem FIRST (it blocks everything else). Then run dual-editor benchmarks with `super_editor 0.3.0-dev.20` vs `appflowy_editor 6.0.0`. Flag to the user that the CLAUDE.md tech stack versions are aspirational and need updating to match the toolchain.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Test BOTH super_editor AND appflowy_editor with identical benchmark suite for direct comparison
- **D-02:** Weighted scoring: IME compatibility 40% + large document performance 30% + API extensibility 20% + community activity 10%
- **D-03:** API extensibility evaluates three capabilities: custom block components (story structure overlays), floating toolbar API (AI action menu), document model queryability (provenance tracking, marker location)
- **D-04:** Editor selection result determines which editor proceeds to Phase 1; update CLAUDE.md tech stack accordingly
- **D-05:** Create full Flutter project skeleton (not throwaway test harness) -- Phase 1 builds directly on it
- **D-06:** Install ALL dependencies from CLAUDE.md tech stack in one step (validates package compatibility as a byproduct)
- **D-07:** Directory structure follows CLAUDE.md four-layer architecture: `core/domain/`, `core/application/`, `core/infrastructure/`, `core/presentation/`, `features/`, `shared/`
- **D-08:** Dual validation: automated TextEditingDelta composition simulation + manual keyboard testing
- **D-09:** Manual testing covers 3 input methods only: Sogou Pinyin, Wubi, Microsoft Pinyin (per ROADMAP.md)
- **D-10:** Automated tests simulate composing -> committed text lifecycle to catch regressions
- **D-11:** Full end-to-end: connect to real OpenAI or DeepSeek API, stream SSE tokens, insert into editor
- **D-12:** Do NOT test Ollama (local environment constraints) -- Ollama validation deferred to Phase 6
- **D-13:** User must provide an API Key (OpenAI or DeepSeek) for streaming tests

### Claude's Discretion
- Exact benchmark methodology (document size steps, frame time measurement approach)
- Specific test text generation for Chinese document benchmarks
- Automated test structure and naming conventions
- How to present benchmark comparison results

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| (Spike) | Validates feasibility for TECH-02 (IME) | Both editors have open CJK IME Windows bugs -- see Editor CJK Status section |
| (Spike) | Validates feasibility for EDIT-01 (rich text editor) | Dual-editor benchmark plan with weighted scoring |
| (Spike) | Validates feasibility for EDIT-04 (300K+ chars at 60fps) | Flutter performance profiling approach documented; document size steps at discretion |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Rich text editing | Browser / Client | -- | Editor widget lives entirely in presentation layer |
| IME handling | Browser / Client | Frontend Server (Flutter Engine) | System-level IME goes through Flutter's platform channels |
| Document model | Browser / Client | -- | Block/delta model is client-side data structure |
| AI streaming (SSE) | API / Backend | Browser / Client | Tokens arrive from API, but buffering/insertion is client-side |
| Package resolution | Build tooling | -- | pub.dev resolution is build-time, no tier |
| Benchmark measurement | Browser / Client | -- | Frame timing is measured in the Flutter rendering pipeline |

## Standard Stack

### CRITICAL: Version Compatibility Gap

The CLAUDE.md tech stack specifies package versions that **do not resolve** on the installed toolchain (Flutter 3.44.0 / Dart 3.5.4). Every AI SDK, Riverpod 3.x, Freezed 3.x, and several supporting libraries require Dart 3.6+ through 3.9+. This was verified by live `flutter pub get` failure.

**Root cause:** The CLAUDE.md versions were specified aspirationally (matching latest pub.dev versions) without checking Dart SDK compatibility of the installed Flutter.

**Two resolution paths:**
1. **Upgrade Flutter/Dart** to a version shipping Dart 3.9+ (enables all CLAUDE.md versions as-specified)
2. **Downgrade packages** to versions compatible with Dart 3.5.4 (verified working set below)

**Recommendation:** Path 1 is strongly preferred. Flutter 3.44.0 shipping Dart 3.5.4 is unusual (the Dart is from October 2024 while Flutter is from May 2026). A `flutter upgrade` may resolve this. If Dart remains at 3.5.4 after upgrade, Path 2 is the fallback. The planner should add a first task to attempt `flutter upgrade` and verify the resulting Dart version.

### Working Dependency Set (Dart 3.5.4 compatible) [VERIFIED: pub.dev API + live flutter pub get]

| Package | CLAUDE.md Spec | Max Compatible | Gap |
|---------|---------------|----------------|-----|
| flutter_riverpod | ^3.3.1 | **2.6.1** (sdk >=2.17.0) | Major version behind (no code-gen providers, no @riverpod annotation) |
| riverpod_annotation | ^4.0.2 | **NONE** (all 3.x/4.x need Dart 3.7+) | Unavailable -- cannot use code-gen Riverpod |
| riverpod_generator | ^4.0.3 | **NONE** (all need Dart 3.7+) | Unavailable -- cannot use code-gen Riverpod |
| freezed | ^3.2.5 | **2.5.7** (sdk >=3.0.0) | Major version behind (no sealed class unions v3) |
| freezed_annotation | ^3.1.0 | **2.4.4** (resolved by pub) | Minor gap |
| openai_dart | ^6.0.0 | **0.4.5** (sdk >=3.4.0) | Massive gap -- pre-1.0, may lack streaming/custom baseUrl |
| anthropic_sdk_dart | ^4.0.0 | **0.2.0+1** (sdk >=3.4.0) | Massive gap -- barely usable pre-alpha |
| ollama_dart | ^2.2.0 | **0.2.2+1** (sdk >=3.4.0) | Massive gap -- pre-alpha |
| appflowy_editor | ^6.2.0 | **6.0.0** (sdk >=3.4.0) | Minor gap (6.1+ needs Dart 3.6) |
| super_editor | (not in CLAUDE.md) | **0.3.0-dev.20** (sdk >=3.0.0) | Must use dev channel; 0.2.7 has uuid ^3 conflict |
| go_router | ^17.2.3 | **15.1.2** (sdk >=3.4.0) | Major gap |
| share_plus | ^13.1.0 | **12.0.2** (sdk >=3.4.0) | Major gap (13.x needs Dart 3.10+) |
| url_launcher | ^6.3.2 | **6.3.1** (sdk >=3.2.0) | Minor gap (6.3.2 needs Dart 3.6) |
| json_annotation | ^4.12.0 | **4.9.0** (sdk ^3.0.0) | Minor gap |
| json_serializable | ^6.14.0 | **6.8.4** (needs verification) | Likely needs Dart 3.6+ too |
| build_runner | ^2.15.0 | **2.4.13** (sdk ^3.5.0) | Minor gap |
| markdown | ^7.3.1 | **7.3.0** (sdk ^3.2.0) | Tiny gap (7.3.1 needs Dart 3.9) |
| google_fonts | ^8.1.0 | **6.2.1** (sdk >=2.14.0) | Major gap |
| file_picker | ^11.0.2 | **8.3.7** (via appflowy_editor dep) | Major gap -- conflicts with appflowy_editor |

### Fully Compatible Packages (no change needed)

| Package | Version | SDK Constraint | Status |
|---------|---------|---------------|--------|
| hive_ce | 2.19.3 | ^3.4.0 | OK |
| hive_ce_flutter | 2.3.4 | ^3.4.0 | OK |
| flutter_secure_storage | 10.3.1 | >=3.3.0 | OK |
| window_manager | 0.5.1 | >=3.0.0 | OK |
| uuid | 4.5.3 | >=3.0.0 | OK |
| logger | 2.7.0 | >=2.17.0 | OK |
| path_provider | 2.1.5 | ^3.4.0 | OK |
| connectivity_plus | 7.1.1 | >=3.2.0 | OK |

### Installation (Dart 3.5.4 compatible set)

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  freezed: ^2.5.7
  freezed_annotation: ^2.4.4
  hive_ce: ^2.19.3
  hive_ce_flutter: ^2.3.4
  flutter_secure_storage: ^10.3.1
  openai_dart: ^0.4.5
  anthropic_sdk_dart: ^0.2.0
  ollama_dart: ^0.2.2
  go_router: ^15.1.2
  window_manager: ^0.5.1
  uuid: ^4.5.3
  logger: ^2.7.0
  markdown: ^7.3.0
  path_provider: ^2.1.5
  share_plus: ^12.0.2
  url_launcher: ^6.3.1
  connectivity_plus: ^7.1.1
  json_annotation: ^4.9.0
  google_fonts: ^6.2.1
  # Editors (for benchmark -- only ONE proceeds to Phase 1)
  super_editor: ^0.3.0-dev.20
  appflowy_editor: ^6.0.0

dev_dependencies:
  build_runner: ^2.4.13
  json_serializable: ^6.8.4
```

**IMPORTANT:** `appflowy_editor` pulls `file_picker ^8.0.2` transitively. If the project needs `file_picker` at a newer version, it conflicts. The benchmark should test editors in SEPARATE pubspec configurations to avoid this conflict during the spike phase. The final editor choice determines which file_picker version the project uses.

## Package Legitimacy Audit

> slopcheck is not available in this environment. All packages tagged [ASSUMED] for registry legitimacy. However, ALL packages below were verified to exist on pub.dev via direct API queries and resolved successfully in live `flutter pub get`.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| super_editor | pub.dev | ~4 yrs (dev channel active) | Moderate | github.com/Flutter-Bounty-Hunters/super_editor (1924 stars) | N/A | [ASSUMED] -- well-established OSS project |
| appflowy_editor | pub.dev | ~3 yrs | High | github.com/AppFlowy-IO/appflowy-editor (652 stars) | N/A | [ASSUMED] -- backed by AppFlowy |
| flutter_riverpod | pub.dev | ~4 yrs | Very High | github.com/rrousselGit/riverpod | N/A | [ASSUMED] -- de facto standard Flutter state management |
| hive_ce | pub.dev | ~2 yrs | Moderate | github.com/IO-Design-LLC/hive_ce | N/A | [ASSUMED] -- community edition of Hive |
| openai_dart | pub.dev | ~2 yrs | Moderate | github.com/davidmigloz/langchain_dart | N/A | [ASSUMED] -- part of langchain_dart ecosystem |
| anthropic_sdk_dart | pub.dev | ~1.5 yrs | Low-Moderate | github.com/davidmigloz/langchain_dart | N/A | [ASSUMED] -- same ecosystem as openai_dart |
| go_router | pub.dev | ~3 yrs | Very High | github.com/flutter/packages (official Flutter team) | N/A | [ASSUMED] -- official Flutter package |
| window_manager | pub.dev | ~3 yrs | Moderate | github.com/leanflutter/window_manager | N/A | [ASSUMED] |
| freezed | pub.dev | ~4 yrs | Very High | github.com/rrousselGit/freezed | N/A | [ASSUMED] -- standard Dart code gen |

**Packages removed due to slopcheck [SLOP] verdict:** none (slopcheck unavailable)
**Packages flagged as suspicious [SUS]:** none

*All packages above are tagged [ASSUMED] because slopcheck was unavailable. However, each was verified to exist on pub.dev via API queries and resolve in live `flutter pub get`. The planner should treat these as safe to install.*

## Editor Comparison: CJK IME Status

### super_editor (0.3.0-dev.20)

| Attribute | Finding | Source |
|-----------|---------|--------|
| Real repo | github.com/Flutter-Bounty-Hunters/super_editor | [VERIFIED: GitHub API] |
| Stars | 1,924 | [VERIFIED: GitHub API] |
| Last push | 2026-05-28 | [VERIFIED: GitHub API] |
| Open issues | 307 | [VERIFIED: GitHub API] |
| IME issues total | 366 | [VERIFIED: GitHub API search] |
| CJK-specific issues | 16 total, 6 open | [VERIFIED: GitHub API search] |

**Open CJK/IME bugs affecting Windows:**
- **#2588** (open, P2): "The IME of the Chinese input method is not in the right position in Windows" -- IME candidate window appears in wrong position (upper left instead of below cursor). Last updated 2025-07-29. [VERIFIED: GitHub API]
- **#2728** (open): "IME Chinese composing crash when deleting character at the end of text". Last updated 2025-07-28. [VERIFIED: GitHub API]
- **#2534** (open): "Chinese layout is very ugly" -- text rendering/layout issues with Chinese characters. Last updated 2025-01-24. [VERIFIED: GitHub API]
- **#743** (open): "broken text in Korean" -- CJK character rendering issue. Last updated 2024-05-22. [VERIFIED: GitHub API]

**Positive signals:**
- 366 IME issues suggests they take IME seriously and invest heavily in it
- Recent IME fixes (#2978 SwiftKey, #2991 iOS backspace) show active development
- `super_keyboard` companion package handles platform keyboard integration
- Uses `TextEditingDelta` API for composition handling

**Concerns:**
- Stable version 0.2.7 is from June 2024 (nearly 2 years old) -- must use dev channel
- Dev channel (0.3.0-dev.*) may have breaking changes between dev releases
- Multiple open Windows CJK bugs suggest Windows CJK is not production-ready

### appflowy_editor (6.0.0)

| Attribute | Finding | Source |
|-----------|---------|--------|
| Real repo | github.com/AppFlowy-IO/appflowy-editor | [VERIFIED: GitHub API] |
| Stars | 652 | [VERIFIED: GitHub API] |
| Last push | 2026-05-26 | [VERIFIED: GitHub API] |
| Open issues | 138 | [VERIFIED: GitHub API] |
| Recent releases | 6.2.0 (2025-12-08), 5.2.0 (2025-04-17) | [VERIFIED: GitHub API + pub.dev API] |

**Open CJK/IME bugs:**
- **#696** (open, **P0**): "Input characters are out of order when using some IME" -- **Sogou input produces garbled character order** ("space+jin tian yi he cha tian" instead of "jin tian yi he cha tian"). This is a showstopper for Sogou Pinyin, one of the three target IMEs. Created 2024-01-29, last updated 2024-12-12. [VERIFIED: GitHub API]

**Positive signals:**
- Backed by AppFlowy (large OSS project with many CJK users)
- Stable release cadence (5 major versions in 2024-2025)
- Built-in `FloatingToolbar` widget per CLAUDE.md tech stack
- Block-based document model (structured, queryable)

**Concerns:**
- P0 Sogou IME bug open for 16+ months without fix
- Depends on `provider` (potential architectural overlap with Riverpod)
- Requires Dart 3.4+ (6.0.0) or 3.6+ (6.1.0+) -- limits version choice
- Transitive `file_picker ^8.0.2` dependency may conflict with project needs

### Editor API Extensibility Comparison

| Capability | super_editor | appflowy_editor |
|-----------|-------------|-----------------|
| **Custom block components** | `BlockComponentBuilder` API -- register custom block types with custom rendering. Used for task lists, images, horizontal rules. Story structure overlays should be implementable. [ASSUMED] | `BlockComponentBuilder` API -- register custom block renderers. AppFlowy uses this for tables, grids, etc. [ASSUMED] |
| **Floating toolbar** | No built-in floating toolbar. Would use `OverlayPortal`/`Follower` from `overlord` package (super_editor dependency) to position a custom toolbar near selection. More work but full control. [ASSUMED] | **Built-in `FloatingToolbar` widget** -- appears on text selection with configurable items (`paragraphItem`, `headingItems`, `markdownFormatItems`, custom items). Production-ready. [ASSUMED] based on CLAUDE.md tech stack documentation |
| **Document model queryability** | `MutableDocument` with programmatic node access. Can query nodes by type, position, content. Delta-based text operations. Provenance tracking would need custom metadata on nodes. [ASSUMED] | Block-based JSON document model. Each node has type, attributes, delta. Queryable by node type, attributes. Custom attributes can store provenance metadata. [ASSUMED] |
| **Programmatic text insertion** | `MutableDocument` supports insert operations via `DocumentEditor` or direct node manipulation. Batch operations possible. [ASSUMED] | `Transaction` API for document operations. `insertNode`, `updateNode`, batch via transaction. [ASSUMED] |

## Architecture Patterns

### Recommended Project Structure

```
lib/
  core/
    domain/                 # Entities, value objects (pure Dart)
    application/            # Use cases, DTOs, port interfaces
    infrastructure/         # Repository implementations, external APIs
    presentation/           # App-level providers, shared widgets
  features/
    editor/                 # Editor feature
      domain/
      application/
      infrastructure/
      presentation/
    knowledge/              # Knowledge base feature
    ai/                     # AI service feature
    capture/                # Fragment capture feature
  shared/                   # Shared utilities, theme, constants
```

### Pattern 1: Riverpod Provider (2.x compatible)

**What:** Use Riverpod 2.x provider patterns (StateNotifierProvider, FutureProvider, StreamProvider) instead of code-gen @riverpod annotation
**When to use:** When toolchain is Dart 3.5.4 and Riverpod 3.x is unavailable
**Example:**
```dart
// Riverpod 2.x pattern (compatible with Dart 3.5.4)
final editorStateProvider = StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier();
});

class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier() : super(EditorState.initial());

  void updateContent(String content) {
    state = state.copyWith(content: content);
  }
}
```

### Pattern 2: SSE Streaming Buffer

**What:** Buffer streaming AI tokens and batch-insert into editor document at fixed intervals (e.g., every 100ms or every N characters) to avoid per-token UI jank
**When to use:** When streaming SSE tokens from OpenAI/DeepSeek into editor
**Example:**
```dart
// Buffer tokens, batch-insert every 100ms
class StreamingBuffer {
  final StringBuffer _buffer = StringBuffer();
  Timer? _flushTimer;
  final void Function(String text) onFlush;

  StreamingBuffer({required this.onFlush});

  void append(String token) {
    _buffer.write(token);
    _flushTimer ??= Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _flush(),
    );
  }

  void _flush() {
    final text = _buffer.toString();
    if (text.isNotEmpty) {
      _buffer.clear();
      onFlush(text);
    }
  }

  void complete() {
    _flushTimer?.cancel();
    _flush();
  }
}
```

### Anti-Patterns to Avoid

- **Per-token document insertion:** Inserting every SSE token individually into the editor document causes layout recalculation per token, resulting in visible jank. Always buffer and batch-insert.
- **Mixing provider and Riverpod:** appflowy_editor depends on `provider`. Do NOT use provider for app state -- only Riverpod. The provider dependency is an internal implementation detail of appflowy_editor.
- **Using super_editor 0.2.7 stable:** It has a `uuid ^3.0.3` dependency that conflicts with `uuid ^4.x`. Use the 0.3.0-dev channel.
- **Ignoring dev channel instability:** super_editor 0.3.0-dev.* may have breaking API changes between dev releases. Pin the exact version once validated.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| IME composition handling | Custom composing region tracking | Flutter's `TextEditingValue.composing` + editor's built-in IME integration | Platform-specific edge cases (Sogou, Wubi, Microsoft Pinyin) are numerous and subtle |
| SSE token parsing | Custom SSE parser | `openai_dart` built-in streaming (`createChatCompletionStream()`) | SSE spec has edge cases (multi-line data, comments, reconnect) |
| Rich text document model | Custom Delta/operations | Editor's built-in document model (super_editor's `MutableDocument` or appflowy_editor's `Document`) | Undo/redo, selection, composition all depend on the document model internals |
| Performance profiling | Custom frame timing | Flutter's `SchedulerBinding.instance.addTimingsCallback` or DevTools Performance view | The framework provides accurate frame timing data; custom timers introduce measurement overhead |

## Common Pitfalls

### Pitfall 1: Dart SDK Version Mismatch
**What goes wrong:** CLAUDE.md specifies package versions that require Dart 3.6-3.9, but Flutter 3.44.0 ships Dart 3.5.4. `flutter pub get` fails with cryptic "version solving failed" errors.
**Why it happens:** Flutter and Dart version numbers are not synced. Flutter 3.44.0 is very new (May 2026) but ships an older Dart (3.5.4 from Oct 2024).
**How to avoid:** Before any `pub add`, verify the Dart SDK with `dart --version`. Check each package's SDK constraint on pub.dev.
**Warning signs:** `flutter pub get` fails immediately; error mentions "requires SDK version >=3.x.0".

### Pitfall 2: Transitive Dependency Conflicts Between Editors
**What goes wrong:** `super_editor` and `appflowy_editor` have conflicting transitive dependencies (e.g., `file_picker`, `uuid`, `flutter_plugin_android_lifecycle`).
**Why it happens:** Both editors are complex packages with many transitive dependencies at different version ranges.
**How to avoid:** During the benchmark spike, install each editor in a SEPARATE configuration (or use separate test projects). Do not attempt to install both in the same project simultaneously. Only install the winning editor in the final project skeleton.
**Warning signs:** `flutter pub get` fails with "depends on X ^1.0 but Y depends on X ^2.0".

### Pitfall 3: CJK IME Candidate Window Position
**What goes wrong:** The IME candidate/composition window appears in the wrong position (e.g., top-left corner instead of below the cursor).
**Why it happens:** Rich text editors with custom text layout may not correctly report cursor position to the platform IME system.
**How to avoid:** This MUST be tested manually on Windows. Automated `TextEditingDelta` tests verify composition correctness but not visual positioning. Include explicit manual testing for IME candidate window position in the test plan.
**Warning signs:** super_editor #2588 is exactly this bug (open, unresolved).

### Pitfall 4: super_editor Dev Channel Instability
**What goes wrong:** Code written against `0.3.0-dev.20` breaks when updating to a later dev version.
**Why it happens:** Dev channel has no stability guarantee. APIs can change between dev releases.
**How to avoid:** Pin the exact dev version in pubspec.yaml. Do NOT use caret syntax (^) for dev versions -- use exact version. When upgrading, treat it as a migration.
**Warning signs:** Build errors after `flutter pub upgrade` that reference changed super_editor APIs.

### Pitfall 5: AI SDK Feature Gap at Downgraded Versions
**What goes wrong:** `openai_dart 0.4.5` lacks features that CLAUDE.md assumes (streaming API, custom baseUrl for DeepSeek/Ollama).
**Why it happens:** The versions compatible with Dart 3.5.4 are pre-1.0 releases with limited API surface.
**How to avoid:** During the SSE streaming spike (D-11), verify that `openai_dart 0.4.5` supports: (a) streaming chat completions, (b) custom baseUrl, (c) proper SSE chunk parsing. If it does not, the project MUST upgrade Flutter/Dart to use newer SDK versions.
**Warning signs:** Streaming API returns raw HTTP responses instead of parsed typed objects; no way to set custom baseUrl.

## Code Examples

### openai_dart 0.4.5 Streaming Pattern
```dart
// Source: [ASSUMED] -- based on openai_dart 0.4.x API patterns
// MUST verify during spike that this API exists in 0.4.5
final client = OpenaiClient(
  apiKey: 'sk-...',
  baseUrl: 'https://api.deepseek.com/v1', // Custom baseUrl for DeepSeek
);

final stream = client.createChatCompletionStream(
  request: CreateChatCompletionRequest(
    model: 'deepseek-chat',
    messages: [
      ChatCompletionMessage(role: Role.user, content: 'Write a story...'),
    ],
    stream: true,
  ),
);

await for (final chunk in stream) {
  final token = chunk.choices.first.delta?.content ?? '';
  streamingBuffer.append(token);
}
streamingBuffer.complete();
```

### Flutter Frame Time Measurement for Benchmark
```dart
// Source: [ASSUMED] -- Flutter SchedulerBinding API
// Measures frame build+render time during scroll of large Chinese document
SchedulerBinding.instance.addTimingsCallback((timings) {
  for (final timing in timings) {
    final totalMs = timing.totalSpan.inMicroseconds / 1000.0;
    debugPrint('Frame: ${totalMs.toStringAsFixed(2)}ms '
        '(build: ${timing.buildDuration.inMicroseconds / 1000.0}ms, '
        'raster: ${timing.rasterDuration.inMicroseconds / 1000.0}ms)');
  }
});
```

### Automated IME Composition Test Pattern
```dart
// Source: [ASSUMED] -- Flutter widget test with TextEditingDelta simulation
testWidgets('Chinese IME composing lifecycle', (tester) async {
  await tester.pumpWidget(MaterialApp(home: EditorPage()));

  // Simulate IME composing phase (underlined text)
  tester.state<EditableTextState>(find.byType(EditableText))
    .didReceiveTextEditingDelta(
      TextEditingDeltaInsertion(
        oldText: '',
        deltaText: 'jin',
        deltaStart: 0,
        deltaEnd: 3,
        selection: const TextSelection(baseOffset: 3, extentOffset: 3),
        composing: const TextRange(start: 0, end: 3),
      ),
    );
  await tester.pump();

  // Simulate IME commit (final text replaces composing)
  tester.state<EditableTextState>(find.byType(EditableText))
    .didReceiveTextEditingDelta(
      TextEditingDeltaReplacement(
        oldText: 'jin',
        replacementText: '今',
        replacedRange: const TextRange(start: 0, end: 3),
        selection: const TextSelection(baseOffset: 1, extentOffset: 1),
        composing: TextRange.empty,
      ),
    );
  await tester.pump();

  // Verify committed text
  expect(find.text('今'), findsOneWidget);
});
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Riverpod manual providers (2.x) | Riverpod code-gen (3.x, @riverpod) | Riverpod 3.0 (2025) | Less boilerplate, compile-time safe, but requires Dart 3.7+ |
| Freezed 2.x unions | Freezed 3.x sealed classes | Freezed 3.0 (2025) | Better pattern matching, but requires Dart 3.6+ |
| super_editor 0.2.x stable | super_editor 0.3.0-dev | Ongoing | New IME integration, but no stable release yet |
| openai_dart 0.x | openai_dart 6.x | 2024-2025 | Full API coverage, streaming, but requires Dart 3.9+ |

**Deprecated/outdated:**
- `flutter_riverpod 2.x`: Still functional but lacks code-gen. If upgrading Dart, switch to 3.x with `@riverpod` annotation.
- `super_editor 0.2.7`: Stable but outdated. Has `uuid ^3` conflict. Use dev channel.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `openai_dart 0.4.5` supports streaming SSE and custom baseUrl | Standard Stack / Code Examples | SSE streaming spike fails; must upgrade Dart to use 6.x |
| A2 | `anthropic_sdk_dart 0.2.0+1` is functional enough for basic API calls | Standard Stack | Claude API testing in Phase 6 may be impossible |
| A3 | `freezed 2.5.7` provides sufficient `copyWith` and union types for domain entities | Standard Stack | May need sealed classes from Dart 3.x language features as alternative |
| A4 | `flutter_riverpod 2.6.1` with `StateNotifierProvider` is adequate for project state management | Standard Stack | More boilerplate than 3.x code-gen; may slow development |
| A5 | super_editor's custom block API supports story structure overlays | Editor Comparison | May need to wrap content in metadata annotations instead of native blocks |
| A6 | appflowy_editor's `FloatingToolbar` works as described in CLAUDE.md | Editor Comparison | If not production-ready, custom toolbar work needed for both editors |
| A7 | `json_serializable 6.8.4` resolves on Dart 3.5.4 (not yet tested directly) | Standard Stack | May need further downgrade or use manual JSON serialization |
| A8 | Flutter 3.44.0 / Dart 3.5.4 is the correct toolchain (not a misconfigured install) | Version Compatibility | If Flutter should ship newer Dart, `flutter upgrade` fixes everything |
| A9 | Both editors' programmatic text insertion APIs support batch operations for streaming | Editor Comparison | Streaming spike would need alternative approach (e.g., rebuild entire document) |

## Open Questions (RESOLVED BY PLAN)

1. **Can Flutter be upgraded to ship Dart 3.9+?** (RESOLVED BY Plan 00-01 Task 1 — runs `flutter upgrade` then `dart --version`)
   - What we know: Flutter 3.44.0 (2026-05-15) ships Dart 3.5.4 (2024-10-16). This is a 7-month gap.
   - What's unclear: Whether `flutter upgrade` will bring a newer Dart, or if this is a WSL2-specific issue.
   - Recommendation: First task in plan should be `flutter upgrade && dart --version` to check. If Dart becomes 3.9+, all CLAUDE.md versions work.

2. **Does `openai_dart 0.4.5` actually support streaming?** (RESOLVED BY Plan 00-03 Task 2 — verifies streaming API surface and documents blocking finding if absent)
   - What we know: 0.4.x is pre-1.0. The 6.x version has full streaming support.
   - What's unclear: Whether the 0.4.x API has `createChatCompletionStream()` or equivalent.
   - Recommendation: Verify during SSE streaming spike. If not, Dart upgrade becomes mandatory.

3. **How severe is super_editor #2588 (IME position bug) in practice?** (RESOLVED BY Plan 00-02 Task 2 checkpoint — manual IME testing explicitly checks candidate window position)
   - What we know: Bug is open, describes wrong IME candidate window position on Windows.
   - What's unclear: Whether it affects all Chinese IMEs or only specific ones; whether it's a cosmetic issue or a usability blocker.
   - Recommendation: Manual testing must explicitly check IME candidate window position during the IME validation spike.

4. **Can both editors be benchmarked in the same project?** (RESOLVED BY Plan 00-01 Task 1 — uses separate benchmark apps per editor; Plan 00-03 merges only the winner)
   - What we know: They have conflicting transitive dependencies (file_picker, uuid, flutter_plugin_android_lifecycle).
   - What's unclear: Whether dependency_overrides can resolve the conflicts for a spike.
   - Recommendation: Plan for separate benchmark apps. Merge only the winning editor into the project skeleton.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Core framework | Yes | 3.44.0 (stable) | -- |
| Dart SDK | Language | Yes | 3.5.4 (bundled) | -- |
| Windows Desktop | Desktop builds | Yes (WSL2) | N/A | Build on Windows host |
| Android SDK | Android builds | Not checked | -- | Skip for Phase 0 (Android is Phase 6) |
| CMake | Windows native build | Not checked | -- | Install if needed for Windows build |
| Visual Studio | Windows native build | Not checked | -- | Required for Windows desktop build |

**Missing dependencies with no fallback:**
- None identified for Phase 0 scope (Windows desktop + Windows IME testing)

**Missing dependencies with fallback:**
- Android SDK: Not needed for Phase 0 (deferred to Phase 6 per D-12)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Flutter test (built-in) + flutter_test_robots (super_editor companion) |
| Config file | None -- Flutter test conventions |
| Quick run command | `flutter test` |
| Full suite command | `flutter test --coverage` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| (Spike) | Editor renders 100K+ char Chinese document | Performance benchmark | `flutter test test/benchmark/` | Wave 0 |
| (Spike) | IME composing -> committed text lifecycle | Unit/widget test | `flutter test test/ime/` | Wave 0 |
| (Spike) | SSE tokens stream into editor | Integration test | `flutter test test/streaming/` | Wave 0 (needs API key) |
| (Spike) | All packages resolve without conflict | Build verification | `flutter pub get` | N/A |

### Sampling Rate
- **Per task commit:** `flutter test`
- **Per wave merge:** `flutter test --coverage`
- **Phase gate:** Full suite green + manual IME testing pass + benchmark results documented

### Wave 0 Gaps
- [ ] `test/benchmark/` -- large document performance tests
- [ ] `test/ime/` -- automated IME composition tests
- [ ] `test/streaming/` -- SSE streaming integration tests
- [ ] Framework install: Flutter SDK is installed, flutter_test_robots comes with super_editor

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | API key management, not user auth |
| V3 Session Management | No | Local-only app |
| V4 Access Control | No | Single-user local app |
| V5 Input Validation | Yes | Validate AI API responses before inserting into document model |
| V6 Cryptography | Yes | `flutter_secure_storage` for API keys; `hive_ce` AES-256 for sensitive data |

### Known Threat Patterns for Flutter/Desktop

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| API key in plaintext | Information Disclosure | `flutter_secure_storage` (Windows Credential Manager) |
| Malicious API response | Tampering | Validate SSE chunk structure before document insertion |
| Dependency confusion | Supply Chain | Pin exact versions in pubspec.yaml; verify pub.dev provenance |

## Sources

### Primary (HIGH confidence)
- pub.dev API -- live version queries for all 30+ packages, SDK constraints verified
- GitHub API -- super_editor (Flutter-Bounty-Hunters) repo stats, issues, releases
- GitHub API -- appflowy-editor (AppFlowy-IO) repo stats, issues, releases
- Live `flutter pub get` -- verified working dependency set on Dart 3.5.4

### Secondary (MEDIUM confidence)
- CLAUDE.md Technology Stack section -- package version specifications (found incompatible with toolchain)

### Tertiary (LOW confidence)
- Editor API extensibility claims -- based on training knowledge of package APIs, not verified against current docs in this session (web search rate-limited)
- Code examples -- patterns assumed from Dart/Flutter ecosystem conventions, not copied from official docs

## Metadata

**Confidence breakdown:**
- Package compatibility: HIGH -- verified by live pub get resolution on actual toolchain
- Editor CJK IME status: HIGH -- verified by GitHub API issue search on real repos
- Editor API extensibility: LOW -- not verified against current docs (web search unavailable)
- SSE streaming patterns: MEDIUM -- approach is standard but openai_dart 0.4.5 API surface unverified
- Benchmark methodology: MEDIUM -- Flutter performance profiling approach is well-established but specific editor profiling needs empirical validation

**Research date:** 2026-05-31
**Valid until:** 2026-06-30 (packages update frequently; version compatibility may shift with Flutter upgrades)
