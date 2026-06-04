import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/onboarding/application/opening_generator_service.dart';
import 'package:museflow/features/onboarding/domain/opening_variant.dart';
import 'package:openai_dart/openai_dart.dart';

void main() {
  group('OpeningGeneratorService', () {
    late OpeningGeneratorService service;

    // Helper to create a service with a mock stream.
    OpeningGeneratorService createService(
      Stream<String> Function(List<ChatMessage>) mockStream,
    ) {
      return OpeningGeneratorService(openingStream: mockStream);
    }

    group('generateOpenings', () {
      test('should return 3 OpeningVariant objects from valid JSON', () async {
        const jsonResponse =
            '{"openings":[{"style":"scene","text":"夜色笼罩着古老的城墙"},{"style":"character","text":"他缓缓睁开双眼"},{"style":"suspense","text":"谁在黑暗中窥视着这一切？"}]}';

        service = createService(
          (messages) => Stream.value(jsonResponse),
        );

        final results = await service.generateOpenings(
          genreName: '玄幻',
          worldDescription: '修仙世界',
          characterDescription: '少年主角',
        );

        expect(results, hasLength(3));
        expect(results[0].style, OpeningVariantStyle.scene);
        expect(results[0].text, '夜色笼罩着古老的城墙');
        expect(results[1].style, OpeningVariantStyle.character);
        expect(results[1].text, '他缓缓睁开双眼');
        expect(results[2].style, OpeningVariantStyle.suspense);
        expect(results[2].text, '谁在黑暗中窥视着这一切？');
      });

      test('should handle malformed JSON and return empty list', () async {
        const malformedResponse = 'This is not JSON at all!';

        service = createService(
          (messages) => Stream.value(malformedResponse),
        );

        final results = await service.generateOpenings(
          genreName: '玄幻',
          worldDescription: '修仙世界',
          characterDescription: '少年主角',
        );

        expect(results, isEmpty);
      });

      test('should handle missing openings array and return empty list', () async {
        const noOpeningsResponse = '{"error": "something went wrong"}';

        service = createService(
          (messages) => Stream.value(noOpeningsResponse),
        );

        final results = await service.generateOpenings(
          genreName: '玄幻',
          worldDescription: '修仙世界',
          characterDescription: '少年主角',
        );

        expect(results, isEmpty);
      });

      test('should strip markdown fences from AI response', () async {
        const fencedResponse =
            '```json\n{"openings":[{"style":"scene","text":"场景文本"}]}\n```';

        service = createService(
          (messages) => Stream.value(fencedResponse),
        );

        final results = await service.generateOpenings(
          genreName: '玄幻',
          worldDescription: '修仙世界',
          characterDescription: '少年主角',
        );

        expect(results, hasLength(1));
        expect(results[0].style, OpeningVariantStyle.scene);
        expect(results[0].text, '场景文本');
      });

      test('should handle streaming chunks accumulated into buffer', () async {
        // Simulate chunked streaming response.
        final chunks = [
          '{"ope',
          'nings":[{"sty',
          'le":"scene","tex',
          't":"累积的文本"}]}',
        ];

        service = createService(
          (messages) => Stream.fromIterable(chunks),
        );

        final results = await service.generateOpenings(
          genreName: '都市',
          worldDescription: '现代都市',
          characterDescription: '上班族',
        );

        expect(results, hasLength(1));
        expect(results[0].text, '累积的文本');
      });

      test('should handle stream error and return empty list', () async {
        service = createService(
          (messages) => Stream.error(Exception('Connection failed')),
        );

        final results = await service.generateOpenings(
          genreName: '玄幻',
          worldDescription: '修仙世界',
          characterDescription: '少年主角',
        );

        expect(results, isEmpty);
      });

      test('should truncate storyConcept to 500 chars', () async {
        String? capturedUserMessage;

        service = createService((messages) {
          // Capture user message for inspection.
          final userMsg = messages.whereType<UserMessage>().first;
          capturedUserMessage = userMsg.text;
          return Stream.value(
            '{"openings":[]}',
          );
        });

        final longConcept = 'A' * 600;
        await service.generateOpenings(
          genreName: '玄幻',
          worldDescription: '世界',
          characterDescription: '角色',
          storyConcept: longConcept,
        );

        // Verify the concept was truncated to 500 chars in the user message.
        expect(capturedUserMessage, isNotNull);
        expect(capturedUserMessage!.contains('A' * 500), isTrue);
        expect(capturedUserMessage!.contains('A' * 501), isFalse);
      });

      test('should not include concept key when storyConcept is null', () async {
        String? capturedUserMessage;

        service = createService((messages) {
          capturedUserMessage = messages.whereType<UserMessage>().first.text;
          return Stream.value('{"openings":[]}');
        });

        await service.generateOpenings(
          genreName: '玄幻',
          worldDescription: '世界',
          characterDescription: '角色',
        );

        expect(capturedUserMessage, isNotNull);
        expect(capturedUserMessage!.contains('concept'), isFalse);
      });

      test('should not include concept key when storyConcept is empty', () async {
        String? capturedUserMessage;

        service = createService((messages) {
          capturedUserMessage = messages.whereType<UserMessage>().first.text;
          return Stream.value('{"openings":[]}');
        });

        await service.generateOpenings(
          genreName: '玄幻',
          worldDescription: '世界',
          characterDescription: '角色',
          storyConcept: '',
        );

        expect(capturedUserMessage, isNotNull);
        expect(capturedUserMessage!.contains('concept'), isFalse);
      });

      test('should truncate opening text exceeding 1000 chars', () async {
        final longText = 'X' * 1200;
        final jsonResponse =
            '{"openings":[{"style":"scene","text":"$longText"}]}';

        service = createService(
          (messages) => Stream.value(jsonResponse),
        );

        final results = await service.generateOpenings(
          genreName: '玄幻',
          worldDescription: '世界',
          characterDescription: '角色',
        );

        expect(results, hasLength(1));
        expect(results[0].text.length, 1000);
        expect(results[0].text, 'X' * 1000);
      });

      test('should include genre, world, character in user message', () async {
        String? capturedUserMessage;

        service = createService((messages) {
          capturedUserMessage = messages.whereType<UserMessage>().first.text;
          return Stream.value('{"openings":[]}');
        });

        await service.generateOpenings(
          genreName: '玄幻',
          worldDescription: '修仙大陆',
          characterDescription: '天才少年',
          storyConcept: '拯救世界',
        );

        expect(capturedUserMessage, isNotNull);
        expect(capturedUserMessage!.contains('玄幻'), isTrue);
        expect(capturedUserMessage!.contains('修仙大陆'), isTrue);
        expect(capturedUserMessage!.contains('天才少年'), isTrue);
        expect(capturedUserMessage!.contains('拯救世界'), isTrue);
      });

      test('should filter out non-map items in openings array', () async {
        const mixedResponse =
            '{"openings":["invalid string",{"style":"scene","text":"有效文本"},42]}';

        service = createService(
          (messages) => Stream.value(mixedResponse),
        );

        final results = await service.generateOpenings(
          genreName: '玄幻',
          worldDescription: '世界',
          characterDescription: '角色',
        );

        expect(results, hasLength(1));
        expect(results[0].text, '有效文本');
      });
    });
  });
}
