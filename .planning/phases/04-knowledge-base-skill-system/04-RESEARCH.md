# Phase 4: Knowledge Base + Skill System - Research

**Researched:** 2026-06-02
**Domain:** Knowledge base CRUD, Chinese entity name matching, PromptPipeline extension, skill system for world-building, deviation detection
**Confidence:** HIGH

## Summary

Phase 4 adds the knowledge base and skill system to MuseFlow. Users create character cards (name, personality, appearance, backstory, aliases) and world settings (rules, factions, geography, technology level) stored in Hive. A name-index entity matcher scans editor text and AI prompt context to auto-inject relevant character/setting data into the PromptPipeline -- no manual selection required. The skill system lets users describe a world concept, have AI generate a complete setting document (power hierarchy, faction relations, rules, taboos, terminology), and then enforce those constraints during writing with real-time deviation detection.

The technical foundation is solid. The existing PromptPipeline middleware chain is the natural injection point for knowledge context -- a new `KnowledgeInjectionMiddleware` slots between BannedListMiddleware and UserContentMiddleware. The Hive CE repository pattern (manual TypeAdapter delegating to fromJson/toJson) is well-established across Fragment, AppSettings, and AIProvider. Riverpod FutureProvider for repositories is the standard pattern. super_editor's keyboard action system uses a chain-of-responsibility pattern with `DocumentKeyboardAction` functions returning `ExecutionInstruction`, which is how the quick-insert shortcut (Ctrl+K) will be implemented.

The primary risk is Chinese name matching accuracy. A dictionary-based approach using the knowledge base's own entity names as the lookup dictionary is the most reliable for this domain -- no external NLP library needed since we control the vocabulary. Token budget management is critical: with large knowledge bases, the injection middleware must select only the most relevant entities to avoid exhausting the context window.

**Primary recommendation:** Build knowledge entities as immutable domain classes with Hive persistence, implement name-index matching via a simple substring/trie lookup against the knowledge base dictionary, extend PromptPipeline with a `KnowledgeInjectionMiddleware`, and use AI-assisted prompt engineering for skill generation and deviation detection.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Character card / world setting CRUD | Domain + Application | Infrastructure | Entity definition + use cases + Hive persistence |
| Name-index entity matching | Application | Infrastructure | Scans text for entity name occurrences, returns matched entities |
| Knowledge auto-injection into PromptPipeline | Application | -- | New middleware in the pipeline chain |
| Skill document generation (AI-assisted) | Application | Infrastructure | Prompt engineering + streaming via OpenAIAdapter |
| Deviation detection | Application | Infrastructure | AI-based contradiction checking via prompt engineering |
| Knowledge base UI (list/detail/edit) | Presentation | -- | CRUD screens for character cards and world settings |
| Skill management UI | Presentation | -- | Skill list, activation toggle, generation wizard |
| Quick-insert keyboard shortcut | Presentation | -- | super_editor keyboard action + dialog overlay |
| Entity name indexing infrastructure | Infrastructure | -- | Trie/index data structure for fast name lookup |

## Standard Stack

### Core (already installed)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| hive_ce | ^2.19.3 | Local NoSQL storage | Already in use for all persistence |
| hive_ce_flutter | ^2.3.4 | Flutter Hive integration | Box initialization |
| flutter_riverpod | ^3.3.1 | State management | Project standard |
| openai_dart | ^6.0.0 | AI API client | Already in use for streaming |
| super_editor | 0.3.0-dev.20 | Rich text editor | Keyboard shortcut integration |
| uuid | ^4.5.1 | Entity ID generation | Already in use |

### Supporting (already installed)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| json_annotation | ^4.12.0 | JSON serialization | Entity fromJson/toJson |
| follow_the_leader | ^0.5.3 | Overlay positioning | Quick-insert dialog positioning |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Dictionary-based name matching | jieba_flutter or HanLP | External NLP adds binary dependency, platform channel complexity, and is overkill when we control the vocabulary. Dictionary-based matching against known entity names is faster, deterministic, and sufficient. |
| AI-based entity extraction | Local NER model | Requires model download, adds inference latency. Dictionary matching is O(n) and zero-latency. |
| Separate knowledge injection service | Standalone middleware | The PromptPipeline middleware pattern is already established and composable -- no reason to create a parallel system. |
| sqflite/drift for knowledge storage | Hive CE | Project mandates Hive CE. Knowledge entities are document-oriented (flexible schema), not relational. |

