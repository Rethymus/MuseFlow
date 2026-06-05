import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/manuscript/domain/manuscript_genre.dart';

void main() {
  group('ManuscriptGenre', () {
    test(
      'presets contains exactly 14 genres matching Phase 7 template types',
      () {
        expect(ManuscriptGenre.presets.length, 14);
        expect(
          ManuscriptGenre.presets,
          containsAll([
            '玄幻',
            '仙侠',
            '都市',
            '科幻',
            '奇幻',
            '武侠',
            '历史',
            '军事',
            '悬疑',
            '恐怖',
            '言情',
            '校园',
            '游戏',
            '末世',
          ]),
        );
      },
    );

    test('genreColor returns a non-zero color for all presets', () {
      for (final genre in ManuscriptGenre.presets) {
        final color = ManuscriptGenre.genreColor(genre);
        expect(color, isNonZero, reason: 'Genre "$genre" should have a color');
        // Verify it is a valid ARGB color (0xFF prefix)
        expect(color & 0xFF000000, 0xFF000000,
            reason: 'Genre "$genre" color should be opaque (0xFF alpha)');
      }
    });

    test('genreColor returns default gray for unknown genres', () {
      final color = ManuscriptGenre.genreColor('unknown_genre');
      expect(color, 0xFF49454F);
    });

    test('statusValues contains correct manuscript statuses', () {
      expect(
        ManuscriptGenre.statusValues,
        ['构思中', '写作中', '已完成'],
      );
    });

    test('chapterStatusValues contains correct chapter statuses', () {
      expect(
        ManuscriptGenre.chapterStatusValues,
        ['草稿', '初稿', '精修', '定稿'],
      );
    });

    test('all genre colors are visually distinct', () {
      final colors = <int>{};
      for (final genre in ManuscriptGenre.presets) {
        final color = ManuscriptGenre.genreColor(genre);
        colors.add(color);
      }
      // All 14 genres should have distinct colors
      expect(colors.length, 14,
          reason: 'Each genre should have a unique color');
    });
  });
}
