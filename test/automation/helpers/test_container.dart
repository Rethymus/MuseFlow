import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/presentation/providers.dart';

import 'fake_adapter.dart';

Future<ProviderContainer> createTestContainer() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final tempDir = Directory.systemTemp.createTempSync('automation_test_');
  Hive.init(tempDir.path);

  await Hive.openBox<dynamic>('manuscripts');
  await Hive.openBox<dynamic>('chapters');
  await Hive.openBox<dynamic>('token_audit');
  await Hive.openBox<dynamic>('ai_providers');
  await Hive.openBox<dynamic>('fragments');

  return ProviderContainer(
    overrides: [openaiAdapterProvider.overrideWithValue(FakeAdapter())],
  );
}

Future<void> cleanupTestContainer(ProviderContainer container) async {
  container.dispose();
  await Hive.deleteFromDisk();
}
