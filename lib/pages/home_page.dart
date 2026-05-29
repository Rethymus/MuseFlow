import '../utils/logger.dart';
import '../config/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../models/app_state.dart';
import '../widgets/note_list.dart';
import '../widgets/note_editor.dart';
import '../widgets/global_search_widget.dart';
import '../services/global_search_service.dart';
import '../models/note.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WindowListener {
  @override
  void initState() {
    super.initState();
    if (Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.linux ||
        Theme.of(context).platform == TargetPlatform.macOS) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.linux ||
        Theme.of(context).platform == TargetPlatform.macOS) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowClose() async {
    try {
      final appState = context.read<AppState>();
      await appState.saveBeforeExit();
      await windowManager.destroy();
    } catch (e) {
      Logger.debug('Error during window close: $e');
      await windowManager.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MuseFlow'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _handleSearch(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 设置功能现在由主导航容器提供
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('请使用底部导航栏的设置功能'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: const [
          Expanded(flex: 1, child: NoteList()),
          Expanded(flex: 2, child: NoteEditor()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<AppState>().createNewNote();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 处理搜索操作
  void _handleSearch(BuildContext context) async {
    await GlobalSearchDialog.show(context);
  }

  /// 处理搜索结果选择
  void _handleSearchResult(BuildContext context, GlobalSearchResult result) {
    switch (result.type) {
      case GlobalSearchResultType.note:
        // 如果是笔记结果，导航到该笔记
        final note = result.data as Note;
        context.read<AppState>().selectNote(note);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已打开笔记: ${note.title}')),
        );
        break;

      case GlobalSearchResultType.character:
        // TODO: 实现角色详情页面导航
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已选择角色: ${result.title}')),
        );
        break;

      case GlobalSearchResultType.world:
        // TODO: 实现世界观详情页面导航
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已选择世界观: ${result.title}')),
        );
        break;

      case GlobalSearchResultType.location:
        // TODO: 实现地点详情页面导航
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已选择地点: ${result.title}')),
        );
        break;

      case GlobalSearchResultType.organization:
        // TODO: 实现组织详情页面导航
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已选择组织: ${result.title}')),
        );
        break;
    }
  }
}
