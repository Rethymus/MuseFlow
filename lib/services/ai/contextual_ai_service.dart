import 'dart:async';
import 'dart:math';
import '../../models/ai_message.dart';
import '../../models/ai_response.dart';
import '../../models/ai_config.dart';
import '../../models/user_preference.dart';
import 'ai_service.dart';
import 'personalized_ai_service.dart';
import '../preference/writing_analyzer.dart';

/// 上下文AI服务
/// 提供基于文档上下文的智能写作辅助
class ContextualAIService {
  static ContextualAIService? _instance;
  final AIService _baseService;
  final PersonalizedAIService _personalizedService;
  final WritingAnalyzer _writingAnalyzer;

  // 上下文历史记录
  final List<DocumentContext> _contextHistory = [];
  final Map<String, ConversationContext> _conversationContexts = {};
  final StreamController<ContextualSuggestion> _suggestionController =
      StreamController.broadcast();

  // 配置
  int _maxContextHistory = 50;
  double _styleAnalysisThreshold = 0.6;
  int _maxConversationTurns = 20;

  ContextualAIService._({
    AIService? baseService,
    PersonalizedAIService? personalizedService,
    WritingAnalyzer? writingAnalyzer,
  })  : _baseService = baseService ?? AIService.instance,
        _personalizedService =
            personalizedService ?? PersonalizedAIService.instance,
        _writingAnalyzer = writingAnalyzer ?? WritingAnalyzer.instance;

  /// 是否已初始化
  bool _initialized = false;

  /// 获取单例实例
  static ContextualAIService get instance {
    _instance ??= ContextualAIService._();
    return _instance!;
  }

  /// 初始化服务
  static Future<ContextualAIService> initialize({
    AIService? baseService,
    PersonalizedAIService? personalizedService,
    WritingAnalyzer? writingAnalyzer,
  }) async {
    final service = instance;
    service._baseService = baseService ?? AIService.instance;
    service._personalizedService =
        personalizedService ?? PersonalizedAIService.instance;
    service._writingAnalyzer = writingAnalyzer ?? WritingAnalyzer.instance;

    // 确保服务已初始化
    if (!service._personalizedService.isInitialized) {
      await PersonalizedAIService.initialize();
    }

    service._initialized = true;
    return service;
  }

  /// 是否已初始化
  bool get isInitialized => _initialized;

  /// 分析文档风格
  Future<DocumentStyleAnalysis> analyzeDocumentStyle(
    String documentContent, {
    String? documentId,
    String? context,
  }) async {
    // 使用写作分析器分析文档
    final writingAnalysis = await _writingAnalyzer.analyze(
      documentContent,
      context: context,
    );

    // 提取风格特征
    final styleFeatures =
        _extractStyleFeatures(documentContent, writingAnalysis);

    // 分析段落结构
    final paragraphAnalysis = _analyzeParagraphStructure(documentContent);

    // 分析词汇使用
    final vocabularyAnalysis = _analyzeVocabularyUsage(documentContent);

    // 生成风格画像
    final styleProfile = _generateStyleProfile(
      styleFeatures,
      paragraphAnalysis,
      vocabularyAnalysis,
    );

    // 创建文档上下文
    final docContext = DocumentContext(
      documentId: documentId ?? _generateDocumentId(),
      content: documentContent,
      styleAnalysis: writingAnalysis,
      styleProfile: styleProfile,
      timestamp: DateTime.now(),
    );

    // 保存到上下文历史
    _addToContextHistory(docContext);

    return DocumentStyleAnalysis(
      documentId: docContext.documentId,
      styleProfile: styleProfile,
      styleFeatures: styleFeatures,
      paragraphAnalysis: paragraphAnalysis,
      vocabularyAnalysis: vocabularyAnalysis,
      confidence: writingAnalysis.confidence,
      recommendations: _generateStyleRecommendations(styleProfile),
    );
  }

