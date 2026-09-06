/// Light/dark golden PAIRS (roadmap C3): every surface below is rendered
/// in BOTH brightnesses so a single-mode regression cannot slip in.
///
/// 1. `settings-light` pairs with the existing dark README golden (#19).
/// 2. `chrome-glass-{light,dark}` pins the core material-system claim:
///    a glass [AppSidebar] floating over REAL backdrop content (color
///    stripes) must show that content blurred through the tint — the
///    "毛玻璃随背后的界面内容产生层次" contract, verified at the pixel
///    level instead of by prose.
///
/// Regenerate:
///   flutter test test/shared/theme/theme_pair_goldens_test.dart --update-goldens
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/domain/creativity_level.dart';
import 'package:museflow/features/settings/presentation/settings_page.dart';
import 'package:museflow/shared/theme/app_colors.dart';
import 'package:museflow/shared/theme/app_theme.dart';
import 'package:museflow/shared/widgets/app_sidebar.dart';
import 'package:museflow/shared/widgets/app_tab_bar.dart';

void main() {
  setUpAll(() async {
    final bytes = await File(
      'test_assets/noto_sans_sc_subset.ttf',
    ).readAsBytes();
    final loader = FontLoader('Noto Sans CJK SC');
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  });

  for (final brightness in Brightness.values) {
    final name = brightness == Brightness.dark ? 'dark' : 'light';

    testWidgets('settings page pair [$name]', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            autoDeviationCheckProvider.overrideWith(
              () => _SeededAutoDeviationNotifier(false),
            ),
            creativityLevelProvider.overrideWith(
              () => _SeededCreativityNotifier(CreativityLevel.balanced),
            ),
            reduceTransparencyProvider.overrideWith(
              () => _SeededReduceTransparencyNotifier(false),
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: appTheme(brightness),
            home: const SettingsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('设置'), findsOneWidget);
      await expectLater(
        find.byType(SettingsPage),
        matchesGoldenFile('goldens/settings-$name.png'),
      );
    });

    testWidgets('glass chrome samples backdrop content [$name]', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: appTheme(brightness),
          home: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                // High-frequency backdrop: alternating saturated stripes.
                // If the sidebar's BackdropFilter ever stops sampling, the
                // golden diff collapses to a flat tint and the pair test
                // fails on the next regeneration.
                const _StripedBackdrop(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppSidebar(
                    selectedIndex: 1,
                    destinations: const [
                      AppSidebarDestination(
                        icon: Icons.bolt_outlined,
                        label: '灵感捕捉',
                      ),
                      AppSidebarDestination(
                        icon: Icons.book_outlined,
                        label: '文稿库',
                      ),
                      AppSidebarDestination(
                        icon: Icons.folder_outlined,
                        label: '知识库',
                      ),
                    ],
                    onDestinationSelected: (_) {},
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AppTabBar(
                    selectedIndex: 0,
                    destinations: const [
                      AppSidebarDestination(
                        icon: Icons.bolt_outlined,
                        label: '捕捉',
                      ),
                      AppSidebarDestination(
                        icon: Icons.book_outlined,
                        label: '文稿',
                      ),
                      AppSidebarDestination(
                        icon: Icons.folder_outlined,
                        label: '知识',
                      ),
                    ],
                    onDestinationSelected: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/chrome-glass-$name.png'),
      );
    });
  }
}

/// Alternating saturated stripes + white gaps: maximal spatial frequency
/// for the blur to average, so the frosted panels visibly tint rather
/// than sit on a void.
class _StripedBackdrop extends StatelessWidget {
  const _StripedBackdrop();

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return CustomPaint(
      size: Size.infinite,
      painter: _StripesPainter(base: p.groupedBackground),
    );
  }
}

class _StripesPainter extends CustomPainter {
  _StripesPainter({required this.base});

  final Color base;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    const colors = [
      Color(0xFFFF9F0A),
      Color(0xFF30D158),
      Color(0xFF0A84FF),
      Color(0xFFBF5AF2),
    ];
    const stripeHeight = 48.0;
    for (var i = 0; i * stripeHeight < size.height; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight / 2),
        Paint()..color = colors[i % colors.length],
      );
    }
  }

  @override
  bool shouldRepaint(_StripesPainter oldDelegate) => oldDelegate.base != base;
}

class _SeededAutoDeviationNotifier extends AutoDeviationCheckNotifier {
  _SeededAutoDeviationNotifier(this._value);

  final bool _value;

  @override
  bool build() => _value;
}

class _SeededCreativityNotifier extends CreativityLevelNotifier {
  _SeededCreativityNotifier(this._value);

  final CreativityLevel _value;

  @override
  CreativityLevel build() => _value;
}

class _SeededReduceTransparencyNotifier extends ReduceTransparencyNotifier {
  _SeededReduceTransparencyNotifier(this._value);

  final bool _value;

  @override
  bool build() => _value;
}
