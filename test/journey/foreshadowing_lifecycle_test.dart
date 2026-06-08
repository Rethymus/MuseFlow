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
import 'package:museflow/features/story_structure/application/foreshadowing_reminder_service.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'package:openai_dart/openai_dart.dart';

import '../automation/helpers/fake_adapter.dart';
import 'helpers/d11_bounds.dart';
import 'helpers/journey_container.dart';
import 'helpers/story_outline.dart';
import 'helpers/xianxia_fixtures.dart';

void main() {
  group('Foreshadowing lifecycle', () {
    late ProviderContainer container;

    setUp(() async {
      container = await createJourneyContainer(
        apiKey: 'journey-local-test-key',
        baseUrl: 'https://example.com/v1',
        model: 'fake-model',
        aiAdapter: _DeterministicForeshadowAdapter(FakeAdapter()),
      );
    });

    tearDown(() async {
      await cleanupJourneyContainer(container);
    });

    group('Foreshadowing creation', () {
      test('should create 4 foreshadowing entries', () async {
        final notifier = container.read(foreshadowingNotifierProvider.notifier);

        for (final entry in _foreshadowingEntries()) {
          await notifier.add(entry);
        }

        final entries = await container.read(foreshadowingNotifierProvider.future);
        expect(entries, hasLength(4));
        expect(
          entries.map((entry) => entry.status).toSet(),
          equals({ForeshadowingStatus.planted}),
        );
        expect(
          entries.map((entry) => entry.mode).toSet(),
          equals({ForeshadowingMode.detailed}),
        );
        expect(
          entries.map((entry) => entry.plantedChapter).toSet(),
          equals({3, 10, 20, 30}),
        );
        expect(
          entries.map((entry) => entry.targetResolutionChapter).toSet(),
          equals({90, 75, 85, 95}),
        );
      });
    });

    group('State transitions', () {
      test('should transition entries through planted-developing-resolved', () async {
        final resolvedEntries = await _runFullForeshadowingLifecycle(container);

        expect(resolvedEntries, hasLength(4));
        expect(
          resolvedEntries.map((entry) => entry.status).toSet(),
          equals({ForeshadowingStatus.resolved}),
        );
        expect(_entryById(resolvedEntries, 'fs-mysterious-origin').resolvedChapter, 92);
        expect(_entryById(resolvedEntries, 'fs-senior-sister-secret').resolvedChapter, 78);
        expect(_entryById(resolvedEntries, 'fs-forbidden-zone').resolvedChapter, 88);
        expect(_entryById(resolvedEntries, 'fs-ancient-artifact').resolvedChapter, 96);
      });
    });

    group('Cross-chapter tracking', () {
      test('should track 4 threads across 60 plus chapters per D-05', () async {
        final resolvedEntries = await _runFullForeshadowingLifecycle(container);
        final spans = resolvedEntries.map(
          (entry) => entry.resolvedChapter! - entry.plantedChapter,
        );

        expect(spans, everyElement(greaterThanOrEqualTo(60)));
        expect(
          resolvedEntries.map((entry) => entry.plantedChapter).toSet(),
          equals({3, 10, 20, 30}),
        );
        expect(
          resolvedEntries.map((entry) => entry.resolvedChapter).toSet(),
          equals({92, 78, 88, 96}),
        );
      });
    });

    group('Reminder service', () {
      test('should generate threshold overdue reminders at chapter 85', () async {
        final notifier = container.read(foreshadowingNotifierProvider.notifier);
        for (final entry in _foreshadowingEntries()) {
          await notifier.add(entry);
        }
        final entries = await container.read(foreshadowingNotifierProvider.future);
        final service = container.read(foreshadowingReminderServiceProvider);

        final reminders = service.findReminders(
          entries: entries,
          currentChapter: 85,
          defaultThreshold: 50,
        );
        final thresholdReminder = reminders.singleWhere(
          (reminder) => reminder.kind == ForeshadowingReminderKind.thresholdOverdue,
        );

        expect(thresholdReminder.count, greaterThanOrEqualTo(2));
        expect(thresholdReminder.entryIds, contains('fs-mysterious-origin'));
        expect(thresholdReminder.entryIds, contains('fs-senior-sister-secret'));
      });
    });

    group('Full lifecycle end state', () {
      test('should have all threads resolved by chapter 100', () async {
        final resolvedEntries = await _runFullForeshadowingLifecycle(container);

        expect(resolvedEntries, everyElement((ForeshadowingEntry entry) => entry.isResolved));
        expect(
          resolvedEntries.map((entry) => entry.resolvedChapter),
          everyElement(inInclusiveRange(75, 96)),
        );
        expect(
          resolvedEntries.map((entry) => entry.resolvedChapter),
          everyElement(lessThanOrEqualTo(100)),
        );
      });
    });

    group('Deviation detection', () {
      test('should run deviation detection across 100 chapters without errors', () async {
        await _setupSkills(container);
        final manuscriptRepository = await container.read(manuscriptRepositoryProvider.future);
        final chapterRepository = await container.read(chapterRepositoryProvider.future);
        final manuscript = await manuscriptRepository.add(
          Manuscript(
            id: 'ms-foreshadowing-deviation',
            title: '剑道苍穹',
            genre: '修仙',
            createdAt: DateTime(2026, 6, 8),
            updatedAt: DateTime(2026, 6, 8),
          ),
        );
        final chapters = await _createChapters(chapterRepository, manuscript.id);

        await _generateChapterContent(
          container: container,
          manuscript: manuscript,
          chapters: chapters,
        );
        final generatedChapters = chapterRepository.getByManuscriptId(manuscript.id);
        final totalWarnings = await _runDeviationDetection(
          container: container,
          manuscript: manuscript,
          chapters: generatedChapters,
        );

        expect(generatedChapters, hasLength(100));
        expect(totalWarnings, greaterThanOrEqualTo(100));
      });
    });
  });
}