  /// 生成个性化提示词
  Future<String> generatePersonalizedPrompt({
    required String userIntent,
    String? documentId,
    String? conversationId,
    Map<String, dynamic>? customContext,
  }) async {
    final promptBuilder = StringBuffer();

    // 获取文档上下文
    DocumentContext? docContext;
    if (documentId != null) {
      docContext = _findDocumentContext(documentId);
    }

    // 获取对话上下文
    ConversationContext? convContext;
    if (conversationId != null) {
      convContext = _conversationContexts[conversationId];
    }

    // 构建系统提示
    promptBuilder.writeln(_buildSystemPrompt(docContext, convContext));

    // 添加用户意图
    promptBuilder.writeln('\n用户请求：');
    promptBuilder.writeln(userIntent);

    // 添加自定义上下文
    if (customContext != null && customContext.isNotEmpty) {
      promptBuilder.writeln('\n附加上下文：');
      customContext.forEach((key, value) {
        promptBuilder.writeln('- $key: $value');
      });
    }

    // 添加风格指导
    if (docContext != null) {
      final styleGuidance = _generateStyleGuidance(docContext.styleProfile);
      if (styleGuidance.isNotEmpty) {
        promptBuilder.writeln('\n风格指导：');
        promptBuilder.writeln(styleGuidance);
      }
    }

    return promptBuilder.toString();
  }

  /// 发送上下文感知消息
  Future<AIResponse> sendContextualMessage(
    String userMessage, {
    String? documentId,
    String? conversationId,
    AIConfig? config,
    Map<String, dynamic>? customContext,
  }) async {
    // 生成个性化提示
    final personalizedPrompt = await generatePersonalizedPrompt(
      userIntent: userMessage,
      documentId: documentId,
      conversationId: conversationId,
      customContext: customContext,
    );

    // 创建消息
    final messages = [
      AIMessage.system(
        id: _generateMessageId(),
        content: personalizedPrompt,
      ),
      AIMessage.user(
        id: _generateMessageId(),
        content: userMessage,
      ),
    ];

    // 发送消息
    final response = await _personalizedService.sendPersonalizedMessage(
      messages,
      config: config,
      applyPreferences: true,
    );

    // 更新对话上下文
    if (conversationId != null) {
      _updateConversationContext(
        conversationId,
        userMessage,
        response.content,
      );
    }

    return response;
  }

  /// 开始多轮对话
  String startConversation({
    String? documentId,
    String? initialContext,
    Map<String, dynamic>? metadata,
  }) {
    final conversationId = _generateConversationId();

    final context = ConversationContext(
      conversationId: conversationId,
      documentId: documentId,
      startTime: DateTime.now(),
      metadata: metadata,
    );

    if (initialContext != null) {
      context.contextHistory.add(initialContext);
    }

    _conversationContexts[conversationId] = context;
    return conversationId;
  }

  /// 继续对话
  Future<AIResponse> continueConversation(
    String conversationId,
    String userMessage, {
    AIConfig? config,
  }) async {
    final context = _conversationContexts[conversationId];
    if (context == null) {
      throw ArgumentError('Conversation not found: $conversationId');
    }

    // 检查对话轮数限制
    if (context.turnCount >= _maxConversationTurns) {
      // 开始新的对话片段
      _startNewConversationSegment(context);
    }

    // 发送上下文感知消息
    final response = await sendContextualMessage(
      userMessage,
      documentId: context.documentId,
      conversationId: conversationId,
      config: config,
    );

    return response;
  }

  /// 结束对话
  Future<ConversationSummary> endConversation(String conversationId) async {
    final context = _conversationContexts[conversationId];
    if (context == null) {
      throw ArgumentError('Conversation not found: $conversationId');
    }

    // 生成对话摘要
    final summary = _generateConversationSummary(context);

    // 移除对话上下文
    _conversationContexts.remove(conversationId);

    return summary;
  }

  /// 获取上下文建议
  Stream<ContextualSuggestion> get contextualSuggestions {
    return _suggestionController.stream;
  }

  /// 请求实时建议
  Future<void> requestRealtimeSuggestions(
    String currentText, {
    String? documentId,
    String? conversationId,
  }) async {
    // 分析当前文本
    final analysis = await _writingAnalyzer.analyze(currentText);

    // 检查是否需要生成建议
    if (analysis.confidence < _styleAnalysisThreshold) {
      return; // 置信度太低，不生成建议
    }

    // 生成建议
    final suggestions = _generateContextualSuggestions(
      currentText,
      analysis,
      documentId,
    );

    // 发送建议
    for (final suggestion in suggestions) {
      _suggestionController.add(suggestion);
    }
  }

