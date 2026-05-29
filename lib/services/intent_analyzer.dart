import '../utils/logger.dart';
import '../config/app_constants.dart';
import 'package:flutter/foundation.dart';
import '../models/intent_confirmation.dart';

/// 意图分析器服务
/// 负责分析用户的AI操作请求，生成可理解的意图确认
class IntentAnalyzer {
  // 配置选项
  final IntentAnalyzerConfig config;

  // 反馈历史（用于学习和改进）
  final List<IntentConfirmationFeedback> _feedbackHistory = [];

  const IntentAnalyzer({this.config = const IntentAnalyzerConfig()});

  /// 分析AI操作请求并生成意图确认
  IntentConfirmation analyzeRequest({
    required AIActionType actionType,
    required String originalText,
    Map<String, dynamic>? additionalParams,
  }) {
    // 根据操作类型生成相应的意图确认
    switch (actionType) {
      case AIActionType.polish:
        return _analyzePolishIntent(originalText, additionalParams);
      case AIActionType.expand:
        return _analyzeExpandIntent(originalText, additionalParams);
      case AIActionType.outline:
        return _analyzeOutlineIntent(originalText, additionalParams);
      case AIActionType.summarize:
        return _analyzeSummarizeIntent(originalText, additionalParams);
      case AIActionType.changeStyle:
        return _analyzeChangeStyleIntent(originalText, additionalParams);
      case AIActionType.smartReplace:
        return _analyzeSmartReplaceIntent(originalText, additionalParams);
    }
  }

  /// 分析润色意图
  IntentConfirmation _analyzePolishIntent(String text, Map<String, dynamic>? params) {
    final context = params?['context'] as String? ?? '';
    final textLength = text.length;

    // 分析文本特征
    final analysis = _analyzeTextCharacteristics(text);

    // 生成个性化的解释
    String explanation = '我将润色选中的文本';
    if (analysis.hasGrammarIssues) {
      explanation += '，重点修正语法错误和表达不当之处';
    }
    if (analysis.isRepetitive) {
      explanation += '，减少重复表达，使语言更加精练';
    }
    if (analysis.isInformal) {
      explanation += '，适当提升表达的专业性和准确性';
    }
    if (context.isNotEmpty) {
      explanation += '，参考上下文内容使表达更加连贯自然';
    } else {
      explanation += '，使其更加通顺流畅';
    }

    // 生成预期效果
    String expectedOutcome = '润色后的文本';
    if (analysis.hasGrammarIssues) {
      expectedOutcome += '将修正语法错误';
    }
    expectedOutcome += '，表达更加简洁流畅';
    if (analysis.isInformal) {
      expectedOutcome += '，用词更加准确专业';
    }
    expectedOutcome += '。';

    return IntentConfirmation(
      id: IntentConfirmation.generateId(),
      actionType: AIActionType.polish,
      description: _generatePolishDescription(analysis),
      originalText: text,
      parameters: {
        'context': context,
        'preserve_original': true,
        'style_level': _determineStyleLevel(analysis),
        'text_length': textLength,
      },
      explanation: explanation,
      expectedOutcome: expectedOutcome,
    );
  }

  /// 分析扩写意图
  IntentConfirmation _analyzeExpandIntent(String text, Map<String, dynamic>? params) {
    final context = params?['context'] as String? ?? '';
    final targetLength = params?['targetLength'] as int? ?? text.length * 2;

    final analysis = _analyzeTextCharacteristics(text);

    // 生成个性化的解释
    String explanation = '我将根据原文核心观点进行扩写';
    if (analysis.isAbstract) {
      explanation += '，添加具体的例子和细节说明';
    }
    if (analysis.isShort) {
      explanation += '，丰富内容和表达层次';
    }
    if (context.isNotEmpty) {
      explanation += '，结合上下文内容使扩写更加连贯';
    } else {
      explanation += '，确保扩写内容自然衔接';
    }

    // 生成预期效果
    final expansionRatio = (targetLength / text.length).toStringAsFixed(1);
    String expectedOutcome = '扩写后的文本将保持原文核心观点，内容扩充约${expansionRatio}倍';
    if (analysis.isAbstract) {
      expectedOutcome += '，包含具体的例子和细节';
    }
    expectedOutcome += '。';

    return IntentConfirmation(
      id: IntentConfirmation.generateId(),
      actionType: AIActionType.expand,
      description: '对选中文本进行扩写，目标长度约${targetLength}字',
      originalText: text,
      parameters: {
        'context': context,
        'target_length': targetLength,
        'expand_ratio': expansionRatio,
      },
      explanation: explanation,
      expectedOutcome: expectedOutcome,
    );
  }

