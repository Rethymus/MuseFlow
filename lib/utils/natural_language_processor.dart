/// 自然语言处理器
/// 专门用于去除AI生成文本的"AI味"，使内容更加自然人性化
class NaturalLanguageProcessor {
  // 处理配置
  final NaturalLanguageConfig config;

  // 统计信息
  final ProcessingStatistics _stats = ProcessingStatistics();

  NaturalLanguageProcessor({
    NaturalLanguageConfig? config,
  }) : config = config ?? NaturalLanguageConfig.defaultConfig();

  /// 处理文本，去除AI味道
  String process(String text) {
    if (text.trim().isEmpty) return text;

    _stats.reset();
    String processedText = text;

    // 1. 替换AI常用连接词
    processedText = _replaceConnectors(processedText);

    // 2. 修复机械表达
    processedText = _fixMechanicalExpressions(processedText);

    // 3. 优化句式结构
    processedText = _optimizeSentenceStructure(processedText);

    // 4. 调整语气和节奏
    processedText = _adjustToneAndRhythm(processedText);

    // 5. 去除重复表达
    processedText = _removeRedundancy(processedText);

    return processedText;
  }

  /// 替换AI常用连接词
  String _replaceConnectors(String text) {
    String result = text;

    // 使用规则库进行替换
    for (final rule in _connectorRules) {
      if (!config.enabledRules.contains(rule.category)) continue;

      final pattern = RegExp(rule.pattern, caseSensitive: false);
      result = result.replaceAllMapped(pattern, (match) {
        _stats.recordReplacement(rule.category, match.group(0)!);

        // 智能选择替换词
        final replacements = rule.replacements;
        final replacement = _selectReplacement(replacements, match.group(0)!);

        return replacement;
      });
    }

    return result;
  }

  /// 修复机械表达
  String _fixMechanicalExpressions(String text) {
    String result = text;

    for (final rule in _mechanicalRules) {
      if (!config.enabledRules.contains(rule.category)) continue;

      final pattern = RegExp(rule.pattern, caseSensitive: false);
      result = result.replaceAllMapped(pattern, (match) {
        _stats.recordReplacement(rule.category, match.group(0)!);
        return rule.replacements.first;
      });
    }

    return result;
  }

  /// 优化句式结构
  String _optimizeSentenceStructure(String text) {
    String result = text;

    // 修复过度整齐的结构
    result = _fixOverlyStructuredText(result);

    // 调整句子长度变化
    result = _varySentenceLength(result);

    return result;
  }

  /// 调整语气和节奏
  String _adjustToneAndRhythm(String text) {
    String result = text;

    // 调整标点符号使用
    result = _adjustPunctuation(result);

    // 修改过于正式的表达
    result = _formalToCasual(result);

    return result;
  }

  /// 去除重复表达
  String _removeRedundancy(String text) {
    String result = text;

    // 去除重复的强调词
    result = result.replaceAllMapped(
      RegExp(r'(非常|特别|极其|相当)\s*\1+', caseSensitive: false),
      (match) => match.group(1)!,
    );

    // 去除重复的连接词
    result = result.replaceAllMapped(
      RegExp(r'(因此|所以|因而)\s*[，,]\s*(因此|所以|因而)', caseSensitive: false),
      (match) => match.group(1)!,
    );

    return result;
  }

  /// 智能选择替换词
  String _selectReplacement(List<String> replacements, String original) {
    if (replacements.isEmpty) return original;
    if (replacements.length == 1) return replacements[0];

    // 随机选择，避免机械性
    return replacements[
        DateTime.now().millisecondsSinceEpoch % replacements.length];
  }