  /// 获取文档上下文历史
  List<DocumentContext> getContextHistory({
    String? documentId,
    int? limit,
  }) {
    Iterable<DocumentContext> history = _contextHistory;

    if (documentId != null) {
      history = history.where((ctx) => ctx.documentId == documentId);
    }

    if (limit != null) {
      history = history.take(limit);
    }

    return history.toList();
  }

  /// 清除上下文历史
  void clearContextHistory({String? documentId}) {
    if (documentId != null) {
      _contextHistory.removeWhere((ctx) => ctx.documentId == documentId);
    } else {
      _contextHistory.clear();
    }
  }

  /// 更新配置
  void updateConfig({
    int? maxContextHistory,
    double? styleAnalysisThreshold,
    int? maxConversationTurns,
  }) {
    _maxContextHistory = maxContextHistory ?? _maxContextHistory;
    _styleAnalysisThreshold = styleAnalysisThreshold ?? _styleAnalysisThreshold;
    _maxConversationTurns = maxConversationTurns ?? _maxConversationTurns;
  }

  // 私有方法

  void _addToContextHistory(DocumentContext context) {
    _contextHistory.add(context);

    // 限制历史记录大小
    while (_contextHistory.length > _maxContextHistory) {
      _contextHistory.removeAt(0);
    }
  }

  DocumentContext? _findDocumentContext(String documentId) {
    return _contextHistory
        .where((ctx) => ctx.documentId == documentId)
        .lastOrNull;
  }

  String _buildSystemPrompt(
    DocumentContext? docContext,
    ConversationContext? convContext,
  ) {
    final prompt = StringBuffer();

    prompt.writeln('你是一个专业的写作助手，能够根据上下文提供智能建议。');

    // 添加文档上下文信息
    if (docContext != null) {
      prompt.writeln('\n文档信息：');
      prompt.writeln('- 文档ID: ${docContext.documentId}');
      prompt.writeln('- 风格特征: ${docContext.styleProfile.primaryStyle}');
      prompt.writeln('- 语言风格: ${docContext.styleAnalysis.languageStyle}');
      prompt.writeln('- 详细程度: ${docContext.styleAnalysis.detailLevel}');
    }

    // 添加对话上下文信息
    if (convContext != null && convContext.contextHistory.isNotEmpty) {
      prompt.writeln('\n对话历史：');
      for (var i = 0; i < convContext.contextHistory.length; i += 2) {
        if (i + 1 < convContext.contextHistory.length) {
          prompt.writeln('用户: ${convContext.contextHistory[i]}');
          prompt.writeln('助手: ${convContext.contextHistory[i + 1]}');
        }
      }
      prompt.writeln('\n当前对话轮数: ${convContext.turnCount}');
    }

    return prompt.toString();
  }

  StyleFeatures _extractStyleFeatures(
    String content,
    dynamic writingAnalysis,
  ) {
    // 分析句子长度分布
    final sentences = content.split(RegExp(r'[。.!?！？]'));
    final sentenceLengths = sentences
        .map((s) => s.trim().length)
        .where((length) => length > 0)
        .toList();

    final avgSentenceLength = sentenceLengths.isEmpty
        ? 0
        : sentenceLengths.reduce((a, b) => a + b) / sentenceLengths.length;

    // 分析段落长度
    final paragraphs = content.split(RegExp(r'\n\n+'));
    final avgParagraphLength = paragraphs.isEmpty
        ? 0
        : paragraphs.map((p) => p.length).reduce((a, b) => a + b) /
            paragraphs.length;

    return StyleFeatures(
      averageSentenceLength: avgSentenceLength,
      averageParagraphLength: avgParagraphLength,
      sentenceLengthVariance: _calculateVariance(sentenceLengths),
      usesFormalLanguage: writingAnalysis.languageStyle == LanguageStyle.formal,
      usesComplexStructures:
          writingAnalysis.sentenceComplexity == SentenceComplexity.complex,
      emotionTone: _detectEmotionTone(content),
    );
  }

