import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'character_service.dart';
import 'world_service.dart';
import 'knowledge_screen.dart';

/// 知识库功能初始化和配置
class KnowledgeFeature {
  /// 初始化知识库功能
  static Future<void> initialize() async {
    // 注册Hive适配器
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(CharacterModelAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(LocationAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(OrganizationAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(WorldModelAdapter());
    }
  }

  /// 获取知识库功能的Provider配置
  static List<SingleChildWidget> getProviders() {
    return [
      ChangeNotifierProvider<CharacterService>(
        create: (_) => CharacterService(),
      ),
      ChangeNotifierProvider<WorldService>(
        create: (_) => WorldService(),
      ),
    ];
  }

  /// 获取知识库主页面
  static Widget getScreen() {
    return const KnowledgeScreen();
  }

  /// 获取快速搜索组件
  static Widget getQuickSearch({
    String? hintText,
    Function(dynamic)? onResultSelected,
  }) {
    return KnowledgeQuickSearch(
      hintText: hintText,
      onResultSelected: onResultSelected,
    );
  }
}

/// 使用示例：
///
/// 1. 在main.dart中初始化：
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Hive.initFlutter();
///   await KnowledgeFeature.initialize();
///
///   runApp(
///     MultiProvider(
///       providers: [
///         ...KnowledgeFeature.getProviders(),
///         // 其他providers
///       ],
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
///
/// 2. 在导航中添加知识库页面：
/// ```dart
/// routes: {
///   '/knowledge': (context) => KnowledgeFeature.getScreen(),
/// }
/// ```
///
/// 3. 在编辑器中添加知识库搜索：
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return Column(
///     children: [
///       KnowledgeFeature.getQuickSearch(
///         hintText: '搜索角色和世界观...',
///         onResultSelected: (result) {
///           // 处理搜索结果，插入到编辑器
///           _insertKnowledgeToEditor(result);
///         },
///       ),
///       // 编辑器内容
///     ],
///   );
/// }
/// ```
///
/// 4. 直接使用服务：
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   final characterService = context.watch<CharacterService>();
///   final worldService = context.watch<WorldService>();
///
///   // 使用服务
///   return ListView(
///     children: [
///       ...characterService.characters.map((c) => ListTile(
///         title: Text(c.name),
///         onTap: () => characterService.setCurrentCharacter(c),
///       )).toList(),
///     ],
///   );
/// }
/// ```
