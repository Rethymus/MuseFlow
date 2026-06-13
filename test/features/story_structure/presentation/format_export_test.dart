import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/features/story_structure/application/export_service.dart';
import 'package:museflow/features/story_structure/domain/export_bundle.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';
import 'package:museflow/features/story_structure/domain/guardian_annotation.dart';
import 'package:museflow/features/story_structure/presentation/format_clean_preview_dialog.dart';
import 'package:museflow/features/story_structure/presentation/export_dialog.dart';

void main() {
  group('FormatCleanPreviewDialog', () {
    testWidgets('should disable Apply cleanup until preview is generated', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FormatCleanPreviewDialog(
                originalText: '测试文本',
                onApply: (_) {},
              ),
            ),
          ),
        ),
      );

      // Find the Apply button
      final applyButton = find.text('确认应用');
      expect(applyButton, findsOneWidget);

      // Verify it is initially disabled
      final applyWidget = tester.widget<ElevatedButton>(
        find.ancestor(of: applyButton, matching: find.byType(ElevatedButton)),
      );
      expect(applyWidget.enabled, isFalse);
    });

    testWidgets('should show preview when Preview cleanup is pressed', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FormatCleanPreviewDialog(
                originalText: '他说,这是一个故事.',
                onApply: (_) {},
              ),
            ),
          ),
        ),
      );

      // Tap the preview button
      final previewButton = find.text('预览清理');
      expect(previewButton, findsOneWidget);
      await tester.tap(previewButton);
      await tester.pumpAndSettle();

      // After preview, the Apply button should be enabled
      final applyButton = find.text('确认应用');
      final applyWidget = tester.widget<ElevatedButton>(
        find.ancestor(of: applyButton, matching: find.byType(ElevatedButton)),
      );
      expect(applyWidget.enabled, isTrue);
    });

    testWidgets('closing/canceling leaves original text unchanged', (
      tester,
    ) async {
      String? appliedText;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FormatCleanPreviewDialog(
                originalText: '他说,这是一个故事.',
                onApply: (text) {
                  appliedText = text;
                },
              ),
            ),
          ),
        ),
      );

      // Find and tap Cancel
      final cancelButton = find.text('取消');
      expect(cancelButton, findsOneWidget);
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // onApply should never have been called
      expect(appliedText, isNull);
    });

    testWidgets('Apply cleanup calls onApply exactly once with cleaned text', (
      tester,
    ) async {
      final appliedTexts = <String>[];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FormatCleanPreviewDialog(
                originalText: '他说,这是一个故事.',
                onApply: (text) {
                  appliedTexts.add(text);
                },
              ),
            ),
          ),
        ),
      );

      // Generate preview first
      await tester.tap(find.text('预览清理'));
      await tester.pumpAndSettle();

      // Now apply
      await tester.tap(find.text('确认应用'));
      await tester.pumpAndSettle();

      // Should have called onApply exactly once
      expect(appliedTexts.length, 1);
      // Cleaned text should have full-width punctuation
      expect(appliedTexts[0], contains('，'));
      expect(appliedTexts[0], contains('。'));
    });
  });

  group('ExportDialog', () {
    ExportBundle createTestBundle() {
      return ExportBundle(
        schemaVersion: '1.0',
        exportedAt: DateTime(2026, 6, 4),
        manuscriptText: '测试稿件。',
        foreshadowingEntries: [
          ForeshadowingEntry(
            id: 'f1',
            title: '伏笔一',
            mode: ForeshadowingMode.detailed,
            status: ForeshadowingStatus.planted,
            plantedChapter: 1,
            createdAt: DateTime(2026, 6, 1),
          ),
        ],
        plotNodes: [
          PlotNode(
            id: 'p1',
            title: '开端',
            chapter: 1,
            createdAt: DateTime(2026, 6, 1),
          ),
        ],
        guardianAnnotations: [
          GuardianAnnotation(
            id: 'g1',
            kind: GuardianFindingKind.characterConsistency,
            severity: GuardianSeverity.medium,
            message: '角色行为不一致',
            reason: '与设定冲突',
            createdAt: DateTime(2026, 6, 2),
          ),
        ],
        characterCards: [
          {'id': 'c1', 'name': '角色A'},
        ],
        worldSettings: [
          {'id': 'w1', 'name': '修仙世界'},
        ],
        skillDocuments: [
          {'id': 's1', 'name': '功法体系'},
        ],
        activeSkillIds: ['s1'],
        metadata: {'appVersion': '1.0.0'},
      );
    }

    testWidgets('shows TXT, Markdown, JSON, and DOCX format choices', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExportDialog(
                bundle: createTestBundle(),
                onExport: (_, _, {textContent, binaryContent}) async {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('TXT'), findsOneWidget);
      expect(find.text('Markdown'), findsOneWidget);
      expect(find.text('JSON'), findsOneWidget);
      expect(find.text('DOCX'), findsOneWidget);
    });

    testWidgets('missing file path prevents export action', (tester) async {
      var exportCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExportDialog(
                bundle: createTestBundle(),
                onExport: (_, _, {textContent, binaryContent}) async {
                  exportCalled = true;
                },
              ),
            ),
          ),
        ),
      );

      // The export button should exist but be disabled without a path
      final exportButton = find.text('导出');
      expect(exportButton, findsOneWidget);

      // Tap the disabled export button - it should be a no-op
      await tester.tap(exportButton);
      await tester.pumpAndSettle();
      expect(exportCalled, isFalse);
    });

    testWidgets('shows suggested local path before path is set', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExportDialog(
                bundle: createTestBundle(),
                onExport: (_, _, {textContent, binaryContent}) async {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('museflow-export.txt'), findsOneWidget);
    });

    testWidgets('shows local path feedback when path is set', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExportDialog(
                bundle: createTestBundle(),
                onExport: (_, _, {textContent, binaryContent}) async {},
              ),
            ),
          ),
        ),
      );

      // Tap "选择路径" to open path dialog
      await tester.tap(find.text('选择路径'));
      await tester.pumpAndSettle();

      // Enter a path in the text field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, '/fake/export/path.txt');

      // Confirm the path
      // The dialog has its own "确定" button
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      // Now the dialog should show the selected path
      expect(find.text('/fake/export/path.txt'), findsOneWidget);
    });

    testWidgets('path dialog rejects wrong extension for selected format', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExportDialog(
                bundle: createTestBundle(),
                onExport: (_, _, {textContent, binaryContent}) async {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Markdown'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('选择路径'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '/fake/export/path.txt');
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      expect(find.text('文件名必须以 .md 结尾'), findsOneWidget);
      expect(find.widgetWithText(AlertDialog, '选择保存路径'), findsOneWidget);
    });

    testWidgets('export callback receives selected format path and content', (
      tester,
    ) async {
      ExportFormat? exportedFormat;
      String? exportedPath;
      String? exportedContent;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExportDialog(
                bundle: createTestBundle(),
                onExport: (format, path, {textContent, binaryContent}) async {
                  exportedFormat = format;
                  exportedPath = path;
                  exportedContent = textContent;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('JSON'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('选择路径'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '/fake/export/book.json');
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('export_button')));
      await tester.pumpAndSettle();

      expect(exportedFormat, ExportFormat.json);
      expect(exportedPath, '/fake/export/book.json');
      expect(exportedContent, contains('"schemaVersion": "1.0"'));
      expect(find.text('/fake/export/book.json'), findsOneWidget);
    });
  });
}
