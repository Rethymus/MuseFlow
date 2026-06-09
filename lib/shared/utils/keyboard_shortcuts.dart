import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/features/capture/presentation/quick_capture.dart';

/// Intent for triggering the quick-capture overlay dialog.
///
/// Registered with [LogicalKeySet] for Ctrl+Shift+N.
class QuickCaptureIntent extends Intent {
  const QuickCaptureIntent();
}

/// Widget that wraps its child with [Shortcuts] and [Actions] for the
/// global Ctrl+Shift+N quick-capture shortcut.
///
/// Per RESEARCH Pitfall 6: Place high in the widget tree so the shortcut
/// works from any branch. Wraps the Scaffold body in AppShellScaffold.
class QuickCaptureShortcut extends ConsumerWidget {
  final Widget child;

  const QuickCaptureShortcut({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyN,
        ): const QuickCaptureIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          QuickCaptureIntent: CallbackAction<QuickCaptureIntent>(
            onInvoke: (_) => _showQuickCapture(context, ref),
          ),
        },
        child: child,
      ),
    );
  }

  void _showQuickCapture(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => const QuickCaptureDialog());
  }
}
