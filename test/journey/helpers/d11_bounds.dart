import 'package:flutter/foundation.dart';

/// Enforces D-11 character bounds (300-500 chars) on raw GLM output.
///
/// This is test-harness enforcement only -- it does NOT modify product code.
/// - Empty output throws [StateError] per D-04 stop-on-error.
/// - Output exceeding 500 chars is truncated at the last sentence boundary
///   within the first 500 characters.
/// - Output below 300 chars is accepted with a warning (lower bound is advisory).
/// - Output within 300-500 chars is returned as-is.
String enforceD11Bounds(String rawOutput) {
  if (rawOutput.isEmpty) {
    throw StateError('Empty GLM output -- D-04 stop-on-error');
  }

  if (rawOutput.length > 500) {
    // Find the last sentence boundary within the first 500 characters.
    const boundaryChars = ['。', '！', '？', '.', '!', '?', '\n'];
    int lastBoundary = -1;
    for (var i = 0; i < rawOutput.length && i < 500; i++) {
      if (boundaryChars.contains(rawOutput[i])) {
        lastBoundary = i;
      }
    }

    final String result;
    if (lastBoundary >= 0 && lastBoundary < 500) {
      // Truncate just past the boundary character.
      result = rawOutput.substring(0, lastBoundary + 1);
    } else {
      // No sentence boundary found -- hard-truncate and append ellipsis.
      result = '${rawOutput.substring(0, 497)}...';
    }

    debugPrint(
      '[D-11] Chapter output truncated: ${rawOutput.length} -> ${result.length} chars',
    );
    return result;
  }

  if (rawOutput.length < 300) {
    debugPrint(
      '[D-11] Chapter output below lower bound: ${rawOutput.length} chars (min 300)',
    );
  }

  return rawOutput;
}
