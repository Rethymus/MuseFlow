import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:openai_dart/openai_dart.dart';

import 'helpers/journey_container.dart';
import 'helpers/story_outline.dart';
import 'helpers/xianxia_fixtures.dart';

void main() {
  final apiKey = Platform.environment['GLM_API_KEY'];
  final baseUrl =
      Platform.environment['GLM_BASE_URL'] ??
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

  test(
    'should complete full xianxia journey from world-building to 30 chapters',
    () async {
      debugPrint('[E2E] Starting full xianxia journey validation');

      await _phaseAWorldBuilding(container);

      final synthesisOutput = await _phaseBFragmentSynthesis(container);
      expect(synthesisOutput.length, greaterThan(50));

      final manuscript = await _phaseCOpeningGuide(container);

      await _phaseDSerialGeneration(container, manuscript);

      await _phaseETokenAudit(container);
    },
    skip: apiKey == null ? 'GLM_API_KEY not set' : null,
    timeout: const Timeout(Duration(minutes: 15)),
  );
}

Future<void> _phaseAWorldBuilding(ProviderContainer container) async {
  final templateRepository = container.read(worldTemplateRepositoryProvider);
  final template = await templateRepository.getById('male-xianxia-sect');
  expect(template, isNotNull);

  final instantiationService = await container.read(
    templateInstantiationServiceProvider.future,
  );
  final draft = instantiationService.createDraft(
    template!,
    storyConcept: '凡人少年林风入门修仙',
  );
  final result = await instantiationService.saveDraft(draft);
  expect(result.worldSetting, isNotNull);
  expect(result.worldSetting!.description, contains('练气'));
  expect(result.worldSetting!.description, contains('宗'));

  final characterRepository = await container.read(
    characterCardRepositoryProvider.future,
  );
  for (final card in [
    XianxiaFixtures.protagonist(),
    XianxiaFixtures.master(),
    XianxiaFixtures.senior(),
    XianxiaFixtures.rival(),
  ]) {
    await characterRepository.add(card);
  }

  final skillRepository = await container.read(skillRepositoryProvider.future);
  for (final skill in XianxiaFixtures.skillRules()) {
    await skillRepository.add(skill);
  }

  container.read(nameIndexServiceProvider.notifier).refresh();
  debugPrint('[E2E] Phase A: World-building complete');
}

Future<String> _phaseBFragmentSynthesis(ProviderContainer container) async {
  final fragmentRepository = await container.read(
    fragmentRepositoryProvider.future,
  );
  final fragments = <Fragment>[];
  for (final text in _fragmentTexts) {
    fragments.add(await fragmentRepository.addFragment(text));
  }

  final pipeline = await container.read(promptPipelineProvider.future);
  final messages = pipeline.build(
    PromptContext(fragments: fragments, bannedPhrases: const []),
  );
  final adapter = container.read(openaiAdapterProvider);
  final provider = container.read(activeProviderProvider)!;
  final key = container.read(activeApiKeyProvider)!;
  final auditService = await container.read(tokenAuditServiceProvider.future);

  Usage? capturedUsage;
  final output = await adapter
      .createStream(
        apiKey: key,
        baseUrl: provider.baseUrl,
        model: provider.model,
        messages: messages,
        onUsage: (usage) => capturedUsage = usage,
      )
      .join();

  auditService.recordAudit(
    usage: capturedUsage,
    modelName: provider.model,
    operationType: AuditOperationType.synthesis,
    manuscriptId: 'ms-e2e-fragment',
    chapterId: null,
    inputText: _fragmentTexts.join('\n'),
    outputText: output,
  );

  expect(output, isNotEmpty);
  expect(output.length, greaterThan(50));
  debugPrint(
    '[E2E] Phase B: Fragment synthesis complete (${output.length} chars)',
  );
  return output;
}

Future<Manuscript> _phaseCOpeningGuide(ProviderContainer container) async {
  final manuscriptRepository = await container.read(
    manuscriptRepositoryProvider.future,
  );
  final manuscript = await manuscriptRepository.add(
    Manuscript(
      id: 'ms-full-journey',
      title: '剑道苍穹',
      genre: '修仙',
      createdAt: DateTime(2026, 6, 7),
      updatedAt: DateTime(2026, 6, 7),
    ),
  );

  final service = await container.read(openingGeneratorServiceProvider.future);
  final variants = await service.generateOpenings(
    genreName: '修仙',
    storyConcept: '凡人少年林风入门修仙',
    worldDescription: '青云山修仙世界，凡人可练气筑基飞升，门派林立。',
    characterDescription: '林风：凡人少年，坚韧隐忍；清虚真人：严厉但慈爱的长老。',
    manuscriptId: manuscript.id,
  );

  expect(variants, hasLength(3));
  for (final variant in variants) {
    expect(variant.text, isNotEmpty);
    final preview = variant.text.substring(0, min(80, variant.text.length));
    debugPrint('[E2E] Opening ${variant.style.displayLabel}: $preview');
  }
  debugPrint('[E2E] Phase C: Opening guide complete (3 variants)');
  return manuscript;
}

