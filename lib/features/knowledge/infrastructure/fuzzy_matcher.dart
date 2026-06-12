/// Fuzzy string matcher using Damerau-Levenshtein distance.
///
/// Supports fuzzy matching of entity names against text for Phase 20
/// (KNOW-01). Handles typos like "林锋" matching "林风" with edit
/// distance ≤ 2.
///
/// Uses optimal string alignment distance (restricted Damerau-Levenshtein)
/// which supports insertion, deletion, substitution, and transposition of
/// adjacent characters — the most common typos in Chinese text.
library;

import 'dart:math' as math;

/// Result of a fuzzy match against a candidate.
class FuzzyResult {
  /// The candidate string that was matched.
  final String candidate;

  /// The edit distance between the query and candidate.
  final int distance;

  /// The position in the source text where the match was found.
  final int position;

  /// The length of the matched text in the source.
  final int length;

  const FuzzyResult({
    required this.candidate,
    required this.distance,
    required this.position,
    required this.length,
  });

  @override
  String toString() =>
      'FuzzyResult(candidate: $candidate, distance: $distance, '
      'position: $position, length: $length)';
}

/// Fuzzy matcher with configurable maximum edit distance.
///
/// Provides three matching modes:
/// - [distance]: Compute edit distance between two strings
/// - [isMatch]: Check if two strings match within max distance
/// - [findFuzzyMatches]: Scan text for fuzzy matches against candidates
/// - [findBestMatch]: Find the single best matching candidate for a query
class FuzzyMatcher {
  /// Maximum edit distance for a match to be considered valid.
  final int maxDistance;

  /// Creates a fuzzy matcher with the given [maxDistance].
  ///
  /// Default [maxDistance] of 2 handles common typos:
  /// - Single character substitution: 林风→林锋
  /// - Single character insertion: 林风→林大风
  /// - Transposition: 风林→林风
  /// - Two adjacent errors: 林风云→林锋云
  const FuzzyMatcher({this.maxDistance = 2});

  /// Computes the Damerau-Levenshtein (optimal string alignment) distance
  /// between [source] and [target].
  ///
  /// Supports four operations:
  /// - Insertion (cost 1)
  /// - Deletion (cost 1)
  /// - Substitution (cost 1)
  /// - Transposition of adjacent characters (cost 1)
  int distance(String source, String target) {
    final sLen = source.length;
    final tLen = target.length;

    // Quick paths for empty strings
    if (sLen == 0) return tLen;
    if (tLen == 0) return sLen;

    // Quick path: if length difference exceeds maxDistance, we know
    // the edit distance is at least that difference.
    final lenDiff = (sLen - tLen).abs();
    if (lenDiff > maxDistance && maxDistance != 0) {
      // Fall through to compute exact distance for correctness
    }

    // Use optimal string alignment (restricted Damerau-Levenshtein)
    // dp[i][j] = edit distance between source[0..i) and target[0..j)
    final dp = List.generate(sLen + 1, (i) => List.filled(tLen + 1, 0));

    for (var i = 0; i <= sLen; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= tLen; j++) {
      dp[0][j] = j;
    }

    for (var i = 1; i <= sLen; i++) {
      for (var j = 1; j <= tLen; j++) {
        final cost = source[i - 1] == target[j - 1] ? 0 : 1;

        dp[i][j] = math.min(
          dp[i - 1][j] + 1, // deletion
          math.min(
            dp[i][j - 1] + 1, // insertion
            dp[i - 1][j - 1] + cost, // substitution
          ),
        );

        // Transposition: if characters are swapped
        if (i > 1 &&
            j > 1 &&
            source[i - 1] == target[j - 2] &&
            source[i - 2] == target[j - 1]) {
          dp[i][j] = math.min(dp[i][j], dp[i - 2][j - 2] + cost);
        }
      }
    }

    return dp[sLen][tLen];
  }

  /// Checks if [source] and [target] match within [maxDistance].
  bool isMatch(String source, String target) {
    return distance(source, target) <= maxDistance;
  }

