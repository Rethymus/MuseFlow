import 'dart:async';
import 'dart:math';
import '../../models/ai_message.dart';
import '../../models/ai_response.dart';
import '../../models/ai_config.dart';
import '../../models/user_preference.dart';
import 'ai_service.dart';
import 'contextual_ai_service.dart';
import '../preference/writing_analyzer.dart';

/// 实时写作助手
/// 提供预测性写作辅助和实时建议
class RealTimeWritingAssistant {
  static RealTimeWritingAssistant? _instance;
  final ContextualAIService _contextualService;
  final WritingAnalyzer _writingAnalyzer;

  // 预测和分析状态
  final Map<String, WritingSession> _activeSessions = {};
  final StreamController<WritingAssistantEvent> _eventController =
      StreamController.broadcast();

  // 配置
  int _predictionWindowSize = 50; // 预测窗口大小（字符数）
  double _predictionConfidenceThreshold = 0.7;
  int _suggestionDebounceMs = 300; // 建议防抖延迟（毫秒）
  int _maxSessionDuration = 30 * 60 * 1000; // 最大会话时长（30分钟）

  RealTimeWritingAssistant._({
    ContextualAIService? contextualService,
    WritingAnalyzer? writingAnalyzer,
  }) : _contextualService = contextualService ?? ContextualAIService.instance,
       _writingAnalyzer = writingAnalyzer ?? WritingAnalyzer.instance;

  /// 获取单例实例
  static RealTimeWritingAssistant get instance {
    _instance ??= RealTimeWritingAssistant._();
    return _instance!;
  }

  /// 初始化服务
  static Future<RealTimeWritingAssistant> initialize({
    ContextualAIService? contextualService,
    WritingAnalyzer? writingAnalyzer,
  }) async {
    final service = instance;
    service._contextualService = contextualService ?? ContextualAIService.instance;
    service._writingAnalyzer = writingAnalyzer ?? WritingAnalyzer.instance;

    // 确保上下文服务已初始化
    if (!service._contextualService.isInitialized) {
      await ContextualAIService.initialize();
    }

    return service;
  }

  /// 开始写作会话
  String startWritingSession({
    required String documentId,
    String? conversationId,
    String? initialContent,
    Map<String, dynamic>? metadata,
  }) {
    final sessionId = _generateSessionId();

    final session = WritingSession(
      sessionId: sessionId,
      documentId: documentId,
      conversationId: conversationId,
      startTime: DateTime.now(),
      initialContent: initialContent ?? '',
      metadata: metadata,
    );

    _activeSessions[sessionId] = session;

    // 发送会话开始事件
    _eventController.add(WritingAssistantEvent(
      type: AssistantEventType.sessionStarted,
      sessionId: sessionId,
      data: {'documentId': documentId},
    ));

    return sessionId;
  }

  /// 处理文本输入
  Future<List<WritingPrediction>> processTextInput(
    String sessionId,
    String currentText, {
    int? cursorPosition,
  }) async {
    final session = _activeSessions[sessionId];
    if (session == null) {
      throw ArgumentError('Session not found: $sessionId');
    }

    // 更新会话状态
    session.lastUpdateTime = DateTime.now();
    session.currentContent = currentText;
    session.cursorPosition = cursorPosition ?? currentText.length;

    // 检查会话是否超时
    if (_isSessionExpired(session)) {
      _endSession(sessionId);
      return [];
    }

    // 分析当前文本
    final analysis = await _writingAnalyzer.analyze(currentText);

    // 生成预测
    final predictions = await _generatePredictions(
      session,
      currentText,
      analysis,
    );

    // 更新上下文
    await _updateContextualUnderstanding(session, currentText, analysis);

    // 生成情境化建议
    final suggestions = await _generateContextualSuggestions(
      session,
      currentText,
      analysis,
    );

    // 发送建议事件
    for (final suggestion in suggestions) {
      _eventController.add(WritingAssistantEvent(
        type: AssistantEventType.suggestionGenerated,
        sessionId: sessionId,
        data: suggestion.toJson(),
      ));
    }

    return predictions;
  }

