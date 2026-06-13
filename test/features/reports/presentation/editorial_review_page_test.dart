/// Widget tests for EditorialReviewPage — verifies the UI layer renders
/// (chapter selector, 4 dimension cards, scores, review button) without
/// needing a live browser.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';
import 'package:museflow/features/reports/domain/editorial_review.dart';
import 'package:museflow/features/reports/presentation/editorial_review_page.dart';
import 'package:museflow/features/reports/providers.dart';

EditorialReview _sampleReview() => EditorialReview(dimensions: [
      DimensionReview(
          dimension: ReviewDimension.plot,
          score: 82,
          strengths: '伏笔清晰',
          weaknesses: '转折略快',
          suggestions: '放缓'),
      DimensionReview(
          dimension: ReviewDimension.character,
          score: 75,
          strengths: '动机合理',
          weaknesses: '配角扁平',
          suggestions: '补背景'),
      DimensionReview(
          dimension: ReviewDimension.prose,
          score: 80,
          strengths: '描写细腻',
          weaknesses: '偶有堆砌',
          suggestions: '删形容词'),
      DimensionReview(
          dimension: ReviewDimension.pacing,
          score: 70,
          strengths: '张弛有度',
          weaknesses: '中段拖沓',
          suggestions: '删冗余'),
    ]);

Chapter _chapter({required String id, required String title, required int order}) {
  return Chapter(
    id: id,
    manuscriptId: 'm1',
    title: title,
    sortOrder: order,
    documentContent: '这是章节 $title 的正文内容，用于评审。',
    createdAt: DateTime(2026, 1, order),
    updatedAt: DateTime(2026, 1, order),
  );
}

void main() {
  testWidgets(
    'renders chapter selector, 4 dimension cards, overall score, and review button',
    (tester) async {
      // Tall viewport so the lazy ListView builds all 4 dimension cards.
      await tester.binding.setSurfaceSize(const Size(800, 2400));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chapterRepositoryProvider.overrideWith(
              (ref) async => _FakeChapterRepo([
                _chapter(id: 'c1', title: '第一章 山门问心', order: 1),
                _chapter(id: 'c2', title: '第二章 断印微光', order: 2),
              ]),
            ),
            editorialReviewProvider.overrideWith(
              () => _StaticReviewNotifier(_sampleReview()),
            ),
          ],
          child: const MaterialApp(home: EditorialReviewPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('编辑评审团'), findsOneWidget);
      // Chapter selector populated with first chapter
      expect(find.textContaining('第一章'), findsWidgets);
      // Overall score card
      expect(find.text('综合评分'), findsOneWidget);
      // All 4 dimension labels render
      expect(find.text('情节'), findsOneWidget);
      expect(find.text('人物'), findsOneWidget);
      expect(find.text('文笔'), findsOneWidget);
      expect(find.text('节奏'), findsOneWidget);
      // Strength text from a dimension renders
      expect(find.textContaining('伏笔清晰'), findsOneWidget);
      // Review action button
      expect(find.text('开始评审'), findsOneWidget);
    },
  );

  testWidgets('shows empty state when there are no chapters', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chapterRepositoryProvider.overrideWith(
            (ref) async => _FakeChapterRepo([]),
          ),
          editorialReviewProvider.overrideWith(
            () => _StaticReviewNotifier(null),
          ),
        ],
        child: const MaterialApp(home: EditorialReviewPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('暂无章节'), findsOneWidget);
  });
}

class _StaticReviewNotifier extends EditorialReviewNotifier {
  _StaticReviewNotifier(this.initial);
  final EditorialReview? initial;
  @override
  Future<EditorialReview?> build() async => initial;
}

class _FakeChapterRepo extends ChapterRepository {
  _FakeChapterRepo(this._chapters) : super(_FakeBox());
  final List<Chapter> _chapters;
  @override
  List<Chapter> getAll() => _chapters;
}

class _FakeBox implements Box<dynamic> {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
