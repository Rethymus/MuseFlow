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

    await tester.scrollUntilVisible(find.text('清除写作统计'), 100.0);
    await tester.tap(find.text('清除写作统计'));
    await tester.pump();
    expect(find.text('清除写作统计？'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pump();
    expect(clearCount, 0);

    await tester.scrollUntilVisible(find.text('清除写作统计'), 100.0);
    await tester.tap(find.text('清除写作统计'));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, '清除'));
    await tester.pump();

    expect(clearCount, 1);
    expect(find.text('写作统计已清除'), findsOneWidget);
  });

  testWidgets(
    'creativity SegmentedButton renders without overflow on narrow Android viewport',
    (tester) async {
      // 360×640 logical at 2x dpr = 720×1280 physical (typical Android phone).
      // Verifies the AA-03 creativity control does not horizontally overflow
      // on the project's first-class Android target (ECC review MEDIUM #2).
      tester.view.devicePixelRatio = 2.0;
      tester.view.physicalSize = const Size(720, 1280);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: SettingsPage())),
      );

      // The creativity control (标题 + 保守/平衡/灵动 三档) must render
      // without a RenderFlex overflow exception at 360dp width.
      expect(find.text('创意度'), findsOneWidget);
      expect(find.text('保守'), findsOneWidget);
      expect(find.text('平衡'), findsOneWidget);
      expect(find.text('灵动'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
