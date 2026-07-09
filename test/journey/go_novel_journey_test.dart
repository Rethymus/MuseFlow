// 围棋题材《俗手》—— 真实 GLM 百章长篇生成 journey。
//
// 与修仙版 long_novel_journey_test.dart 平行，但：
//   • 题材：2022 新高考Ⅰ卷围棋题（本手/妙手/俗手），现代奇诡喜剧＋冷幽默＋
//     打破第四面墙，刻意避开修仙。
//   • 输出：docs/novel-go/（不覆盖修仙版 docs/novel-journey/ 展示）。
//   • 可恢复：每章落盘 .md + summaries.json + chapters_metrics.jsonl；重跑时
//     跳过已达标（CJK≥6500）章节，从 summaries.json 重建上下文链。10h 任务
//     可跨中断分批完成（GO_START / GO_END 环境变量控制范围）。
//
// 每章走 MuseFlow 全栈：AntiAIScentProcessor → DeviationDetectionService（围棋
// Skill 守护）→ ChapterSummarizationService → Foreshadowing 12线 → TokenAudit。
//
// 输出（仅当 GLM_API_KEY 设置时写入 docs/novel-go/）：
//   chapters/第NNN章-标题.md  · metrics.json · progress.json · summaries.json
//   chapters_metrics.jsonl    · foreshadowing.json · errors.log

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

import 'helpers/go_fixtures.dart';
import 'helpers/go_novel_plan.dart';
import 'helpers/go_outline.dart';
import 'helpers/journey_container.dart';

const String _kOutputDir = 'docs/novel-go';
const String _kManuscriptTitle = '俗手';
const String _kManuscriptId = 'ms-go-novel';
const int _kFullChapterCount = 100;
const int _kResumeFloor = 6500; // 已落盘章节 CJK≥此值则跳过（可恢复）

void main() {
  final apiKey = Platform.environment['GLM_API_KEY'];
  final baseUrl =
      Platform.environment['GLM_BASE_URL'] ??
      'https://open.bigmodel.cn/api/paas/v4';

  test(
    'go-novel GLM streaming smoke test',
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
              ChatMessage.system('你是一位风格凌厉的中文小说家。'),
              ChatMessage.user('用一句话写棋子落盘的声音，要有冷幽默与人味，只输出这一句。'),
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
    'go-novel validation: 3 chapters through the whole stack',
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
          final gen = _GoNovelGenerator(
            container: container,
            outputDir: _kOutputDir,
            startChapter: 1,
            endChapter: 3,
          );
          final metrics = await gen.run();
          debugPrint(
            '[VALIDATION] chapters=${metrics.chapterCount} '
            'avgCjk=${metrics.avgCjkChars} wallClock=${metrics.wallClockSeconds}s '
            'tokens=${metrics.totalTokens}',
          );
          for (final c in metrics.chapters) {
            debugPrint(
              '[VALIDATION] 第${c.chapterNo}章 ${c.cjkChars}字 ${c.segments}段 '
              'model=${c.openingModel} antiAi=${c.antiAiHighlights} '
              'dev=${c.deviationWarnings}',
            );
          }
          expect(metrics.chapterCount, greaterThan(0));
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
    'go-novel full run: ~100 chapters × 7000–9000 chars with real GLM',
    () async {
      final start = int.parse(Platform.environment['GO_START'] ?? '1');
      final end = int.parse(
        Platform.environment['GO_END'] ?? _kFullChapterCount.toString(),
      );
      final HttpOverrides? previous = HttpOverrides.current;
      HttpOverrides.global = null;
      try {
        final container = await createJourneyContainer(
          apiKey: apiKey!,
          baseUrl: baseUrl,
          model: kModelLow,
        );
        try {
          final gen = _GoNovelGenerator(
            container: container,
            outputDir: _kOutputDir,
            startChapter: start,
            endChapter: end,
          );
          final metrics = await gen.run();
          debugPrint(
            '[FULL] chapters=${metrics.chapterCount} '
            'totalCjk=${metrics.totalCjkChars} avgCjk=${metrics.avgCjkChars} '
            'wallClock=${metrics.wallClockSeconds}s tokens=${metrics.totalTokens} '
            'foreshadowFill=${metrics.foreshadowingFillRate}',
          );
          expect(metrics.chapterCount, greaterThan(0));
        } finally {
          await cleanupJourneyContainer(container);
        }
      } finally {
        HttpOverrides.global = previous;
      }
    },
    skip: apiKey == null ? 'GLM_API_KEY not set' : null,
    // 百章 × ~6 流式调用 + 守护 + 摘要 + 限速。实测以小时计；给宽裕预算。
    timeout: const Timeout(Duration(hours: 14)),
  );
}

