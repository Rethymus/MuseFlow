import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/ai/domain/ai_adapter.dart';
import 'package:museflow/features/knowledge/domain/skill_document.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:openai_dart/openai_dart.dart';

import '../automation/helpers/fake_adapter.dart';
import 'helpers/d11_bounds.dart';
import 'helpers/journey_container.dart';
import 'helpers/stage_prompts.dart';
import 'helpers/story_outline.dart';
import 'helpers/xianxia_fixtures.dart';

void main() {
  final apiKey = Platform.environment['GLM_API_KEY'];
  final baseUrl =
      Platform.environment['GLM_BASE_URL'] ??
      'https://open.bigmodel.cn/api/paas/v4';
  final model = Platform.environment['GLM_MODEL'] ?? 'glm-4-flash';

  ProviderContainer? container;

  setUp(() async {
    if (apiKey == null) return;
    container = await createJourneyContainer(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
    );
  });

  tearDown(() async {
    final activeContainer = container;
    container = null;
    if (activeContainer != null) {
      await cleanupJourneyContainer(activeContainer);
    }
  });

  test(
    'should pass GLM streaming smoke test',
    () async {
      // The deterministic tests below initialize TestWidgetsFlutterBinding
      // (via createJourneyContainer when apiKey == 'journey-local-test-key'),
      // installing a process-global HttpClient mock that returns 400 and would
      // poison this real GLM call. Null the override for the smoke test so
      // dart:io HttpClient uses its genuine implementation. See full_journey_test
      // for the recursion footgun in the HttpOverrides.runZoned alternative.
      final HttpOverrides? previous = HttpOverrides.current;
      HttpOverrides.global = null;
      try {
        await _runGlmSmokeTest(container!);
      } finally {
        HttpOverrides.global = previous;
      }
    },
    skip: apiKey == null ? 'GLM_API_KEY not set' : null,
    timeout: const Timeout(Duration(seconds: 120)),
  );

  test(
    'deterministic serial journey should generate 30 chapters without GLM credentials',
    () async {
      final localContainer = await createJourneyContainer(
        apiKey: 'journey-local-test-key',
        baseUrl: 'https://example.com/v1',
        model: 'fake-model',
        aiAdapter: _DeterministicJourneyAdapter(FakeAdapter()),
      );
      try {
        await _setupWorldBuilding(localContainer);
        final result = await _generateThirtyChapterJourney(
          container: localContainer,
          manuscriptId: 'ms-deterministic-serial',
          useDelay: false,
          runDeviationDetection: true,
        );

        expect(result.chapters, hasLength(30));
        expect(result.snapshot.totalCalls, greaterThanOrEqualTo(30));
        expect(result.snapshot.totalInputTokens, greaterThan(0));
        expect(result.snapshot.totalOutputTokens, greaterThan(0));
        expect(result.chapters[0].documentContent, contains('林风'));
        expect(result.chapters[7].documentContent, contains('苏雪晴'));
        expect(result.deviationChecks, equals(30));
        debugPrint(
          '[DETERMINISTIC] Serial journey complete: 30/30, '
          'totalCalls=${result.snapshot.totalCalls}, '
          'length min/max/avg=${result.minLength}/${result.maxLength}/${result.averageLength}',
        );
      } finally {
        await cleanupJourneyContainer(localContainer);
      }
    },
    skip: apiKey != null
        ? 'Deterministic no-credential path runs only without GLM_API_KEY'
        : null,
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'should generate 30 chapters with knowledge injection and Skill guardian',
    () async {
      final HttpOverrides? previous = HttpOverrides.current;
      HttpOverrides.global = null;
      try {
        await _setupWorldBuilding(container!);
        final result = await _generateThirtyChapterJourney(
          container: container!,
          manuscriptId: 'ms-serial-generation',
          useDelay: true,
          runDeviationDetection: true,
        );

        expect(result.chapters, hasLength(30));
        expect(result.chaptersWithNames, greaterThanOrEqualTo(2));
        expect(result.deviationChecks, equals(30));
        expect(result.snapshot.totalCalls, greaterThanOrEqualTo(30));
        expect(result.snapshot.totalInputTokens, greaterThan(0));
        expect(result.snapshot.totalOutputTokens, greaterThan(0));
        debugPrint(
          '[AUDIT] Total calls: ${result.snapshot.totalCalls}, '
          'input: ${result.snapshot.totalInputTokens}, '
          'output: ${result.snapshot.totalOutputTokens}',
        );
      } finally {
        HttpOverrides.global = previous;
      }
    },
    skip: apiKey == null ? 'GLM_API_KEY not set' : null,
    timeout: const Timeout(Duration(minutes: 20)),
  );
  test(
    'deterministic 100-chapter journey should generate with stage prompts and summary injection',
    () async {
      final localContainer = await createJourneyContainer(
        apiKey: 'journey-local-test-key',
        baseUrl: 'https://example.com/v1',
        model: 'fake-model',
        aiAdapter: _DeterministicJourneyAdapter(FakeAdapter()),
      );
      try {
        await _setupWorldBuilding(localContainer);
        final result = await _generateHundredChapterJourney(
          container: localContainer,
          manuscriptId: 'ms-deterministic-hundred',
          useDelay: false,
          runDeviationDetection: true,
        );

        expect(result.chapters, hasLength(100));
        expect(result.snapshot.totalCalls, greaterThanOrEqualTo(100));
        expect(result.snapshot.totalInputTokens, greaterThan(0));
        expect(result.snapshot.totalOutputTokens, greaterThan(0));
        expect(result.deviationChecks, equals(100));
        expect(result.totalChapters, equals(100));
        for (final chapter in result.chapters) {
          expect(chapter.documentContent, isNotEmpty);
          expect(chapter.documentContent.length, inInclusiveRange(300, 500));
        }
        debugPrint(
          '[DETERMINISTIC] 100-chapter journey complete: 100/100, '
          'totalCalls=${result.snapshot.totalCalls}, '
          'length min/max/avg=${result.minLength}/${result.maxLength}/${result.averageLength}',
        );
      } finally {
        await cleanupJourneyContainer(localContainer);
      }
    },
    skip: apiKey != null
        ? 'Deterministic no-credential path runs only without GLM_API_KEY'
        : null,
    timeout: const Timeout(Duration(minutes: 10)),
  );

  test(
    'should generate chapters 31-100 with knowledge injection and stage prompts',
    () async {
      final HttpOverrides? previous = HttpOverrides.current;
      HttpOverrides.global = null;
      try {
        await _setupWorldBuilding(container!);
        final result = await _generateHundredChapterJourney(
          container: container!,
          manuscriptId: 'ms-hundred-generation',
          useDelay: true,
          runDeviationDetection: true,
        );

        expect(result.chapters, hasLength(100));
        expect(result.chaptersWithNames, equals(5));
        expect(result.deviationChecks, equals(100));
        expect(result.snapshot.totalCalls, greaterThanOrEqualTo(100));
        expect(result.snapshot.totalInputTokens, greaterThan(0));
        expect(result.snapshot.totalOutputTokens, greaterThan(0));
        debugPrint(
          '[AUDIT] 100-chapter total calls: ${result.snapshot.totalCalls}, '
          'input: ${result.snapshot.totalInputTokens}, '
          'output: ${result.snapshot.totalOutputTokens}',
        );
      } finally {
        HttpOverrides.global = previous;
      }
    },
    skip: apiKey == null ? 'GLM_API_KEY not set' : null,
    // Real GLM 100-chapter generation measured ~78min (260618-h4h probe, ran
    // ch31→80 before the old 60min ceiling killed it). 120min gives headroom;
    // skipped entirely without GLM_API_KEY so CI never hits this.
    timeout: const Timeout(Duration(minutes: 120)),
  );
}

