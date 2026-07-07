/// Real widget screenshot generator for the README ai-providers image (#20).
///
/// Renders the **actual** [ProviderManagementPage] — AI 模型管理: a master/detail
/// layout (left: configured providers + presets; right: selected-provider
/// details) — at 1440x1000 with a seeded [ProviderManagementState], producing
/// a truthful screenshot.
///
/// The build path watches providerManagementProvider (state) + presetProvidersProvider
/// (pure, returns PresetProviders.all — no override needed). Only
/// providerManagementProvider is overridden with a seeded state carrying 3 realistic
/// configured providers (one active) and isLoading=false so the list renders.
///
/// Shares the bundled universal GB2312 subset `test_assets/noto_sans_sc_subset.ttf`.
///
/// Regenerate after changing the page or seed data:
///   flutter test test/readme_screenshots/provider_management_test.dart --update-goldens
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/presentation/provider_management_notifier.dart';
import 'package:museflow/features/ai/presentation/provider_management_page.dart';

void main() {
  setUpAll(() async {
    final bytes = await File(
      'test_assets/noto_sans_sc_subset.ttf',
    ).readAsBytes();
    final loader = FontLoader('Noto Sans CJK SC');
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  });

  testWidgets('ProviderManagementPage renders a real 1440x1000 screenshot', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          providerManagementProvider.overrideWith(
            () => _SeededProviderManagementNotifier(),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _screenshotTheme(),
          home: const ProviderManagementPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Prove the page rendered past loading (AppBar title present, no spinner).
    // 'AI 模型管理' is the AppBar title (unique). No CircularProgressIndicator
    // proves the seeded state (isLoading=false) drove the list render path.
    expect(find.text('AI 模型管理'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // A configured provider renders by name (left list + possibly right detail,
    // so assert presence, not exact count).
    expect(find.text('GLM-4-Flash'), findsAtLeastNWidgets(1));

    await expectLater(
      find.byType(ProviderManagementPage),
      matchesGoldenFile('../../docs/readme/screenshots/20-ai-providers.png'),
    );
  });
}

/// Seeded override returning a fixed ProviderManagementState with 3 realistic
/// configured providers (the active one selected), isLoading=false so the
/// master/detail renders instead of the loading spinner. Honest reflection of
/// a configured multi-provider setup (OpenAI-compatible GLM + DeepSeek, local
/// Ollama) — no real keys, demo base URLs only.
class _SeededProviderManagementNotifier extends ProviderManagementNotifier {
  @override
  ProviderManagementState build() {
    final now = DateTime.now();
    final providers = <AIProvider>[
      AIProvider(
        id: 'p1',
        name: 'GLM-4-Flash',
        baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
        type: AiProviderType.openai,
        model: 'glm-4-flash',
        isActive: true,
        createdAt: now,
      ),
      AIProvider(
        id: 'p2',
        name: 'DeepSeek',
        baseUrl: 'https://api.deepseek.com/v1',
        type: AiProviderType.openai,
        model: 'deepseek-chat',
        createdAt: now,
      ),
      AIProvider(
        id: 'p3',
        name: 'Ollama 本地',
        baseUrl: 'http://localhost:11434/v1',
        type: AiProviderType.ollama,
        model: 'qwen2.5:14b',
        createdAt: now,
      ),
    ];
    return ProviderManagementState(
      providers: providers,
      selectedProvider: providers.first,
      activeProvider: providers.first,
      isLoading: false,
    );
  }
}

ThemeData _screenshotTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    brightness: Brightness.dark,
  );
  final base = Typography.material2021().white.apply(
    fontFamily: 'Noto Sans CJK SC',
  );
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    textTheme: base.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
  );
}
