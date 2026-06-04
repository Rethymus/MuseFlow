import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/shared/constants/app_constants.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  setUp(() async {
    await setUpHiveTest();
  });

  tearDown(() async {
    await tearDownHiveTest();
  });

  /// Simulates the redirect logic from MuseFlowApp._handleRedirect.
  ///
  /// Extracted into a testable function that mirrors the production logic
  /// without requiring the full widget/routing infrastructure.
  Future<String?> handleRedirect({
    required String matchedLocation,
    required Box<dynamic> box,
  }) async {
    final isOnboarding = matchedLocation == AppConstants.onboarding;

    try {
      final completed =
          box.get('onboarding_completed', defaultValue: false) as bool;

      if (!completed && !isOnboarding) {
        return AppConstants.onboarding;
      }

      if (completed && isOnboarding) {
        return AppConstants.editor;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  group('Onboarding redirect guard', () {
    late Box<dynamic> box;

    setUp(() async {
      box = await Hive.openBox<dynamic>('test_settings');
    });

    test('should redirect to /onboarding when completed=false and not on onboarding route',
        () async {
      final result = await handleRedirect(
        matchedLocation: '/editor',
        box: box,
      );

      expect(result, AppConstants.onboarding);
    });

    test('should return null when completed=true and not on onboarding route', () async {
      await box.put('onboarding_completed', true);

      final result = await handleRedirect(
        matchedLocation: '/editor',
        box: box,
      );

      expect(result, isNull);
    });

    test('should redirect to editor when completed=true and on onboarding route', () async {
      await box.put('onboarding_completed', true);

      final result = await handleRedirect(
        matchedLocation: AppConstants.onboarding,
        box: box,
      );

      expect(result, AppConstants.editor);
    });

    test('should return null when completed=false and already on /onboarding (prevents infinite loop)',
        () async {
      // onboarding_completed is not set (defaults to false)

      final result = await handleRedirect(
        matchedLocation: AppConstants.onboarding,
        box: box,
      );

      expect(result, isNull);
    });

    test('should redirect from /capture when not completed', () async {
      final result = await handleRedirect(
        matchedLocation: '/capture',
        box: box,
      );

      expect(result, AppConstants.onboarding);
    });

    test('should redirect from /settings when not completed', () async {
      final result = await handleRedirect(
        matchedLocation: '/settings',
        box: box,
      );

      expect(result, AppConstants.onboarding);
    });

    test('should return null when completed=true and on /knowledge', () async {
      await box.put('onboarding_completed', true);

      final result = await handleRedirect(
        matchedLocation: '/knowledge',
        box: box,
      );

      expect(result, isNull);
    });
  });

  group('AppConstants.onboarding', () {
    test('should equal /onboarding', () {
      expect(AppConstants.onboarding, '/onboarding');
    });
  });
}