// ---------------------------------------------------------------------------
// Generator
// ---------------------------------------------------------------------------

class _GoNovelGenerator {
  _GoNovelGenerator({
    required this.container,
    required this.outputDir,
    required this.startChapter,
    required this.endChapter,
  });

  final ProviderContainer container;
  final String outputDir;
  final int startChapter;
  final int endChapter;

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
  late final IOSink _errorLog;

  /// 跨 run 持久化的章节摘要（chapterNo -> summary），用于可恢复重建上下文链。
  final Map<int, String> _summaries = {};

  final List<String> _banned = AntiAIScentProcessor.synonymKeys;

  Future<_GoRunMetrics> run() async {
    _antiAi = AntiAIScentProcessor();
    _adapter = container.read(openaiAdapterProvider);
    final provider = container.read(activeProviderProvider)!;
    _apiKey = container.read(activeApiKeyProvider)!;
    _baseUrl = provider.baseUrl;
    _auditService = await container.read(tokenAuditServiceProvider.future);
    _auditRepo = await container.read(tokenAuditRepositoryProvider.future);
    _chapterRepo = await container.read(chapterRepositoryProvider.future);
    _manuscriptRepo = await container.read(manuscriptRepositoryProvider.future);
    // 手动构造守护服务并注入 audit，使一致性检查的 token 也被记录。
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
    _errorLog = File('$outputDir/errors.log').openWrite(mode: FileMode.append);

    await _setupWorld();
    _activeSkills = await _loadActiveSkills();
    _loadSummaries(); // 可恢复：从 summaries.json 重建上下文链
    final chapters = await _createOrSyncChapters();

    final chapterResults = <_GoChapterResult>[];
    final sw = Stopwatch()..start();

    for (var chapterNo = startChapter; chapterNo <= endChapter; chapterNo++) {
      _plantForeshadowingAt(chapterNo);
      try {
        // 可恢复：已达标章节直接跳过（仅汇总其落盘指标）。
        final existing = _readExistingChapter(chapterNo);
        if (existing != null) {
          chapterResults.add(existing);
          _resolveForeshadowingAt(chapterNo);
          debugPrint('[SKIP] 第$chapterNo章 已存在 ${existing.cjkChars}字，跳过');
          continue;
        }
        final prevSummary = _summaries[chapterNo - 1];
        final contextChain = _buildContextChain(chapterNo);
        final result = await _generateChapter(
          chapter: chapters[chapterNo - 1],
          chapterNo: chapterNo,
          prevSummary: prevSummary,
          contextChain: contextChain,
        );
        chapterResults.add(result);
        if (result.summary != null) {
          _summaries[chapterNo] = result.summary!;
        }
        _resolveForeshadowingAt(chapterNo);
        _persistSummary(chapterNo, result.title, result.summary);
        _appendChapterMetrics(result);
        debugPrint(
          '[JOURNEY] 第$chapterNo章/$endChapter '
          '${result.cjkChars}字（去标点）· ${result.segments}段 · '
          '${result.openingModel} · ${result.elapsedSeconds}s · '
          '反AI味=${result.antiAiHighlights} 守护=${result.deviationWarnings}',
        );
      } catch (e, st) {
        _errorLog.writeln('第$chapterNo章 失败: $e\n$st');
        debugPrint('[ERROR] 第$chapterNo章 failed: $e');
      }
      _writeProgress(chapterNo, chapterResults, sw.elapsed);
      if (chapterNo < endChapter) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
    sw.stop();
    await _auditService.flush();
    await _errorLog.flush();
    await _errorLog.close();

    final metrics = await _assembleMetrics(chapterResults, sw.elapsed);
    await _writeMetricsFile(metrics);
    await _writeForeshadowingFile(endChapter);
    return metrics;
  }

  // -- world / chapter setup ------------------------------------------------

  Future<void> _setupWorld() async {
    final templateRepo = container.read(worldTemplateRepositoryProvider);
    // 现代都市题材模板；缺失则跳过——真正指导生成的是 prompt 里的 kGoWorldContext。
    final template = await templateRepo.getById('male-urban-power');
    if (template != null) {
      final instantiationService = await container.read(
        templateInstantiationServiceProvider.future,
      );
      final draft = instantiationService.createDraft(
        template,
        storyConcept: '迷茫青年陆衡入半目棋社学棋，识破俗手即妙手',
      );
      await instantiationService.saveDraft(draft);
    }
    final characterRepo = await container.read(
      characterCardRepositoryProvider.future,
    );
    for (final card in GoFixtures.characters()) {
      await characterRepo.add(card);
    }
    container.read(nameIndexServiceProvider.notifier).refresh();
  }

  Future<List<SkillDocument>> _loadActiveSkills() async {
    final skillRepo = await container.read(skillRepositoryProvider.future);
    for (final skill in GoFixtures.skillRules()) {
      await skillRepo.add(skill);
    }
    return skillRepo.getAll().where((s) => s.isActive).toList();
  }

  Future<List<Chapter>> _createOrSyncChapters() async {
    final existingMs = _manuscriptRepo.getById(_kManuscriptId);
    if (existingMs == null) {
      await _manuscriptRepo.add(
        Manuscript(
          id: _kManuscriptId,
          title: _kManuscriptTitle,
          genre: '现代·围棋·奇诡喜剧',
          targetWordCount: 800000,
          createdAt: DateTime(2026, 7, 8),
          updatedAt: DateTime(2026, 7, 8),
        ),
      );
    }
    final chapters = <Chapter>[];
    for (var i = 1; i <= _kFullChapterCount; i++) {
      final beat = GoStoryOutline.chapters[i - 1];
      final title = chapterTitleFromBeat(beat);
      final chapter = await _chapterRepo.add(
        Chapter(
          id: '',
          manuscriptId: _kManuscriptId,
          title: title,
          sortOrder: i,
          documentContent: '',
          createdAt: DateTime(2026, 7, 8),
          updatedAt: DateTime(2026, 7, 8),
        ),
      );
      chapters.add(chapter);
    }
    return chapters;
  }

  // -- per-chapter generation ----------------------------------------------

  Future<_GoChapterResult> _generateChapter({
    required Chapter chapter,
    required int chapterNo,
    required String? prevSummary,
    required String? contextChain,
  }) async {
    final beat = GoStoryOutline.chapters[chapterNo - 1];
    final title = chapterTitleFromBeat(beat);
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
      temperature: 0.9, // 围棋喜剧＋怪话，略高温度激发奇诡与人味
    );
    var text = open.text;
    var segments = 1;
    final callLog = <String, int>{openModel: 1};

    // 续写至 CJK 达 7000 地板。
    while (cjkCharCount(text) < 7000 && segments < 5) {
      segments++;
      final tail = text.length > 1500
          ? text.substring(text.length - 1500)
          : text;
      final contMessages = _continuationMessages(
        chapterNo,
        title,
        beat,
        tail,
        segments,
      );
      final cont = await _generate(
        messages: contMessages,
        model: kModelLow,
        maxTokens: 4096,
        op: AuditOperationType.expand,
        chapterId: chapter.id,
        temperature: 0.84,
      );
      text += cont.text;
      callLog[kModelLow] = (callLog[kModelLow] ?? 0) + 1;
    }

    final raw = trimToCjkRange(text);
    final rawCjk = cjkCharCount(raw);

    // 反 AI 味：确定性净化 + 收集复核信号。
    final ai = _antiAi.process(raw, bannedPhrases: _banned);
    final clean = _normalizePunctuation(_stripMarkers(ai.processedText));
    final cleanCjk = cjkCharCount(clean);

    await _chapterRepo.updateDocumentContent(chapter.id, clean);
    final fresh = _chapterRepo.getById(chapter.id)!;

    // Skill 守护一致性检查（自带 audit）。
    int deviationWarnings = 0;
    try {
      final dev = await _deviationService.detectDeviations(
        clean,
        _activeSkills,
        manuscriptId: _kManuscriptId,
        chapterId: chapter.id,
      );
      deviationWarnings = dev.warnings.length;
    } catch (e) {
      _errorLog.writeln('第$chapterNo章 守护检测失败: $e');
    }

    // 章节摘要（为下一章上下文）。
    String? summary;
    try {
      final s = await _summarizationService.summarize(fresh);
      summary = s.summary;
      _auditService.recordAudit(
        usage: null,
        modelName: kModelLow,
        operationType: AuditOperationType.synthesis,
        manuscriptId: _kManuscriptId,
        chapterId: chapter.id,
        inputText: clean,
        outputText: summary,
      );
    } catch (e) {
      _errorLog.writeln('第$chapterNo章 摘要失败: $e');
    }

    // 本章 token 用量（用于跨 run 累加的 chapters_metrics.jsonl）。
    final records = await _auditRepo.loadAll();
    final chapterTokensByModel = <String, Map<String, int>>{};
    final chapterTokensByOp = <String, Map<String, int>>{};
    for (final r in records.where((r) => r.chapterId == chapter.id)) {
      _tally(chapterTokensByModel, r.modelName, r.inputTokens, r.outputTokens);
      _tally(
        chapterTokensByOp,
        r.operationType.name,
        r.inputTokens,
        r.outputTokens,
      );
    }

    sw.stop();
    await _writeChapterFile(chapterNo, title, clean);

    return _GoChapterResult(
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
      tokensByModel: chapterTokensByModel,
      tokensByOp: chapterTokensByOp,
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
          manuscriptId: _kManuscriptId,
          chapterId: chapterId,
          inputText: inputText,
          outputText: output,
        );
        return (
          text: output,
          inputTokens: inputTokens,
          outputTokens: outputTokens,
        );
      } catch (e) {
        if (attempt >= 5 || !_isTransient(e)) rethrow;
        final backoff = const Duration(seconds: 8) * attempt;
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
    // Streaming connection drops (GLM's SSE stream is occasionally closed
    // mid-receive) are transient — retry the segment instead of failing the
    // whole chapter. This was the root cause of ch29-60 failing in a prior run.
    if (e is AIStreamException) return true;
    if (e is AIAuthException) return false;
    final s = e.toString();
    return s.contains('429') ||
        s.contains('Socket') ||
        s.contains('Timeout') ||
        s.contains('Connection closed') ||
        s.contains('receiving data') ||
        s.contains('Connection reset');
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
      kGoWriterPersona,
      '',
      kGoWorldContext,
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
    final user =
        '【本章】《$_kManuscriptTitle》第$chapterNo章 $title\n'
        '【剧情要点】$beat\n\n${kSegmentHints[1]!}$kLengthFloor';
    return [ChatMessage.system(sys), ChatMessage.user(user)];
  }

