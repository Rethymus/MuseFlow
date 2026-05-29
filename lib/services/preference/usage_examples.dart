import '../../config/app_constants.dart';
import '../../models/ai_message.dart';
import '../../models/user_preference.dart';
import '../../utils/logger.dart';
import 'package:flutter/material.dart';
import 'user_preference_manager.dart';
import 'feedback_collector.dart';
import 'writing_analyzer.dart';
import '../ai/personalized_ai_service.dart';

/// 用户偏好学习系统使用示例
///
/// 这个文件展示了如何使用用户偏好学习系统的主要功能

class PreferenceLearningExample {
  /// 示例1：初始化系统
  static Future<void> initializeSystemExample() async {
    try {
      // 1. 初始化用户偏好管理器
      final preferenceManager = await UserPreferenceManager.initialize();

      // 2. 初始化个性化AI服务
      final personalizedAI = await PersonalizedAIService.initialize(
        preferenceManager: preferenceManager,
      );

      Logger.debug('✅ 用户偏好学习系统初始化成功');

      // 3. 检查学习状态
      final stats = preferenceManager.getLearningStats();
      Logger.debug('学习数据点: ${stats['learningDataPoints']}');
      Logger.debug('置信度: ${stats['confidenceScore']}');
    } catch (e) {
      Logger.debug('❌ 初始化失败: $e');
    }
  }

  /// 示例2：记录用户反馈
  static Future<void> recordFeedbackExample() async {
    try {
      final feedbackCollector = FeedbackCollector.instance;
      final preferenceManager = await UserPreferenceManager.initialize();

      // 模拟用户接受AI建议的场景
      const originalText = '这个很好';
      const suggestedText = '这个产品非常好用';
      const finalText = '这个产品非常好用'; // 用户接受了建议

      // 记录接受反馈
      final feedback = await feedbackCollector.recordAcceptance(
        originalText: originalText,
        modifiedText: suggestedText,
        modificationType: ModificationType.style,
        context: '产品评价',
        topics: ['产品', '评价', '质量'],
        processingTime: 1500,
        aiConfidence: 0.85,
      );

      // 添加到偏好管理器进行学习
      await preferenceManager.addFeedback(feedback);

      Logger.debug('✅ 反馈记录成功: ${feedback.feedbackType}');
    } catch (e) {
      Logger.debug('❌ 反馈记录失败: $e');
    }
  }

  /// 示例3：分析用户写作
  static Future<void> analyzeWritingExample() async {
    try {
      final preferenceManager = await UserPreferenceManager.initialize();

      // 分析用户的写作样本
      const userText = '''
        在当今这个快速发展的时代，我们需要不断地学习和进步。
        人工智能技术正在改变我们的工作方式，为我们带来更多的可能性。
        我们应该积极拥抱这些变化，不断提升自己的技能。
      ''';

      // 分析写作风格
      final analysis = await preferenceManager.analyzeWriting(userText);

      Logger.debug('📝 写作分析结果:');
      Logger.debug('语言风格: ${analysis.detectedLanguageStyle}');
      Logger.debug('详细程度: ${analysis.detectedDetailLevel}');
      Logger.debug('段落结构: ${analysis.detectedParagraphStructure}');
      Logger.debug('句式复杂度: ${analysis.detectedSentenceComplexity}');
      Logger.debug('关键词: ${analysis.keywords.join(', ')}');
      Logger.debug('分析置信度: ${analysis.confidence}');
    } catch (e) {
      Logger.debug('❌ 写作分析失败: $e');
    }
  }

  /// 示例4：使用个性化AI服务
  static Future<void> personalizedAIExample() async {
    try {
      final personalizedAI = await PersonalizedAIService.initialize();

      // 构建消息列表
      final messages = [
        AIMessage(
          role: 'user',
          content: '请帮我改进这段文字：这个很好用',
        ),
      ];

      // 发送个性化消息
      final response = await personalizedAI.sendPersonalizedMessage(
        messages,
        applyPreferences: true,
      );

      Logger.debug('🤖 AI回复: ${response.content}');

      // 检查是否应用了个性化
      if (response.metadata?['personalized'] == true) {
        Logger.debug('✨ 已应用用户个性化偏好');
      }
    } catch (e) {
      Logger.debug('❌ AI服务调用失败: $e');
    }
  }