**Installation:**
```bash
# No new packages required -- all dependencies already in pubspec.yaml
```

**Version verification:** All packages verified via pubspec.yaml as of 2026-06-02. No version conflicts.

## Package Legitimacy Audit

> No new external packages required. Phase 4 builds entirely on the existing dependency set.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| hive_ce | pub.dev | 3+ yrs | established | github.com/iodesign-team/hive_ce | N/A (already installed) | Approved |
| flutter_riverpod | pub.dev | 4+ yrs | established | github.com/rrousselGit/riverpod | N/A (already installed) | Approved |
| openai_dart | pub.dev | 2+ yrs | established | github.com/davidmigloz/openai_dart | N/A (already installed) | Approved |
| super_editor | pub.dev | 3+ yrs | established | github.com/superlistapp/super_editor | N/A (already installed) | Approved |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Project Constraints (from CLAUDE.md)

- **Architecture**: Clean Architecture (domain -> application -> infrastructure -> presentation)
- **State management**: Riverpod exclusively
- **Storage**: Hive CE local database, JSON export, API keys encrypted
- **Immutable entities**: All data classes use `copyWith`, no mutation
- **Error handling**: `Result<T>` type, full try-catch, no empty catch blocks
- **Testing**: TDD, coverage >= 90%, test naming: `should [behavior] when [conditions]`
- **Formatting**: `flutter format` + `flutter analyze` zero errors
- **Anti-AI-scent**: Product soul -- no "one-click generate" buttons, forced segmented interaction
- **Performance**: Startup < 3s, memory < 200MB, 60fps
- **File limits**: Recommended 200-400 lines, max 800 lines

## Architecture Patterns

### System Architecture Diagram

```
User writes in editor / triggers AI operation
        |
        v
PromptPipeline.build(context)
        |
        v
[SystemPromptMiddleware] -> [PersonaInjectionMiddleware] -> [BannedListMiddleware]
        |
        v
[KnowledgeInjectionMiddleware]  <-- NEW: scans context for entity names,
        |                            injects matched character/setting data
        v
[SkillEnforcementMiddleware]    <-- NEW: injects active skill constraints
        |
        v
[UserContentMiddleware / EditorOperationMiddleware]
        |
        v
OpenAIAdapter.createStream(messages)
        |
        v
Streaming response -> Post-processing (anti-AI-scent) -> Display

--- Skill System ---

User describes world concept
        |
        v
SkillGenerationService.buildPrompt(concept)
        |
        v
OpenAIAdapter.createStream() -> streaming structured document
        |
        v
Parse into SkillDocument entity -> Save to Hive
        |
        v
User activates skill -> SkillEnforcementMiddleware reads active skills
        |
        v
DeviationDetectionService: compare new text against skill rules
        |
        v
Flag contradictions as inline warnings
```

### Recommended Project Structure

```
lib/features/knowledge/
├── domain/
│   ├── character_card.dart          # Character entity (name, personality, appearance, backstory, aliases)
│   ├── world_setting.dart           # World setting entity (rules, factions, geography, tech level)
│   ├── skill_document.dart          # Skill/world-building document entity
│   ├── knowledge_entity.dart        # Abstract base for searchable entities
│   └── entity_match.dart            # Value object: matched entity + relevance score
├── application/
│   ├── knowledge_repository.dart    # Abstract interface for knowledge persistence
│   ├── character_card_notifier.dart # Riverpod AsyncNotifier for character CRUD
│   ├── world_setting_notifier.dart  # Riverpod AsyncNotifier for world setting CRUD
│   ├── skill_notifier.dart          # Riverpod AsyncNotifier for skill management
│   ├── name_index_service.dart      # Builds and queries the entity name index
│   ├── knowledge_injection_middleware.dart  # PromptPipeline middleware
│   ├── skill_enforcement_middleware.dart    # PromptPipeline middleware
│   ├── skill_generation_service.dart       # AI-assisted skill document generation
│   └── deviation_detection_service.dart    # AI-based contradiction checking
├── infrastructure/
│   ├── character_card_repository.dart  # Hive-backed implementation
│   ├── world_setting_repository.dart   # Hive-backed implementation
│   ├── skill_repository.dart           # Hive-backed implementation
│   └── name_index.dart                 # Trie-based name index implementation
└── presentation/
    ├── knowledge_base_page.dart         # Main knowledge base list page
    ├── character_card_form.dart         # Create/edit character card
    ├── world_setting_form.dart          # Create/edit world setting
    ├── skill_list_page.dart             # Skill management page
    ├── skill_generation_wizard.dart     # AI-assisted skill creation wizard
    ├── skill_activation_toggle.dart     # Multi-skill activation UI
    ├── quick_insert_dialog.dart         # Keyboard shortcut dialog
    └── deviation_warning_widget.dart    # Inline deviation warning
```

