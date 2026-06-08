import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/ai/domain/ai_adapter.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:museflow/features/stats/domain/stats_snapshot.dart';
import 'package:museflow/features/stats/infrastructure/token_audit_repository.dart';
import 'package:openai_dart/openai_dart.dart';

import '../automation/helpers/fake_adapter.dart';
import 'helpers/d11_bounds.dart';
import 'helpers/journey_container.dart';
import 'helpers/story_outline.dart';
import 'helpers/xianxia_fixtures.dart';

void main() {
  group('JOURNEY-10 statistics accuracy', () {
    test(
      'should have accurate word count for 100 generated chapters',
      () async {
        final container = await createJourneyContainer(
          apiKey: 'journey-local-test-key',
          baseUrl: 'https://example.com/v1',
          model: 'fake-model',
          aiAdapter: _DeterministicStatsAdapter(FakeAdapter()),
        );

        try {
          await _setupWorldBuilding(container);
          final startedAt = DateTime.now();
          final result = await _generateHundredChapterStatsJourney(
            container: container,
            manuscriptId: 'ms-statistics-accuracy',
          );
          final elapsed = DateTime.now().difference(startedAt);
          final writingSpeed =
              result.totalCharacters / max(1, elapsed.inMilliseconds) * 1000;

          expect(result.chapters, hasLength(100));
          expect(result.totalCharacters, inInclusiveRange(27000, 55000));
          expect(result.aiUsageRate, inInclusiveRange(0.95, 1.0));
          expect(writingSpeed, greaterThan(0));
          expect(result.statsSnapshot.totalUnits, greaterThan(0));
          expect(result.statsSnapshot.aiAssistRatio, inInclusiveRange(0.95, 1.0));
          expect(result.tokenAuditSnapshot.totalCalls, greaterThanOrEqualTo(100));
          expect(result.tokenAuditSnapshot.totalInputTokens, greaterThan(0));
          expect(result.tokenAuditSnapshot.totalOutputTokens, greaterThan(0));

          debugPrint(
            '[STATS] total=${result.totalCharacters}, '
            'min=${result.minLength}, max=${result.maxLength}, '
            'avg=${result.averageLength}, '
            'aiRate=${result.aiUsageRate.toStringAsFixed(3)}, '
            'speed=${writingSpeed.toStringAsFixed(2)} chars/sec',
          );
        } finally {
          await cleanupJourneyContainer(container);
        }
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}

Future<_StatsJourneyResult> _generateHundredChapterStatsJourney({
  required ProviderContainer container,
  required String manuscriptId,
}) async {
  final manuscriptRepository = await container.read(manuscriptRepositoryProvider.future);
  final chapterRepository = await container.read(chapterRepositoryProvider.future);
  final statsCollector = await container.read(writingStatsCollectorProvider.future);
  final auditService = await container.read(tokenAuditServiceProvider.future);
  final manuscript = await manuscriptRepository.add(
    Manuscript(
      id: manuscriptId,
      title: '剑道苍穹百章统计验证',
      genre: '修仙',
      createdAt: DateTime(2026, 6, 8),
      updatedAt: DateTime(2026, 6, 8),
    ),
  );
  final chapters = await _createHundredChapters(chapterRepository, manuscript.id);

  final pipeline = await container.read(promptPipelineProvider.future);
  final adapter = container.read(openaiAdapterProvider);
  final provider = container.read(activeProviderProvider)!;
  final key = container.read(activeApiKeyProvider)!;

  for (var index = 0; index < chapters.length; index++) {
    final fragment = Fragment(
      id: 'stats-frag-$index',
      text: StoryOutline.chapters[index],
      createdAt: DateTime.now(),
    );
    final context = PromptContext(fragments: [fragment], bannedPhrases: const []);
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
    statsCollector.recordAiInsertion(
      boundedOutput,
      projectId: manuscript.id,
      documentId: chapters[index].id,
    );
    await chapterRepository.updateDocumentContent(chapters[index].id, boundedOutput);
    debugPrint('[STATS] Chapter ${index + 1}/100 generated (${boundedOutput.length} chars)');
  }

  await auditService.flush();
  await statsCollector.flush();
  final auditRepository = await container.read(tokenAuditRepositoryProvider.future);
  final tokenAuditSnapshot = await auditRepository.buildSnapshot();
  _expectCompleteTokenAudit(tokenAuditSnapshot, expectedRecords: 100);
  container.invalidate(writingStatsNotifierProvider);
  final statsSnapshot = await container.read(writingStatsNotifierProvider.future);

  final generatedChapters = chapterRepository.getByManuscriptId(manuscript.id);
  expect(generatedChapters, hasLength(100));

  var totalCharacters = 0;
  var minLength = 1 << 30;
  var maxLength = 0;
  for (final chapter in generatedChapters) {
    final length = chapter.documentContent.length;
    expect(chapter.documentContent, isNotEmpty);
    expect(length, inInclusiveRange(300, 500));
    totalCharacters += length;
    minLength = min(minLength, length);
    maxLength = max(maxLength, length);
  }

  final aiUsageRate = statsSnapshot.aiAssistRatio;

  return _StatsJourneyResult(
    chapters: generatedChapters,
    statsSnapshot: statsSnapshot,
    tokenAuditSnapshot: tokenAuditSnapshot,
    totalCharacters: totalCharacters,
    minLength: minLength,
    maxLength: maxLength,
    averageLength: totalCharacters ~/ generatedChapters.length,
    aiUsageRate: aiUsageRate,
  );
}

void _expectCompleteTokenAudit(
  TokenAuditSnapshot snapshot, {
  required int expectedRecords,
}) {
  expect(snapshot.totalCalls, greaterThanOrEqualTo(expectedRecords));
  expect(snapshot.totalInputTokens, greaterThan(0));
  expect(snapshot.totalOutputTokens, greaterThan(0));
  expect(snapshot.records, hasLength(greaterThanOrEqualTo(expectedRecords)));

  for (final record in snapshot.records) {
    expect(
      record.inputTokens,
      greaterThan(0),
      reason: 'Record ${record.id} has zero input tokens',
    );
    expect(
      record.outputTokens,
      greaterThan(0),
      reason: 'Record ${record.id} has zero output tokens',
    );
    expect(
      record.operationType.name,
      isNotEmpty,
      reason: 'Record ${record.id} has empty operation type',
    );
    expect(record.timestamp, isNotNull);
  }

  debugPrint(
    '[AUDIT] calls=${snapshot.totalCalls}, '
    'input=${snapshot.totalInputTokens}, output=${snapshot.totalOutputTokens}',
  );
}

Future<List<Chapter>> _createHundredChapters(
  dynamic chapterRepository,
  String manuscriptId,
) async {
  final chapters = <Chapter>[];
  for (var index = 1; index <= 100; index++) {
    final plotPoint = StoryOutline.chapters[index - 1];
    final titleEnd = min(10, plotPoint.length);
    final chapter = await chapterRepository.add(
      Chapter(
        id: '',
        manuscriptId: manuscriptId,
        title: '第$index章 ${plotPoint.substring(0, titleEnd)}',
        sortOrder: index,
        documentContent: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    chapters.add(chapter);
  }
  return chapters;
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

  final characterRepository = await container.read(characterCardRepositoryProvider.future);
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
}

class _DeterministicStatsAdapter implements AIAdapter {
  _DeterministicStatsAdapter(this._fallback);

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
    final promptText = messages.map((message) => message.toJson()['content']).join('\n');
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
    final chapterNo = (index % StoryOutline.chapters.length) + 1;
    final name = StoryOutline.characterNames[index % StoryOutline.characterNames.length];
    final plot = StoryOutline.chapters[index % StoryOutline.chapters.length];
    final text = '第$chapterNo章，林风沿着青云宗山道前行，$name在旁提醒他莫忘清虚真人的告诫。$plot 他没有急着求成，而是先整理灵气、核对门规、记录白灵的反应，再把今日所见写入随身玉简。夜色落下时，苏雪晴递来一盏灵茶，赵天磊的目光从演武场另一侧扫过，新的冲突已经埋下。这一章保持凡人少年稳步成长的节奏，既写修炼压力，也写宗门人情，让知识库中的人物关系、境界限制和世界观禁忌自然进入叙事。林风明白每一次选择都会影响后续百章的因果，因此他只推进一个明确目标，不越过作者亲自打磨的边界。清虚真人要求他每晚复盘战斗细节，把白日的得失化成下一次行动的依据。';
    return text.substring(0, min(430, text.length));
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

class _StatsJourneyResult {
  const _StatsJourneyResult({
    required this.chapters,
    required this.statsSnapshot,
    required this.tokenAuditSnapshot,
    required this.totalCharacters,
    required this.minLength,
    required this.maxLength,
    required this.averageLength,
    required this.aiUsageRate,
  });

  final List<Chapter> chapters;
  final StatsSnapshot statsSnapshot;
  final TokenAuditSnapshot tokenAuditSnapshot;
  final int totalCharacters;
  final int minLength;
  final int maxLength;
  final int averageLength;
  final double aiUsageRate;
}