List<ForeshadowingEntry> _foreshadowingEntries() {
  final createdAt = DateTime(2026, 6, 8);
  return [
    ForeshadowingEntry(
      id: 'fs-mysterious-origin',
      title: '神秘身世',
      mode: ForeshadowingMode.detailed,
      status: ForeshadowingStatus.planted,
      plantedChapter: 3,
      targetResolutionChapter: 90,
      sourceExcerpt: '林风身世不明，清虚真人对他格外关注',
      createdAt: createdAt,
    ),
    ForeshadowingEntry(
      id: 'fs-senior-sister-secret',
      title: '师姐的秘密',
      mode: ForeshadowingMode.detailed,
      status: ForeshadowingStatus.planted,
      plantedChapter: 10,
      targetResolutionChapter: 75,
      sourceExcerpt: '苏雪晴深夜独自前往禁地，行为可疑',
      createdAt: createdAt,
    ),
    ForeshadowingEntry(
      id: 'fs-forbidden-zone',
      title: '门派禁地',
      mode: ForeshadowingMode.detailed,
      status: ForeshadowingStatus.planted,
      plantedChapter: 20,
      targetResolutionChapter: 85,
      sourceExcerpt: '禁地深处传来异响，封印似乎在松动',
      createdAt: createdAt,
    ),
    ForeshadowingEntry(
      id: 'fs-ancient-artifact',
      title: '远古法器',
      mode: ForeshadowingMode.detailed,
      status: ForeshadowingStatus.planted,
      plantedChapter: 30,
      targetResolutionChapter: 95,
      sourceExcerpt: '林风发现玉简表面刻满古老符文，灵光隐隐',
      createdAt: createdAt,
    ),
  ];
}

Future<List<ForeshadowingEntry>> _runFullForeshadowingLifecycle(
  ProviderContainer container,
) async {
  final notifier = container.read(foreshadowingNotifierProvider.notifier);
  for (final entry in _foreshadowingEntries()) {
    await notifier.add(entry);
  }

  await _developAndResolve(
    container: container,
    id: 'fs-mysterious-origin',
    notes: '身世线索逐渐浮现',
    resolvedChapter: 92,
  );
  await _developAndResolve(
    container: container,
    id: 'fs-senior-sister-secret',
    notes: '苏雪晴的真实身份开始暴露',
    resolvedChapter: 78,
  );
  await _developAndResolve(
    container: container,
    id: 'fs-forbidden-zone',
    notes: '禁地封印出现裂痕',
    resolvedChapter: 88,
  );
  await _developAndResolve(
    container: container,
    id: 'fs-ancient-artifact',
    notes: '玉简灵光越来越强',
    resolvedChapter: 96,
  );

  return container.read(foreshadowingNotifierProvider.future);
}

Future<void> _developAndResolve({
  required ProviderContainer container,
  required String id,
  required String notes,
  required int resolvedChapter,
}) async {
  final notifier = container.read(foreshadowingNotifierProvider.notifier);
  final entries = await container.read(foreshadowingNotifierProvider.future);
  final entry = _entryById(entries, id);
  await notifier.save(
    entry.copyWith(
      status: ForeshadowingStatus.developing,
      notes: notes,
      updatedAt: DateTime(2026, 6, 8),
    ),
  );
  final developingEntries = await container.read(foreshadowingNotifierProvider.future);
  expect(_entryById(developingEntries, id).status, ForeshadowingStatus.developing);

  await notifier.markResolved(id, resolvedChapter: resolvedChapter);
  final resolvedEntries = await container.read(foreshadowingNotifierProvider.future);
  final resolvedEntry = _entryById(resolvedEntries, id);
  expect(resolvedEntry.status, ForeshadowingStatus.resolved);
  expect(resolvedEntry.resolvedChapter, resolvedChapter);
}

