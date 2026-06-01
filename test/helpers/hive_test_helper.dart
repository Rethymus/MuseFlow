import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

/// Sets up Hive for testing with a temporary directory.
/// Call this in setUp() before any Hive operations.
Future<void> setUpHiveTest() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final tempDir = Directory.systemTemp.createTempSync('hive_test_');
  Hive.init(tempDir.path);
}

/// Tears down Hive after testing.
/// Closes all boxes and cleans up.
Future<void> tearDownHiveTest() async {
  await Hive.deleteFromDisk();
}
