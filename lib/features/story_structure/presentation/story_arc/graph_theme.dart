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
      'causal' => isDark ? Colors.blue.shade700 : Colors.blue.shade600,
      'association' => isDark ? Colors.grey.shade600 : Colors.grey.shade400,
      'foreshadowing' => Colors.amber.shade500,
      _ => isDark ? Colors.grey.shade600 : Colors.grey.shade400,
    };
  }

  /// Returns the lighter causal edge endpoint for gradient rendering.
  Color causalEdgeEndColor() {
    return isDark ? Colors.blue.shade300 : Colors.blue.shade200;
  }
}
