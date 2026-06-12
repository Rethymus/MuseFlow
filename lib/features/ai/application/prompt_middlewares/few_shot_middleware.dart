/// Few-shot middleware — injects author's writing samples into AI prompts.
///
/// When an [AuthorStyleProfile] with [StyleSample]s is available in the
/// [PromptContext], this middleware appends 3-5 high-quality paragraphs
/// from the author's own chapters as few-shot examples.
///
/// The samples demonstrate the author's actual voice, giving the AI a
/// concrete reference for style mimicry beyond abstract instructions.
library;

import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/editor/domain/author_style_profile.dart';
import 'package:museflow/features/editor/domain/style_dimension.dart';
import 'package:openai_dart/openai_dart.dart';

/// Injects author paragraph samples as few-shot style examples.
///
/// Per STYLE-03: AI prompts automatically include 3-5 high-quality paragraphs
/// extracted from the author's own chapters as few-shot style examples.
class FewShotMiddleware extends PromptMiddleware {
  const FewShotMiddleware();

  @override
  PromptContext apply(PromptContext context) {
    final profile = context.styleProfile;
    if (profile == null || profile.sampleParagraphs.isEmpty) {
      return context;
    }

    // Budget: use up to 15% of token budget for samples
    final maxTokens = (context.tokenBudget * 0.15).floor();
    final samples = _selectSamplesWithinBudget(profile, maxTokens);

    if (samples.isEmpty) {
      return context;
    }

    // Build few-shot injection text
    final buffer = StringBuffer();
    buffer.write('\n\n## 作者写作风格参考（请模仿以下段落的风格）\n');
    for (var i = 0; i < samples.length; i++) {
      final sample = samples[i];
      // Truncate very long samples to ~200 chars
      final displayText = sample.text.length > 200
          ? '${sample.text.substring(0, 200)}……'
          : sample.text;
      buffer.write('\n【范例${i + 1}】');
      // Add dimension highlights for the best-scoring dimensions
      final topDims = _topDimensions(sample);
      if (topDims.isNotEmpty) {
        buffer.write('（${topDims.join('、')}）');
      }
      buffer.write('\n$displayText\n');
    }
    buffer.write('\n请在创作时参考上述段落的风格特征。\n');

    // Append to system message
    final systemIndex = _firstSystemMessageIndex(context.messages);
    if (systemIndex == null) {
      return context.addMessage(ChatMessage.system(buffer.toString().trim()));
    }

    final existing = _messageContent(context.messages[systemIndex]);
    return context.replaceSystemMessage(
      systemIndex,
      '$existing${buffer.toString()}',
    );
  }

  /// Selects samples within the token budget, preferring diverse dimensions.
  ///
  /// Estimates ~1.5 tokens per CJK character.
  List<SampleSelection> _selectSamplesWithinBudget(
    AuthorStyleProfile profile,
    int maxTokens,
  ) {
    final samples = profile.sampleParagraphs;
    if (samples.isEmpty) return [];

    var usedTokens = 0;
    final selected = <SampleSelection>[];

    for (final sample in samples) {
      final estimatedTokens = (sample.text.length * 3 ~/ 2);
      if (usedTokens + estimatedTokens > maxTokens) continue;

      selected.add(SampleSelection(
        text: sample.text,
        dimensionScores: sample.dimensionScores,
      ));
      usedTokens += estimatedTokens;
    }

    return selected;
  }

  /// Returns the top 2 dimension names where this sample scores highest.
  List<String> _topDimensions(SampleSelection sample) {
    final entries = sample.dimensionScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final result = <String>[];
    for (final entry in entries.take(2)) {
      if (entry.value > 0.5) {
        result.add(entry.key.label);
      }
    }
    return result;
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

/// A sample paragraph selected for few-shot injection.
class SampleSelection {
  final String text;
  final Map<StyleDimension, double> dimensionScores;

  const SampleSelection({
    required this.text,
    required this.dimensionScores,
  });
}