### Pattern 1: Knowledge Entity Domain Model

**What:** Immutable domain entities for character cards and world settings, following the existing Fragment/AIProvider pattern.

**When to use:** All knowledge base data structures.

**Example:**
```dart
// Following existing patterns from Fragment and AIProvider
class CharacterCard {
  final String id;
  final String name;
  final String personality;
  final String appearance;
  final String backstory;
  final List<String> aliases;  // Alternative names for matching
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CharacterCard({
    required this.id,
    required this.name,
    required this.personality,
    required this.appearance,
    required this.backstory,
    this.aliases = const [],
    required this.createdAt,
    this.updatedAt,
  });

  CharacterCard copyWith({String? id, String? name, ...}) => CharacterCard(...);

  factory CharacterCard.fromJson(Map<String, dynamic> json) => CharacterCard(...);
  Map<String, dynamic> toJson() => {...};

  /// All searchable names: primary name + aliases
  List<String> get allNames => [name, ...aliases];
}
```

### Pattern 2: Hive Repository Pattern

**What:** Repository classes that wrap a Hive Box with CRUD operations, matching the existing FragmentRepository and ProviderRepository patterns.

**When to use:** All knowledge base persistence.

**Example:**
```dart
// Following existing patterns from FragmentRepository
class CharacterCardRepository {
  final Box<dynamic> _box;
  final _uuid = const Uuid();

  CharacterCardRepository(this._box);

  Future<CharacterCard> add(CharacterCard card) async {
    await _box.put(card.id, card.toJson());
    return card;
  }

  List<CharacterCard> getAll() {
    return _box.values
        .map((json) => CharacterCard.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> delete(String id) => _box.delete(id);
  Future<void> update(CharacterCard card) => _box.put(card.id, card.toJson());
  CharacterCard? getById(String id) { ... }
}
```

### Pattern 3: Name-Index Entity Matching

**What:** A lightweight in-memory index that maps entity names (and aliases) to their entity IDs for fast lookup during text scanning.

**When to use:** Auto-injection of knowledge context into AI prompts.

**Design:** The index is rebuilt from the Hive box on app start and updated on entity CRUD operations. It uses a simple Map<String, List<String>> structure where keys are name strings (normalized to lowercase for ASCII, unchanged for CJK) and values are lists of entity IDs. For Chinese text scanning, it performs substring matching against the known name dictionary.

```dart
class NameIndex {
  // name -> list of entity IDs
  final Map<String, List<String>> _nameToIds = {};
  // id -> entity type (character/setting/skill)
  final Map<String, EntityType> _idToType = {};

  void addEntity(String id, EntityType type, List<String> names) {
    _idToType[id] = type;
    for (final name in names) {
      _nameToIds.putIfAbsent(name, () => []).add(id);
    }
  }

  /// Scans text for known entity names, returns matched entity IDs with positions.
  List<EntityMatch> findMatches(String text) {
    final matches = <EntityMatch>[];
    for (final entry in _nameToIds.entries) {
      final name = entry.key;
      int startIndex = 0;
      while (true) {
        final index = text.indexOf(name, startIndex);
        if (index == -1) break;
        matches.add(EntityMatch(
          entityId: entry.value.first,
          entityName: name,
          position: index,
          length: name.length,
        ));
        startIndex = index + name.length;
      }
    }
    return matches..sort((a, b) => a.position.compareTo(b.position));
  }
}
```

### Pattern 4: PromptPipeline Middleware Extension

