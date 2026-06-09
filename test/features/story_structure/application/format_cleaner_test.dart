import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/story_structure/application/format_cleaner.dart';
import 'package:museflow/features/story_structure/domain/format_clean_result.dart';

void main() {
  group('FormatCleanResult', () {
    test('should create result with original and cleaned text', () {
      const result = FormatCleanResult(
        originalText: 'hello',
        cleanedText: 'hello',
        changes: [],
      );

      expect(result.originalText, 'hello');
      expect(result.cleanedText, 'hello');
      expect(result.changes, isEmpty);
    });

    test('should report hasChanges when changes exist', () {
      const result = FormatCleanResult(
        originalText: 'a',
        cleanedText: 'b',
        changes: [
          FormatChange(
            category: FormatChangeCategory.punctuation,
            original: 'a',
            replacement: 'b',
            startOffset: 0,
            endOffset: 1,
            explanation: 'test',
          ),
        ],
      );

      expect(result.hasChanges, true);
    });

    test('should report no hasChanges when changes is empty', () {
      const result = FormatCleanResult(
        originalText: 'a',
        cleanedText: 'a',
        changes: [],
      );

      expect(result.hasChanges, false);
    });

    test('should serialize to and from JSON', () {
      const result = FormatCleanResult(
        originalText: 'original',
        cleanedText: 'cleaned',
        changes: [
          FormatChange(
            category: FormatChangeCategory.punctuation,
            original: ',',
            replacement: '，',
            startOffset: 0,
            endOffset: 1,
            explanation: 'half-width to full-width comma',
          ),
        ],
      );

      final json = result.toJson();
      final restored = FormatCleanResult.fromJson(json);

      expect(restored.originalText, result.originalText);
      expect(restored.cleanedText, result.cleanedText);
      expect(restored.changes.length, 1);
      expect(restored.changes[0].category, FormatChangeCategory.punctuation);
      expect(restored.changes[0].original, ',');
      expect(restored.changes[0].replacement, '，');
    });
  });

  group('FormatCleaner', () {
    late FormatCleaner cleaner;

    setUp(() {
      cleaner = const FormatCleaner();
    });

    // --- Chinese punctuation normalization ---

    group('punctuation normalization', () {
      test('should convert half-width comma to full-width in CJK prose', () {
        const text = '他说，这是一个故事。';
        // Already clean
        final result = cleaner.clean(text);
        expect(result.cleanedText, text);
      });

      test('should convert half-width comma to full-width in Chinese text', () {
        // "他说,这是一个故事" -> "他说，这是一个故事"
        const text = '他说,这是一个故事';
        final result = cleaner.clean(text);
        expect(result.cleanedText, contains('，'));
        expect(result.cleanedText, isNot(contains(',')));
      });

      test(
        'should convert half-width period to full-width in Chinese text',
        () {
          // Chinese sentence ending with half-width period
          const text = '这是一个故事.';
          final result = cleaner.clean(text);
          expect(result.cleanedText, contains('。'));
          expect(result.cleanedText, isNot(contains('.')));
        },
      );

      test(
        'should convert half-width question mark to full-width in Chinese text',
        () {
          const text = '你好?';
          final result = cleaner.clean(text);
          expect(result.cleanedText, contains('？'));
          expect(result.cleanedText, isNot(contains('?')));
        },
      );

      test(
        'should convert half-width exclamation mark to full-width in Chinese text',
        () {
          const text = '太好了!';
          final result = cleaner.clean(text);
          expect(result.cleanedText, contains('！'));
          expect(result.cleanedText, isNot(contains('!')));
        },
      );

      test('should convert half-width colon to full-width in Chinese text', () {
        const text = '原因:结果';
        final result = cleaner.clean(text);
        expect(result.cleanedText, contains('：'));
        expect(result.cleanedText, isNot(contains(':')));
      });

      test(
        'should convert half-width semicolon to full-width in Chinese text',
        () {
          const text = '前半句;后半句';
          final result = cleaner.clean(text);
          expect(result.cleanedText, contains('；'));
          expect(result.cleanedText, isNot(contains(';')));
        },
      );

      test('should NOT corrupt URLs with half-width punctuation', () {
        const text = '访问 https://example.com/path?q=1&r=2 了解更多';
        final result = cleaner.clean(text);
        // URL punctuation must remain intact
        expect(
          result.cleanedText,
          contains('https://example.com/path?q=1&r=2'),
        );
      });

      test('should NOT corrupt decimal numbers', () {
        const text = '温度 36.5 度';
        final result = cleaner.clean(text);
        expect(result.cleanedText, contains('36.5'));
      });

      test('should NOT corrupt English abbreviations with periods', () {
        const text = '使用 U.S.A. 标准';
        final result = cleaner.clean(text);
        expect(result.cleanedText, contains('U.S.A.'));
      });

      test('should NOT corrupt model names with periods', () {
        const text = '模型 GPT-4.0 更强';
        final result = cleaner.clean(text);
        expect(result.cleanedText, contains('GPT-4.0'));
      });

      test('should NOT corrupt file paths with periods', () {
        const text = '文件在 C:\\Users\\test.txt';
        final result = cleaner.clean(text);
        expect(result.cleanedText, contains('test.txt'));
      });
    });

    // --- Markdown residual cleaning ---

    group('Markdown residual cleaning', () {
      test('should strip leading heading markers', () {
        const text = '# 第一章\n## 小节';
        final result = cleaner.clean(text);
        expect(result.cleanedText, isNot(contains('# 第一章')));
        expect(result.cleanedText, contains('第一章'));
        expect(result.cleanedText, contains('小节'));
      });

      test('should strip list bullet markers at paragraph start', () {
        const text = '- 第一项\n- 第二项';
        final result = cleaner.clean(text);
        expect(result.cleanedText, isNot(contains('- ')));
        expect(result.cleanedText, contains('第一项'));
      });

      test('should strip asterisk list markers at paragraph start', () {
        const text = '* 第一项\n* 第二项';
        final result = cleaner.clean(text);
        expect(result.cleanedText, isNot(contains('* 第')));
        expect(result.cleanedText, contains('第一项'));
      });

      test('should strip unmatched emphasis markers around CJK text', () {
        const text = '*这是重点*';
        final result = cleaner.clean(text);
        expect(result.cleanedText, '这是重点');
      });

      test('should strip unmatched double emphasis markers', () {
        const text = '**这是加粗**';
        final result = cleaner.clean(text);
        expect(result.cleanedText, '这是加粗');
      });

      test('should strip simple HTML tags', () {
        const text = '<b>加粗</b>文字';
        final result = cleaner.clean(text);
        expect(result.cleanedText, '加粗文字');
      });

      test('should strip <br> tags', () {
        const text = '第一行<br>第二行';
        final result = cleaner.clean(text);
        expect(result.cleanedText, isNot(contains('<br>')));
      });

      test('should NOT strip asterisks in multiplication context', () {
        const text = '2 * 3 = 6';
        final result = cleaner.clean(text);
        expect(result.cleanedText, contains('2 * 3 = 6'));
      });
    });

    // --- Whitespace and paragraph normalization ---

    group('whitespace and paragraph normalization', () {
      test('should trim trailing whitespace from lines', () {
        const text = '第一行   \n第二行  ';
        final result = cleaner.clean(text);
        expect(result.cleanedText, isNot(contains('   ')));
      });

      test('should collapse excessive blank lines to at most one', () {
        const text = '第一段\n\n\n\n第二段';
        final result = cleaner.clean(text);
        expect(result.cleanedText, '第一段\n\n第二段');
      });

      test('should normalize line endings to LF', () {
        const text = '第一行\r\n第二行\r第三行';
        final result = cleaner.clean(text);
        expect(result.cleanedText, contains('\n'));
        expect(result.cleanedText, isNot(contains('\r')));
      });

      test('should normalize mixed line endings preserving paragraphs', () {
        const text = '段落一\r\n\r\n段落二';
        final result = cleaner.clean(text);
        expect(result.cleanedText, '段落一\n\n段落二');
      });
    });

    // --- Idempotence ---

    group('idempotence', () {
      test('should produce zero changes on already-clean text', () {
        const text = '他说，这是一个故事。\n\n第二段开始了。';
        final result = cleaner.clean(text);
        expect(result.cleanedText, text);
        expect(result.changes, isEmpty);
      });

      test('should be idempotent - applying twice produces same result', () {
        const text = '他说,这是一个故事.';
        final first = cleaner.clean(text);
        final second = cleaner.clean(first.cleanedText);

        expect(second.cleanedText, first.cleanedText);
        expect(second.changes, isEmpty);
      });
    });

    // --- Options ---

    group('with options', () {
      test('should skip punctuation when option is disabled', () {
        const text = '他说,这是一个故事.';
        const options = FormatCleanOptions(
          normalizePunctuation: false,
          cleanMarkdown: true,
          normalizeWhitespace: true,
          normalizeIndentation: true,
          normalizeParagraphSpacing: true,
        );
        final result = cleaner.clean(text, options: options);
        // Half-width comma and period should remain
        expect(result.cleanedText, contains(','));
        expect(result.cleanedText, contains('.'));
      });

      test('should skip Markdown cleaning when option is disabled', () {
        const text = '# 标题';
        const options = FormatCleanOptions(
          normalizePunctuation: true,
          cleanMarkdown: false,
          normalizeWhitespace: true,
          normalizeIndentation: true,
          normalizeParagraphSpacing: true,
        );
        final result = cleaner.clean(text, options: options);
        expect(result.cleanedText, contains('# '));
      });
    });
  });
}
