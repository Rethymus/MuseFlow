/// Test configuration for the README golden screenshots.
///
/// Goldens in this directory are regenerated on Windows workstations but
/// asserted in CI on Linux. Skia rasterizes text with per-platform
/// subpixel antialiasing, so bit-identical goldens are impossible across
/// OSes even when every glyph, color and layout rect is unchanged
/// (measured drift: 0.5–2.3% of pixels, all along text/icon edges).
///
/// This comparator widens the pixel-diff budget to 3.5% **only** for this
/// directory's marketing screenshots — a real regression (changed layout,
/// colors, content) dwarfs 3.5% of a 1440×1000 frame, while rasterization
/// noise stays well below it. All other golden tests keep the default
/// strict comparison.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// Maximum fraction of differing pixels tolerated for README goldens.
const double _kMaxDiffFraction = 0.035;

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
        'README golden "$golden" passed with ${diffPercent.toStringAsFixed(2)}% '
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
      'cross-platform tolerance for README goldens.',
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
/// fonts (MaterialIcons, CupertinoIcons) included. Without this, golden
/// renders show tofu boxes wherever `Icon(...)` appears, because `flutter
/// test` does not auto-register package icon fonts.
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