**What:** New middlewares that inject knowledge base context and skill constraints into the AI prompt, following the existing middleware pattern.

**When to use:** Every AI call that should be knowledge-aware.

**Example:**
```dart
// Following existing ContextAnchorMiddleware pattern
class KnowledgeInjectionMiddleware extends PromptMiddleware {
  final NameIndex _nameIndex;
  final KnowledgeRepository _repository;

  const KnowledgeInjectionMiddleware(this._nameIndex, this._repository);

  @override
  PromptContext apply(PromptContext context) {
    // Collect all text to scan (selected text + fragments + anchors)
    final scanText = _buildScanText(context);
    if (scanText.isEmpty) return context;

    // Find matching entities
    final matches = _nameIndex.findMatches(scanText);
    if (matches.isEmpty) return context;

    // Deduplicate and limit to most relevant entities
    final uniqueIds = matches.map((m) => m.entityId).toSet().take(5);
    final entities = uniqueIds
        .map((id) => _repository.getById(id))
        .whereType<KnowledgeEntity>()
        .toList();

    // Build injection text
    final buffer = StringBuffer();
    buffer.write('\n\n以下是与当前内容相关的角色和设定信息，请在创作时参考：');
    for (final entity in entities) {
      buffer.write('\n\n【${entity.displayName}】\n${entity.toContextString()}');
    }

    // Append to system message
    if (context.messages.isEmpty) {
      return context.addMessage(ChatMessage.system(buffer.toString()));
    }
    final systemContent = _extractContent(context.messages[0]);
    return context.replaceSystemMessage(0, systemContent + buffer.toString());
  }
}
```

### Pattern 5: Skill System Design

**What:** Skill documents represent structured world-building templates that can be generated by AI and enforced during writing.

**Document structure:**
```dart
class SkillDocument {
  final String id;
  final String name;           // e.g., "修仙体系"
  final String description;    // User's original concept description
  final String content;        // Full structured document (markdown)
  final SkillSections sections; // Parsed structured sections
  final bool isActive;         // Whether currently enforced
  final DateTime createdAt;

  // ...
}

class SkillSections {
  final String? powerHierarchy;    // 力量等级体系
  final String? factionRelations;  // 门派/势力关系
  final String? rules;             // 世界规则
  final String? taboos;            // 禁忌/限制
  final String? terminology;       // 专用术语
  final String? rawContent;        // Unstructured fallback
}
```

**Generation flow:** User provides a concept description -> build a structured prompt asking AI to generate sections -> stream response -> parse into SkillSections -> save to Hive.

**Enforcement flow:** Active skills' rules/terminology/taboo sections are injected into the system prompt via `SkillEnforcementMiddleware`, telling the AI to write within those constraints.

### Anti-Patterns to Avoid

- **Storing knowledge entities as free-text blobs:** Use structured fields (name, personality, etc.) so the name index and injection middleware can extract specific data. Free-text blobs cannot be queried efficiently.
- **Scanning entire editor document for entity names on every keystroke:** Debounce the scan and only scan the visible/recent portion, or scan only when an AI operation is triggered. Real-time scanning of 300K+ character documents is wasteful.
- **Injecting all knowledge base entities into every prompt:** Use the name index to inject only entities mentioned in the current context. Injecting everything wastes tokens and dilutes relevance.
- **One-click skill generation from minimal input:** Per project anti-AI-scent philosophy, the skill generation wizard should be a multi-step interactive process, not a single button press.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Chinese word segmentation | Custom jieba-like tokenizer | Dictionary-based name matching against known entity names | We control the vocabulary; no need for general-purpose segmentation. Dictionary matching is deterministic and fast. |
| JSON serialization | Manual toJson/fromJson | json_annotation + json_serializable (code gen) | Already in use for other entities, reduces boilerplate |
| Hive TypeAdapter | Auto-generated @GenerateAdapters | Manual TypeAdapter delegating to fromJson/toJson | Matches existing project pattern (FragmentAdapter, AppSettingsAdapter) |
| Trie data structure for name lookup | Custom trie implementation | Simple Map<String, List<String>> with substring matching | The dictionary size is small (tens of entities), making a trie overkill. Substring matching is O(n*m) but n is small. |
| AI prompt template management | String concatenation scattered across code | Structured prompt building via middleware | PromptPipeline middleware pattern is already established and composable |