  /// 分析大纲意图
  IntentConfirmation _analyzeOutlineIntent(String text, Map<String, dynamic>? params) {
    final maxItems = params?['maxItems'] as int? ?? 10;
    final sentences = text.split(RegExp(r'[。！？\n]'));
    final actualSentences = sentences.where((s) => s.trim().isNotEmpty).length;

    return IntentConfirmation(
      id: IntentConfirmation.generateId(),
      actionType: AIActionType.outline,
      description: '为全文生成结构化大纲，包含主要观点和论据',
      originalText: text,
      parameters: {
        'max_items': maxItems,
        'total_sentences': actualSentences,
        'numbering_style': 'numeric',
      },
      explanation: '我将分析全文内容（约${actualSentences}个句子），提取主要观点和论据，按逻辑层次生成结构化大纲。',
      expectedOutcome: '生成的大纲将使用数字编号，包含${actualSentences.clamp(3, maxItems)}个要点，层次清晰，简洁明了。',
    );
  }

  /// 分析摘要意图
  IntentConfirmation _analyzeSummarizeIntent(String text, Map<String, dynamic>? params) {
    final maxLength = params?['maxLength'] as int? ?? 100;
    final textLength = text.length;
    final compressionRatio = (maxLength / textLength * 100).toStringAsFixed(0);

    return IntentConfirmation(
      id: IntentConfirmation.generateId(),
      actionType: AIActionType.summarize,
      description: '为选中文本生成摘要，压缩至约$maxLength字',
      originalText: text,
      parameters: {
        'max_length': maxLength,
        'original_length': textLength,
        'compression_ratio': compressionRatio,
      },
      explanation: '我将提取文本的核心信息，保持逻辑连贯，将${textLength}字的原文压缩为约$maxLength字的摘要。',
      expectedOutcome: '摘要将包含文本的核心信息，逻辑连贯，简洁明确，压缩率约${compressionRatio}%。',
    );
  }

  /// 分析风格转换意图
  IntentConfirmation _analyzeChangeStyleIntent(String text, Map<String, dynamic>? params) {
    final targetStyle = params?['targetStyle'] as String? ?? '正式';

    return IntentConfirmation(
      id: IntentConfirmation.generateId(),
      actionType: AIActionType.changeStyle,
      description: '将选中文本转换为$targetStyle风格',
      originalText: text,
      parameters: {
        'target_style': targetStyle,
        'preserve_core_info': true,
      },
      explanation: '我将调整文本的表达方式以匹配$targetStyle风格的特点，同时保持核心信息不变，确保转换自然不生硬。',
      expectedOutcome: '转换后的文本将体现$targetStyle风格的特点，核心信息保持不变，表达自然流畅。',
    );
  }

  /// 分析智能替换意图
  IntentConfirmation _analyzeSmartReplaceIntent(String text, Map<String, dynamic>? params) {
    final findText = params?['findText'] as String? ?? '';
    final replaceWith = params?['replaceWith'] as String? ?? '';

    final occurrences = (text.toLowerCase().split(findText.toLowerCase()).length - 1).clamp(0, 999);

    return IntentConfirmation(
      id: IntentConfirmation.generateId(),
      actionType: AIActionType.smartReplace,
      description: '智能替换文本中的"$findText"为"$replaceWith"',
      originalText: text,
      parameters: {
        'find_text': findText,
        'replace_with': replaceWith,
        'occurrences': occurrences,
        'preserve_context': true,
      },
      explanation: '我将在保持文本连贯性的前提下进行替换（找到$occurrences处），自动调整时态和语态，确保替换后的表达自然。',
      expectedOutcome: '替换后的文本将保持连贯性，时态和语态自动调整，表达自然不生硬。',
    );
  }

  /// 分析文本特征
  TextCharacteristics _analyzeTextCharacteristics(String text) {
    if (text.isEmpty) {
      return const TextCharacteristics();
    }

    // 基本统计
    final sentences = text.split(RegExp(r'[。！？]'));
    final avgSentenceLength = text.length / sentences.length;

    // 检测各种特征
    final hasGrammarIssues = _detectGrammarIssues(text);
    final isRepetitive = _detectRepetition(text);
    final isInformal = _detectInformalStyle(text);
    final isAbstract = _detectAbstractContent(text);
    final isShort = text.length < 50;

    return TextCharacteristics(
      hasGrammarIssues: hasGrammarIssues,
      isRepetitive: isRepetitive,
      isInformal: isInformal,
      isAbstract: isAbstract,
      isShort: isShort,
      avgSentenceLength: avgSentenceLength,
    );
  }

  /// 检测语法问题
  bool _detectGrammarIssues(String text) {
    // 简单的语法问题检测
    final grammarIssuePatterns = [
      RegExp(r'的{2,}'), // 重复的"的"
      RegExp(r'[，,]{2,}'), // 重复的逗号
      RegExp(r'\s{3,}'), // 多余的空格
    ];

    return grammarIssuePatterns.any((pattern) => pattern.hasMatch(text));
  }

