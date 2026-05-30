import 'package:flutter/material.dart';

/// 隐私控制面板
/// 提供隐私设置的控制选项
class PrivacyControlPanel extends StatefulWidget {
  final bool dataStoredLocally;
  final bool dataStoredInSecureStorage;
  final int feedbackHistorySize;
  final int writingAnalyticsSize;
  final int dataRetentionDays;
  final bool anonymizeData;
  final Function({
    bool? anonymizeData,
    int? dataRetentionDays,
    bool? autoApply,
  })? onPrivacyChanged;

  const PrivacyControlPanel({
    super.key,
    required this.dataStoredLocally,
    required this.dataStoredInSecureStorage,
    required this.feedbackHistorySize,
    required this.writingAnalyticsSize,
    required this.dataRetentionDays,
    required this.anonymizeData,
    this.onPrivacyChanged,
  });

  @override
  State<PrivacyControlPanel> createState() => _PrivacyControlPanelState();
}

class _PrivacyControlPanelState extends State<PrivacyControlPanel> {
  late bool _anonymizeData;
  late int _dataRetentionDays;

  @override
  void initState() {
    super.initState();
    _anonymizeData = widget.anonymizeData;
    _dataRetentionDays = widget.dataRetentionDays;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, size: 24),
                const SizedBox(width: 12),
                Text(
                  '隐私设置',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDataStorageInfo(),
            const SizedBox(height: 16),
            _buildAnonymizeDataToggle(),
            const SizedBox(height: 16),
            _buildDataRetentionSlider(),
          ],
        ),
      ),
    );
  }

  Widget _buildDataStorageInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              widget.dataStoredLocally ? Icons.check_circle : Icons.circle,
              color: widget.dataStoredLocally ? Colors.green : Colors.grey,
              size: 16,
            ),
            const SizedBox(width: 8),
            const Text('数据仅存储在本地'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              widget.dataStoredInSecureStorage
                  ? Icons.check_circle
                  : Icons.circle,
              color:
                  widget.dataStoredInSecureStorage ? Colors.green : Colors.grey,
              size: 16,
            ),
            const SizedBox(width: 8),
            const Text('敏感数据使用加密存储'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '当前存储：${widget.feedbackHistorySize} 条反馈记录，${widget.writingAnalyticsSize} 条写作分析',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildAnonymizeDataToggle() {
    return SwitchListTile(
      title: const Text('匿名化数据'),
      subtitle: const Text('在分析时移除个人识别信息'),
      value: _anonymizeData,
      onChanged: (value) {
        setState(() {
          _anonymizeData = value;
        });
        widget.onPrivacyChanged?.call(anonymizeData: value);
      },
    );
  }

  Widget _buildDataRetentionSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('数据保留期限'),
            Text(
              '$_dataRetentionDays 天',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _dataRetentionDays.toDouble(),
          min: 7,
          max: 365,
          divisions: 358,
          label: '$_dataRetentionDays 天',
          onChanged: (value) {
            setState(() {
              _dataRetentionDays = value.toInt();
            });
            widget.onPrivacyChanged
                ?.call(dataRetentionDays: _dataRetentionDays);
          },
        ),
        const SizedBox(height: 8),
        Text(
          '超过此期限的历史数据将被自动删除',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