**Key insight:** The knowledge base vocabulary is small and user-controlled (not a general-purpose NLP problem). A simple dictionary-based approach with substring matching is sufficient and much more maintainable than integrating external Chinese NLP libraries.

## Common Pitfalls

### Pitfall 1: Name Matching False Positives in Chinese
**What goes wrong:** Short Chinese names (2 characters like "李白") match common words or unrelated text fragments, causing irrelevant knowledge injection.
**Why it happens:** Chinese has no word boundaries, and 2-character strings are extremely common.
**How to avoid:** Require minimum 2-character names, prioritize longer matches, and use alias disambiguation. For very common names, require the user to add a distinguishing alias (e.g., "剑仙李白" instead of just "李白"). Score matches by name length (longer = more confident).
**Warning signs:** User reports AI injecting irrelevant character context.

### Pitfall 2: Token Budget Exhaustion from Large Knowledge Bases
**What goes wrong:** Users create many characters and settings; the knowledge injection middleware fills the context window, leaving no room for the actual content.
**Why it happens:** No budget management in the injection middleware.
**How to avoid:** Use the existing TokenBudgetCalculator to allocate a knowledge budget (e.g., 30% of available tokens). Limit injection to the top N most relevant entities (by match count and recency). Truncate long entity descriptions to fit budget.
**Warning signs:** AI responses become incoherent or truncated.

### Pitfall 3: Stale Name Index After CRUD Operations
**What goes wrong:** User adds/edits/deletes a character, but the name index still references old data, causing missed matches or matches to deleted entities.
**Why it happens:** The name index is not updated when entities change.
**How to avoid:** Update the name index in the same Riverpod notifier that handles CRUD. The index should be a derived state from the repository, refreshed on every mutation.
**Warning signs:** New character names not being auto-injected, deleted characters still appearing in AI context.

### Pitfall 4: Skill Document Parsing Fragility
**What goes wrong:** AI-generated skill documents have inconsistent structure, making section parsing fail silently.
**Why it happens:** LLM output is non-deterministic; section headers may vary.
**How to avoid:** Use a robust parsing strategy: try structured JSON output first (ask AI to return JSON), fall back to markdown heading-based parsing, and finally fall back to storing the entire document as raw content. Always preserve the raw content regardless of parsing success.
**Warning signs:** Skill sections appearing empty despite AI having generated content.

### Pitfall 5: Deviation Detection Producing Too Many False Alerts
**What goes wrong:** Every minor writing choice triggers a "contradiction" warning, annoying the user.
**Why it happens:** Overly strict enforcement rules in the deviation detection prompt.
**How to avoid:** Make deviation detection advisory, not blocking. Only flag clear contradictions (e.g., character dies in chapter 3 but appears alive in chapter 5), not stylistic choices. Use a confidence threshold -- only show warnings above a certain certainty level.
**Warning signs:** Users ignoring deviation warnings, disabling the feature.

## Code Examples

### Hive TypeAdapter Registration Pattern

```dart
// Source: lib/core/infrastructure/hive_adapters.dart (existing pattern)
// Add new type IDs to HiveTypeIds:
abstract class HiveTypeIds {
  static const int fragment = 0;
  static const int appSettings = 1;
  static const int manuscript = 2;
  static const int characterCard = 3;      // NEW
  static const int worldSetting = 4;       // NEW
  static const int skillDocument = 5;      // NEW
}

// Manual TypeAdapter delegating to fromJson/toJson:
class CharacterCardAdapter extends TypeAdapter<CharacterCard> {
  @override
  final int typeId = HiveTypeIds.characterCard;

  @override
  CharacterCard read(BinaryReader reader) {
    final json = reader.readMap() as Map<String, dynamic>;
    return CharacterCard.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, CharacterCard obj) {
    writer.writeMap(obj.toJson());
  }
}
```

### Riverpod Provider Registration Pattern

