import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/onboarding/application/opening_generator_service.dart';
import 'package:museflow/features/onboarding/domain/opening_variant.dart';
import 'package:museflow/features/onboarding/presentation/opening_generator_sheet.dart';
import 'package:museflow/features/editor/presentation/editor_page.dart'
    show EditorHolderNotifier;
import 'package:openai_dart/openai_dart.dart';
import 'package:super_editor/super_editor.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  group('OpeningGeneratorSheet', () {
    testWidgets('should show title, concept input, and generate button', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            openingGeneratorServiceProvider.overrideWith(
              (ref) async => _openingServiceWith([]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: OpeningGeneratorSheet()),
          ),
        ),
      );

      expect(find.text('开篇生成'), findsOneWidget);
      expect(find.text('补充描述你的故事概念（可选）'), findsOneWidget);
      expect(find.text('生成开篇'), findsOneWidget);
      expect(find.byIcon(Icons.auto_stories), findsOneWidget);
    });

    testWidgets(
      'should generate variants and insert selected opening into editor',
      (tester) async {
        await setUpHiveTest();
        addTearDown(tearDownHiveTest);

        final editor = createDefaultDocumentEditor(
          document: MutableDocument(
            nodes: [ParagraphNode(id: 'node-1', text: AttributedText('正文'))],
          ),
        );
        editor.composer.setSelectionWithReason(
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: 'node-1',
              nodePosition: const TextNodePosition(offset: 2),
            ),
          ),
        );

        const variants = [
          OpeningVariant(style: OpeningVariantStyle.scene, text: '场景开篇'),
          OpeningVariant(style: OpeningVariantStyle.character, text: '人物开篇'),
          OpeningVariant(style: OpeningVariantStyle.suspense, text: '悬念开篇'),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              openingGeneratorServiceProvider.overrideWith(
                (ref) async => _openingServiceWith(variants),
              ),
              editorProvider.overrideWith(() => _TestEditorHolder(editor)),
            ],
            child: const MaterialApp(
              home: Scaffold(body: OpeningGeneratorSheet()),
            ),
          ),
        );

        await tester.tap(find.text('生成开篇'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('场景开篇'), findsOneWidget);
        expect(find.text('人物开篇'), findsOneWidget);
        expect(find.text('悬念开篇'), findsOneWidget);

        await tester.tap(find.text('人物切入'));
        await tester.pumpAndSettle();

        final node = editor.document.first as ParagraphNode;
        expect(node.text.toPlainText(), '正文人物开篇');
        editor.composer.dispose();
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

class _TestEditorHolder extends EditorHolderNotifier {
  _TestEditorHolder(this._editor);

  final Editor _editor;

  @override
  Editor? build() => _editor;
}