  /// 预测用户需求
  Future<UserIntentPrediction> predictUserNeeds(
    String sessionId,
    String currentText,
  ) async {
    final session = _activeSessions[sessionId];
    if (session == null) {
      throw ArgumentError('Session not found: $sessionId');
    }

    // 分析写作模式
    final writingPattern = _analyzeWritingPattern(session, currentText);

    // 检测用户意图
    final detectedIntents = _detectUserIntents(currentText, writingPattern);

    // 预测下一步动作
    final nextActions = _predictNextActions(
      session,
      currentText,
      detectedIntents,
    );

    // 计算置信度
    final confidence = _calculateIntentConfidence(detectedIntents, writingPattern);

    return UserIntentPrediction(
      primaryIntent: detectedIntents.isEmpty
          ? WritingIntent.continueWriting
          : detectedIntents.first.intent,
      alternativeIntents: detectedIntents
          .skip(1)
          .map((d) => d.intent)
          .toList(),
      suggestedActions: nextActions,
      confidence: confidence,
      contextFactors: _extractContextFactors(session, currentText),
    );
  }

  /// 生成情境化提示
  Future<ContextualPrompt> generateContextualPrompt(
    String sessionId,
    String currentText, {
    String? specificContext,
    List<String>? focusAreas,
  }) async {
    final session = _activeSessions[sessionId];
    if (session == null) {
      throw ArgumentError('Session not found: $sessionId');
    }

    // 分析当前状态
    final analysis = await _writingAnalyzer.analyze(currentText);

    // 确定提示重点
    final promptFocus = _determinePromptFocus(
      currentText,
      analysis,
      focusAreas,
    );

    // 生成提示内容
    final promptContent = await _generatePromptContent(
      session,
      currentText,
      analysis,
      promptFocus,
    );

    // 生成格式建议
    final formatSuggestions = _generateFormatSuggestions(
      currentText,
      analysis,
    );

    return ContextualPrompt(
      content: promptContent,
      focusAreas: promptFocus,
      formatSuggestions: formatSuggestions,
      timingHint: _determineTimingHint(currentText, analysis),
      confidence: analysis.confidence,
    );
  }

  /// 提供格式建议
  Future<FormatSuggestion> provideFormatSuggestion(
    String sessionId,
    String currentText,
  ) async {
    final session = _activeSessions[sessionId];
    if (session == null) {
      throw ArgumentError('Session not found: $sessionId');
    }

    // 分析格式
    final formatAnalysis = await _analyzeFormat(currentText);

    // 生成建议
    final suggestions = _generateFormatImprovementSuggestions(formatAnalysis);

    return FormatSuggestion(
      currentFormat: formatAnalysis.currentFormat,
      suggestedFormat: formatAnalysis.suggestedFormat,
      specificSuggestions: suggestions,
      priority: _calculateFormatPriority(formatAnalysis),
      estimatedImpact: _estimateFormatImpact(formatAnalysis),
    );
  }

  /// 结束写作会话
  Future<WritingSessionSummary> endWritingSession(String sessionId) async {
    final session = _activeSessions[sessionId];
    if (session == null) {
      throw ArgumentError('Session not found: $sessionId');
    }

    // 生成会话摘要
    final summary = await _generateSessionSummary(session);

    // 移除会话
    _activeSessions.remove(sessionId);

    // 发送会话结束事件
    _eventController.add(WritingAssistantEvent(
      type: AssistantEventType.sessionEnded,
      sessionId: sessionId,
      data: summary.toJson(),
    ));

    return summary;
  }

  /// 获取写作助手事件流
  Stream<WritingAssistantEvent> get events => _eventController.stream;

  /// 获取活跃会话
  List<WritingSession> get activeSessions => _activeSessions.values.toList();

  /// 更新配置
  void updateConfig({
    int? predictionWindowSize,
    double? predictionConfidenceThreshold,
    int? suggestionDebounceMs,
    int? maxSessionDuration,
  }) {
    _predictionWindowSize = predictionWindowSize ?? _predictionWindowSize;
    _predictionConfidenceThreshold =
        predictionConfidenceThreshold ?? _predictionConfidenceThreshold;
    _suggestionDebounceMs = suggestionDebounceMs ?? _suggestionDebounceMs;
    _maxSessionDuration = maxSessionDuration ?? _maxSessionDuration;
  }

  // 私有方法

