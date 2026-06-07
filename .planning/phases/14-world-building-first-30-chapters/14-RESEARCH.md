# Phase 14: World-Building & First 30 Chapters - Research

**Researched:** 2026-06-07
**Domain:** User journey validation via automated scripts + manual spot-checks
**Confidence:** HIGH

## Summary

Phase 14 is a validation phase, not a feature-building phase. All required features shipped in v1.0--v1.2: knowledge base, fragment capture, editor with floating toolbar, manuscript/chapter management, AI integration with knowledge injection and Skill guardian, opening guide, and template library. The phase delivers automated scripts that create a xianxia world and 30 chapter skeletons using the real GLM API, followed by manual spot-checks of 4 key interaction areas and a structured issue log.

The primary technical work is adapting Phase 13's `ProviderContainer` + `FakeAdapter` pattern to use a real `OpenAIAdapter` configured for the GLM API endpoint. The existing `createTestContainer()` opens 5 Hive boxes and overrides `openaiAdapterProvider` -- the Phase 14 script needs the same infrastructure but with `OpenAIAdapter()` instead of `FakeAdapter()`, plus additional boxes for `character_cards`, `world_settings`, `skill_documents`, and `writing_stats`.

**Primary recommendation:** Reuse Phase 13's `test_container.dart` as a template. Create a new `test/journey/` directory with a journey-specific container factory that configures real GLM API credentials, opens all required Hive boxes, and wires the full PromptPipeline with KnowledgeInjection + SkillEnforcement middlewares. Run 30-chapter serial generation with 2-3 second delays between API calls.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Automated-first -- use automated scripts to create manuscript and 30 chapter skeletons, manual spot-check for key interactions. Phase 13's ProviderContainer + FakeAdapter pattern is reusable, but content generation uses real GLM API instead of FakeAdapter.
- **D-02:** Real GLM API -- AI content generation uses real GLM API (not FakeAdapter), user already has API Key. This validates knowledge base auto-injection, anti-AI-scent output quality, and Skill guardian deviation detection with real performance.
- **D-03:** Serial interval calls -- 30 chapters AI content generated serially, 2-3 second interval between each call to avoid GLM API rate limiting. Total generation time ~3-5 minutes.
- **D-04:** Stop on error -- any chapter AI call failure immediately stops the entire process and logs error info. No auto-retry, no skip. User must troubleshoot and re-run.
- **D-05:** Full manual spot-check -- after automation completes, manually verify all 4 key interaction areas: editor floating toolbar (rewrite/polish/free-edit), knowledge injection + Skill guardian, opening guide 3 styles (scene/character/suspense), chapter operations (reorder/split/merge/copy/delete).
- **D-06:** Structured issue log -- problems found during execution recorded in structured document, categorized (functional defect / UX friction / missing need) and severity (high/mid/low). Prepares for Phase 16 pain-point report (REPORT-02).
- **D-07:** Xianxia template + custom supplement -- use Phase 7's existing xianxia preset template for world skeleton (realm system, sect settings), manually supplement custom character cards and Skill guardian rules.
- **D-08:** 3-4 character cards -- protagonist (mortal youth) + 2-3 supporting characters (master, senior/junior disciple, rival). Sufficient to validate character card creation, knowledge base NameIndex character name recognition/injection, and character memory guardian.
- **D-09:** 4-5 Skill guardian rules -- configure rules covering realm system constraints, sect relations, ability limits, world taboos. Validates DeviationDetectionService across 30 chapters of continuous creation.
- **D-10:** Coherent storyline -- 30 chapters with coherent xianxia growth line (mortal -> Qi Refining -> Foundation Establishment). Best for validating knowledge base consistency, character continuity, and Skill guardian long-term effectiveness.
- **D-11:** 300-500 words per chapter -- total ~9,000-15,000 words. Exceeds ROADMAP's "~100 words" minimum, more effective for validating AI generation quality, anti-AI-scent effects, and token audit at real scale.