  /// Finds all fuzzy matches of [candidates] within [text].
  ///
  /// Slides a window of each candidate's length across the text and
  /// checks if any substring matches within [maxDistance].
  ///
  /// Uses a minimum similarity guard: requires at least one character
  /// to match (distance < max(source, target) length) to prevent
  /// trivial matches between short unrelated strings.
  ///
  /// Results are sorted by distance (best match first).
  /// Returns empty list if [text] or [candidates] is empty.
  List<FuzzyResult> findFuzzyMatches({
    required String text,
    required List<String> candidates,
  }) {
    if (text.isEmpty || candidates.isEmpty) return const [];

    // Deduplicate candidates to avoid redundant scanning
    final seen = <String>{};
    final uniqueCandidates = <String>[];
    for (final c in candidates) {
      final trimmed = c.trim();
      if (trimmed.length >= 2 && seen.add(trimmed)) {
        uniqueCandidates.add(trimmed);
      }
    }
    if (uniqueCandidates.isEmpty) return const [];

    final textLen = text.length;

    // Use a map to keep only the best match per (position, candidate) pair.
    // Key: 'pos\x00candidate', Value: best FuzzyResult so far.
    final bestAt = <String, FuzzyResult>{};

    for (final candidate in uniqueCandidates) {
      final candLen = candidate.length;

      // Scan text with windows around candidate length ±maxDistance.
      // Iterate from longest to shortest so exact matches are found first
      // and shorter (inferior) window matches don't override them.
      final minLen = (candLen - maxDistance).clamp(2, textLen);
      final maxLen = (candLen + maxDistance).clamp(minLen, textLen);

      for (var winLen = maxLen; winLen >= minLen; winLen--) {
        for (var pos = 0; pos <= textLen - winLen; pos++) {
          final key = '$pos\x00$candidate';
          final existing = bestAt[key];
          if (existing != null && existing.distance == 0) continue;

          final substring = text.substring(pos, pos + winLen);
          final dist = distance(substring, candidate);
          if (dist <= maxDistance) {
            // Reject trivial matches: require at least one char in common
            final maxPossible = math.max(substring.length, candLen);
            if (dist >= maxPossible) continue;

            // Only keep if this is better than existing match at this position
            if (existing == null || dist < existing.distance) {
              bestAt[key] = FuzzyResult(
                candidate: candidate,
                distance: dist,
                position: pos,
                length: winLen,
              );
            }
          }
        }
      }
    }

    final results = bestAt.values.toList();

    // Sort by distance (best first), then by position
    results.sort((a, b) {
      final byDist = a.distance.compareTo(b.distance);
      if (byDist != 0) return byDist;
      return a.position.compareTo(b.position);
    });

    // Deduplicate: keep only the best match per candidate entity.
    // For name matching, we care about which entities are mentioned,
    // not every possible position.
    final seenCandidates = <String>{};
    final deduped = <FuzzyResult>[];
    for (final r in results) {
      if (seenCandidates.add(r.candidate)) {
        deduped.add(r);
      }
    }

    return deduped;
  }

  /// Finds the single best matching candidate for a [query].
  ///
  /// Compares the full [query] string directly against each candidate
  /// (no window scanning). Returns null if no candidate matches within
  /// [maxDistance] with at least one character in common.
  FuzzyResult? findBestMatch({
    required String query,
    required List<String> candidates,
  }) {
    if (query.trim().length < 2 || candidates.isEmpty) return null;

    FuzzyResult? best;
    var bestDistance = maxDistance + 1;

    for (final candidate in candidates) {
      final trimmed = candidate.trim();
      if (trimmed.length < 2) continue;

      final maxPossible = math.max(query.length, trimmed.length);
      final dist = distance(query, trimmed);
      // Reject trivial matches: require at least one char in common
      if (dist < bestDistance && dist < maxPossible) {
        bestDistance = dist;
        best = FuzzyResult(
          candidate: trimmed,
          distance: dist,
          position: 0,
          length: query.length,
        );
      }
    }

    return best;
  }
}
