import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog for creating a new chapter with a title input field.
///
/// Per T-11-05 (mitigate): Title field validates non-empty and max 100 chars.
class ChapterCreateDialog extends StatefulWidget {
  const ChapterCreateDialog({
    super.key,
    this.initialTitle = '',
  });

  /// Optional initial title to pre-fill.
  final String initialTitle;

  @override
  State<ChapterCreateDialog> createState() => _ChapterCreateDialogState();
}

class _ChapterCreateDialogState extends State<ChapterCreateDialog> {
  late final TextEditingController _titleController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
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
      title: const Text('新建章节'),
      content: TextField(
        key: const Key('chapter_title_field'),
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
          child: const Text('创建'),
        ),
      ],
    );
  }
}