### Claude's Discretion
Planners may choose:
- Specific plot outline for the xianxia story (each chapter's theme/plot points)
- Specific field content for character cards (name, personality, background, abilities)
- Specific wording and trigger conditions for Skill guardian rules
- Specific structure of automation scripts (whether to reuse Phase 13's ProviderContainer pattern, script segmentation strategy)
- Specific format and storage location for the structured issue log
- Manual spot-check operation step lists (checklist format)
- Fragment capture validation content (what fragments to input in bullet-note mode)
- Knowledge injection validation assertion method (how to determine if character names/settings are correctly injected)

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| JOURNEY-01 | Xianxia template world-building (character cards, world settings, Skill guardian config) | TemplateInstantiationService.createDraft() + saveDraft() for world + characters; SkillRepository.add() for Skill documents; NameIndexService.refresh() to build name index after entities created |
| JOURNEY-02 | Fragment capture to AI synthesis (bullet-note mode input, AI organizes into coherent paragraphs) | FragmentRepository for creating fragments; SynthesisNotifier.startSynthesis() for full pipeline; or direct OpenAIAdapter.createStream() with PromptPipeline.build() for script-only path |
| JOURNEY-03 | Opening guide 3 styles (scene/character/suspense) | OpeningGeneratorService.generateOpenings() returns List<OpeningVariant> with style field; needs AIAdapter + apiKey + baseUrl + model |
| JOURNEY-04 | 30 chapter CRUD + reorder/split/merge/copy/delete | ChapterRepository.add() x30; ChapterNotifier.reorder(), splitChapter(), mergeChapters(), duplicateChapter(); ChapterRepository.delete() |
| JOURNEY-05 | Per-chapter AI generation + knowledge injection + Skill guardian | OpenAIAdapter.createStream() with PromptPipeline (includes KnowledgeInjectionMiddleware + SkillEnforcementMiddleware); DeviationDetectionService.detectDeviations() for post-generation check; TokenAuditService.recordAudit() |
| JOURNEY-06 | Editor floating toolbar (tone rewrite, paragraph polish, free-input edit) + anti-AI-scent | EditorAINotifier.startOperation() with EditorAIOperation.toneRewrite/paragraphPolish/freeInput; AntiAIScentProcessor.process() for post-processing; manual validation only |

</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| World template instantiation | Infrastructure | Application | TemplateInstantiationService loads template JSON and creates entities via repositories |
| Character card / world setting / Skill CRUD | Infrastructure | Domain | Repositories persist immutable entities to Hive boxes |
| Name index building | Application | -- | NameIndexService reads all repositories and builds in-memory index |
| PromptPipeline assembly | Application | -- | Middleware chain composes system + user messages |
| AI streaming (GLM API) | Infrastructure | -- | OpenAIAdapter handles HTTP streaming via openai_dart |
| Knowledge injection | Application | -- | KnowledgeInjectionMiddleware scans text via NameIndex and injects entity context |
| Skill enforcement | Application | -- | SkillEnforcementMiddleware injects active Skill constraints into prompts |
| Deviation detection | Application | Infrastructure | DeviationDetectionService calls AI to check for setting violations |
| Anti-AI-scent processing | Application | -- | AntiAIScentProcessor does regex-based replacement and highlighting |
| Token audit recording | Application | Infrastructure | TokenAuditService buffers records, flushes to Hive repository |
| Fragment capture | Application | Infrastructure | FragmentRepository persists; FragmentService provides CRUD |
| Opening generation | Application | Infrastructure | OpeningGeneratorService calls AI to produce 3 style variants |
| Chapter management | Application | Infrastructure | ChapterNotifier orchestrates CRUD/split/merge; ChapterRepository persists |
| Manual spot-check | Human | -- | Editor floating toolbar, opening guide, chapter operations require UI interaction |

## Standard Stack

### Core (Existing - No New Installs)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_riverpod | ^3.3.1 | State management, ProviderContainer | Project constraint. ProviderContainer is the test harness foundation. |
| openai_dart | ^6.0.0 | OpenAI-compatible API client | Supports custom baseUrl for GLM API endpoint. Streaming via createStream(). |
| hive_ce | ^2.19.3 | Local NoSQL database | All entity persistence. Journey scripts open 9+ Hive boxes. |
| hive_ce_flutter | ^2.3.4 | Flutter integration for Hive | Hive.initFlutter() for path resolution. |
| uuid | latest | Entity ID generation | All domain entities use UUIDs. |

### Supporting (Existing - Used by Journey Scripts)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| flutter_test | SDK | Test framework for journey scripts | TestWidgetsFlutterBinding.ensureInitialized() for Hive init in test context |
| build_runner | latest | Code generation runner | May need `dart run build_runner build` if generated code is stale |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| ProviderContainer in test/ | flutter drive integration test | ProviderContainer is lighter, no device needed. Reuses Phase 13 proven pattern. |
| Direct OpenAIAdapter calls | SynthesisNotifier flow | Direct calls are simpler for scripted generation; SynthesisNotifier requires UI state (selectedFragments, editor). |

**Installation:**
No new packages needed. All dependencies are already in pubspec.yaml from previous phases.

**Version verification:**
```
Flutter 3.44.0 (stable) / Dart 3.12.0 (stable) -- verified on machine
flutter_riverpod: ^3.3.1 -- in pubspec.yaml
openai_dart: ^6.0.0 -- in pubspec.yaml
hive_ce: ^2.19.3 -- in pubspec.yaml
```

## Package Legitimacy Audit

This phase installs NO new external packages. All packages were verified and approved in previous phases (Phase 7-13). The journey scripts use only existing project dependencies.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| (none new) | -- | -- | -- | -- | -- | N/A |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
[Journey Script Entry]
        |
        v
[ProviderContainer Factory]
   |-- OpenAIAdapter (real GLM API)
   |-- 9+ Hive Boxes (manuscripts, chapters, token_audit, ...)
   |-- PromptPipeline (with KnowledgeInjection + SkillEnforcement)
   |
   +---> [Phase A: World Building]
   |      |-- WorldTemplateRepository -> load xianxia template JSON
   |      |-- TemplateInstantiationService -> createDraft() + saveDraft()
   |      |-- CharacterCardRepository.add() x 3-4
   |      |-- WorldSettingRepository.add() x 1
   |      |-- SkillRepository.add() x 4-5 (isActive: true)
   |      +-- NameIndexService.refresh() -> build name index
   |
   +---> [Phase B: Fragment Capture + Synthesis]
   |      |-- FragmentRepository.add() (3-5 fragments)
   |      |-- OpenAIAdapter.createStream() via PromptPipeline
   |      +-- AntiAIScentProcessor.process() -> validate output
   |
   +---> [Phase C: Opening Guide 3 Styles]
   |      |-- OpeningGeneratorService.generateOpenings()
   |      +-- Verify 3 variants (scene/character/suspense)
   |
   +---> [Phase D: 30 Chapter Skeleton + AI Generation]
   |      |-- ManuscriptRepository.add()
   |      |-- ChapterRepository.add() x 30 (serial loop)
   |      |-- For each chapter:
   |      |     |-- PromptPipeline.build() (KnowledgeInjection + SkillEnforcement)
   |      |     |-- OpenAIAdapter.createStream() -> 300-500 chars
   |      |     |-- ChapterRepository.updateDocumentContent()
   |      |     |-- TokenAuditService.recordAudit()
   |      |     +-- Future.delayed(2-3s) -> rate limit
   |      +-- TokenAuditService.flush() -> persist all audit records
   |
   +---> [Phase E: Token Audit Verification]
   |      |-- TokenAuditRepository.buildSnapshot()
   |      +-- Assert totalCalls == 30, totalTokens > 0
   |
   +---> [Phase F: Manual Spot-Check Checklist]
          |-- Editor floating toolbar (rewrite/polish/free-input)
          |-- Knowledge injection effectiveness (check prompt content)
          |-- Opening guide 3 styles in UI
          +-- Chapter operations (reorder/split/merge/copy/delete)
```

### Recommended Project Structure

```
test/
├── journey/                           # Phase 14 journey validation scripts
│   ├── helpers/
│   │   ├── journey_container.dart     # ProviderContainer factory with real GLM API
│   │   ├── xianxia_fixtures.dart      # Character cards, world settings, Skill documents
│   │   └── story_outline.dart         # 30-chapter plot outline data
│   ├── world_building_test.dart       # JOURNEY-01: template + world + characters + skills
│   ├── fragment_synthesis_test.dart   # JOURNEY-02: fragment capture -> AI synthesis
│   ├── opening_guide_test.dart        # JOURNEY-03: 3 opening styles
│   ├── chapter_management_test.dart   # JOURNEY-04: 30 chapter CRUD + reorder/split/merge
│   ├── serial_generation_test.dart    # JOURNEY-05: 30-chapter AI generation with pipeline
│   └── full_journey_test.dart         # E2E: complete flow from world-building to 30 chapters
├── automation/                        # Phase 13 infrastructure (existing)
│   ├── helpers/
│   │   ├── fake_adapter.dart
│   │   └── test_container.dart
│   └── core_flow_test.dart
└── ...
```

### Pattern 1: Journey Container Factory (Real API)

**What:** Creates a ProviderContainer configured for real GLM API calls instead of FakeAdapter.
**When to use:** All journey validation scripts that need real AI interaction.
**Example:**
```dart
// Source: Adapted from test/automation/helpers/test_container.dart
Future<ProviderContainer> createJourneyContainer({
  required String apiKey,
  required String baseUrl,
  required String model,
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final tempDir = Directory.systemTemp.createTempSync('journey_test_');
  Hive.init(tempDir.path);

  // Open ALL required boxes (journey uses more features than Phase 13)
  await Hive.openBox<dynamic>('manuscripts');
  await Hive.openBox<dynamic>('chapters');
  await Hive.openBox<dynamic>('token_audit');
  await Hive.openBox<dynamic>('ai_providers');
  await Hive.openBox<dynamic>('fragments');
  await Hive.openBox<dynamic>('character_cards');
  await Hive.openBox<dynamic>('world_settings');
  await Hive.openBox<dynamic>('skill_documents');
  await Hive.openBox<dynamic>('writing_stats');

  // Use REAL OpenAIAdapter (not FakeAdapter)
  return ProviderContainer(
    overrides: [
      openaiAdapterProvider.overrideWithValue(OpenAIAdapter()),
      // Override activeProvider + apiKey so all dependent services work
      activeProviderProvider.overrideWithValue(AIProvider(
        id: 'glm',
        name: 'GLM',
        baseUrl: baseUrl,
        model: model,
        // ... other fields
      )),
      activeApiKeyProvider.overrideWithValue(apiKey),
    ],
  );
}
```

### Pattern 2: World-Building via Template Instantiation

**What:** Uses TemplateInstantiationService to create world + characters from xianxia preset template.
**When to use:** JOURNEY-01 world-building setup.
**Example:**
```dart
// Source: lib/features/templates/application/template_instantiation_service.dart
// Load the xianxia template (id: "male-xianxia-sect")
final templateRepo = container.read(worldTemplateRepositoryProvider);
final template = await templateRepo.getById('male-xianxia-sect');
expect(template, isNotNull);

// Create draft with custom story concept
final instantiationService = await container.read(
  templateInstantiationServiceProvider.future,
);
final draft = instantiationService.createDraft(
  template!,
  storyConcept: '凡人少年入门修仙，经历炼气、筑基的成长之路',
);

// Save: creates WorldSetting + CharacterCards
final result = await instantiationService.saveDraft(draft);
expect(result.worldSetting, isNotNull);
expect(result.characterCards, hasLength(3)); // template has 3 characters
```

### Pattern 3: Skill Document Creation for Guardian Rules

**What:** Creates SkillDocument entities with structured sections for realm constraints, taboos, etc.
**When to use:** JOURNEY-01 Skill guardian configuration.
**Example:**
```dart
// Source: lib/features/knowledge/domain/skill_document.dart
final skillRepo = await container.read(skillRepositoryProvider.future);

// Rule 1: Realm system constraints
await skillRepo.add(SkillDocument(
  id: '',
  name: '境界体系约束',
  description: '修仙世界力量等级体系规则',
  content: '凡人 -> 练气九层 -> 筑基 -> 金丹 -> 元婴 -> 化神',
  sections: SkillSections(
    powerHierarchy: '凡人 < 练气(1-9层) < 筑基 < 金丹 < 元婴 < 化神',
    rules: '不可跨境界战斗获胜；突破需要对应灵材和心性考验',
    taboos: '主角当前为凡人/练气期，不能使用筑基以上法术',
  ),
  isActive: true,
  createdAt: DateTime.now(),
));
```

### Pattern 4: Serial AI Generation with Pipeline

**What:** For each chapter, builds prompt via PromptPipeline (with KnowledgeInjection + SkillEnforcement), calls real GLM API, records audit.
**When to use:** JOURNEY-05 per-chapter AI generation.
**Example:**
```dart
// Source: lib/features/ai/application/prompt_pipeline.dart
final pipeline = await container.read(promptPipelineProvider.future);
final adapter = container.read(openaiAdapterProvider);
final auditService = await container.read(tokenAuditServiceProvider.future);
final apiKey = container.read(activeApiKeyProvider)!;

for (var i = 0; i < 30; i++) {
  final chapter = chapters[i];

  // Build prompt with knowledge injection + skill enforcement
  final context = PromptContext(
    fragments: [Fragment(
      id: 'frag-$i',
      text: storyOutline[i],  // chapter plot point
      createdAt: DateTime.now(),
    )],
    bannedPhrases: [],
  );
  final messages = pipeline.build(context);

  // Stream from real GLM API
  final buffer = StringBuffer();
  await adapter.createStream(
    apiKey: apiKey,
    baseUrl: baseUrl,
    model: model,
    messages: messages,
    onUsage: (usage) {
      auditService.recordAudit(
        usage: usage,
        modelName: model,
        operationType: AuditOperationType.synthesis,
        manuscriptId: manuscript.id,
        chapterId: chapter.id,
        inputText: storyOutline[i],
        outputText: buffer.toString(),
      );
    },
  ).forEach(buffer.write);

  // Save generated content to chapter
  final chapterRepo = await container.read(chapterRepositoryProvider.future);
  await chapterRepo.updateDocumentContent(chapter.id, buffer.toString());

  // Rate limit between calls
  await Future.delayed(Duration(seconds: 2));
}
```

### Anti-Patterns to Avoid

- **Don't call SynthesisNotifier directly in scripts**: SynthesisNotifier reads from UI state (selectedFragments via captureProvider, editorProvider). For scripted generation, call OpenAIAdapter + PromptPipeline directly.
- **Don't skip NameIndexService.refresh()**: After creating character cards and world settings, the name index must be rebuilt. Without refresh, KnowledgeInjectionMiddleware won't match any entity names in prompts.
- **Don't forget TokenAuditService.flush()**: The audit service uses 30-second debatched writes. After the serial generation loop, explicitly flush to ensure all records are persisted before verification.
- **Don't use FakeAdapter for content generation**: D-02 mandates real GLM API. FakeAdapter is only for Phase 13's automated test suite.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| ProviderContainer setup | Custom DI framework | Phase 13's test_container.dart pattern | Proven pattern, just swap FakeAdapter for OpenAIAdapter |
| AI streaming | Raw HTTP client | OpenAIAdapter.createStream() | Handles error classification, client caching, HTTPS validation |
| Prompt assembly | Manual message concatenation | PromptPipeline.build() | 6 middlewares in correct order: SystemPrompt -> PersonaInjection -> BannedList -> KnowledgeInjection -> SkillEnforcement -> UserContent |
| Name matching | Custom string search | NameIndex.findMatches() | Boundary-aware matching, entity type tracking, multi-alias support |
| Token estimation | Manual character counting | TokenBudgetCalculator.estimateTokens() | Used by both KnowledgeInjection and SkillEnforcement for budget management |
| Anti-AI-scent processing | Custom regex replacement | AntiAIScentProcessor.process() | Dual-layer: auto-replacement + structural highlighting with boundary awareness |
| World template loading | File parsing | WorldTemplateRepository + TemplateInstantiationService | Loads JSON assets, creates drafts, saves to repositories |
| Chapter content persistence | Raw Hive put | ChapterRepository.updateDocumentContent() | Sets updatedAt timestamp, validates entity exists |
| Token audit recording | Direct Hive writes | TokenAuditService.recordAudit() + flush() | Debatched writes, auto-cleanup at 10K records |

**Key insight:** The entire creation pipeline already exists. The journey script is orchestration code that wires existing services together in sequence. No new business logic needed.

## Runtime State Inventory

This is NOT a rename/refactor/migration phase. This section is SKIPPED.

## Common Pitfalls

### Pitfall 1: Missing Hive Boxes
**What goes wrong:** Journey scripts crash with "Box not found" when accessing providers that depend on unopened Hive boxes.
**Why it happens:** Phase 13's test_container.dart only opens 5 boxes (manuscripts, chapters, token_audit, ai_providers, fragments). The journey needs 4 additional boxes: character_cards, world_settings, skill_documents, writing_stats.
**How to avoid:** Open ALL 9 boxes in the journey container factory. Reference the full list in providers.dart.
**Warning signs:** `HiveError: Box not found` when reading CharacterCardRepository, WorldSettingRepository, SkillRepository, or WritingStatsRepository.

### Pitfall 2: NameIndex Empty After Entity Creation
**What goes wrong:** KnowledgeInjectionMiddleware finds no matches even though character cards and world settings exist.
**Why it happens:** NameIndexService is a Notifier that builds the index once during build(). When entities are added to repositories after container creation, the index is stale.
**How to avoid:** After creating all character cards, world settings, and Skill documents, call `container.read(nameIndexServiceProvider.notifier).refresh()` to invalidate and rebuild the index.
**Warning signs:** Generated chapters show no knowledge injection in the system prompt; DeviationDetection produces zero warnings despite intentional violations.

### Pitfall 3: PromptPipeline Missing Middlewares
**What goes wrong:** PromptPipeline is created without KnowledgeInjection or SkillEnforcement middlewares.
**Why it happens:** promptPipelineProvider tries to watch knowledgeInjectionMiddlewareProvider and skillEnforcementMiddlewareProvider with try/catch that silently falls back to null. If the repositories aren't ready when the pipeline is first resolved, middlewares are skipped.
**How to avoid:** Ensure all knowledge-related providers are resolved BEFORE reading promptPipelineProvider. Or construct the pipeline explicitly with middlewares after entities are created.
**Warning signs:** Generated prompts don't contain entity context blocks like "【角色】林风" or Skill constraint sections like "以下是当前激活的世界观设定约束".

### Pitfall 4: GLM API Rate Limiting
**What goes wrong:** GLM API returns 429 errors after rapid sequential calls.
**Why it happens:** Even with 2-3 second delays, the GLM API may rate-limit if other requests are in flight or if the model has stricter limits.
**How to avoid:** Use `await Future.delayed(Duration(seconds: 3))` between calls (D-03). If 429 occurs, D-04 says stop immediately and log. Consider adding a configurable delay constant.
**Warning signs:** `AIRateLimitException` thrown from OpenAIAdapter.

### Pitfall 5: TokenAuditService Unflushed Records
**What goes wrong:** Token audit verification shows fewer than 30 records.
**Why it happens:** TokenAuditService uses a 30-second debounce timer. If the script exits or checks immediately after the generation loop, records may still be in the pending buffer.
**How to avoid:** Always call `await auditService.flush()` before reading `TokenAuditRepository.buildSnapshot()`.
**Warning signs:** `snapshot.totalCalls` is less than the number of API calls made.

### Pitfall 6: SecureStorage Dependency in Test Context
**What goes wrong:** settingsRepositoryProvider fails because flutter_secure_storage doesn't work in test environment.
**Why it happens:** settingsRepositoryProvider uses SecureStorageService to manage Hive encryption keys, which requires platform channels unavailable in `flutter test`.
**How to avoid:** Do NOT open the 'settings' box or use settingsRepositoryProvider. Journey scripts should not need settings. If provider resolution chains hit this provider, override it with a mock or skip it.
**Warning signs:** `MissingPluginException` or `PlatformException` when resolving settingsRepositoryProvider.

### Pitfall 7: WorldTemplateRepository Asset Loading in Test
**What goes wrong:** WorldTemplateRepository.loadLibrary() fails because it uses `rootBundle.loadString()` which requires Flutter asset binding.
**Why it happens:** The template JSON is an asset bundled with the app. In test context, assets are available if `TestWidgetsFlutterBinding.ensureInitialized()` is called and the test runs via `flutter test` (which includes asset bundle setup).
**How to avoid:** Ensure TestWidgetsFlutterBinding is initialized. Alternatively, construct WorldTemplate directly from the JSON data without using WorldTemplateRepository (read the file from the filesystem).
**Warning signs:** `Unable to load asset: assets/templates/world_presets/templates_zh.json`.

### Pitfall 8: PromptPipeline vs EditorPromptPipeline Confusion
**What goes wrong:** Using EditorPromptPipeline for chapter generation instead of PromptPipeline.
**Why it happens:** Both exist in the codebase. EditorPromptPipeline is for editor AI operations (rewrite/polish/freeInput) that use selectedText instead of fragments.
**How to avoid:** Use `promptPipelineProvider` (not `editorPromptPipelineProvider`) for fragment-based chapter generation. Use `editorPromptPipelineProvider` only for JOURNEY-06 manual validation of floating toolbar operations.
**Warning signs:** Generated prompts don't include fragment content, or include operation-type instructions like "改写" in the system message.

## Code Examples

### Complete Journey Container Factory

```dart
// Source: Adapted from test/automation/helpers/test_container.dart (Phase 13)
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';

Future<ProviderContainer> createJourneyContainer({
  required String apiKey,
  required String baseUrl,
  required String model,
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final tempDir = Directory.systemTemp.createTempSync('journey_test_');
  Hive.init(tempDir.path);

  // All boxes used by the features under test
  final boxes = [
    'manuscripts', 'chapters', 'token_audit', 'ai_providers',
    'fragments', 'character_cards', 'world_settings',
    'skill_documents', 'writing_stats', 'daily_writing_stats',
    'achievement_badges', 'plot_nodes', 'foreshadowing_entries',
    'graph_positions', 'guardian_annotations',
  ];
  for (final name in boxes) {
    await Hive.openBox<dynamic>(name);
  }

  final provider = AIProvider(
    id: 'glm-journey',
    name: 'GLM',
    baseUrl: baseUrl,
    model: model,
    temperature: 0.8,
    topP: 0.9,
  );

  return ProviderContainer(overrides: [
    openaiAdapterProvider.overrideWithValue(OpenAIAdapter()),
    activeProviderProvider.overrideWithValue(provider),
    activeApiKeyProvider.overrideWithValue(apiKey),
  ]);
}
```

### Skill Guardian Rule Examples for Xianxia World

```dart
// Source: Derived from lib/features/knowledge/domain/skill_document.dart structure

// Rule 1: Realm progression constraints
SkillDocument(
  id: '', name: '境界体系约束',
  description: '修仙力量等级规则',
  content: '凡人->练气->筑基->金丹->元婴->化神',
  sections: SkillSections(
    powerHierarchy: '凡人 < 练气(1-9层) < 筑基 < 金丹 < 元婴 < 化神',
    rules: '不可跨大境界战斗获胜；突破需要灵材+心性考验',
    taboos: '练气期不可使用筑基以上法术；丹药等级不得超过当前境界两层',
  ),
  isActive: true, createdAt: DateTime.now(),
)

// Rule 2: Sect hierarchy
SkillDocument(
  id: '', name: '门派等级森严',
  description: '宗门等级制度约束',
  content: '门派等级森严，不可逾越',
  sections: SkillSections(
    rules: '外门弟子不得擅入内门禁地；杂役弟子不可直接面见长老',
    taboos: '低阶弟子不可对高阶师兄无礼；未经允许不可学习其他峰的功法',
  ),
  isActive: true, createdAt: DateTime.now(),
)

// Rule 3: World technology limits (no firearms)
SkillDocument(
  id: '', name: '世界观禁忌',
  description: '修仙世界不存在的事物',
  content: '世界观禁忌限制',
  sections: SkillSections(
    taboos: '不存在火器、枪械、现代电子设备；不存在"科学"概念；通信只能用符箓或灵兽传书',
  ),
  isActive: true, createdAt: DateTime.now(),
)
```

### Deviation Detection After Chapter Generation

```dart
// Source: lib/features/knowledge/application/deviation_detection_service.dart
final deviationService = await container.read(
  deviationDetectionServiceProvider.future,
);
final skillRepo = await container.read(skillRepositoryProvider.future);
final activeSkills = skillRepo.getActive();

// After generating chapter content, check for deviations
final result = await deviationService.detectDeviations(
  chapterContent,
  activeSkills,
  manuscriptId: manuscript.id,
  chapterId: chapter.id,
);

if (result.hasWarnings) {
  for (final warning in result.warnings) {
    debugPrint('[偏离] ${warning.severity}: ${warning.description}');
    debugPrint('  规则: ${warning.skillName}');
    if (warning.suggestedFix != null) {
      debugPrint('  建议: ${warning.suggestedFix}');
    }
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| FakeAdapter for all test automation | Real API for journey validation | Phase 14 decision (D-02) | Journey scripts now test real AI output quality, not just flow correctness |
| Phase 13: 5 Hive boxes in test container | Phase 14: 15+ Hive boxes needed | Phase 14 scope expansion | More features under test require more repositories initialized |
| Single batch generation (Phase 13 E2E) | Serial generation with rate limiting | Phase 14 decision (D-03) | Real API has rate limits; must add inter-call delays |
| No deviation detection in tests | Post-generation deviation checks | Phase 14 scope (JOURNEY-05) | Validates DeviationDetectionService end-to-end with real content |

**Deprecated/outdated:**
- Phase 13's FakeAdapter: Still valid for unit tests, but NOT for journey content generation per D-02.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | GLM API endpoint is `https://open.bigmodel.cn/api/paas/v4` or user-provided | Architecture | Script fails to connect; user must provide correct endpoint |
| A2 | User's GLM API key has sufficient quota for ~30 + 5 API calls (~35 total) | Architecture | Script hits billing/quota limits mid-run |
| A3 | WorldTemplateRepository works in `flutter test` context via asset bundle | Architecture | Must fall back to filesystem JSON loading |
| A4 | SecureStorage-related providers can be avoided without breaking the provider graph | Pitfalls | If provider resolution chain forces SecureStorage, must add mock override |
| A5 | `openai_dart` package is compatible with GLM's OpenAI-compatible endpoint (chat completions + streaming) | Architecture | Streaming may fail; need to verify GLM's specific streaming format |
| A6 | The "male-xianxia-sect" template ID exists in templates_zh.json and has 3 characters + world data | Code Examples | Must use correct template ID or load template differently |

## Open Questions

All previously open research questions are resolved into explicit pre-execution plan tasks/checkpoints in `14-01-PLAN.md` and `14-03-PLAN.md`.

1. **GLM API Streaming Compatibility — RESOLVED FOR EXECUTION**
   - Decision: `serial_generation_test.dart` must run a single real GLM streaming smoke test before the 30-chapter loop.
   - Evidence path: The test logs `[SMOKE_TEST_PASSED]` on success or `[SMOKE_TEST_FAILED]` and rethrows on failure. This satisfies D-04 stop-on-error before sustained generation begins.

2. **Provider Graph Depth with Real API Credentials — RESOLVED FOR EXECUTION**
   - Decision: `journey_container.dart` must override `activeProviderProvider`, `activeApiKeyProvider`, and `openaiAdapterProvider` directly. The Plan 14-01 checkpoint explicitly checks for absence of `StateError: 未配置可用的 AI 模型`, `MissingPluginException`, and `PlatformException`.
   - Evidence path: `opening_guide_test.dart`, `serial_generation_test.dart`, and `full_journey_test.dart` all fail fast if provider graph overrides are insufficient.

3. **Manual Spot-Check Scope Definition — RESOLVED FOR EXECUTION**
   - Decision: Automated tests verify prompt/content/audit assertions; the Plan 14-03 blocking human checkpoint requires actual app interaction for editor toolbar rewrite, polish, free-input, anti-AI-scent review, knowledge/Skill UI checks, opening guide style review, and chapter operations.
   - Evidence path: `14-ISSUE-LOG.md` must record evidence for each manual-only subsection before approval.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Test runner | Y | 3.44.0 | -- |
| Dart SDK | Test runner | Y | 3.12.0 | -- |
| GLM API Key | Real AI calls | Needs user input | -- | Cannot run without it |
| GLM API Endpoint | OpenAIAdapter baseUrl | Needs user input | -- | Default: `https://open.bigmodel.cn/api/paas/v4` |
| `flutter test` | Script execution | Y | -- | -- |
| Network access | GLM API calls | Y (assumed) | -- | Cannot run without it |

**Missing dependencies with no fallback:**
- GLM API Key: Must be provided by user at execution time. Script must accept it as parameter or environment variable.
- GLM API Endpoint URL: Must be confirmed by user. May differ from default.

**Missing dependencies with fallback:**
- None identified.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (Dart test framework) |
| Config file | none -- tests run via `flutter test test/journey/` |
| Quick run command | `flutter test test/journey/world_building_test.dart` |
| Full suite command | `flutter test test/journey/ -j 1 --timeout 900s` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| JOURNEY-01 | World template instantiation + character cards + Skill documents | Integration | `flutter test test/journey/world_building_test.dart` | Wave 0 |
| JOURNEY-02 | Fragment capture -> AI synthesis | Integration | `flutter test test/journey/fragment_synthesis_test.dart` | Wave 0 |
| JOURNEY-03 | Opening guide 3 styles | Integration | `flutter test test/journey/opening_guide_test.dart` | Wave 0 |
| JOURNEY-04 | 30 chapter CRUD + reorder/split/merge | Integration | `flutter test test/journey/chapter_management_test.dart` | Wave 0 |
| JOURNEY-05 | 30-chapter serial AI generation | Integration | `flutter test test/journey/serial_generation_test.dart -j 1 --timeout 900s` | Wave 0 |
| JOURNEY-06 | Editor floating toolbar + anti-AI-scent | Manual-only | Human interaction with running app | N/A |

### Sampling Rate
- **Per task commit:** `flutter test test/journey/<specific_test>.dart`
- **Per wave merge:** `flutter test test/journey/ -j 1 --timeout 900s`
- **Phase gate:** Full journey suite green + manual spot-check checklist complete

### Wave 0 Gaps
- [ ] `test/journey/helpers/journey_container.dart` -- journey container factory
- [ ] `test/journey/helpers/xianxia_fixtures.dart` -- character card, world setting, Skill document data
- [ ] `test/journey/helpers/story_outline.dart` -- 30-chapter plot points
- [ ] `test/journey/world_building_test.dart` -- covers JOURNEY-01
- [ ] `test/journey/fragment_synthesis_test.dart` -- covers JOURNEY-02
- [ ] `test/journey/opening_guide_test.dart` -- covers JOURNEY-03
- [ ] `test/journey/chapter_management_test.dart` -- covers JOURNEY-04
- [ ] `test/journey/serial_generation_test.dart` -- covers JOURNEY-05
- [ ] `test/journey/full_journey_test.dart` -- E2E full flow

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | GLM API Key authentication via OpenAIAdapter |
| V3 Session Management | no | Stateless API calls, no session state |
| V4 Access Control | no | No user-facing access control in scripts |
| V5 Input Validation | yes | AIAdapter validates baseUrl (HTTPS enforcement), domain validates field lengths |
| V6 Cryptography | yes | API Key stored in env/parameter, never committed to git |

### Known Threat Patterns for Journey Scripts

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| API Key exposure in test output | Information Disclosure | Never print apiKey; use environment variable; ensure .gitignore covers any config files |
| Unencrypted API Key in temp directory | Information Disclosure | Don't write API key to disk; pass as parameter only |
| Man-in-the-middle on API calls | Tampering | OpenAIAdapter._validateBaseUrl() enforces HTTPS (except localhost) |

## Sources

### Primary (HIGH confidence)
- Codebase analysis: `test/automation/helpers/test_container.dart` -- ProviderContainer factory pattern
- Codebase analysis: `test/automation/core_flow_test.dart` -- 8-segment + E2E test structure
- Codebase analysis: `lib/features/ai/infrastructure/openai_adapter.dart` -- OpenAIAdapter implementation
- Codebase analysis: `lib/features/ai/application/prompt_pipeline.dart` -- Pipeline + middleware chain
- Codebase analysis: `lib/features/knowledge/application/knowledge_injection_middleware.dart` -- Knowledge injection
- Codebase analysis: `lib/features/knowledge/application/skill_enforcement_middleware.dart` -- Skill enforcement
- Codebase analysis: `lib/features/knowledge/application/deviation_detection_service.dart` -- Deviation detection
- Codebase analysis: `lib/features/templates/application/template_instantiation_service.dart` -- Template instantiation
- Codebase analysis: `lib/core/presentation/providers.dart` -- Full provider graph (700 lines)
- Codebase analysis: `assets/templates/world_presets/templates_zh.json` -- Xianxia template data

### Secondary (MEDIUM confidence)
- Phase 13 CONTEXT.md -- FakeAdapter pattern, test infrastructure decisions
- Phase 12 CONTEXT.md -- Token audit architecture

### Tertiary (LOW confidence)
- GLM API endpoint URL (`https://open.bigmodel.cn/api/paas/v4`) -- [ASSUMED] from CONTEXT.md specifics

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all packages already in pubspec.yaml, verified on machine
- Architecture: HIGH -- all source code read and analyzed directly
- Pitfalls: HIGH -- derived from code analysis, not external sources
- GLM API compatibility: MEDIUM -- assumed OpenAI-compatible but not tested in this session

**Research date:** 2026-06-07
**Valid until:** 2026-07-07 (30 days -- stable codebase, no fast-moving dependencies)
