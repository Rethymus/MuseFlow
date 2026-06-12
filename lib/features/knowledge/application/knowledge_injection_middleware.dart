import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/ai/application/token_budget_calculator.dart';
import 'package:museflow/features/knowledge/domain/entity_match.dart';
import 'package:museflow/features/knowledge/domain/entity_type.dart';
import 'package:museflow/features/knowledge/domain/knowledge_entity.dart';
import 'package:museflow/features/knowledge/infrastructure/character_card_repository.dart';
import 'package:museflow/features/knowledge/infrastructure/character_relationship_repository.dart';
import 'package:museflow/features/knowledge/infrastructure/fuzzy_matcher.dart';
import 'package:museflow/features/knowledge/infrastructure/name_index.dart';
import 'package:museflow/features/knowledge/infrastructure/pronoun_resolver.dart';
import 'package:museflow/features/knowledge/infrastructure/world_setting_repository.dart';
import 'package:openai_dart/openai_dart.dart';

/// Prompt middleware that auto-injects matching character/setting context.
///
/// Supports three matching strategies:
/// 1. **Exact match** via [NameIndex] (original, fastest)
/// 2. **Fuzzy match** via [FuzzyMatcher] (handles typos, edit distance ≤ 2)
/// 3. **Pronoun resolution** via [PronounResolver] (他/她 → character)
///
/// Results are merged and deduplicated, then sorted by match quality
/// (exact > fuzzy > pronoun) before injection within token budget.
class KnowledgeInjectionMiddleware extends PromptMiddleware {
  final NameIndex nameIndex;
  final CharacterCardRepository characterRepository;
  final WorldSettingRepository worldSettingRepository;
  final TokenBudgetCalculator tokenBudgetCalculator;

  /// Optional repository for character relationship injection.
  /// Per Phase 21 (KNOW-02): When available, injects relationship context
  /// for matched characters into AI prompts.
  final CharacterRelationshipRepository? relationshipRepository;

  /// Optional fuzzy matcher for typo-tolerant matching.
  /// When null, fuzzy matching is disabled.
  final FuzzyMatcher? fuzzyMatcher;

  /// Optional pronoun resolver for coreference resolution.
  /// When null, pronoun resolution is disabled.
  final PronounResolver? pronounResolver;

  KnowledgeInjectionMiddleware({
    required this.nameIndex,
    required this.characterRepository,
    required this.worldSettingRepository,
    required this.tokenBudgetCalculator,
    this.relationshipRepository,
    this.fuzzyMatcher,
    this.pronounResolver,
  });

