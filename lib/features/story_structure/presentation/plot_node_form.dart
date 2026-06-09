import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';

/// Form for creating and editing plot nodes.
///
/// Opens as an AlertDialog for both create and edit modes.
/// In edit mode, the [node] parameter provides existing values.
class PlotNodeForm extends ConsumerStatefulWidget {
  final PlotNode? node;

  const PlotNodeForm({super.key, this.node});

  @override
  ConsumerState<PlotNodeForm> createState() => _PlotNodeFormState();
}

class _PlotNodeFormState extends ConsumerState<PlotNodeForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _summaryController;
  late final TextEditingController _chapterController;

  PlotNodeWritingStatus _status = PlotNodeWritingStatus.notStarted;
  PlotNodeStructuralRole _role = PlotNodeStructuralRole.setup;
  bool _isSaving = false;

  bool get _isEditing => widget.node != null;

  @override
  void initState() {
    super.initState();
    final node = widget.node;
    _titleController = TextEditingController(text: node?.title ?? '');
    _summaryController = TextEditingController(text: node?.summary ?? '');
    _chapterController = TextEditingController(
      text: (node?.chapter ?? 1).toString(),
    );
    _status = node?.writingStatus ?? PlotNodeWritingStatus.notStarted;
    _role = node?.structuralRole ?? PlotNodeStructuralRole.setup;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _chapterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? '编辑情节点' : '新建情节点'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '标题 *',
                  hintText: '例如：初遇、转折、高潮',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _chapterController,
                decoration: const InputDecoration(
                  labelText: '章节号 *',
                  hintText: '1',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _summaryController,
                decoration: const InputDecoration(
                  labelText: '摘要',
                  hintText: '简要描述这个情节节点',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PlotNodeStructuralRole>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: '结构角色'),
                items: PlotNodeStructuralRole.values
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(_roleLabel(r)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _role = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PlotNodeWritingStatus>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: '写作状态'),
                items: PlotNodeWritingStatus.values
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(_statusLabel(s)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
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
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? '保存' : '创建'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final chapterText = _chapterController.text.trim();
    final chapter = int.tryParse(chapterText) ?? 1;

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入标题')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(plotNodeNotifierProvider.notifier);

      if (_isEditing) {
        await notifier.save(
          widget.node!.copyWith(
            title: title,
            chapter: chapter,
            summary: _summaryController.text.trim(),
            writingStatus: _status,
            structuralRole: _role,
          ),
        );
      } else {
        await notifier.add(
          PlotNode(
            id: '',
            title: title,
            chapter: chapter,
            summary: _summaryController.text.trim(),
            writingStatus: _status,
            structuralRole: _role,
            manualOrder: 0,
            createdAt: DateTime.now(),
          ),
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _roleLabel(PlotNodeStructuralRole r) {
    return switch (r) {
      PlotNodeStructuralRole.setup => '铺垫',
      PlotNodeStructuralRole.development => '发展',
      PlotNodeStructuralRole.turn => '转折',
      PlotNodeStructuralRole.climax => '高潮',
      PlotNodeStructuralRole.resolution => '收束',
    };
  }

  String _statusLabel(PlotNodeWritingStatus s) {
    return switch (s) {
      PlotNodeWritingStatus.notStarted => '未写',
      PlotNodeWritingStatus.drafting => '草稿',
      PlotNodeWritingStatus.complete => '完成',
      PlotNodeWritingStatus.needsRevision => '待改',
    };
  }
}
