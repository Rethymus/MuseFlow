// Long-form, real-GLM 100-chapter novel journey.
//
// Unlike `serial_generation_test.dart` (which caps output at 300–500 chars
// via the D-11 test harness bound), this generator produces 7000–9000
// Chinese-character chapters by composing multiple streamed calls per chapter
// (opening + continuations) through the real OpenAIAdapter, then runs every
// chapter through MuseFlow's full stack:
//   • AntiAIScentProcessor — deterministic 反 AI 味 post-processing
//   • DeviationDetectionService — Skill guardian consistency check
//   • ChapterSummarizationService — previous-chapter context for ch N+1
//   • ForeshadowingRepository — 12-thread lifecycle → fill-rate metric
//   • TokenAuditService — per-call usage accounting
//
// High-perf/low-cost model mix: glm-4-plus opens the key chapters listed in
// `kKeyChapters`; every other opening and all continuations use glm-4-flash.
//
// Outputs (written under docs/novel-journey/ only when GLM_API_KEY is set):
//   chapters/第NNN章-标题.md  — one Markdown file per generated chapter
//   metrics.json              — full run metrics for the README
//   progress.json             — running progress (updated per chapter)
//   errors.log                — per-chapter failures (does not abort the run)

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/application/anti_ai_scent_processor.dart';
import 'package:museflow/features/ai/domain/ai_adapter.dart';
import 'package:museflow/features/ai/domain/ai_exception.dart';
import 'package:museflow/features/knowledge/application/deviation_detection_service.dart';
import 'package:museflow/features/knowledge/domain/skill_document.dart';
import 'package:museflow/features/manuscript/application/chapter_summarization_service.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';
import 'package:museflow/features/manuscript/infrastructure/manuscript_repository.dart';
import 'package:museflow/features/stats/application/token_audit_service.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:museflow/features/stats/infrastructure/token_audit_repository.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'package:museflow/features/story_structure/infrastructure/foreshadowing_repository.dart';
import 'package:openai_dart/openai_dart.dart';

import 'helpers/journey_container.dart';
import 'helpers/long_novel_plan.dart';
import 'helpers/story_outline.dart';
import 'helpers/xianxia_fixtures.dart';