  ParagraphAnalysis _analyzeParagraphStructure(String content) {
    final paragraphs = content.split(RegExp(r'\n\n+'));

    return ParagraphAnalysis(
      totalParagraphs: paragraphs.length,
      averageLength: paragraphs.isEmpty
          ? 0
          : paragraphs.map((p) => p.length).reduce((a, b) => a + b) /
              paragraphs.length,
      usesIndentation: content.contains('    '),
      topicSentencePattern: _detectTopicSentencePattern(content),
      transitionUsage: _detectTransitionUsage(content),
    );
  }

  VocabularyAnalysis _analyzeVocabularyUsage(String content) {
    final words = content.split(RegExp(r'[\s,。.!?！？:：;；、]'));
    final uniqueWords = words.where((w) => w.isNotEmpty).toSet();

    return VocabularyAnalysis(
      totalWords: words.length,
      uniqueWordCount: uniqueWords.length,
      vocabularyRichness: uniqueWords.length / max(words.length, 1),
      technicalTerms: _detectTechnicalTerms(content),
      metaphorUsage: _detectMetaphorUsage(content),
    );
  }

  DocumentStyleProfile _generateStyleProfile(
    StyleFeatures styleFeatures,
    ParagraphAnalysis paragraphAnalysis,
    VocabularyAnalysis vocabularyAnalysis,
  ) {
    String primaryStyle;
    List<String> secondaryStyles = [];

    // 确定主要风格
    if (styleFeatures.usesFormalLanguage) {
      primaryStyle = 'formal';
      secondaryStyles.add('professional');
    } else if (styleFeatures.emotionTone == EmotionTone.emotional) {
      primaryStyle = 'emotional';
      secondaryStyles.add('expressive');
    } else {
      primaryStyle = 'neutral';
    }

    if (styleFeatures.usesComplexStructures) {
      secondaryStyles.add('complex');
    } else {
      secondaryStyles.add('simple');
    }

    if (vocabularyAnalysis.vocabularyRichness > 0.7) {
      secondaryStyles.add('rich_vocabulary');
    }

    return DocumentStyleProfile(
      primaryStyle: primaryStyle,
      secondaryStyles: secondaryStyles,
      consistency: _calculateStyleConsistency(styleFeatures),
      readability: _calculateReadability(styleFeatures, vocabularyAnalysis),
    );
  }

  List<String> _generateStyleRecommendations(DocumentStyleProfile profile) {
    final recommendations = <String>[];

    if (profile.readability < 0.6) {
      recommendations.add('建议简化句子结构以提高可读性');
    }

    if (profile.consistency < 0.7) {
      recommendations.add('建议保持写作风格的一致性');
    }

    if (!profile.secondaryStyles.contains('rich_vocabulary')) {
      recommendations.add('可以考虑使用更丰富的词汇');
    }

    return recommendations;
  }

  String _generateStyleGuidance(DocumentStyleProfile profile) {
    final guidance = StringBuffer();

    switch (profile.primaryStyle) {
      case 'formal':
        guidance.writeln('- 使用正式、专业的语言');
        guidance.writeln('- 避免口语化表达');
        guidance.writeln('- 保持客观、中立的语气');
        break;
      case 'emotional':
        guidance.writeln('- 使用富有感情色彩的语言');
        guidance.writeln('- 适当使用修辞手法');
        guidance.writeln('- 注重情感表达');
        break;
      case 'neutral':
        guidance.writeln('- 保持平衡、客观的语言');
        guidance.writeln('- 避免过于极端的表达');
        break;
    }

    if (profile.secondaryStyles.contains('complex')) {
      guidance.writeln('- 使用多样化的句子结构');
      guidance.writeln('- 适当使用复合句');
    }

    return guidance.toString();
  }

  void _updateConversationContext(
    String conversationId,
    String userMessage,
    String assistantResponse,
  ) {
    final context = _conversationContexts[conversationId];
    if (context != null) {
      context.contextHistory.add(userMessage);
      context.contextHistory.add(assistantResponse);
      context.turnCount++;
      context.lastUpdateTime = DateTime.now();
    }
  }

