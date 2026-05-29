import '../../utils/logger.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../utils/natural_language_processor.dart';
import '../../services/intent_analyzer.dart';
import '../../models/intent_confirmation.dart';
import '../../config/app_constants.dart';
import '../../services/ai/ai_service.dart';
import '../../services/ai/adapters/openai_adapter.dart';
import '../../services/ai/adapters/claude_adapter.dart';
import '../../models/ai_config.dart';
import '../../models/ai_message.dart';
import '../../models/ai_response.dart';
import '../../services/ai/ai_adapter.dart';

/// AI操作处理器
/// 负责处理所有AI相关的操作（润色、扩写、大纲生成等）
class AIActionHandler {
  // 回调函数
  final Function(String action, String result) onResult;
  final Function(String error) onError;

  // 意图确认回调
  final Function(IntentConfirmation)? onIntentConfirmation;

  // 自然语言处理器（用于去除AI味道）
  late final NaturalLanguageProcessor _naturalLanguageProcessor;

  // 意图分析器
  late final IntentAnalyzer _intentAnalyzer;

  // AI服务
  final AIService? _aiService;

  // 当前AI配置
  AIConfig? _currentConfig;

  // 流式响应控制器
  final StreamController<String> _responseStreamController =
      StreamController<String>.broadcast();

  // 取消令牌
  bool _isCancelled = false;

  // 操作队列
  final List<_AIOperation> _operationQueue = [];
  bool _isProcessing = false;

  // 超时设置
  static const Duration _defaultTimeout = AppConstants.aiTimeout;

  // 配置
  final bool enableIntentConfirmation;

  AIActionHandler({
    required this.onResult,
    required this.onError,
    this.onIntentConfirmation,
    NaturalLanguageConfig? nlConfig,
    IntentAnalyzerConfig? intentConfig,
    this.enableIntentConfirmation = true,
    AIService? aiService,
  }) : _aiService = aiService {
    _naturalLanguageProcessor = NaturalLanguageProcessor(
      config: nlConfig ?? NaturalLanguageConfig.defaultConfig(),
    );
    _intentAnalyzer =
        IntentAnalyzer(config: intentConfig ?? const IntentAnalyzerConfig());
    _initializeAIService();
  }

  /// 初始化AI服务
  Future<void> _initializeAIService() async {
    if (_aiService == null) {
      return;
    }

    try {
      // 获取活跃配置
      _currentConfig = await _aiService!.getActiveConfig();
      if (kDebugMode && _currentConfig != null) {
        Logger.debug('AI服务初始化成功，使用模型: ${_currentConfig!.model}');
      }
    } catch (e) {
      if (kDebugMode) {
        Logger.debug('AI服务初始化失败: $e');
      }
    }
  }

  /// 设置AI配置
  Future<void> setAIConfig(AIConfig config) async {
    _currentConfig = config;
    if (_aiService != null) {
      await _aiService!.setActiveConfig(config.id);
    }
  }

  /// 获取响应流
  Stream<String> get responseStream => _responseStreamController.stream;

  /// AI润色
  Future<void> polish({
    required String text,
    String context = '',
    bool skipConfirmation = false,
  }) async {
    if (text.trim().isEmpty) {
      onError('请选择要润色的文本');
      return;
    }

    // 生成意图确认
    final intent = _intentAnalyzer.analyzeRequest(
      actionType: AIActionType.polish,
      originalText: text,
      additionalParams: {'context': context},
    );

    if (enableIntentConfirmation && !skipConfirmation) {
      onIntentConfirmation?.call(intent);
      return;
    }

    final operation = _AIOperation(
      type: 'polish',
      text: text,
      context: context,
      prompt: _buildPolishPrompt(text, context),
      intent: intent,
    );

    await _enqueueOperation(operation);
  }

