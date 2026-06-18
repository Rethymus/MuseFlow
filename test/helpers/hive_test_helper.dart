import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

/// Sets up Hive for testing with a temporary directory.
/// Call this in setUp() before any Hive operations.
///
/// ⚠ **Do NOT use this in tests that make REAL network/HTTP calls** (real-API
/// integration tests, live endpoint smoke tests). This calls
/// `TestWidgetsFlutterBinding.ensureInitialized()`, which installs flutter_test's
/// `HttpOverrides.global` mock — every real HTTP request then returns status 400
/// ("all HTTP requests will return status code 400, and no network request"),
/// silently intercepting live API calls and masking them as provider errors.
/// Use [setUpHiveForNetworkTest] for any test that touches the network. Pure
/// unit tests (no real HTTP) are unaffected.
Future<void> setUpHiveTest() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final tempDir = Directory.systemTemp.createTempSync('hive_test_');
  Hive.init(tempDir.path);
}

/// Sets up Hive for tests that ALSO make REAL network/HTTP calls (real-API
/// integration tests like `chapter_summary_refresh_service_real_glm_test.dart`).
///
/// Unlike [setUpHiveTest], this does NOT call
/// `TestWidgetsFlutterBinding.ensureInitialized()`, so flutter_test's HTTP mock
/// is never installed and real API calls reach the live endpoint. Hive needs no
/// Flutter binding when given an explicit temp path.
///
/// Pair with [tearDownHiveTest] for cleanup (closes boxes + deletes the temp
/// store). Mirrors the real-API pattern in
/// `test/journey/helpers/journey_container.dart`.
Future<void> setUpHiveForNetworkTest() async {
  final tempDir = Directory.systemTemp.createTempSync('hive_network_test_');
  Hive.init(tempDir.path);
}

/// Tears down Hive after testing.
/// Closes all boxes and cleans up.
Future<void> tearDownHiveTest() async {
  await Hive.deleteFromDisk();
}
