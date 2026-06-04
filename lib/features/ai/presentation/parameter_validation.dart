/// Parameter validation functions for the provider management form.
///
/// Pure Dart functions for parsing and validating model parameter inputs.
/// Per D-05: TextField-based input with numeric range validation.
/// Per RESEARCH Pitfall 2: empty string maps to null, not 0.
library;

/// Parses a temperature input string.
///
/// Valid range: 0.0 - 2.0. Empty string returns null (use model default).
/// Non-numeric or out-of-range input returns null.
double? parseTemperature(String text) {
  if (text.isEmpty) return null;
  final value = double.tryParse(text);
  if (value == null) return null;
  if (value < 0.0 || value > 2.0) return null;
  return value;
}

/// Parses a topP input string.
///
/// Valid range: 0.0 - 1.0. Empty string returns null (use model default).
/// Non-numeric or out-of-range input returns null.
double? parseTopP(String text) {
  if (text.isEmpty) return null;
  final value = double.tryParse(text);
  if (value == null) return null;
  if (value < 0.0 || value > 1.0) return null;
  return value;
}

/// Parses a maxTokens input string.
///
/// Valid range: 1 - 128000. Empty string returns null (use model default).
/// Non-numeric or out-of-range input returns null.
int? parseMaxTokens(String text) {
  if (text.isEmpty) return null;
  final value = int.tryParse(text);
  if (value == null) return null;
  if (value < 1 || value > 128000) return null;
  return value;
}
