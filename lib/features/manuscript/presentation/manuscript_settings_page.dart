import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/application/manuscript_notifier.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/manuscript/domain/manuscript_genre.dart';

const _manuscriptTitleMaxLength = 100;
const _customGenreMaxLength = 20;

/// Manuscript metadata editing page.
///
/// Loads a manuscript by [manuscriptId] and provides form fields for
/// title, genre, description, and target word count. Save button
/// persists changes via [ManuscriptNotifier.save].
class ManuscriptSettingsPage extends ConsumerStatefulWidget {
  const ManuscriptSettingsPage({super.key, required this.manuscriptId});

  final String manuscriptId;

  @override
  ConsumerState<ManuscriptSettingsPage> createState() =>
      _ManuscriptSettingsPageState();
}

class _ManuscriptSettingsPageState
    extends ConsumerState<ManuscriptSettingsPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetWordCountController = TextEditingController();
  String _selectedGenre = ManuscriptGenre.presets.first;
  bool _isCustomGenre = false;
  final _customGenreController = TextEditingController();

  bool _isLoaded = false;
  bool _isSaving = false;
  Manuscript? _loadedManuscript;
  String? _titleError;
  String? _genreError;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetWordCountController.dispose();
    _customGenreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manuscriptsAsync = ref.watch(manuscriptNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('文稿设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回文稿库',
          onPressed: () => context.go('/editor'),
        ),
      ),
      body: manuscriptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('加载失败: $error'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(manuscriptNotifierProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (manuscripts) {
          if (!_isLoaded) {
            final manuscript = manuscripts
                .where((m) => m.id == widget.manuscriptId)
                .firstOrNull;

            if (manuscript != null) {
              _loadManuscript(manuscript);
            } else if (manuscripts.isNotEmpty) {
              // Manuscripts loaded but ID not found
              return const Center(child: Text('未找到该文稿'));
            }
          }

          if (_loadedManuscript == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 600,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: '标题',
                      border: const OutlineInputBorder(),
                      errorText: _titleError,
                      counterText: '',
                    ),
                    maxLength: _manuscriptTitleMaxLength,
                    maxLengthEnforcement: MaxLengthEnforcement.none,
                    onChanged: (_) => _clearTitleError(),
                  ),
                  const SizedBox(height: 20),

                  // Genre
                  DropdownButtonFormField<String>(
                    key: const Key('manuscript-settings-genre-dropdown'),
                    initialValue: _isCustomGenre ? '自定义' : _selectedGenre,
                    decoration: const InputDecoration(
                      labelText: '类型',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      ...ManuscriptGenre.presets.map(
                        (genre) =>
                            DropdownMenuItem(value: genre, child: Text(genre)),
                      ),
                      const DropdownMenuItem(value: '自定义', child: Text('自定义')),
                    ],
                    onChanged: (value) {
                      if (value == '自定义') {
                        setState(() => _isCustomGenre = true);
                      } else {
                        setState(() {
                          _isCustomGenre = false;
                          _selectedGenre = value!;
                        });
                      }
                    },
                  ),
                  if (_isCustomGenre) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customGenreController,
                      decoration: InputDecoration(
                        labelText: '自定义类型',
                        border: const OutlineInputBorder(),
                        errorText: _genreError,
                        counterText: '',
                      ),
                      maxLength: _customGenreMaxLength,
                      maxLengthEnforcement: MaxLengthEnforcement.none,
                      onChanged: (_) => _clearGenreError(),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Description
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: '简介',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 20),

                  // Target word count
                  TextField(
                    controller: _targetWordCountController,
                    decoration: const InputDecoration(
                      labelText: '目标字数',
                      border: OutlineInputBorder(),
                      suffixText: '字',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _handleSave,
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('保存'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _loadManuscript(Manuscript manuscript) {
    _loadedManuscript = manuscript;
    _titleController.text = manuscript.title;
    _descriptionController.text = manuscript.description ?? '';
    _targetWordCountController.text = manuscript.targetWordCount.toString();

    final isPreset = ManuscriptGenre.presets.contains(manuscript.genre);
    if (isPreset) {
      _selectedGenre = manuscript.genre;
      _isCustomGenre = false;
    } else {
      _isCustomGenre = true;
      _customGenreController.text = manuscript.genre;
    }

    _isLoaded = true;
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

  Future<void> _handleSave() async {
    if (_loadedManuscript == null) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = '标题不能为空');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('标题不能为空')));
      return;
    }
    if (title.length > _manuscriptTitleMaxLength) {
      setState(() => _titleError = '标题不能超过100个字符');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('标题不能超过100个字符')));
      return;
    }

    final genre = _isCustomGenre
        ? _customGenreController.text.trim()
        : _selectedGenre;
    if (genre.isEmpty) {
      setState(() => _genreError = '请输入自定义类型');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入自定义类型')));
      return;
    }
    if (_isCustomGenre && genre.length > _customGenreMaxLength) {
      setState(() => _genreError = '类型不能超过20个字符');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('类型不能超过20个字符')));
      return;
    }

    final targetWordCount =
        int.tryParse(_targetWordCountController.text.trim()) ??
        _loadedManuscript!.targetWordCount;

    setState(() => _isSaving = true);

    final updated = _loadedManuscript!.copyWith(
      title: title,
      genre: genre,
      description: _descriptionController.text.trim(),
      targetWordCount: targetWordCount,
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(manuscriptNotifierProvider.notifier).save(updated);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存成功')));
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }
}
