import 'package:museflow/features/story_structure/application/guardian_context_builder.dart';
import 'package:museflow/features/story_structure/domain/guardian_annotation.dart';

/// Service for detecting timeline, world-setting, skill-rule contradictions,
/// and unresolved foreshadowing risks in story text.
///
/// Sends bounded context to an AI provider and parses the response into
/// advisory [GuardianAnnotation] objects. Malformed AI output and provider
/// failures are non-blocking (return empty results, never throw through UI).
class LogicGuardianService {
  /// Builds the logic guardian check prompt.
  String buildLogicPrompt({
    required String text,
    required GuardianContextBundle context,
  }) {
    // TODO: implement
    throw UnimplementedError();
  }

  /// Parses an AI response into guardian annotations.
  List<GuardianAnnotation> parseLogicResponse(String response) {
    // TODO: implement
    throw UnimplementedError();
  }
}
