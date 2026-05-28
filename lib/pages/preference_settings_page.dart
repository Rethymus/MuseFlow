import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_preference.dart';
import '../services/preference/user_preference_manager.dart';
import '../widgets/preference/preference_summary_card.dart';
import '../widgets/preference/language_style_indicator.dart';
import '../widgets/preference/learning_progress_bar.dart';
import '../widgets/preference/modification_acceptance_chart.dart';
import '../widgets/preference/topic_interest_cloud.dart';
import '../widgets/preference/privacy_control_panel.dart';

/// 用户偏好设置页面
/// 显示和管理用户偏好学习数据和隐私设置
class PreferenceSettingsPage extends StatefulWidget {
  const PreferenceSettingsPage({Key? key}) : super(key: key);

  @override
  State<PreferenceSettingsPage> createState() => _PreferenceSettingsPageState();
}

class _PreferenceSettingsPageState extends State<PreferenceSettingsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _learningStats;
  Map<String, dynamic>? _privacyReport;
  UserPreference? _currentPreference;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final manager = context.read<UserPreferenceManager>();
      _currentPreference = manager.currentPreference;
      _learningStats = manager.getLearningStats();
      _privacyReport = await manager.getPrivacyReport();
    } catch (e) {
      // 处理错误
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI偏好学习设置'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildLearningOverview(),
          const SizedBox(height: 24),
          _buildPreferenceDetails(),
          const SizedBox(height: 24),
          _buildPrivacyControls(),
          const SizedBox(height: 24),
          _buildDataManagement(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final preference = _currentPreference;
    final isEnabled = preference?.enabled ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isEnabled ? Icons.psychology : Icons.psychology_outlined,
                  size: 32,
                  color: isEnabled ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI个性化学习',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEnabled ? '已启用' : '已禁用',
                        style: TextStyle(
                          color: isEnabled ? Colors.green : Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: (value) => _toggleLearningEnabled(value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningOverview() {
    final stats = _learningStats;
    if (stats == null) return const SizedBox.shrink();

    return PreferenceSummaryCard(
      learningDataPoints: stats['learningDataPoints'] as int? ?? 0,
      confidenceScore: (stats['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      learningProgress: (stats['learningProgress'] as num?)?.toDouble() ?? 0.0,
      overallAcceptanceRate: (stats['overallAcceptanceRate'] as num?)?.toDouble() ?? 0.0,
      hasSufficientConfidence: stats['hasSufficientConfidence'] as bool? ?? false,
    );
  }

  Widget _buildPreferenceDetails() {
    final preference = _currentPreference;
    if (preference == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '学习到的偏好',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            LanguageStyleIndicator(
              languageStyle: preference.languageStyle,
              detailLevel: preference.detailLevel,
              paragraphStructure: preference.paragraphStructure,
              sentenceComplexity: preference.sentenceComplexity,
            ),
            const SizedBox(height: 16),
            LearningProgressBar(
              progress: preference.learningProgress,
              dataPoints: preference.learningDataPoints,
              confidence: preference.confidenceScore,
            ),
            if (preference.modificationAcceptanceRates.isNotEmpty) ...[
              const SizedBox(height: 16),
              ModificationAcceptanceChart(
                acceptanceRates: preference.modificationAcceptanceRates,
              ),
            ],
            if (preference.topicInterests.isNotEmpty) ...[
              const SizedBox(height: 16),
              TopicInterestCloud(
                topicInterests: preference.topicInterests,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyControls() {
    final report = _privacyReport;
    if (report == null) return const SizedBox.shrink();

    return PrivacyControlPanel(
      dataStoredLocally: report['dataStoredLocally'] as bool? ?? false,
      dataStoredInSecureStorage: report['dataStoredInSecureStorage'] as bool? ?? false,
      feedbackHistorySize: report['feedbackHistorySize'] as int? ?? 0,
      writingAnalyticsSize: report['writingAnalyticsSize'] as int? ?? 0,
      dataRetentionDays: report['dataRetentionDays'] as int? ?? 90,
      anonymizeData: report['anonymizeData'] as bool? ?? false,
      onPrivacyChanged: _updatePrivacySettings,
    );
  }

  Widget _buildDataManagement() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '数据管理',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('清除偏好数据'),
              subtitle: const Text('删除所有学习到的偏好，但保留配置'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showClearPreferencesDialog(),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined),
              title: const Text('清除所有数据'),
              subtitle: const Text('删除所有学习数据和历史记录'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showClearAllDataDialog(),
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('导出偏好数据'),
              subtitle: const Text('将偏好数据导出为JSON格式'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _exportData,
            ),
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text('查看详细统计'),
              subtitle: const Text('查看学习过程的详细统计信息'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showDetailedStats,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLearningEnabled(bool enabled) async {
    try {
      final manager = context.read<UserPreferenceManager>();
      final updatedConfig = manager.config.copyWith(enabled: enabled);
      await manager.updateConfig(updatedConfig);
      await _loadData();
    } catch (e) {
      _showErrorDialog('无法更改学习设置：$e');
    }
  }

  Future<void> _updatePrivacySettings({
    bool? anonymizeData,
    int? dataRetentionDays,
    bool? autoApply,
  }) async {
    try {
      final manager = context.read<UserPreferenceManager>();
      final currentConfig = manager.config;
      final updatedConfig = currentConfig.copyWith(
        anonymizeData: anonymizeData ?? currentConfig.anonymizeData,
        dataRetentionDays: dataRetentionDays ?? currentConfig.dataRetentionDays,
        autoApply: autoApply ?? currentConfig.autoApply,
      );
      await manager.updateConfig(updatedConfig);
      await _loadData();
    } catch (e) {
      _showErrorDialog('无法更新隐私设置：$e');
    }
  }

  Future<void> _showClearPreferencesDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除偏好数据'),
        content: const Text('这将删除所有学习到的偏好，但保留配置。确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final manager = context.read<UserPreferenceManager>();
        await manager.resetPreferences();
        await _loadData();
        _showSuccessDialog('偏好数据已清除');
      } catch (e) {
        _showErrorDialog('无法清除偏好数据：$e');
      }
    }
  }

  Future<void> _showClearAllDataDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除所有数据'),
        content: const Text('这将删除所有学习数据、历史记录和配置。此操作不可恢复。确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('全部清除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final manager = context.read<UserPreferenceManager>();
        await manager.clearAllData();
        await _loadData();
        _showSuccessDialog('所有数据已清除');
      } catch (e) {
        _showErrorDialog('无法清除数据：$e');
      }
    }
  }

  Future<void> _exportData() async {
    try {
      final manager = context.read<UserPreferenceManager>();
      final data = await manager.exportData();
      // 这里可以实现数据导出逻辑
      // 例如：保存到文件或分享
      _showSuccessDialog('数据导出成功');
    } catch (e) {
      _showErrorDialog('无法导出数据：$e');
    }
  }

  void _showDetailedStats() {
    final stats = _learningStats;
    if (stats == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('详细学习统计'),
        content: SingleChildScrollView(
          child: Text(
            stats.toString(),
            style: const TextStyle(fontFamily: 'monospace'),
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

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('成功'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}