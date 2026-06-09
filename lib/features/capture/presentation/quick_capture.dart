import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/features/capture/presentation/capture_provider.dart';

/// Quick-capture overlay dialog for capturing fleeting ideas.
///
/// Per D-11: Triggered by Ctrl+Shift+N global shortcut.
/// Per D-12: Text-only minimal form, saves to default tag.
///
/// Shows an [AlertDialog] with a multiline [TextField], and two action
/// buttons: "保存" (save) and "取消" (cancel).
class QuickCaptureDialog extends ConsumerStatefulWidget {
  const QuickCaptureDialog({super.key});

  @override
  ConsumerState<QuickCaptureDialog> createState() => _QuickCaptureDialogState();
}

class _QuickCaptureDialogState extends ConsumerState<QuickCaptureDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Autofocus the text field when the dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _saveAndClose() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    ref.read(captureProvider.notifier).addFragment(text);
    Navigator.of(context).pop();

    // Show success snackbar on the scaffold messenger
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('灵感已保存'), duration: Duration(seconds: 2)),
    );
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('快速捕捉'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '输入你的灵感...',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _saveAndClose(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _cancel, child: const Text('取消')),
        ElevatedButton(onPressed: _saveAndClose, child: const Text('保存')),
      ],
    );
  }
}
