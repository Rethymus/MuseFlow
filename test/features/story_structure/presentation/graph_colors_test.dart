import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';
import 'package:museflow/features/story_structure/presentation/story_arc/graph_colors.dart';
import 'package:museflow/features/story_structure/presentation/story_arc/graph_theme.dart';

void main() {
  group('GraphColor', () {
    test('should return dark setup color by default', () {
      expect(
        GraphColor.forRole(PlotNodeStructuralRole.setup),
        const Color(0xFF5E5CE6),
      );
    });

    test('should return correct dark colors for all structural roles', () {
      expect(
        GraphColor.forRole(PlotNodeStructuralRole.setup),
        const Color(0xFF5E5CE6),
      );
      expect(
        GraphColor.forRole(PlotNodeStructuralRole.development),
        const Color(0xFF0A84FF),
      );
      expect(
        GraphColor.forRole(PlotNodeStructuralRole.turn),
        const Color(0xFFFF9F0A),
      );
      expect(
        GraphColor.forRole(PlotNodeStructuralRole.climax),
        const Color(0xFFFF453A),
      );
      expect(
        GraphColor.forRole(PlotNodeStructuralRole.resolution),
        const Color(0xFF30D158),
      );
    });

    test('should return correct light colors for all structural roles', () {
      expect(
        GraphColor.forRole(PlotNodeStructuralRole.setup, isDark: false),
        const Color(0xFF5856D7),
      );
      expect(
        GraphColor.forRole(PlotNodeStructuralRole.development, isDark: false),
        const Color(0xFF007AFF),
      );
      expect(
        GraphColor.forRole(PlotNodeStructuralRole.turn, isDark: false),
        const Color(0xFFFF9500),
      );
      expect(
        GraphColor.forRole(PlotNodeStructuralRole.climax, isDark: false),
        const Color(0xFFFF3B30),
      );
      expect(
        GraphColor.forRole(PlotNodeStructuralRole.resolution, isDark: false),
        const Color(0xFF34C759),
      );
    });
  });

  group('GraphStatus', () {
    test('should return correct border colors for all writing statuses', () {
      expect(
        GraphStatus.borderColor(PlotNodeWritingStatus.notStarted),
        const Color(0xFF8E8E93),
      );
      expect(
        GraphStatus.borderColor(PlotNodeWritingStatus.drafting),
        const Color(0xFF007AFF),
      );
      expect(
        GraphStatus.borderColor(PlotNodeWritingStatus.complete),
        const Color(0xFF34C759),
      );
      expect(
        GraphStatus.borderColor(PlotNodeWritingStatus.needsRevision),
        const Color(0xFFFF9500),
      );
    });

    test('should return correct border patterns for all writing statuses', () {
      expect(
        GraphStatus.borderPattern(PlotNodeWritingStatus.notStarted),
        'dashed',
      );
      expect(
        GraphStatus.borderPattern(PlotNodeWritingStatus.drafting),
        'solid',
      );
      expect(
        GraphStatus.borderPattern(PlotNodeWritingStatus.complete),
        'solid',
      );
      expect(
        GraphStatus.borderPattern(PlotNodeWritingStatus.needsRevision),
        'dotted',
      );
    });

    test('should return correct status icons for all writing statuses', () {
      expect(
        GraphStatus.statusIcon(PlotNodeWritingStatus.notStarted),
        Icons.circle_outlined,
      );
      expect(
        GraphStatus.statusIcon(PlotNodeWritingStatus.drafting),
        Icons.edit,
      );
      expect(
        GraphStatus.statusIcon(PlotNodeWritingStatus.complete),
        Icons.check_circle,
      );
      expect(
        GraphStatus.statusIcon(PlotNodeWritingStatus.needsRevision),
        Icons.warning,
      );
    });
  });

  group('GraphTheme', () {
    test('should resolve different role colors for dark and light mode', () {
      const darkTheme = GraphTheme(brightness: Brightness.dark);
      const lightTheme = GraphTheme(brightness: Brightness.light);

      expect(
        darkTheme.roleColor(PlotNodeStructuralRole.development),
        const Color(0xFF0A84FF),
      );
      expect(
        lightTheme.roleColor(PlotNodeStructuralRole.development),
        const Color(0xFF007AFF),
      );
      expect(
        darkTheme.roleColor(PlotNodeStructuralRole.development),
        isNot(lightTheme.roleColor(PlotNodeStructuralRole.development)),
      );
    });

    test('should resolve edge colors for dark and light mode', () {
      const darkTheme = GraphTheme(brightness: Brightness.dark);
      const lightTheme = GraphTheme(brightness: Brightness.light);

      expect(darkTheme.edgeColor('causal'), const Color(0xFF0A84FF));
      expect(darkTheme.edgeColor('association'), const Color(0xFF8E8E93));
      expect(lightTheme.edgeColor('association'), const Color(0xFFAEAEB2));
      expect(darkTheme.edgeColor('foreshadowing'), const Color(0xFFFF9F0A));
    });
  });
}
