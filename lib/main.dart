import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';

import 'pages/home_page.dart';
import 'pages/startup_page.dart';
import 'pages/main_navigation.dart';
import 'services/progressive_initializer.dart';
import 'services/startup_monitor.dart';
import 'services/storage_service.dart';
import 'services/window_service.dart';
import 'services/global_search_service.dart';
import 'services/secure_storage_service.dart';
import 'services/shared_data_service.dart';
import 'models/app_state.dart';
import 'theme/app_theme.dart';
import 'features/knowledge/character_service.dart';
import 'features/knowledge/world_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 开始启动性能监控
  StartupMonitor.instance.startMonitoring();

  // 初始化存储服务
  await StorageService.instance.initialize();

  // 初始化渐进式初始化器
  await ProgressiveInitializer.instance.initialize();

  // Initialize Window Manager for Desktop
  await WindowService.instance.initializeWindow();

  // 记录启动完成
  StartupMonitor.instance.recordComplete();

  runApp(const MuseFlowApp());
}

class MuseFlowApp extends StatelessWidget {
  const MuseFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => CharacterService()),
        ChangeNotifierProvider(create: (_) => WorldService()),
        ChangeNotifierProvider(create: (_) => SecureStorageService()),
        ChangeNotifierProvider(create: (_) => GlobalSearchService(
          storageService: SecureStorageService.instance,
          characterService: CharacterService(),
          worldService: WorldService(),
        )),
        ChangeNotifierProvider(create: (_) => SharedDataService()),
      ],
      child: MaterialApp(
        title: 'MuseFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const StartupScreenWrapper(
          child: MainNavigationContainer(),
        ),
      ),
    );
  }
}
