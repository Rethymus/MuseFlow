import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:integration_test/integration_test.dart';
import 'package:museflow/app.dart';
import 'package:museflow/core/infrastructure/hive_adapters.dart';
import 'package:museflow/features/ai/infrastructure/preset_providers.dart';

Future<void> _initializeTestStorage() async {
  final tempDir = await Directory.systemTemp.createTemp(
    'museflow_integration_',
  );
  Hive.init(tempDir.path);

  if (!Hive.isAdapterRegistered(HiveTypeIds.fragment)) {
    Hive.registerAdapter(FragmentAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.appSettings)) {
    Hive.registerAdapter(AppSettingsAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.characterCard)) {
    Hive.registerAdapter(CharacterCardAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.worldSetting)) {
    Hive.registerAdapter(WorldSettingAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.skillDocument)) {
    Hive.registerAdapter(SkillDocumentAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.foreshadowingEntry)) {
    Hive.registerAdapter(ForeshadowingEntryAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.plotNode)) {
    Hive.registerAdapter(PlotNodeAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.guardianAnnotation)) {
    Hive.registerAdapter(GuardianAnnotationAdapter());
  }
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const MuseFlowApp());
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await _initializeTestStorage();
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  testWidgets('App launches and shows main shell', (tester) async {
    await _pumpApp(tester);

    expect(find.text('编辑器'), findsOneWidget);
    expect(find.text('捕捉器'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
  });

  testWidgets('Navigate to settings', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();

    expect(find.text('AI 模型'), findsOneWidget);
    expect(find.text('本地数据'), findsOneWidget);
  });

  testWidgets('Navigate to AI provider settings', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI 模型'));
    await tester.pumpAndSettle();

    expect(find.text('AI 模型管理'), findsOneWidget);
    expect(find.text('预设模型'), findsOneWidget);
  });

  testWidgets('Preset providers are displayed', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI 模型'));
    await tester.pumpAndSettle();

    for (final preset in PresetProviders.all) {
      expect(find.text(preset.name), findsWidgets);
    }
  });
}
