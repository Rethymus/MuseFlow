import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/onboarding/application/opening_generator_service.dart';
import 'package:museflow/features/onboarding/domain/opening_variant.dart';
import 'package:museflow/features/onboarding/presentation/wizard_steps/opening_step_page.dart';
import 'package:openai_dart/openai_dart.dart';

void main() {
  group('OpeningStepPage', () {
    testWidgets('should show concept input, generate button, and empty state', (
      tester,
    ) async {
      OpeningVariant? selected;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            openingGeneratorServiceProvider.overrideWith(
              (ref) async => _openingServiceWith([]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: OpeningStepPage(
                genreName: '玄幻',
                worldDescription: '灵气复苏的世界',
                characterDescription: '背负秘密的少年',
                onSelected: (variant) => selected = variant,
              ),
            ),
          ),
        ),
      );

      expect(find.text('补充描述你的故事概念（可选）'), findsOneWidget);
      expect(find.text('生成开篇'), findsOneWidget);
      expect(find.byIcon(Icons.auto_stories), findsOneWidget);
      expect(find.text('点击上方按钮生成开篇'), findsOneWidget);
      expect(selected, isNull);
    });

    testWidgets(
      'should generate variants and notify when a variant is selected',
      (tester) async {
        OpeningVariant? selected;
        const variants = [
          OpeningVariant(style: OpeningVariantStyle.scene, text: '雨夜的城门缓缓打开。'),
          OpeningVariant(
            style: OpeningVariantStyle.character,
            text: '少年握紧了袖中的旧钥匙。',
          ),
          OpeningVariant(
            style: OpeningVariantStyle.suspense,
            text: '钟声响起时，尸体消失了。',
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              openingGeneratorServiceProvider.overrideWith(
                (ref) async => _openingServiceWith(variants),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: OpeningStepPage(
                  genreName: '悬疑',
                  worldDescription: '迷雾笼罩的小镇',
                  characterDescription: '追查真相的女主',
                  onSelected: (variant) => selected = variant,
                ),
              ),
            ),
          ),
        );

        await tester.enterText(find.byType(TextField), '从一封匿名信开始');
        await tester.tap(find.text('生成开篇'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('场景切入'), findsOneWidget);
        expect(find.text('人物切入'), findsOneWidget);
        expect(find.text('悬念切入'), findsOneWidget);
        expect(find.text('雨夜的城门缓缓打开。'), findsOneWidget);
        expect(find.text('少年握紧了袖中的旧钥匙。'), findsOneWidget);
        expect(find.text('钟声响起时，尸体消失了。'), findsOneWidget);

        await tester.tap(find.text('人物切入'));
        await tester.pumpAndSettle();

        expect(selected, variants[1]);
      },
    );
  });
}

OpeningGeneratorService _openingServiceWith(List<OpeningVariant> variants) {
  return OpeningGeneratorService(
    openingStream: (List<ChatMessage> messages) => Stream.value(
      jsonEncode({
        'openings': variants.map((variant) => variant.toJson()).toList(),
      }),
    ),
  );
}