  /// 修复过度结构化的文本
  String _fixOverlyStructuredText(String text) {
    String result = text;

    // 检测过多的"首先、其次、最后"结构
    final structurePattern = RegExp(
      r'首先.*?其次.*?(最后|最终)',
      caseSensitive: false,
      dotAll: true,
    );

    if (structurePattern.hasMatch(result)) {
      _stats.recordReplacement('structure', '过度结构化');
      result = result.replaceAllMapped(structurePattern, (match) {
        final matchedText = match.group(0)!;
        // 移除明显的结构标记
        return matchedText
            .replaceAll(RegExp(r'首先[，,]?\s*', caseSensitive: false), '一方面，')
            .replaceAll(RegExp(r'其次[，,]?\s*', caseSensitive: false), '另一方面，')
            .replaceAll(RegExp(r'(最后|最终)[，,]?\s*', caseSensitive: false), '此外');
      });
    }

    return result;
  }

  /// 变化句子长度
  String _varySentenceLength(String text) {
    // 检测过多的短句
    final sentences = text.split(RegExp(r'[。！？]'));
    if (sentences.length < 3) return text;

    final shortSentenceCount =
        sentences.where((s) => s.isNotEmpty && s.length < 15).length;

    if (shortSentenceCount / sentences.length > 0.7) {
      _stats.recordReplacement('sentence_length', '过多短句');
      // 这里可以合并短句，但保持简单处理
    }

    return text;
  }

  /// 调整标点符号
  String _adjustPunctuation(String text) {
    String result = text;

    // 减少感叹号的使用
    final exclamationCount = '!'.allMatches(result).length;
    if (exclamationCount > 3) {
      result = result.replaceAll('!', '。');
      _stats.recordReplacement('punctuation', '过多感叹号');
    }

    // 调整顿号使用
    result = result.replaceAll('、', '，');

    return result;
  }

  /// 正式转口语
  String _formalToCasual(String text) {
    String result = text;

    for (final rule in _formalToCasualRules) {
      if (!config.enabledRules.contains(rule.category)) continue;

      final pattern = RegExp(rule.pattern, caseSensitive: false);
      result = result.replaceAllMapped(pattern, (match) {
        _stats.recordReplacement(rule.category, match.group(0)!);
        return rule.replacements.first;
      });
    }

    return result;
  }

  /// 获取处理统计信息
  ProcessingStatistics getStatistics() => _stats;

  /// 重置统计信息
  void resetStatistics() {
    _stats.reset();
  }

  // ===== 规则库 =====

  static final List<ReplacementRule> _connectorRules = [
    // 开头连接词
    ReplacementRule(
      category: 'connector',
      pattern: r'总之[，,]?\s*',
      replacements: ['总的来说，', '简单来说，', '换句话说，', '归纳起来，', ''],
    ),
    ReplacementRule(
      category: 'connector',
      pattern: r'然而[，,]?\s*',
      replacements: ['不过，', '但是，', '只是，', '可是，', '但其实，'],
    ),
    ReplacementRule(
      category: 'connector',
      pattern: r'因此[，,]?\s*',
      replacements: ['所以，', '这就是为什么，', '正因如此，', '难怪，', ''],
    ),
    ReplacementRule(
      category: 'connector',
      pattern: r'此外[，,]?\s*',
      replacements: ['而且，', '还有，', '再加上，', '另外，', '值得一提的是，'],
    ),
    ReplacementRule(
      category: 'connector',
      pattern: r'另外[，,]?\s*',
      replacements: ['而且', '还有', '同时', '再者', ''],
    ),
    ReplacementRule(
      category: 'connector',
      pattern: r'首先[，,]?\s*',
      replacements: ['一方面，', '先说', '一来', '最开始', ''],
    ),
    ReplacementRule(
      category: 'connector',
      pattern: r'其次[，,]?\s*',
      replacements: ['另一方面，', '再说', '二来', '接着', '然后'],
    ),
    ReplacementRule(
      category: 'connector',
      pattern: r'最后[，,]?\s*',
      replacements: ['最终', '结果', '到了最后', '这样一来', ''],
    ),
    ReplacementRule(
      category: 'connector',
      pattern: r'值得注意的是[，,]?\s*',
      replacements: ['值得一提的是，', '特别要强调的是，', '关键在于，', '最重要的是，', ''],
    ),
    ReplacementRule(
      category: 'connector',
      pattern: r'显而易见[，,]?\s*',
      replacements: ['很明显，', '可以清楚看到，', '不难发现，', '大家都能看出，', ''],
    ),
    ReplacementRule(
      category: 'connector',
      pattern: r'诚然[，,]?\s*',
      replacements: ['虽然', '的确', '确实', '话虽这么说', ''],
    ),
    ReplacementRule(
      category: 'connector',
      pattern: r'毋庸置疑[，,]?\s*',
      replacements: ['毫无疑问', '显然', '肯定的是', '必须承认', ''],
    ),
    ReplacementRule(
      category: 'connector',
      pattern: r'综上所述[，,]?\s*',
      replacements: ['总的来说', '综合来看', '整体而言', '概括起来', ''],
    ),
    ReplacementRule(
      category: 'connector',
      pattern: r'换句话说[，,]?\s*',
      replacements: ['也就是说', '换句话说就是', '换个说法', '更准确地说', ''],
    ),
    ReplacementRule(
      category: 'connector',
      pattern: r'事实上[，,]?\s*',
      replacements: ['实际上', '其实', '说真的', '老实说', ''],
    ),
    ReplacementRule(
      category: 'connector',
      pattern: r'实际上[，,]?\s*',
      replacements: ['其实', '事实上', '实际上', '说白了', ''],
    ),
  ];

