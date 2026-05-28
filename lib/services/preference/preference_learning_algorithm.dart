import 'dart:math';
import '../../models/user_preference.dart';

/// 偏好学习算法
/// 实现基于用户反馈的机器学习算法，自动学习和适应用户写作偏好
class PreferenceLearningAlgorithm {
  static PreferenceLearningAlgorithm? _instance;

  final Random _random = Random();
  final Map<String, double> _styleWeights = {};

  PreferenceLearningAlgorithm._();

  /// 获取单例实例
  static PreferenceLearningAlgorithm get instance {
    _instance ??= PreferenceLearningAlgorithm._();
    return _instance!;
  }

  /// 从反馈中学习
  Future<UserPreference> learnFromFeedback(
    UserFeedback feedback,
    UserPreference currentPreference,
    PreferenceLearningConfig config,
  ) async {
    // 计算新的接受率统计
    final updatedAcceptanceRates = _updateAcceptanceRates(
      feedback,
      currentPreference.modificationAcceptanceRates,
      currentPreference.learningDataPoints,
      config.learningRate,
    );

    // 更新主题兴趣
    final updatedTopicInterests = _updateTopicInterests(
      feedback,
      currentPreference.topicInterests,
      config.learningRate,
    );

    // 更新词汇偏好
    final updatedVocabulary = _updateVocabulary(
      feedback,
      currentPreference.preferredVocabulary,
    );

    // 计算新的置信度
    final newConfidenceScore = _calculateConfidence(
      currentPreference.learningDataPoints + 1,
      config.minLearningSamples,
    );

    // 计算新的总体接受率
    final newOverallRate = _calculateOverallAcceptanceRate(
      currentPreference.overallAcceptanceRate,
      feedback.isPositive ? 1.0 : 0.0,
      currentPreference.learningDataPoints,
      config.learningRate,
    );

    return currentPreference.copyWith(
      modificationAcceptanceRates: updatedAcceptanceRates,
      topicInterests: updatedTopicInterests,
      preferredVocabulary: updatedVocabulary,
      overallAcceptanceRate: newOverallRate,
      learningDataPoints: currentPreference.learningDataPoints + 1,
      confidenceScore: newConfidenceScore,
    );
  }

  /// 从写作样本中学习
  Future<UserPreference> learnFromWriting(
    WritingAnalysis analysis,
    UserPreference currentPreference,
    PreferenceLearningConfig config,
  ) async {
    // 如果分析置信度太低，不更新偏好
    if (analysis.confidence < 0.3) {
      return currentPreference;
    }

    // 更新语言风格偏好
    final updatedLanguageStyle = _updateLanguageStyle(
      currentPreference.languageStyle,
      analysis.detectedLanguageStyle,
      analysis.confidence,
      currentPreference.learningDataPoints,
    );

    // 更新详细程度偏好
    final updatedDetailLevel = _updateDetailLevel(
      currentPreference.detailLevel,
      analysis.detectedDetailLevel,
      analysis.confidence,
      currentPreference.learningDataPoints,
    );

    // 更新段落结构偏好
    final updatedParagraphStructure = _updateParagraphStructure(
      currentPreference.paragraphStructure,
      analysis.detectedParagraphStructure,
      analysis.confidence,
      currentPreference.learningDataPoints,
    );

    // 更新句式复杂度偏好
    final updatedSentenceComplexity = _updateSentenceComplexity(
      currentPreference.sentenceComplexity,
      analysis.detectedSentenceComplexity,
      analysis.confidence,
      currentPreference.learningDataPoints,
    );

    // 更新主题兴趣
    final updatedTopicInterests = _updateTopicInterestsFromAnalysis(
      analysis,
      currentPreference.topicInterests,
      config.learningRate,
    );

    return currentPreference.copyWith(
      languageStyle: updatedLanguageStyle,
      detailLevel: updatedDetailLevel,
      paragraphStructure: updatedParagraphStructure,
      sentenceComplexity: updatedSentenceComplexity,
      topicInterests: updatedTopicInterests,
      learningDataPoints: currentPreference.learningDataPoints + 1,
    );
  }

  /// 生成个性化建议
  Map<String, dynamic> generateSuggestions(
    String text,
    UserPreference preference,
  ) {
    if (!preference.hasSufficientConfidence()) {
      return {
        'confidence': preference.confidenceScore,
        'message': '需要更多学习数据才能提供个性化建议',
      };
    }

    return {
      'confidence': preference.confidenceScore,
      'languageStyle': _suggestLanguageStyle(preference),
      'detailLevel': _suggestDetailLevel(preference),
      'paragraphStructure': _suggestParagraphStructure(preference),
      'sentenceComplexity': _suggestSentenceComplexity(preference),
      'preferredVocabulary': _suggestVocabulary(preference),
      'modificationSuggestions': _suggestModifications(preference),
      'topics': _suggestTopics(preference),
    };
  }