Future<void> _phaseDSerialGeneration(
  ProviderContainer container,
  Manuscript manuscript,
) async {
  final chapterRepository = await container.read(
    chapterRepositoryProvider.future,
  );
  final chapters = await _createThirtyChapters(
    chapterRepository,
    manuscript.id,
  );
  final pipeline = await container.read(promptPipelineProvider.future);
  final adapter = container.read(openaiAdapterProvider);
  final provider = container.read(activeProviderProvider)!;
  final key = container.read(activeApiKeyProvider)!;
  final auditService = await container.read(tokenAuditServiceProvider.future);

  for (var i = 0; i < 30; i++) {
    try {
      final output = await _generateChapter(
        index: i,
        pipeline: pipeline,
        adapter: adapter,
        apiKey: key,
        baseUrl: provider.baseUrl,
        model: provider.model,
        manuscript: manuscript,
        chapter: chapters[i],
        auditService: auditService,
        chapterRepository: chapterRepository,
      );
      debugPrint(
        '[E2E] Chapter ${i + 1}/30 generated (${output.length} chars)',
      );
    } catch (e) {
      debugPrint('[E2E][ERROR] Chapter ${i + 1}/30 failed: $e');
      rethrow;
    }

    if (i < 29) {
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  debugPrint('[E2E] Phase D: 30-chapter generation complete');
}

Future<void> _phaseETokenAudit(ProviderContainer container) async {
  final auditService = await container.read(tokenAuditServiceProvider.future);
  await auditService.flush();
  final auditRepository = await container.read(
    tokenAuditRepositoryProvider.future,
  );
  final snapshot = await auditRepository.buildSnapshot();
  expect(snapshot.totalCalls, greaterThanOrEqualTo(32));
  expect(snapshot.totalInputTokens, greaterThan(0));
  expect(snapshot.totalOutputTokens, greaterThan(0));
  debugPrint(
    '[E2E] Audit calls: ${snapshot.totalCalls}, '
    'input: ${snapshot.totalInputTokens}, output: ${snapshot.totalOutputTokens}',
  );
  debugPrint(
    '[E2E] Phase E: Token audit verified (${snapshot.totalCalls} calls)',
  );
}

Future<String> _generateChapter({
  required int index,
  required PromptPipeline pipeline,
  required dynamic adapter,
  required String apiKey,
  required String baseUrl,
  required String model,
  required Manuscript manuscript,
  required Chapter chapter,
  required dynamic auditService,
  required dynamic chapterRepository,
}) async {
  final fragment = Fragment(
    id: 'e2e-frag-$index',
    text: StoryOutline.chapters[index],
    createdAt: DateTime.now(),
  );
  final messages = pipeline.build(
    PromptContext(fragments: [fragment], bannedPhrases: const []),
  );

  Usage? capturedUsage;
  final output = await adapter
      .createStream(
        apiKey: apiKey,
        baseUrl: baseUrl,
        model: model,
        messages: messages,
        onUsage: (usage) => capturedUsage = usage,
      )
      .join();

  auditService.recordAudit(
    usage: capturedUsage,
    modelName: model,
    operationType: AuditOperationType.synthesis,
    manuscriptId: manuscript.id,
    chapterId: chapter.id,
    inputText: StoryOutline.chapters[index],
    outputText: output,
  );
  await chapterRepository.updateDocumentContent(chapter.id, output);
  return output;
}

Future<List<Chapter>> _createThirtyChapters(
  dynamic chapterRepository,
  String manuscriptId,
) async {
  final chapters = <Chapter>[];
  for (var i = 1; i <= 30; i++) {
    final plotPoint = StoryOutline.chapters[i - 1];
    final chapter = await chapterRepository.add(
      Chapter(
        id: '',
        manuscriptId: manuscriptId,
        title: '第$i章 ${plotPoint.substring(0, min(10, plotPoint.length))}',
        sortOrder: i,
        documentContent: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    chapters.add(chapter);
  }
  return chapters;
}

const _fragmentTexts = [
  '林风在青云峰采集灵草时发现一块刻满符文的古玉',
  '苏雪晴暗中帮助林风通过入门考核，赠送一枚护身符',
  '赵天磊在比武中使出禁术，引起长老注意',
  '清虚真人传授林风无名功法第一层，告诫不可外传',
  '外门禁地深处传来异响，有弟子夜间失踪',
];
