import 'package:flutter/material.dart';

/// A genre/template option displayed during onboarding.
///
/// Provides a lightweight built-in genre list for the onboarding wizard.
/// This is intentionally separate from the full WorldTemplate system (Phase 7)
/// to avoid coupling onboarding to unfinished infrastructure.
class GenreOption {
  const GenreOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.channel,
    this.tags = const [],
  });

  /// Unique identifier for this genre option.
  final String id;

  /// Display title.
  final String title;

  /// Short description shown on the card.
  final String description;

  /// Leading icon for the card.
  final IconData icon;

  /// Channel category (男频 / 女频).
  final String channel;

  /// Additional tags displayed on the card.
  final List<String> tags;

  /// All built-in genre options for the onboarding wizard.
  static const List<GenreOption> builtIn = [
    // Male channel (男频)
    GenreOption(
      id: 'xianxia',
      title: '修仙',
      description: '修真悟道、飞升成仙，天地法则下的长生之路',
      icon: Icons.filter_vintage,
      channel: '男频',
      tags: ['修炼', '境界'],
    ),
    GenreOption(
      id: 'wuxia',
      title: '武侠',
      description: '仗剑江湖、快意恩仇，侠义精神传承千年',
      icon: Icons.sports_kabaddi,
      channel: '男频',
      tags: ['江湖', '侠义'],
    ),
    GenreOption(
      id: 'xuanhuan',
      title: '玄幻',
      description: '异世大陆、神秘血脉，热血少年的崛起之路',
      icon: Icons.auto_awesome,
      channel: '男频',
      tags: ['异世', '热血'],
    ),
    GenreOption(
      id: 'scifi',
      title: '科幻',
      description: '星际文明、科技异变，探索未知的宇宙边疆',
      icon: Icons.science,
      channel: '男频',
      tags: ['星际', '未来'],
    ),
    GenreOption(
      id: 'dushi',
      title: '都市',
      description: '都市繁华、商海沉浮，平凡人的非凡人生',
      icon: Icons.location_city,
      channel: '男频',
      tags: ['商战', '生活'],
    ),
    GenreOption(
      id: 'lishi',
      title: '历史',
      description: '穿越古今、纵横乱世，以现代智慧改写历史',
      icon: Icons.history_edu,
      channel: '男频',
      tags: ['穿越', '权谋'],
    ),
    GenreOption(
      id: 'junshi',
      title: '军事',
      description: '铁血战场、沙场点兵，军人的荣耀与使命',
      icon: Icons.shield,
      channel: '男频',
      tags: ['战场', '战争'],
    ),
    GenreOption(
      id: 'lingyi',
      title: '灵异',
      description: '诡异怪谈、阴阳两界，看不见的恐怖真相',
      icon: Icons.dark_mode,
      channel: '男频',
      tags: ['怪谈', '悬疑'],
    ),
    // Female channel (女频)
    GenreOption(
      id: 'gudayanqing',
      title: '古言',
      description: '宫廷深院、锦绣华服，倾城之恋在乱世中绽放',
      icon: Icons.temple_buddhist,
      channel: '女频',
      tags: ['古代', '言情'],
    ),
    GenreOption(
      id: 'xiandaiyanqing',
      title: '现言',
      description: '都市爱情、甜蜜日常，心动的每个瞬间',
      icon: Icons.favorite,
      channel: '女频',
      tags: ['现代', '言情'],
    ),
    GenreOption(
      id: 'chuanyue',
      title: '穿越',
      description: '魂穿异世、逆天改命，用现代智慧开辟新天地',
      icon: Icons.time_to_leave,
      channel: '女频',
      tags: ['重生', '逆袭'],
    ),
    GenreOption(
      id: 'fantongren',
      title: '玄幻言情',
      description: '仙魔情缘、三生三世，跨越种族的爱与守护',
      icon: Icons.auto_fix_high,
      channel: '女频',
      tags: ['仙侠', '言情'],
    ),
    GenreOption(
      id: 'yule',
      title: '娱乐圈',
      description: '星光璀璨、幕后故事，从素人到顶流的逆袭之路',
      icon: Icons.theater_comedy,
      channel: '女频',
      tags: ['明星', '逆袭'],
    ),
    GenreOption(
      id: 'xuanyi_nv',
      title: '悬疑推理',
      description: '蛛丝马迹、层层推理，在迷雾中寻找真相',
      icon: Icons.search,
      channel: '女频',
      tags: ['悬疑', '推理'],
    ),
  ];
}
