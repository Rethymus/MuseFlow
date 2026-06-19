/// Real-API validation for the guided continuation-suggestion path (LFIN-03).
///
/// Distinct from the editor polish path: [ContinuationSuggestionNotifier]
/// builds its OWN prompt (not the EditorPromptPipeline) requesting
/// STRICT JSON-structured output — exactly 3 plot directions as
/// `[{"direction","summary","keyPoints"}, ...]`. Structured-JSON generation
/// is the single most fragile thing to ask of a real LLM: models wrap output
/// in markdown fences, add chatty preamble, or emit malformed JSON. The
/// notifier's `_parseSuggestions` has fallback logic (strips ``` fences,
/// tolerates trailing prose) that only real model output can stress — the
/// canned tests feed a perfectly-shaped string and so prove nothing about
/// parser robustness against real GLM behavior.
///
/// This env-gated test drives the real notifier end-to-end (prompt → real
/// GLM-4-flash → parse → state) and asserts the parser survives real output
/// and yields exactly 3 well-formed suggestions — closing the LFIN-03 path's
/// real-API gap.
library;

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/application/continuation_suggestion_notifier.dart';

import '../../../journey/helpers/journey_container.dart';

void main() {
  final apiKey = Platform.environment['GLM_API_KEY'];
  final baseUrl =
      Platform.environment['GLM_BASE_URL'] ??
      'https://open.bigmodel.cn/api/paas/v4';
  final model = Platform.environment['GLM_MODEL'] ?? 'glm-4-flash';

  // A chapter ending with a clear hook (the mysterious ancient jade, a calling
  // hall) so GLM has narrative material to propose 3 distinct directions from.
  const chapterEnding =
      '林风盘膝坐在青云峰的密室中，运转清虚真人传授的无名功法。丹田中的灵气如溪流般缓缓流转，'
      '那块刻满符文的古玉在他掌心微微发烫。突然，一阵奇异的波动从古玉中传出，他眼前浮现出'
      '一座从未见过的古老殿堂。殿堂深处，似乎有什么东西在呼唤他。林风睁开眼，心中既惊又疑——'
      '这块古玉的来历，远比他想象的更加神秘。';

  group('Continuation suggestions (Real GLM API)', () {
    test(
      'generates exactly 3 well-formed plot directions via real GLM + survives parser',
      () async {
        final container = await createJourneyContainer(
          apiKey: apiKey!,
          baseUrl: baseUrl,
          model: model,
        );
        addTearDown(() => cleanupJourneyContainer(container));

        final notifier = container.read(
          continuationSuggestionNotifierProvider.notifier,
        );

        // Fire-and-forget: generation runs async, updating state
        // (isLoading → suggestions | error).
        notifier.generateSuggestions(chapterText: chapterEnding);

        // Poll until the async generation settles (no longer loading).
        // GLM-4-flash: ~10-25s for a 3-item JSON completion.
        final deadline = DateTime.now().add(const Duration(seconds: 100));
        while (
            container.read(continuationSuggestionNotifierProvider).isLoading) {
          if (DateTime.now().isAfter(deadline)) {
            throw TimeoutException(
              'Continuation generation did not settle within 100s',
            );
          }
          await Future.delayed(const Duration(milliseconds: 400));
        }

        final state = container.read(continuationSuggestionNotifierProvider);

        // The parser must have survived real GLM output. An error here would
        // mean real model output (markdown fences / preamble / malformed JSON)
        // broke _parseSuggestions — the exact failure mode this test exists to
        // catch.
        expect(
          state.error,
          isNull,
          reason:
              'Parser should survive real GLM output; error=$state.error '
              'indicates real-model output broke _parseSuggestions',
        );

        // The prompt explicitly requests exactly 3 directions.
        expect(
          state.suggestions.length,
          3,
          reason: 'Prompt requests exactly 3 plot directions',
        );

        // All 3 must be well-formed (non-empty direction + summary).
        for (var i = 0; i < state.suggestions.length; i++) {
          final s = state.suggestions[i];
          expect(
            s.direction,
            isNotEmpty,
            reason: 'Suggestion $i direction must be non-empty',
          );
          expect(
            s.summary,
            isNotEmpty,
            reason: 'Suggestion $i summary must be non-empty',
          );
        }

        for (final s in state.suggestions) {
          print('[CONTINUATION] ${s.direction} — ${s.summary}');
        }
      },
      skip: apiKey == null ? 'GLM_API_KEY not set' : null,
      timeout: const Timeout(Duration(seconds: 120)),
    );
  });
}
