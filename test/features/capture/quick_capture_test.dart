import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/features/capture/presentation/capture_provider.dart';
import 'package:museflow/features/capture/presentation/quick_capture.dart';
import 'package:museflow/shared/utils/keyboard_shortcuts.dart';

/// Creates a mock CaptureNotifier that records calls to addFragment.
class _MockCaptureNotifier extends CaptureNotifier {
  final List<String> addedTexts = [];

  @override
  CaptureState build() => const CaptureState();

  @override
  Future<void> addFragment(String text, {List<String>? tags}) async {
    addedTexts.add(text);
  }
}

void main() {
  group('QuickCaptureDialog', () {
    testWidgets('should render with title, TextField, and action buttons',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const QuickCaptureDialog(),
                      );
                    },
                    child: const Text('OPEN_DIALOG'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('OPEN_DIALOG'));
      await tester.pumpAndSettle();

      // Dialog title
      expect(find.text('快速捕捉'), findsOneWidget);

      // TextField with hint
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('输入你的灵感...'), findsOneWidget);

      // Action buttons
      expect(find.text('保存'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
    });

    testWidgets('should save fragment when 保存 is tapped with text',
        (tester) async {
      final mockNotifier = _MockCaptureNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            captureProvider.overrideWith(() => mockNotifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const QuickCaptureDialog(),
                      );
                    },
                    child: const Text('OPEN_DIALOG'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('OPEN_DIALOG'));
      await tester.pumpAndSettle();

      // Enter text
      await tester.enterText(find.byType(TextField), '测试灵感文本');

      // Tap save
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // Verify addFragment was called with the entered text
      expect(mockNotifier.addedTexts, ['测试灵感文本']);

      // Dialog should be closed
      expect(find.text('快速捕捉'), findsNothing);
    });

    testWidgets('should close without saving when 取消 is tapped',
        (tester) async {
      final mockNotifier = _MockCaptureNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            captureProvider.overrideWith(() => mockNotifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const QuickCaptureDialog(),
                      );
                    },
                    child: const Text('OPEN_DIALOG'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('OPEN_DIALOG'));
      await tester.pumpAndSettle();

      // Enter text
      await tester.enterText(find.byType(TextField), '不会被保存的文本');

      // Tap cancel
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      // Verify addFragment was NOT called
      expect(mockNotifier.addedTexts, isEmpty);

      // Dialog should be closed
      expect(find.text('快速捕捉'), findsNothing);
    });

    testWidgets('should not save when text is empty and 保存 is tapped',
        (tester) async {
      final mockNotifier = _MockCaptureNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            captureProvider.overrideWith(() => mockNotifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const QuickCaptureDialog(),
                      );
                    },
                    child: const Text('OPEN_DIALOG'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('OPEN_DIALOG'));
      await tester.pumpAndSettle();

      // Do NOT enter any text -- just tap save
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // Verify addFragment was NOT called (empty text is rejected)
      expect(mockNotifier.addedTexts, isEmpty);

      // Dialog should still be open (not closed on empty input)
      expect(find.text('快速捕捉'), findsOneWidget);
    });

    testWidgets('should show SnackBar after successful save', (tester) async {
      final mockNotifier = _MockCaptureNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            captureProvider.overrideWith(() => mockNotifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const QuickCaptureDialog(),
                      );
                    },
                    child: const Text('OPEN_DIALOG'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('OPEN_DIALOG'));
      await tester.pumpAndSettle();

      // Enter text
      await tester.enterText(find.byType(TextField), '灵感内容');

      // Tap save
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // SnackBar should show success message
      expect(find.text('灵感已保存'), findsOneWidget);
    });
  });

  group('QuickCaptureShortcut', () {
    testWidgets('should register Ctrl+Shift+N shortcut', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuickCaptureShortcut(
              child: const Scaffold(
                body: Text('TEST_CONTENT'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that QuickCaptureShortcut's Shortcuts widget is present.
      // MaterialApp and Scaffold add their own Shortcuts widgets, so we
      // check that at least one exists (ours is among them).
      expect(find.byType(Shortcuts), findsAtLeast(1));

      // Verify the child content is rendered
      expect(find.text('TEST_CONTENT'), findsOneWidget);

      // Verify our specific shortcut is registered by finding a Shortcuts
      // widget that contains the Ctrl+Shift+N -> QuickCaptureIntent mapping.
      // The Shortcuts widget stores its shortcuts in the `shortcuts` property
      // which is a Map<LogicalKeySet, Intent>.
      bool foundOurShortcut = false;
      for (final element in find.byType(Shortcuts).evaluate()) {
        final shortcutsWidget = element.widget as Shortcuts;
        // The shortcuts are stored in the internal manager; access via
        // checking if our intent type exists in the widget's debug properties.
        // Instead, we can check the `shortcuts` constructor param directly.
        final shortcuts = shortcutsWidget.shortcuts;
        if (shortcuts is Map<LogicalKeySet, Intent>) {
          if (shortcuts.values.any((intent) => intent is QuickCaptureIntent)) {
            foundOurShortcut = true;
            break;
          }
        }
      }
      expect(foundOurShortcut, isTrue);
    });

    testWidgets('should contain Actions for QuickCaptureIntent',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuickCaptureShortcut(
              child: const Scaffold(
                body: Text('TEST_CONTENT'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that QuickCaptureShortcut's Actions widget is present.
      // MaterialApp and Scaffold add their own Actions widgets, so we
      // check that at least one exists with our QuickCaptureIntent action.
      bool foundOurAction = false;
      for (final element in find.byType(Actions).evaluate()) {
        final actionsWidget = element.widget as Actions;
        if (actionsWidget.actions.containsKey(QuickCaptureIntent)) {
          foundOurAction = true;
          break;
        }
      }
      expect(foundOurAction, isTrue);
    });
  });
}
