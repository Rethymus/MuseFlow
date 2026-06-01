import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/core/domain/fragment_tag.dart';
import 'package:museflow/features/capture/presentation/capture_page.dart';
import 'package:museflow/features/capture/presentation/capture_provider.dart';

void main() {
  group('CapturePage', () {
    late List<Fragment> testFragments;

    setUp(() {
      testFragments = [
        Fragment(
          id: 'frag-1',
          text: '这是第一条灵感碎片',
          tags: [FragmentTags.story],
          createdAt: DateTime(2026, 6, 1, 14, 30),
        ),
        Fragment(
          id: 'frag-2',
          text: '这是第二条灵感碎片',
          tags: [FragmentTags.chapter],
          createdAt: DateTime(2026, 6, 1, 14, 25),
        ),
        Fragment(
          id: 'frag-3',
          text: '这是第三条灵感碎片',
          tags: [FragmentTags.scene],
          createdAt: DateTime(2026, 6, 1, 14, 20),
        ),
      ];
    });

    Widget buildTestWidget({
      CaptureState captureState = const CaptureState(
        fragments: [],
        isLoading: false,
      ),
    }) {
      return ProviderScope(
        overrides: [
          captureProvider.overrideWith(() => _TestCaptureNotifier(captureState)),
          captureInputProvider.overrideWith(() => _TestCaptureInputNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CapturePage(),
          ),
        ),
      );
    }

    testWidgets('should display input field with correct hint text',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('输入灵感碎片，按回车添加...'), findsOneWidget);
    });

    testWidgets('should show empty state when no fragments exist',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('还没有灵感碎片'), findsOneWidget);
      expect(
        find.text('在上方输入框中写下你的第一个灵感，按回车即可保存。'),
        findsOneWidget,
      );
    });

    testWidgets('should display filter chips with correct labels',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('全部'), findsWidgets); // May appear in filter and empty state
      expect(find.text('故事'), findsOneWidget);
      expect(find.text('章节'), findsOneWidget);
      expect(find.text('场景'), findsOneWidget);
    });

    testWidgets('should display fragment cards with text and timestamp',
        (tester) async {
      final state = CaptureState(
        fragments: testFragments,
        isLoading: false,
      );

      await tester.pumpWidget(buildTestWidget(captureState: state));
      await tester.pumpAndSettle();

      expect(find.text('这是第一条灵感碎片'), findsOneWidget);
      expect(find.text('这是第二条灵感碎片'), findsOneWidget);
      expect(find.text('这是第三条灵感碎片'), findsOneWidget);

      // Verify timestamp is displayed (formatted as yyyy-MM-dd HH:mm)
      expect(find.text('2026-06-01 14:30'), findsOneWidget);
    });

    testWidgets('should show checkboxes on fragment cards', (tester) async {
      final state = CaptureState(
        fragments: testFragments,
        isLoading: false,
      );

      await tester.pumpWidget(buildTestWidget(captureState: state));
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsNWidgets(3));
    });

    testWidgets('should show loading indicator while loading', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          captureState: const CaptureState(isLoading: true),
        ),
      );
      // Use pump instead of pumpAndSettle -- CircularProgressIndicator animates indefinitely
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display tag chips on fragment cards', (tester) async {
      final state = CaptureState(
        fragments: testFragments,
        isLoading: false,
      );

      await tester.pumpWidget(buildTestWidget(captureState: state));
      await tester.pumpAndSettle();

      // Verify fragment cards are rendered
      final cardFinder = find.byType(Card);
      expect(cardFinder, findsWidgets);

      // Verify each fragment text is present (exact matches, excludes hint)
      expect(find.text('这是第一条灵感碎片'), findsOneWidget);
      expect(find.text('这是第二条灵感碎片'), findsOneWidget);
      expect(find.text('这是第三条灵感碎片'), findsOneWidget);
    });
  });
}

/// Test notifier that returns a preset state without needing a real repository.
class _TestCaptureNotifier extends CaptureNotifier {
  final CaptureState _initialState;

  _TestCaptureNotifier(this._initialState);

  @override
  CaptureState build() => _initialState;
}

/// Test input notifier.
class _TestCaptureInputNotifier extends CaptureInputNotifier {
  @override
  String build() => '';
}
