import 'package:json_annotation/json_annotation.dart';

part 'user_preference.g.dart';

/// 语言风格偏好类型
enum LanguageStyle {
  /// 正式语言
  formal,

  /// 口语化语言
  casual,

  /// 混合风格
  mixed,

  /// 未检测到明确偏好
  unknown,
}

/// 语言详细程度偏好
enum DetailLevel {
  /// 简洁
  concise,

  /// 适中
  moderate,

  /// 详细
  detailed,

  /// 极其详细
  verbose,

  /// 未检测
  unknown,
}

/// 修改类型分类
enum ModificationType {
  /// 语法修正
  grammar,

  /// 拼写修正
  spelling,

  /// 风格改进
  style,

  /// 内容扩展
  expansion,

  /// 内容精简
  simplification,

  /// 结构调整
  structure,

  /// 词汇替换
  vocabulary,

  /// 其他修改
  other,
}

/// 用户对修改的反馈类型
enum FeedbackType {
  /// 接受修改
  accepted,

  /// 拒绝修改
  rejected,

  /// 部分接受
  partiallyAccepted,

  /// 撤销修改
  reverted,
}

/// 段落结构偏好
enum ParagraphStructure {
  /// 短段落为主
  shortParagraphs,

  /// 中等长度段落
  mediumParagraphs,

  /// 长段落为主
  longParagraphs,

  /// 混合使用
  mixed,

  /// 未检测
  unknown,
}

/// 句式复杂度偏好
enum SentenceComplexity {
  /// 简单句为主
  simple,

  /// 中等复杂度
  moderate,

  /// 复杂句为主
  complex,

  /// 多样化混合
  varied,

  /// 未检测
  unknown,
}

/// 用户偏好数据模型
@JsonSerializable()
class UserPreference {
  /// 唯一标识符
  final String id;

  /// 创建时间
  final DateTime createdAt;

  /// 最后更新时间
  final DateTime updatedAt;

  /// 语言风格偏好
  final LanguageStyle languageStyle;

  /// 语言详细程度偏好
  final DetailLevel detailLevel;

  /// 段落结构偏好
  final ParagraphStructure paragraphStructure;

  /// 句式复杂度偏好
  final SentenceComplexity sentenceComplexity;

  /// 各类修改的接受率统计
  final Map<ModificationType, double> modificationAcceptanceRates;

  /// 常用词汇偏好（词频统计）
  final Map<String, int> preferredVocabulary;

  /// 用户关注的主题（关键词和权重）
  final Map<String, double> topicInterests;

  /// 用户接受度评分（0.0 - 1.0）
  final double overallAcceptanceRate;

  /// 学习数据点数量
  final int learningDataPoints;

  /// 偏好置信度（0.0 - 1.0）
  final double confidenceScore;

  /// 启用状态
  final bool enabled;

  const UserPreference({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.languageStyle = LanguageStyle.unknown,
    this.detailLevel = DetailLevel.unknown,
    this.paragraphStructure = ParagraphStructure.unknown,
    this.sentenceComplexity = SentenceComplexity.unknown,
    this.modificationAcceptanceRates = const {},
    this.preferredVocabulary = const {},
    this.topicInterests = const {},
    this.overallAcceptanceRate = 0.5,
    this.learningDataPoints = 0,
    this.confidenceScore = 0.0,
    this.enabled = true,
  });

  /// 创建空的偏好配置
  factory UserPreference.create() {
    final now = DateTime.now();
    return UserPreference(
      id: _generateId(),
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 从JSON创建
  factory UserPreference.fromJson(Map<String, dynamic> json) =>
      _$UserPreferenceFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$UserPreferenceToJson(this);

  /// 复制并更新部分字段
  UserPreference copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    LanguageStyle? languageStyle,
    DetailLevel? detailLevel,
    ParagraphStructure? paragraphStructure,
    SentenceComplexity? sentenceComplexity,
    Map<ModificationType, double>? modificationAcceptanceRates,
    Map<String, int>? preferredVocabulary,
    Map<String, double>? topicInterests,
    double? overallAcceptanceRate,
    int? learningDataPoints,
    double? confidenceScore,
    bool? enabled,
  }) {
    return UserPreference(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      languageStyle: languageStyle ?? this.languageStyle,
      detailLevel: detailLevel ?? this.detailLevel,
      paragraphStructure: paragraphStructure ?? this.paragraphStructure,
      sentenceComplexity: sentenceComplexity ?? this.sentenceComplexity,
      modificationAcceptanceRates:
          modificationAcceptanceRates ?? this.modificationAcceptanceRates,
      preferredVocabulary: preferredVocabulary ?? this.preferredVocabulary,
      topicInterests: topicInterests ?? this.topicInterests,
      overallAcceptanceRate:
          overallAcceptanceRate ?? this.overallAcceptanceRate,
      learningDataPoints: learningDataPoints ?? this.learningDataPoints,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      enabled: enabled ?? this.enabled,
    );
  }