  Future<List<WritingPrediction>> _generatePredictions(
    WritingSession session,
    String currentText,
    dynamic analysis,
  ) async {
    final predictions = <WritingPrediction>[];

    // 预测下一个词/短语
    final nextWords = await _predictNextWords(currentText, analysis);
    if (nextWords.isNotEmpty) {
      predictions.addAll(nextWords);
    }

    // 预测句子补全
    final sentenceCompletion = await _predictSentenceCompletion(currentText, analysis);
    if (sentenceCompletion != null) {
      predictions.add(sentenceCompletion);
    }

    // 预测段落结构
    final paragraphStructure = await _predictParagraphStructure(currentText, analysis);
    if (paragraphStructure != null) {
      predictions.add(paragraphStructure);
    }

    return predictions;
  }

  Future<List<WordPrediction>> _predictNextWords(
    String currentText,
    dynamic analysis,
  ) async {
    final predictions = <WordPrediction>[];

    // 基于上下文预测下一个词
    final words = currentText.split(RegExp(r'[\s,。.!?！？]'));
    if (words.isEmpty) return predictions;

    final lastWord = words.last.toLowerCase();

    // 简化的预测逻辑（实际应该使用更复杂的模型）
    final commonNextWords = _getCommonNextWords(lastWord);

    for (final entry in commonNextWords.entries) {
      if (entry.value >= _predictionConfidenceThreshold) {
        predictions.add(WordPrediction(
          word: entry.key,
          confidence: entry.value,
          position: currentText.length,
        ));
      }
    }

    return predictions;
  }

  Future<SentencePrediction?> _predictSentenceCompletion(
    String currentText,
    dynamic analysis,
  ) async {
    // 检测句子是否未完成
    if (_isSentenceComplete(currentText)) {
      return null;
    }

    // 生成句子补全建议
    final completion = _generateSentenceCompletion(currentText);

    return SentencePrediction(
      suggestedCompletion: completion,
      confidence: 0.7, // 简化的置信度
      position: currentText.length,
    );
  }

  Future<ParagraphStructurePrediction?> _predictParagraphStructure(
    String currentText,
    dynamic analysis,
  ) async {
    // 分析段落结构
    final paragraphs = currentText.split(RegExp(r'\n\n+'));
    final currentParagraph = paragraphs.isNotEmpty ? paragraphs.last : '';

    // 预测段落是否即将结束
    if (currentParagraph.length > 200) {
      return ParagraphStructurePrediction(
        prediction: ParagraphAction.newParagraph,
        confidence: 0.8,
        reason: '段落长度较长，建议开始新段落',
      );
    }

    return null;
  }

  Future<void> _updateContextualUnderstanding(
    WritingSession session,
    String currentText,
    dynamic analysis,
  ) async {
    // 更新会话的上下文理解
    session.contextUnderstanding = ContextUnderstanding(
      currentTopic: _detectCurrentTopic(currentText),
      writingStyle: analysis.languageStyle,
      contentStructure: _analyzeContentStructure(currentText),
      emotionalTone: _detectEmotionalTone(currentText),
    );
  }

  Future<List<ContextualSuggestion>> _generateContextualSuggestions(
    WritingSession session,
    String currentText,
    dynamic analysis,
  ) async {
    final suggestions = <ContextualSuggestion>[];

    // 基于分析生成建议
    if (analysis.confidence > 0.6) {
      // 词汇建议
      if (_shouldSuggestVocabulary(currentText, analysis)) {
        suggestions.add(ContextualSuggestion(
          type: SuggestionType.vocabulary,
          title: '词汇丰富性',
          description: '考虑使用更丰富的词汇',
          confidence: analysis.confidence * 0.8,
          applicableText: _findSimpleWords(currentText),
        ));
      }

      // 结构建议
      if (_shouldSuggestStructure(currentText, analysis)) {
        suggestions.add(ContextualSuggestion(
          type: SuggestionType.structure,
          title: '结构优化',
          description: '建议优化文本结构',
          confidence: analysis.confidence * 0.7,
        ));
      }

      // 风格建议
      if (_shouldSuggestStyle(currentText, analysis)) {
        suggestions.add(ContextualSuggestion(
          type: SuggestionType.style,
          title: '风格一致性',
          description: '保持写作风格的一致性',
          confidence: analysis.confidence * 0.9,
        ));
      }
    }

    return suggestions;
  }