Future<_JourneyResult> _generateHundredChapterJourney({
  required ProviderContainer container,
  required String manuscriptId,
  required bool useDelay,
  required bool runDeviationDetection,
}) async {
  final manuscriptRepo = await container.read(
    manuscriptRepositoryProvider.future,
  );
  final chapterRepository = await container.read(
    chapterRepositoryProvider.future,
  );
  final manuscript = await manuscriptRepo.add(
    Manuscript(
      id: manuscriptId,
      title: '剑道苍穹',
      genre: '修仙',
      createdAt: DateTime(2026, 6, 8),
      updatedAt: DateTime(2026, 6, 8),
    ),
  );
  final chapters = await _createChapters(chapterRepository, manuscript.id, 100);

  await _runGlmSmokeTest(container);

  final pipeline = await container.read(promptPipelineProvider.future);
  final adapter = container.read(openaiAdapterProvider);
  final provider = container.read(activeProviderProvider)!;
  final key = container.read(activeApiKeyProvider)!;
  final auditService = await container.read(tokenAuditServiceProvider.future);

  Future<String> generateChapter(int index) async {
    final currentChapters = chapterRepository.getByManuscriptId(manuscript.id);
    currentChapters.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final previousContent = index > 0
        ? currentChapters[index - 1].documentContent
        : '';
    final previousSummary = previousContent.isEmpty
        ? ''
        : previousContent.length > 100
        ? '${previousContent.substring(0, 100)}...'
        : previousContent;
    final fragmentText = [
      StagePrompts.forChapterIndex(index),
      if (previousSummary.isNotEmpty) '上一章概要：$previousSummary',
      StoryOutline.chapters[index],
    ].where((text) => text.isNotEmpty).join('\n\n');
    final fragment = Fragment(
      id: 'frag-100-$index',
      text: fragmentText,
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

    final boundedOutput = enforceD11Bounds(output);

    auditService.recordAudit(
      usage: capturedUsage,
      modelName: provider.model,
      operationType: AuditOperationType.synthesis,
      manuscriptId: manuscript.id,
      chapterId: chapters[index].id,
      inputText: fragmentText,
      outputText: boundedOutput,
    );
    await chapterRepository.updateDocumentContent(
      chapters[index].id,
      boundedOutput,
    );
    return boundedOutput;
  }

  for (var i = 0; i < 100; i++) {
    try {
      final output = await generateChapter(i);
      debugPrint(
        '[JOURNEY] Chapter ${i + 1}/100 generated (${output.length} chars)',
      );
    } catch (e) {
      final diagnostic = _safeExceptionDiagnostic(e);
      debugPrint('[ERROR] Chapter ${i + 1}/100 failed: $diagnostic');
      rethrow;
    }

    if (useDelay && i < 99) {
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  final generatedChapters = chapterRepository.getByManuscriptId(manuscript.id);
  expect(generatedChapters, hasLength(100));

  var totalChars = 0;
  var minLength = 1 << 30;
  var maxLength = 0;
  for (var i = 0; i < generatedChapters.length; i++) {
    final content = generatedChapters[i].documentContent;
    expect(content, isNotEmpty);
    expect(content.length, inInclusiveRange(300, 500));
    totalChars += content.length;
    minLength = min(minLength, content.length);
    maxLength = max(maxLength, content.length);
    debugPrint('[JOURNEY] Chapter ${i + 1}: ${content.length} chars');
  }
  debugPrint('[JOURNEY] Total chars: $totalChars, avg: ${totalChars ~/ 100}');

  var chaptersWithNames = 0;
  for (final index in [44, 57, 79, 84, 96]) {
    final content = generatedChapters[index].documentContent;
    final matchedNames = StoryOutline.characterNames
        .where(content.contains)
        .toList(growable: false);
    expect(
      matchedNames,
      isNotEmpty,
      reason: 'Chapter ${index + 1} should include a character name',
    );
    chaptersWithNames++;
    debugPrint('[KNOWLEDGE] Chapter ${index + 1} contains: $matchedNames');
  }

  final deviationChecks = runDeviationDetection
      ? await _runDeviationDetectionForAllChapters(
          container: container,
          manuscript: manuscript,
          chapters: generatedChapters,
        )
      : 0;

  await auditService.flush();
  final auditRepository = await container.read(
    tokenAuditRepositoryProvider.future,
  );
  final snapshot = await auditRepository.buildSnapshot();

  return _JourneyResult(
    chapters: generatedChapters,
    chaptersWithNames: chaptersWithNames,
    deviationChecks: deviationChecks,
    snapshot: snapshot,
    minLength: minLength,
    maxLength: maxLength,
    averageLength: totalChars ~/ generatedChapters.length,
    totalChapters: generatedChapters.length,
  );
}

Future<_JourneyResult> _generateThirtyChapterJourney({
  required ProviderContainer container,
  required String manuscriptId,
  required bool useDelay,
  required bool runDeviationDetection,
}) async {
  final manuscriptRepo = await container.read(
    manuscriptRepositoryProvider.future,
  );
  final chapterRepository = await container.read(
    chapterRepositoryProvider.future,
  );
  final manuscript = await manuscriptRepo.add(
    Manuscript(
      id: manuscriptId,
      title: '剑道苍穹',
      genre: '修仙',
      createdAt: DateTime(2026, 6, 7),
      updatedAt: DateTime(2026, 6, 7),
    ),
  );
  final chapters = await _createChapters(chapterRepository, manuscript.id, 30);

  await _runGlmSmokeTest(container);

  final pipeline = await container.read(promptPipelineProvider.future);
  final adapter = container.read(openaiAdapterProvider);
  final provider = container.read(activeProviderProvider)!;
  final key = container.read(activeApiKeyProvider)!;
  final auditService = await container.read(tokenAuditServiceProvider.future);

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

    final boundedOutput = enforceD11Bounds(output);

    auditService.recordAudit(
      usage: capturedUsage,
      modelName: provider.model,
      operationType: AuditOperationType.synthesis,
      manuscriptId: manuscript.id,
      chapterId: chapters[index].id,
      inputText: StoryOutline.chapters[index],
      outputText: boundedOutput,
    );
    await chapterRepository.updateDocumentContent(
      chapters[index].id,
      boundedOutput,
    );
    return boundedOutput;
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

    if (useDelay && i < 29) {
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  final generatedChapters = chapterRepository.getByManuscriptId(manuscript.id);
  expect(generatedChapters, hasLength(30));

  var totalChars = 0;
  var minLength = 1 << 30;
  var maxLength = 0;
  for (var i = 0; i < generatedChapters.length; i++) {
    final content = generatedChapters[i].documentContent;
    expect(content, isNotEmpty);
    expect(content.length, inInclusiveRange(300, 500));
    totalChars += content.length;
    minLength = min(minLength, content.length);
    maxLength = max(maxLength, content.length);
    debugPrint('[JOURNEY] Chapter ${i + 1}: ${content.length} chars');
  }
  debugPrint('[JOURNEY] Total chars: $totalChars, avg: ${totalChars ~/ 30}');

  var chaptersWithNames = 0;
  for (final index in [0, 7, 14, 21, 28]) {
    final content = generatedChapters[index].documentContent;
    final matchedNames = StoryOutline.characterNames
        .where(content.contains)
        .toList(growable: false);
    if (matchedNames.isNotEmpty) chaptersWithNames++;
    debugPrint('[KNOWLEDGE] Chapter ${index + 1} contains: $matchedNames');
  }

  final deviationChecks = runDeviationDetection
      ? await _runDeviationDetectionForAllChapters(
          container: container,
          manuscript: manuscript,
          chapters: generatedChapters,
        )
      : 0;

  await auditService.flush();
  final auditRepository = await container.read(
    tokenAuditRepositoryProvider.future,
  );
  final snapshot = await auditRepository.buildSnapshot();

  return _JourneyResult(
    chapters: generatedChapters,
    chaptersWithNames: chaptersWithNames,
    deviationChecks: deviationChecks,
    snapshot: snapshot,
    minLength: minLength,
    maxLength: maxLength,
    averageLength: totalChars ~/ generatedChapters.length,
    totalChapters: generatedChapters.length,
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

Future<List<Chapter>> _createChapters(
  dynamic chapterRepository,
  String manuscriptId,
  int count,
) async {
  final chapters = <Chapter>[];
  for (var i = 1; i <= count; i++) {
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

Future<int> _runDeviationDetectionForAllChapters({
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
      debugPrint(
        '[ERROR] Deviation chapter ${i + 1}/${chapters.length} failed: ${_safeExceptionDiagnostic(e)}',
      );
      rethrow;
    }
  }
  debugPrint(
    '[DEVIATION] Warnings: $totalWarnings across ${chapters.length} chapters',
  );
  return chapters.length;
}

class _DeterministicJourneyAdapter implements AIAdapter {
  _DeterministicJourneyAdapter(this._fallback);

  final FakeAdapter _fallback;
  var _chapterIndex = 0;

  @override
  Stream<String> createStream({
    required String apiKey,
    required String baseUrl,
    required String model,
    required List<ChatMessage> messages,
    double? temperature,
    double? topP,
    int? maxTokens,
    void Function(Usage?)? onUsage,
  }) async* {
    final promptText = messages
        .map((message) => message.toJson()['content'])
        .join('\n');
    if (!promptText.contains('第') || !promptText.contains('林风')) {
      yield* _fallback.createStream(
        apiKey: apiKey,
        baseUrl: baseUrl,
        model: model,
        messages: messages,
        temperature: temperature,
        topP: topP,
        maxTokens: maxTokens,
        onUsage: onUsage,
      );
      return;
    }

    final response = _chapterText(_chapterIndex);
    _chapterIndex++;
    for (final codePoint in response.runes) {
      yield String.fromCharCode(codePoint);
    }
    onUsage?.call(_usage(promptText, response));
  }

  String _chapterText(int index) {
    final chapterNo = index + 1;
    final name =
        StoryOutline.characterNames[index % StoryOutline.characterNames.length];
    final plot = StoryOutline.chapters[index];
    final text =
        '第$chapterNo章，林风沿着青云宗山道前行，$name在旁提醒他莫忘清虚真人的告诫。$plot 他没有急着求成，而是先整理灵气、核对门规、记录白灵的反应，再把今日所见写入随身玉简。夜色落下时，苏雪晴递来一盏灵茶，赵天磊的目光从演武场另一侧扫过，新的冲突已经埋下。这一章保持凡人少年稳步成长的节奏，既写修炼压力，也写宗门人情，让知识库中的人物关系、境界限制和世界观禁忌自然进入叙事。林风明白每一次选择都会影响后续三十章的因果，因此他只推进一个明确目标，不越过作者亲自打磨的边界。清虚真人要求他每晚复盘战斗细节，把白日的得失化成下一次行动的依据。';
    return text.substring(0, min(420, text.length));
  }

  Usage _usage(String prompt, String response) {
    final promptTokens = prompt.replaceAll(RegExp(r'\s'), '').length * 2;
    final completionTokens = response.replaceAll(RegExp(r'\s'), '').length * 2;
    return Usage(
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalTokens: promptTokens + completionTokens,
    );
  }
}

class _JourneyResult {
  final List<Chapter> chapters;
  final int chaptersWithNames;
  final int deviationChecks;
  final dynamic snapshot;
  final int minLength;
  final int maxLength;
  final int averageLength;
  final int totalChapters;

  const _JourneyResult({
    required this.chapters,
    required this.chaptersWithNames,
    required this.deviationChecks,
    required this.snapshot,
    required this.minLength,
    required this.maxLength,
    required this.averageLength,
    required this.totalChapters,
  });
}