```dart
// Source: lib/core/presentation/providers.dart (existing pattern)
// Add to providers.dart:

final characterCardRepositoryProvider =
    FutureProvider<CharacterCardRepository>((ref) async {
  final box = await Hive.openBox<dynamic>('character_cards');
  return CharacterCardRepository(box);
});

final worldSettingRepositoryProvider =
    FutureProvider<WorldSettingRepository>((ref) async {
  final box = await Hive.openBox<dynamic>('world_settings');
  return WorldSettingRepository(box);
});

final skillRepositoryProvider =
    FutureProvider<SkillRepository>((ref) async {
  final box = await Hive.openBox<dynamic>('skill_documents');
  return SkillRepository(box);
});

/// Name index rebuilt from all repositories on changes.
final nameIndexProvider = FutureProvider<NameIndex>((ref) async {
  final charRepo = await ref.watch(characterCardRepositoryProvider.future);
  final settingRepo = await ref.watch(worldSettingRepositoryProvider.future);
  final index = NameIndex();
  for (final card in charRepo.getAll()) {
    index.addEntity(card.id, EntityType.character, card.allNames);
  }
  for (final setting in settingRepo.getAll()) {
    index.addEntity(setting.id, EntityType.setting, [setting.name, ...setting.aliases]);
  }
  return index;
});
```

### super_editor Keyboard Action for Quick Insert (Ctrl+K)

```dart
// Source: super_editor DocumentKeyboardAction pattern
// https://github.com/superlistapp/super_editor
ExecutionInstruction quickInsertKnowledgeAction({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  // Only handle Ctrl+K (or Cmd+K on macOS)
  if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
    return ExecutionInstruction.continueExecution;
  }
  if (keyEvent.logicalKey != LogicalKeyboardKey.keyK) {
    return ExecutionInstruction.continueExecution;
  }
  if (!keyEvent.isPrimaryShortcutKeyPressed) {
    return ExecutionContext.continueExecution;
  }

  // Trigger quick-insert dialog via a callback or state management
  // This will show a search dialog over the editor
  return ExecutionInstruction.haltExecution;
}

// Register in EditorPage's SuperEditor widget:
SuperEditor(
  keyboardActions: [
    quickInsertKnowledgeAction,  // Check first
    ...defaultKeyboardActions,
  ],
)
```

### Knowledge Injection Middleware