  void _startNewConversationSegment(ConversationContext context) {
    // 保存当前片段摘要
    context.segments.add(_createConversationSegment(context));

    // 保留最后几轮对话作为上下文
    final recentTurns = min(5, context.contextHistory.length ~/ 2);
    context.contextHistory = context.contextHistory.sublist(
      context.contextHistory.length - recentTurns * 2,
    );
    context.turnCount = recentTurns;
  }

  ConversationSegment _createConversationSegment(ConversationContext context) {
    return ConversationSegment(
      startTime: context.segments.isEmpty
          ? context.startTime
          : context.segments.last.endTime,
      endTime: DateTime.now(),
      turnCount: context.turnCount,
      summary: _generateSegmentSummary(context),
    );
  }

  String _generateSegmentSummary(ConversationContext context) {
    // 简单摘要生成
    return '对话片段，包含 ${context.turnCount} 轮对话';
  }

  ConversationSummary _generateConversationSummary(
      ConversationContext context) {
    return ConversationSummary(
      conversationId: context.conversationId,
      documentId: context.documentId,
      startTime: context.startTime,
      endTime: DateTime.now(),
      totalTurns: context.turnCount,
      segments: context.segments,
      metadata: context.metadata,
    );
  }

  List<ContextualSuggestion> _generateContextualSuggestions(
    String currentText,
    dynamic analysis,
    String? documentId,
  ) {
    final suggestions = <ContextualSuggestion>[];

    // 根据分析生成建议
    if (analysis.confidence > 0.7) {
      // 风格建议
      suggestions.add(ContextualSuggestion(
        type: SuggestionType.style,
        title: '风格一致性',
        description: '保持与文档风格的一致性',
        confidence: analysis.confidence,
      ));

      // 词汇建议
      if (analysis.keywords.isNotEmpty) {
        suggestions.add(ContextualSuggestion(
          type: SuggestionType.vocabulary,
          title: '词汇扩展',
          description: '考虑使用更丰富的词汇',
          confidence: analysis.confidence * 0.8,
        ));
      }
    }

    return suggestions;
  }

  EmotionTone _detectEmotionTone(String content) {
    final emotionalIndicators = [
      RegExp(r'[很高兴！|太棒了！|太好了！]'),
      RegExp(r'[很遗憾！|太难过了！|很失望！]'),
      RegExp(r'[太惊讶了！|很震惊！]'),
    ];

    final hasEmotionalContent =
        emotionalIndicators.any((pattern) => pattern.hasMatch(content));

    return hasEmotionalContent ? EmotionTone.emotional : EmotionTone.neutral;
  }

  double _calculateVariance(List<int> values) {
    if (values.isEmpty) return 0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
            values.length;

    return variance;
  }

  double _calculateStyleConsistency(StyleFeatures features) {
    // 简化的一致性计算
    return 0.8; // 实际实现应该基于更多因素
  }

  double _calculateReadability(
    StyleFeatures features,
    VocabularyAnalysis vocab,
  ) {
    // 简化的可读性计算
    final sentenceScore = features.averageSentenceLength > 20 ? 0.6 : 0.8;
    final vocabScore = vocab.vocabularyRichness > 0.5 ? 0.8 : 0.7;

    return (sentenceScore + vocabScore) / 2;
  }

  String _detectTopicSentencePattern(String content) {
    // 简化的主题句模式检测
    return 'topic_first';
  }

  double _detectTransitionUsage(String content) {
    final transitions = ['因此', '然而', '但是', '所以', '而且'];
    int count = 0;

    for (final transition in transitions) {
      count += transition.allMatches(content).length;
    }

    return count.toDouble();
  }

  List<String> _detectTechnicalTerms(String content) {
    // 简化的技术术语检测
    return [];
  }

  double _detectMetaphorUsage(String content) {
    // 简化的隐喻使用检测
    return 0.0;
  }

  String _generateDocumentId() {
    return 'doc_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateConversationId() {
    return 'conv_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  /// 清理资源
  void dispose() {
    _suggestionController.close();
    _contextHistory.clear();
    _conversationContexts.clear();
  }
}

/// 文档上下文
class DocumentContext {
  final String documentId;
  final String content;
  final dynamic styleAnalysis;
  final DocumentStyleProfile styleProfile;
  final DateTime timestamp;

