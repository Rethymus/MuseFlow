/// Dynamic persona middleware — replaces fixed persona with style-aware instructions.
///
/// When an [AuthorStyleProfile] is available in the [PromptContext], this
/// middleware generates a personalized style instruction based on the author's
/// measured writing dimensions, replacing the generic "自然、有温度、像人写的"
/// text from [PersonaInjectionMiddleware].
///
/// Falls back to the default persona when no style profile exists.
library;

import 'package:museflow/features/ai/application/prompt_middlewares/persona_injection_middleware.dart';
import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/editor/domain/author_style_profile.dart';
import 'package:museflow/features/editor/domain/style_dimension.dart';
import 'package:openai_dart/openai_dart.dart';

/// Dynamic persona middleware that adapts AI output style to the author.
///
/// Generates personalized style instructions from the five dimensions of an
/// [AuthorStyleProfile]. The instruction tells the AI to match the author's
/// measured sentence length, rhythm, vocabulary, rhetoric, and emotional tone.
class DynamicPersonaMiddleware extends PromptMiddleware {
  const DynamicPersonaMiddleware();

  @override
  PromptContext apply(PromptContext context) {
    final profile = context.styleProfile;

    // No profile — pass through unchanged (PersonaInjectionMiddleware
    // already applied the default fallback).
    if (profile == null || !profile.hasData) {
      return context;
    }

    // Generate dynamic persona from style dimensions
    final personaText = _buildDynamicPersona(profile);

    // Find and replace the system message
    final systemIndex = _firstSystemMessageIndex(context.messages);
    if (systemIndex == null) {
      return context.addMessage(ChatMessage.system(personaText));
    }

    // Remove the default persona text if present, replace with dynamic
    final existing = _messageContent(context.messages[systemIndex]);
    final cleaned = _removeDefaultPersona(existing);
    return context.replaceSystemMessage(systemIndex, cleaned + personaText);
  }

  /// Builds a dynamic persona instruction from the author's style profile.
  String _buildDynamicPersona(AuthorStyleProfile profile) {
    final parts = <String>[];

    parts.add('\n\n## 写作风格指令（基于作者风格分析）\n');

    // Sentence length guidance
    final stats = profile.sentenceLengthStats;
    if (stats.avg > 0) {
      final guidance = _sentenceLengthGuidance(stats);
      parts.add('- 句式：$guidance');
    }

    // Rhythm guidance
    final rhythmInterpret = StyleDimension.rhythm.interpret(
      profile.rhythmScore,
    );
    parts.add('- 节奏：$rhythmInterpret。请保持句式长短错落的变化感。');

    // Vocabulary guidance
    final vocabInterpret = StyleDimension.vocabulary.interpret(
      profile.vocabularyRichness,
    );
    parts.add('- 词汇：$vocabInterpret。请使用与作者水平相当的词汇变化。');

    // Rhetoric guidance
    final habits = profile.rhetoricHabits;
    parts.add(_rhetoricGuidance(habits));

    // Emotional tone guidance
    parts.add('- 情感基调：${profile.emotionalTone.overall}。');

    // Author vocabulary signature (naturally blend, anti keyword stuffing).
    // Injects the author's characteristic n-grams so the AI internalizes the
    // author's actual vocabulary palette rather than a generic "comparable
    // vocabulary level". Phrased as guidance — mechanical stuffing of these
    // words is itself an AI-scent tell and violates the product soul.
    if (profile.lexicalSignature.topTerms.isNotEmpty) {
      final terms = profile.lexicalSignature.topTerms
          .take(10)
          .map((t) => t.term)
          .join('、');
      parts.add('- 作者常用表达：$terms');
      parts.add('  （请在创作中自然融入作者的表达倾向，不要机械堆砌这些词）');
    }

    // Anti-AI-scent anchor
    parts.add(
      '\n**核心要求**：模仿上述风格特征，但不要让读者感到刻意。'
      '避免任何AI生成的痕迹，包括但不限于套话连接词、公式化句式、'
      '过度均衡的描写、过于完美的逻辑。',
    );

    return parts.join('\n');
  }

  /// Generates sentence length guidance from stats.
  String _sentenceLengthGuidance(SentenceLengthStats stats) {
    if (stats.avg < 12) {
      return '偏好短句（平均${stats.avg.toStringAsFixed(0)}字），节奏明快';
    } else if (stats.avg < 20) {
      return '以中等句长为主（平均${stats.avg.toStringAsFixed(0)}字），交替使用长短句';
    } else if (stats.avg < 30) {
      return '偏长句（平均${stats.avg.toStringAsFixed(0)}字），叙述从容，文风厚重';
    }
    return '长句为主（平均${stats.avg.toStringAsFixed(0)}字），叙事绵密';
  }

  /// Generates rhetoric guidance from habit ratios.
  String _rhetoricGuidance(RhetoricHabits habits) {
    final parts = <String>[];

    if (habits.dialogueRatio > 0.3) {
      parts.add('对话较多，注意保持角色的声音区分');
    }
    if (habits.descriptionRatio > 0.3) {
      parts.add('描写细腻，注意感官细节的层次');
    }
    if (habits.actionRatio > 0.2) {
      parts.add('动作描写干脆有力，动词选择精准');
    }
    if (habits.metaphorFrequency > 0.05) {
      parts.add('善用比喻修辞，但不要过度');
    }

    if (parts.isEmpty) {
      return '- 修辞：叙述为主，修辞适度';
    }

    return '- 修辞偏好：${parts.join('，')}';
  }

  /// Removes the default persona text from a system message.
  String _removeDefaultPersona(String content) {
    return content
        .replaceAll(PersonaInjectionMiddleware.personaText, '')
        .replaceAll(
          '\n\n写作风格：自然、有温度、像人写的。'
              '避免使用任何AI生成的痕迹。',
          '',
        );
  }

  int? _firstSystemMessageIndex(List messages) {
    for (var i = 0; i < messages.length; i++) {
      if (messages[i].toJson()['role'] == 'system') return i;
    }
    return null;
  }

  String _messageContent(dynamic message) {
    final content = message.toJson()['content'];
    return content is String ? content : '';
  }
}

/// Helper for creating persona messages (used when no system message exists).
class PersonaInjection {
  static String personaMessage(String text) => text;
}