  /// 生成唯一ID
  static String _generateId() {
    return 'pref_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 获取偏好摘要
  Map<String, dynamic> getSummary() {
    return {
      'languageStyle': languageStyle.toString(),
      'detailLevel': detailLevel.toString(),
      'paragraphStructure': paragraphStructure.toString(),
      'sentenceComplexity': sentenceComplexity.toString(),
      'overallAcceptanceRate': overallAcceptanceRate,
      'learningDataPoints': learningDataPoints,
      'confidenceScore': confidenceScore,
      'topModificationTypes': getTopModificationTypes(3),
      'topTopics': getTopTopics(5),
    };
  }

  /// 获取接受率最高的修改类型
  List<Map<String, dynamic>> getTopModificationTypes(int limit) {
    final entries = modificationAcceptanceRates.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries
        .take(limit)
        .map((e) => {
              'type': e.key.toString(),
              'acceptanceRate': e.value,
            })
        .toList();
  }

  /// 获取最关注的主题
  List<Map<String, dynamic>> getTopTopics(int limit) {
    final entries = topicInterests.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries
        .take(limit)
        .map((e) => {
              'topic': e.key,
              'interest': e.value,
            })
        .toList();
  }

  /// 是否有足够的置信度
  bool hasSufficientConfidence([double threshold = 0.6]) {
    return confidenceScore >= threshold && learningDataPoints >= 10;
  }

  /// 获取学习进度百分比
  double get learningProgress {
    // 假设100个数据点为完整学习
    return (learningDataPoints / 100).clamp(0.0, 1.0);
  }
}

/// 用户反馈数据模型
@JsonSerializable()
class UserFeedback {
  /// 反馈ID
  final String id;

  /// 时间戳
  final DateTime timestamp;

  /// 反馈类型
  final FeedbackType feedbackType;

  /// 修改类型
  final ModificationType modificationType;

  /// 原始文本
  final String originalText;

  /// 修改后的文本
  final String modifiedText;

  /// 用户最终接受的文本
  final String? finalText;

  /// 上下文信息
  final String? context;

  /// 相关主题标签
  final List<String> topics;

  /// 处理时间（毫秒）
  final int? processingTime;

  /// AI建议的置信度
  final double? aiConfidence;

  const UserFeedback({
    required this.id,
    required this.timestamp,
    required this.feedbackType,
    required this.modificationType,
    required this.originalText,
    required this.modifiedText,
    this.finalText,
    this.context,
    this.topics = const [],
    this.processingTime,
    this.aiConfidence,
  });

  /// 创建新的反馈记录
  factory UserFeedback.create({
    required FeedbackType feedbackType,
    required ModificationType modificationType,
    required String originalText,
    required String modifiedText,
    String? finalText,
    String? context,
    List<String>? topics,
    int? processingTime,
    double? aiConfidence,
  }) {
    return UserFeedback(
      id: _generateId(),
      timestamp: DateTime.now(),
      feedbackType: feedbackType,
      modificationType: modificationType,
      originalText: originalText,
      modifiedText: modifiedText,
      finalText: finalText,
      context: context,
      topics: topics ?? [],
      processingTime: processingTime,
      aiConfidence: aiConfidence,
    );
  }

  /// 从JSON创建
  factory UserFeedback.fromJson(Map<String, dynamic> json) =>
      _$UserFeedbackFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$UserFeedbackToJson(this);

  /// 生成唯一ID
  static String _generateId() {
    return 'feedback_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// 是否是正反馈
  bool get isPositive =>
      feedbackType == FeedbackType.accepted ||
      feedbackType == FeedbackType.partiallyAccepted;

  /// 是否是负反馈
  bool get isNegative =>
      feedbackType == FeedbackType.rejected ||
      feedbackType == FeedbackType.reverted;
}

/// 写作分析数据
@JsonSerializable()
class WritingAnalysis {
  /// 分析ID
  final String id;

