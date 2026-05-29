import 'package:flutter/material.dart';

/// 根据世界观类型返回对应图标
IconData getWorldIcon(String worldType) {
  switch (worldType.toLowerCase()) {
    case '奇幻':
      return Icons.auto_awesome;
    case '科幻':
      return Icons.rocket_launch;
    case '现实':
      return Icons.location_city;
    case '历史':
      return Icons.history_edu;
    default:
      return Icons.public;
  }
}

/// 构建空详情占位组件，[type] 为类型名称（如"角色卡"、"世界观"）
Widget buildEmptyDetail(String type) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.description, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(
          '选择一个$type查看详情',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    ),
  );
}

/// 构建带标题和内容的详情区块，内容为空时返回空组件
Widget buildSection(String title, String? content) {
  if (content?.isEmpty ?? true) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      Text(content!),
      const SizedBox(height: 16),
    ],
  );
}