ForeshadowingEntry _entryById(List<ForeshadowingEntry> entries, String id) {
  return entries.singleWhere((entry) => entry.id == id);
}

class _DeterministicForeshadowAdapter implements AIAdapter {
  _DeterministicForeshadowAdapter(this._fallback);

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
    if (promptText.contains('设定一致性审校员')) {
      final response = _deviationWarnings();
      yield response;
      onUsage?.call(_usage(promptText, response));
      return;
    }
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
    final text = '第$chapterNo章，林风沿青云宗石阶缓步而上，$name在旁提醒他谨守门规。$plot 他先核对境界限制，再记录白灵的反应，并把清虚真人的叮嘱写入玉简。夜色落下时，苏雪晴送来灵茶，赵天磊从演武场另一侧望来，新的冲突埋下却不急于爆发。林风明白每章只推进一个目标，修炼、宗门人情和伏笔都要留给作者继续打磨，不能越过凡人本心。清虚真人要求他复盘今日得失，确认没有现代科技、越级法术或破坏门规的描写，让故事在百章尺度上保持稳定。';
    return text.substring(0, text.length < 430 ? text.length : 430);
  }

  String _deviationWarnings() {
    return '[{"description":"练气期能力边界需要复核","severity":"medium","skillName":"能力限制","suggestedFix":"确认当前章节境界后再描写法术"},{"description":"门派等级行为需要保持一致","severity":"medium","skillName":"门派等级森严","suggestedFix":"补充低阶弟子遵守门规的动作"}]';
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

Future<List<Chapter>> _createChapters(dynamic chapterRepository, String manuscriptId) async {
  final chapters = <Chapter>[];
  for (var i = 1; i <= 100; i++) {
    final plotPoint = StoryOutline.chapters[i - 1];
    final titleEnd = plotPoint.length < 10 ? plotPoint.length : 10;
    final chapter = await chapterRepository.add(
      Chapter(
        id: '',
        manuscriptId: manuscriptId,
        title: '第$i章 ${plotPoint.substring(0, titleEnd)}',
        sortOrder: i,
        documentContent: '',
        createdAt: DateTime(2026, 6, 8),
        updatedAt: DateTime(2026, 6, 8),
      ),
    );
    chapters.add(chapter);
  }
  return chapters;
}

Future<void> _setupSkills(ProviderContainer container) async {
  final skillRepo = await container.read(skillRepositoryProvider.future);
  for (final skill in XianxiaFixtures.skillRules()) {
    await skillRepo.add(skill);
  }
}

Future<void> _generateChapterContent({
  required ProviderContainer container,
  required Manuscript manuscript,
  required List<Chapter> chapters,
}) async {
  final pipeline = await container.read(promptPipelineProvider.future);
  final adapter = container.read(openaiAdapterProvider);
  final provider = container.read(activeProviderProvider)!;
  final key = container.read(activeApiKeyProvider)!;
  final chapterRepository = await container.read(chapterRepositoryProvider.future);

  for (var index = 0; index < chapters.length; index++) {
    final fragment = Fragment(
      id: 'foreshadow-frag-$index',
      text: StoryOutline.chapters[index],
      createdAt: DateTime(2026, 6, 8),
    );
    final context = PromptContext(fragments: [fragment], bannedPhrases: const []);
    final output = await adapter
        .createStream(
          apiKey: key,
          baseUrl: provider.baseUrl,
          model: provider.model,
          messages: pipeline.build(context),
        )
        .join();
    final boundedOutput = enforceD11Bounds(output);
    await chapterRepository.updateDocumentContent(chapters[index].id, boundedOutput);
    debugPrint('[FORESHADOWING] Chapter ${index + 1}/100 generated');
  }
}

Future<int> _runDeviationDetection({
  required ProviderContainer container,
  required Manuscript manuscript,
  required List<Chapter> chapters,
}) async {
  final deviationService = await container.read(deviationDetectionServiceProvider.future);
  final skillRepo = await container.read(skillRepositoryProvider.future);
  final activeSkills = skillRepo.getAll().where((skill) => skill.isActive).toList();
  expect(activeSkills, isA<List<SkillDocument>>());
  expect(activeSkills, isNotEmpty);

  var totalWarnings = 0;
  for (final chapter in chapters) {
    final result = await deviationService.detectDeviations(
      chapter.documentContent,
      activeSkills,
      manuscriptId: manuscript.id,
      chapterId: chapter.id,
    );
    totalWarnings += result.warnings.length;
  }
  return totalWarnings;
}
