import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/ai/application/token_budget_calculator.dart';
import 'package:museflow/features/knowledge/domain/skill_document.dart';
import 'package:museflow/features/knowledge/infrastructure/skill_repository.dart';
import 'package:openai_dart/openai_dart.dart';

/// Injects active skill constraints into AI prompts.
class SkillEnforcementMiddleware extends PromptMiddleware {
  final SkillRepository skillRepository;
  final TokenBudgetCalculator tokenBudgetCalculator;

  SkillEnforcementMiddleware({
    required this.skillRepository,
    required this.tokenBudgetCalculator,
  });

  @override
  PromptContext apply(PromptContext context) {
    final activeSkills = skillRepository.getActive();
    if (activeSkills.isEmpty) return context;

    final budget = (context.tokenBudget * 0.2).floor();
    var used = 0;
    final buffer = StringBuffer('以下是当前激活的世界观设定约束，请严格遵守：');

    for (final skill in activeSkills) {
      final text = _constraintText(skill);
      if (text.isEmpty) continue;
      final tokens = tokenBudgetCalculator.estimateTokens(text);
      if (used + tokens > budget) break;
      used += tokens;
      buffer.write('\n\n【${skill.name}】\n$text');
    }

    if (used == 0) return context;
    final injection = buffer.toString();
    final systemIndex = _firstSystemMessageIndex(context.messages);
    if (systemIndex == null) {
      return context.addMessage(ChatMessage.system(injection));
    }
    final existing = _messageContent(context.messages[systemIndex]);
    return context.replaceSystemMessage(systemIndex, '$existing\n\n$injection');
  }

  String _constraintText(SkillDocument skill) {
    final buffer = StringBuffer();
    void add(String title, String? value) {
      if (value == null || value.trim().isEmpty) return;
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln('## $title');
      buffer.writeln(value.trim());
    }

    add('世界规则', skill.sections.rules);
    add('禁忌/限制', skill.sections.taboos);
    add('专用术语', skill.sections.terminology);
    return buffer.toString().trim();
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
