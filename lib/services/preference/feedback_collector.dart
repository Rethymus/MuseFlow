import 'dart:async';
import '../../models/user_preference.dart';
import '../../utils/logger.dart';

/// 反馈收集器
/// 负责收集和管理用户对AI建议的反馈
class FeedbackCollector {
  static FeedbackCollector? _instance;
  final StreamController<UserFeedback> _feedbackController =
      StreamController.broadcast();
  final List<FeedbackListener> _listeners = [];

  FeedbackCollector._();

  /// 获取单例实例
  static FeedbackCollector get instance {
    _instance ??= FeedbackCollector._();
    return _instance!;
  }

  /// 反馈流
  Stream<UserFeedback> get feedbackStream => _feedbackController.stream;

  /// 记录用户接受修改
  Future<UserFeedback> recordAcceptance({
    required String originalText,
    required String modifiedText,
    required ModificationType modificationType,
    String? context,
    List<String>? topics,
    int? processingTime,
    double? aiConfidence,
  }) async {
    final feedback = UserFeedback.create(
      feedbackType: FeedbackType.accepted,
      modificationType: modificationType,
      originalText: originalText,
      modifiedText: modifiedText,
      finalText: modifiedText, // 接受后最终文本就是修改后的文本
      context: context,
      topics: topics ?? [],
      processingTime: processingTime,
      aiConfidence: aiConfidence,
    );

    await _emitFeedback(feedback);
    return feedback;
  }

  /// 记录用户拒绝修改
  Future<UserFeedback> recordRejection({
    required String originalText,
    required String modifiedText,
    required ModificationType modificationType,
    String? context,
    List<String>? topics,
    int? processingTime,
    double? aiConfidence,
  }) async {
    final feedback = UserFeedback.create(
      feedbackType: FeedbackType.rejected,
      modificationType: modificationType,
      originalText: originalText,
      modifiedText: modifiedText,
      finalText: originalText, // 拒绝后最终文本是原始文本
      context: context,
      topics: topics ?? [],
      processingTime: processingTime,
      aiConfidence: aiConfidence,
    );

    await _emitFeedback(feedback);
    return feedback;
  }

  /// 记录用户部分接受修改
  Future<UserFeedback> recordPartialAcceptance({
    required String originalText,
    required String modifiedText,
    required String finalText,
    required ModificationType modificationType,
    String? context,
    List<String>? topics,
    int? processingTime,
    double? aiConfidence,
  }) async {
    final feedback = UserFeedback.create(
      feedbackType: FeedbackType.partiallyAccepted,
      modificationType: modificationType,
      originalText: originalText,
      modifiedText: modifiedText,
      finalText: finalText, // 用户编辑后的文本
      context: context,
      topics: topics ?? [],
      processingTime: processingTime,
      aiConfidence: aiConfidence,
    );

    await _emitFeedback(feedback);
    return feedback;
  }

  /// 记录用户撤销修改
  Future<UserFeedback> recordReversion({
    required String originalText,
    required String modifiedText,
    required ModificationType modificationType,
    String? context,
    List<String>? topics,
  }) async {
    final feedback = UserFeedback.create(
      feedbackType: FeedbackType.reverted,
      modificationType: modificationType,
      originalText: originalText,
      modifiedText: modifiedText,
      finalText: originalText, // 撤销后回到原始文本
      context: context,
      topics: topics ?? [],
    );

    await _emitFeedback(feedback);
    return feedback;
  }

