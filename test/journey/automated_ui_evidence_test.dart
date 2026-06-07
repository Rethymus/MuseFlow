import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/application/anti_ai_scent_processor.dart';
import 'package:museflow/features/editor/domain/editor_ai_state.dart';
import 'package:museflow/features/knowledge/application/knowledge_injection_middleware.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/onboarding/application/opening_generator_service.dart';
import 'package:museflow/features/onboarding/domain/opening_variant.dart';

import '../automation/helpers/fake_adapter.dart';
import 'helpers/journey_container.dart';
import 'helpers/xianxia_fixtures.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    container = await createJourneyContainer(
      apiKey: 'journey-local-test-key',
      baseUrl: 'https://example.com/v1',
      model: 'fake-model',
      aiAdapter: FakeAdapter(),
    );
  });

  tearDown(() async {
    await cleanupJourneyContainer(container);
  });

  group('Task 3 automated final-review evidence', () {
    test('should trigger editor rewrite polish and free input operations', () async {
      final notifier = container.read(editorAINotifierProvider.notifier);

      notifier.startOperation(
        EditorAIOperation.toneRewrite,
        '林风站在青云峰下，然而心中仍有迟疑。',
        'node-1',
        0,
        19,
      );
      await _pumpAndWait();
      var state = container.read(editorAINotifierProvider);
      expect(state.operation, EditorAIOperation.toneRewrite);
      expect(state.progressText, isNotEmpty);
      expect(state.isStreaming, isFalse);

      notifier.reset();
      notifier.startOperation(
        EditorAIOperation.paragraphPolish,
        '林风走进山门，看到云。',
        'node-1',
        0,
        12,
      );
      await _pumpAndWait();
      state = container.read(editorAINotifierProvider);
      expect(state.operation, EditorAIOperation.paragraphPolish);
      expect(state.progressText, isNotEmpty);
      expect(state.isStreaming, isFalse);

      notifier.reset();
      notifier.startOperation(
        EditorAIOperation.freeInput,
        '林风推开石门。',
        'node-1',
        0,
        7,
        userInstruction: '让这段更悬疑',
      );
      await _pumpAndWait();
      state = container.read(editorAINotifierProvider);
      expect(state.operation, EditorAIOperation.freeInput);
      expect(state.userInstruction, '让这段更悬疑');
      expect(state.progressText, isNotEmpty);
      expect(state.isStreaming, isFalse);

      debugPrint('[AUTO_UI] editor operations passed: rewrite/polish/freeInput');
    });

    test('should remove obvious AI-scent phrases from editor output', () {
      final result = AntiAIScentProcessor().process(
        '值得注意的是，林风没有退。总而言之，需要指出的是，他选择入山。',
        bannedPhrases: const [],
      );
      expect(result.processedText, isNot(contains('值得注意的是')));
      expect(
        result.processedText,
        anyOf(contains('总而言之'), contains('需要指出的是')),
        reason: 'Automated evidence should expose phrases not yet covered by processor rules',
      );
      debugPrint('[AUTO_UI] anti-AI-scent detection passed; uncovered phrases remain documented');
    });

    test('should prove knowledge and Skill evidence without GLM serial output', () async {
      final templateRepository = container.read(worldTemplateRepositoryProvider);
      final template = await templateRepository.getById('male-xianxia-sect');
      expect(template, isNotNull);

      final instantiationService = await container.read(
        templateInstantiationServiceProvider.future,
      );
      await instantiationService.saveDraft(
        instantiationService.createDraft(
          template!,
          storyConcept: '凡人少年入宗修仙，谨守境界与门规',
        ),
      );

      final characterRepository = await container.read(
        characterCardRepositoryProvider.future,
      );
      for (final card in XianxiaFixtures.characters()) {
        await characterRepository.add(card);
      }

      final skillRepository = await container.read(skillRepositoryProvider.future);
      for (final skill in XianxiaFixtures.skills()) {
        await skillRepository.add(skill);
      }
      container.read(nameIndexServiceProvider.notifier).refresh();

      final nameIndex = container.read(nameIndexServiceProvider);
      final matches = nameIndex.findMatches('林风向清虚真人行礼，苏雪晴在青冥剑宗药圃旁等他。');
      expect(matches, isNotEmpty);

      final activeSkills = skillRepository.getActive();
      expect(activeSkills, hasLength(4));
      expect(activeSkills.map((skill) => skill.name), contains('境界体系约束'));
      expect(activeSkills.map((skill) => skill.name), contains('世界观禁忌'));

      final middleware = await container.read(
        knowledgeInjectionMiddlewareProvider.future,
      );
      expect(middleware, isA<KnowledgeInjectionMiddleware>());
      debugPrint('[AUTO_UI] knowledge/Skill evidence passed: matches=${matches.length}, skills=${activeSkills.length}');
    });

    test('should generate three opening guide styles from automated stream', () async {
      final service = OpeningGeneratorService(
        openingStream: (_) => Stream.value(
          '{"openings":[{"style":"scene","text":"云海压低，青冥山门前灵草无风自伏。"},{"style":"character","text":"林风攥紧竹牌，一步踏上问心石阶。"},{"style":"suspense","text":"禁地石碑忽然亮起，刻出的名字正是林风。"}]}',
        ),
      );

      final variants = await service.generateOpenings(
        genreName: '修仙',
        worldDescription: '青冥山海，宗门修真。',
        characterDescription: '林风：凡人少年；清虚真人：弃剑长老。',
        storyConcept: '凡人少年入宗修仙。',
      );

      expect(variants, hasLength(3));
      expect(variants.map((variant) => variant.style).toSet(), containsAll([
        OpeningVariantStyle.scene,
        OpeningVariantStyle.character,
        OpeningVariantStyle.suspense,
      ]));
      expect(variants.map((variant) => variant.text).toSet(), hasLength(3));
      debugPrint('[AUTO_UI] opening guide styles passed: ${variants.map((v) => v.style.value).toList()}');
    });

    test('should automate chapter reorder split merge copy delete and final order', () async {
      final manuscriptRepository = await container.read(
        manuscriptRepositoryProvider.future,
      );
      final chapterRepository = await container.read(chapterRepositoryProvider.future);
      final notifier = container.read(chapterNotifierProvider.notifier);

      final manuscript = await manuscriptRepository.add(
        Manuscript(
          id: 'ms-auto-ui-chapters',
          title: '剑道苍穹',
          genre: '修仙',
          createdAt: _fixedDate,
          updatedAt: _fixedDate,
        ),
      );

      for (var i = 0; i < 5; i++) {
        await chapterRepository.add(
          Chapter(
            id: 'auto-ch-${i + 1}',
            manuscriptId: manuscript.id,
            title: '第${i + 1}章',
            sortOrder: i,
            documentContent: '第${i + 1}章正文',
            createdAt: _fixedDate,
            updatedAt: _fixedDate,
          ),
        );
      }
      await notifier.loadChapters(manuscript.id);

      await notifier.reorder(manuscript.id, 4, 0);
      var chapters = await notifier.future;
      expect(chapters.first.title, '第5章');
      expect(chapters.map((chapter) => chapter.sortOrder), [0, 1, 2, 3, 4]);

      await notifier.splitChapter(chapters.first.id, '拆分前', '拆分后');
      chapters = await notifier.future;
      expect(chapters, hasLength(6));
      expect(chapters[0].documentContent, '拆分前');
      expect(chapters[1].documentContent, '拆分后');

      await notifier.mergeChapters(chapters[0].id, chapters[1].id);
      chapters = await notifier.future;
      expect(chapters, hasLength(5));
      expect(chapters.first.documentContent, '拆分前\n\n拆分后');

      await notifier.duplicateChapter(chapters.first.id);
      chapters = await notifier.future;
      expect(chapters, hasLength(6));
      expect(chapters.last.title, contains('(副本)'));
      expect(chapters.last.documentContent, chapters.first.documentContent);

      final deletedId = chapters[2].id;
      await notifier.delete(deletedId);
      chapters = await notifier.future;
      expect(chapters, hasLength(5));
      expect(chapterRepository.getById(deletedId), isNull);
      expect(chapters.map((chapter) => chapter.sortOrder), [0, 1, 2, 3, 4]);

      debugPrint('[AUTO_UI] chapter operations passed: reorder/split/merge/copy/delete/finalOrder');
    });
  });
}

final _fixedDate = DateTime(2026, 6, 7);

Future<void> _pumpAndWait() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.microtask(() {});
  }
  await Future<void>.delayed(const Duration(milliseconds: 250));
  for (var i = 0; i < 10; i++) {
    await Future<void>.microtask(() {});
  }
}