  /// AI扩写
  Future<void> expand({
    required String text,
    String context = '',
    int? targetLength,
    bool skipConfirmation = false,
  }) async {
    if (text.trim().isEmpty) {
      onError('请选择要扩写的文本');
      return;
    }

    // 生成意图确认
    final intent = _intentAnalyzer.analyzeRequest(
      actionType: AIActionType.expand,
      originalText: text,
      additionalParams: {'context': context, 'targetLength': targetLength},
    );

    if (enableIntentConfirmation && !skipConfirmation) {
      onIntentConfirmation?.call(intent);
      return;
    }

    final operation = _AIOperation(
      type: 'expand',
      text: text,
      context: context,
      prompt: _buildExpandPrompt(text, context),
      intent: intent,
    );

    await _enqueueOperation(operation);
  }

  /// 生成大纲
  Future<void> outline({
    required String text,
    int? maxItems,
    bool skipConfirmation = false,
  }) async {
    if (text.trim().isEmpty) {
      onError('请输入要生成大纲的文本');
      return;
    }

    // 生成意图确认
    final intent = _intentAnalyzer.analyzeRequest(
      actionType: AIActionType.outline,
      originalText: text,
      additionalParams: {'maxItems': maxItems},
    );

    if (enableIntentConfirmation && !skipConfirmation) {
      onIntentConfirmation?.call(intent);
      return;
    }

    final operation = _AIOperation(
      type: 'outline',
      text: text,
      context: '',
      prompt: _buildOutlinePrompt(text),
      intent: intent,
    );

    await _enqueueOperation(operation);
  }

  /// 摘要生成
  Future<void> summarize({
    required String text,
    int maxLength = 100,
    bool skipConfirmation = false,
  }) async {
    if (text.trim().isEmpty) {
      onError('请选择要摘要的文本');
      return;
    }

    // 生成意图确认
    final intent = _intentAnalyzer.analyzeRequest(
      actionType: AIActionType.summarize,
      originalText: text,
      additionalParams: {'maxLength': maxLength},
    );

    if (enableIntentConfirmation && !skipConfirmation) {
      onIntentConfirmation?.call(intent);
      return;
    }

    final operation = _AIOperation(
      type: 'summarize',
      text: text,
      context: '',
      prompt: _buildSummarizePrompt(text, maxLength),
      intent: intent,
    );

    await _enqueueOperation(operation);
  }

  /// 风格转换
  Future<void> changeStyle({
    required String text,
    required String targetStyle,
  }) async {
    final validStyles = [
      '正式',
      '口语',
      '学术',
      '文艺',
      '简洁',
    ];

    if (!validStyles.contains(targetStyle)) {
      onError('无效的风格选项');
      return;
    }

    final operation = _AIOperation(
      type: 'change_style',
      text: text,
      context: '',
      prompt: _buildStyleChangePrompt(text, targetStyle),
    );

    await _enqueueOperation(operation);
  }

  /// 查找替换（智能替换）
  Future<void> smartReplace({
    required String text,
    required String findText,
    required String replaceWith,
  }) async {
    if (findText.trim().isEmpty) {
      onError('请输入要查找的文本');
      return;
    }

    final operation = _AIOperation(
      type: 'smart_replace',
      text: text,
      context: '',
      additionalData: {
        'find': findText,
        'replace': replaceWith,
      },
      prompt: _buildSmartReplacePrompt(text, findText, replaceWith),
    );

    await _enqueueOperation(operation);
  }

  // 将操作加入队列
  Future<void> _enqueueOperation(_AIOperation operation) async {
    _operationQueue.add(operation);
    await _processQueue();
  }

  // 处理操作队列
  Future<void> _processQueue() async {
    if (_isProcessing || _operationQueue.isEmpty) {
      return;
    }

    _isProcessing = true;

    while (_operationQueue.isNotEmpty) {
      final operation = _operationQueue.removeAt(0);
      await _executeOperation(operation);
    }

    _isProcessing = false;
  }

