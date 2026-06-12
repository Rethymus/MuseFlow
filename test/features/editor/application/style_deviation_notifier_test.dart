/// Tests for StyleDeviationNotifier.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/features/editor/application/style_deviation_notifier.dart';
import 'package:museflow/features/editor/application/style_profile_notifier.dart';
import 'package:museflow/features/editor/domain/author_style_profile.dart';

AuthorStyleProfile _testProfile() {
  return AuthorStyleProfile(
    manuscriptId: 'test-ms',
    sentenceLengthStats: const SentenceLengthStats(
      avg: 18,
      stdDev: 8,
      median: 16,
    ),
    rhythmScore: 0.3,
    vocabularyRichness: 0.6,
    rhetoricHabits: const RhetoricHabits(
      metaphorFrequency: 0.08,
      dialogueRatio: 0.35,
      descriptionRatio: 0.4,
      actionRatio: 0.17,
    ),
    emotionalTone: const EmotionalTone(
      overall: '温暖克制',
      warmth: 0.6,
      intensity: 0.4,
    ),
    analyzedChapterCount: 5,
    analyzedCharCount: 12000,
  );
}

void main() {
  group('StyleDeviationNotifier', () {
    test('should return null result when no profile available', () {
      final container = ProviderContainer(
        overrides: [
          styleProfileNotifierProvider.overrideWith(() => _FakeStyleNotifier()),
        ],
      );
      addTearDown(container.dispose);

      final notifier =
          container.read(styleDeviationNotifierProvider.notifier);
      notifier.analyzeText('林风独自站在高高的山门前。');

      final state = container.read(styleDeviationNotifierProvider);
      expect(state.result, isNull);
    });

    test('should return null result when profile has insufficient data', () {
      final container = ProviderContainer(
        overrides: [
          styleProfileNotifierProvider.overrideWith(
            () => _FakeStyleNotifier(
              profile: AuthorStyleProfile(
                manuscriptId: 'test',
                analyzedChapterCount: 1,
                analyzedCharCount: 200,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier =
          container.read(styleDeviationNotifierProvider.notifier);
      notifier.analyzeText('林风独自站在高高的山门前。');

      final state = container.read(styleDeviationNotifierProvider);
      expect(state.result, isNull);
    });

    test('should produce deviation result for valid profile and text', () {
      final container = ProviderContainer(
        overrides: [
          styleProfileNotifierProvider.overrideWith(
            () => _FakeStyleNotifier(profile: _testProfile()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier =
          container.read(styleDeviationNotifierProvider.notifier);
      notifier.analyzeText(
        '林风站在山门前，望着远方的天空。他心中涌起不安。',
      );

      final state = container.read(styleDeviationNotifierProvider);
      expect(state.result, isNotNull);
      expect(state.result!.aiScentScore, greaterThanOrEqualTo(0));
      expect(state.result!.aiScentScore, lessThanOrEqualTo(100));
      expect(state.result!.deviations.length, 5);
    });

    test('should return null result for non-CJK text', () {
      final container = ProviderContainer(
        overrides: [
          styleProfileNotifierProvider.overrideWith(
            () => _FakeStyleNotifier(profile: _testProfile()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier =
          container.read(styleDeviationNotifierProvider.notifier);
      notifier.analyzeText('hello world test');

      final state = container.read(styleDeviationNotifierProvider);
      expect(state.result, isNull);
    });

    test('reset should clear the result', () {
      final container = ProviderContainer(
        overrides: [
          styleProfileNotifierProvider.overrideWith(
            () => _FakeStyleNotifier(profile: _testProfile()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier =
          container.read(styleDeviationNotifierProvider.notifier);
      notifier.analyzeText('林风独自站在高高的山门前。');

      expect(container.read(styleDeviationNotifierProvider).result, isNotNull);

      notifier.reset();
      expect(container.read(styleDeviationNotifierProvider).result, isNull);
    });
  });
}

class _FakeStyleNotifier extends StyleProfileNotifier {
  final AuthorStyleProfile? profile;

  _FakeStyleNotifier({this.profile});

  @override
  StyleProfileState build() {
    return StyleProfileState(profile: profile);
  }
}
