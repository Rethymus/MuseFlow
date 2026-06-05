import 'package:flutter/material.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';

/// Semantic node background colors for story arc structural roles.
///
/// Names intentionally match [PlotNodeStructuralRole] values so UI code reads
/// in domain language instead of raw palette names.
class GraphColor {
  static const setup = Color(0xFF6B7280);
  static const setupLight = Color(0xFF4B5563);
  static const development = Color(0xFF10B981);
  static const developmentLight = Color(0xFF059669);
  static const turn = Color(0xFFF59E0B);
  static const turnLight = Color(0xFFD97706);
  static const climax = Color(0xFFEF4444);
  static const climaxLight = Color(0xFFDC2626);
  static const resolution = Color(0xFF1E40AF);
  static const resolutionLight = Color(0xFF1E3A8A);

  const GraphColor._();

  /// Resolves a structural role to its visual node color.
  static Color forRole(PlotNodeStructuralRole role, {bool isDark = true}) {
    return switch (role) {
      PlotNodeStructuralRole.setup => isDark ? setup : setupLight,
      PlotNodeStructuralRole.development =>
        isDark ? development : developmentLight,
      PlotNodeStructuralRole.turn => isDark ? turn : turnLight,
      PlotNodeStructuralRole.climax => isDark ? climax : climaxLight,
      PlotNodeStructuralRole.resolution =>
        isDark ? resolution : resolutionLight,
    };
  }
}

/// Semantic border and icon styling for plot node writing status.
class GraphStatus {
  static const notStarted = Color(0xFF6B7280);
  static const drafting = Color(0xFF3B82F6);
  static const complete = Color(0xFF10B981);
  static const needsRevision = Color(0xFFF59E0B);

  const GraphStatus._();

  /// Resolves the border color for a writing status.
  static Color borderColor(PlotNodeWritingStatus status) {
    return switch (status) {
      PlotNodeWritingStatus.notStarted => notStarted,
      PlotNodeWritingStatus.drafting => drafting,
      PlotNodeWritingStatus.complete => complete,
      PlotNodeWritingStatus.needsRevision => needsRevision,
    };
  }

  /// Resolves the border pattern for a writing status.
  static String borderPattern(PlotNodeWritingStatus status) {
    return switch (status) {
      PlotNodeWritingStatus.notStarted => 'dashed',
      PlotNodeWritingStatus.drafting => 'solid',
      PlotNodeWritingStatus.complete => 'solid',
      PlotNodeWritingStatus.needsRevision => 'dotted',
    };
  }

  /// Resolves the Material status icon for a writing status.
  static IconData statusIcon(PlotNodeWritingStatus status) {
    return switch (status) {
      PlotNodeWritingStatus.notStarted => Icons.circle_outlined,
      PlotNodeWritingStatus.drafting => Icons.edit,
      PlotNodeWritingStatus.complete => Icons.check_circle,
      PlotNodeWritingStatus.needsRevision => Icons.warning,
    };
  }
}
