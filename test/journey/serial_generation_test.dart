import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/knowledge/domain/skill_document.dart';
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
    'should pass GLM streaming smoke test',
    () async {
      await _runGlmSmokeTest(container);
    },
    skip: apiKey == null ? 'GLM_API_KEY not set' : null,
    timeout: const Timeout(Duration(seconds: 120)),
  );

  test(
    'should generate 30 chapters with knowledge injection and Skill guardian',
    () async {
      await _setupWorldBuilding(container);

      final manuscriptRepo = await container.read(
        manuscriptRepositoryProvider.future,
      );
      final chapterRepository = await container.read(
        chapterRepositoryProvider.future,
      );
      final manuscript = await manuscriptRepo.add(
        Manuscript(
          id: 'ms-serial-generation',
          title: '剑道苍穹',
          genre: '修仙',
          createdAt: DateTime(2026, 6, 7),
          updatedAt: DateTime(2026, 6, 7),
        ),
      );
      final chapters = await _createThirtyChapters(
        chapterRepository,
        manuscript.id,
      );

      await _runGlmSmokeTest(container);

      final pipeline = await container.read(promptPipelineProvider.future);
      final adapter = container.read(openaiAdapterProvider);
      final provider = container.read(activeProviderProvider)!;
      final key = container.read(activeApiKeyProvider)!;
      final auditService = await container.read(
        tokenAuditServiceProvider.future,
      );

      Future<String> generateChapter(int index) async {
        final fragment = Fragment(
          id: 'frag-$index',
          text: StoryOutline.chapters[index],
          createdAt: DateTime.now(),
        );
        final context = PromptContext(
          fragments: [fragment],
          bannedPhrases: const [],
        );
        final messages = pipeline.build(context);

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
          manuscriptId: manuscript.id,
          chapterId: chapters[index].id,
          inputText: StoryOutline.chapters[index],
          outputText: output,
        );
        await chapterRepository.updateDocumentContent(
          chapters[index].id,
          output,
        );
        return output;
      }

      for (var i = 0; i < 30; i++) {
        try {
          final output = await generateChapter(i);
          debugPrint(
            '[JOURNEY] Chapter ${i + 1}/30 generated (${output.length} chars)',
          );
        } catch (e) {
          final diagnostic = _safeExceptionDiagnostic(e);
          debugPrint('[ERROR] Chapter ${i + 1}/30 failed: $diagnostic');
          rethrow;
        }

        if (i < 29) {
          await Future.delayed(const Duration(seconds: 3));
        }
      }

      final generatedChapters = chapterRepository.getByManuscriptId(
        manuscript.id,
      );
      expect(generatedChapters, hasLength(30));

      var totalChars = 0;
      for (var i = 0; i < generatedChapters.length; i++) {
        final content = generatedChapters[i].documentContent;
        expect(content, isNotEmpty);
        expect(content.length, greaterThanOrEqualTo(300));
        expect(content.length, lessThanOrEqualTo(500));
        totalChars += content.length;
        debugPrint('[JOURNEY] Chapter ${i + 1}: ${content.length} chars');
      }
      debugPrint(
        '[JOURNEY] Total chars: $totalChars, avg: ${totalChars ~/ 30}',
      );

      var chaptersWithNames = 0;
      for (final index in [0, 7, 14, 21, 28]) {
        final content = generatedChapters[index].documentContent;
        final matchedNames = StoryOutline.characterNames
            .where(content.contains)
            .toList(growable: false);
        if (matchedNames.isNotEmpty) chaptersWithNames++;
        debugPrint('[KNOWLEDGE] Chapter ${index + 1} contains: $matchedNames');
      }
      expect(chaptersWithNames, greaterThanOrEqualTo(2));

      await _runDeviationDetectionForAllChapters(
        container: container,
        manuscript: manuscript,
        chapters: generatedChapters,
      );

      await auditService.flush();
      final auditRepository = await container.read(
        tokenAuditRepositoryProvider.future,
      );
      final snapshot = await auditRepository.buildSnapshot();
      expect(snapshot.totalCalls, greaterThanOrEqualTo(30));
      expect(snapshot.totalInputTokens, greaterThan(0));
      expect(snapshot.totalOutputTokens, greaterThan(0));
      debugPrint(
        '[AUDIT] Total calls: ${snapshot.totalCalls}, '
        'input: ${snapshot.totalInputTokens}, '
        'output: ${snapshot.totalOutputTokens}',
      );
    },
    skip: apiKey == null ? 'GLM_API_KEY not set' : null,
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

