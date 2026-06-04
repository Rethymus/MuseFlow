/// Category of a format cleanup change.
enum FormatChangeCategory {
  punctuation,
  markdown,
  whitespace,
  indentation,
  paragraph;

  /// Deserialize from JSON string.
  static FormatChangeCategory fromJsonString(String value) {
    return FormatChangeCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FormatChangeCategory.punctuation,
    );
  }

  /// Serialize to JSON string.
  String toJsonString() => name;
}

/// A single change produced by format cleanup.
///
/// Immutable record of what was replaced, where, and why.
class FormatChange {
  final FormatChangeCategory category;
  final String original;
  final String replacement;
  final int startOffset;
  final int endOffset;
  final String explanation;

  const FormatChange({
    required this.category,
    required this.original,
    required this.replacement,
    required this.startOffset,
    required this.endOffset,
    required this.explanation,
  });

  factory FormatChange.fromJson(Map<String, dynamic> json) {
    return FormatChange(
      category: FormatChangeCategory.fromJsonString(
        json['category'] as String? ?? 'punctuation',
      ),
      original: json['original'] as String,
      replacement: json['replacement'] as String,
      startOffset: json['startOffset'] as int,
      endOffset: json['endOffset'] as int,
      explanation: json['explanation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category.toJsonString(),
      'original': original,
      'replacement': replacement,
      'startOffset': startOffset,
      'endOffset': endOffset,
      'explanation': explanation,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FormatChange &&
        other.category == category &&
        other.original == original &&
        other.replacement == replacement &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset &&
        other.explanation == explanation;
  }

  @override
  int get hashCode => Object.hash(
        category,
        original,
        replacement,
        startOffset,
        endOffset,
        explanation,
      );

  @override
  String toString() =>
      'FormatChange($category: "$original" -> "$replacement" at $startOffset-$endOffset)';
}

/// Result of format cleanup with structured preview of all changes.
///
/// Contains the original text, cleaned text, and a list of individual changes
/// grouped by category. The UI presents this as a preview requiring explicit
/// confirmation before the cleaned text replaces the original.
class FormatCleanResult {
  final String originalText;
  final String cleanedText;
  final List<FormatChange> changes;

  const FormatCleanResult({
    required this.originalText,
    required this.cleanedText,
    required this.changes,
  });

  /// Whether any changes were produced.
  bool get hasChanges => changes.isNotEmpty;

  factory FormatCleanResult.fromJson(Map<String, dynamic> json) {
    return FormatCleanResult(
      originalText: json['originalText'] as String,
      cleanedText: json['cleanedText'] as String,
      changes: (json['changes'] as List<dynamic>)
          .map((c) => FormatChange.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalText': originalText,
      'cleanedText': cleanedText,
      'changes': changes.map((c) => c.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FormatCleanResult &&
        other.originalText == originalText &&
        other.cleanedText == cleanedText &&
        _listEquals(other.changes, changes);
  }

  @override
  int get hashCode => Object.hash(
        originalText,
        cleanedText,
        Object.hashAll(changes),
      );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