  List<ChatMessage> _continuationMessages(
    int chapterNo,
    String title,
    String beat,
    String textTail,
    int segNo,
  ) {
    final sys =
        '$kGoWriterPersona\n\n$kGoWorldContext\n\n'
        '【续写铁律】紧接【已写正文结尾】自然推进；严禁复述已写情节；'
        '严禁重复上文已用过的比喻、意象或整句（例如不得反复出现同一句'
        '"黑白子在光影中变幻"之类的描写），每段必须用全新的画面、动作与对话向前推进；'
        '避免堆砌"命运""莫名的恐惧""像被无形力量拉扯"等抽象抒情，多用白描与具体细节。';
    final hint = kSegmentHints[segNo] ?? kSegmentHints[4]!;
    final user =
        '【本章】《$_kManuscriptTitle》第$chapterNo章 $title\n'
        '【剧情要点】$beat\n【已写正文结尾】\n"""\n$textTail\n"""\n\n'
        '$hint$kLengthFloor';
    return [ChatMessage.system(sys), ChatMessage.user(user)];
  }

  String _buildContextChain(int chapterNo) {
    final last = <String>[];
    for (var i = chapterNo - 1; i >= 1 && last.length < 3; i--) {
      final s = _summaries[i];
      if (s != null && s.isNotEmpty) last.add('第$i章：$s');
    }
    return last.reversed.join('；');
  }

