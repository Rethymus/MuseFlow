import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/ai/application/token_budget_calculator.dart';
import 'package:museflow/features/knowledge/domain/entity_type.dart';
import 'package:museflow/features/knowledge/domain/knowledge_entity.dart';
import 'package:museflow/features/knowledge/infrastructure/character_card_repository.dart';
import 'package:museflow/features/knowledge/infrastructure/name_index.dart';
import 'package:museflow/features/knowledge/infrastructure/world_setting_repository.dart';
import 'package:openai_dart/openai_dart.dart';

/// Prompt middleware that auto-injects matching character/setting context.
class KnowledgeInjectionMiddleware extends PromptMiddleware {
  final NameIndex nameIndex;
  final CharacterCardRepository characterRepository;
  final WorldSettingRepository worldSettingRepository;
  final TokenBudgetCalculator tokenBudgetCalculator;

  KnowledgeInjectionMiddleware({
    required this.nameIndex,
    required this.characterRepository,
    required this.worldSettingRepository,
    required this.tokenBudgetCalculator,
  });

  @override
  PromptContext apply(PromptContext context) {
    final scanText = _collectScanText(context);
    if (scanText.trim().isEmpty) return context;

    final matches = nameIndex.findMatches(scanText);
    if (matches.isEmpty) return context;

    final counts = <String, int>{};
    for (final match in matches) {
      counts.update(match.entityId, (value) => value + 1, ifAbsent: () => 1);
    }

    final sortedIds = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
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
    final injection = StringBuffer(
      '\n\n以下是与当前内容相关的角色和设定信息，请在创作时参考：',
    )..writeAll(entityTexts);

    final systemIndex = _firstSystemMessageIndex(context.messages);
    if (systemIndex == null) {
      return context.addMessage(ChatMessage.system(injection.toString().trim()));
    }

    final existing = _messageContent(context.messages[systemIndex]);
    return context.replaceSystemMessage(
      systemIndex,
      '$existing${injection.toString()}',
    );
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
}