```dart
// Following existing ContextAnchorMiddleware pattern
class KnowledgeInjectionMiddleware extends PromptMiddleware {
  final NameIndex _nameIndex;
  final CharacterCardRepository _charRepo;
  final WorldSettingRepository _settingRepo;
  final TokenBudgetCalculator _budgetCalc;

  const KnowledgeInjectionMiddleware(
    this._nameIndex, this._charRepo, this._settingRepo, this._budgetCalc);

  @override
  PromptContext apply(PromptContext context) {
    final scanText = _collectScanText(context);
    if (scanText.isEmpty) return context;

    final matches = _nameIndex.findMatches(scanText);
    if (matches.isEmpty) return context;

    // Deduplicate by entity ID, sort by match count (most relevant first)
    final matchCounts = <String, int>{};
    for (final match in matches) {
      matchCounts[match.entityId] = (matchCounts[match.entityId] ?? 0) + 1;
    }
    final sortedIds = matchCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Build context within token budget (30% of available)
    final knowledgeBudget = (context.tokenBudget * 0.3).toInt();
    final buffer = StringBuffer();
    buffer.write('\n\n以下是与当前内容相关的角色和设定信息，请在创作时参考：');
    var usedTokens = 0;

    for (final entry in sortedIds) {
      final entity = _findEntity(entry.key);
      if (entity == null) continue;

      final entityText = '\n\n【${entity.displayName}】\n${entity.toContextString()}';
      final entityTokens = _budgetCalc.estimateTokens(entityText);
      if (usedTokens + entityTokens > knowledgeBudget) break;

      buffer.write(entityText);
      usedTokens += entityTokens;
    }

    if (usedTokens == 0) return context;

    if (context.messages.isEmpty) {
      return context.addMessage(ChatMessage.system(buffer.toString()));
    }
    final systemContent = _extractContent(context.messages[0]);
    return context.replaceSystemMessage(0, systemContent + buffer.toString());
  }

  /// Collects text from all sources for entity name scanning.
  String _collectScanText(PromptContext context) {
    final parts = <String>[];
    if (context.selectedText != null) parts.add(context.selectedText!);
    for (final fragment in context.fragments) {
      parts.add(fragment.text);
    }
    if (context.anchors != null) {
      for (final anchor in context.anchors!) {
        parts.add(anchor.text);
      }
    }
    return parts.join('\n');
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual context copy-paste | Auto-injection via PromptPipeline middleware | Phase 4 (this phase) | Zero-effort knowledge context in every AI call |
| Static world-building notes | AI-assisted skill document generation | Phase 4 (this phase) | Structured, enforceable world-building documents |
| Manual consistency checking | AI-powered deviation detection | Phase 4 (this phase) | Real-time contradiction flagging |
| No entity indexing | Name-index based entity matching | Phase 4 (this phase) | Fast, deterministic entity lookup in Chinese text |

## Assumptions Log

> All claims in this research are either verified against the existing codebase or based on well-established patterns from the codebase itself. No external package recommendations require user confirmation.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Chinese name matching via simple substring search against a small dictionary (tens of entities) is performant enough for real-time use | Pattern 3 | If dictionary grows to hundreds of entities, may need optimization (trie). Low risk for v1. |
| A2 | 30% of token budget is a reasonable allocation for knowledge injection | Pitfall 2 | May need tuning based on real-world usage. Can be made configurable. |
| A3 | Top 5 entities by match count is a reasonable limit for injection | Pattern 4 | May need adjustment based on token budget and entity size. |
| A4 | AI-generated skill documents can be reliably parsed from markdown headings | Pattern 5 | Fallback to raw content storage mitigates this risk. |

## Open Questions

1. **Should knowledge injection be configurable per-project or global?**
   - What we know: The knowledge base is per-project (each story has its own characters/settings).
   - What's unclear: Whether the user should be able to disable auto-injection globally or per-operation.
   - Recommendation: Default enabled, with a per-operation toggle in the floating toolbar (add a "inject knowledge" checkbox).

2. **How should the quick-insert dialog present search results?**
   - What we know: Ctrl+K opens a dialog, user types to search entities.
   - What's unclear: Whether to insert the entity's full description or just a reference marker.
   - Recommendation: Insert a structured reference (e.g., `{{角色:李白}}`) that the knowledge injection middleware can resolve, rather than pasting full text into the editor.

3. **Should deviation detection run in real-time or on-demand?**
   - What we know: SKIL-04 requires AI to flag contradictions.
   - What's unclear: Whether to check every keystroke (expensive) or only when the user explicitly requests it.
   - Recommendation: On-demand only (triggered by a button or after AI operations). Real-time checking would be too expensive and distracting.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All features | Yes | 3.44.0 stable | -- |
| Dart SDK | All features | Yes | 3.12.0 stable | -- |
| Hive CE | Knowledge persistence | Yes | ^2.19.3 | -- |
| flutter_riverpod | State management | Yes | ^3.3.1 | -- |
| openai_dart | AI generation | Yes | ^6.0.0 | -- |
| super_editor | Keyboard shortcuts | Yes | 0.3.0-dev.20 | -- |
| build_runner | Code generation | Yes | ^2.15.0 | -- |
| flutter_test | Testing | Yes | SDK | -- |

**Missing dependencies with no fallback:** none
**Missing dependencies with fallback:** none

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK) |
| Config file | analysis_options.yaml |
| Quick run command | `flutter test test/features/knowledge/` |
| Full suite command | `flutter test` |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| KNOW-01 | Character card CRUD with Hive persistence | unit | `flutter test test/features/knowledge/domain/character_card_test.dart` | No (Wave 0) |
| KNOW-02 | World setting CRUD with Hive persistence | unit | `flutter test test/features/knowledge/domain/world_setting_test.dart` | No (Wave 0) |
| KNOW-03 | AI auto-injects relevant context | unit | `flutter test test/features/knowledge/application/knowledge_injection_middleware_test.dart` | No (Wave 0) |
| KNOW-04 | Name-index entity matching | unit | `flutter test test/features/knowledge/infrastructure/name_index_test.dart` | No (Wave 0) |
| KNOW-05 | Quick-insert keyboard shortcut | unit | `flutter test test/features/knowledge/presentation/quick_insert_test.dart` | No (Wave 0) |
| SKIL-01 | AI-assisted skill generation | unit | `flutter test test/features/knowledge/application/skill_generation_service_test.dart` | No (Wave 0) |
| SKIL-02 | Skill document structure | unit | `flutter test test/features/knowledge/domain/skill_document_test.dart` | No (Wave 0) |
| SKIL-03 | Skill enforcement middleware | unit | `flutter test test/features/knowledge/application/skill_enforcement_middleware_test.dart` | No (Wave 0) |
| SKIL-04 | Deviation detection | unit | `flutter test test/features/knowledge/application/deviation_detection_service_test.dart` | No (Wave 0) |
| SKIL-05 | Multi-skill activation | unit | `flutter test test/features/knowledge/application/skill_notifier_test.dart` | No (Wave 0) |

### Sampling Rate

- **Per task commit:** `flutter test test/features/knowledge/`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/features/knowledge/domain/character_card_test.dart` -- covers KNOW-01
- [ ] `test/features/knowledge/domain/world_setting_test.dart` -- covers KNOW-02
- [ ] `test/features/knowledge/domain/skill_document_test.dart` -- covers SKIL-02
- [ ] `test/features/knowledge/infrastructure/name_index_test.dart` -- covers KNOW-04
- [ ] `test/features/knowledge/application/knowledge_injection_middleware_test.dart` -- covers KNOW-03
- [ ] `test/features/knowledge/application/skill_enforcement_middleware_test.dart` -- covers SKIL-03
- [ ] `test/features/knowledge/application/skill_generation_service_test.dart` -- covers SKIL-01
- [ ] `test/features/knowledge/application/deviation_detection_service_test.dart` -- covers SKIL-04
- [ ] `test/features/knowledge/application/skill_notifier_test.dart` -- covers SKIL-05
- [ ] `test/features/knowledge/application/character_card_notifier_test.dart` -- covers KNOW-01
- [ ] `test/features/knowledge/application/world_setting_notifier_test.dart` -- covers KNOW-02
- [ ] `test/features/knowledge/presentation/quick_insert_test.dart` -- covers KNOW-05

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No user accounts in local-first app |
| V3 Session Management | no | No sessions |
| V4 Access Control | no | Single-user local app |
| V5 Input Validation | yes | Validate entity names (length, characters), sanitize AI-generated content before storage |
| V6 Cryptography | no | Knowledge data is not sensitive (API keys already handled by flutter_secure_storage) |