  // -- foreshadowing lifecycle ---------------------------------------------

  void _plantForeshadowingAt(int chapterNo) {
    for (final t in kGoForeshadowingThreads) {
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
            createdAt: DateTime(2026, 7, 8),
          ),
        );
      }
    }
  }

  void _resolveForeshadowingAt(int chapterNo) {
    for (final t in kGoForeshadowingThreads) {
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

  // -- resume: persistence --------------------------------------------------

  void _loadSummaries() {
    final f = File('$outputDir/summaries.json');
    if (!f.existsSync()) return;
    final map = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    for (final entry in map.entries) {
      final no = int.tryParse(entry.key);
      if (no != null) {
        final v = entry.value;
        if (v is Map && v['summary'] is String) {
          _summaries[no] = v['summary'] as String;
        }
      }
    }
    debugPrint('[RESUME] loaded ${_summaries.length} chapter summaries');
  }

  void _persistSummary(int chapterNo, String title, String? summary) {
    final f = File('$outputDir/summaries.json');
    var map = <String, dynamic>{};
    if (f.existsSync()) {
      map = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    }
    map[chapterNo.toString()] = {'title': title, 'summary': summary ?? ''};
    f.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(map));
  }

  /// 读取已落盘章节；CJK ≥ 地板则返回汇总结果（可恢复跳过），否则返回 null（需重生成）。
  _GoChapterResult? _readExistingChapter(int chapterNo) {
    final beat = GoStoryOutline.chapters[chapterNo - 1];
    final title = chapterTitleFromBeat(beat);
    final padded = chapterNo.toString().padLeft(3, '0');
    final nameOnly = title.replaceFirst(RegExp(r'^第\d+章\s*'), '');
    final safe = (nameOnly.isEmpty ? title : nameOnly).replaceAll(
      RegExp(r'[/\\:*?"<>|]'),
      '',
    );
    final f = File('$outputDir/chapters/第$padded章-$safe.md');
    if (!f.existsSync()) return null;
    final raw = f.readAsStringSync();
    final body = raw.split('\n').skip(1).join('\n').trim();
    final cjk = cjkCharCount(body);
    if (cjk < _kResumeFloor) return null; // 太短，重生成
    return _GoChapterResult(
      chapterNo: chapterNo,
      title: title,
      content: body,
      cjkChars: cjk,
      rawCjkChars: cjk,
      segments: 0,
      openingModel: openingModelFor(chapterNo),
      elapsedSeconds: 0,
      antiAiHighlights: 0,
      antiAiAutoReplaced: 0,
      antiAiSignals: const [],
      deviationWarnings: 0,
      summary: _summaries[chapterNo],
      callLog: const {},
      tokensByModel: const {},
      tokensByOp: const {},
    );
  }

  // -- file output ----------------------------------------------------------

  Future<void> _writeChapterFile(
    int chapterNo,
    String title,
    String content,
  ) async {
    final padded = chapterNo.toString().padLeft(3, '0');
    final nameOnly = title.replaceFirst(RegExp(r'^第\d+章\s*'), '');
    final safe = (nameOnly.isEmpty ? title : nameOnly).replaceAll(
      RegExp(r'[/\\:*?"<>|]'),
      '',
    );
    final file = File('$outputDir/chapters/第$padded章-$safe.md');
    final body = '# $title\n\n$content\n';
    await file.writeAsString(body);
  }

  /// 追加每章指标到 chapters_metrics.jsonl（跨 run 累加，断点续跑不丢）。
  void _appendChapterMetrics(_GoChapterResult c) {
    final f = File('$outputDir/chapters_metrics.jsonl');
    final sink = f.openWrite(mode: FileMode.append);
    sink.writeln(
      jsonEncode({
        'chapterNo': c.chapterNo,
        'title': c.title,
        'cjkChars': c.cjkChars,
        'rawCjkChars': c.rawCjkChars,
        'segments': c.segments,
        'openingModel': c.openingModel,
        'elapsedSeconds': c.elapsedSeconds,
        'antiAiHighlights': c.antiAiHighlights,
        'antiAiAutoReplaced': c.antiAiAutoReplaced,
        'antiAiSignals': c.antiAiSignals,
        'deviationWarnings': c.deviationWarnings,
        'callLog': c.callLog,
        'tokensByModel': c.tokensByModel,
        'tokensByOp': c.tokensByOp,
      }),
    );
    sink.close();
  }

  void _writeProgress(
    int chapterNo,
    List<_GoChapterResult> done,
    Duration elapsed,
  ) {
    final map = <String, dynamic>{
      'lastChapter': chapterNo,
      'generatedThisRun': done.where((c) => c.segments > 0).length,
      'skippedThisRun': done.where((c) => c.segments == 0).length,
      'range': '$startChapter-$endChapter',
      'elapsedSeconds': elapsed.inSeconds,
      'lastTitle': done.isEmpty ? '' : done.last.title,
      'lastCjkChars': done.isEmpty ? 0 : done.last.cjkChars,
    };
    File(
      '$outputDir/progress.json',
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(map));
  }

  Future<_GoRunMetrics> _assembleMetrics(
    List<_GoChapterResult> done,
    Duration elapsed,
  ) async {
    // 优先用跨 run 累加的 chapters_metrics.jsonl（覆盖断点续跑的全部章节）。
    final all = _loadAllChapterMetrics();
    final useAll = all.length >= done.length;
    final src = useAll ? all : done;

    final totalCjk = src.fold<int>(0, (a, c) => a + c.cjkChars);
    final minCjk = src.isEmpty
        ? 0
        : src.map((c) => c.cjkChars).reduce((a, b) => a < b ? a : b);
    final maxCjk = src.isEmpty
        ? 0
        : src.map((c) => c.cjkChars).reduce((a, b) => a > b ? a : b);
    final totalHighlights = src.fold<int>(0, (a, c) => a + c.antiAiHighlights);
    final totalAuto = src.fold<int>(0, (a, c) => a + c.antiAiAutoReplaced);
    final totalDev = src.fold<int>(0, (a, c) => a + c.deviationWarnings);

    final signalCounts = <String, int>{};
    for (final c in src) {
      for (final s in c.antiAiSignals) {
        final t = s['title'] as String;
        signalCounts[t] = (signalCounts[t] ?? 0) + 1;
      }
    }
    final topSignals = signalCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 跨 run 累加 token（来自 chapters_metrics.jsonl 的 tokensByModel/Op）。
    final byModel = <String, Map<String, int>>{};
    final byOp = <String, Map<String, int>>{};
    var totalInput = 0, totalOutput = 0, totalCalls = 0;
    for (final c in src) {
      for (final entry in c.tokensByModel.entries) {
        _tally(
          byModel,
          entry.key,
          entry.value['input']!,
          entry.value['output']!,
        );
        totalInput += entry.value['input']!;
        totalOutput += entry.value['output']!;
        totalCalls += entry.value['calls']!;
      }
      for (final entry in c.tokensByOp.entries) {
        _tally(byOp, entry.key, entry.value['input']!, entry.value['output']!);
      }
    }

    // Foreshadowing stats derived from the plan + the highest chapter actually
    // generated (resume-safe: does not depend on per-run Hive state, which on
    // a resumed run only covers the re-attempted range).
    final maxGenerated = src.isEmpty
        ? 0
        : src.map((c) => c.chapterNo).reduce((a, b) => a > b ? a : b);
    final plantedCount = kGoForeshadowingThreads.length;
    final resolved = kGoForeshadowingThreads
        .where((t) => t.resolveChapter <= maxGenerated)
        .toList();
    final fillRate = plantedCount == 0 ? 0.0 : resolved.length / plantedCount;
    final avgResolve = resolved.isEmpty
        ? 0.0
        : resolved
                  .map((t) => t.resolveChapter - t.plantedChapter)
                  .reduce((a, b) => a + b) /
              resolved.length;

    return _GoRunMetrics(
      chapterCount: src.length,
      successCount: src.length,
      totalCjkChars: totalCjk,
      avgCjkChars: src.isEmpty ? 0 : totalCjk ~/ src.length,
      minCjkChars: minCjk,
      maxCjkChars: maxCjk,
      wallClockSeconds: elapsed.inSeconds,
      totalTokens: totalInput + totalOutput,
      totalInputTokens: totalInput,
      totalOutputTokens: totalOutput,
      totalCalls: totalCalls,
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
      chapters: src,
    );
  }

  /// 从 chapters_metrics.jsonl 重建全部章节指标（可恢复的真相之源）。
  List<_GoChapterResult> _loadAllChapterMetrics() {
    final f = File('$outputDir/chapters_metrics.jsonl');
    if (!f.existsSync()) return [];
    final out = <_GoChapterResult>[];
    final seen = <int>{};
    for (final line in f.readAsLinesSync()) {
      if (line.trim().isEmpty) continue;
      final m = jsonDecode(line) as Map<String, dynamic>;
      final no = m['chapterNo'] as int;
      if (seen.contains(no)) continue; // 去重，取首次达标记录
      seen.add(no);
      final tModel = _readNestedMap(m['tokensByModel']);
      final tOp = _readNestedMap(m['tokensByOp']);
      out.add(
        _GoChapterResult(
          chapterNo: no,
          title: m['title'] as String,
          content: '',
          cjkChars: (m['cjkChars'] as num).toInt(),
          rawCjkChars: (m['rawCjkChars'] as num).toInt(),
          segments: (m['segments'] as num).toInt(),
          openingModel: m['openingModel'] as String,
          elapsedSeconds: (m['elapsedSeconds'] as num).toInt(),
          antiAiHighlights: (m['antiAiHighlights'] as num).toInt(),
          antiAiAutoReplaced: (m['antiAiAutoReplaced'] as num).toInt(),
          antiAiSignals: (m['antiAiSignals'] as List)
              .map((e) => Map<String, String>.from(e as Map))
              .toList(),
          deviationWarnings: (m['deviationWarnings'] as num).toInt(),
          summary: null,
          callLog: (m['callLog'] as Map).map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          ),
          tokensByModel: tModel,
          tokensByOp: tOp,
        ),
      );
    }
    out.sort((a, b) => a.chapterNo.compareTo(b.chapterNo));
    return out;
  }

  Future<void> _writeMetricsFile(_GoRunMetrics m) async {
    final encoder = const JsonEncoder.withIndent('  ');
    final map = <String, dynamic>{
      'generatedAt': DateTime.now().toIso8601String(),
      'manuscriptTitle': _kManuscriptTitle,
      'theme': '2022 全国新高考Ⅰ卷围棋题（本手/妙手/俗手）·现代奇诡喜剧·欧·亨利反转',
      'endingNote': '三单元剧环扣、欧·亨利式反转于第 100 章收束（俗手即妙手）',
      'targetChapterCount': _kFullChapterCount,
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
        'note': 'wallClock 仅为本次 run；断点续跑累计耗时见 chapters_metrics.jsonl',
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
        'avgChaptersToResolve': m.foreshadowingAvgChaptersToResolve
            .toStringAsFixed(1),
      },
      'modelStrategy': {
        'highPerf': kModelHigh,
        'lowCost': kModelLow,
        'keyChaptersOpenedWithHighPerf': kGoKeyChapters.toList()..sort(),
      },
      'chapters': m.chapters
          .map(
            (c) => {
              'chapterNo': c.chapterNo,
              'title': c.title,
              'cjkChars': c.cjkChars,
              'segments': c.segments,
              'openingModel': c.openingModel,
              'elapsedSeconds': c.elapsedSeconds,
              'antiAiHighlights': c.antiAiHighlights,
              'deviationWarnings': c.deviationWarnings,
            },
          )
          .toList(),
    };
    await File('$outputDir/metrics.json').writeAsString(encoder.convert(map));
  }

  Future<void> _writeForeshadowingFile(int maxChapter) async {
    // 可恢复：直接按 plan + 本次最大章节推导状态（不依赖易失的 Hive）。
    final encoder = const JsonEncoder.withIndent('  ');
    final map = kGoForeshadowingThreads.map((t) {
      final resolved = t.resolveChapter <= maxChapter;
      return {
        'id': t.id,
        'title': t.title,
        'status': resolved ? 'resolved' : 'planted',
        'plantedChapter': t.plantedChapter,
        'resolvedChapter': resolved ? t.resolveChapter : null,
        'sourceExcerpt': t.sourceExcerpt,
      };
    }).toList();
    await File(
      '$outputDir/foreshadowing.json',
    ).writeAsString(encoder.convert(map));
  }

  // -- small helpers --------------------------------------------------------

  void _tally(
    Map<String, Map<String, int>> bag,
    String key,
    int input,
    int output,
  ) {
    bag.putIfAbsent(key, () => {'calls': 0, 'input': 0, 'output': 0});
    bag[key]!['calls'] = bag[key]!['calls']! + 1;
    bag[key]!['input'] = bag[key]!['input']! + input;
    bag[key]!['output'] = bag[key]!['output']! + output;
  }

  /// 从 jsonDecode 的嵌套 Map 显式构造 `Map<String, Map<String,int>>`，
  /// 避免 `.map` 推断出 `Map<dynamic,...>` 的类型错误。
  Map<String, Map<String, int>> _readNestedMap(Object? raw) {
    final result = <String, Map<String, int>>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is Map) {
          result[k.toString()] = v.map(
            (kk, vv) => MapEntry(kk.toString(), (vv as num).toInt()),
          );
        }
      });
    }
    return result;
  }

  String _stripMarkers(String text) =>
      text.replaceAllMapped(RegExp(r'【(.*?)】'), (m) => m.group(1) ?? '').trim();

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

class _GoChapterResult {
  const _GoChapterResult({
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
    required this.tokensByModel,
    required this.tokensByOp,
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
  final Map<String, Map<String, int>> tokensByModel;
  final Map<String, Map<String, int>> tokensByOp;
}

class _GoRunMetrics {
  const _GoRunMetrics({
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
  final List<_GoChapterResult> chapters;
}