  // 执行单个操作
  Future<void> _executeOperation(_AIOperation operation) async {
    _isCancelled = false;

    try {
      String result;

      // 检查是否配置了AI服务
      if (_aiService != null && _currentConfig != null) {
        // 使用真实的AI服务
        result = await _callAIService(operation);
      } else {
        // 回退到模拟调用（用于开发和测试）
        if (kDebugMode) {
          Logger.debug('使用模拟AI调用（未配置AI服务）');
        }
        result = await _mockAICall(operation);
      }

      // 检查是否被取消
      if (_isCancelled) {
        return;
      }

      // 应用自然语言处理，去除AI味道
      if (_shouldApplyNaturalLanguageProcessing(operation.type)) {
        result = _naturalLanguageProcessor.process(result);

        // 记录处理统计（用于调试和优化）
        if (kDebugMode) {
          final stats = _naturalLanguageProcessor.getStatistics();
          Logger.debug('自然语言处理统计: ${stats.toJson()}');
        }
      }

      onResult(operation.type, result);
    } catch (e) {
      if (_isCancelled) {
        // 如果是取消操作，不报错
        return;
      }
      onError('AI操作失败: ${e.toString()}');
    }
  }

  // 判断是否需要应用自然语言处理
  bool _shouldApplyNaturalLanguageProcessing(String operationType) {
    // 对以下操作类型应用自然语言处理
    const treatableTypes = {
      'polish', // 润色
      'expand', // 扩写
      'summarize', // 摘要
      'change_style', // 风格转换
    };

    return treatableTypes.contains(operationType);
  }

  /// 调用AI服务
  Future<String> _callAIService(_AIOperation operation) async {
    if (_aiService == null || _currentConfig == null) {
      throw StateError('AI服务未配置');
    }

    try {
      // 构建消息列表
      final messages = [
        AIMessage.system(
          id: 'system',
          content: _buildSystemPrompt(operation.type),
        ),
        AIMessage.user(
          id: 'user',
          content: operation.prompt,
        ),
      ];

      // 检查是否需要流式响应
      if (_shouldUseStreamResponse()) {
        return await _executeStreamRequest(messages, operation);
      } else {
        return await _executeSimpleRequest(messages, operation);
      }
    } catch (e) {
      throw _handleAIError(e);
    }
  }

  /// 构建系统提示词
  String _buildSystemPrompt(String operationType) {
    switch (operationType) {
      case 'polish':
        return '你是一个专业的文本编辑助手，擅长润色和优化文本表达。';
      case 'expand':
        return '你是一个创意写作助手，擅长扩展和丰富文本内容。';
      case 'outline':
        return '你是一个结构化分析专家，擅长提取和组织文本要点。';
      case 'summarize':
        return '你是一个摘要专家，擅长提炼文本核心信息。';
      case 'change_style':
        return '你是一个风格转换专家，擅长调整文本的表达风格。';
      case 'smart_replace':
        return '你是一个文本替换专家，擅长进行智能的文本替换和调整。';
      default:
        return '你是一个专业的写作助手。';
    }
  }

  /// 判断是否使用流式响应
  bool _shouldUseStreamResponse() {
    // 根据配置决定是否使用流式响应
    return _currentConfig?.model == 'gpt-4' ||
        _currentConfig?.model == 'gpt-4-turbo' ||
        _currentConfig?.model?.startsWith('claude-3') == true;
  }

  /// 执行流式请求
  Future<String> _executeStreamRequest(
    List<AIMessage> messages,
    _AIOperation operation,
  ) async {
    final buffer = StringBuffer();

    await for (final chunk in _aiService!.sendMessageStream(
      messages,
      config: _currentConfig,
      onChunk: (chunk) {
        if (!_isCancelled) {
          buffer.write(chunk.content);
          _responseStreamController.add(chunk.content);
        }
      },
    )) {
      if (_isCancelled) {
        break;
      }
    }

    return buffer.toString();
  }

