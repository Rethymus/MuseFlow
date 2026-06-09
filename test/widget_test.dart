import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke test renders a Flutter widget', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('MuseFlow 灵韵'))),
      ),
    );

    expect(find.text('MuseFlow 灵韵'), findsOneWidget);
  });
}