  /// 批量记录反馈
  Future<List<UserFeedback>> recordBatchFeedback(
      List<FeedbackData> feedbacks) async {
    final results = <UserFeedback>[];

    for (final feedbackData in feedbacks) {
      UserFeedback feedback;

      switch (feedbackData.feedbackType) {
        case FeedbackType.accepted:
          feedback = await recordAcceptance(
            originalText: feedbackData.originalText,
            modifiedText: feedbackData.modifiedText,
            modificationType: feedbackData.modificationType,
            context: feedbackData.context,
            topics: feedbackData.topics,
            processingTime: feedbackData.processingTime,
            aiConfidence: feedbackData.aiConfidence,
          );
          break;

        case FeedbackType.rejected:
          feedback = await recordRejection(
            originalText: feedbackData.originalText,
            modifiedText: feedbackData.modifiedText,
            modificationType: feedbackData.modificationType,
            context: feedbackData.context,
            topics: feedbackData.topics,
            processingTime: feedbackData.processingTime,
            aiConfidence: feedbackData.aiConfidence,
          );
          break;

        case FeedbackType.partiallyAccepted:
          feedback = await recordPartialAcceptance(
            originalText: feedbackData.originalText,
            modifiedText: feedbackData.modifiedText,
            finalText: feedbackData.finalText ?? feedbackData.originalText,
            modificationType: feedbackData.modificationType,
            context: feedbackData.context,
            topics: feedbackData.topics,
            processingTime: feedbackData.processingTime,
            aiConfidence: feedbackData.aiConfidence,
          );
          break;

        case FeedbackType.reverted:
          feedback = await recordReversion(
            originalText: feedbackData.originalText,
            modifiedText: feedbackData.modifiedText,
            modificationType: feedbackData.modificationType,
            context: feedbackData.context,
            topics: feedbackData.topics,
          );
          break;
      }

      results.add(feedback);
    }

    return results;
  }

  /// 添加反馈监听器
  void addListener(FeedbackListener listener) {
    _listeners.add(listener);
  }

  /// 移除反馈监听器
  void removeListener(FeedbackListener listener) {
    _listeners.remove(listener);
  }

  /// 发送反馈事件
  Future<void> _emitFeedback(UserFeedback feedback) async {
    // 通过流发送
    _feedbackController.add(feedback);

    // 通知监听器
    for (final listener in _listeners) {
      try {
        await listener.onFeedback(feedback);
      } catch (e) {
        // 忽略监听器错误，继续处理其他监听器
        Logger.error('Feedback listener error: $e', tag: 'FEEDBACK', error: e);
      }
    }
  }

  /// 自动检测修改类型
  ModificationType detectModificationType(String original, String modified) {
    // 计算文本差异
    final originalLength = original.length;
    final modifiedLength = modified.length;
    final lengthDiff = modifiedLength - originalLength;

    // 检查拼写修正
    if (_isSpellingCorrection(original, modified)) {
      return ModificationType.spelling;
    }

    // 检查语法修正
    if (_isGrammarCorrection(original, modified)) {
      return ModificationType.grammar;
    }

    // 检查词汇替换
    if (_isVocabularyReplacement(original, modified)) {
      return ModificationType.vocabulary;
    }

    // 根据长度变化判断扩展或精简
    if (lengthDiff > 50) {
      return ModificationType.expansion;
    } else if (lengthDiff < -50) {
      return ModificationType.simplification;
    }

    // 检查结构变化
    if (_isStructureChange(original, modified)) {
      return ModificationType.structure;
    }

    // 默认为风格改进
    return ModificationType.style;
  }

  /// 判断是否为拼写修正
  bool _isSpellingCorrection(String original, String modified) {
    // 简单判断：字符差异小，但词语相同
    final originalWords = original.split(RegExp(r'\s+'));
    final modifiedWords = modified.split(RegExp(r'\s+'));

    if (originalWords.length != modifiedWords.length) return false;

    int diffCount = 0;
    for (int i = 0; i < originalWords.length; i++) {
      if (originalWords[i] != modifiedWords[i]) {
        diffCount++;
      }
    }

    // 差异很小且单词数相同
    return diffCount <= 2 && diffCount > 0;
  }

  /// 判断是否为语法修正
  bool _isGrammarCorrection(String original, String modified) {
    // 检查常见的语法修正模式
    final grammarPatterns = [
      RegExp(r'\s+,\s*'), // 标点符号空格修正
      RegExp(r'\s+\.'), // 句号前空格移除
      RegExp(r'[,.]\s*[a-z]'), // 小写字母开头修正
    ];

    for (final pattern in grammarPatterns) {
      if (pattern.hasMatch(original) && !pattern.hasMatch(modified)) {
        return true;
      }
    }

    return false;
  }

  /// 判断是否为词汇替换
  bool _isVocabularyReplacement(String original, String modified) {
    // 检查是否有词汇被替换
    final originalWords = original.toLowerCase().split(RegExp(r'\s+'));
    final modifiedWords = modified.toLowerCase().split(RegExp(r'\s+'));

    if (originalWords.length != modifiedWords.length) return false;

    int diffCount = 0;
    for (int i = 0; i < originalWords.length; i++) {
      if (originalWords[i] != modifiedWords[i]) {
        diffCount++;
      }
    }

    // 有词汇差异
    return diffCount > 0 && diffCount <= originalWords.length ~/ 3;
  }

