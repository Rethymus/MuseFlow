/// Real widget screenshot generator for the README ai-organization image (#03).
///
/// Renders the **actual** [CapturePage] with the [SynthesisPanel] overlay showing
/// a completed AI-organized draft: the "AI 整理把碎片组织成结构化草稿" view.
///
/// `captureProvider` is seeded with fragments (the panel overlays the capture
/// page). `synthesisProvider` is seeded with `accumulatedText` (the synthesized
/// draft) + `isEditing: true`, which makes CapturePage show the panel
/// (`showPanel = isStreaming || isEditing || error`) and makes SynthesisPanel's
/// `_buildContentArea` render the editable draft TextField (the
/// `isEditing || accumulatedText.isNotEmpty` branch).
///
/// The TextField is not autofocus → no blinking cursor → no cursor flake. The
/// panel's AnimatedContainer (250ms) is at its final state after pumpAndSettle.
///
/// CapturePage is body-only (hosted by AppShellScaffold's Scaffold in the real
/// app), so the test wraps it in `Scaffold(body:)` (mirrors #02).
///
/// Shares the bundled universal GB2312 subset `test_assets/noto_sans_sc_subset.ttf`.
///
/// Regenerate after changing the page or seed data:
///   flutter test test/readme_screenshots/ai_organization_test.dart --update-goldens
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/features/ai/presentation/synthesis_notifier.dart';
import 'package:museflow/features/capture/presentation/capture_page.dart';
import 'package:museflow/features/capture/presentation/capture_provider.dart';

void main() {
  setUpAll(() async {
    final bytes = await File('test_assets/noto_sans_sc_subset.ttf').readAsBytes();
    final loader = FontLoader('Noto Sans CJK SC');
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  });

  testWidgets('CapturePage + SynthesisPanel renders a real 1440x1000 screenshot',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          captureProvider.overrideWith(() => _SeededCaptureNotifier()),
          synthesisProvider.overrideWith(() => _SeededSynthesisNotifier()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _screenshotTheme(),
          home: const Scaffold(body: CapturePage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Prove the synthesis panel + editable draft rendered: the 'AI 整理' header
    // (a Text widget) is present, and the editing TextField branch rendered.
    // (find.text cannot see text inside a TextField's controller — the draft is
    // rendered in the editing TextField via _editController sync, captured by the
    // golden even though not assertable via find.text.)
    expect(find.text('AI 整理'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);

    await expectLater(
      find.byType(CapturePage),
      matchesGoldenFile('../../docs/readme/screenshots/03-ai-organization.png'),
    );
  });
}

/// Seeded SynthesisNotifier returning a completed, editable draft (isEditing).
class _SeededSynthesisNotifier extends SynthesisNotifier {
  @override
  SynthesisState build() => const SynthesisState(
        accumulatedText: _synthesizedDraft,
        isEditing: true,
      );
}

const String _synthesizedDraft = '''林风独立于青云峰巅，脚下云海翻涌如潮。

山门前那声古剑低鸣仍在耳畔回荡——他抬手，断裂的剑印在掌心微微发烫，仿佛回应着什么遥远的召唤。苏雪晴留下的药香线索指向雾海禁地，而第八十章前必须揭开的弃剑峰旧约，正与他血脉中的剑印遥相呼应。

问心石阶只认断裂剑印。他终于明白，这条路从一开始就没有退路。''';

/// Seeded CaptureNotifier (mirrors #02) — 6 fragments, 4 selected. The panel
/// overlays the capture page; the left fragment list peeks behind it.
class _SeededCaptureNotifier extends CaptureNotifier {
  @override
  CaptureState build() {
    final now = DateTime(2026, 6, 22, 22, 40);
    final fragments = <Fragment>[
      Fragment(
        id: 'f1',
        text: '林风在山门前听见古剑低鸣',
        tags: const ['故事'],
        createdAt: now.subtract(const Duration(hours: 2, minutes: 8)),
      ),
      Fragment(
        id: 'f2',
        text: '苏雪晴用药香留下禁地线索',
        tags: const ['故事'],
        createdAt: now.subtract(const Duration(hours: 2, minutes: 14)),
      ),
      Fragment(
        id: 'f3',
        text: '第八十章前揭开弃剑峰旧约',
        tags: const ['章节'],
        createdAt: now.subtract(const Duration(hours: 2, minutes: 20)),
      ),
      Fragment(
        id: 'f4',
        text: '问心石阶只回应断裂剑印',
        tags: const ['场景'],
        createdAt: now.subtract(const Duration(hours: 2, minutes: 28)),
      ),
      Fragment(
        id: 'f5',
        text: '雾海裂隙深处藏着旧宗主令',
        tags: const ['场景'],
        createdAt: now.subtract(const Duration(hours: 1, minutes: 50)),
      ),
    ];
    return CaptureState(
      fragments: fragments,
      selectedIds: const {'f1', 'f2', 'f3', 'f4'},
      activeFilter: '全部',
      isLoading: false,
    );
  }
}

ThemeData _screenshotTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    brightness: Brightness.dark,
  );
  final base = Typography.material2021().white.apply(fontFamily: 'Noto Sans CJK SC');
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    textTheme: base.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
  );
}
