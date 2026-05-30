import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/utils/natural_language_processor.dart';

void main() {
  group('NaturalLanguageProcessor', () {
    late NaturalLanguageProcessor processor;

    setUp(() {
      processor = NaturalLanguageProcessor();
    });

    test('应该能去除AI常用连接词', () {
      const input = '首先，这是一个测试。其次，我们继续测试。最后，测试完成。';
      final result = processor.process(input);

      expect(result, isNot(contains('首先')));
      expect(result, isNot(contains('其次')));
      expect(result, isNot(contains('最后')));
    });

    test('应该能替换机械表达', () {
      const input = '随着技术的发展，在当前背景下，基于考虑这个问题。';
      final result = processor.process(input);

      expect(result, contains('现在'));
      expect(result, contains('当下'));
    });

    test('应该能调整语气从正式到口语', () {
      const input = '实施这个计划，通过这种方式进行操作。';
      final result = processor.process(input);

      expect(result, isNot(contains('实施')));
      expect(result, isNot(contains('通过')));
    });

    test('应该能处理过度结构化的文本', () {
      const input = '首先，我们分析问题。其次，我们找到解决方案。最后，我们实施计划。';
      final result = processor.process(input);

      // 检查是否破坏了过度结构化
      expect(result, isNot(contains('首先，')));
      expect(result, isNot(contains('其次，')));
    });

    test('应该能记录替换统计', () {
      const input = '首先，然而，因此，此外，另外';
      processor.process(input);

      final stats = processor.getStatistics();
      expect(stats.totalReplacements, greaterThan(0));
      expect(stats.replacements.isNotEmpty, true);
    });

    test('应该能处理空文本', () {
      final result = processor.process('');
      expect(result, isEmpty);
    });

    test('应该能处理纯空格文本', () {
      final result = processor.process('   ');
      expect(result, '   ');
    });

    test('默认配置应该正确', () {
      const config = NaturalLanguageConfig.defaultConfig();
      expect(config.enabledRules, contains('connector'));
      expect(config.enabledRules, contains('mechanical'));
      expect(config.processingIntensity, 0.7);
    });

    test('最小配置应该只处理基本规则', () {
      const config = NaturalLanguageConfig.minimalConfig();
      expect(config.enabledRules.length, lessThan(4));
      expect(config.enabledRules, contains('connector'));
    });

    test('激进配置应该启用所有规则', () {
      const config = NaturalLanguageConfig.aggressiveConfig();
      expect(config.enabledRules.length, greaterThan(4));
      expect(config.processingIntensity, 1.0);
      expect(config.preserveFormatting, false);
    });
  });

  group('ReplacementRule', () {
    test('应该能正确匹配模式', () {
      final rule = ReplacementRule(
        category: 'test',
        pattern: r'首先[，,]?\s*',
        replacements: ['替换词'],
      );

      final pattern = RegExp(rule.pattern, caseSensitive: false);
      expect(pattern.hasMatch('首先，'), true);
      expect(pattern.hasMatch('首先,'), true);
      expect(pattern.hasMatch('首先 '), true);
      expect(pattern.hasMatch('首先'), true);
    });
  });

  group('NaturalLanguageABTester', () {
    test('应该能比较两种配置', () {
      final tester = NaturalLanguageABTester(
        configA: NaturalLanguageConfig.minimalConfig(),
        configB: NaturalLanguageConfig.aggressiveConfig(),
      );

      const input = '首先，然而，因此';
      final results = tester.compare(input);

      expect(results, containsPair('original', input));
      expect(results, containsPair('version_a', isA<String>()));
      expect(results, containsPair('version_b', isA<String>()));
      expect(results['version_a'], isNot(equals(results['version_b'])));
    });
  });

  group('BatchNaturalLanguageProcessor', () {
    test('应该能批量处理文本', () {
      final processor = BatchNaturalLanguageProcessor();
      final texts = [
        '首先，测试1。然而，测试1。',
        '其次，测试2。因此，测试2。',
        '最后，测试3。此外，测试3。',
      ];

      final results = processor.processBatch(texts);

      expect(results.length, texts.length);
      for (final result in results) {
        expect(result, isNot(contains('首先')));
        expect(result, isNot(contains('然而')));
      }
    });

    test('应该能返回批量处理统计', () {
      final processor = BatchNaturalLanguageProcessor();
      const texts = [
        '首先，测试。',
        '然而，测试。',
        '因此，测试。',
      ];

      final results = processor.processBatchWithStats(texts);

      expect(results, containsPair('results', isA<List>()));
      expect(results, containsPair('statistics', isA<Map>()));
      expect(
          results['statistics'], containsPair('totalReplacements', isA<int>()));
    });
  });

  group('实际应用场景测试', () {
    late NaturalLanguageProcessor processor;

    setUp(() {
      processor = NaturalLanguageProcessor();
    });

    test('应该能处理真实的AI生成文本', () {
      const aiGeneratedText = '''
        首先，人工智能技术在近年来取得了显著进展。其次，深度学习算法的优化使得模型性能大幅提升。
        此外，计算资源的增加为大规模应用提供了基础。然而，数据隐私问题仍然需要重视。
        因此，建立完善的监管机制至关重要。最后，我们可以预见AI技术将在更多领域发挥重要作用。
        总的来说，这是一个充满机遇的时代。诚然，挑战依然存在，但毋庸置疑的是，技术进步的趋势不可逆转。
        事实上，许多行业已经开始受益于AI技术。值得注意的是，这种变化是深远的。
      ''';

      final result = processor.process(aiGeneratedText);

      // 检查AI常用词是否被替换
      expect(result, isNot(contains('首先，')));
      expect(result, isNot(contains('其次，')));
      expect(result, isNot(contains('此外，')));
      expect(result, isNot(contains('然而，')));
      expect(result, isNot(contains('因此，')));
      expect(result, isNot(contains('最后，')));
      expect(result, isNot(contains('总的来说，')));
      expect(result, isNot(contains('诚然，')));
      expect(result, isNot(contains('毋庸置疑，')));
      expect(result, isNot(contains('事实上，')));
      expect(result, isNot(contains('值得注意的是，')));

      // 检查文本仍然保持意义
      expect(result, contains('人工智能'));
      expect(result, contains('技术'));
    });

    test('应该能保留原始内容的语义', () {
      const input = '这是一个重要的概念。然而，很多人理解有误。';
      final result = processor.process(input);

      // 检查关键信息被保留
      expect(result, contains('重要'));
      expect(result, contains('概念'));
      expect(result, contains('理解'));
      expect(result, contains('误'));
    });

    test('应该能处理混合内容', () {
      const mixedContent = '''
        这是一段正常的文本。

        首先，这里是AI生成的内容。其次，这里有更多的AI内容。最后，这里是结论。

        回到正常文本内容。
      ''';

      final result = processor.process(mixedContent);

      // AI生成部分应该被处理
      expect(result, isNot(contains('首先，')));
      expect(result, isNot(contains('其次，')));

      // 正常文本应该保持
      expect(result, contains('正常的文本'));
    });

    test('应该能处理专业术语', () {
      const technicalText = '''
        在机器学习领域，首先需要理解基本概念。其次，要掌握常用算法。
        此外，实践经验同样重要。因此，建议从简单项目开始。
      ''';

      final result = processor.process(technicalText);

      // 专业术语应该被保留
      expect(result, contains('机器学习'));
      expect(result, contains('算法'));
      expect(result, contains('项目'));

      // AI连接词应该被替换
      expect(result, isNot(contains('首先，')));
      expect(result, isNot(contains('其次，')));
    });
  });

  group('配置测试', () {
    test('应该能根据配置选择性应用规则', () {
      final config = NaturalLanguageConfig(
        enabledRules: {'connector'}, // 只启用连接词规则
        processingIntensity: 0.8,
      );

      final processor = NaturalLanguageProcessor(config: config);
      const input = '首先，实施这个计划。通过这种方式进行操作。';

      final result = processor.process(input);

      // 连接词应该被处理
      expect(result, isNot(contains('首先，')));

      // 机械表达应该被保留（因为规则未启用）
      expect(result, contains('实施'));
    });

    test('应该能配置保护短语', () {
      final config = NaturalLanguageConfig(
        enabledRules: {'connector', 'formal_casual'},
        protectedPhrases: ['首先考虑到'],
      );

      final processor = NaturalLanguageProcessor(config: config);
      const input = '首先考虑到这个问题很重要。首先，我们需要分析。';

      final result = processor.process(input);

      // 第二个"首先"应该被处理
      expect(result, isNot(contains('首先，我们需要分析')));
    });
  });

  group('边界情况测试', () {
    late NaturalLanguageProcessor processor;

    setUp(() {
      processor = NaturalLanguageProcessor();
    });

    test('应该能处理只包含AI连接词的文本', () {
      const input = '首先。其次。最后。然而。因此。';
      final result = processor.process(input);

      // 应该被大幅修改
      expect(result, isNot(equals(input)));
    });

    test('应该能处理很长的文本', () {
      final longText = List.generate(1000, (i) => '首先，这是第$i个句子。').join('');
      final result = processor.process(longText);

      expect(result, isNot(contains('首先，')));
    });

    test('应该能处理包含特殊字符的文本', () {
      final specialText = '首先，这是测试！@#\$%^&*()然而，继续测试123456789';
      final result = processor.process(specialText);

      expect(result, contains('测试'));
      expect(result, contains(RegExp(r'[!@#\$%^&*()]')));
      expect(result, contains('123456789'));
    });

    test('应该能处理中英文混合文本', () {
      final mixedText = '首先，这是一个test。However，this is English text。';
      final result = processor.process(mixedText);

      expect(result, contains('test'));
      expect(result, contains('English'));
      expect(result, isNot(contains('首先，')));
    });
  });
}
