import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/story_structure/application/format_cleaner.dart';
import 'package:museflow/features/story_structure/domain/format_clean_result.dart';

import '../automation/helpers/fake_adapter.dart';
import 'helpers/journey_container.dart';
import 'helpers/story_outline.dart';

void main() {
  late ProviderContainer container;
  late List<String> rawChapters;
  const cleaner = FormatCleaner();

  setUp(() async {
    container = await createJourneyContainer(
      apiKey: 'journey-local-test-key',
      baseUrl: 'https://example.com/v1',
      model: 'fake-model',
      aiAdapter: FakeAdapter(),
    );
    rawChapters = _buildRawChapters();
  });

  tearDown(() async {
    await cleanupJourneyContainer(container);
  });

  group('100-chapter batch cleaning', () {
    test(
      'should clean 100 chapters with no Markdown residue (D-08 category 1)',
      () {
        expect(rawChapters, hasLength(100));
        final cleanedResults = _cleanAll(rawChapters, cleaner);
        final headingPattern = RegExp(r'(^|\n)#{1,6}\s', multiLine: true);
        final boldPattern = RegExp(r'\*\*[^*]+\*\*');

        for (var i = 0; i < cleanedResults.length; i++) {
          final result = cleanedResults[i];
          if (result.hasChanges) {
            debugPrint(
              '[D-08] chapter ${i + 1} markdown changes=${result.changes.length}',
            );
          }
          expect(
            result.cleanedText,
            isNot(matches(headingPattern)),
            reason: 'Chapter ${i + 1} still has Markdown heading markers',
          );
          expect(
            result.cleanedText,
            isNot(matches(boldPattern)),
            reason: 'Chapter ${i + 1} still has bold markers',
          );
          expect(
            result.cleanedText,
            isNot(contains('```')),
            reason: 'Chapter ${i + 1} still has code fences',
          );
        }
      },
    );

    test(
      'should normalize CJK punctuation across 100 chapters (D-08 category 2)',
      () {
        final cjkAsciiPunctuationPattern = RegExp(r'[一-鿿][,;:!?]');
        final cleanedResults = _cleanAll(rawChapters, cleaner);

        for (var i = 0; i < cleanedResults.length; i++) {
          expect(
            cleanedResults[i].cleanedText,
            isNot(matches(cjkAsciiPunctuationPattern)),
            reason:
                'Chapter ${i + 1} still has CJK followed by ASCII punctuation',
          );
        }
      },
    );

    test('should normalize layout across 100 chapters (D-08 category 3)', () {
      final excessiveBlankLinesPattern = RegExp(r'\n{4,}');
      final cleanedResults = _cleanAll(rawChapters, cleaner);

      for (var i = 0; i < cleanedResults.length; i++) {
        expect(
          cleanedResults[i].cleanedText,
          isNot(matches(excessiveBlankLinesPattern)),
          reason: 'Chapter ${i + 1} still has 3+ consecutive blank lines',
        );
      }
    });

    test('should be idempotent on 100 chapters', () {
      final cleanedResults = _cleanAll(rawChapters, cleaner);

      for (var i = 0; i < cleanedResults.length; i++) {
        final secondPass = cleaner.clean(cleanedResults[i].cleanedText);
        expect(
          secondPass.changes,
          isEmpty,
          reason: 'Chapter ${i + 1} produced second-pass changes',
        );
      }
    });
  });

  group('FormatCleanResult validation', () {
    test(
      'should preserve original text and produce non-empty cleaned text for every chapter',
      () {
        final cleanedResults = _cleanAll(rawChapters, cleaner);

        for (var i = 0; i < cleanedResults.length; i++) {
          final result = cleanedResults[i];
          expect(result, isA<FormatCleanResult>());
          expect(result.originalText, rawChapters[i]);
          expect(
            result.cleanedText,
            isNotEmpty,
            reason: 'Chapter ${i + 1} cleaned text is empty',
          );
        }
      },
    );

    test(
      'should keep journey container available without external AI calls',
      () {
        final provider = container.read(activeProviderProvider);
        final manuscript = Manuscript(
          id: 'format-cleaning-journey',
          title: '剑道苍穹',
          genre: '修仙',
          createdAt: _fixedDate,
          updatedAt: _fixedDate,
        );
        final chapter = Chapter(
          id: 'format-cleaning-chapter-1',
          manuscriptId: manuscript.id,
          title: '第1章',
          sortOrder: 1,
          documentContent: rawChapters.first,
          createdAt: _fixedDate,
          updatedAt: _fixedDate,
        );

        expect(provider, isNotNull);
        expect(provider!.model, 'fake-model');
        expect(manuscript.title, '剑道苍穹');
        expect(chapter.documentContent, contains('**加粗文本**'));
      },
    );
  });
}

final _fixedDate = DateTime(2026, 6, 8);

List<String> _buildRawChapters() {
  return List.generate(StoryOutline.chapters.length, (index) {
    final chapterNumber = index + 1;
    final buffer = StringBuffer();
    if (chapterNumber % 10 == 0) {
      buffer.writeln('# 标题行');
      buffer.writeln();
    }
    buffer.write(StoryOutline.chapters[index]);
    buffer.write(' 林风回望山门,仍旧不退!');
    buffer.write('\n\n\n\n段落间距异常。');
    if (chapterNumber.isOdd) {
      buffer.write('\n**加粗文本**');
    }
    if (chapterNumber % 10 == 5) {
      buffer.write('\n```代码块```');
    }
    return buffer.toString();
  });
}

List<FormatCleanResult> _cleanAll(
  List<String> rawChapters,
  FormatCleaner cleaner,
) {
  return [
    for (final chapterContent in rawChapters) cleaner.clean(chapterContent),
  ];
}