  /// 执行简单请求
  Future<String> _executeSimpleRequest(
    List<AIMessage> messages,
    _AIOperation operation,
  ) async {
    final response = await _aiService!.sendMessage(
      messages,
      config: _currentConfig,
    );

    return response.content;
  }

  /// 处理AI错误
  Exception _handleAIError(dynamic error) {
    if (error is ApiKeyException) {
      return Exception('API密钥无效，请检查配置');
    } else if (error is RateLimitException) {
      return Exception('请求频率过高，请稍后再试');
    } else if (error is QuotaException) {
      return Exception('API配额已用完，请充值后重试');
    } else if (error is AITimeoutException) {
      return Exception('请求超时，请检查网络连接');
    } else if (error is NetworkException) {
      return Exception('网络连接失败，请检查网络设置');
    } else if (error is ContentFilterException) {
      return Exception('内容被过滤，请调整输入内容');
    } else {
      return Exception('AI服务错误: ${error.toString()}');
    }
  }

  // 模拟AI调用（开发阶段用）
  Future<String> _mockAICall(_AIOperation operation) async {
    // 模拟网络延迟
    await Future.delayed(AppConstants.extraLongDelay);

    switch (operation.type) {
      case 'polish':
        return _mockPolishResult(operation.text);
      case 'expand':
        return _mockExpandResult(operation.text);
      case 'outline':
        return _mockOutlineResult(operation.text);
      case 'summarize':
        return _mockSummarizeResult(operation.text);
      case 'change_style':
        return _mockStyleChangeResult(
            operation.text, operation.additionalData?['style'] ?? '正式');
      case 'smart_replace':
        final find = operation.additionalData?['find'] ?? '';
        final replace = operation.additionalData?['replace'] ?? '';
        return _mockSmartReplaceResult(operation.text, find, replace);
      default:
        return operation.text;
    }
  }

  // 构建润色提示词
  String _buildPolishPrompt(String text, String context) {
    final buffer = StringBuffer();

    buffer.writeln('请对以下文本进行润色，使其更加通顺、准确、优雅：');
    buffer.writeln();

    if (context.isNotEmpty) {
      buffer.writeln('【上下文参考】');
      buffer.writeln(context);
      buffer.writeln();
    }

    buffer.writeln('【待润色文本】');
    buffer.writeln(text);
    buffer.writeln();

    buffer.writeln('【要求】');
    buffer.writeln('1. 保持原意不变');
    buffer.writeln('2. 使表达更加简洁流畅');
    buffer.writeln('3. 修正语法和用词错误');
    buffer.writeln('4. 只返回润色后的文本，不要解释');

    return buffer.toString();
  }

  // 构建扩写提示词
  String _buildExpandPrompt(String text, String context) {
    final buffer = StringBuffer();

    buffer.writeln('请对以下文本进行扩写，丰富内容和表达：');
    buffer.writeln();

    if (context.isNotEmpty) {
      buffer.writeln('【上下文参考】');
      buffer.writeln(context);
      buffer.writeln();
    }

    buffer.writeln('【待扩写文本】');
    buffer.writeln(text);
    buffer.writeln();

    buffer.writeln('【要求】');
    buffer.writeln('1. 保持原文核心观点');
    buffer.writeln('2. 添加适当的细节和例子');
    buffer.writeln('3. 使内容更加丰富完整');
    buffer.writeln('4. 扩写内容要自然衔接');

    return buffer.toString();
  }

  // 构建大纲提示词
  String _buildOutlinePrompt(String text) {
    final buffer = StringBuffer();

    buffer.writeln('请为以下文本生成结构化大纲：');
    buffer.writeln();
    buffer.writeln('【文本内容】');
    buffer.writeln(text);
    buffer.writeln();
    buffer.writeln('【要求】');
    buffer.writeln('1. 提取主要观点和论据');
    buffer.writeln('2. 按逻辑层次组织');
    buffer.writeln('3. 使用数字编号');
    buffer.writeln('4. 简洁明了');

    return buffer.toString();
  }

