import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';

/// Form for creating or editing a [ForeshadowingEntry].
///
/// Supports manual creation and selection-based prefill.
/// Includes simple/detailed mode, status, planted chapter, target resolution
/// chapter, source excerpt, and notes.
class ForeshadowingForm extends ConsumerStatefulWidget {
  /// Existing entry to edit. Null for creating a new entry.
  final ForeshadowingEntry? entry;

  /// Optional pre-filled source excerpt from editor selection.
  final String? prefilledExcerpt;

  /// Optional source location from editor selection.
  final SourceLocation? prefilledLocation;

  const ForeshadowingForm({
    super.key,
    this.entry,
    this.prefilledExcerpt,
    this.prefilledLocation,
  });

  @override
  ConsumerState<ForeshadowingForm> createState() => _ForeshadowingFormState();
}

class _ForeshadowingFormState extends ConsumerState<ForeshadowingForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _sourceExcerptController;
  late ForeshadowingMode _mode;
  late ForeshadowingStatus _status;
  late int _plantedChapter;
  int? _targetResolutionChapter;
  SourceLocation? _sourceLocation;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _titleController = TextEditingController(text: e?.title ?? '');
    _notesController = TextEditingController(text: e?.notes ?? '');
    _sourceExcerptController = TextEditingController(
      text: e?.sourceExcerpt ?? widget.prefilledExcerpt ?? '',
    );
    _mode = e?.mode ?? ForeshadowingMode.simple;
    _status = e?.status ?? ForeshadowingStatus.planted;
    _plantedChapter = e?.plantedChapter ?? 1;
    _targetResolutionChapter = e?.targetResolutionChapter;
    _sourceLocation = e?.sourceLocation ?? widget.prefilledLocation;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _sourceExcerptController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.entry != null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? '编辑伏笔' : '新建伏笔'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '标题 *',
                  hintText: '简要描述这条伏笔',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入标题';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Mode selector
              SegmentedButton<ForeshadowingMode>(
                segments: const [
                  ButtonSegment(
                    value: ForeshadowingMode.simple,
                    label: Text('简单'),
                    icon: Icon(Icons.checklist),
                  ),
                  ButtonSegment(
                    value: ForeshadowingMode.detailed,
                    label: Text('详细'),
                    icon: Icon(Icons.description_outlined),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (modes) => setState(() => _mode = modes.first),
              ),
              const SizedBox(height: 16),

              // Status (only in detailed mode or when editing)
              if (_mode == ForeshadowingMode.detailed || _isEditing) ...[
                DropdownButtonFormField<ForeshadowingStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: '状态',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ForeshadowingStatus.planted,
                      child: Text('已埋设'),
                    ),
                    DropdownMenuItem(
                      value: ForeshadowingStatus.developing,
                      child: Text('发展中'),
                    ),
                    DropdownMenuItem(
                      value: ForeshadowingStatus.resolved,
                      child: Text('已解决'),
                    ),
                    DropdownMenuItem(
                      value: ForeshadowingStatus.abandoned,
                      child: Text('已放弃'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Planted chapter
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _plantedChapter.toString(),
                      decoration: const InputDecoration(
                        labelText: '埋设章节 *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || int.tryParse(value) == null) {
                          return '请输入有效的章节号';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _plantedChapter = int.parse(value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: _targetResolutionChapter?.toString() ?? '',
                      decoration: const InputDecoration(
                        labelText: '计划解决章节',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onSaved: (value) {
                        _targetResolutionChapter =
                            value != null && value.isNotEmpty
                                ? int.parse(value)
                                : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Source excerpt
              TextFormField(
                controller: _sourceExcerptController,
                decoration: const InputDecoration(
                  labelText: '来源摘录',
                  hintText: '选中的原文或手动输入的关键线索',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: '备注',
                  hintText: '关于这条伏笔的补充说明',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(_isEditing ? '保存' : '创建'),
        ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final notifier = ref.read(foreshadowingNotifierProvider.notifier);

    if (_isEditing) {
      final updated = widget.entry!.copyWith(
        title: _titleController.text.trim(),
        mode: _mode,
        status: _status,
        plantedChapter: _plantedChapter,
        targetResolutionChapter: _targetResolutionChapter,
        sourceExcerpt: _sourceExcerptController.text.trim(),
        sourceLocation: _sourceLocation,
        notes: _notesController.text.trim(),
      );
      notifier.save(updated);
    } else {
      final entry = ForeshadowingEntry(
        id: '',
        title: _titleController.text.trim(),
        mode: _mode,
        status: _status,
        plantedChapter: _plantedChapter,
        targetResolutionChapter: _targetResolutionChapter,
        sourceExcerpt: _sourceExcerptController.text.trim(),
        sourceLocation: _sourceLocation,
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
      );
      notifier.add(entry);
    }

    Navigator.of(context).pop();
  }
}
