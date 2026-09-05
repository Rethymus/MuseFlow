import 'package:flutter/material.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';

/// Semantic node background colors for story arc structural roles, on the
/// Apple system palette (dark-mode variants are the brighter iOS tones so
/// nodes stay legible on the pure-black graph background).
///
/// Names intentionally match [PlotNodeStructuralRole] values so UI code reads
/// in domain language instead of raw palette names.
class GraphColor {
  // systemIndigo
  static const setup = Color(0xFF5E5CE6);
  static const setupLight = Color(0xFF5856D7);
  // systemBlue
  static const development = Color(0xFF0A84FF);
  static const developmentLight = Color(0xFF007AFF);
  // systemOrange
  static const turn = Color(0xFFFF9F0A);
  static const turnLight = Color(0xFFFF9500);
  // systemRed
  static const climax = Color(0xFFFF453A);
  static const climaxLight = Color(0xFFFF3B30);
  // systemGreen
  static const resolution = Color(0xFF30D158);
  static const resolutionLight = Color(0xFF34C759);

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
  // systemGray / systemBlue / systemGreen / systemOrange
  static const notStarted = Color(0xFF8E8E93);
  static const drafting = Color(0xFF007AFF);
  static const complete = Color(0xFF34C759);
  static const needsRevision = Color(0xFFFF9500);

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
