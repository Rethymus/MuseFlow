import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/app.dart';
import 'package:museflow/shared/constants/app_constants.dart';

import '../helpers/hive_test_helper.dart';

void main() {
  group('Token audit route', () {
    setUp(() async {
      await setUpHiveTest();
      final settings = await Hive.openBox<dynamic>('settings');
      await settings.put('onboarding_completed', true);
    });

    tearDown(() async {
      await tearDownHiveTest();
    });

    testWidgets('should render TokenAuditPage when navigating to stats tokens', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: MuseFlowApp()));
      await tester.pump();

      final context = tester.element(find.byType(Scaffold).first);
      GoRouter.of(context).go(AppConstants.statsTokens);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Token 消耗总览'), findsWidgets);
      expect(
        find.text('Token Audit Page - Coming in Plan 03'),
        findsNothing,
      );
    });
  });
}
