/// Lexical signature — author's characteristic CJK n-gram vocabulary.
///
/// Immutable value object capturing the high-frequency bigrams and trigrams
/// extracted from an author's writing. Stored as the `lexicalSignature` field
/// of an [AuthorStyleProfile] and injected by [DynamicPersonaMiddleware] so
/// the AI internalizes the author's actual vocabulary palette rather than a
/// generic "comparable vocabulary level" instruction.
///
/// Pure Dart domain layer — no Flutter or application-layer imports.
library;

/// A single scored n-gram term in a [LexicalSignature].
class LexicalTerm {
  /// The n-gram string (2 or 3 CJK characters).
  final String term;

  /// Salience score (frequency × weight, where trigram weight = 1.5 and
  /// bigram weight = 1.0). Higher = more characteristic of the author.
  final double score;

  /// Raw occurrence count in the analyzed text.
  final int frequency;

  const LexicalTerm({required this.term, this.score = 0, this.frequency = 0});

  LexicalTerm copyWith({String? term, double? score, int? frequency}) {
    return LexicalTerm(
      term: term ?? this.term,
      score: score ?? this.score,
      frequency: frequency ?? this.frequency,
    );
  }

  factory LexicalTerm.fromJson(Map<String, dynamic> json) {
    return LexicalTerm(
      term: json['term'] as String,
      score: (json['score'] as num).toDouble(),
      frequency: json['frequency'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'term': term,
    'score': score,
    'frequency': frequency,
  };

  @override
  bool operator ==(Object other) {
    return other is LexicalTerm &&
        other.term == term &&
        other.score == score &&
        other.frequency == frequency;
  }

  @override
  int get hashCode => Object.hash(term, score, frequency);
}

/// Author's characteristic n-gram vocabulary, ranked by salience.
class LexicalSignature {
  /// Ranked list of characteristic n-grams (highest salience first).
  final List<LexicalTerm> topTerms;

  const LexicalSignature({this.topTerms = const []});

  /// Empty signature sentinel (no characteristic terms).
  static const LexicalSignature empty = LexicalSignature();

  /// Whether this signature carries any characteristic terms.
  bool get isEmpty => topTerms.isEmpty;

  LexicalSignature copyWith({List<LexicalTerm>? topTerms}) {
    return LexicalSignature(topTerms: topTerms ?? this.topTerms);
  }

  factory LexicalSignature.fromJson(Map<String, dynamic> json) {
    final raw = json['topTerms'] as List<dynamic>?;
    return LexicalSignature(
      topTerms:
          raw
              ?.map((t) => LexicalTerm.fromJson(t as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'topTerms': topTerms.map((t) => t.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) {
    if (other is! LexicalSignature) return false;
    if (other.topTerms.length != topTerms.length) return false;
    for (var i = 0; i < topTerms.length; i++) {
      if (other.topTerms[i] != topTerms[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(topTerms);
}
