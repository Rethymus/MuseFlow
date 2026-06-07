import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';

import 'helpers/journey_container.dart';

void main() {
  final apiKey = Platform.environment['GLM_API_KEY'];
  final baseUrl = Platform.environment['GLM_BASE_URL'] ??
      'https://open.bigmodel.cn/api/paas/v4';
  final model = Platform.environment['GLM_MODEL'] ?? 'glm-4-flash';

  late ProviderContainer container;

  setUp(() async {
    container = await createJourneyContainer(
      apiKey: apiKey!,
      baseUrl: baseUrl,
      model: model,
    );
  });

  tearDown(() async {
    await cleanupJourneyContainer(container);
  });

  group('Opening Generator Service Resolution', () {
    test(
      'should resolve openingGeneratorServiceProvider without StateError',
      () async {
        // This proves that activeProviderProvider and activeApiKeyProvider
        // overrides in journey_container.dart satisfy the provider chain.
        final service = await container.read(
          openingGeneratorServiceProvider.future,
        );

        expect(service, isNotNull);
      },
      skip: apiKey == null ? 'GLM_API_KEY not set' : null,
      timeout: const Timeout(Duration(seconds: 120)),
    );
  });

  group('Generate 3 Opening Styles', () {
    test(
      'should generate exactly 3 opening variants with non-empty text',
      () async {
        // Create a manuscript for the manuscriptId parameter
        final manuscriptRepo = await container.read(
          manuscriptRepositoryProvider.future,
        );
        final manuscript = await manuscriptRepo.add(
          Manuscript(
            id: 'ms-opening-test',
            title: '剑道苍穹',
            genre: '修仙',
            createdAt: fixedDate,
            updatedAt: fixedDate,
          ),
        );

        final service = await container.read(
          openingGeneratorServiceProvider.future,
        );

        final variants = await service.generateOpenings(
          genreName: '修仙',
          worldDescription: '青云山修仙世界，凡人可练气筑基飞升，门派林立',
          characterDescription: '林风：凡人少年，坚韧隐忍；清虚真人：严厉但慈爱的长老',
          storyConcept: '凡人少年林风入门青云宗修仙，经历练气筑基的成长之路',
          manuscriptId: manuscript.id,
        );

        expect(variants, isA<List>());
        expect(variants.length, equals(3),
            reason: 'Should generate exactly 3 opening variants');

        for (final variant in variants) {
          expect(variant.text, isNotEmpty,
              reason: 'Each variant text should be non-empty');
        }

        // Print variant previews for manual review
        for (final variant in variants) {
          final preview = variant.text.substring(
            0,
            min(80, variant.text.length),
          );
          // ignore: avoid_print
          print(
            '[OPENING] Style=${variant.style.displayLabel}: $preview',
          );
        }
      },
      skip: apiKey == null ? 'GLM_API_KEY not set' : null,
      timeout: const Timeout(Duration(seconds: 120)),
    );
  });

  group('Style Differentiation', () {
    test(
      'should produce 3 variants that are NOT all identical',
      () async {
        final manuscriptRepo = await container.read(
          manuscriptRepositoryProvider.future,
        );
        final manuscript = await manuscriptRepo.add(
          Manuscript(
            id: 'ms-opening-diff-test',
            title: '剑道苍穹',
            genre: '修仙',
            createdAt: fixedDate,
            updatedAt: fixedDate,
          ),
        );

        final service = await container.read(
          openingGeneratorServiceProvider.future,
        );

        final variants = await service.generateOpenings(
          genreName: '修仙',
          worldDescription: '青云山修仙世界，凡人可练气筑基飞升，门派林立',
          characterDescription: '林风：凡人少年，坚韧隐忍；清虚真人：严厉但慈爱的长老',
          storyConcept: '凡人少年林风入门青云宗修仙，经历练气筑基的成长之路',
          manuscriptId: manuscript.id,
        );

        expect(variants.length, equals(3));

        // Extract style fields
        final styles = variants.map((v) => v.style).toList();
        // ignore: avoid_print
        print('[STYLES] ${styles.map((s) => s.displayLabel).toList()}');

        // Assert the 3 variants are NOT all identical in text content
        final texts = variants.map((v) => v.text).toList();
        final allIdentical =
            texts[0] == texts[1] && texts[1] == texts[2];
        expect(allIdentical, isFalse,
            reason:
                'The 3 opening variants should not all be identical (style differentiation)');

        // Also check styles differ (scene, character, suspense)
        final styleValues = styles.map((s) => s.value).toSet();
        expect(styleValues.length, greaterThanOrEqualTo(2),
            reason:
                'At least 2 distinct styles should be present among 3 variants');
      },
      skip: apiKey == null ? 'GLM_API_KEY not set' : null,
      timeout: const Timeout(Duration(seconds: 120)),
    );
  });
}

// Fixed date for test consistency
final fixedDate = DateTime(2026, 6, 7);