void main() {
  final apiKey = Platform.environment['GLM_API_KEY'];
  final baseUrl =
      Platform.environment['GLM_BASE_URL'] ??
      'https://open.bigmodel.cn/api/paas/v4';

  test(
    'long-novel GLM streaming smoke test',
    () async {
      final HttpOverrides? previous = HttpOverrides.current;
      HttpOverrides.global = null;
      try {
        final container = await createJourneyContainer(
          apiKey: apiKey!,
          baseUrl: baseUrl,
          model: kModelLow,
        );
        try {
          final adapter = container.read(openaiAdapterProvider);
          final buffer = StringBuffer();
          await for (final token in adapter.createStream(
            apiKey: apiKey,
            baseUrl: baseUrl,
            model: kModelLow,
            messages: [
              ChatMessage.system('你是一位中文小说家。'),
              ChatMessage.user('用一句话描写山间晨雾，要有画面感。'),
            ],
            maxTokens: 80,
          )) {
            buffer.write(token);
          }
          expect(buffer.toString(), isNotEmpty);
          debugPrint('[SMOKE] ${buffer.toString().length} chars OK');
        } finally {
          await cleanupJourneyContainer(container);
        }
      } finally {
        HttpOverrides.global = previous;
      }
    },
    skip: apiKey == null ? 'GLM_API_KEY not set' : null,
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test(
    'long-novel validation: 3 full-length chapters through the whole stack',
    () async {
      final HttpOverrides? previous = HttpOverrides.current;
      HttpOverrides.global = null;
      try {
        final container = await createJourneyContainer(
          apiKey: apiKey!,
          baseUrl: baseUrl,
          model: kModelLow,
        );
        try {
          final gen = _LongNovelGenerator(
            container: container,
            outputDir: 'docs/novel-journey',
            chapterCount: 3,
            manuscriptTitle: '剑道苍穹（3章验证）',
            manuscriptId: 'ms-long-validation',
          );
          final metrics = await gen.run();
          debugPrint(
            '[VALIDATION] chapters=${metrics.chapterCount} '
            'avgCjk=${metrics.avgCjkChars} '
            'wallClock=${metrics.wallClockSeconds}s '
            'tokens=${metrics.totalTokens}',
          );
          for (final c in metrics.chapters) {
            debugPrint(
              '[VALIDATION] 第${c.chapterNo}章 ${c.cjkChars}字 '
              '${c.segments}段 model=${c.openingModel} '
              'antiAi=${c.antiAiHighlights} dev=${c.deviationWarnings}',
            );
          }
          expect(metrics.chapterCount, 3);
          expect(metrics.totalCjkChars, greaterThan(15000));
        } finally {
          await cleanupJourneyContainer(container);
        }
      } finally {
        HttpOverrides.global = previous;
      }
    },
    skip: apiKey == null ? 'GLM_API_KEY not set' : null,
    timeout: const Timeout(Duration(minutes: 40)),
  );

  test(
    'long-novel full run: 100 chapters × 7000–9000 chars with real GLM',
    () async {
      final HttpOverrides? previous = HttpOverrides.current;
      HttpOverrides.global = null;
      try {
        final container = await createJourneyContainer(
          apiKey: apiKey!,
          baseUrl: baseUrl,
          model: kModelLow,
        );
        try {
          final gen = _LongNovelGenerator(
            container: container,
            outputDir: 'docs/novel-journey',
            chapterCount: 100,
            manuscriptTitle: '剑道苍穹',
            manuscriptId: 'ms-long-novel',
          );
          final metrics = await gen.run();
          debugPrint(
            '[FULL] chapters=${metrics.chapterCount} '
            'totalCjk=${metrics.totalCjkChars} '
            'avgCjk=${metrics.avgCjkChars} '
            'wallClock=${metrics.wallClockSeconds}s '
            'tokens=${metrics.totalTokens} '
            'foreshadowFill=${metrics.foreshadowingFillRate}',
          );
          expect(metrics.chapterCount, 100);
          expect(metrics.successCount, 100);
          expect(metrics.avgCjkChars, greaterThanOrEqualTo(6500));
        } finally {
          await cleanupJourneyContainer(container);
        }
      } finally {
        HttpOverrides.global = previous;
      }
    },
    skip: apiKey == null ? 'GLM_API_KEY not set' : null,
    // 100 chapters × ~6 streamed calls each, plus guardian + summary per
    // chapter, plus rate-limit pacing. Measured ceiling is many hours; allow
    // a wide overnight budget so an isolated run completes in one go.
    timeout: const Timeout(Duration(hours: 14)),
  );
}

// ---------------------------------------------------------------------------
// Generator
// ---------------------------------------------------------------------------

class _LongNovelGenerator {
  _LongNovelGenerator({
    required this.container,
    required this.outputDir,
    required this.chapterCount,
    required this.manuscriptTitle,
    required this.manuscriptId,
  });

  final ProviderContainer container;
  final String outputDir;
  final int chapterCount;
  final String manuscriptTitle;
  final String manuscriptId;

  late final AIAdapter _adapter;
  late final String _apiKey;
  late final String _baseUrl;
  late final ChapterRepository _chapterRepo;
  late final ManuscriptRepository _manuscriptRepo;
  late final TokenAuditService _auditService;
  late final TokenAuditRepository _auditRepo;
  late final DeviationDetectionService _deviationService;
  late final ChapterSummarizationService _summarizationService;
  late final ForeshadowingRepository _foreshadowRepo;
  late final AntiAIScentProcessor _antiAi;
  late final List<SkillDocument> _activeSkills;
  late final List<Chapter> _chapters;
  late final IOSink _errorLog;

  final List<String> _banned = AntiAIScentProcessor.synonymKeys;

  Future<_RunMetrics> run() async {
    _antiAi = AntiAIScentProcessor();
    _adapter = container.read(openaiAdapterProvider);
    final provider = container.read(activeProviderProvider)!;
    _apiKey = container.read(activeApiKeyProvider)!;
    _baseUrl = provider.baseUrl;
    _auditService = await container.read(tokenAuditServiceProvider.future);
    _auditRepo = await container.read(tokenAuditRepositoryProvider.future);
    _chapterRepo = await container.read(chapterRepositoryProvider.future);
    _manuscriptRepo = await container.read(manuscriptRepositoryProvider.future);
    // Construct the guardian service manually with the audit service injected
    // so consistency-check calls are recorded (the default provider wires it
    // without auditService, which would undercount token usage).
    _deviationService = DeviationDetectionService(
      openAIAdapter: _adapter,
      apiKey: _apiKey,
      baseUrl: _baseUrl,
      model: kModelLow,
      auditService: _auditService,
    );
    _foreshadowRepo = await container.read(
      foreshadowingRepositoryProvider.future,
    );
    _summarizationService = ChapterSummarizationService(
      openAIAdapter: _adapter,
      apiKey: _apiKey,
      baseUrl: _baseUrl,
      model: kModelLow,
    );

    Directory(outputDir).createSync(recursive: true);
    Directory('$outputDir/chapters').createSync(recursive: true);
    _errorLog = File('$outputDir/errors.log').openWrite();

    await _setupWorld();
    _activeSkills = await _loadActiveSkills();
    _chapters = await _createChapters();

    final chapterResults = <_ChapterResult>[];
    String? prevSummary;
    final sw = Stopwatch()..start();

    for (var i = 0; i < chapterCount; i++) {
      final chapterNo = i + 1;
      _plantForeshadowingAt(chapterNo);
      try {
        final contextChain = _buildContextChain(chapterResults);
        final result = await _generateChapter(
          index: i,
          chapterNo: chapterNo,
          prevSummary: prevSummary,
          contextChain: contextChain,
        );
        chapterResults.add(result);
        prevSummary = result.summary ?? prevSummary;
        _resolveForeshadowingAt(chapterNo);
        debugPrint(
          '[JOURNEY] 第$chapterNo章/$chapterCount '
          '${result.cjkChars}字（去标点）· '
          '${result.segments}段 · ${result.openingModel} · '
          '${result.elapsedSeconds}s · '
          '反AI味=${result.antiAiHighlights} 守护=${result.deviationWarnings}',
        );
      } catch (e, st) {
        _errorLog.writeln('第$chapterNo章 失败: $e\n$st');
        debugPrint('[ERROR] 第$chapterNo章 failed: $e');
      }
      _writeProgress(chapterNo, chapterResults, sw.elapsed);
      // Polite pacing between chapters to respect GLM rate limits.
      if (i < chapterCount - 1) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
    sw.stop();
    await _auditService.flush();
    await _errorLog.flush();
    await _errorLog.close();

    final metrics = await _assembleMetrics(chapterResults, sw.elapsed);
    await _writeMetricsFile(metrics);
    await _writeForeshadowingFile();
    return metrics;
  }

  // -- world / chapter setup ------------------------------------------------

  Future<void> _setupWorld() async {
    final templateRepo = container.read(worldTemplateRepositoryProvider);
    final template = await templateRepo.getById('male-xianxia-sect');
    if (template == null) {
      throw StateError('xianxia template missing');
    }
    final instantiationService = await container.read(
      templateInstantiationServiceProvider.future,
    );
    final draft = instantiationService.createDraft(
      template,
      storyConcept: '凡人少年林风入门修仙',
    );
    await instantiationService.saveDraft(draft);

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
    container.read(nameIndexServiceProvider.notifier).refresh();
  }

  Future<List<SkillDocument>> _loadActiveSkills() async {
    final skillRepo = await container.read(skillRepositoryProvider.future);
    for (final skill in XianxiaFixtures.skillRules()) {
      await skillRepo.add(skill);
    }
    return skillRepo.getAll().where((s) => s.isActive).toList();
  }

  Future<List<Chapter>> _createChapters() async {
    await _manuscriptRepo.add(
      Manuscript(
        id: manuscriptId,
        title: manuscriptTitle,
        genre: '修仙',
        targetWordCount: 800000,
        createdAt: DateTime(2026, 7, 7),
        updatedAt: DateTime(2026, 7, 7),
      ),
    );
    final chapters = <Chapter>[];
    for (var i = 1; i <= chapterCount; i++) {
      final beat = StoryOutline.chapters[i - 1];
      final title = chapterTitleFromBeat(beat);
      final chapter = await _chapterRepo.add(
        Chapter(
          id: '',
          manuscriptId: manuscriptId,
          title: title,
          sortOrder: i,
          documentContent: '',
          createdAt: DateTime(2026, 7, 7),
          updatedAt: DateTime(2026, 7, 7),
        ),
      );
      chapters.add(chapter);
    }
    return chapters;
  }

  // -- per-chapter generation ----------------------------------------------

  Future<_ChapterResult> _generateChapter({
    required int index,
    required int chapterNo,
    required String? prevSummary,
    required String? contextChain,
  }) async {
    final beat = StoryOutline.chapters[index];
    final title = chapterTitleFromBeat(beat);
    final chapter = _chapters[index];
    final openModel = openingModelFor(chapterNo);
    final sw = Stopwatch()..start();

    final openMessages = _openingMessages(
      chapterNo,
      title,
      beat,
      prevSummary,
      contextChain,
    );
    final open = await _generate(
      messages: openMessages,
      model: openModel,
      maxTokens: 4096,
      op: AuditOperationType.opening,
      chapterId: chapter.id,
      temperature: 0.88,
    );
    var text = open.text;
    var segments = 1;
    final callLog = <String, int>{openModel: 1};

    // Continuations until the CJK-char floor is met. Target the 7000 floor
    // directly (the per-segment length floor above means 4–5 segments land in
    // 7000–8500), keeping the full 100-chapter run inside the time budget.
    while (cjkCharCount(text) < 7000 && segments < 5) {
      segments++;
      final tail = text.length > 1500 ? text.substring(text.length - 1500) : text;
      final contMessages = _continuationMessages(chapterNo, title, beat, tail, segments);
      final cont = await _generate(
        messages: contMessages,
        model: kModelLow,
        maxTokens: 4096,
        op: AuditOperationType.expand,
        chapterId: chapter.id,
        temperature: 0.82,
      );
      text += cont.text;
      callLog[kModelLow] = (callLog[kModelLow] ?? 0) + 1;
    }

    final raw = trimToCjkRange(text);
    final rawCjk = cjkCharCount(raw);

    // Anti-AI-scent: deterministic clean + collect review signals.
    final ai = _antiAi.process(raw, bannedPhrases: _banned);
    final clean = _normalizePunctuation(_stripMarkers(ai.processedText));
    final cleanCjk = cjkCharCount(clean);

    await _chapterRepo.updateDocumentContent(chapter.id, clean);
    final fresh = _chapterRepo.getById(chapter.id)!;

    // Skill guardian consistency check (records its own audit).
    int deviationWarnings = 0;
    try {
      final dev = await _deviationService.detectDeviations(
        clean,
        _activeSkills,
        manuscriptId: manuscriptId,
        chapterId: chapter.id,
      );
      deviationWarnings = dev.warnings.length;
    } catch (e) {
      _errorLog.writeln('第$chapterNo章 守护检测失败: $e');
    }

    // Chapter summary for next-chapter context. ChapterSummarizationService
    // does not record audit, so estimate tokens via the same fallback the
    // audit service uses (char-based).
    String? summary;
    try {
      final s = await _summarizationService.summarize(fresh);
      summary = s.summary;
      _auditService.recordAudit(
        usage: null,
        modelName: kModelLow,
        operationType: AuditOperationType.synthesis,
        manuscriptId: manuscriptId,
        chapterId: chapter.id,
        inputText: clean,
        outputText: summary,
      );
    } catch (e) {
      _errorLog.writeln('第$chapterNo章 摘要失败: $e');
    }

    sw.stop();
    await _writeChapterFile(chapterNo, title, clean, beat);

    return _ChapterResult(
      chapterNo: chapterNo,
      title: title,
      content: clean,
      cjkChars: cleanCjk,
      rawCjkChars: rawCjk,
      segments: segments,
      openingModel: openModel,
      elapsedSeconds: sw.elapsed.inSeconds,
      antiAiHighlights: ai.highlights.length,
      antiAiAutoReplaced: ai.highlights
          .where((h) => h.type == HighlightType.bannedWord)
          .length,
      antiAiSignals: ai.reviewSignals
          .map((s) => {'title': s.title, 'severity': s.severity.name})
          .toList(),
      deviationWarnings: deviationWarnings,
      summary: summary,
      callLog: callLog,
    );
  }

  Future<({String text, int inputTokens, int outputTokens})> _generate({
    required List<ChatMessage> messages,
    required String model,
    required int maxTokens,
    required AuditOperationType op,
    required String chapterId,
    double temperature = 0.85,
  }) async {
    final inputText = messages.map(_messageContent).join('\n');
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        Usage? usage;
        final buffer = StringBuffer();
        await for (final token in _adapter.createStream(
          apiKey: _apiKey,
          baseUrl: _baseUrl,
          model: model,
          messages: messages,
          temperature: temperature,
          maxTokens: maxTokens,
          onUsage: (u) => usage = u,
        )) {
          buffer.write(token);
        }
        final output = buffer.toString();
        final inputTokens = usage?.promptTokens ?? (inputText.length * 2);
        final outputTokens = usage?.completionTokens ?? (output.length * 2);
        _auditService.recordAudit(
          usage: usage,
          modelName: model,
          operationType: op,
          manuscriptId: manuscriptId,
          chapterId: chapterId,
          inputText: inputText,
          outputText: output,
        );
        return (text: output, inputTokens: inputTokens, outputTokens: outputTokens);
      } catch (e) {
        if (attempt >= 3 || !_isTransient(e)) rethrow;
        final backoff = const Duration(seconds: 5) * attempt;
        debugPrint(
          '[RETRY] $model/$op attempt $attempt failed ($e); '
          'backing off ${backoff.inSeconds}s',
        );
        await Future<void>.delayed(backoff);
      }
    }
  }

  bool _isTransient(Object e) {
    if (e is AIRateLimitException) return true;
    if (e is AINetworkException) return true;
    // Be lenient: any non-auth network-ish failure is worth one retry.
    if (e is AIAuthException) return false;
    return e.toString().contains('429') ||
        e.toString().contains('Socket') ||
        e.toString().contains('Timeout');
  }

  // -- prompt builders ------------------------------------------------------

  List<ChatMessage> _openingMessages(
    int chapterNo,
    String title,
    String beat,
    String? prevSummary,
    String? contextChain,
  ) {
    final sys = [
      kWriterPersona,
      '',
      kWorldContext,
      '',
      if (prevSummary != null && prevSummary.isNotEmpty)
        '【上一章概要】$prevSummary'
      else
        '【上一章概要】（本章为开篇或独立章节，无前文）',
      if (contextChain != null && contextChain.isNotEmpty)
        '【前序脉络】$contextChain',
      '',
      '【禁用词清单（出现即视为AI腔，须回避或以更自然表达替代）】'
          '${_banned.take(90).join('、')}',
    ].join('\n');
    final user = '【本章】《剑道苍穹》第$chapterNo章 $title\n'
        '【剧情要点】$beat\n\n'
        '${kSegmentHints[1]!}$kLengthFloor';
    return [ChatMessage.system(sys), ChatMessage.user(user)];
  }

  List<ChatMessage> _continuationMessages(
    int chapterNo,
    String title,
    String beat,
    String textTail,
    int segNo,
  ) {
    final sys = '$kWriterPersona\n\n$kWorldContext';
    final hint = kSegmentHints[segNo] ?? kSegmentHints[4]!;
    final user = '【本章】《剑道苍穹》第$chapterNo章 $title\n'
        '【剧情要点】$beat\n'
        '【已写正文结尾】\n"""\n$textTail\n"""\n\n'
        '$hint$kLengthFloor';
    return [ChatMessage.system(sys), ChatMessage.user(user)];
  }

  String _buildContextChain(List<_ChapterResult> done) {
    if (done.isEmpty) return '';
    final last = <String>[];
    for (var i = done.length - 1; i >= 0 && last.length < 3; i--) {
      final s = done[i].summary;
      if (s != null && s.isNotEmpty) last.add('第${done[i].chapterNo}章：$s');
    }
    return last.reversed.join('；');
  }

  // -- foreshadowing lifecycle ---------------------------------------------

  void _plantForeshadowingAt(int chapterNo) {
    for (final t in kForeshadowingThreads) {
      if (t.plantedChapter == chapterNo) {
        _foreshadowRepo.add(
          ForeshadowingEntry(
            id: t.id,
            title: t.title,
            mode: ForeshadowingMode.detailed,
            status: ForeshadowingStatus.planted,
            plantedChapter: t.plantedChapter,
            targetResolutionChapter: t.resolveChapter,
            sourceExcerpt: t.sourceExcerpt,
            createdAt: DateTime(2026, 7, 7),
          ),
        );
      }
    }
  }

  void _resolveForeshadowingAt(int chapterNo) {
    for (final t in kForeshadowingThreads) {
      if (t.resolveChapter == chapterNo) {
        final e = _foreshadowRepo.getById(t.id);
        if (e != null) {
          _foreshadowRepo.update(
            e.copyWith(
              status: ForeshadowingStatus.resolved,
              resolvedChapter: chapterNo,
            ),
          );
        }
      }
    }
  }

  // -- file output ----------------------------------------------------------

  Future<void> _writeChapterFile(
    int chapterNo,
    String title,
    String content,
    String beat,
  ) async {
    final padded = chapterNo.toString().padLeft(3, '0');
    // title carries a "第N章 名称" prefix from the outline beat; strip it for
    // the filename so we don't get "第001章-第1章 …" redundancy.
    final nameOnly = title.replaceFirst(RegExp(r'^第\d+章\s*'), '');
    final safe = (nameOnly.isEmpty ? title : nameOnly)
        .replaceAll(RegExp(r'[/\\:*?"<>|]'), '');
    final file = File('$outputDir/chapters/第$padded章-$safe.md');
    final body = '# $title\n\n$content\n';
    await file.writeAsString(body);
  }

  void _writeProgress(
    int chapterNo,
    List<_ChapterResult> done,
    Duration elapsed,
  ) {
    final map = <String, dynamic>{
      'lastChapter': chapterNo,
      'completed': done.length,
      'total': chapterCount,
      'elapsedSeconds': elapsed.inSeconds,
      'lastTitle': done.isEmpty ? '' : done.last.title,
      'lastCjkChars': done.isEmpty ? 0 : done.last.cjkChars,
    };
    File('$outputDir/progress.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(map),
    );
  }

  Future<_RunMetrics> _assembleMetrics(
    List<_ChapterResult> done,
    Duration elapsed,
  ) async {
    final totalCjk = done.fold<int>(0, (a, c) => a + c.cjkChars);
    final minCjk = done.isEmpty
        ? 0
        : done.map((c) => c.cjkChars).reduce((a, b) => a < b ? a : b);
    final maxCjk = done.isEmpty
        ? 0
        : done.map((c) => c.cjkChars).reduce((a, b) => a > b ? a : b);
    final totalHighlights = done.fold<int>(0, (a, c) => a + c.antiAiHighlights);
    final totalAuto = done.fold<int>(0, (a, c) => a + c.antiAiAutoReplaced);
    final totalDev = done.fold<int>(0, (a, c) => a + c.deviationWarnings);

    final signalCounts = <String, int>{};
    for (final c in done) {
      for (final s in c.antiAiSignals) {
        final t = s['title'] as String;
        signalCounts[t] = (signalCounts[t] ?? 0) + 1;
      }
    }
    final topSignals = signalCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Snapshot = authoritative totals; records = exact per-model/per-op split.
    final snapshot = await _auditRepo.buildSnapshot();
    final records = await _auditRepo.loadAll();
    final byModel = <String, Map<String, int>>{};
    final byOp = <String, Map<String, int>>{};
    void tally(Map<String, Map<String, int>> bag, String key, int input, int output) {
      bag.putIfAbsent(key, () => {'calls': 0, 'input': 0, 'output': 0});
      bag[key]!['calls'] = bag[key]!['calls']! + 1;
      bag[key]!['input'] = bag[key]!['input']! + input;
      bag[key]!['output'] = bag[key]!['output']! + output;
    }
    for (final r in records) {
      tally(byModel, r.modelName, r.inputTokens, r.outputTokens);
      tally(byOp, r.operationType.name, r.inputTokens, r.outputTokens);
    }

    final allThreads = _foreshadowRepo.getAll();
    final plantedCount = allThreads.length;
    final resolved = allThreads
        .where((e) => e.status == ForeshadowingStatus.resolved)
        .toList();
    final fillRate = plantedCount == 0 ? 0.0 : resolved.length / plantedCount;
    final avgResolve = resolved.isEmpty
        ? 0.0
        : resolved
              .map(
                (e) =>
                    (e.resolvedChapter ?? e.plantedChapter) - e.plantedChapter,
              )
              .reduce((a, b) => a + b) /
            resolved.length;

    return _RunMetrics(
      chapterCount: done.length,
      successCount: done.length,
      totalCjkChars: totalCjk,
      avgCjkChars: done.isEmpty ? 0 : totalCjk ~/ done.length,
      minCjkChars: minCjk,
      maxCjkChars: maxCjk,
      wallClockSeconds: elapsed.inSeconds,
      totalTokens: snapshot.totalInputTokens + snapshot.totalOutputTokens,
      totalInputTokens: snapshot.totalInputTokens,
      totalOutputTokens: snapshot.totalOutputTokens,
      totalCalls: snapshot.totalCalls,
      tokensByModel: byModel,
      tokensByOperation: byOp,
      antiAiHighlights: totalHighlights,
      antiAiAutoReplaced: totalAuto,
      antiAiTopSignals: topSignals
          .map((e) => {'signal': e.key, 'count': e.value})
          .toList(),
      deviationWarnings: totalDev,
      foreshadowingPlanted: plantedCount,
      foreshadowingResolved: resolved.length,
      foreshadowingFillRate: fillRate,
      foreshadowingAvgChaptersToResolve: avgResolve,
      chapters: done,
    );
  }

  Future<void> _writeMetricsFile(_RunMetrics m) async {
    final encoder = const JsonEncoder.withIndent('  ');
    final map = <String, dynamic>{
      'generatedAt': DateTime.now().toIso8601String(),
      'manuscriptTitle': manuscriptTitle,
      'targetChapterCount': chapterCount,
      'chapterCount': m.chapterCount,
      'successCount': m.successCount,
      'length': {
        'totalCjkChars': m.totalCjkChars,
        'avgCjkCharsPerChapter': m.avgCjkChars,
        'minCjkChars': m.minCjkChars,
        'maxCjkChars': m.maxCjkChars,
      },
      'timing': {
        'wallClockSeconds': m.wallClockSeconds,
        'wallClockHuman': _humanDuration(m.wallClockSeconds),
        'avgSecondsPerChapter': m.chapterCount == 0
            ? 0
            : (m.wallClockSeconds / m.chapterCount).toStringAsFixed(1),
      },
      'tokens': {
        'total': m.totalTokens,
        'input': m.totalInputTokens,
        'output': m.totalOutputTokens,
        'totalCalls': m.totalCalls,
        'byModel': m.tokensByModel,
        'byOperation': m.tokensByOperation,
      },
      'antiAi': {
        'totalHighlights': m.antiAiHighlights,
        'totalAutoReplaced': m.antiAiAutoReplaced,
        'topSignals': m.antiAiTopSignals,
      },
      'deviation': {'totalWarnings': m.deviationWarnings},
      'foreshadowing': {
        'planted': m.foreshadowingPlanted,
        'resolved': m.foreshadowingResolved,
        'fillRate': m.foreshadowingFillRate.toStringAsFixed(3),
        'avgChaptersToResolve': m.foreshadowingAvgChaptersToResolve.toStringAsFixed(1),
      },
      'modelStrategy': {
        'highPerf': kModelHigh,
        'lowCost': kModelLow,
        'keyChaptersOpenedWithHighPerf': kKeyChapters.toList()..sort(),
      },
      'chapters': m.chapters
          .map((c) => {
                'chapterNo': c.chapterNo,
                'title': c.title,
                'cjkChars': c.cjkChars,
                'segments': c.segments,
                'openingModel': c.openingModel,
                'elapsedSeconds': c.elapsedSeconds,
                'antiAiHighlights': c.antiAiHighlights,
                'deviationWarnings': c.deviationWarnings,
              })
          .toList(),
    };
    await File('$outputDir/metrics.json').writeAsString(encoder.convert(map));
  }

  Future<void> _writeForeshadowingFile() async {
    final all = _foreshadowRepo.getAll();
    final encoder = const JsonEncoder.withIndent('  ');
    final map = all
        .map((e) => {
              'id': e.id,
              'title': e.title,
              'status': e.status.name,
              'plantedChapter': e.plantedChapter,
              'resolvedChapter': e.resolvedChapter,
              'sourceExcerpt': e.sourceExcerpt,
            })
        .toList();
    await File('$outputDir/foreshadowing.json').writeAsString(encoder.convert(map));
  }

  // -- small helpers --------------------------------------------------------

  String _stripMarkers(String text) =>
      text.replaceAllMapped(RegExp(r'【(.*?)】'), (m) => m.group(1) ?? '').trim();

  /// Collapses stray punctuation artifacts the model occasionally emits
  /// (e.g. "，。" from a clipped segment) without touching prose.
  String _normalizePunctuation(String text) {
    return text
        .replaceAll('，。', '。')
        .replaceAll('。，', '。')
        .replaceAll('；。', '。')
        .replaceAll(RegExp(r'。{2,}'), '。')
        .replaceAll(RegExp(r'，{2,}'), '，')
        .replaceAll(RegExp(r'\s+\n'), '\n')
        .trim();
  }

  static String _messageContent(ChatMessage m) {
    final c = m.toJson()['content'];
    if (c is String) return c;
    if (c is List) {
      return c
          .map((e) => e is Map ? (e['text'] ?? '').toString() : e.toString())
          .join();
    }
    return c?.toString() ?? '';
  }

  static String _humanDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h${m}m${s}s';
    if (m > 0) return '${m}m${s}s';
    return '${s}s';
  }
}

