import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/infrastructure/secure_storage_service.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/application/provider_service.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/infrastructure/provider_repository.dart';
import 'package:museflow/features/ai/presentation/provider_management_page.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  late Box<dynamic> box;
  late ProviderService service;

  setUp(() async {
    await setUpHiveTest();
    box = await Hive.openBox<dynamic>('ai_providers_test');
    final secureStorage = _InMemorySecureStorage();
    service = ProviderService(
      ProviderRepository(box, secureStorage),
      secureStorage,
    );
  });

  tearDown(() async {
    await tearDownHiveTest();
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [providerServiceProvider.overrideWith((ref) async => service)],
      child: const MaterialApp(home: ProviderManagementPage()),
    );
  }

  group('ProviderManagementPage responsive layout', () {
    testWidgets('uses desktop Row layout at the 600px breakpoint', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(LayoutBuilder), findsOneWidget);
      expect(find.byType(VerticalDivider), findsOneWidget);
      expect(find.text('返回列表'), findsNothing);
      expect(find.text('预设模型'), findsOneWidget);
      expect(find.text('配置新模型'), findsOneWidget);
    });

    testWidgets('uses mobile list/form switching below 600px', (tester) async {
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(LayoutBuilder), findsOneWidget);
      expect(find.byType(VerticalDivider), findsNothing);
      expect(find.text('返回列表'), findsOneWidget);
      expect(find.text('预设模型'), findsOneWidget);
      expect(find.text('配置新模型'), findsNothing);

      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();

      expect(find.text('预设模型'), findsNothing);
      expect(find.text('配置新模型'), findsOneWidget);
      expect(find.text('Temperature'), findsOneWidget);

      await tester.tap(find.text('返回列表'));
      await tester.pumpAndSettle();

      expect(find.text('预设模型'), findsOneWidget);
      expect(find.text('配置新模型'), findsNothing);
    });
  });
}

class _InMemorySecureStorage implements SecureStorageService {
  final Map<String, String> _store = {};

  @override
  Future<void> deleteApiKey(String providerId) async {
    _store.remove(providerId);
  }

  @override
  Future<String?> getApiKey(String providerId) async {
    return _store[providerId];
  }

  @override
  Future<void> saveApiKey(String providerId, String key) async {
    _store[providerId] = key;
  }
}