  // 构建摘要提示词
  String _buildSummarizePrompt(String text, int maxLength) {
    final buffer = StringBuffer();

    buffer.writeln('请为以下文本生成摘要（最多$maxLength字）：');
    buffer.writeln();
    buffer.writeln(text);
    buffer.writeln();
    buffer.writeln('【要求】');
    buffer.writeln('1. 提取核心信息');
    buffer.writeln('2. 保持逻辑连贯');
    buffer.writeln('3. 简洁明确');

    return buffer.toString();
  }

  // 构建风格转换提示词
  String _buildStyleChangePrompt(String text, String targetStyle) {
    final buffer = StringBuffer();

    buffer.writeln('请将以下文本转换为目标风格：$targetStyle');
    buffer.writeln();
    buffer.writeln(text);
    buffer.writeln();
    buffer.writeln('【要求】');
    buffer.writeln('1. 保持核心信息不变');
    buffer.writeln('2. 调整表达方式以匹配目标风格');
    buffer.writeln('3. 确保转换自然不生硬');

    return buffer.toString();
  }

  // 构建智能替换提示词
  String _buildSmartReplacePrompt(
      String text, String findText, String replaceWith) {
    final buffer = StringBuffer();

    buffer.writeln('请进行智能文本替换：');
    buffer.writeln();
    buffer.writeln('【原文本】');
    buffer.writeln(text);
    buffer.writeln();
    buffer.writeln('【查找】$findText');
    buffer.writeln('【替换为】$replaceWith');
    buffer.writeln();
    buffer.writeln('【要求】');
    buffer.writeln('1. 保持文本连贯性');
    buffer.writeln('2. 自动调整时态和语态');
    buffer.writeln('3. 确保替换后的表达自然');

    return buffer.toString();
  }

  // 模拟润色结果
  String _mockPolishResult(String text) {
    // 模拟AI润色结果，包含一些AI常用的表达模式
    return '首先，${text}。此外，这个表达也值得进一步优化。总之，通过润色可以使文本更加通顺。然而，需要注意保持原意不变。因此，建议在使用时根据具体语境进行调整。';
  }

  // 模拟扩写结果
  String _mockExpandResult(String text) {
    return '${text}。首先，从理论角度来看，这个观点具有重要意义。其次，实践证明，通过深入分析可以发现更多细节。此外，值得注意的是，这个概念在多个领域都有广泛应用。最后，综上所述，我们可以得出这样的结论。';
  }

  // 模拟大纲结果
  String _mockOutlineResult(String text) {
    final sentences = text.split(RegExp(r'[。！？\n]'));
    final outline = StringBuffer();

    for (int i = 0; i < sentences.length && i < 10; i++) {
      final sentence = sentences[i].trim();
      if (sentence.isNotEmpty) {
        outline.writeln('${i + 1}. $sentence');
      }
    }

    return outline.toString().trim();
  }

  // 模拟摘要结果
  String _mockSummarizeResult(String text) {
    final sentences = text.split(RegExp(r'[。！？]'));
    if (sentences.isEmpty) return text;

    final firstSentence = sentences.first.trim();
    return '首先，${firstSentence}。此外，通过分析可以看出主要内容。总之，这是一个值得关注的要点。';
  }

  // 模拟风格转换结果
  String _mockStyleChangeResult(String text, String style) {
    // 模拟风格转换，包含AI常用的表达
    return '首先，${text}。然而，需要注意的是，这是$style风格的表达。此外，通过这种转换可以使文本更符合目标风格。因此，建议在使用时根据具体需求进行适当调整。';
  }

  // 模拟智能替换结果
  String _mockSmartReplaceResult(String text, String find, String replace) {
    return text.replaceAll(find, replace);
  }

  /// 取消所有待处理操作
  void cancelAll() {
    _isCancelled = true;
    _operationQueue.clear();
    _isProcessing = false;

    // 通知流式响应监听者
    _responseStreamController.add('[CANCELLED]');
  }

