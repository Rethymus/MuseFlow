import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/text_controller.dart';
import 'package:museflow/features/editor/format_cleaner.dart';

void main() {
  group('EditorTextController Tests', () {
    late EditorTextController controller;

    setUp(() {
      controller = EditorTextController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('初始化控制器应该为空', () {
      expect(controller.text, isEmpty);
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isFalse);
    });

    test('设置文本应该保存到历史记录', () {
      controller.text = 'Hello World';
      expect(controller.text, equals('Hello World'));
    });

    test('撤销功能应该正常工作', () {
      controller.text = 'First';
      controller.text = 'Second';
      controller.text = 'Third';

      controller.undo();
      expect(controller.text, equals('Second'));

      controller.undo();
      expect(controller.text, equals('First'));
    });

    test('重做功能应该正常工作', () {
      controller.text = 'First';
      controller.text = 'Second';

      controller.undo();
      expect(controller.text, equals('First'));

      controller.redo();
      expect(controller.text, equals('Second'));
    });

    test('在光标位置插入文本', () {
      controller.text = 'Hello World';
      controller.value = controller.value.copyWith(
        selection: TextSelection.collapsed(offset: 5),
      );

      controller.insertAtCursor(' Beautiful');
      expect(controller.text, equals('Hello Beautiful World'));
    });

    test('替换选中的文本', () {
      controller.text = 'Hello World';
      controller.value = controller.value.copyWith(
        selection: TextSelection(baseOffset: 0, extentOffset: 5),
      );

      controller.replaceSelection('Hi');
      expect(controller.text, equals('Hi World'));
    });

    test('获取当前段落', () {
      controller.text = 'First paragraph\n\nSecond paragraph\nThird paragraph';
      controller.value = controller.value.copyWith(
        selection: TextSelection.collapsed(offset: 20),
      );

      final paragraph = controller.getCurrentParagraph();
      expect(paragraph, equals('Second paragraph'));
    });

    test('扩展到完整单词', () {
      controller.text = 'Hello World Test';
      controller.value = controller.value.copyWith(
        selection: TextSelection.collapsed(offset: 7),
      );

      final word = controller.expandToWord();
      expect(word, equals('World'));
    });
  });

  group('FormatCleaner Tests', () {
    late FormatCleaner cleaner;

    setUp(() {
      cleaner = FormatCleaner();
    });

    tearDown(() {
      cleaner.dispose();
    });

    test('清除多余空行', () {
      final input = 'Line 1\n\n\n\nLine 2';
      final output = cleaner.cleanMarkdown(input);
      expect(output, equals('Line 1\n\nLine 2'));
    });

    test('清除行尾空格', () {
      final input = 'Line 1   \nLine 2\t';
      final output = cleaner.cleanMarkdown(input);
      expect(output, equals('Line 1\nLine 2'));
    });

    test('清除粗体标记', () {
      final input = 'This is **bold** text';
      final output = cleaner.cleanMarkdown(input);
      expect(output, equals('This is bold text'));
    });

    test('清除斜体标记', () {
      final input = 'This is *italic* text';
      final output = cleaner.cleanMarkdown(input);
      expect(output, equals('This is italic text'));
    });

    test('清除链接语法', () {
      final input = 'Check [this link](https://example.com)';
      final output = cleaner.cleanMarkdown(input);
      expect(output, equals('Check this link'));
    });

    test('保留标题标记', () {
      final input = '# Title 1\n## Title 2\n### Title 3';
      final output = cleaner.cleanMarkdown(input);
      expect(output, equals(input));
    });

    test('保留列表标记', () {
      final input = '- Item 1\n- Item 2\n1. Numbered item';
      final output = cleaner.cleanMarkdown(input);
      expect(output, equals(input));
    });

    test('转换为纯文本', () {
      final input = '''# Title
*Italic* and **bold** text
- List item
[Link](url)''';

      final output = cleaner.toPlainText(input);
      expect(output, contains('Title'));
      expect(output, contains('Italic and bold text'));
      expect(output, contains('List item'));
      expect(output, contains('Link'));
      expect(output, isNot(contains('#')));
      expect(output, isNot(contains('*')));
      expect(output, isNot(contains('[')));
    });

    test('智能清洗保留结构', () {
      final input = '''# Main Title

This is *important* text.

## Subtitle

- List item 1
- List item 2''';

      final output = cleaner.cleanSmart(input);
      expect(output, contains('# Main Title'));
      expect(output, contains('## Subtitle'));
      expect(output, contains('- List item'));
      expect(output, isNot(contains('*important*')));
    });

    test('轻量清洗只清理明显问题', () {
      final input = 'Text  \n\n\n\nMore text';
      final output = cleaner.cleanLight(input);
      expect(output, equals('Text\n\nMore text'));
    });

    test('格式信息检测', () {
      final markdownText = '''# Title
* Item 1
* Item 2''';

      final info = cleaner.detectFormat(markdownText);
      expect(info.hasMarkdown, isTrue);
      expect(info.markdownHeaderCount, equals(1));
      expect(info.markdownListCount, equals(2));
    });

    test('HTML标签检测', () {
      final htmlText = '<p>Paragraph</p>\n<div>Content</div>';
      final info = cleaner.detectFormat(htmlText);
      expect(info.hasHTML, isTrue);
      expect(info.htmlTagCount, equals(2));
    });

    test('清洗预览生成', () {
      final input = 'Text with **bold** and *italic*\n\n\n\nExtra spaces';
      final previews = cleaner.getCleanPreview(input);

      expect(previews, isNotEmpty);
      expect(previews.any((p) => p.description.contains('粗体')), isTrue);
      expect(previews.any((p) => p.description.contains('空行')), isTrue);
    });
  });

  group('Editor Integration Tests', () {
    test('完整的编辑工作流', () {
      final controller = EditorTextController();
      final cleaner = FormatCleaner();

      // 1. 输入文本
      controller.text = 'This is **sample** text with *formatting*.';

      // 2. 选择和替换
      controller.value = controller.value.copyWith(
        selection: TextSelection(baseOffset: 10, extentOffset: 17),
      );
      controller.replaceSelection('clean');

      expect(controller.text, contains('clean'));

      // 3. 清洗格式
      final cleaned = cleaner.cleanMarkdown(controller.text);
      expect(cleaned, isNot(contains('**')));
      expect(cleaned, isNot(contains('*')));

      controller.dispose();
      cleaner.dispose();
    });

    test('思维碎片插入工作流', () {
      final controller = EditorTextController();

      // 1. 初始文本
      controller.text = 'Introduction paragraph.\n';

      // 2. 在光标位置插入碎片
      controller.value = controller.value.copyWith(
        selection: TextSelection.collapsed(offset: 22),
      );

      const fragment = 'Key insight: AI is changing the world.';
      controller.insertAtCursor('\n$fragment\n');

      expect(controller.text, contains(fragment));

      // 3. 清洗插入的文本
      final cleaner = FormatCleaner();
      final cleaned = cleaner.cleanLight(controller.text);

      expect(cleaned, contains(fragment));

      controller.dispose();
      cleaner.dispose();
    });
  });

  group('边界情况和错误处理', () {
    test('空文本处理', () {
      final controller = EditorTextController();
      final cleaner = FormatCleaner();

      expect(cleaner.cleanMarkdown(''), isEmpty);
      expect(cleaner.toPlainText(''), isEmpty);
      expect(cleaner.cleanLight(''), isEmpty);

      controller.dispose();
      cleaner.dispose();
    });

    test('撤销边界', () {
      final controller = EditorTextController();

      controller.text = 'Text';
      controller.undo();
      controller.undo();
      controller.undo();

      expect(controller.canUndo, isFalse);
      expect(controller.text, equals('Text'));

      controller.dispose();
    });

    test('重做边界', () {
      final controller = EditorTextController();

      controller.text = 'Text';
      controller.redo();
      controller.redo();

      expect(controller.canRedo, isFalse);

      controller.dispose();
    });

    test('选择边界处理', () {
      final controller = EditorTextController();
      controller.text = 'Hello World';

      // 无效选择
      controller.value = controller.value.copyWith(
        selection: const TextSelection.collapsed(offset: -1),
      );

      expect(controller.selectedText, isEmpty);

      // 超出范围的选择
      controller.value = controller.value.copyWith(
        selection: const TextSelection.collapsed(offset: 1000),
      );

      expect(controller.selectedText, isEmpty);

      controller.dispose();
    });

    test('特殊字符处理', () {
      final cleaner = FormatCleaner();

      final specialChars = 'Test with 🎉 emojis, 中文, and "quotes".';
      final cleaned = cleaner.cleanMarkdown(specialChars);

      expect(cleaned, contains('🎉'));
      expect(cleaned, contains('中文'));

      cleaner.dispose();
    });
  });
}
