import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';

class ManuscriptFixtures {
  static final DateTime _fixedDate = DateTime(2026, 1, 1);

  static Manuscript xianxiaManuscript({String? id}) {
    return Manuscript(
      id: id ?? 'ms-test-001',
      title: '剑道苍穹',
      description: '自动化测试用修仙文稿',
      genre: '修仙',
      targetWordCount: 100000,
      status: '写作中',
      createdAt: _fixedDate,
      updatedAt: _fixedDate,
      coverLetter: '剑',
    );
  }

  static Chapter chapter({
    required String manuscriptId,
    required int number,
    String? content,
  }) {
    return Chapter(
      id: 'ch-$number',
      manuscriptId: manuscriptId,
      title: '第$number章',
      sortOrder: number,
      status: '草稿',
      documentContent: content ?? '',
      createdAt: _fixedDate,
      updatedAt: _fixedDate,
    );
  }
}
