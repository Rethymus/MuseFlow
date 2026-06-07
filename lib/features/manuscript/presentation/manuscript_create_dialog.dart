import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/application/manuscript_notifier.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/manuscript/domain/manuscript_genre.dart';

const _manuscriptTitleMaxLength = 100;
const _customGenreMaxLength = 20;

/// Quick-create dialog for a new manuscript.
///
/// Provides title input (required, non-empty validation) and genre
/// dropdown populated from [ManuscriptGenre.presets]. On confirm,
/// creates the manuscript via [ManuscriptNotifier.create] and dismisses.
class ManuscriptCreateDialog extends ConsumerStatefulWidget {
  const ManuscriptCreateDialog({
    super.key,
    this.initialCustomGenre = false,
  });

  final bool initialCustomGenre;

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
  String? _genreError;

  @override
  void initState() {
    super.initState();
    if (widget.initialCustomGenre) {
      _isCustomGenre = true;
      _selectedGenre = '自定义';
    }
  }

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
              key: const Key('manuscript_title'),
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '标题',
                hintText: '输入文稿标题',
                errorText: _titleError,
                counterText: '',
              ),
              maxLength: _manuscriptTitleMaxLength,
              maxLengthEnforcement: MaxLengthEnforcement.none,
              autofocus: true,
              onChanged: (_) => _clearTitleError(),
              onSubmitted: (_) => _handleCreate(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: const Key('manuscript-create-genre-dropdown'),
              initialValue: _selectedGenre,
              decoration: const InputDecoration(labelText: '类型'),
              items: [
                ...ManuscriptGenre.presets.map(
                  (genre) => DropdownMenuItem(value: genre, child: Text(genre)),
                ),
                const DropdownMenuItem(value: '自定义', child: Text('自定义')),
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
                key: const Key('manuscript_genre'),
                controller: _customGenreController,
                decoration: InputDecoration(
                  labelText: '自定义类型',
                  hintText: '输入自定义类型名称',
                  errorText: _genreError,
                  counterText: '',
                ),
                maxLength: _customGenreMaxLength,
                maxLengthEnforcement: MaxLengthEnforcement.none,
                onChanged: (_) => _clearGenreError(),
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

  void _clearGenreError() {
    if (_genreError != null) {
      setState(() => _genreError = null);
    }
  }

  Future<void> _handleCreate() async {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      setState(() => _titleError = '请输入标题');
      return;
    }
    if (title.length > _manuscriptTitleMaxLength) {
      setState(() => _titleError = '标题不能超过100个字符');
      return;
    }

    final genre = _isCustomGenre
        ? _customGenreController.text.trim()
        : _selectedGenre;

    if (genre.isEmpty) {
      setState(() => _genreError = '请输入自定义类型');
      return;
    }
    if (_isCustomGenre && genre.length > _customGenreMaxLength) {
      setState(() => _genreError = '类型不能超过20个字符');
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('创建失败: $e')));
      }
    }
  }
}
