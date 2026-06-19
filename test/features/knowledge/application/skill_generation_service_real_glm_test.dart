/// Real-API validation for the skill-generation Markdown parsing path.
///
/// [SkillGenerationService] streams a world-building SkillDocument in Markdown
/// (5 fixed `##` sections: 力量等级体系 / 门派·势力关系 / 世界规则 / 禁忌·限制 /
/// 专用术语), then [parseSkillDocument] slices it via `_parseMarkdown`, which
/// matches each section by `contains` on heading keywords. The canned
/// `skill_generation_service_test` feeds perfectly-shaped Markdown via a fake
/// adapter, so it proves nothing about whether `_parseMarkdown` survives real
/// model output — real LLMs can drift on heading wording, add preamble, or
/// vary formatting, any of which could make a `pick(['力量','等级'])` miss.
///
/// curl probes confirmed GLM-4-flash complies with the requested headings and
/// all 5 sections parse (2/2). This env-gated test locks that behavior in as a
/// regression guard and closes the last real-API coverage gap among the
/// structured-output paths. Constructor-injected (no ProviderContainer needed).
library;

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:museflow/features/knowledge/application/skill_generation_service.dart';

void main() {
  final apiKey = Platform.environment['GLM_API_KEY'];
  final baseUrl =
      Platform.environment['GLM_BASE_URL'] ??
      'https://open.bigmodel.cn/api/paas/v4';
  final model = Platform.environment['GLM_MODEL'] ?? 'glm-4-flash';

  group('Skill generation (Real GLM API)', () {
    test(
      'streams a 5-section SkillDocument that parseSkillDocument fully slices',
      () async {
        final adapter = OpenAIAdapter();
        addTearDown(adapter.dispose);

        final service = SkillGenerationService(
          openAIAdapter: adapter,
          apiKey: apiKey!,
          baseUrl: baseUrl,
          model: model,
        );

        // Stream the generation and accumulate the raw Markdown.
        final chunks = await service
            .generateSkillStream('一个名叫林风的少年在青云峰修仙，觉醒祖传古玉血脉，卷入消失百年的天玄宗谜案')
            .toList();
        final rawContent = chunks.join();

        expect(
          rawContent,
          isNotEmpty,
          reason: 'skill generation must stream non-empty content',
        );

        final doc = service.parseSkillDocument(
          name: '青云界设定',
          description: '修仙世界观',
          rawContent: rawContent,
        );

        // Every one of the 5 sections must be sliced non-empty from real GLM
        // Markdown output. If a section is null/empty, _parseMarkdown's
        // contains-based pick missed the real heading wording — the exact
        // failure mode this test guards against.
        final sections = doc.sections;
        expect(
          sections.powerHierarchy,
          isNotEmpty,
          reason: '力量等级体系 section must be sliced from real output',
        );
        expect(
          sections.factionRelations,
          isNotEmpty,
          reason: '门派/势力关系 section must be sliced from real output',
        );
        expect(
          sections.rules,
          isNotEmpty,
          reason: '世界规则 section must be sliced from real output',
        );
        expect(
          sections.taboos,
          isNotEmpty,
          reason: '禁忌/限制 section must be sliced from real output',
        );
        expect(
          sections.terminology,
          isNotEmpty,
          reason: '专用术语 section must be sliced from real output',
        );

        print(
          '[SKILL] powerHierarchy=${sections.powerHierarchy!.length}chars '
          'rules=${sections.rules!.length}chars '
          'terminology=${sections.terminology!.length}chars',
        );
        final head = sections.powerHierarchy!;
        print(
          '[SKILL] powerHierarchy head: '
          '${head.length > 60 ? head.substring(0, 60) : head}',
        );
      },
      skip: apiKey == null ? 'GLM_API_KEY not set' : null,
      timeout: const Timeout(Duration(seconds: 120)),
    );
  });
}