  @override
  PromptContext apply(PromptContext context) {
    final scanText = _collectScanText(context);
    if (scanText.trim().isEmpty) return context;

    // Phase 1: Exact matches via NameIndex
    final exactMatches = nameIndex.findMatches(scanText);

    // Phase 2: Fuzzy matches via FuzzyMatcher (if available)
    final fuzzyMatches = <EntityMatch>[];
    if (fuzzyMatcher != null && nameIndex.allEntityIds.isNotEmpty) {
      final allNames = _collectAllNames();
      if (allNames.isNotEmpty) {
        final fuzzyResults = fuzzyMatcher!.findFuzzyMatches(
          text: scanText,
          candidates: allNames,
        );
        for (final fr in fuzzyResults) {
          // Find entity ID for the matched candidate name
          final id = _findEntityIdByName(fr.candidate);
          if (id == null) continue;
          final type = nameIndex.typeOf(id);
          if (type == null) continue;

          // Skip if already found by exact match at same position
          final isDuplicate = exactMatches.any(
            (m) => m.entityId == id && m.position == fr.position,
          );
          if (!isDuplicate) {
            fuzzyMatches.add(EntityMatch(
              entityId: id,
              entityType: type,
              entityName: fr.candidate,
              position: fr.position,
              length: fr.length,
            ));
          }
        }
      }
    }

    // Phase 3: Pronoun resolution via PronounResolver (if available)
    final pronounMatches = <EntityMatch>[];
    if (pronounResolver != null && context.characterGenders.isNotEmpty) {
      final genders = _parseGenderMap(context.characterGenders);
      if (genders.isNotEmpty) {
        final resolutions = pronounResolver!.resolveAll(
          text: scanText,
          characters: genders,
        );
        for (final r in resolutions) {
          final type = nameIndex.typeOf(r.entityId);
          if (type == null) continue;

          final isDuplicate = exactMatches.any(
            (m) => m.entityId == r.entityId,
          ) || fuzzyMatches.any(
            (m) => m.entityId == r.entityId,
          );
          if (!isDuplicate) {
            pronounMatches.add(EntityMatch(
              entityId: r.entityId,
              entityType: type,
              entityName: r.entityName,
              position: r.pronounPosition,
              length: 1,
            ));
          }
        }
      }
    }

    // Merge all matches: exact first, then fuzzy, then pronoun
    final allMatches = [
      ...exactMatches,
      ...fuzzyMatches,
      ...pronounMatches,
    ];
    if (allMatches.isEmpty) return context;

    // Count mentions per entity (higher = more relevant)
    final counts = <String, int>{};
    for (final match in allMatches) {
      counts.update(match.entityId, (v) => v + 1, ifAbsent: () => 1);
    }

    // Sort by relevance: exact matches (in counts) come first,
    // then by mention count
    final sortedIds = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

    // Build injection text within token budget
    final budget = (context.tokenBudget * 0.3).floor();
    var used = 0;
    final entityTexts = <String>[];

    for (final id in sortedIds.take(5)) {
      final entity = _loadEntity(id);
      if (entity == null) continue;
      final text = '\n\n【${entity.displayName}】\n${entity.toContextString}';
      final tokens = tokenBudgetCalculator.estimateTokens(text);
      if (used + tokens > budget) break;
      used += tokens;
      entityTexts.add(text);
    }

    if (entityTexts.isEmpty) return context;
    final injection = StringBuffer('\n\n以下是与当前内容相关的角色和设定信息，请在创作时参考：')
      ..writeAll(entityTexts);

    // Phase 21 (KNOW-02): Inject relationship context for matched characters
    if (relationshipRepository != null) {
      final matchedCharIds = sortedIds
          .take(5)
          .where((id) => nameIndex.typeOf(id) == EntityType.character)
          .toList();
      if (matchedCharIds.length >= 2) {
        final relTexts = <String>[];
        for (var i = 0; i < matchedCharIds.length && i < 3; i++) {
          for (var j = i + 1; j < matchedCharIds.length; j++) {
            final rel = relationshipRepository!.getBetween(
              matchedCharIds[i],
              matchedCharIds[j],
            );
            if (rel != null) {
              final fromName = _entityDisplayName(matchedCharIds[i]) ?? '';
              final toName = _entityDisplayName(matchedCharIds[j]) ?? '';
              final relText = '\n${rel.toContextString(fromName, toName)}';
              final tokens = tokenBudgetCalculator.estimateTokens(relText);
              if (used + tokens <= budget) {
                used += tokens;
                relTexts.add(relText);
              }
            }
          }
        }
        if (relTexts.isNotEmpty) {
          injection.write('\n\n【角色关系】');
          injection.writeAll(relTexts);
        }
      }
    }

    final systemIndex = _firstSystemMessageIndex(context.messages);
    if (systemIndex == null) {
      return context.addMessage(
        ChatMessage.system(injection.toString().trim()),
      );
    }

    final existing = _messageContent(context.messages[systemIndex]);
    return context.replaceSystemMessage(
      systemIndex,
      '$existing${injection.toString()}',
    );
  }

  /// Collects all entity names from the index for fuzzy matching.
  List<String> _collectAllNames() {
    final names = <String>[];
    for (final entry in nameIndex.allEntityIds) {
      final entity = _loadEntity(entry);
      if (entity != null) {
        names.addAll(entity.allNames);
      }
    }
    return names;
  }

  /// Finds an entity ID by any of its registered names.
  String? _findEntityIdByName(String name) {
    for (final id in nameIndex.allEntityIds) {
      final entity = _loadEntity(id);
      if (entity != null && entity.allNames.contains(name)) {
        return id;
      }
    }
    return null;
  }

  /// Parses the characterGenders map from dynamic to typed Gender values.
  Map<String, Gender> _parseGenderMap(Map<String, dynamic> raw) {
    final result = <String, Gender>{};
    for (final entry in raw.entries) {
      final gender = entry.value;
      if (gender is Gender) {
        result[entry.key] = gender;
      } else if (gender == 'male' || gender == Gender.male) {
        result[entry.key] = Gender.male;
      } else if (gender == 'female' || gender == Gender.female) {
        result[entry.key] = Gender.female;
      }
    }
    return result;
  }

  String _collectScanText(PromptContext context) {
    final buffer = StringBuffer();
    if (context.selectedText != null) buffer.writeln(context.selectedText);
    for (final fragment in context.fragments) {
      buffer.writeln(fragment.text);
    }
    for (final anchor in context.anchors ?? const <AnchorReference>[]) {
      buffer.writeln(anchor.text);
    }
    return buffer.toString();
  }

  KnowledgeEntity? _loadEntity(String id) {
    return switch (nameIndex.typeOf(id)) {
      EntityType.character => characterRepository.getById(id),
      EntityType.setting => worldSettingRepository.getById(id),
      EntityType.skill => null,
      null => null,
    };
  }

  int? _firstSystemMessageIndex(List<ChatMessage> messages) {
    for (var i = 0; i < messages.length; i++) {
      if (messages[i].toJson()['role'] == 'system') return i;
    }
    return null;
  }

  String _messageContent(ChatMessage message) {
    final content = message.toJson()['content'];
    return content is String ? content : '';
  }

  /// Returns the display name for an entity by ID, or null if not found.
  String? _entityDisplayName(String id) {
    final entity = _loadEntity(id);
    return entity?.displayName;
  }
}
