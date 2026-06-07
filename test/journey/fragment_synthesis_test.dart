import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:openai_dart/openai_dart.dart';

import 'helpers/journey_container.dart';
import 'helpers/story_outline.dart';

void main() {
  final apiKey = Platform.environment['GLM_API_KEY'];
  final baseUrl = Platform.environment['GLM_BASE_URL'] ??
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

  group('Fragment Creation (Bullet-Note Mode)', () {
    test(
      'should create 5 fragments and persist them in repository',
      () async {
        final fragmentRepo = await container.read(
          fragmentRepositoryProvider.future,
        );

        final fragmentTexts = [
          '林风在青云峰采集灵草时发现一块刻满符文的古玉',
          '苏雪晴暗中帮助林风通过入门考核，赠送一枚护身符',
          '赵天磊在比武中使出禁术，引起长老注意',
          '清虚真人传授林风无名功法第一层，告诫不可外传',
          '外门禁地深处传来异响，有弟子夜间失踪',
        ];

        final createdFragments = <Fragment>[];
        for (final text in fragmentTexts) {
          final fragment = await fragmentRepo.addFragment(text);
          createdFragments.add(fragment);
        }

        final allFragments = fragmentRepo.getAllFragments();
        expect(allFragments, hasLength(5));

        for (final fragment in allFragments) {
          expect(fragment.text, isNotEmpty);
          expect(fragment.id, isNotEmpty);
        }
      },
      skip: apiKey == null ? 'GLM_API_KEY not set' : null,
      timeout: const Timeout(Duration(seconds: 120)),
    );
  });

  group('PromptPipeline Assembly', () {
    test(
      'should assemble messages from fragments via pipeline',
      () async {
        final fragmentRepo = await container.read(
          fragmentRepositoryProvider.future,
        );

        final fragmentTexts = [
          '林风在青云峰采集灵草时发现一块刻满符文的古玉',
          '苏雪晴暗中帮助林风通过入门考核，赠送一枚护身符',
          '赵天磊在比武中使出禁术，引起长老注意',
          '清虚真人传授林风无名功法第一层，告诫不可外传',
          '外门禁地深处传来异响，有弟子夜间失踪',
        ];

        final fragments = <Fragment>[];
        for (final text in fragmentTexts) {
          fragments.add(await fragmentRepo.addFragment(text));
        }

        final pipeline = await container.read(
          promptPipelineProvider.future,
        );

        final context = PromptContext(
          fragments: fragments,
          bannedPhrases: [],
        );

        final messages = pipeline.build(context);

        expect(messages, isNotEmpty);
        expect(messages.length, greaterThanOrEqualTo(2));

        // Verify at least one message contains fragment text content
        // Extract text content from messages using pattern matching
        String extractContent(ChatMessage m) => switch (m) {
              SystemMessage(:final content) => content,
              UserMessage(:final content) => content is UserTextContent
                  ? content.text
                  : content.toString(),
              AssistantMessage(:final content) => content ?? '',
              DeveloperMessage(:final content) => content,
              ToolMessage() => '',
            };

        final allContent =
            messages.map(extractContent).join(' ');

        // Check that fragment content was assembled into messages
        var foundFragmentContent = false;
        for (final text in fragmentTexts) {
          if (allContent.contains(text)) {
            foundFragmentContent = true;
            break;
          }
        }
        // At minimum, user content middleware should include fragments
        expect(
          foundFragmentContent || allContent.contains('林风'),
          isTrue,
          reason: 'Pipeline messages should contain fragment text content',
        );
      },
      skip: apiKey == null ? 'GLM_API_KEY not set' : null,
      timeout: const Timeout(Duration(seconds: 120)),
    );
  });

  group('AI Synthesis (Real GLM API)', () {
    test(
      'should produce non-empty synthesis via real streaming API call',
      () async {
        final fragmentRepo = await container.read(
          fragmentRepositoryProvider.future,
        );

        final fragmentTexts = [
          '林风在青云峰采集灵草时发现一块刻满符文的古玉',
          '苏雪晴暗中帮助林风通过入门考核，赠送一枚护身符',
          '赵天磊在比武中使出禁术，引起长老注意',
          '清虚真人传授林风无名功法第一层，告诫不可外传',
          '外门禁地深处传来异响，有弟子夜间失踪',
        ];

        final fragments = <Fragment>[];
        for (final text in fragmentTexts) {
          fragments.add(await fragmentRepo.addFragment(text));
        }

        final pipeline = await container.read(
          promptPipelineProvider.future,
        );

        final context = PromptContext(
          fragments: fragments,
          bannedPhrases: [],
        );

        final messages = pipeline.build(context);

        final adapter = container.read(openaiAdapterProvider);
        final provider = container.read(activeProviderProvider)!;
        final key = container.read(activeApiKeyProvider)!;

        Usage? capturedUsage;
        final buffer = StringBuffer();

        try {
          final stream = adapter.createStream(
            apiKey: key,
            baseUrl: provider.baseUrl,
            model: provider.model,
            messages: messages,
            onUsage: (usage) {
              capturedUsage = usage;
            },
          );

          await for (final chunk in stream) {
            buffer.write(chunk);
          }
        } catch (e) {
          // ignore: avoid_print
          print('[STREAM_ERROR] $e');
          rethrow;
        }

        final output = buffer.toString();
        // ignore: avoid_print
        print('[SYNTHESIS] Length: ${output.length} chars');

        expect(output, isNotEmpty);
        expect(output.length, greaterThan(50),
            reason: 'Synthesis output should exceed 50 characters');
        expect(capturedUsage, isNotNull,
            reason: 'onUsage callback should be invoked');
      },
      skip: apiKey == null ? 'GLM_API_KEY not set' : null,
      timeout: const Timeout(Duration(seconds: 120)),
    );
  });

  group('Synthesis Quality Check', () {
    test(
      'should contain character names from knowledge injection',
      () async {
        final fragmentRepo = await container.read(
          fragmentRepositoryProvider.future,
        );

        final fragmentTexts = [
          '林风在青云峰采集灵草时发现一块刻满符文的古玉',
          '苏雪晴暗中帮助林风通过入门考核，赠送一枚护身符',
          '赵天磊在比武中使出禁术，引起长老注意',
          '清虚真人传授林风无名功法第一层，告诫不可外传',
          '外门禁地深处传来异响，有弟子夜间失踪',
        ];

        final fragments = <Fragment>[];
        for (final text in fragmentTexts) {
          fragments.add(await fragmentRepo.addFragment(text));
        }

        final pipeline = await container.read(
          promptPipelineProvider.future,
        );

        final context = PromptContext(
          fragments: fragments,
          bannedPhrases: [],
        );

        final messages = pipeline.build(context);

        final adapter = container.read(openaiAdapterProvider);
        final provider = container.read(activeProviderProvider)!;
        final key = container.read(activeApiKeyProvider)!;

        final buffer = StringBuffer();

        try {
          final stream = adapter.createStream(
            apiKey: key,
            baseUrl: provider.baseUrl,
            model: provider.model,
            messages: messages,
          );

          await for (final chunk in stream) {
            buffer.write(chunk);
          }
        } catch (e) {
          // ignore: avoid_print
          print('[STREAM_ERROR] $e');
          rethrow;
        }

        final output = buffer.toString();

        // Check if output contains character names from StoryOutline
        final matchedNames = <String>[];
        for (final name in StoryOutline.characterNames) {
          if (output.contains(name)) {
            matchedNames.add(name);
          }
        }

        if (matchedNames.isNotEmpty) {
          // ignore: avoid_print
          print('[KNOWLEDGE] Synthesis contains: $matchedNames');
        } else {
          // ignore: avoid_print
          print('[WARN] No character names found in synthesis output');
        }

        // Assert at least 1 character name found (knowledge injection working)
        expect(matchedNames.length, greaterThanOrEqualTo(1),
            reason:
                'Synthesis should contain at least 1 character name, proving knowledge injection works');
      },
      skip: apiKey == null ? 'GLM_API_KEY not set' : null,
      timeout: const Timeout(Duration(seconds: 120)),
    );
  });
}
