/// 反AI味处理系统演示脚本
/// 展示如何使用自然语言处理器去除AI生成文本的机械味道

import 'package:museflow/utils/natural_language_processor.dart';

void main() {
  print('=== MuseFlow 反AI味处理系统演示 ===\n');

  // 演示1: 基础处理
  demonstrateBasicProcessing();

  // 演示2: 配置对比
  demonstrateConfigComparison();

  // 演示3: 真实AI文本处理
  demonstrateRealAITextProcessing();

  // 演示4: 批量处理
  demonstrateBatchProcessing();

  // 演示5: A/B测试
  demonstrateABTesting();

  print('=== 演示完成 ===');
}

/// 演示基础处理功能
void demonstrateBasicProcessing() {
  print('【演示1】基础处理功能');
  print('-' * 50);

  final processor = NaturalLanguageProcessor();

  final aiText = '''
    首先，人工智能技术在近年来取得了显著进展。
    其次，深度学习算法的优化使得模型性能大幅提升。
    此外，计算资源的增加为大规模应用提供了基础。
    然而，数据隐私问题仍然需要重视。
    因此，建立完善的监管机制至关重要。
    最后，我们可以预见AI技术将在更多领域发挥重要作用。
  ''';

  print('原始文本:');
  print(aiText);

  final processed = processor.process(aiText);

  print('\n处理后文本:');
  print(processed);

  final stats = processor.getStatistics();
  print('\n处理统计:');
  print(stats);

  print('\n');
}

/// 演示不同配置的对比效果
void demonstrateConfigComparison() {
  print('【演示2】配置对比');
  print('-' * 50);

  final testText = '首先，这是一个重要概念。然而，很多人理解有误。因此，需要澄清。';

  print('原始文本:');
  print(testText);
  print('');

  // 最小配置
  final minimalProcessor = NaturalLanguageProcessor(
    config: NaturalLanguageConfig.minimalConfig(),
  );
  final minimalResult = minimalProcessor.process(testText);

  print('最小配置处理结果:');
  print(minimalResult);
  print('');

  // 默认配置
  final defaultProcessor = NaturalLanguageProcessor(
    config: NaturalLanguageConfig.defaultConfig(),
  );
  final defaultResult = defaultProcessor.process(testText);

  print('默认配置处理结果:');
  print(defaultResult);
  print('');

  // 激进配置
  final aggressiveProcessor = NaturalLanguageProcessor(
    config: NaturalLanguageConfig.aggressiveConfig(),
  );
  final aggressiveResult = aggressiveProcessor.process(testText);

  print('激进配置处理结果:');
  print(aggressiveResult);
  print('\n');
}

/// 演示真实AI文本处理
void demonstrateRealAITextProcessing() {
  print('【演示3】真实AI文本处理');
  print('-' * 50);

  final processor = NaturalLanguageProcessor();

  final realAIText = '''
    在当前的科技发展趋势下，人工智能技术正在改变各行各业。
    首先，自动化技术的普及提高了生产效率。其次，数据分析能力的增强使得决策更加科学。
    诚然，技术进步带来了新的挑战。毋庸置疑的是，这些挑战是可以克服的。
    事实上，许多企业已经开始从中受益。值得注意的是，这种变革是深远的。
    综上所述，我们需要积极拥抱技术进步，同时妥善处理相关问题。
  ''';

  print('真实AI生成的文本:');
  print(realAIText);

  final naturalText = processor.process(realAIText);

  print('\n自然化处理后的文本:');
  print(naturalText);

  print('\n主要改动:');
  print('• 去除机械连接词: "首先"、"其次"、"诚然"等');
  print('• 替换正式表达: "综上所述"、"毋庸置疑"等');
  print('• 调整句子结构，使表达更自然');
  print('\n');
}

/// 演示批量处理功能
void demonstrateBatchProcessing() {
  print('【演示4】批量处理');
  print('-' * 50);

  final batchProcessor = BatchNaturalLanguageProcessor();

  final texts = [
    '首先，这是第一个文本。然而，需要进一步说明。',
    '其次，这是第二个文本。因此，结论很重要。',
    '最后，这是第三个文本。总之，处理完成。',
  ];

  print('原始文本列表:');
  texts.forEach((text) => print('  • $text'));

  final results = batchProcessor.processBatch(texts);

  print('\n处理后文本列表:');
  results.forEach((text) => print('  • $text'));

  print('\n');
}

/// 演示A/B测试功能
void demonstrateABTesting() {
  print('【演示5】A/B测试');
  print('-' * 50);

  final tester = NaturalLanguageABTester(
    configA: NaturalLanguageConfig.minimalConfig(),
    configB: NaturalLanguageConfig.aggressiveConfig(),
  );

  final testText = '''
    首先，我们需要了解背景。其次，要分析问题。
    此外，还需考虑各种因素。因此，解决方案需要综合考量。
  ''';

  print('测试文本:');
  print(testText);

  final comparison = tester.compare(testText);

  print('\n配置A (最小配置) 结果:');
  print(comparison['version_a']);

  print('\n配置B (激进配置) 结果:');
  print(comparison['version_b']);

  print('\n推荐:');
  print('对于日常使用，建议使用默认配置以获得最佳的自然度。');
  print('对于保守内容，使用最小配置保留更多原始表达。');
  print('对于创意内容，使用激进配置获得最自然的表达。');

  print('\n');
}

/// 实际应用示例
class PracticalExamples {
  static void demonstrateEditorIntegration() {
    print('【实际应用】编辑器集成示例');
    print('-' * 50);

    // 模拟编辑器中的AI辅助功能
    final processor = NaturalLanguageProcessor();

    final userText = '随着技术的发展，在当前背景下，基于考虑这个问题。';
    print('用户输入:');
    print(userText);

    final enhanced = processor.process(userText);
    print('\nAI增强后:');
    print(enhanced);

    print('\n在MuseFlow编辑器中，这个过程是自动的。');
    print('当用户使用AI润色、扩写等功能时，系统会自动应用反AI味处理。');
    print('\n');
  }

  static void demonstrateContentOptimization() {
    print('【实际应用】内容优化示例');
    print('-' * 50);

    final processor = NaturalLanguageProcessor();

    final blogPost = '''
      首先，在这篇文章中我们将探讨编程的重要性。
      其次，我们会分析学习编程的最佳路径。
      此外，还将分享实用的学习资源。
      然而，需要强调的是实践的重要性。
      因此，建议大家多动手编写代码。
      最后，希望能对读者的编程学习有所帮助。
    ''';

    print('原始博客文章:');
    print(blogPost);

    final optimized = processor.process(blogPost);

    print('\n优化后的博客文章:');
    print(optimized);

    print('\n优化效果:');
    print('• 去除了机械的"首先、其次、最后"结构');
    print('• 使表达更加自然流畅');
    print('• 提升了文章的可读性');
    print('\n');
  }
}