  /// 分析时间
  final DateTime timestamp;

  /// 文本内容
  final String text;

  /// 检测到的语言风格
  final LanguageStyle detectedLanguageStyle;

  /// 检测到的详细程度
  final DetailLevel detectedDetailLevel;

  /// 检测到的段落结构
  final ParagraphStructure detectedParagraphStructure;

  /// 检测到的句式复杂度
  final SentenceComplexity detectedSentenceComplexity;

  /// 提取的关键词
  final List<String> keywords;

  /// 文本特征
  final Map<String, dynamic> features;

  /// 置信度
  final double confidence;

  const WritingAnalysis({
    required this.id,
    required this.timestamp,
    required this.text,
    required this.detectedLanguageStyle,
    required this.detectedDetailLevel,
    required this.detectedParagraphStructure,
    required this.detectedSentenceComplexity,
    this.keywords = const [],
    this.features = const {},
    this.confidence = 0.0,
  });

  /// 创建写作分析
  factory WritingAnalysis.create({
    required String text,
    required LanguageStyle languageStyle,
    required DetailLevel detailLevel,
    required ParagraphStructure paragraphStructure,
    required SentenceComplexity sentenceComplexity,
    List<String>? keywords,
    Map<String, dynamic>? features,
    double confidence = 0.0,
  }) {
    return WritingAnalysis(
      id: _generateId(),
      timestamp: DateTime.now(),
      text: text,
      detectedLanguageStyle: languageStyle,
      detectedDetailLevel: detailLevel,
      detectedParagraphStructure: paragraphStructure,
      detectedSentenceComplexity: sentenceComplexity,
      keywords: keywords ?? [],
      features: features ?? {},
      confidence: confidence,
    );
  }

  /// 从JSON创建
  factory WritingAnalysis.fromJson(Map<String, dynamic> json) =>
      _$WritingAnalysisFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$WritingAnalysisToJson(this);

  /// 生成唯一ID
  static String _generateId() {
    return 'analysis_${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// 偏好学习配置
@JsonSerializable()
class PreferenceLearningConfig {
  /// 是否启用学习
  final bool enabled;

  /// 最小学习样本数
  final int minLearningSamples;

  /// 最大反馈历史记录数
  final int maxFeedbackHistory;

  /// 学习速率（0.0 - 1.0）
  final double learningRate;

  /// 置信度阈值
  final double confidenceThreshold;

  /// 是否启用自动应用
  final bool autoApply;

  /// 数据保留天数
  final int dataRetentionDays;

  /// 是否启用匿名分析
  final bool anonymizeData;

  const PreferenceLearningConfig({
    this.enabled = true,
    this.minLearningSamples = 10,
    this.maxFeedbackHistory = 1000,
    this.learningRate = 0.1,
    this.confidenceThreshold = 0.6,
    this.autoApply = false,
    this.dataRetentionDays = 90,
    this.anonymizeData = true,
  });

  /// 创建默认配置
  factory PreferenceLearningConfig.defaultConfig() {
    return const PreferenceLearningConfig();
  }

  /// 从JSON创建
  factory PreferenceLearningConfig.fromJson(Map<String, dynamic> json) =>
      _$PreferenceLearningConfigFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$PreferenceLearningConfigToJson(this);

  /// 复制并更新
  PreferenceLearningConfig copyWith({
    bool? enabled,
    int? minLearningSamples,
    int? maxFeedbackHistory,
    double? learningRate,
    double? confidenceThreshold,
    bool? autoApply,
    int? dataRetentionDays,
    bool? anonymizeData,
  }) {
    return PreferenceLearningConfig(
      enabled: enabled ?? this.enabled,
      minLearningSamples: minLearningSamples ?? this.minLearningSamples,
      maxFeedbackHistory: maxFeedbackHistory ?? this.maxFeedbackHistory,
      learningRate: learningRate ?? this.learningRate,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      autoApply: autoApply ?? this.autoApply,
      dataRetentionDays: dataRetentionDays ?? this.dataRetentionDays,
      anonymizeData: anonymizeData ?? this.anonymizeData,
    );
  }
}
