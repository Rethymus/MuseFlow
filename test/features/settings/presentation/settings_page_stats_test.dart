import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/settings/presentation/settings_page.dart';

void main() {
  testWidgets('clear stats tile requires confirmation and clears stats', (
    tester,
  ) async {
    var clearCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SettingsPage(
            debugClearStats: () async {
              clearCount++;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('清除写作统计'));
    await tester.pump();
    expect(find.text('清除写作统计？'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pump();
    expect(clearCount, 0);

    await tester.tap(find.text('清除写作统计'));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, '清除'));
    await tester.pump();

    expect(clearCount, 1);
    expect(find.text('写作统计已清除'), findsOneWidget);
  });
}