  /// 调整AI建议
  String adjustSuggestion(
    String originalSuggestion,
    String context,
    UserPreference preference,
  ) {
    String adjusted = originalSuggestion;

    // 根据详细程度偏好调整长度
    adjusted = _adjustForDetailLevel(adjusted, preference.detailLevel);

    // 根据语言风格偏好调整语气
    adjusted = _adjustForLanguageStyle(adjusted, preference.languageStyle);

    // 根据句式复杂度偏好调整结构
    adjusted = _adjustForSentenceComplexity(adjusted, preference.sentenceComplexity);

    return adjusted;
  }

  /// 更新接受率统计
  Map<ModificationType, double> _updateAcceptanceRates(
    UserFeedback feedback,
    Map<ModificationType, double> currentRates,
    int dataPoints,
    double learningRate,
  ) {
    final updatedRates = Map<ModificationType, double>.from(currentRates);
    final type = feedback.modificationType;
    final currentValue = updatedRates[type] ?? 0.5;
    final feedbackValue = feedback.isPositive ? 1.0 : 0.0;

    // 使用指数移动平均更新接受率
    final newValue = currentValue + learningRate * (feedbackValue - currentValue);
    updatedRates[type] = newValue;

    return updatedRates;
  }

  /// 更新主题兴趣
  Map<String, double> _updateTopicInterests(
    UserFeedback feedback,
    Map<String, double> currentInterests,
    double learningRate,
  ) {
    final updatedInterests = Map<String, double>.from(currentInterests);

    for (final topic in feedback.topics) {
      final currentValue = updatedInterests[topic] ?? 0.0;
      final increase = feedback.isPositive ? 0.1 : -0.05;
      final newValue = (currentValue + increase).clamp(0.0, 1.0);
      updatedInterests[topic] = newValue;
    }

    // 从上下文中提取潜在主题
    if (feedback.context != null) {
      final contextTopics = _extractTopicsFromText(feedback.context!);
      for (final topic in contextTopics) {
        final currentValue = updatedInterests[topic] ?? 0.0;
        final newValue = (currentValue + 0.02).clamp(0.0, 1.0);
        updatedInterests[topic] = newValue;
      }
    }

    return updatedInterests;
  }

  /// 从写作分析中更新主题兴趣
  Map<String, double> _updateTopicInterestsFromAnalysis(
    WritingAnalysis analysis,
    Map<String, double> currentInterests,
    double learningRate,
  ) {
    final updatedInterests = Map<String, double>.from(currentInterests);

    for (final keyword in analysis.keywords) {
      final currentValue = updatedInterests[keyword] ?? 0.0;
      final increase = analysis.confidence * 0.05;
      final newValue = (currentValue + increase).clamp(0.0, 1.0);
      updatedInterests[keyword] = newValue;
    }

    return updatedInterests;
  }

  /// 更新词汇偏好
  Map<String, int> _updateVocabulary(
    UserFeedback feedback,
    Map<String, int> currentVocabulary,
  ) {
    final updatedVocabulary = Map<String, int>.from(currentVocabulary);

    // 从最终接受的文本中提取词汇
    final text = feedback.finalText ?? feedback.modifiedText;
    final words = _extractWords(text);

    for (final word in words) {
      if (_isSignificantWord(word)) {
        updatedVocabulary[word] = (updatedVocabulary[word] ?? 0) + 1;
      }
    }

    return updatedVocabulary;
  }

  /// 计算置信度
  double _calculateConfidence(int dataPoints, int minSamples) {
    if (dataPoints < minSamples) {
      return dataPoints / minSamples * 0.5;
    }
    // 使用sigmoid函数计算置信度
    final x = (dataPoints - minSamples) / 50.0;
    return 0.5 + 0.5 * (1 / (1 + (-x).exp()));
  }

  /// 计算总体接受率
  double _calculateOverallAcceptanceRate(
    double currentRate,
    double feedbackValue,
    int dataPoints,
    double learningRate,
  ) {
    return currentRate + learningRate * (feedbackValue - currentRate);
  }

  /// 更新语言风格偏好
  LanguageStyle _updateLanguageStyle(
    LanguageStyle current,
    LanguageStyle detected,
    double confidence,
    int dataPoints,
  ) {
    if (detected == LanguageStyle.unknown) return current;

    if (current == LanguageStyle.unknown) return detected;

    if (dataPoints < 10) {
      // 早期阶段，直接采用检测到的风格
      return detected;
    }

    // 后期阶段，逐渐融合
    return current == detected ? current : LanguageStyle.mixed;
  }

