import 'package:flutter/material.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';
import 'package:museflow/features/story_structure/presentation/story_arc/graph_colors.dart';

/// Dark/light-mode-aware graph styling resolver.
class GraphTheme {
  final Brightness brightness;

  const GraphTheme({required this.brightness});

  bool get isDark => brightness == Brightness.dark;

  /// Returns the node background color for a structural role.
  Color roleColor(PlotNodeStructuralRole role) {
    return GraphColor.forRole(role, isDark: isDark);
  }

  /// Returns the border color for a writing status.
  Color statusBorderColor(PlotNodeWritingStatus status) {
    return GraphStatus.borderColor(status);
  }

  /// Returns the base edge color for a story arc relationship type.
  Color edgeColor(String type) {
    return switch (type) {
      // systemBlue / systemGray / systemOrange (bright dark variants).
      'causal' => isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF),
      'association' =>
        isDark ? const Color(0xFF8E8E93) : const Color(0xFFAEAEB2),
      'foreshadowing' =>
        isDark ? const Color(0xFFFF9F0A) : const Color(0xFFFF9500),
      _ => isDark ? const Color(0xFF8E8E93) : const Color(0xFFAEAEB2),
    };
  }

  /// Returns the lighter causal edge endpoint for gradient rendering.
  Color causalEdgeEndColor() {
    return isDark ? const Color(0xFF64D2FF) : const Color(0xFF32ADE6);
  }
}