// ---------------------------------------------------------------------------
// Result types
// ---------------------------------------------------------------------------

class _ChapterResult {
  const _ChapterResult({
    required this.chapterNo,
    required this.title,
    required this.content,
    required this.cjkChars,
    required this.rawCjkChars,
    required this.segments,
    required this.openingModel,
    required this.elapsedSeconds,
    required this.antiAiHighlights,
    required this.antiAiAutoReplaced,
    required this.antiAiSignals,
    required this.deviationWarnings,
    required this.summary,
    required this.callLog,
  });

  final int chapterNo;
  final String title;
  final String content;
  final int cjkChars;
  final int rawCjkChars;
  final int segments;
  final String openingModel;
  final int elapsedSeconds;
  final int antiAiHighlights;
  final int antiAiAutoReplaced;
  final List<Map<String, String>> antiAiSignals;
  final int deviationWarnings;
  final String? summary;
  final Map<String, int> callLog;
}

class _RunMetrics {
  const _RunMetrics({
    required this.chapterCount,
    required this.successCount,
    required this.totalCjkChars,
    required this.avgCjkChars,
    required this.minCjkChars,
    required this.maxCjkChars,
    required this.wallClockSeconds,
    required this.totalTokens,
    required this.totalInputTokens,
    required this.totalOutputTokens,
    required this.totalCalls,
    required this.tokensByModel,
    required this.tokensByOperation,
    required this.antiAiHighlights,
    required this.antiAiAutoReplaced,
    required this.antiAiTopSignals,
    required this.deviationWarnings,
    required this.foreshadowingPlanted,
    required this.foreshadowingResolved,
    required this.foreshadowingFillRate,
    required this.foreshadowingAvgChaptersToResolve,
    required this.chapters,
  });

  final int chapterCount;
  final int successCount;
  final int totalCjkChars;
  final int avgCjkChars;
  final int minCjkChars;
  final int maxCjkChars;
  final int wallClockSeconds;
  final int totalTokens;
  final int totalInputTokens;
  final int totalOutputTokens;
  final int totalCalls;
  final Map<String, Map<String, int>> tokensByModel;
  final Map<String, Map<String, int>> tokensByOperation;
  final int antiAiHighlights;
  final int antiAiAutoReplaced;
  final List<Map<String, Object>> antiAiTopSignals;
  final int deviationWarnings;
  final int foreshadowingPlanted;
  final int foreshadowingResolved;
  final double foreshadowingFillRate;
  final double foreshadowingAvgChaptersToResolve;
  final List<_ChapterResult> chapters;
}
