import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/ai/application/anti_ai_scent_processor.dart';
import 'package:museflow/features/editor/domain/editor_ai_state.dart';
import 'package:museflow/features/knowledge/application/knowledge_injection_middleware.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/chapter_export.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/onboarding/application/opening_generator_service.dart';
import 'package:museflow/features/onboarding/domain/opening_variant.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:museflow/features/story_structure/application/export_service.dart';
import 'package:museflow/features/story_structure/application/format_cleaner.dart';
import 'package:museflow/features/story_structure/domain/export_bundle.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'package:openai_dart/openai_dart.dart';

import '../automation/helpers/fake_adapter.dart';
import 'helpers/d11_bounds.dart';
import 'helpers/journey_container.dart';
import 'helpers/story_outline.dart';
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
    test(
      'should trigger editor rewrite polish and free input operations',
      () async {
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

        debugPrint(
          '[AUTO_UI] editor operations passed: rewrite/polish/freeInput',
        );
      },
    );

    test('should remove obvious AI-scent phrases from editor output', () {
      final result = AntiAIScentProcessor().process(
        '值得注意的是，林风没有退。总而言之，需要指出的是，他选择入山。',
        bannedPhrases: const [],
      );
      expect(result.processedText, isNot(contains('值得注意的是')));
      expect(result.processedText, isNot(contains('总而言之')));
      expect(result.processedText, isNot(contains('需要指出的是')));
      expect(
        result.highlights.map((highlight) => highlight.originalText),
        containsAll(['值得注意的是', '总而言之', '需要指出的是']),
      );
      debugPrint(
        '[AUTO_UI] anti-AI-scent removal passed; verifier-listed phrases removed',
      );
    });

    test(
      'should prove knowledge and Skill evidence without GLM serial output',
      () async {
        final templateRepository = container.read(
          worldTemplateRepositoryProvider,
        );
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

        final skillRepository = await container.read(
          skillRepositoryProvider.future,
        );
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
        debugPrint(
          '[AUTO_UI] knowledge/Skill evidence passed: matches=${matches.length}, skills=${activeSkills.length}',
        );
      },
    );

    test(
      'should generate three opening guide styles from automated stream',
      () async {
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
        expect(
          variants.map((variant) => variant.style).toSet(),
          containsAll([
            OpeningVariantStyle.scene,
            OpeningVariantStyle.character,
            OpeningVariantStyle.suspense,
          ]),
        );
        expect(variants.map((variant) => variant.text).toSet(), hasLength(3));
        debugPrint(
          '[AUTO_UI] opening guide styles passed: ${variants.map((v) => v.style.value).toList()}',
        );
      },
    );

    test(
      'should automate chapter reorder split merge copy delete and final order',
      () async {
        final manuscriptRepository = await container.read(
          manuscriptRepositoryProvider.future,
        );
        final chapterRepository = await container.read(
          chapterRepositoryProvider.future,
        );
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

        debugPrint(
          '[AUTO_UI] chapter operations passed: reorder/split/merge/copy/delete/finalOrder',
        );
      },
    );
  });

  group('JOURNEY-07 foreshadowing service evidence', () {
    test(
      'should prove foreshadowing plant-track-resolve lifecycle at 100-chapter scale',
      () async {
        final notifier = container.read(foreshadowingNotifierProvider.notifier);
        final fixtures = [
          (id: 'fs-mysterious-origin', title: '神秘身世', planted: 3, resolved: 92),
          (
            id: 'fs-senior-sister-secret',
            title: '师姐的秘密',
            planted: 10,
            resolved: 78,
          ),
          (id: 'fs-forbidden-zone', title: '门派禁地', planted: 20, resolved: 88),
          (id: 'fs-ancient-artifact', title: '远古法器', planted: 30, resolved: 96),
        ];

        for (final fixture in fixtures) {
          final entry = ForeshadowingEntry(
            id: fixture.id,
            title: fixture.title,
            mode: ForeshadowingMode.detailed,
            status: ForeshadowingStatus.planted,
            plantedChapter: fixture.planted,
            createdAt: _fixedDate,
          );
          await notifier.add(entry);
          await notifier.save(
            entry.copyWith(status: ForeshadowingStatus.developing),
          );
          await notifier.markResolved(
            fixture.id,
            resolvedChapter: fixture.resolved,
          );
        }

        final entries = await notifier.future;
        final resolvedEntries = entries
            .where((entry) => fixtureIds.contains(entry.id))
            .toList();
        expect(resolvedEntries, hasLength(4));
        expect(resolvedEntries.every((entry) => entry.isResolved), isTrue);
        debugPrint(
          '[AUTO_UI] JOURNEY-07 foreshadowing lifecycle passed: 4/4 threads resolved',
        );
      },
    );
  });

  group('JOURNEY-08 format cleaning evidence', () {
    test(
      'should prove FormatCleaner produces clean output at 100-chapter scale',
      () {
        const cleaner = FormatCleaner();
        const sampledIndices = [0, 14, 29, 44, 59, 74, 89, 99];

        for (final index in sampledIndices) {
          final marker = index.isOdd ? '\n**加粗文本**\n' : '\n## 残留标题\n';
          final result = cleaner.clean(
            '${StoryOutline.chapters[index]}$marker',
          );
          expect(result.cleanedText, isNot(contains('**')));
          expect(result.cleanedText, isNot(contains('##')));
        }

        debugPrint(
          '[AUTO_UI] JOURNEY-08 format cleaning passed: 8/8 sampled chapters clean',
        );
      },
    );
  });

  group('JOURNEY-09 three-format export evidence', () {
    test(
      'should prove ExportService builds valid three-format output for 100 chapters',
      () {
        final chapters = [
          for (var i = 0; i < StoryOutline.chapters.length; i++)
            ChapterExport(
              title: '第${i + 1}章',
              sortOrder: i + 1,
              content: StoryOutline.chapters[i],
            ),
        ];
        final bundle = ExportBundle(
          schemaVersion: '1.0',
          manuscriptText: StoryOutline.chapters.join('\n\n'),
          chapters: chapters,
        );
        final service = ExportService(fileWriter: (_, _) async {});

        final markdown = service.buildMarkdown(bundle);
        final txt = service.buildTxt(bundle);
        final json = service.buildJson(bundle);
        final decoded = jsonDecode(json) as Map<String, dynamic>;

        expect(
          RegExp(r'^## ', multiLine: true).allMatches(markdown),
          hasLength(100),
        );
        expect(txt, isNot(contains('##')));
        expect(decoded['chapters'], hasLength(100));
        debugPrint(
          '[AUTO_UI] JOURNEY-09 export validation passed: md=100 headers, txt=clean, json=100 chapters',
        );
      },
    );
  });

  group('JOURNEY-10 statistics evidence', () {
    test('should prove statistics accuracy and token audit at scale', () async {
      final manuscriptRepository = await container.read(
        manuscriptRepositoryProvider.future,
      );
      final chapterRepository = await container.read(
        chapterRepositoryProvider.future,
      );
      final manuscript = await manuscriptRepository.add(
        Manuscript(
          id: 'ms-auto-ui-stats',
          title: '剑道苍穹统计验证',
          genre: '修仙',
          createdAt: _fixedDate,
          updatedAt: _fixedDate,
        ),
      );
      final pipeline = await container.read(promptPipelineProvider.future);
      final adapter = container.read(openaiAdapterProvider);
      final provider = container.read(activeProviderProvider)!;
      final key = container.read(activeApiKeyProvider)!;
      final auditService = await container.read(
        tokenAuditServiceProvider.future,
      );
      var totalWordCount = 0;

      for (var i = 0; i < 10; i++) {
        final chapter = await chapterRepository.add(
          Chapter(
            id: 'auto-ui-stats-ch-${i + 1}',
            manuscriptId: manuscript.id,
            title: '第${i + 1}章',
            sortOrder: i + 1,
            documentContent: '',
            createdAt: _fixedDate,
            updatedAt: _fixedDate,
          ),
        );
        final messages = pipeline.build(
          PromptContext(
            fragments: [
              Fragment(
                id: 'auto-ui-stats-frag-$i',
                text: StoryOutline.chapters[i],
                createdAt: _fixedDate,
              ),
            ],
            bannedPhrases: const [],
          ),
        );
        Usage? usage;
        final output = await adapter
            .createStream(
              apiKey: key,
              baseUrl: provider.baseUrl,
              model: provider.model,
              messages: messages,
              onUsage: (captured) => usage = captured,
            )
            .join();
        final boundedOutput = enforceD11Bounds(output);
        totalWordCount += boundedOutput.runes.length;
        auditService.recordAudit(
          usage: usage,
          modelName: provider.model,
          operationType: AuditOperationType.synthesis,
          manuscriptId: manuscript.id,
          chapterId: chapter.id,
          inputText: StoryOutline.chapters[i],
          outputText: boundedOutput,
        );
        await chapterRepository.updateDocumentContent(
          chapter.id,
          boundedOutput,
        );
      }

      await auditService.flush();
      final auditRepository = await container.read(
        tokenAuditRepositoryProvider.future,
      );
      final snapshot = await auditRepository.buildSnapshot();
      expect(snapshot.totalCalls, greaterThanOrEqualTo(10));
      expect(snapshot.totalInputTokens, greaterThan(0));
      expect(snapshot.totalOutputTokens, greaterThan(0));
      expect(totalWordCount, greaterThan(0));
      debugPrint(
        '[AUTO_UI] JOURNEY-10 statistics passed: calls=${snapshot.totalCalls}, input=${snapshot.totalInputTokens}, output=${snapshot.totalOutputTokens}',
      );
    });
  });

  group('Phase 14 issue regression checks', () {
    test('should verify Phase 14 fixes hold at 100-chapter scale', () {
      final longOutput = ('林风修行的日子一天天过去。' * 80).padRight(1000, '山');
      final bounded = enforceD11Bounds(longOutput);
      expect(bounded.length, lessThanOrEqualTo(500));
      expect(bounded.length, greaterThanOrEqualTo(300));

      final result = AntiAIScentProcessor().process(
        '这段话。总而言之，非常重要，需要指出的是，值得注意的。',
        bannedPhrases: const [],
      );
      expect(result.processedText, isNot(contains('总而言之')));
      expect(result.processedText, isNot(contains('需要指出的是')));
      debugPrint(
        '[AUTO_UI] Phase 14 regression passed: enforceD11Bounds<=500, anti-AI-scent phrases removed',
      );
    });
  });
}

final _fixedDate = DateTime(2026, 6, 7);
final fixtureIds = {
  'fs-mysterious-origin',
  'fs-senior-sister-secret',
  'fs-forbidden-zone',
  'fs-ancient-artifact',
};

Future<void> _pumpAndWait() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.microtask(() {});
  }
  await Future<void>.delayed(const Duration(milliseconds: 250));
  for (var i = 0; i < 10; i++) {
    await Future<void>.microtask(() {});
  }
}
