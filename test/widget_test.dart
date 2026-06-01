import 'package:flutter_test/flutter_test.dart';

import 'package:museflow/main.dart';

void main() {
  testWidgets('MuseFlow app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MuseFlowApp());

    // Verify the app title is displayed
    expect(find.text('MuseFlow 灵韵'), findsWidgets);
  });
}
