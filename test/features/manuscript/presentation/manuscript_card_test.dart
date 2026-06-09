import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/manuscript/presentation/manuscript_card.dart';

void main() {
  final now = DateTime(2026, 6, 6, 12, 0);

  Manuscript testManuscript({
    String title = '测试文稿',
    String genre = '玄幻',
    String status = '写作中',
    int targetWordCount = 50000,
    String coverLetter = '测试',
  }) {
    return Manuscript(
      id: 'm1',
      title: title,
      genre: genre,
      status: status,
      targetWordCount: targetWordCount,
      coverLetter: coverLetter,
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now,
    );
  }

  testWidgets('should render cover letter from manuscript', (tester) async {
    final manuscript = testManuscript(coverLetter: '玄');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ManuscriptCard(manuscript: manuscript, onTap: () {}),
        ),
      ),
    );

    expect(find.text('玄'), findsOneWidget);
  });

  testWidgets('should render manuscript title', (tester) async {
    final manuscript = testManuscript(title: '龙族传说');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ManuscriptCard(manuscript: manuscript, onTap: () {}),
        ),
      ),
    );

    expect(find.text('龙族传说'), findsOneWidget);
  });

  testWidgets('should render progress bar for target word count', (
    tester,
  ) async {
    final manuscript = testManuscript(targetWordCount: 50000);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ManuscriptCard(
            manuscript: manuscript,
            currentWordCount: 12000,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    // Word count label
    expect(find.textContaining('12,000'), findsOneWidget);
    expect(find.textContaining('50,000'), findsOneWidget);
  });

  testWidgets('should render status badge', (tester) async {
    final manuscript = testManuscript(status: '写作中');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ManuscriptCard(manuscript: manuscript, onTap: () {}),
        ),
      ),
    );

    expect(find.text('写作中'), findsOneWidget);
  });

  testWidgets(
    'should use title substring as cover letter when coverLetter is empty',
    (tester) async {
      final manuscript = testManuscript(title: '龙族传说', coverLetter: '');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManuscriptCard(manuscript: manuscript, onTap: () {}),
          ),
        ),
      );

      // Should use first 2 chars of title: "龙族"
      expect(find.text('龙族'), findsOneWidget);
    },
  );
}