  /// 示例5：记录编辑会话反馈
  static Future<void> editSessionExample() async {
    try {
      final autoCollector = AutoFeedbackCollector();
      final preferenceManager = await UserPreferenceManager.initialize();

      // 开始编辑会话
      const sessionId = 'session_001';
      const initialText = '这个很好用';

      autoCollector.startSession(sessionId, initialText);

      // AI给出建议
      const aiSuggestion = '这个产品非常好用';
      autoCollector.recordAISuggestion(sessionId, aiSuggestion);

      // 用户接受建议
      await autoCollector.recordUserAccept(
        sessionId,
        aiSuggestion,
        aiSuggestion, // 用户完全接受
      );

      Logger.debug('✅ 编辑会话反馈记录成功');

      // 结束会话
      autoCollector.endSession(sessionId);
    } catch (e) {
      Logger.debug('❌ 编辑会话记录失败: $e');
    }
  }

  /// 示例6：获取个性化建议
  static Future<void> getPersonalizationExample() async {
    try {
      final personalizedAI = await PersonalizedAIService.initialize();

      // 获取个性化建议
      const text = '帮我写一段产品评价';
      final suggestions = personalizedAI.getPersonalizationSuggestions(text);

      Logger.debug('💡 个性化建议:');
      suggestions.forEach((key, value) {
        Logger.debug('$key: $value');
      });
    } catch (e) {
      Logger.debug('❌ 获取建议失败: $e');
    }
  }

  /// 示例7：隐私管理
  static Future<void> privacyManagementExample() async {
    try {
      final preferenceManager = await UserPreferenceManager.initialize();

      // 获取隐私报告
      final privacyReport = await preferenceManager.getPrivacyReport();

      Logger.debug('🔒 隐私报告:');
      Logger.debug('数据本地存储: ${privacyReport['dataStoredLocally']}');
      Logger.debug('数据加密存储: ${privacyReport['dataStoredInSecureStorage']}');
      Logger.debug('反馈记录数: ${privacyReport['feedbackHistorySize']}');
      Logger.debug('分析记录数: ${privacyReport['writingAnalyticsSize']}');
      Logger.debug('数据保留天数: ${privacyReport['dataRetentionDays']}');

      // 清除过期数据
      await preferenceManager.clearExpiredData();
      Logger.debug('✅ 过期数据已清除');
    } catch (e) {
      Logger.debug('❌ 隐私管理失败: $e');
    }
  }

  /// 示例8：配置管理
  static Future<void> configManagementExample() async {
    try {
      final preferenceManager = await UserPreferenceManager.initialize();

      // 获取当前配置
      final currentConfig = preferenceManager.config;
      Logger.debug('📋 当前配置:');
      Logger.debug('启用学习: ${currentConfig.enabled}');
      Logger.debug('最小学习样本: ${currentConfig.minLearningSamples}');
      Logger.debug('学习速率: ${currentConfig.learningRate}');
      Logger.debug('自动应用: ${currentConfig.autoApply}');

      // 更新配置
      final updatedConfig = currentConfig.copyWith(
        enabled: true,
        autoApply: true,
        learningRate: 0.15,
      );

      await preferenceManager.updateConfig(updatedConfig);
      Logger.debug('✅ 配置已更新');
    } catch (e) {
      Logger.debug('❌ 配置管理失败: $e');
    }
  }

  /// 示例9：重置偏好数据
  static Future<void> resetPreferencesExample() async {
    try {
      final preferenceManager = await UserPreferenceManager.initialize();

      // 重置偏好（保留配置）
      await preferenceManager.resetPreferences();
      Logger.debug('✅ 偏好数据已重置');
    } catch (e) {
      Logger.debug('❌ 重置失败: $e');
    }
  }

  /// 示例10：完整的用户交互流程
  static Future<void> completeUserFlowExample() async {
    try {
      // 1. 初始化系统
      final preferenceManager = await UserPreferenceManager.initialize();
      final personalizedAI = await PersonalizedAIService.initialize(
        preferenceManager: preferenceManager,
      );

      Logger.debug('🚀 开始完整的用户交互流程');

      // 2. 用户输入文本
      const userText = '这个很好用';
      Logger.debug('👤 用户输入: $userText');

      // 3. AI给出建议
      final aiResponse = await personalizedAI.sendPersonalizedMessage([
        AIMessage(role: 'user', content: '请改进这段文字：$userText'),
      ]);
      Logger.debug('🤖 AI建议: ${aiResponse.content}');

      // 4. 用户反馈
      const finalText = '这个产品非常好用';
      await personalizedAI.recordFeedback(
        originalText: userText,
        suggestedText: aiResponse.content,
        finalText: finalText,
        context: '产品评价',
        topics: ['产品', '质量'],
      );
      Logger.debug('✅ 用户反馈已记录');

      // 5. 查看学习进度
      final stats = preferenceManager.getLearningStats();
      Logger.debug('📊 学习进度: ${stats['learningProgress']}');
      Logger.debug('📊 置信度: ${stats['confidenceScore']}');

      Logger.debug('✨ 完整流程执行成功');
    } catch (e) {
      Logger.debug('❌ 流程执行失败: $e');
    }
  }
}

