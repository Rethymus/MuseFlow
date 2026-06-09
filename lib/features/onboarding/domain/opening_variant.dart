/// Opening variant domain model for AI-generated story openings.
///
/// Each variant represents a distinct narrative style for opening a story:
/// - scene: Environmental/atmospheric opening (场景切入)
/// - character: Character action/psychology opening (人物切入)
/// - suspense: Question/tension opening (悬念切入)
library;

/// Style enum for opening variants.
///
/// Reuses the same semantic values as [OpeningSampleStyle] from
/// world_template.dart (scene/character/suspense) for consistency
/// across the codebase. Created as standalone enum because the templates
/// feature may not be available in all worktree branches.
enum OpeningVariantStyle {
  scene('scene'),
  character('character'),
  suspense('suspense');

  const OpeningVariantStyle(this.value);

  /// Storage value for JSON serialization and API communication.
  final String value;

  /// Factory from storage string.
  ///
  /// Throws [ArgumentError] for unknown style values.
  static OpeningVariantStyle fromString(String value) {
    return OpeningVariantStyle.values.firstWhere(
      (style) => style.value == value,
      orElse: () => throw ArgumentError.value(
        value,
        'value',
        'Unknown opening variant style',
      ),
    );
  }

  /// Chinese display label for UI presentation.
  String get displayLabel => switch (this) {
    OpeningVariantStyle.scene => '场景切入',
    OpeningVariantStyle.character => '人物切入',
    OpeningVariantStyle.suspense => '悬念切入',
  };
}

/// Immutable value object representing a single AI-generated opening variant.
///
/// Each variant pairs a narrative [style] with the opening paragraph [text].
/// Instances are created by [OpeningGeneratorService] from AI streaming output.
class OpeningVariant {
  const OpeningVariant({required this.style, required this.text});

  /// The narrative style of this opening variant.
  final OpeningVariantStyle style;

  /// The opening paragraph text (200-400 characters per prompt instruction).
  final String text;

  /// Constructs an [OpeningVariant] from a JSON map.
  ///
  /// Expected shape: `{'style': 'scene', 'text': '...'}`
  factory OpeningVariant.fromJson(Map<String, dynamic> json) {
    return OpeningVariant(
      style: OpeningVariantStyle.fromString(json['style'] as String),
      text: json['text'] as String,
    );
  }

  /// Serializes this variant to a JSON-compatible map.
  Map<String, dynamic> toJson() => {'style': style.value, 'text': text};

  /// Creates a copy with optionally replaced fields.
  OpeningVariant copyWith({OpeningVariantStyle? style, String? text}) {
    return OpeningVariant(style: style ?? this.style, text: text ?? this.text);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpeningVariant && style == other.style && text == other.text;

  @override
  int get hashCode => Object.hash(style, text);

  @override
  String toString() =>
      'OpeningVariant(style: $style, text: ${text.length} chars)';
}