  WritingPattern _analyzeWritingPattern(
    WritingSession session,
    String currentText,
  ) {
    // 计算写作速度
    final timeElapsed = DateTime.now().difference(session.lastUpdateTime);
    final textAdded = currentText.length - session.currentContent.length;
    final writingSpeed = timeElapsed.inMilliseconds > 0
        ? textAdded / timeElapsed.inMilliseconds * 1000 // 字符/秒
        : 0;

    // 分析编辑模式
    final editPattern = _analyzeEditPattern(session, currentText);

    // 分析暂停模式
    final pausePattern = _analyzePausePattern(session);

    return WritingPattern(
      writingSpeed: writingSpeed,
      editPattern: editPattern,
      pausePattern: pausePattern,
      averageWordLength: _calculateAverageWordLength(currentText),
    );
  }

  List<DetectedIntent> _detectUserIntents(
    String currentText,
    WritingPattern pattern,
  ) {
    final intents = <DetectedIntent>[];

    // 检测不同的意图
    if (_isAskingQuestion(currentText)) {
      intents.add(DetectedIntent(
        intent: WritingIntent.askQuestion,
        confidence: 0.8,
        evidence: ['疑问句结构'],
      ));
    }

    if (_isListingItems(currentText)) {
      intents.add(DetectedIntent(
        intent: WritingIntent.createList,
        confidence: 0.7,
        evidence: ['列举特征'],
      ));
    }

    if (_isExplainingConcept(currentText)) {
      intents.add(DetectedIntent(
        intent: WritingIntent.explainConcept,
        confidence: 0.6,
        evidence: ['解释性语言'],
      ));
    }

    if (_isMakingArgument(currentText)) {
      intents.add(DetectedIntent(
        intent: WritingIntent.makeArgument,
        confidence: 0.7,
        evidence: ['论证性语言'],
      ));
    }

    // 默认意图：继续写作
    if (intents.isEmpty) {
      intents.add(DetectedIntent(
        intent: WritingIntent.continueWriting,
        confidence: 0.9,
        evidence: ['常规写作'],
      ));
    }

    return intents;
  }

  List<SuggestedAction> _predictNextActions(
    WritingSession session,
    String currentText,
    List<DetectedIntent> intents,
  ) {
    final actions = <SuggestedAction>[];

    for (final intent in intents) {
      switch (intent.intent) {
        case WritingIntent.continueWriting:
          actions.add(SuggestedAction(
            type: ActionType.continueWriting,
            description: '继续当前写作',
            priority: ActionPriority.high,
          ));
          break;
        case WritingIntent.askQuestion:
          actions.add(SuggestedAction(
            type: ActionType.answerQuestion,
            description: '回答问题',
            priority: ActionPriority.medium,
          ));
          break;
        case WritingIntent.createList:
          actions.add(SuggestedAction(
            type: ActionType.formatAsList,
            description: '格式化为列表',
            priority: ActionPriority.low,
          ));
          break;
        case WritingIntent.explainConcept:
          actions.add(SuggestedAction(
            type: ActionType.provideExample,
            description: '提供示例',
            priority: ActionPriority.medium,
          ));
          break;
        case WritingIntent.makeArgument:
          actions.add(SuggestedAction(
            type: ActionType.strengthenArgument,
            description: '加强论证',
            priority: ActionPriority.medium,
          ));
          break;
      }
    }

    return actions;
  }

  double _calculateIntentConfidence(
    List<DetectedIntent> intents,
    WritingPattern pattern,
  ) {
    if (intents.isEmpty) return 0.5;

    // 基于检测到的意图和写作模式计算置信度
    final avgIntentConfidence = intents
        .map((i) => i.confidence)
        .reduce((a, b) => a + b) / intents.length;

    final patternFactor = _calculatePatternFactor(pattern);

    return avgIntentConfidence * patternFactor;
  }

  List<String> _determinePromptFocus(
    String currentText,
    dynamic analysis,
    List<String>? requestedAreas,
  ) {
    if (requestedAreas != null && requestedAreas.isNotEmpty) {
      return requestedAreas;
    }

    final focusAreas = <String>[];

    // 基于分析确定关注区域
    if (analysis.confidence < 0.7) {
      focusAreas.add('风格一致性');
    }

    if (_needsStructureImprovement(currentText)) {
      focusAreas.add('结构优化');
    }

    if (_needsVocabularyEnhancement(currentText)) {
      focusAreas.add('词汇丰富性');
    }

    if (focusAreas.isEmpty) {
      focusAreas.add('内容连贯性');
    }

    return focusAreas;
  }

