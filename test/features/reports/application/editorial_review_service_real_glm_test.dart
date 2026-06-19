/// Real-API validation for the editorial review (CritiCS) JSON parsing path.
///
/// [EditorialReviewService] makes a single LLM call requesting STRICT JSON
/// output — a 4-dimension critique (情节/人物/文笔/节奏), each with
/// score/strengths/weaknesses/suggestions — then [EditorialReview.parseFromLLM]
/// decodes it with tolerant fallback (strips ```json fences, isolates the first
/// {...}, degrades gracefully). This is the same fragile class as the
/// continuation-suggestion path: structured-JSON generation is what real LLMs
/// most often bot (markdown fences, chatty preamble, trailing prose, malformed
/// braces). The canned `editorial_review_service_test` feeds a perfectly-shaped
/// JSON string via a fake adapter, so it proves nothing about whether
/// `parseFromLLM` survives real model output.
///
/// The service is constructor-injected (no ProviderContainer needed), so this
/// env-gated test wires a REAL OpenAIAdapter against GLM-4-flash directly and
/// asserts the parser yields a non-degraded 4-dimension review from real output
/// — closing the CritiCS editorial-review path's real-API gap.
library;

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:museflow/features/reports/application/editorial_review_service.dart';
import 'package:museflow/features/reports/domain/editorial_review.dart';

void main() {
  final apiKey = Platform.environment['GLM_API_KEY'];
  final baseUrl =
      Platform.environment['GLM_BASE_URL'] ??
      'https://open.bigmodel.cn/api/paas/v4';
  final model = Platform.environment['GLM_MODEL'] ?? 'glm-4-flash';

  // A substantive 修仙 passage (~330 chars) with plot, character, prose, and
  // pacing material for all 4 review dimensions to engage with.
  const sampleChapter =
      '青云峰上，晨雾未散。林风握着那块古玉，指尖传来微微温热。自从清虚真人传他无名功法以来，'
      '丹田中的灵气日渐醇厚，可这块古玉的秘密始终困扰着他。他想起苏雪晴的告诫——这玉或许与百年前'
      '消失的天玄宗有关。山风忽起，卷动他的衣袂。远处传来一声钟鸣，是宗门召集弟子的信号。林风'
      '收起古玉，毅然向主峰奔去。他不知道，等待他的将是一场改变命运的试炼，而苏雪晴的身影，'
      '此刻正悄然出现在他身后的密林之中。';

  group('Editorial review (Real GLM API)', () {
    test(
      'CritiCS 4-dimension review survives parseFromLLM on real GLM output',
      () async {
        final adapter = OpenAIAdapter();
        addTearDown(adapter.dispose);

        final service = EditorialReviewService(
          openAIAdapter: adapter,
          apiKey: apiKey!,
          baseUrl: baseUrl,
          model: model,
        );

        final review = await service.reviewChapter(sampleChapter);

        // The tolerant parser must have survived real GLM output. A degraded
        // review means real model output (markdown fences / preamble / malformed
        // JSON) broke parseFromLLM — the exact failure mode this test exists to
        // catch. Print the degradedReason for diagnosis if it happens.
        if (review.isDegraded) {
          print('[REVIEW] DEGRADED: ${review.degradedReason}');
        }
        expect(
          review.isDegraded,
          isFalse,
          reason:
              'parseFromLLM should survive real GLM JSON output; '
              'degraded=${review.degradedReason}',
        );

        // The prompt requests exactly 4 dimensions (情节/人物/文笔/节奏).
        expect(
          review.dimensions.length,
          4,
          reason: 'Prompt requests 4 editorial dimensions',
        );

        // Every dimension must be well-formed: a valid enum, a clamped 0-100
        // score, and non-empty critique text.
        for (final d in review.dimensions) {
          expect(d.score, inInclusiveRange(0, 100));
          expect(
            d.strengths,
            isNotEmpty,
            reason: '${d.dimension.label} strengths must be non-empty',
          );
          expect(
            d.weaknesses,
            isNotEmpty,
            reason: '${d.dimension.label} weaknesses must be non-empty',
          );
          print(
            '[REVIEW] ${d.dimension.label} score=${d.score} '
            'strengths=${d.strengths.length}chars',
          );
        }

        // Overall score is the mean of dimensions — must be a valid 0-100.
        expect(review.overallScore, inInclusiveRange(0, 100));
      },
      skip: apiKey == null ? 'GLM_API_KEY not set' : null,
      timeout: const Timeout(Duration(seconds: 120)),
    );
  });
}
