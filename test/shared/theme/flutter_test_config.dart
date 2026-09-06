/// Test configuration for the theme golden pairs in this directory.
///
/// Same policy as `test/readme_screenshots/flutter_test_config.dart`:
/// goldens are regenerated on Windows workstations but asserted in CI on
/// Linux, and Skia's per-platform text antialiasing makes bit-identical
/// renders impossible. Measured cross-platform drift for these frames
/// (CI run 34038238299): 0.32–1.69% of pixels, all along text/icon edges.
///
/// The comparator widens the pixel-diff budget to 2% **only** for this
/// directory — above the measured 1.69% noise ceiling, far below any real
/// regression (a changed layout, color or content step dwarfs 2%). The
/// ambient-canvas subtlety contract is additionally pinned by the
/// quantitative variance tests, not by goldens, so the tolerance cannot
/// mask a glass/surface regression.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// Maximum fraction of differing pixels tolerated for theme goldens.
const double _kMaxDiffFraction = 0.02;

class _TolerantGoldenComparator extends LocalFileComparator {
  _TolerantGoldenComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed) {
      result.dispose();
      return true;
    }

    final diffPercent = result.diffPercent * 100;
    if (diffPercent <= _kMaxDiffFraction * 100) {
      debugPrint(
        'Theme golden "$golden" passed with ${diffPercent.toStringAsFixed(2)}% '
        'cross-platform rasterization noise '
        '(tolerance ${_kMaxDiffFraction * 100}%).',
      );
      result.dispose();
      return true;
    }

    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(
      '$error\n'
      'Diff $diffPercent% exceeded the ${_kMaxDiffFraction * 100}% '
      'cross-platform tolerance for theme goldens.',
    );
  }
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final existing = goldenFileComparator as LocalFileComparator;
  // LocalFileComparator derives its golden-path base from the test file's
  // directory; rebuild the same basedir from the current comparator.
  goldenFileComparator = _TolerantGoldenComparator(
    existing.basedir.resolve('flutter_test_config.dart'),
  );
  await _loadAllBundledFonts();
  await testMain();
}

/// Loads every font declared in the build's FontManifest.json — the icon
/// fonts (MaterialIcons, CupertinoIcons) included — so goldens in this
/// directory render real glyphs instead of tofu boxes.
Future<void> _loadAllBundledFonts() async {
  final manifestContent = await rootBundle.loadString('FontManifest.json');
  final List<dynamic> manifest = jsonDecode(manifestContent) as List<dynamic>;
  for (final font in manifest) {
    final String family = font['family'] as String;
    final loader = FontLoader(family);
    for (final Map<String, dynamic> fontAsset
        in (font['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(fontAsset['asset'] as String));
    }
    await loader.load();
  }
}