  Future<String> _generatePromptContent(
    WritingSession session,
    String currentText,
    dynamic analysis,
    List<String> focusAreas,
  ) async {
    final prompt = StringBuffer();

    prompt.writeln('基于当前写作状态，建议关注以下方面：');

    for (final area in focusAreas) {
      prompt.writeln('\n$area:');
      prompt.writeln('- ${_getAreaSpecificSuggestion(area, currentText, analysis)}');
    }

    return prompt.toString();
  }

  FormatSuggestions _generateFormatSuggestions(
    String currentText,
    dynamic analysis,
  ) {
    final suggestions = FormatSuggestions();

    // 分析段落格式
    if (currentText.contains('\n\n')) {
      suggestions.paragraphBreaks = '适当';
    } else if (currentText.contains('\n')) {
      suggestions.paragraphBreaks = '较少';
    } else {
      suggestions.paragraphBreaks = '缺失';
    }

    // 分析列表格式
    suggestions.listUsage = _detectListUsage(currentText);

    // 分析标点使用
    suggestions.punctuationStyle = _detectPunctuationStyle(currentText);

    return suggestions;
  }

  bool _isSessionExpired(WritingSession session) {
    final elapsed = DateTime.now().difference(session.lastUpdateTime);
    return elapsed.inMilliseconds > _maxSessionDuration;
  }

  void _endSession(String sessionId) {
    _activeSessions.remove(sessionId);
    _eventController.add(WritingAssistantEvent(
      type: AssistantEventType.sessionEnded,
      sessionId: sessionId,
      data: {'reason': 'expired'},
    ));
  }

  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  // 辅助方法

  Map<String, double> _getCommonNextWords(String lastWord) {
    // 简化的常见后续词词典
    final commonNextWords = <String, Map<String, double>>{
      '的': {'是': 0.8, '是': 0.7, '人': 0.6},
      '是': {'一': 0.7, '非常': 0.6, '很': 0.5},
      '很': {'好': 0.8, '多': 0.7, '重要': 0.6},
      '但': {'是': 0.7, '不过': 0.6, '然而': 0.5},
    };

    return commonNextWords[lastWord] ?? {};
  }

  bool _isSentenceComplete(String text) {
    return text.contains(RegExp(r'[。.!?！？]\s*$'));
  }

  String _generateSentenceCompletion(String text) {
    // 简化的句子补全逻辑
    if (text.endsWith('因为')) {
      return '所以';
    } else if (text.endsWith('虽然')) {
      return '但是';
    } else if (text.endsWith('不仅')) {
      return '而且';
    }
    return '';
  }

  String _detectCurrentTopic(String text) {
    // 简化的主题检测
    final words = text.split(RegExp(r'[\s,。.!?！？]'));
    return words.isNotEmpty ? words.first : '';
  }

  ContentStructure _analyzeContentStructure(String text) {
    final paragraphs = text.split(RegExp(r'\n\n+'));
    return ContentStructure(
      totalParagraphs: paragraphs.length,
      hasIntroduction: paragraphs.isNotEmpty,
      hasConclusion: paragraphs.length > 1,
      hasBody: paragraphs.length > 2,
    );
  }

  EmotionalTone _detectEmotionalTone(String text) {
    final positiveWords = ['高兴', '愉快', '满意', '成功'];
    final negativeWords = ['失望', '难过', '失败', '遗憾'];

    final hasPositive = positiveWords.any((word) => text.contains(word));
    final hasNegative = negativeWords.any((word) => text.contains(word));

    if (hasPositive) return EmotionalTone.positive;
    if (hasNegative) return EmotionalTone.negative;
    return EmotionalTone.neutral;
  }

  bool _shouldSuggestVocabulary(String text, dynamic analysis) {
    final words = text.split(RegExp(r'[\s,。.!?！？]'));
    final uniqueWords = words.toSet();
    return uniqueWords.length / words.length < 0.5;
  }

