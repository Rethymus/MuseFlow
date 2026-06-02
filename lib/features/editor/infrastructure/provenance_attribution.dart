/// AI text provenance attribution system.
///
/// Tracks which text was AI-modified using super_editor's attribution system.
/// Uses a unique [NamedAttribution] id ('ai_provenance') to avoid conflicts
/// with [BackgroundColorAttribution] (Pitfall 2 from RESEARCH.md).
library;

import 'package:flutter/painting.dart';
import 'package:super_editor/super_editor.dart';

/// Attribution marking text as AI-modified.
///
/// Uses [NamedAttribution] with a unique id to avoid id conflicts with
/// [BackgroundColorAttribution] (which also uses 'background_color').
/// Per Pitfall 2: custom attribution with unique id is the safe approach.
const aiProvenanceAttribution = NamedAttribution('ai_provenance');

/// Blue background color for AI-provenance text.
///
/// Per D-09: Blue with 10% opacity (0x1A alpha).
const provenanceColor = Color(0x1A2196F3);

/// Utility class for applying/removing AI provenance attribution to editor text.
///
/// Uses [ToggleTextAttributionsRequest] to modify text attributions through
/// the editor's command pipeline, preserving the undo/redo chain (T-03-04).
abstract class ProvenanceAttributions {
  ProvenanceAttributions._();

  /// Applies the AI provenance attribution to text in [range].
  ///
  /// Executes a [ToggleTextAttributionsRequest] through the editor's
  /// command pipeline. If the attribution is already present, it is
  /// toggled off (idempotent toggle behavior).
  static void applyProvenance(Editor editor, DocumentRange range) {
    editor.execute([
      ToggleTextAttributionsRequest(
        documentRange: range,
        attributions: {aiProvenanceAttribution},
      ),
    ]);
  }

  /// Removes the AI provenance attribution from text in [range].
  ///
  /// Uses the same toggle mechanism -- if attribution is present it is
  /// removed, if absent nothing changes.
  static void removeProvenance(Editor editor, DocumentRange range) {
    editor.execute([
      ToggleTextAttributionsRequest(
        documentRange: range,
        attributions: {aiProvenanceAttribution},
      ),
    ]);
  }
}