  DocumentContext({
    required this.documentId,
    required this.content,
    required this.styleAnalysis,
    required this.styleProfile,
    required this.timestamp,
  });
}

/// 对话上下文
class ConversationContext {
  final String conversationId;
  final String? documentId;
  final DateTime startTime;
  final List<String> contextHistory = [];
  final Map<String, dynamic>? metadata;
  int turnCount = 0;
  DateTime? lastUpdateTime;
  final List<ConversationSegment> segments = [];

  ConversationContext({
    required this.conversationId,
    this.documentId,
    required this.startTime,
    this.metadata,
  });
}

/// 对话片段
class ConversationSegment {
  final DateTime startTime;
  final DateTime endTime;
  final int turnCount;
  final String summary;

  ConversationSegment({
    required this.startTime,
    required this.endTime,
    required this.turnCount,
    required this.summary,
  });
}

/// 对话摘要
class ConversationSummary {
  final String conversationId;
  final String? documentId;
  final DateTime startTime;
  final DateTime endTime;
  final int totalTurns;
  final List<ConversationSegment> segments;
  final Map<String, dynamic>? metadata;

  ConversationSummary({
    required this.conversationId,
    this.documentId,
    required this.startTime,
    required this.endTime,
    required this.totalTurns,
    required this.segments,
    this.metadata,
  });
}

/// 文档风格分析结果
class DocumentStyleAnalysis {
  final String documentId;
  final DocumentStyleProfile styleProfile;
  final StyleFeatures styleFeatures;
  final ParagraphAnalysis paragraphAnalysis;
  final VocabularyAnalysis vocabularyAnalysis;
  final double confidence;
  final List<String> recommendations;

  DocumentStyleAnalysis({
    required this.documentId,
    required this.styleProfile,
    required this.styleFeatures,
    required this.paragraphAnalysis,
    required this.vocabularyAnalysis,
    required this.confidence,
    required this.recommendations,
  });
}

/// 文档风格画像
class DocumentStyleProfile {
  final String primaryStyle;
  final List<String> secondaryStyles;
  final double consistency;
  final double readability;

  DocumentStyleProfile({
    required this.primaryStyle,
    required this.secondaryStyles,
    required this.consistency,
    required this.readability,
  });
}

/// 风格特征
class StyleFeatures {
  final double averageSentenceLength;
  final double averageParagraphLength;
  final double sentenceLengthVariance;
  final bool usesFormalLanguage;
  final bool usesComplexStructures;
  final EmotionTone emotionTone;

  StyleFeatures({
    required this.averageSentenceLength,
    required this.averageParagraphLength,
    required this.sentenceLengthVariance,
    required this.usesFormalLanguage,
    required this.usesComplexStructures,
    required this.emotionTone,
  });
}

/// 段落分析
class ParagraphAnalysis {
  final int totalParagraphs;
  final double averageLength;
  final bool usesIndentation;
  final String topicSentencePattern;
  final double transitionUsage;

  ParagraphAnalysis({
    required this.totalParagraphs,
    required this.averageLength,
    required this.usesIndentation,
    required this.topicSentencePattern,
    required this.transitionUsage,
  });
}

/// 词汇分析
class VocabularyAnalysis {
  final int totalWords;
  final int uniqueWordCount;
  final double vocabularyRichness;
  final List<String> technicalTerms;
  final double metaphorUsage;

  VocabularyAnalysis({
    required this.totalWords,
    required this.uniqueWordCount,
    required this.vocabularyRichness,
    required this.technicalTerms,
    required this.metaphorUsage,
  });
}

/// 上下文建议
class ContextualSuggestion {
  final SuggestionType type;
  final String title;
  final String description;
  final double confidence;
  final DateTime timestamp = DateTime.now();

  ContextualSuggestion({
    required this.type,
    required this.title,
    required this.description,
    required this.confidence,
  });
}

/// 建议类型
enum SuggestionType {
  style,
  vocabulary,
  grammar,
  structure,
  content,
}

/// 情感基调
enum EmotionTone {
  emotional,
  neutral,
}
