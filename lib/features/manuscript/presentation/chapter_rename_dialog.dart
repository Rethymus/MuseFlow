import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog for renaming a chapter with a pre-filled title input field.
///
/// Per T-11-05 (mitigate): Title field validates non-empty and max 100 chars.
class ChapterRenameDialog extends StatefulWidget {
  const ChapterRenameDialog({
    super.key,
    required this.currentTitle,
  });

  /// The current chapter title to pre-fill.
  final String currentTitle;

  @override
  State<ChapterRenameDialog> createState() => _ChapterRenameDialogState();
}

class _ChapterRenameDialogState extends State<ChapterRenameDialog> {
  late final TextEditingController _titleController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.currentTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String? _validate(String value) {
    if (value.trim().isEmpty) return '章节标题不能为空';
    if (value.trim().length > 100) return '章节标题不能超过100个字符';
    return null;
  }

  void _submit() {
    final title = _titleController.text;
    final error = _validate(title);
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    Navigator.of(context).pop(title.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('重命名章节'),
      content: TextField(
        controller: _titleController,
        autofocus: true,
        maxLength: 100,
        decoration: InputDecoration(
          hintText: '章节标题',
          errorText: _errorText,
          border: const OutlineInputBorder(),
        ),
        inputFormatters: [
          LengthLimitingTextInputFormatter(100),
        ],
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