  /// 检测重复内容
  bool _detectRepetition(String text) {
    final words = text.split(RegExp(r'[\s，。、；：？！））(（]+'));
    final wordCount = <String, int>{};

    for (final word in words) {
      if (word.length >= 2) {
        wordCount[word] = (wordCount[word] ?? 0) + 1;
      }
    }

    // 如果有词语出现超过3次，认为有重复
    return wordCount.values.any((count) => count > 3);
  }

  /// 检测非正式风格
  bool _detectInformalStyle(String text) {
    final informalPatterns = [
      RegExp(r'[嘛吧呢呀哦嘛]'), // 语气词
      RegExp(r'[嘿嘿哈哈呵呵]'), // 拟声词
      RegExp(r'[~！]{2,}'), // 重复的感叹号或波浪号
    ];

    return informalPatterns.any((pattern) => pattern.hasMatch(text));
  }

  /// 检测抽象内容
  bool _detectAbstractContent(String text) {
    // 检测是否缺乏具体的例子和细节
    final abstractIndicators = ['应该', '需要', '可能', '一般来说', '通常'];
    final concreteIndicators = ['例如', '比如', '具体', '实际上', '事实'];

    final abstractCount = abstractIndicators
        .where((indicator) => text.contains(indicator))
        .length;
    final concreteCount = concreteIndicators
        .where((indicator) => text.contains(indicator))
        .length;

    return abstractCount > concreteCount && text.length < 200;
  }

  /// 生成润色描述
  String _generatePolishDescription(TextCharacteristics analysis) {
    final parts = <String>['对选中文本进行润色'];

    if (analysis.hasGrammarIssues) {
      parts.add('修正语法错误');
    }
    if (analysis.isRepetitive) {
      parts.add('减少重复表达');
    }
    if (analysis.isInformal) {
      parts.add('提升表达专业性');
    }

    parts.add('使语言更加流畅自然');
    return parts.join('，') + '。';
  }

  /// 确定风格级别
  String _determineStyleLevel(TextCharacteristics analysis) {
    if (analysis.isInformal) {
      return 'formal';
    } else if (analysis.hasGrammarIssues) {
      return 'corrective';
    } else {
      return 'moderate';
    }
  }

  /// 记录用户反馈
  void recordFeedback(IntentConfirmationFeedback feedback) {
    _feedbackHistory.add(feedback);

    // 在调试模式下输出反馈信息
    if (kDebugMode) {
      Logger.debug('意图确认反馈已记录: ${feedback.intentId}');
      Logger.debug('确认状态: ${feedback.confirmed}');
      if (feedback.adjustedDescription != null) {
        Logger.debug('调整后描述: ${feedback.adjustedDescription}');
      }
    }
  }

  /// 获取反馈统计
  Map<String, dynamic> getFeedbackStatistics() {
    if (_feedbackHistory.isEmpty) {
      return {
        'total': 0,
        'confirmed': 0,
        'adjusted': 0,
        'rejected': 0,
        'confirmation_rate': 0.0,
      };
    }

    final confirmed = _feedbackHistory.where((f) => f.confirmed).length;
    final adjusted = _feedbackHistory.where((f) =>
        f.adjustedDescription != null ||
        (f.adjustedParameters?.isNotEmpty ?? false)
    ).length;

    return {
      'total': _feedbackHistory.length,
      'confirmed': confirmed,
      'adjusted': adjusted,
      'rejected': _feedbackHistory.length - confirmed,
      'confirmation_rate': confirmed / _feedbackHistory.length,
    };
  }

  /// 清除反馈历史
  void clearFeedbackHistory() {
    _feedbackHistory.clear();
  }
}

/// 意图分析器配置
class IntentAnalyzerConfig {
  final bool enableDetailedAnalysis;
  final bool enableFeedbackLearning;
  final int maxFeedbackHistorySize;

  const IntentAnalyzerConfig({
    this.enableDetailedAnalysis = true,
    this.enableFeedbackLearning = true,
    this.maxFeedbackHistorySize = 100,
  });
}

/// 文本特征分析结果
class TextCharacteristics {
  final bool hasGrammarIssues;
  final bool isRepetitive;
  final bool isInformal;
  final bool isAbstract;
  final bool isShort;
  final double avgSentenceLength;

  const TextCharacteristics({
    this.hasGrammarIssues = false,
    this.isRepetitive = false,
    this.isInformal = false,
    this.isAbstract = false,
    this.isShort = false,
    this.avgSentenceLength = 0.0,
  });

  @override
  String toString() {
    return 'TextCharacteristics('
        'hasGrammarIssues: $hasGrammarIssues, '
        'isRepetitive: $isRepetitive, '
        'isInformal: $isInformal, '
        'isAbstract: $isAbstract, '
        'isShort: $isShort, '
        'avgSentenceLength: $avgSentenceLength)';
  }
}