  /// 获取队列状态
  bool get isProcessing => _isProcessing;
  int get pendingOperations => _operationQueue.length;

  /// 执行已确认的意图
  Future<void> executeConfirmedIntent(
      IntentConfirmation confirmedIntent) async {
    // 记录反馈
    _intentAnalyzer.recordFeedback(
      IntentConfirmationFeedback(
        intentId: confirmedIntent.id,
        confirmed: true,
        adjustedDescription: confirmedIntent.description,
        adjustedParameters: confirmedIntent.parameters,
      ),
    );

    // 根据意图类型执行相应的操作
    switch (confirmedIntent.actionType) {
      case AIActionType.polish:
        await polish(
          text: confirmedIntent.originalText,
          context: confirmedIntent.parameters['context']?.toString() ?? '',
          skipConfirmation: true,
        );
        break;
      case AIActionType.expand:
        await expand(
          text: confirmedIntent.originalText,
          context: confirmedIntent.parameters['context']?.toString() ?? '',
          targetLength: confirmedIntent.parameters['target_length'] as int?,
          skipConfirmation: true,
        );
        break;
      case AIActionType.outline:
        await outline(
          text: confirmedIntent.originalText,
          maxItems: confirmedIntent.parameters['max_items'] as int?,
          skipConfirmation: true,
        );
        break;
      case AIActionType.summarize:
        await summarize(
          text: confirmedIntent.originalText,
          maxLength: confirmedIntent.parameters['max_length'] as int? ?? 100,
          skipConfirmation: true,
        );
        break;
      case AIActionType.changeStyle:
        await changeStyle(
          text: confirmedIntent.originalText,
          targetStyle:
              confirmedIntent.parameters['target_style']?.toString() ?? '正式',
        );
        break;
      case AIActionType.smartReplace:
        await smartReplace(
          text: confirmedIntent.originalText,
          findText: confirmedIntent.parameters['find_text']?.toString() ?? '',
          replaceWith:
              confirmedIntent.parameters['replace_with']?.toString() ?? '',
        );
        break;
    }
  }

  /// 拒绝意图
  void rejectIntent(IntentConfirmation intent) {
    // 记录反馈
    _intentAnalyzer.recordFeedback(
      IntentConfirmationFeedback(
        intentId: intent.id,
        confirmed: false,
      ),
    );
  }

  /// 获取意图分析统计
  Map<String, dynamic> getIntentStatistics() {
    return _intentAnalyzer.getFeedbackStatistics();
  }

  /// 更新自然语言处理配置
  void updateNaturalLanguageConfig(NaturalLanguageConfig config) {
    _naturalLanguageProcessor = NaturalLanguageProcessor(config: config);
  }

  /// 获取自然语言处理统计
  ProcessingStatistics getNaturalLanguageStats() {
    return _naturalLanguageProcessor.getStatistics();
  }

  /// 直接应用自然语言处理
  String applyNaturalLanguageProcessing(String text) {
    return _naturalLanguageProcessor.process(text);
  }

  /// A/B测试不同的自然语言处理配置
  Map<String, String> compareNaturalLanguageConfigs(
    String text, {
    NaturalLanguageConfig? configA,
    NaturalLanguageConfig? configB,
  }) {
    final tester = NaturalLanguageABTester(
      configA: configA ?? NaturalLanguageConfig.defaultConfig(),
      configB: configB ?? NaturalLanguageConfig.minimalConfig(),
    );

    return tester.compare(text);
  }

  void dispose() {
    cancelAll();
    _responseStreamController.close();
  }
}

// AI操作数据结构
class _AIOperation {
  final String type;
  final String text;
  final String context;
  final String prompt;
  final Map<String, dynamic>? additionalData;
  final IntentConfirmation? intent;

  _AIOperation({
    required this.type,
    required this.text,
    required this.context,
    required this.prompt,
    this.additionalData,
    this.intent,
  });
}
