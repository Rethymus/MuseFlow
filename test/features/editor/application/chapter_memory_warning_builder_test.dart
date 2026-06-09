import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/application/chapter_memory_warning_builder.dart';

void main() {
  group('ChapterMemoryWarningBuilder', () {
    const builder = ChapterMemoryWarningBuilder();

    test('should return warning when previous summary is stale', () {
      final warning = builder.buildWarning(
        summary: '林风在灵溪禁地拾起青铜玉简，苏雪晴发现玉简上有玄鸟印记。',
        adjacentChapterText: '林风回到青云宗演武场，赵天磊逼他当众比剑，清虚真人在旁观战。',
        direction: ChapterMemoryDirection.previous,
      );

      expect(warning, isNotNull);
      expect(warning, contains('上一章'));
      expect(warning, contains('重合度'));
      expect(warning, contains('灵溪'));
      expect(warning, contains('复查'));
    });

    test('should return warning when next summary is stale', () {
      final warning = builder.buildWarning(
        summary: '苏雪晴将在寒潭边交出白鹿玉佩，并说明灵溪禁地的门规。',
        adjacentChapterText: '赵天磊带着外门弟子闯入药园，逼林风交出新炼的凝气丹。',
        direction: ChapterMemoryDirection.next,
      );

      expect(warning, isNotNull);
      expect(warning, contains('下一章'));
      expect(warning, contains('寒潭'));
    });

    test('should return null when summary overlaps adjacent chapter text', () {
      final warning = builder.buildWarning(
        summary: '林风在灵溪禁地拾起青铜玉简，苏雪晴发现玉简上有玄鸟印记。',
        adjacentChapterText: '夜色落下，林风在灵溪禁地拾起青铜玉简。苏雪晴发现玉简上有玄鸟印记，提醒他暂时不要告诉赵天磊。',
        direction: ChapterMemoryDirection.previous,
      );

      expect(warning, isNull);
    });

    test('should return null for thin summaries', () {
      final warning = builder.buildWarning(
        summary: '前情。',
        adjacentChapterText: '林风在灵溪禁地拾起青铜玉简。',
        direction: ChapterMemoryDirection.previous,
      );

      expect(warning, isNull);
    });

    test('should return null for empty inputs', () {
      expect(
        builder.buildWarning(
          summary: '',
          adjacentChapterText: '林风在灵溪禁地拾起青铜玉简。',
          direction: ChapterMemoryDirection.previous,
        ),
        isNull,
      );
      expect(
        builder.buildWarning(
          summary: '林风在灵溪禁地拾起青铜玉简。',
          adjacentChapterText: '',
          direction: ChapterMemoryDirection.next,
        ),
        isNull,
      );
    });
  });
}
