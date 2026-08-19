/// Semantic color helpers on the Apple palette for domain-specific UI:
/// diff/provenance rendering, AI-scent score ramps, and context anchors.
///
/// These map product semantics (insert/delete, score quality, anchors) onto
/// iOS system colors so feature code never hardcodes hex values.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Diff sentence backgrounds and strokes (accept/reject bar included).
extension AppDiffColors on AppPalette {
  /// Background tint for deleted text spans.
  Color get diffDeletionBg => systemRed.withValues(alpha: 0.16);

  /// Background tint for inserted text spans.
  Color get diffInsertionBg => systemGreen.withValues(alpha: 0.16);

  /// Strikethrough color for deleted spans.
  Color get diffStrike => systemRed;

  /// Accept action tint.
  Color get diffAccept => systemGreen;

  /// Reject action tint.
  Color get diffReject => systemRed;
}

/// AI-scent / style score (0–100, higher = more AI-flavored) → Apple ramp.
///
/// green (<25) → yellow (<50) → orange (<75) → red.
Color qualityScoreColor(int score) {
  if (score < 25) return const Color(0xFF34C759); // systemGreen
  if (score < 50) return const Color(0xFFFFCC00); // systemYellow
  if (score < 75) return const Color(0xFFFF9500); // systemOrange
  return const Color(0xFFFF3B30); // systemRed
}

/// Deviation ratio (0..1, higher = more deviation) → Apple ramp.
Color deviationColor(double deviation) {
  if (deviation < 0.2) return const Color(0xFF34C759);
  if (deviation < 0.4) return const Color(0xFFFFCC00);
  if (deviation < 0.6) return const Color(0xFFFF9500);
  return const Color(0xFFFF3B30);
}

/// Context-anchor golden tint (product signature: 金色锚点) on systemYellow.
abstract final class AppAnchorColors {
  static const Color persistent = Color(0x1AFFC400);
  static const Color oneTime = Color(0x0DFFC400);
  static const Color icon = Color(0x99FFC400);
}