### Known Threat Patterns for Local Knowledge Storage

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Oversized entity data exhausting disk | Denial of Service | Limit entity field lengths (name: 100 chars, description: 10000 chars) |
| Malicious AI-generated content in skill documents | Tampering | Sanitize/validate AI output before Hive storage; display raw content for user review |
| Name injection via aliases | Tampering | Validate alias format (no control characters, reasonable length) |

## Sources

### Primary (HIGH confidence)
- Existing codebase: `lib/features/ai/application/prompt_pipeline.dart` -- PromptPipeline middleware pattern
- Existing codebase: `lib/features/editor/application/context_anchor_middleware.dart` -- Knowledge injection middleware pattern
- Existing codebase: `lib/core/infrastructure/hive_adapters.dart` -- Hive TypeAdapter pattern
- Existing codebase: `lib/core/infrastructure/fragment_repository.dart` -- Repository pattern
- Existing codebase: `lib/core/presentation/providers.dart` -- Riverpod provider pattern
- Existing codebase: `lib/features/editor/presentation/editor_page.dart` -- super_editor keyboard shortcut pattern
- super_editor source: `DocumentKeyboardAction` chain-of-responsibility pattern with `ExecutionInstruction` return type

### Secondary (MEDIUM confidence)
- pub.dev: hive_ce 2.19.3 verified current
- pub.dev: flutter_riverpod 3.3.1 verified current

### Tertiary (LOW confidence)
- Chinese name matching approach: based on training knowledge of Chinese text processing. The dictionary-based substring approach is well-understood but specific performance characteristics at scale are untested in this context.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all packages already installed and verified in codebase
- Architecture: HIGH -- follows established patterns from Phase 1-3
- Pitfalls: MEDIUM -- Chinese name matching false positives and token budget management are areas where real-world testing will be needed

**Research date:** 2026-06-02
**Valid until:** 2026-07-02 (30 days -- stable phase building on established patterns)
