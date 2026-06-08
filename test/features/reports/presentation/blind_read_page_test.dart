import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/reports/domain/blind_read_result.dart';
import 'package:museflow/features/reports/presentation/blind_read_page.dart';
import 'package:museflow/features/reports/providers.dart';

void main() {
  group('BlindReadPage', () {
    testWidgets('should show start button when no evaluation started', (tester) async {
      await tester.pumpWidget(_wrap(const BlindReadPage()));

      expect(find.text('开始盲读'), findsOneWidget);
      expect(find.text('需要先完成章节创作才能进行盲读测试。'), findsOneWidget);
    });

    testWidgets('should show instruction text and progress during evaluation', (tester) async {
      await tester.pumpWidget(_wrap(const BlindReadPage(), state: _evaluatingState()));

      expect(find.text('下方段落来自你的100章创作。请逐段判断：这是 AI 生成的，还是人写的？'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('第 1 / 2 段'), findsOneWidget);
    });

    testWidgets('should show excerpt card with text and chapter index', (tester) async {
      await tester.pumpWidget(_wrap(const BlindReadPage(), state: _evaluatingState()));

      expect(find.text('这是一段用于盲读测试的章节内容。'), findsOneWidget);
      expect(find.text('第3章'), findsOneWidget);
    });

    testWidgets('should render three verdict buttons', (tester) async {
      await tester.pumpWidget(_wrap(const BlindReadPage(), state: _evaluatingState()));

      expect(find.widgetWithText(FilledButton, 'AI 生成'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, '人写的'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '跳过'), findsOneWidget);
    });

    testWidgets('should show result summary after evaluation completes', (tester) async {
      final result = BlindReadResult(
        excerpts: [_excerpt(verdict: true), _excerpt(verdict: false)],
        correctCount: 1,
      );
      await tester.pumpWidget(
        _wrap(const BlindReadPage(), state: BlindReadState(excerpts: result.excerpts, result: result)),
      );

      expect(find.text('盲读辨识率：50%'), findsOneWidget);
      expect(find.text('你判断了 2 段，其中 1 段判断正确。'), findsOneWidget);
      expect(find.text('AI 内容有一定可辨识性。'), findsOneWidget);
    });

    testWidgets('should show export button in app bar', (tester) async {
      final result = BlindReadResult(excerpts: [_excerpt(verdict: true)], correctCount: 1);
      await tester.pumpWidget(
        _wrap(const BlindReadPage(), state: BlindReadState(excerpts: result.excerpts, result: result)),
      );

      expect(find.byIcon(Icons.download_outlined), findsOneWidget);
    });
  });
}

Widget _wrap(Widget child, {BlindReadState state = const BlindReadState()}) {
  return ProviderScope(
    overrides: [blindReadProvider.overrideWith(() => _FakeBlindReadNotifier(state))],
    child: MaterialApp(home: child),
  );
}

BlindReadState _evaluatingState() {
  return BlindReadState(excerpts: [_excerpt(), _excerpt(chapterIndex: 4)]);
}

BlindReadExcerpt _excerpt({int chapterIndex = 3, bool? verdict}) {
  return BlindReadExcerpt(
    text: '这是一段用于盲读测试的章节内容。',
    chapterId: 'c$chapterIndex',
    chapterIndex: chapterIndex,
    humanVerdict: verdict,
  );
}

class _FakeBlindReadNotifier extends BlindReadNotifier {
  _FakeBlindReadNotifier(this.initialState);

  final BlindReadState initialState;

  @override
  BlindReadState build() => initialState;

  @override
  Future<void> startEvaluation({String? manuscriptId}) async {}
}
