import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/application/manuscript_notifier.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/manuscript/domain/manuscript_genre.dart';

/// Quick-create dialog for a new manuscript.
///
/// Provides title input (required, non-empty validation) and genre
/// dropdown populated from [ManuscriptGenre.presets]. On confirm,
/// creates the manuscript via [ManuscriptNotifier.create] and dismisses.
class ManuscriptCreateDialog extends ConsumerStatefulWidget {
  const ManuscriptCreateDialog({super.key});

  @override
  ConsumerState<ManuscriptCreateDialog> createState() =>
      _ManuscriptCreateDialogState();
}

class _ManuscriptCreateDialogState
    extends ConsumerState<ManuscriptCreateDialog> {
  final _titleController = TextEditingController();
  final _customGenreController = TextEditingController();
  String _selectedGenre = ManuscriptGenre.presets.first;
  bool _isCustomGenre = false;
  bool _isCreating = false;
  String? _titleError;

  @override
  void dispose() {
    _titleController.dispose();
    _customGenreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('创建文稿'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '标题',
                hintText: '输入文稿标题',
                errorText: _titleError,
              ),
              autofocus: true,
              onChanged: (_) => _clearTitleError(),
              onSubmitted: (_) => _handleCreate(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGenre,
              decoration: const InputDecoration(
                labelText: '类型',
              ),
              items: [
                ...ManuscriptGenre.presets.map(
                  (genre) => DropdownMenuItem(
                    value: genre,
                    child: Text(genre),
                  ),
                ),
                const DropdownMenuItem(
                  value: '自定义',
                  child: Text('自定义'),
                ),
              ],
              onChanged: (value) {
                if (value == '自定义') {
                  setState(() {
                    _isCustomGenre = true;
                    _selectedGenre = '自定义';
                  });
                } else {
                  setState(() {
                    _isCustomGenre = false;
                    _selectedGenre = value ?? ManuscriptGenre.presets.first;
                  });
                }
              },
            ),
            if (_isCustomGenre) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customGenreController,
                decoration: const InputDecoration(
                  labelText: '自定义类型',
                  hintText: '输入自定义类型名称',
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isCreating ? null : _handleCreate,
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('创建'),
        ),
      ],
    );
  }

  void _clearTitleError() {
    if (_titleError != null) {
      setState(() => _titleError = null);
    }
  }

  Future<void> _handleCreate() async {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      setState(() => _titleError = '请输入标题');
      return;
    }

    final genre = _isCustomGenre
        ? _customGenreController.text.trim()
        : _selectedGenre;

    if (genre.isEmpty) {
      return;
    }

    setState(() => _isCreating = true);

    final now = DateTime.now();
    final coverLetter = title.substring(0, title.length.clamp(0, 2));

    final manuscript = Manuscript(
      id: '',
      title: title,
      genre: genre,
      coverLetter: coverLetter,
      status: '构思中',
      targetWordCount: 50000,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await ref.read(manuscriptNotifierProvider.notifier).create(manuscript);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e')),
        );
      }
    }
  }
}
