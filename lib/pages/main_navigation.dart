import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../features/editor/editor_screen.dart';
import '../features/knowledge/knowledge_screen.dart';
import 'home_page.dart';
import 'settings_page.dart';
import 'search_page.dart';
import '../utils/page_transitions.dart';

/// MuseFlow主导航容器
/// 统一管理所有主要功能模块的导航和切换
class MainNavigationContainer extends StatefulWidget {
  const MainNavigationContainer({super.key});

  @override
  State<MainNavigationContainer> createState() =>
      _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  final List<NavigationDestination> _destinations = [
    const NavigationDestination(
      icon: Icon(Icons.edit_note),
      selectedIcon: Icon(Icons.edit_note),
      label: '写作',
    ),
    const NavigationDestination(
      icon: Icon(Icons.psychology),
      selectedIcon: Icon(Icons.psychology),
      label: '编辑器',
    ),
    const NavigationDestination(
      icon: Icon(Icons.library_books),
      selectedIcon: Icon(Icons.library_books),
      label: '知识库',
    ),
    const NavigationDestination(
      icon: Icon(Icons.search),
      selectedIcon: Icon(Icons.search),
      label: '搜索',
    ),
    const NavigationDestination(
      icon: Icon(Icons.settings),
      selectedIcon: Icon(Icons.settings),
      label: '设置',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _destinations.length,
      vsync: this,
      initialIndex: _currentIndex,
    );
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentIndex = _tabController.index;
      });
    }
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _currentIndex = index;
      _tabController.animateTo(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // 主内容区域
          _buildCurrentPage(),

          // 顶部导航栏 - 大屏幕显示在左侧，小屏幕显示在底部
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildNavigationBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPage() {
    // 为每个页面添加内边距，避免被导航栏遮挡
    return Padding(
      padding: EdgeInsets.only(
        bottom: 80, // 为底部导航栏留出空间
      ),
      child: _buildPageContent(),
    );
  }

  Widget _buildPageContent() {
    Widget page;
    switch (_currentIndex) {
      case 0:
        page = const HomePage();
        break;
      case 1:
        page = const EditorScreen();
        break;
      case 2:
        page = const KnowledgeScreen();
        break;
      case 3:
        page = const SearchPage();
        break;
      case 4:
        page = const SettingsPage();
        break;
      default:
        page = const HomePage();
    }

    // 使用页面切换动画
    return PageSwitchAnimation(
      key: ValueKey(_currentIndex),
      currentIndex: _currentIndex,
      previousIndex: _currentIndex == 0 ? 4 : _currentIndex - 1,
      child: page,
    );
  }

  Widget _buildNavigationBar() {
    final isLargeScreen = MediaQuery.of(context).size.width > 800;

    if (isLargeScreen) {
      // 大屏幕：显示侧边导航栏
      return _buildSideNavigationBar();
    } else {
      // 小屏幕：显示底部导航栏
      return _buildBottomNavigationBar();
    }
  }

  Widget _buildBottomNavigationBar() {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: _onDestinationSelected,
      destinations: _destinations,
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildSideNavigationBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _destinations.asMap().entries.map((entry) {
          final index = entry.key;
          final destination = entry.value;
          final isSelected = _currentIndex == index;

          return _buildNavigationItem(
            icon: destination.icon,
            selectedIcon: destination.selectedIcon,
            label: destination.label,
            isSelected: isSelected,
            onTap: () => _onDestinationSelected(index),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNavigationItem({
    required Widget icon,
    Widget? selectedIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme(
              data: IconThemeData(
                size: 24,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              child: isSelected ? (selectedIcon ?? icon) : icon,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