  bool _shouldSuggestStructure(String text, dynamic analysis) {
    final paragraphs = text.split(RegExp(r'\n\n+'));
    return paragraphs.length < 3 && text.length > 200;
  }

  bool _shouldSuggestStyle(String text, dynamic analysis) {
    return analysis.confidence < 0.8;
  }

  String _findSimpleWords(String text) {
    // 简化的简单词检测
    return '';
  }

  EditPattern _analyzeEditPattern(WritingSession session, String currentText) {
    return EditPattern(
      deletions: 0,
      insertions: currentText.length - session.currentContent.length,
      replacements: 0,
    );
  }

  PausePattern _analyzePausePattern(WritingSession session) {
    return PausePattern(
      shortPauses: 0,
      longPauses: 0,
      thinkingPauses: 0,
    );
  }

  double _calculateAverageWordLength(String text) {
    final words = text.split(RegExp(r'[\s,。.!?！？]'));
    if (words.isEmpty) return 0;

    final totalLength = words.fold<int>(0, (sum, word) => sum + word.length);
    return totalLength / words.length;
  }

  bool _isAskingQuestion(String text) {
    return text.contains('?') || text.contains('？') ||
           text.contains(RegExp(r'[是否|怎样|如何|为什么|啥]'));
  }

  bool _isListingItems(String text) {
    return text.contains(RegExp(r'[\n]')) ||
           text.contains(RegExp(r'[，、]')) ||
           text.contains('首先') || text.contains('其次');
  }

  bool _isExplainingConcept(String text) {
    return text.contains('是指') || text.contains('意思是') ||
           text.contains('例如') || text.contains('比如');
  }

  bool _isMakingArgument(String text) {
    return text.contains('因此') || text.contains('所以') ||
           text.contains('然而') || text.contains('但是');
  }

  double _calculatePatternFactor(WritingPattern pattern) {
    return min(1.0, pattern.writingSpeed / 10 + 0.5);
  }

  bool _needsStructureImprovement(String text) {
    final paragraphs = text.split(RegExp(r'\n\n+'));
    return paragraphs.length < 2 && text.length > 150;
  }

  bool _needsVocabularyEnhancement(String text) {
    final words = text.split(RegExp(r'[\s,。.!?！？]'));
    final uniqueWords = words.toSet();
    return uniqueWords.length / max(words.length, 1) < 0.4;
  }

  String _getAreaSpecificSuggestion(
    String area,
    String text,
    dynamic analysis,
  ) {
    switch (area) {
      case '风格一致性':
        return '保持当前的语言风格和表达方式';
      case '结构优化':
        return '考虑添加段落分隔和过渡语句';
      case '词汇丰富性':
        return '使用更多样化的词汇来表达';
      case '内容连贯性':
        return '确保内容逻辑连贯，思路清晰';
      default:
        return '关注文本质量';
    }
  }

  Future<FormatAnalysis> _analyzeFormat(String text) async {
    return FormatAnalysis(
      currentFormat: _detectCurrentFormat(text),
      suggestedFormat: 'standard',
      issues: [],
      strengths: [],
    );
  }

  String _detectCurrentFormat(String text) {
    if (text.contains('#')) return 'markdown';
    if (text.contains('<html')) return 'html';
    return 'plain';
  }

  List<String> _generateFormatImprovementSuggestions(FormatAnalysis analysis) {
    return [];
  }

  ActionPriority _calculateFormatPriority(FormatAnalysis analysis) {
    return ActionPriority.low;
  }

  double _estimateFormatImpact(FormatAnalysis analysis) {
    return 0.5;
  }

  String _determineTimingHint(String text, dynamic analysis) {
    return '建议在完成当前段落后进行修改';
  }

  String _detectListUsage(String text) {
    if (text.contains(RegExp(r'^\s*[-*]\s', multiLine: true))) {
      return '项目符号';
    } else if (text.contains(RegExp(r'^\s*\d+\.\s', multiLine: true))) {
      return '编号列表';
    }
    return '无列表';
  }

  String _detectPunctuationStyle(String text) {
    final hasChinesePunctuation = text.contains(RegExp(r'[，。！？；：]'));
    final hasEnglishPunctuation = text.contains(RegExp(r'[,.!?;:]'));

    if (hasChinesePunctuation && hasEnglishPunctuation) {
      return '混合';
    } else if (hasChinesePunctuation) {
      return '中文标点';
    } else if (hasEnglishPunctuation) {
      return '英文标点';
    }
    return '较少';
  }