  /// 更新详细程度偏好
  DetailLevel _updateDetailLevel(
    DetailLevel current,
    DetailLevel detected,
    double confidence,
    int dataPoints,
  ) {
    if (detected == DetailLevel.unknown) return current;

    if (current == DetailLevel.unknown) return detected;

    if (dataPoints < 10) {
      return detected;
    }

    // 基于置信度决定是否更新
    if (confidence > 0.7) {
      return detected;
    }

    return current;
  }

  /// 更新段落结构偏好
  ParagraphStructure _updateParagraphStructure(
    ParagraphStructure current,
    ParagraphStructure detected,
    double confidence,
    int dataPoints,
  ) {
    if (detected == ParagraphStructure.unknown) return current;

    if (current == ParagraphStructure.unknown) return detected;

    if (dataPoints < 10) {
      return detected;
    }

    return current == detected ? current : ParagraphStructure.mixed;
  }

  /// 更新句式复杂度偏好
  SentenceComplexity _updateSentenceComplexity(
    SentenceComplexity current,
    SentenceComplexity detected,
    double confidence,
    int dataPoints,
  ) {
    if (detected == SentenceComplexity.unknown) return current;

    if (current == SentenceComplexity.unknown) return detected;

    if (dataPoints < 10) {
      return detected;
    }

    return current == detected ? current : SentenceComplexity.varied;
  }

  /// 建议语言风格
  String _suggestLanguageStyle(UserPreference preference) {
    switch (preference.languageStyle) {
      case LanguageStyle.formal:
        return '建议使用正式、专业的语言风格';
      case LanguageStyle.casual:
        return '建议使用口语化、自然的语言风格';
      case LanguageStyle.mixed:
        return '建议根据语境灵活调整语言风格';
      case LanguageStyle.unknown:
        return '尚未检测到明确的语言风格偏好';
    }
  }

  /// 建议详细程度
  String _suggestDetailLevel(UserPreference preference) {
    switch (preference.detailLevel) {
      case DetailLevel.concise:
        return '建议保持简洁明了的表达方式';
      case DetailLevel.moderate:
        return '建议保持适中的详细程度';
      case DetailLevel.detailed:
        return '建议提供详细的信息和解释';
      case DetailLevel.verbose:
        return '建议提供全面详细的阐述';
      case DetailLevel.unknown:
        return '尚未检测到明确的详细程度偏好';
    }
  }

  /// 建议段落结构
  String _suggestParagraphStructure(UserPreference preference) {
    switch (preference.paragraphStructure) {
      case ParagraphStructure.shortParagraphs:
        return '建议使用短段落，增强可读性';
      case ParagraphStructure.mediumParagraphs:
        return '建议使用中等长度的段落';
      case ParagraphStructure.longParagraphs:
        return '建议使用长段落，进行深入阐述';
      case ParagraphStructure.mixed:
        return '建议根据内容需要灵活调整段落长度';
      case ParagraphStructure.unknown:
        return '尚未检测到明确的段落结构偏好';
    }
  }

  /// 建议句式复杂度
  String _suggestSentenceComplexity(UserPreference preference) {
    switch (preference.sentenceComplexity) {
      case SentenceComplexity.simple:
        return '建议使用简单直接的句式';
      case SentenceComplexity.moderate:
        return '建议使用中等复杂度的句式';
      case SentenceComplexity.complex:
        return '建议使用复杂句式，表达丰富含义';
      case SentenceComplexity.varied:
        return '建议使用多样化的句式结构';
      case SentenceComplexity.unknown:
        return '尚未检测到明确的句式复杂度偏好';
    }
  }

  /// 建议词汇使用
  List<String> _suggestVocabulary(UserPreference preference) {
    final vocabulary = preference.preferredVocabulary;
    if (vocabulary.isEmpty) return [];

    // 返回最常用的10个词汇
    final entries = vocabulary.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.take(10).map((e) => e.key).toList();
  }

  /// 建议修改类型
  List<String> _suggestModifications(UserPreference preference) {
    final rates = preference.modificationAcceptanceRates;
    if (rates.isEmpty) return [];

    // 找出接受率最高的修改类型
    final entries = rates.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final suggestions = <String>[];

    for (final entry in entries) {
      if (entry.value > 0.7) {
        suggestions.add('用户倾向于接受 ${_describeModificationType(entry.key)} 类型的修改');
      } else if (entry.value < 0.3) {
        suggestions.add('用户倾向于拒绝 ${_describeModificationType(entry.key)} 类型的修改');
      }
    }

    return suggestions;
  }