/// Flutter Widget使用示例
class PreferenceLearningExampleWidget extends StatefulWidget {
  @override
  _PreferenceLearningExampleWidgetState createState() =>
      _PreferenceLearningExampleWidgetState();
}

class _PreferenceLearningExampleWidgetState
    extends State<PreferenceLearningExampleWidget> {
  UserPreferenceManager? _preferenceManager;
  PersonalizedAIService? _personalizedAI;
  Map<String, dynamic>? _learningStats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeSystem();
  }

  Future<void> _initializeSystem() async {
    setState(() => _isLoading = true);

    try {
      _preferenceManager = await UserPreferenceManager.initialize();
      _personalizedAI = await PersonalizedAIService.initialize(
        preferenceManager: _preferenceManager,
      );

      _learningStats = _preferenceManager!.getLearningStats();

      // 监听偏好更新
      _preferenceManager!.preferenceUpdates.listen((preference) {
        setState(() {
          _learningStats = _preferenceManager!.getLearningStats();
        });
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('用户偏好学习示例'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFeedbackDialog,
        tooltip: '记录反馈',
        child: const Icon(Icons.feedback),
      ),
    );
  }

  Widget _buildBody() {
    if (_learningStats == null) {
      return const Center(child: Text('系统初始化中...'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildLearningProgressCard(),
        const SizedBox(height: 16),
        _buildQuickActions(),
        const SizedBox(height: 16),
        _buildStatisticsCard(),
      ],
    );
  }

  Widget _buildLearningProgressCard() {
    final progress =
        (_learningStats!['learningProgress'] as num?)?.toDouble() ?? 0.0;
    final confidence =
        (_learningStats!['confidenceScore'] as num?)?.toDouble() ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('学习进度', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
            ),
            const SizedBox(height: 8),
            Text('进度: ${(progress * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 8),
            Text('置信度: ${(confidence * 100).toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('快速操作', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('分析我的写作'),
              onTap: _analyzeMyWriting,
            ),
            ListTile(
              leading: const Icon(Icons.psychology),
              title: const Text('获取个性化建议'),
              onTap: _getPersonalSuggestions,
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('偏好设置'),
              onTap: _openPreferenceSettings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final dataPoints = _learningStats!['learningDataPoints'] as int? ?? 0;
    final acceptanceRate =
        (_learningStats!['overallAcceptanceRate'] as num?)?.toDouble() ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('学习统计', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Text('学习数据点: $dataPoints'),
            const SizedBox(height: 8),
            Text('总体接受率: ${(acceptanceRate * 100).toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  Future<void> _analyzeMyWriting() async {
    final controller = TextEditingController(text: '在这里输入你的文字...');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('分析写作'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: '输入要分析的文本',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final analysis = await _preferenceManager!.analyzeWriting(
                controller.text,
              );
              Navigator.pop(context);
              _showAnalysisResult(analysis);
            },
            child: const Text('分析'),
          ),
        ],
      ),
    );
  }

  Future<void> _getPersonalSuggestions() async {
    final suggestions = _personalizedAI!.getPersonalizationSuggestions('示例文本');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('个性化建议'),
        content: SingleChildScrollView(
          child: Text(suggestions.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _openPreferenceSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PreferenceSettingsPage(),
      ),
    );
  }

  Future<void> _showFeedbackDialog() async {
    // 显示反馈对话框的实现
  }

  void _showAnalysisResult(WritingAnalysis analysis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('分析结果'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('语言风格: ${analysis.detectedLanguageStyle}'),
              Text('详细程度: ${analysis.detectedDetailLevel}'),
              Text('段落结构: ${analysis.detectedParagraphStructure}'),
              Text('句式复杂度: ${analysis.detectedSentenceComplexity}'),
              const SizedBox(height: 16),
              const Text('关键词:'),
              ...analysis.keywords.map((keyword) => Text('• $keyword')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