  Future<WritingSessionSummary> _generateSessionSummary(WritingSession session) async {
    return WritingSessionSummary(
      sessionId: session.sessionId,
      documentId: session.documentId,
      startTime: session.startTime,
      endTime: DateTime.now(),
      finalContent: session.currentContent,
      metadata: session.metadata,
    );
  }

  List<String> _extractContextFactors(WritingSession session, String currentText) {
    return [
      '文档ID: ${session.documentId}',
      '文本长度: ${currentText.length}',
      '写作时长: ${DateTime.now().difference(session.startTime).inMinutes}分钟',
    ];
  }

  /// 清理资源
  void dispose() {
    _eventController.close();
    _activeSessions.clear();
  }
}

// 支持类和枚举

/// 写作会话
class WritingSession {
  final String sessionId;
  final String documentId;
  final String? conversationId;
  final DateTime startTime;
  String initialContent;
  String currentContent;
  DateTime lastUpdateTime;
  int cursorPosition;
  final Map<String, dynamic>? metadata;
  ContextUnderstanding? contextUnderstanding;

  WritingSession({
    required this.sessionId,
    required this.documentId,
    this.conversationId,
    required this.startTime,
    required this.initialContent,
    String? currentContent,
    DateTime? lastUpdateTime,
    this.cursorPosition = 0,
    this.metadata,
  }) : currentContent = currentContent ?? initialContent,
       lastUpdateTime = lastUpdateTime ?? startTime;
}

/// 上下文理解
class ContextUnderstanding {
  final String currentTopic;
  final dynamic writingStyle;
  final ContentStructure contentStructure;
  final EmotionalTone emotionalTone;

  ContextUnderstanding({
    required this.currentTopic,
    required this.writingStyle,
    required this.contentStructure,
    required this.emotionalTone,
  });
}

/// 内容结构
class ContentStructure {
  final int totalParagraphs;
  final bool hasIntroduction;
  final bool hasConclusion;
  final bool hasBody;

  ContentStructure({
    required this.totalParagraphs,
    required this.hasIntroduction,
    required this.hasConclusion,
    required this.hasBody,
  });
}

/// 情感基调
enum EmotionalTone {
  positive,
  negative,
  neutral,
}

/// 写作预测
class WritingPrediction {
  final String type;
  final String content;
  final double confidence;
  final int position;

  WritingPrediction({
    required this.type,
    required this.content,
    required this.confidence,
    required this.position,
  });
}

/// 词预测
class WordPrediction extends WritingPrediction {
  WordPrediction({
    required String word,
    required double confidence,
    required int position,
  }) : super(
          type: 'word',
          content: word,
          confidence: confidence,
          position: position,
        );
}

/// 句子预测
class SentencePrediction extends WritingPrediction {
  SentencePrediction({
    required String suggestedCompletion,
    required double confidence,
    required int position,
  }) : super(
          type: 'sentence',
          content: suggestedCompletion,
          confidence: confidence,
          position: position,
        );
}

/// 段落结构预测
class ParagraphStructurePrediction extends WritingPrediction {
  final ParagraphAction prediction;
  final String reason;

  ParagraphStructurePrediction({
    required this.prediction,
    required double confidence,
    required this.reason,
  }) : super(
          type: 'paragraph_structure',
          content: prediction.toString(),
          confidence: confidence,
          position: 0,
        );
}

/// 段落动作
enum ParagraphAction {
  newParagraph,
  continueParagraph,
  mergeParagraphs,
}

/// 用户意图预测
class UserIntentPrediction {
  final WritingIntent primaryIntent;
  final List<WritingIntent> alternativeIntents;
  final List<SuggestedAction> suggestedActions;
  final double confidence;
  final List<String> contextFactors;

  UserIntentPrediction({
    required this.primaryIntent,
    required this.alternativeIntents,
    required this.suggestedActions,
    required this.confidence,
    required this.contextFactors,
  });
}

/// 写作意图
enum WritingIntent {
  continueWriting,
  askQuestion,
  createList,
  explainConcept,
  makeArgument,
  requestHelp,
}

