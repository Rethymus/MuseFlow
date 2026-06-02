/// Synthesis request value object.
///
/// Holds the parameters for an AI synthesis operation:
/// fragments to synthesize, optional instruction, token budget, and temperature.
/// Per D-06: supports additional instruction for fine-grained control.
///
/// Immutable -- use [copyWith] to create modified copies.
library;

import 'package:museflow/core/domain/fragment.dart';

/// A value object representing a synthesis request.
///
/// Encapsulates all parameters needed to perform an AI synthesis:
/// the fragments to synthesize, optional additional instructions,
/// output token limit, and sampling temperature.
class SynthesisRequest {
  /// The fragments to synthesize into a coherent paragraph.
  final List<Fragment> fragments;

  /// Optional additional instruction for the AI model.
  /// Per D-06: allows users to add context like "注意语气要自然".
  final String? additionalInstruction;

  /// Maximum output tokens for the generated text.
  /// Default: 2000 (sufficient for ~1000 Chinese characters).
  final int maxOutputTokens;

  /// Sampling temperature (0.0 - 2.0).
  /// Lower values = more deterministic, higher = more creative.
  /// Default: 0.7 (balanced creativity).
  final double temperature;

  const SynthesisRequest({
    required this.fragments,
    this.additionalInstruction,
    this.maxOutputTokens = 2000,
    this.temperature = 0.7,
  });

  /// Creates a copy of this request with the given fields replaced.
  SynthesisRequest copyWith({
    List<Fragment>? fragments,
    String? additionalInstruction,
    int? maxOutputTokens,
    double? temperature,
  }) {
    return SynthesisRequest(
      fragments: fragments ?? this.fragments,
      additionalInstruction: additionalInstruction ?? this.additionalInstruction,
      maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
      temperature: temperature ?? this.temperature,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SynthesisRequest) return false;
    if (other.fragments.length != fragments.length) return false;
    for (var i = 0; i < fragments.length; i++) {
      if (other.fragments[i] != fragments[i]) return false;
    }
    return other.additionalInstruction == additionalInstruction &&
        other.maxOutputTokens == maxOutputTokens &&
        other.temperature == temperature;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(fragments),
        additionalInstruction,
        maxOutputTokens,
        temperature,
      );

  @override
  String toString() =>
      'SynthesisRequest(fragments: ${fragments.length}, '
      'instruction: $additionalInstruction, '
      'maxTokens: $maxOutputTokens, temp: $temperature)';
}