Future<void> _runGlmSmokeTest(ProviderContainer container) async {
  final pipeline = await container.read(promptPipelineProvider.future);
  final adapter = container.read(openaiAdapterProvider);
  final provider = container.read(activeProviderProvider)!;
  final key = container.read(activeApiKeyProvider)!;
  final context = PromptContext(
    fragments: [
      Fragment(
        id: 'frag-smoke',
        text: '修仙世界观测试：林风踏上修炼之路',
        createdAt: DateTime.now(),
      ),
    ],
    bannedPhrases: const [],
  );

  try {
    final output = await adapter
        .createStream(
          apiKey: key,
          baseUrl: provider.baseUrl,
          model: provider.model,
          messages: pipeline.build(context),
        )
        .join();
    expect(output, isNotEmpty);
    debugPrint(
      '[SMOKE_TEST_PASSED] GLM API streaming compatible (${output.length} chars)',
    );
  } catch (e) {
    debugPrint('[SMOKE_TEST_FAILED] ${_safeExceptionDiagnostic(e)}');
    rethrow;
  }
}

String _safeExceptionDiagnostic(Object error) {
  final sanitized = error
      .toString()
      .replaceAll(
        RegExp(
          r'authorization\s*[:=]\s*bearer\s+[^\s,}]+',
          caseSensitive: false,
        ),
        'Auth header [REDACTED]',
      )
      .replaceAll(
        RegExp(r'bearer\s+[^\s,}]+', caseSensitive: false),
        'Auth token [REDACTED]',
      )
      .replaceAll(
        RegExp(r'(api[_-]?key\s*[:=]\s*)[^\s,}]+', caseSensitive: false),
        r'$1[REDACTED]',
      );
  return '${error.runtimeType}: $sanitized';
}

Future<void> _setupWorldBuilding(ProviderContainer container) async {
  final templateRepository = container.read(worldTemplateRepositoryProvider);
  final template = await templateRepository.getById('male-xianxia-sect');
  expect(template, isNotNull, reason: 'Phase 7 xianxia template must exist');

  final instantiationService = await container.read(
    templateInstantiationServiceProvider.future,
  );
  final draft = instantiationService.createDraft(
    template!,
    storyConcept: '凡人少年林风入门修仙',
  );
  final result = await instantiationService.saveDraft(draft);
  expect(result.worldSetting, isNotNull);
  expect(result.worldSetting!.name, contains('青冥'));
  expect(result.worldSetting!.description, contains('宗门'));

  final characterRepo = await container.read(
    characterCardRepositoryProvider.future,
  );
  for (final card in [
    XianxiaFixtures.protagonist(),
    XianxiaFixtures.master(),
    XianxiaFixtures.senior(),
    XianxiaFixtures.rival(),
  ]) {
    await characterRepo.add(card);
  }

  final skillRepo = await container.read(skillRepositoryProvider.future);
  for (final skill in XianxiaFixtures.skillRules()) {
    await skillRepo.add(skill);
  }

  container.read(nameIndexServiceProvider.notifier).refresh();
}

Future<List<Chapter>> _createThirtyChapters(
  dynamic chapterRepository,
  String manuscriptId,
) async {
  final chapters = <Chapter>[];
  for (var i = 1; i <= 30; i++) {
    final plotPoint = StoryOutline.chapters[i - 1];
    final titleEnd = min(10, plotPoint.length);
    final chapter = await chapterRepository.add(
      Chapter(
        id: '',
        manuscriptId: manuscriptId,
        title: '第$i章 ${plotPoint.substring(0, titleEnd)}',
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

Future<void> _runDeviationDetectionForAllChapters({
  required ProviderContainer container,
  required Manuscript manuscript,
  required List<Chapter> chapters,
}) async {
  final deviationService = await container.read(
    deviationDetectionServiceProvider.future,
  );
  final skillRepo = await container.read(skillRepositoryProvider.future);
  final activeSkills = skillRepo.getAll().where((s) => s.isActive).toList();
  expect(activeSkills, isA<List<SkillDocument>>());

  var totalWarnings = 0;
  for (var i = 0; i < chapters.length; i++) {
    final chapter = chapters[i];
    try {
      final result = await deviationService.detectDeviations(
        chapter.documentContent,
        activeSkills,
        manuscriptId: manuscript.id,
        chapterId: chapter.id,
      );
      totalWarnings += result.warnings.length;
      for (final warning in result.warnings) {
        debugPrint(
          '[DEVIATION] Ch ${i + 1}: ${warning.severity.name} | '
          '${warning.skillName} | ${warning.description}',
        );
        if (warning.suggestedFix != null) {
          debugPrint('[DEVIATION]   Fix: ${warning.suggestedFix}');
        }
      }
    } catch (e) {
      debugPrint('[ERROR] Deviation chapter ${i + 1}/30 failed: $e');
      rethrow;
    }

    if (i < chapters.length - 1) {
      await Future.delayed(const Duration(seconds: 2));
    }
  }
  debugPrint('[DEVIATION] Warnings: $totalWarnings across 30 chapters');
}