/// 检测到的意图
class DetectedIntent {
  final WritingIntent intent;
  final double confidence;
  final List<String> evidence;

  DetectedIntent({
    required this.intent,
    required this.confidence,
    required this.evidence,
  });
}

/// 建议动作
class SuggestedAction {
  final ActionType type;
  final String description;
  final ActionPriority priority;

  SuggestedAction({
    required this.type,
    required this.description,
    required this.priority,
  });
}

/// 动作类型
enum ActionType {
  continueWriting,
  answerQuestion,
  formatAsList,
  provideExample,
  strengthenArgument,
  improveFlow,
}

/// 动作优先级
enum ActionPriority {
  high,
  medium,
  low,
}

/// 情境化提示
class ContextualPrompt {
  final String content;
  final List<String> focusAreas;
  final FormatSuggestions formatSuggestions;
  final String timingHint;
  final double confidence;

  ContextualPrompt({
    required this.content,
    required this.focusAreas,
    required this.formatSuggestions,
    required this.timingHint,
    required this.confidence,
  });
}

/// 格式建议
class FormatSuggestions {
  String paragraphBreaks = '适当';
  String listUsage = '无';
  String punctuationStyle = '标准';

  Map<String, dynamic> toJson() => {
    'paragraphBreaks': paragraphBreaks,
    'listUsage': listUsage,
    'punctuationStyle': punctuationStyle,
  };
}

/// 格式建议
class FormatSuggestion {
  final String currentFormat;
  final String suggestedFormat;
  final List<String> specificSuggestions;
  final ActionPriority priority;
  final double estimatedImpact;

  FormatSuggestion({
    required this.currentFormat,
    required this.suggestedFormat,
    required this.specificSuggestions,
    required this.priority,
    required this.estimatedImpact,
  });
}

/// 格式分析
class FormatAnalysis {
  final String currentFormat;
  final String suggestedFormat;
  final List<String> issues;
  final List<String> strengths;

  FormatAnalysis({
    required this.currentFormat,
    required this.suggestedFormat,
    required this.issues,
    required this.strengths,
  });
}

/// 写作模式
class WritingPattern {
  final double writingSpeed;
  final EditPattern editPattern;
  final PausePattern pausePattern;
  final double averageWordLength;

  WritingPattern({
    required this.writingSpeed,
    required this.editPattern,
    required this.pausePattern,
    required this.averageWordLength,
  });
}

/// 编辑模式
class EditPattern {
  final int deletions;
  final int insertions;
  final int replacements;

  EditPattern({
    required this.deletions,
    required this.insertions,
    required this.replacements,
  });
}

/// 暂停模式
class PausePattern {
  final int shortPauses;
  final int longPauses;
  final int thinkingPauses;

  PausePattern({
    required this.shortPauses,
    required this.longPauses,
    required this.thinkingPauses,
  });
}

/// 写作助手事件
class WritingAssistantEvent {
  final AssistantEventType type;
  final String sessionId;
  final Map<String, dynamic> data;

  WritingAssistantEvent({
    required this.type,
    required this.sessionId,
    required this.data,
  });
}

/// 助手事件类型
enum AssistantEventType {
  sessionStarted,
  sessionEnded,
  suggestionGenerated,
  predictionAvailable,
  contextUpdated,
}

/// 写作会话摘要
class WritingSessionSummary {
  final String sessionId;
  final String documentId;
  final DateTime startTime;
  final DateTime endTime;
  final String finalContent;
  final Map<String, dynamic>? metadata;

  WritingSessionSummary({
    required this.sessionId,
    required this.documentId,
    required this.startTime,
    required this.endTime,
    required this.finalContent,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'documentId': documentId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'finalContent': finalContent,
    'metadata': metadata,
  };
}

/// 上下文建议
class ContextualSuggestion {
  final SuggestionType type;
  final String title;
  final String description;
  final double confidence;
  final String? applicableText;

  ContextualSuggestion({
    required this.type,
    required this.title,
    required this.description,
    required this.confidence,
    this.applicableText,
  });

  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'title': title,
    'description': description,
    'confidence': confidence,
    'applicableText': applicableText,
  };
}

/// 建议类型
enum SuggestionType {
  style,
  vocabulary,
  grammar,
  structure,
  content,
}