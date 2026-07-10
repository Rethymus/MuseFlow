/// Sentence-level AI-scent analyzer (AA-04).
///
/// The whole-text [StyleDeviationDetector] (Phase 19) reports an aggregate
/// AI-scent score across the author's 5 style dimensions. This analyzer adds
/// *sentence-level* granularity: it splits text into sentences and scores each
/// one 0-100 using sentence-LOCAL signals, so the editor can tell the author
/// *which specific sentences* are most AI-like (SenDetEX, EMNLP 2025;
/// LaTeCHCLfL 2026).
///
/// Signals (each is independent and additive; the whole-text detector cannot
/// use these because rhythm/emotion-curve need multiple sentences):
///   1. **Mechanical transition-word start** (+35): sentence begins with a
///      connector like 然而/此外/综上所述/不仅……而且 — a hallmark of AI prose.
///   2. **AI-tell pattern** (+35): contains a formulaic construction such as
///      不仅…而且, 在这个…的时代, 值得一提的是, 众所周知, 毫无疑问.
///   3. **High function-word ratio** (+35): > 40% of CJK chars are grammatical
///      particles (的/了/是/在/和…) — content-thin, filler-heavy (AI tendency).
///   4. **Run-on** (+30): > 40 CJK chars with no internal 、，； pause — AI
///      tends to produce long unpunctuated runs.
///
/// The editor highlighting UI (mapping scores to text ranges) is deferred to
/// real-device UAT; this class is pure, side-effect-free, and fully testable.
library;

/// A single sentence's AI-scent verdict.
class SentenceAiScentScore {
  /// The scored sentence text (trimmed, non-empty).
  final String sentence;

  /// AI-scent score in [0, 100]; higher = more AI-like.
  final int score;

  /// Human-readable Chinese reasons explaining why this sentence was flagged.
  final List<String> reasons;

  const SentenceAiScentScore({
    required this.sentence,
    required this.score,
    required this.reasons,
  });
}

/// The result of analyzing a passage sentence-by-sentence.
class SentenceAiScentAnalysis {
  /// Per-sentence scores, sorted descending (worst/most-AI first).
  final List<SentenceAiScentScore> scores;

  /// Score at/above which a sentence is worth the author's attention.
  final int notableThreshold;

  const SentenceAiScentAnalysis({
    required this.scores,
    this.notableThreshold = SentenceAiScentAnalyzer.notableThreshold,
  });

  /// Whether any sentence reaches the notable threshold.
  bool get hasNotable => scores.any((s) => s.score >= notableThreshold);

  /// The single highest-scoring sentence, or null if the passage was empty.
  SentenceAiScentScore? get worst => scores.isEmpty ? null : scores.first;
}

/// Scores each sentence of a passage for AI-scent using local signals.
class SentenceAiScentAnalyzer {
  /// Runtime threshold used by [SentenceAiScentAnalysis.hasNotable].
  final int threshold;

  const SentenceAiScentAnalyzer({this.threshold = notableThreshold})
    : assert(threshold >= 0 && threshold <= 100);

  /// Score at/above which a sentence is "notable" (worth the author's attention).
  static const int notableThreshold = 25;

  /// Sentence-leading connectors that mark mechanical, AI-like transitions.
  static const Set<String> transitionStarts = {
    '然而',
    '此外',
    '而且',
    '另外',
    '综上',
    '综上所述',
    '不仅',
    '不仅如此',
    '值得一提',
    '值得一提的是',
    '与此同时',
    '总的来说',
    '总而言之',
    '换言之',
    '毫无疑问',
    '事实上',
    '实际上',
    '众所周知',
    '显而易见',
  };

  /// Formulaic AI-tell constructions (matched anywhere in the sentence).
  static final List<RegExp> aiTellPatterns = [
    RegExp(r'不仅.{0,20}而且'),
    RegExp(r'既.{0,20}又'),
    RegExp(r'在这个.{0,10}的时代'),
    RegExp(r'值得一提的是'),
    RegExp(r'众所周知'),
    RegExp(r'毫无疑问'),
    RegExp(r'综上所述'),
    RegExp(r'与此同时'),
    RegExp(r'总而言之'),
    RegExp(r'换言之'),
  ];