  /// 判断是否为结构变化
  bool _isStructureChange(String original, String modified) {
    // 检查段落或句子结构的变化
    final originalSentences = original.split(RegExp(r'[.!?]\s+'));
    final modifiedSentences = modified.split(RegExp(r'[.!?]\s+'));

    // 句子数量发生显著变化
    return (originalSentences.length - modifiedSentences.length).abs() > 2;
  }

  /// 释放资源
  void dispose() {
    _feedbackController.close();
    _listeners.clear();
  }
}

/// 反馈监听器接口
abstract class FeedbackListener {
  Future<void> onFeedback(UserFeedback feedback);
}

/// 反馈数据传输对象
class FeedbackData {
  final FeedbackType feedbackType;
  final ModificationType modificationType;
  final String originalText;
  final String modifiedText;
  final String? finalText;
  final String? context;
  final List<String>? topics;
  final int? processingTime;
  final double? aiConfidence;

  FeedbackData({
    required this.feedbackType,
    required this.modificationType,
    required this.originalText,
    required this.modifiedText,
    this.finalText,
    this.context,
    this.topics,
    this.processingTime,
    this.aiConfidence,
  });
}

/// 自动反馈收集器
/// 自动从编辑器行为中收集反馈
class AutoFeedbackCollector {
  final FeedbackCollector _collector;
  final List<EditSession> _sessions = [];

  AutoFeedbackCollector({FeedbackCollector? collector})
      : _collector = collector ?? FeedbackCollector.instance;

  /// 开始编辑会话
  void startSession(String sessionId, String initialText) {
    _sessions.add(EditSession(
      id: sessionId,
      startTime: DateTime.now(),
      initialText: initialText,
    ));
  }

  /// 记录AI建议
  void recordAISuggestion(String sessionId, String suggestion) {
    final session = _sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => throw ArgumentError('Session not found: $sessionId'),
    );

    session.aiSuggestions.add(suggestion);
  }

  /// 记录用户接受
  Future<void> recordUserAccept(
      String sessionId, String suggestion, String result) async {
    final session = _sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => throw ArgumentError('Session not found: $sessionId'),
    );

    // 检测修改类型
    final modificationType = _collector.detectModificationType(
      session.initialText,
      result,
    );

    // 提取主题
    final topics = _extractTopics(result);

    await _collector.recordAcceptance(
      originalText: session.initialText,
      modifiedText: suggestion,
      finalText: result,
      modificationType: modificationType,
      context: session.id,
      topics: topics,
      processingTime:
          DateTime.now().difference(session.startTime).inMilliseconds,
    );
  }

  /// 记录用户拒绝
  Future<void> recordUserReject(String sessionId, String suggestion) async {
    final session = _sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => throw ArgumentError('Session not found: $sessionId'),
    );

    // 检测修改类型
    final modificationType = _collector.detectModificationType(
      session.initialText,
      suggestion,
    );

    await _collector.recordRejection(
      originalText: session.initialText,
      modifiedText: suggestion,
      modificationType: modificationType,
      context: session.id,
      topics: _extractTopics(session.initialText),
    );
  }

  /// 结束编辑会话
  void endSession(String sessionId) {
    _sessions.removeWhere((s) => s.id == sessionId);
  }

  /// 提取主题关键词
  List<String> _extractTopics(String text) {
    // 简单的关键词提取
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'));

    // 过滤停用词和短词
    final stopWords = {
      '的',
      '是',
      '在',
      '和',
      '或',
      '但',
      '与',
      '及',
      '等',
      '很',
      '也',
      'the',
      'is',
      'and',
      'or',
      'but',
      'with',
      'very',
      'also',
      'this',
      'that',
    };

    return words
        .where((word) => word.length > 2 && !stopWords.contains(word))
        .toSet()
        .toList()
      ..shuffle()
      ..take(5);
  }
}

/// 编辑会话
class EditSession {
  final String id;
  final DateTime startTime;
  final String initialText;
  final List<String> aiSuggestions = [];

  EditSession({
    required this.id,
    required this.startTime,
    required this.initialText,
  });
}