  /// 建议主题
  List<String> _suggestTopics(UserPreference preference) {
    final topics = preference.topicInterests;
    if (topics.isEmpty) return [];

    final entries = topics.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.take(10).where((e) => e.value > 0.3).map((e) => e.key).toList();
  }

  /// 根据详细程度调整建议
  String _adjustForDetailLevel(String text, DetailLevel detailLevel) {
    switch (detailLevel) {
      case DetailLevel.concise:
        return _makeMoreConcise(text);
      case DetailLevel.detailed:
      case DetailLevel.verbose:
        return _makeMoreDetailed(text);
      default:
        return text;
    }
  }

  /// 根据语言风格调整建议
  String _adjustForLanguageStyle(String text, LanguageStyle languageStyle) {
    switch (languageStyle) {
      case LanguageStyle.formal:
        return _makeMoreFormal(text);
      case LanguageStyle.casual:
        return _makeMoreCasual(text);
      default:
        return text;
    }
  }

  /// 根据句式复杂度调整建议
  String _adjustForSentenceComplexity(String text, SentenceComplexity complexity) {
    switch (complexity) {
      case SentenceComplexity.simple:
        return _simplifySentences(text);
      case SentenceComplexity.complex:
        return _complexifySentences(text);
      default:
        return text;
    }
  }

  /// 使文本更简洁
  String _makeMoreConcise(String text) {
    // 移除冗余词汇
    final redundantPatterns = [
      RegExp(r'\b(?:事实上|实际上|基本上|本质上)\b'),
      RegExp(r'\b(?:我认为|在我看来|据我看来)\b'),
    ];

    String result = text;
    for (final pattern in redundantPatterns) {
      result = result.replaceAll(pattern, '');
    }

    return result.trim();
  }

  /// 使文本更详细
  String _makeMoreDetailed(String text) {
    // 这里可以添加逻辑来扩展文本
    return text; // 简化实现
  }

  /// 使文本更正式
  String _makeMoreFormal(String text) {
    // 替换口语化表达
    final replacements = {
      '很好': '优秀',
      '不错': '良好',
      '很多': '诸多',
      '特别': '尤为',
      '非常': '十分',
    };

    String result = text;
    replacements.forEach((informal, formal) {
      result = result.replaceAll(informal, formal);
    });

    return result;
  }

  /// 使文本更口语化
  String _makeMoreCasual(String text) {
    // 替换正式表达为口语
    final replacements = {
      '优秀': '很棒',
      '良好': '不错',
      '诸多': '很多',
      '尤为': '特别',
      '十分': '非常',
    };

    String result = text;
    replacements.forEach((formal, informal) {
      result = result.replaceAll(formal, informal);
    });

    return result;
  }

  /// 简化句子
  String _simplifySentences(String text) {
    // 简化复杂句式的逻辑
    return text; // 简化实现
  }

  /// 复杂化句子
  String _complexifySentences(String text) {
    // 增加句子复杂度的逻辑
    return text; // 简化实现
  }

  /// 提取文本中的主题
  List<String> _extractTopicsFromText(String text) {
    // 简单的关键词提取
    final words = _extractWords(text);
    final significantWords = words.where(_isSignificantWord).toSet();

    return significantWords.take(10).toList();
  }

  /// 提取单词
  List<String> _extractWords(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').split(RegExp(r'\s+'));
  }

  /// 判断是否为重要词汇
  bool _isSignificantWord(String word) {
    if (word.length < 2) return false;

    // 过滤常见停用词
    final stopWords = {
      '的', '是', '在', '和', '或', '但', '与', '及', '等', '很', '也',
      'the', 'is', 'and', 'or', 'but', 'with', 'very', 'also',
    };

    return !stopWords.contains(word);
  }

  /// 描述修改类型
  String _describeModificationType(ModificationType type) {
    switch (type) {
      case ModificationType.grammar:
        return '语法修正';
      case ModificationType.spelling:
        return '拼写修正';
      case ModificationType.style:
        return '风格改进';
      case ModificationType.expansion:
        return '内容扩展';
      case ModificationType.simplification:
        return '内容精简';
      case ModificationType.structure:
        return '结构调整';
      case ModificationType.vocabulary:
        return '词汇替换';
      case ModificationType.other:
        return '其他修改';
    }
  }

  /// 扩展方法：计算数值的指数
  double numExp(double x) {
    return _exp(x);
  }

  double _exp(double x) {
    // 简单的泰勒级数近似
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 20; i++) {
      term *= x / i;
      result += term;
      if (term.abs() < 1e-10) break;
    }
    return result;
  }
}

extension on double {
  double exp() {
    final algorithm = PreferenceLearningAlgorithm.instance;
    return algorithm.numExp(this);
  }
}