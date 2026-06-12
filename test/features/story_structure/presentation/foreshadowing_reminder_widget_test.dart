/// Tests for ForeshadowingReminderWidget.
///
/// Per Phase 21 (KNOW-04): Validates the widget's rendering logic.
/// Widget integration (provider → notifier → repository → Hive) is tested
/// via repository and notifier tests. These tests focus on the widget's
/// conditional rendering behavior using controlled overrides.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/features/story_structure/presentation/foreshadowing_reminder_widget.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';

void main() {
  group('ForeshadowingReminderWidget', () {
    testWidgets('should render without error in empty state', (tester) async {
      // With default provider (no Hive), the async state will be loading/error
      // → widget returns SizedBox.shrink
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ForeshadowingReminderWidget()),
          ),
        ),
      );

      // No crash, no visible foreshadowing text
      expect(find.textContaining('伏笔未收束'), findsNothing);
    });

    testWidgets('should have correct widget structure', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ForeshadowingReminderWidget()),
          ),
        ),
      );

      // Widget tree should exist (SizedBox.shrink is valid)
      expect(find.byType(ForeshadowingReminderWidget), findsOneWidget);
    });
  });

  group('ForeshadowingReminderPanel', () {
    testWidgets('should render without error in empty state', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ForeshadowingReminderPanel(currentChapter: 5),
            ),
          ),
        ),
      );

      // No visible reminder content when no data
      expect(find.text('伏笔追踪'), findsNothing);
    });

    testWidgets('should accept chapter and threshold parameters', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ForeshadowingReminderPanel(
                currentChapter: 12,
                defaultThreshold: 10,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ForeshadowingReminderPanel), findsOneWidget);
    });
  });

  group('ForeshadowingReminder logic', () {
    test('should correctly identify open entries', () {
      final open = ForeshadowingEntry(
        id: 'f-1',
        title: '伏笔',
        plantedChapter: 1,
        status: ForeshadowingStatus.planted,
        mode: ForeshadowingMode.detailed,
        createdAt: DateTime(2026, 1, 1),
      );

      final developing = ForeshadowingEntry(
        id: 'f-2',
        title: '伏笔',
        plantedChapter: 1,
        status: ForeshadowingStatus.developing,
        mode: ForeshadowingMode.detailed,
        createdAt: DateTime(2026, 1, 1),
      );

      final resolved = ForeshadowingEntry(
        id: 'f-3',
        title: '伏笔',
        plantedChapter: 1,
        status: ForeshadowingStatus.resolved,
        resolvedChapter: 5,
        mode: ForeshadowingMode.detailed,
        createdAt: DateTime(2026, 1, 1),
      );

      final abandoned = ForeshadowingEntry(
        id: 'f-4',
        title: '伏笔',
        plantedChapter: 1,
        status: ForeshadowingStatus.abandoned,
        mode: ForeshadowingMode.detailed,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(open.isOpen, isTrue);
      expect(developing.isOpen, isTrue);
      expect(resolved.isOpen, isFalse);
      expect(abandoned.isOpen, isFalse);
    });

    test('should correctly detect overdue entries', () {
      final entry = ForeshadowingEntry(
        id: 'f-1',
        title: '伏笔',
        plantedChapter: 1,
        status: ForeshadowingStatus.planted,
        targetResolutionChapter: 5,
        mode: ForeshadowingMode.detailed,
        createdAt: DateTime(2026, 1, 1),
      );

      // Chapter 3: not overdue
      expect(entry.isOverdue(currentChapter: 3, defaultThreshold: 10), isFalse);
      // Chapter 6: past target resolution
      expect(entry.isOverdue(currentChapter: 6, defaultThreshold: 10), isTrue);
      // Chapter 12: past threshold
      expect(entry.isOverdue(currentChapter: 12, defaultThreshold: 10), isTrue);
    });

    test('resolved entries should not be overdue', () {
      final entry = ForeshadowingEntry(
        id: 'f-1',
        title: '伏笔',
        plantedChapter: 1,
        status: ForeshadowingStatus.resolved,
        resolvedChapter: 5,
        mode: ForeshadowingMode.detailed,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(entry.isOverdue(currentChapter: 20, defaultThreshold: 5), isFalse);
    });
  });
}
