import 'dart:io';
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
import 'package:openai_dart/openai_dart.dart';

import '../automation/helpers/fake_adapter.dart';
import 'helpers/d11_bounds.dart';
import 'helpers/journey_container.dart';
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
    'should complete deterministic full xianxia journey without GLM credentials',
    () async {
      final localContainer = await createJourneyContainer(
        apiKey: 'journey-local-test-key',
        baseUrl: 'https://example.com/v1',
        model: 'fake-model',
        aiAdapter: _DeterministicFullJourneyAdapter(FakeAdapter()),
      );
      try {
        debugPrint('[E2E][DETERMINISTIC] Starting local full journey');
        await _phaseAWorldBuilding(localContainer);

        final synthesisOutput = await _phaseBFragmentSynthesis(localContainer);
        expect(synthesisOutput.length, greaterThan(50));

        final manuscript = await _phaseCOpeningGuide(localContainer);
        await _phaseDSerialGeneration(
          localContainer,
          manuscript,
          useDelay: false,
        );

        final snapshot = await _phaseETokenAudit(localContainer);
        expect(snapshot.totalCalls, greaterThanOrEqualTo(31));
        debugPrint('[E2E][DETERMINISTIC] Full journey complete');
      } finally {
        await cleanupJourneyContainer(localContainer);
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'should complete full xianxia journey from world-building to 30 chapters',
    () async {
      debugPrint('[E2E] Starting full xianxia journey validation');

      await _phaseAWorldBuilding(container!);

      final synthesisOutput = await _phaseBFragmentSynthesis(container!);
      expect(synthesisOutput.length, greaterThan(50));

      final manuscript = await _phaseCOpeningGuide(container!);

      await _phaseDSerialGeneration(container!, manuscript, useDelay: true);

      await _phaseETokenAudit(container!);
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
  expect(result.worldSetting!.name, contains('青冥'));
  expect(result.worldSetting!.description, contains('宗门'));

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
  final fragmentRepository = await container.read(fragmentRepositoryProvider.future);
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
  debugPrint('[E2E] Phase B: Fragment synthesis complete (${output.length} chars)');
  return output;
}

Future<Manuscript> _phaseCOpeningGuide(ProviderContainer container) async {
  final manuscriptRepository = await container.read(manuscriptRepositoryProvider.future);
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
  Manuscript manuscript, {
  required bool useDelay,
}) async {
  final chapterRepository = await container.read(chapterRepositoryProvider.future);
  final chapters = await _createThirtyChapters(chapterRepository, manuscript.id);
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
      expect(output.length, inInclusiveRange(300, 500));
      debugPrint('[E2E] Chapter ${i + 1}/30 generated (${output.length} chars)');
    } catch (e) {
      debugPrint('[E2E][ERROR] Chapter ${i + 1}/30 failed: ${_safeExceptionDiagnostic(e)}');
      rethrow;
    }

    if (useDelay && i < 29) {
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  debugPrint('[E2E] Phase D: 30-chapter generation complete');
}

Future<dynamic> _phaseETokenAudit(ProviderContainer container) async {
  final auditService = await container.read(tokenAuditServiceProvider.future);
  await auditService.flush();
  final auditRepository = await container.read(tokenAuditRepositoryProvider.future);
  final snapshot = await auditRepository.buildSnapshot();
  expect(snapshot.totalCalls, greaterThanOrEqualTo(31));
  expect(snapshot.totalInputTokens, greaterThan(0));
  expect(snapshot.totalOutputTokens, greaterThan(0));
  debugPrint(
    '[E2E] Audit calls: ${snapshot.totalCalls}, '
    'input: ${snapshot.totalInputTokens}, output: ${snapshot.totalOutputTokens}',
  );
  debugPrint('[E2E] Phase E: Token audit verified (${snapshot.totalCalls} calls)');
  return snapshot;
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

  final boundedOutput = enforceD11Bounds(output);

  auditService.recordAudit(
    usage: capturedUsage,
    modelName: model,
    operationType: AuditOperationType.synthesis,
    manuscriptId: manuscript.id,
    chapterId: chapter.id,
    inputText: StoryOutline.chapters[index],
    outputText: boundedOutput,
  );
  await chapterRepository.updateDocumentContent(chapter.id, boundedOutput);
  return boundedOutput;
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

class _DeterministicFullJourneyAdapter implements AIAdapter {
  _DeterministicFullJourneyAdapter(this._fallback);

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
    final String response;
    if (promptText.contains('返回格式') || promptText.contains('openings')) {
      response = _openingsJson;
    } else if (promptText.contains('第') && promptText.contains('林风')) {
      response = _chapterText(_chapterIndex++);
    } else {
      response = await _fallback
          .createStream(
            apiKey: apiKey,
            baseUrl: baseUrl,
            model: model,
            messages: messages,
            temperature: temperature,
            topP: topP,
            maxTokens: maxTokens,
          )
          .join();
    }

    for (final codePoint in response.runes) {
      yield String.fromCharCode(codePoint);
    }
    onUsage?.call(_usage(promptText, response));
  }

  String _chapterText(int index) {
    final chapterNo = index + 1;
    final name = StoryOutline.characterNames[index % StoryOutline.characterNames.length];
    final plot = StoryOutline.chapters[index];
    final text = '第$chapterNo章，林风沿着青云宗山道前行，$name在旁提醒他莫忘清虚真人的告诫。$plot 他先整理灵气、核对门规、记录白灵的反应，再把今日所见写入随身玉简。夜色落下时，苏雪晴递来一盏灵茶，赵天磊的目光从演武场另一侧扫过，新的冲突已经埋下。这一章保持凡人少年稳步成长的节奏，既写修炼压力，也写宗门人情，让人物关系、境界限制和世界观禁忌自然进入叙事。林风只推进一个明确目标，不越过作者亲自打磨的边界。清虚真人要求他每晚复盘战斗细节，把白日的得失化成下一次行动的依据。苏雪晴则提醒他把每一次犹豫都写清楚。';
    return text.substring(0, min(420, text.length));
  }

  String get _openingsJson =>
      '{"openings":[{"style":"scene","text":"青云山夜雨初歇，石阶间浮起薄薄灵雾。林风握着旧木剑站在山门前，听见远处钟声穿过松林，像是在催促凡人少年迈入未知的修仙世界。"},{"style":"character","text":"林风把掌心磨破的血迹藏进袖中，仍然向执事行了一礼。清虚真人的目光从高台落下，苏雪晴微微颔首，他知道自己不能退。"},{"style":"suspense","text":"禁地深处的玉简为何只在林风靠近时发光？赵天磊的冷笑还未散去，白灵已经竖起耳朵，仿佛听见了某个被宗门封存多年的名字。"}]}';

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

const _fragmentTexts = [
  '林风在青云峰采集灵草时发现一块刻满符文的古玉',
  '苏雪晴暗中帮助林风通过入门考核，赠送一枚护身符',
  '赵天磊在比武中使出禁术，引起长老注意',
  '清虚真人传授林风无名功法第一层，告诫不可外传',
  '外门禁地深处传来异响，有弟子夜间失踪',
];