  static final List<ReplacementRule> _mechanicalRules = [
    ReplacementRule(
      category: 'mechanical',
      pattern: r'随着.*?的发展',
      replacements: ['现在', '当下', '如今'],
    ),
    ReplacementRule(
      category: 'mechanical',
      pattern: r'在.*?背景下',
      replacements: ['考虑到这个情况', '在这个基础上', '基于此'],
    ),
    ReplacementRule(
      category: 'mechanical',
      pattern: r'基于.*?考虑',
      replacements: ['考虑到', '想到', '从...角度'],
    ),
    ReplacementRule(
      category: 'mechanical',
      pattern: r'从.*?角度来看',
      replacements: ['在...方面', '就...而言', '从...说'],
    ),
    ReplacementRule(
      category: 'mechanical',
      pattern: r'在.*?方面(?!的)',
      replacements: ['在...上', '对于...', '关于...'],
    ),
  ];

  static final List<ReplacementRule> _formalToCasualRules = [
    ReplacementRule(
      category: 'formal_casual',
      pattern: r'实施',
      replacements: ['做', '执行', '开展'],
    ),
    ReplacementRule(
      category: 'formal_casual',
      pattern: r'进行',
      replacements: ['做', '搞', '弄'],
    ),
    ReplacementRule(
      category: 'formal_casual',
      pattern: r'相较于',
      replacements: ['比起', '和...比起来', '相对于'],
    ),
    ReplacementRule(
      category: 'formal_casual',
      pattern: r'通过.*?方式',
      replacements: ['用...方法', '以...方式', '靠...'],
    ),
    ReplacementRule(
      category: 'formal_casual',
      pattern: r'使得',
      replacements: ['让', '使', '叫'],
    ),
    ReplacementRule(
      category: 'formal_casual',
      pattern: r'从而',
      replacements: ['这样就能', '这样一来', '于是'],
    ),
    ReplacementRule(
      category: 'formal_casual',
      pattern: r'予以',
      replacements: ['给', '加以', '进行'],
    ),
    ReplacementRule(
      category: 'formal_casual',
      pattern: r'所谓',
      replacements: ['大家说的', '常说的', '所谓的'],
    ),
  ];
}

/// 替换规则
class ReplacementRule {
  final String category;
  final String pattern;
  final List<String> replacements;

  ReplacementRule({
    required this.category,
    required this.pattern,
    required this.replacements,
  });
}

