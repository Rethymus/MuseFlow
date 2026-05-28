import 'package:flutter/material.dart';
import '../models/intent_confirmation.dart';
import '../services/intent_analyzer.dart';
import 'intent_confirmation_dialog.dart';
import 'intent_feedback_widget.dart';

/// 意图确认系统使用示例
///
/// 此文件展示如何使用意图确认系统的各个组件
class IntentConfirmationExample extends StatefulWidget {
  const IntentConfirmationExample({super.key});

  @override
  State<IntentConfirmationExample> createState() => _IntentConfirmationExampleState();
}

class _IntentConfirmationExampleState extends State<IntentConfirmationExample> {
  late final IntentAnalyzer _intentAnalyzer;
  final List<String> _operationHistory = [];
  final Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _intentAnalyzer = const IntentAnalyzer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('意图确认系统示例'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 基本用法示例
          _buildSection(
            '基本用法',
            [
              _buildExampleCard(
                title: 'AI润色操作',
                description: '演示基本的意图确认流程',
                onTap: () => _showPolishExample(),
              ),
              const SizedBox(height: 12),
              _buildExampleCard(
                title: 'AI扩写操作',
                description: '演示带有参数调整的意图确认',
                onTap: () => _showExpandExample(),
              ),
              const SizedBox(height: 12),
              _buildExampleCard(
                title: '生成大纲操作',
                description: '演示复杂操作的意图确认',
                onTap: () => _showOutlineExample(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 高级功能示例
          _buildSection(
            '高级功能',
            [
              _buildExampleCard(
                title: '查看意图分析',
                description: '展示意图分析器的详细分析',
                onTap: () => _showAnalysisExample(),
              ),
              const SizedBox(height: 12),
              _buildExampleCard(
                title: '反馈收集',
                description: '演示用户反馈收集流程',
                onTap: () => _showFeedbackExample(),
              ),
              const SizedBox(height: 12),
              _buildExampleCard(
                title: '统计数据',
                description: '查看意图确认的统计数据',
                onTap: () => _showStatisticsExample(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 操作历史
          _buildSection(
            '操作历史',
            [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '最近的操作',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_operationHistory.isEmpty)
                      const Text('暂无操作记录')
                    else
                      ..._operationHistory.map((operation) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.history, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(operation)),
                          ],
                        ),
                      )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildExampleCard({
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // 示例1: 基本的润色操作
  void _showPolishExample() {
    const sampleText = '这是一个示例文本，包含一些语法错误和表达不当的地方。';

    // 分析意图
    final intent = _intentAnalyzer.analyzeRequest(
      actionType: AIActionType.polish,
      originalText: sampleText,
    );

    // 显示确认对话框
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => IntentConfirmationDialog(
          intent: intent,
          onConfirm: (confirmedIntent) {
            _addToHistory('AI润色: ${confirmedIntent.description}');
            _showFeedbackDialog(confirmedIntent.id, 'polish');
          },
          onCancel: () {
            _addToHistory('AI润色: 用户取消');
          },
        ),
      );
    }
  }

  // 示例2: 带参数调整的扩写操作
  void _showExpandExample() {
    const sampleText = '人工智能技术正在快速发展。';

    final intent = _intentAnalyzer.analyzeRequest(
      actionType: AIActionType.expand,
      originalText: sampleText,
      additionalParams: {
        'context': '技术趋势分析',
        'targetLength': 200,
      },
    );

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => IntentConfirmationDialog(
          intent: intent,
          onConfirm: (confirmedIntent) {
            _addToHistory('AI扩写: ${confirmedIntent.description}');
            _showFeedbackDialog(confirmedIntent.id, 'expand');
          },
          onCancel: () {
            _addToHistory('AI扩写: 用户取消');
          },
        ),
      );
    }
  }

  // 示例3: 生成大纲操作
  void _showOutlineExample() {
    const sampleText = '''
机器学习是人工智能的一个分支。它通过算法让计算机从数据中学习。
深度学习是机器学习的一种特殊形式。神经网络是深度学习的基础。
人工智能的应用领域越来越广泛。''';

    final intent = _intentAnalyzer.analyzeRequest(
      actionType: AIActionType.outline,
      originalText: sampleText,
    );

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => IntentConfirmationDialog(
          intent: intent,
          onConfirm: (confirmedIntent) {
            _addToHistory('生成大纲: ${confirmedIntent.description}');
            _showFeedbackDialog(confirmedIntent.id, 'outline');
          },
          onCancel: () {
            _addToHistory('生成大纲: 用户取消');
          },
        ),
      );
    }
  }

  // 示例4: 查看意图分析
  void _showAnalysisExample() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('意图分析示例'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAnalysisItem('润色操作', () {
                return _intentAnalyzer.analyzeRequest(
                  actionType: AIActionType.polish,
                  originalText: '这段文本有一些语法问题。。。',
                );
              }),
              const SizedBox(height: 12),
              _buildAnalysisItem('扩写操作', () {
                return _intentAnalyzer.analyzeRequest(
                  actionType: AIActionType.expand,
                  originalText: '短文本',
                );
              }),
              const SizedBox(height: 12),
              _buildAnalysisItem('摘要操作', () {
                return _intentAnalyzer.analyzeRequest(
                  actionType: AIActionType.summarize,
                  originalText: '这是一段较长的文本，需要生成摘要。' * 10,
                  additionalParams: {'maxLength': 50},
                );
              }),
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

  Widget _buildAnalysisItem(String title, IntentConfirmation Function() builder) {
    final intent = builder();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('操作类型: ${intent.actionType}'),
        Text('描述: ${intent.description}'),
        Text('解释: ${intent.explanation}'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '预期效果: ${intent.expectedOutcome}',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  // 示例5: 反馈收集
  void _showFeedbackExample() {
    showDialog(
      context: context,
      builder: (context) => IntentFeedbackDialog(
        intentId: 'example_intent_123',
        operationType: 'polish',
        onSubmit: (feedback, rating) {
          _addToHistory('反馈提交: 评分$rating, $feedback');
        },
      ),
    );
  }

  // 示例6: 统计数据
  void _showStatisticsExample() {
    final stats = _intentAnalyzer.getFeedbackStatistics();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('意图确认统计'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('总操作数: ${stats['total']}'),
            Text('确认次数: ${stats['confirmed']}'),
            Text('调整次数: ${stats['adjusted']}'),
            Text('拒绝次数: ${stats['rejected']}'),
            const SizedBox(height: 8),
            Text(
              '确认率: ${((stats['confirmation_rate'] as double) * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
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

  void _showFeedbackDialog(String intentId, String operationType) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => IntentFeedbackDialog(
          intentId: intentId,
          operationType: operationType,
          onSubmit: (feedback, rating) {
            _intentAnalyzer.recordFeedback(
              IntentConfirmationFeedback(
                intentId: intentId,
                confirmed: true,
                userComment: feedback,
              ),
            );
            _addToHistory('反馈: $rating星 - $feedback');
          },
        ),
      );
    }
  }

  void _addToHistory(String operation) {
    setState(() {
      _operationHistory.insert(0, operation);
      if (_operationHistory.length > 10) {
        _operationHistory.removeLast();
      }
    });
  }
}

/// 意图确认系统快速开始指南
///
/// 基本步骤:
/// 1. 创建 IntentAnalyzer 实例
/// 2. 分析用户请求生成 IntentConfirmation
/// 3. 显示 IntentConfirmationDialog 让用户确认
/// 4. 根据用户选择执行操作或取消
/// 5. (可选) 收集用户反馈以改进系统
///
/// 示例代码:
/// ```dart
/// // 1. 创建分析器
/// final analyzer = IntentAnalyzer();
///
/// // 2. 分析请求
/// final intent = analyzer.analyzeRequest(
///   actionType: AIActionType.polish,
///   originalText: '用户文本',
/// );
///
/// // 3. 显示对话框
/// showDialog(
///   context: context,
///   builder: (context) => IntentConfirmationDialog(
///     intent: intent,
///     onConfirm: (confirmed) {
///       // 执行操作
///     },
///     onCancel: () {
///       // 取消操作
///     },
///   ),
/// );
/// ```
