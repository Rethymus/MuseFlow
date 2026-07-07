/// Real-API validation for the editor AI operation path.
///
/// The editor AI notifier (润色 / 改写 / free-input) is the product's primary
/// author interaction surface and the path through which the anti-AI-scent
/// post-processor runs on real model output — yet it had ZERO real-API
/// coverage (only a canned `_FakeOpenAIAdapter`). The synthesis path has
/// `fragment_synthesis_test`; the manuscript path has chapter-summarization
/// tests; the editor path alone was unvalidated against real GLM behavior.
///
/// This env-gated test builds a paragraph-polish prompt via the real
/// [EditorPromptPipeline] (the full 12-middleware editor stack), streams a
/// real GLM-4-flash completion, and asserts the editor prompt is *effective*
/// (non-empty, actually polishes rather than echoing, preserves meaning) and
/// that the anti-AI-scent post-processor handles real model output without
/// crashing — closing the editor AI path's real-API gap (gap-analysis Phase
/// 25, previously ❌ "needs external key", now unblocked by the GLM key).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/application/anti_ai_scent_processor.dart';
import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/ai/domain/ai_exception.dart';
import 'package:museflow/features/editor/application/editor_prompt_pipeline.dart';
import 'package:museflow/features/editor/domain/editor_ai_state.dart';
import 'package:openai_dart/openai_dart.dart';

import '../../../journey/helpers/journey_container.dart';

void main() {
  final apiKey = Platform.environment['GLM_API_KEY'];
  final baseUrl =
      Platform.environment['GLM_BASE_URL'] ??
      'https://open.bigmodel.cn/api/paas/v4';
  final model = Platform.environment['GLM_MODEL'] ?? 'glm-4-flash';

  // A deliberately flat, AI-scented paragraph (short uniform sentences) that
  // a polish operation should meaningfully improve — so "output != input" is a
  // real signal the editor prompt is effective, not a trivial diff.
  const sampleText =
      '林风站在青云峰上，看着远方的云。他想着修炼的事情。'
      '风吹过他的脸。他觉得很平静。天空很蓝。';

  group('Editor AI polish (Real GLM API)', () {
    test(
      'EditorPromptPipeline polish produces effective, meaning-preserving output',
      () async {
        final container = await createJourneyContainer(
          apiKey: apiKey!,
          baseUrl: baseUrl,
          model: model,
        );
        addTearDown(() => cleanupJourneyContainer(container));

        // Build the editor polish prompt via the REAL 12-middleware pipeline
        // (persona / few-shot / banned-list / contrastive-subtraction /
        // context-anchor / chapter-context / editor-operation / user-content).
        final pipeline = EditorPromptPipeline();
        final context = PromptContext(
          fragments: const [],
          selectedText: sampleText,
          selectedOperation: EditorAIOperation.paragraphPolish,
          bannedPhrases: const [],
        );
        final messages = pipeline.build(context);

        // The pipeline must assemble a multi-message prompt (system + user at
        // minimum); a single-message result would mean a middleware dropped.
        expect(
          messages.length,
          greaterThanOrEqualTo(2),
          reason: 'EditorPromptPipeline should emit system + user messages',
        );

        final adapter = container.read(openaiAdapterProvider);
        final provider = container.read(activeProviderProvider)!;
        final key = container.read(activeApiKeyProvider)!;

        Usage? capturedUsage;
        final buffer = StringBuffer();

        try {
          final stream = adapter.createStream(
            apiKey: key,
            baseUrl: provider.baseUrl,
            model: provider.model,
            messages: messages,
            onUsage: (usage) {
              capturedUsage = usage;
            },
          );
          await for (final chunk in stream) {
            buffer.write(chunk);
          }
        } on AIException catch (e) {
          // ignore: avoid_print
          print('[STREAM_ERROR] $e');
          rethrow;
        }

        final output = buffer.toString().trim();
        // ignore: avoid_print
        print(
          '[POLISH] in=${sampleText.length}chars out=${output.length}chars',
        );
        // ignore: avoid_print
        print('[POLISH] output: $output');

        // 1. Non-empty, substantive output.
        expect(output, isNotEmpty);
        expect(
          output.length,
          greaterThan(20),
          reason: 'Polish output should be substantive',
        );

        // 2. The polish actually changed the text (not an echo). A real polish
        //    of flat prose restructures it; an identical return would indicate
        //    the operation instruction was ignored.
        expect(
          output,
          isNot(equals(sampleText)),
          reason: 'Polish should transform the text, not echo it',
        );

        // 3. Meaning preserved — the protagonist name survives the rewrite.
        //    A polish that drops the subject has failed its core contract.
        expect(
          output,
          contains('林风'),
          reason: 'Polish should preserve the protagonist reference',
        );

        // 4. Token usage captured (the editor audits every op for cost
        //    transparency; the onUsage path must fire on real completions).
        expect(
          capturedUsage,
          isNotNull,
          reason: 'onUsage callback should fire for real GLM completion',
        );

        // 5. The anti-AI-scent post-processor (which the editor runs on every
        //    output) must handle real model output without crashing — its
        //    review-signals list must be well-formed regardless of content.
        final processor = AntiAIScentProcessor();
        final scentResult = processor.process(output, bannedPhrases: const []);
        expect(
          scentResult.reviewSignals,
          isA<List>(),
          reason: 'AntiAIScentProcessor must return a well-formed signal list',
        );
      },
      skip: apiKey == null ? 'GLM_API_KEY not set' : null,
      timeout: const Timeout(Duration(seconds: 120)),
    );
  });
}