/// 处理配置
class NaturalLanguageConfig {
  final Set<String> enabledRules;
  final double processingIntensity;
  final bool preserveFormatting;
  final List<String> protectedPhrases;

  NaturalLanguageConfig({
    required this.enabledRules,
    this.processingIntensity = 0.7,
    this.preserveFormatting = true,
    this.protectedPhrases = const [],
  });

  factory NaturalLanguageConfig.defaultConfig() {
    return NaturalLanguageConfig(
      enabledRules: {
        'connector',
        'mechanical',
        'formal_casual',
        'structure',
        'sentence_length',
        'punctuation',
      },
      processingIntensity: 0.7,
      preserveFormatting: true,
      protectedPhrases: [],
    );
  }

  factory NaturalLanguageConfig.minimalConfig() {
    return NaturalLanguageConfig(
      enabledRules: {'connector', 'mechanical'},
      processingIntensity: 0.5,
      preserveFormatting: true,
    );
  }

  factory NaturalLanguageConfig.aggressiveConfig() {
    return NaturalLanguageConfig(
      enabledRules: {
        'connector',
        'mechanical',
        'formal_casual',
        'structure',
        'sentence_length',
        'punctuation',
      },
      processingIntensity: 1.0,
      preserveFormatting: false,
    );
  }

  NaturalLanguageConfig copyWith({
    Set<String>? enabledRules,
    double? processingIntensity,
    bool? preserveFormatting,
    List<String>? protectedPhrases,
  }) {
    return NaturalLanguageConfig(
      enabledRules: enabledRules ?? this.enabledRules,
      processingIntensity: processingIntensity ?? this.processingIntensity,
      preserveFormatting: preserveFormatting ?? this.preserveFormatting,
      protectedPhrases: protectedPhrases ?? this.protectedPhrases,
    );
  }
}

/// 处理统计信息
class ProcessingStatistics {
  final Map<String, List<String>> replacements = {};
  int totalReplacements = 0;

  void recordReplacement(String category, String original) {
    replacements.putIfAbsent(category, () => []);
    replacements[category]!.add(original);
    totalReplacements++;
  }

  void reset() {
    replacements.clear();
    totalReplacements = 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalReplacements': totalReplacements,
      'replacementsByCategory': replacements.map(
        (category, items) => MapEntry(category, items.length),
      ),
    };
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('处理统计:');
    buffer.writeln('总替换次数: $totalReplacements');

    for (final entry in replacements.entries) {
      buffer.writeln('  ${entry.key}: ${entry.value.length}次');
    }

    return buffer.toString();
  }
}

/// A/B测试支持
class NaturalLanguageABTester {
  final NaturalLanguageProcessor processorA;
  final NaturalLanguageProcessor processorB;

  NaturalLanguageABTester({
    required NaturalLanguageConfig configA,
    required NaturalLanguageConfig configB,
  })  : processorA = NaturalLanguageProcessor(config: configA),
        processorB = NaturalLanguageProcessor(config: configB);

  Map<String, String> compare(String text) {
    return {
      'original': text,
      'version_a': processorA.process(text),
      'version_b': processorB.process(text),
      'stats_a': processorA.getStatistics().toString(),
      'stats_b': processorB.getStatistics().toString(),
    };
  }
}

/// 批量处理支持
class BatchNaturalLanguageProcessor {
  final NaturalLanguageProcessor processor;

  BatchNaturalLanguageProcessor({
    NaturalLanguageConfig? config,
  }) : processor = NaturalLanguageProcessor(config: config);

  List<String> processBatch(List<String> texts) {
    return texts.map((text) => processor.process(text)).toList();
  }

  Map<String, dynamic> processBatchWithStats(List<String> texts) {
    processor.resetStatistics();

    final results = texts.map((text) => processor.process(text)).toList();

    return {
      'results': results,
      'statistics': processor.getStatistics().toJson(),
    };
  }
}
