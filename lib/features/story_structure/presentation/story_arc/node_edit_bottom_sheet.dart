import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';

/// Bottom sheet form for creating or editing plot nodes from the graph.
class NodeEditBottomSheet extends ConsumerStatefulWidget {
  final PlotNode? node;
  final ValueChanged<PlotNode>? onSave;

  const NodeEditBottomSheet({super.key, this.node, this.onSave});

  @override
  ConsumerState<NodeEditBottomSheet> createState() =>
      _NodeEditBottomSheetState();
}

class _NodeEditBottomSheetState extends ConsumerState<NodeEditBottomSheet> {
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEditing ? '编辑节点' : '新建节点',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: '标题 *'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _chapterController,
                decoration: const InputDecoration(labelText: '章节号 *'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _summaryController,
                decoration: const InputDecoration(labelText: '摘要'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PlotNodeStructuralRole>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: '结构角色'),
                items: PlotNodeStructuralRole.values
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(_roleLabel(role)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _role = value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PlotNodeWritingStatus>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: '写作状态'),
                items: PlotNodeWritingStatus.values
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(_statusLabel(status)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('放弃修改'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditing ? '保存修改' : '保存节点'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入标题')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final chapter = int.tryParse(_chapterController.text.trim()) ?? 1;
      final summary = _summaryController.text.trim();
      final node = _isEditing
          ? widget.node!.copyWith(
              title: title,
              chapter: chapter,
              summary: summary,
              writingStatus: _status,
              structuralRole: _role,
            )
          : PlotNode(
              id: '',
              title: title,
              chapter: chapter,
              summary: summary,
              writingStatus: _status,
              structuralRole: _role,
              createdAt: DateTime.now(),
            );

      if (widget.onSave != null) {
        widget.onSave!(node);
      } else {
        final notifier = ref.read(plotNodeNotifierProvider.notifier);
        if (_isEditing) {
          await notifier.save(node);
        } else {
          await notifier.add(node);
        }
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

  String _roleLabel(PlotNodeStructuralRole role) {
    return switch (role) {
      PlotNodeStructuralRole.setup => '铺垫',
      PlotNodeStructuralRole.development => '发展',
      PlotNodeStructuralRole.turn => '转折',
      PlotNodeStructuralRole.climax => '高潮',
      PlotNodeStructuralRole.resolution => '收束',
    };
  }

  String _statusLabel(PlotNodeWritingStatus status) {
    return switch (status) {
      PlotNodeWritingStatus.notStarted => '未写',
      PlotNodeWritingStatus.drafting => '草稿',
      PlotNodeWritingStatus.complete => '完成',
      PlotNodeWritingStatus.needsRevision => '待改',
    };
  }
}
