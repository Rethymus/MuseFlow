// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preference.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserPreference _$UserPreferenceFromJson(Map<String, dynamic> json) =>
    UserPreference(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      languageStyle:
          $enumDecodeNullable(_$LanguageStyleEnumMap, json['languageStyle']) ??
              LanguageStyle.unknown,
      detailLevel:
          $enumDecodeNullable(_$DetailLevelEnumMap, json['detailLevel']) ??
              DetailLevel.unknown,
      paragraphStructure: $enumDecodeNullable(
              _$ParagraphStructureEnumMap, json['paragraphStructure']) ??
          ParagraphStructure.unknown,
      sentenceComplexity: $enumDecodeNullable(
              _$SentenceComplexityEnumMap, json['sentenceComplexity']) ??
          SentenceComplexity.unknown,
      modificationAcceptanceRates:
          (json['modificationAcceptanceRates'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry($enumDecode(_$ModificationTypeEnumMap, k),
                    (e as num).toDouble()),
              ) ??
              const {},
      preferredVocabulary:
          (json['preferredVocabulary'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, (e as num).toInt()),
              ) ??
              const {},
      topicInterests: (json['topicInterests'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          const {},
      overallAcceptanceRate:
          (json['overallAcceptanceRate'] as num?)?.toDouble() ?? 0.5,
      learningDataPoints: (json['learningDataPoints'] as num?)?.toInt() ?? 0,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      enabled: json['enabled'] as bool? ?? true,
    );

Map<String, dynamic> _$UserPreferenceToJson(UserPreference instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'languageStyle': _$LanguageStyleEnumMap[instance.languageStyle]!,
      'detailLevel': _$DetailLevelEnumMap[instance.detailLevel]!,
      'paragraphStructure':
          _$ParagraphStructureEnumMap[instance.paragraphStructure]!,
      'sentenceComplexity':
          _$SentenceComplexityEnumMap[instance.sentenceComplexity]!,
      'modificationAcceptanceRates': instance.modificationAcceptanceRates
          .map((k, e) => MapEntry(_$ModificationTypeEnumMap[k]!, e)),
      'preferredVocabulary': instance.preferredVocabulary,
      'topicInterests': instance.topicInterests,
      'overallAcceptanceRate': instance.overallAcceptanceRate,
      'learningDataPoints': instance.learningDataPoints,
      'confidenceScore': instance.confidenceScore,
      'enabled': instance.enabled,
    };

const _$LanguageStyleEnumMap = {
  LanguageStyle.formal: 'formal',
  LanguageStyle.casual: 'casual',
  LanguageStyle.mixed: 'mixed',
  LanguageStyle.unknown: 'unknown',
};

const _$DetailLevelEnumMap = {
  DetailLevel.concise: 'concise',
  DetailLevel.moderate: 'moderate',
  DetailLevel.detailed: 'detailed',
  DetailLevel.verbose: 'verbose',
  DetailLevel.unknown: 'unknown',
};

const _$ParagraphStructureEnumMap = {
  ParagraphStructure.shortParagraphs: 'shortParagraphs',
  ParagraphStructure.mediumParagraphs: 'mediumParagraphs',
  ParagraphStructure.longParagraphs: 'longParagraphs',
  ParagraphStructure.mixed: 'mixed',
  ParagraphStructure.unknown: 'unknown',
};

const _$SentenceComplexityEnumMap = {
  SentenceComplexity.simple: 'simple',
  SentenceComplexity.moderate: 'moderate',
  SentenceComplexity.complex: 'complex',
  SentenceComplexity.varied: 'varied',
  SentenceComplexity.unknown: 'unknown',
};

const _$ModificationTypeEnumMap = {
  ModificationType.grammar: 'grammar',
  ModificationType.spelling: 'spelling',
  ModificationType.style: 'style',
  ModificationType.expansion: 'expansion',
  ModificationType.simplification: 'simplification',
  ModificationType.structure: 'structure',
  ModificationType.vocabulary: 'vocabulary',
  ModificationType.other: 'other',
};

UserFeedback _$UserFeedbackFromJson(Map<String, dynamic> json) => UserFeedback(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      feedbackType: $enumDecode(_$FeedbackTypeEnumMap, json['feedbackType']),
      modificationType:
          $enumDecode(_$ModificationTypeEnumMap, json['modificationType']),
      originalText: json['originalText'] as String,
      modifiedText: json['modifiedText'] as String,
      finalText: json['finalText'] as String?,
      context: json['context'] as String?,
      topics: (json['topics'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      processingTime: (json['processingTime'] as num?)?.toInt(),
      aiConfidence: (json['aiConfidence'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$UserFeedbackToJson(UserFeedback instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp.toIso8601String(),
      'feedbackType': _$FeedbackTypeEnumMap[instance.feedbackType]!,
      'modificationType': _$ModificationTypeEnumMap[instance.modificationType]!,
      'originalText': instance.originalText,
      'modifiedText': instance.modifiedText,
      'finalText': instance.finalText,
      'context': instance.context,
      'topics': instance.topics,
      'processingTime': instance.processingTime,
      'aiConfidence': instance.aiConfidence,
    };

const _$FeedbackTypeEnumMap = {
  FeedbackType.accepted: 'accepted',
  FeedbackType.rejected: 'rejected',
  FeedbackType.partiallyAccepted: 'partiallyAccepted',
  FeedbackType.reverted: 'reverted',
};

WritingAnalysis _$WritingAnalysisFromJson(Map<String, dynamic> json) =>
    WritingAnalysis(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      text: json['text'] as String,
      detectedLanguageStyle:
          $enumDecode(_$LanguageStyleEnumMap, json['detectedLanguageStyle']),
      detectedDetailLevel:
          $enumDecode(_$DetailLevelEnumMap, json['detectedDetailLevel']),
      detectedParagraphStructure: $enumDecode(
          _$ParagraphStructureEnumMap, json['detectedParagraphStructure']),
      detectedSentenceComplexity: $enumDecode(
          _$SentenceComplexityEnumMap, json['detectedSentenceComplexity']),
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      features: json['features'] as Map<String, dynamic>? ?? const {},
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$WritingAnalysisToJson(WritingAnalysis instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp.toIso8601String(),
      'text': instance.text,
      'detectedLanguageStyle':
          _$LanguageStyleEnumMap[instance.detectedLanguageStyle]!,
      'detectedDetailLevel':
          _$DetailLevelEnumMap[instance.detectedDetailLevel]!,
      'detectedParagraphStructure':
          _$ParagraphStructureEnumMap[instance.detectedParagraphStructure]!,
      'detectedSentenceComplexity':
          _$SentenceComplexityEnumMap[instance.detectedSentenceComplexity]!,
      'keywords': instance.keywords,
      'features': instance.features,
      'confidence': instance.confidence,
    };

PreferenceLearningConfig _$PreferenceLearningConfigFromJson(
        Map<String, dynamic> json) =>
    PreferenceLearningConfig(
      enabled: json['enabled'] as bool? ?? true,
      minLearningSamples: (json['minLearningSamples'] as num?)?.toInt() ?? 10,
      maxFeedbackHistory: (json['maxFeedbackHistory'] as num?)?.toInt() ?? 1000,
      learningRate: (json['learningRate'] as num?)?.toDouble() ?? 0.1,
      confidenceThreshold:
          (json['confidenceThreshold'] as num?)?.toDouble() ?? 0.6,
      autoApply: json['autoApply'] as bool? ?? false,
      dataRetentionDays: (json['dataRetentionDays'] as num?)?.toInt() ?? 90,
      anonymizeData: json['anonymizeData'] as bool? ?? true,
    );

Map<String, dynamic> _$PreferenceLearningConfigToJson(
        PreferenceLearningConfig instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'minLearningSamples': instance.minLearningSamples,
      'maxFeedbackHistory': instance.maxFeedbackHistory,
      'learningRate': instance.learningRate,
      'confidenceThreshold': instance.confidenceThreshold,
      'autoApply': instance.autoApply,
      'dataRetentionDays': instance.dataRetentionDays,
      'anonymizeData': instance.anonymizeData,
    };