  /// CJK grammatical particles / function words.
  static const Set<String> functionChars = {
    '的',
    '了',
    '是',
    '在',
    '和',
    '与',
    '也',
    '都',
    '就',
    '而',
    '或',
    '把',
    '被',
    '对',
    '向',
    '给',
    '着',
    '过',
    '地',
    '得',
    '这',
    '那',
    '他',
    '她',
    '它',
    '们',
  };

  /// Hollow intensifiers (AA-04b) — empty degree adverbs AI prose pads with.
  /// Distinct from [functionChars]: these are content-ish adverbs (真是/十分/
  /// 非常…) so the function-word-ratio signal structurally misses them.
  /// Flagged only on concentration (≥3 hits/sentence) to stay precise.
  static const Set<String> emptyIntensifiers = {
    '真是',
    '简直',
    '十分',
    '非常',
    '尤其',
    '格外',
    '颇为',
    '相当',
    '无比',
    '极其',
    '尤为',
    '极为',
  };

  /// Analyzes [text] sentence-by-sentence, returning scores sorted worst-first.
  ///
  /// Sentences with fewer than 2 CJK characters are skipped as fragments.
  /// If [maxSentences] is given, only the top-N worst are returned.
  SentenceAiScentAnalysis analyze(String text, {int? maxSentences}) {
    final parts = text.split(RegExp(r'[。！？；\n]+'));
    var scored = <SentenceAiScentScore>[];
    for (final raw in parts) {
      final sentence = raw.trim();
      final cjk = _cjkChars(sentence);
      if (cjk.length < 2) continue;
      scored.add(_score(sentence, cjk));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    if (maxSentences != null) {
      scored = scored.take(maxSentences).toList();
    }
    return SentenceAiScentAnalysis(scores: scored, notableThreshold: threshold);
  }

  SentenceAiScentScore _score(String sentence, String cjk) {
    var score = 0;
    final reasons = <String>[];

    // Signal 1: mechanical transition-word start.
    for (final t in transitionStarts) {
      if (sentence.startsWith(t)) {
        score += 35;
        reasons.add('机械过渡词起句');
        break;
      }
    }

    // Signal 2: AI-tell formulaic pattern.
    for (final p in aiTellPatterns) {
      if (p.hasMatch(sentence)) {
        score += 35;
        reasons.add('AI套式句式');
        break;
      }
    }

    // Signal 3: high function-word ratio (content-thin).
    final funcCount = cjk.codeUnits.where((u) {
      final ch = String.fromCharCode(u);
      return functionChars.contains(ch);
    }).length;
    final ratio = cjk.isEmpty ? 0.0 : funcCount / cjk.length;
    if (ratio > 0.4) {
      score += 35;
      reasons.add('虚词/功能词占比过高');
    }

    // Signal 4: run-on (long, no internal pause punctuation).
    if (cjk.length > 40 && !RegExp(r'[、，；]').hasMatch(sentence)) {
      score += 30;
      reasons.add('超长无断句');
    }

    // Signal 5: hollow-intensifier concentration (AA-04b). Counts empty degree
    // adverbs (真是/十分/非常…) in the sentence — classic AI padding the
    // function-word-ratio signal misses (intensifiers aren't functionChars).
    // ≥3 hits/sentence fires; 1-2 is normal rhetoric and stays silent.
    var intensifierHits = 0;
    for (final w in emptyIntensifiers) {
      var offset = 0;
      while (true) {
        final idx = sentence.indexOf(w, offset);
        if (idx == -1) break;
        intensifierHits++;
        offset = idx + w.length;
      }
    }
    if (intensifierHits >= 3) {
      score += 30;
      reasons.add('空洞强调词堆砌');
    }

    return SentenceAiScentScore(
      sentence: sentence,
      score: score.clamp(0, 100),
      reasons: reasons,
    );
  }

  /// Extracts only CJK ideographs (U+4E00–U+9FFF), dropping punctuation/Latin.
  String _cjkChars(String s) => s.replaceAll(RegExp(r'[^一-鿿]'), '');
}
