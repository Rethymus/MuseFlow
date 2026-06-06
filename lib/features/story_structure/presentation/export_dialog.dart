import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/features/story_structure/application/export_service.dart';
import 'package:museflow/features/story_structure/domain/export_bundle.dart';

/// Dialog for exporting manuscript to local file.
///
/// Per FRMT-04 and D-17: Exports to TXT, Markdown, or JSON format,
/// writing only to a user-selected local file path. Shows progress,
/// success, and error states.
class ExportDialog extends ConsumerStatefulWidget {
  /// The export bundle containing manuscript and structured data.
  final ExportBundle bundle;

  /// Callback for performing the actual export.
  final Future<void> Function(ExportFormat format, String content) onExport;

  const ExportDialog({
    super.key,
    required this.bundle,
    required this.onExport,
  });

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  ExportFormat _selectedFormat = ExportFormat.txt;
  String? _selectedPath;
  bool _isExporting = false;
  String? _errorMessage;
  bool _exportSuccess = false;

  static final _exportService = ExportService(
    fileWriter: _noopWriter,
  );

  // No-op writer for content building (actual writing happens via onExport)
  static Future<void> _noopWriter(String path, String content) async {}

  Future<void> _pickPath() async {
    setState(() {
      _selectedPath = null;
      _errorMessage = null;
    });

    // Show a simple dialog to enter a path (placeholder for file_picker)
    final path = await showDialog<String>(
      context: context,
      builder: (ctx) => _PathInputDialog(
        initialPath: _selectedPath,
        defaultExtension: _selectedFormat.extension,
      ),
    );

    if (path != null && path.isNotEmpty) {
      setState(() {
        _selectedPath = path;
        _errorMessage = null;
        _exportSuccess = false;
      });
    }
  }

  Future<void> _doExport() async {
    if (_selectedPath == null) return;

    setState(() {
      _isExporting = true;
      _errorMessage = null;
      _exportSuccess = false;
    });

    try {
      final content = _exportService.buildContent(
        widget.bundle,
        _selectedFormat,
      );
      await widget.onExport(_selectedFormat, content);

      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportSuccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('导出稿件'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info text
            Text(
              '文件只会保存到你选择的本地路径。',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),

            // Format selector
            const Text(
              '导出格式',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SegmentedButton<ExportFormat>(
              segments: const [
                ButtonSegment(value: ExportFormat.txt, label: Text('TXT')),
                ButtonSegment(
                    value: ExportFormat.markdown, label: Text('Markdown')),
                ButtonSegment(value: ExportFormat.json, label: Text('JSON')),
              ],
              selected: {_selectedFormat},
              onSelectionChanged: (formats) {
                setState(() {
                  _selectedFormat = formats.first;
                  _selectedPath = null;
                  _exportSuccess = false;
                  _errorMessage = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // Format description
            Text(
              _formatDescription(_selectedFormat),
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            // Chapter count info when chapters present
            if (widget.bundle.chapters.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '包含 ${widget.bundle.chapters.length} 个章节',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Path picker
            const Text(
              '保存路径',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedPath ?? '未选择路径',
                    style: TextStyle(
                      color: _selectedPath != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _pickPath,
                  child: const Text('选择路径'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress / Success / Error states
            if (_isExporting)
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('正在导出...'),
                ],
              ),
            if (_exportSuccess)
              Row(
                children: [
                  Icon(Icons.check_circle, color: colorScheme.tertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '已导出至: $_selectedPath',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),

            // Content summary for JSON
            if (_selectedFormat == ExportFormat.json) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JSON 导出包含:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _summaryItem('稿件文本'),
                    _summaryItem(
                        '伏笔条目 (${widget.bundle.foreshadowingEntries.length})'),
                    _summaryItem(
                        '情节点 (${widget.bundle.plotNodes.length})'),
                    _summaryItem(
                        '守护标注 (${widget.bundle.guardianAnnotations.length})'),
                    _summaryItem(
                        '角色卡 (${widget.bundle.characterCards.length})'),
                    _summaryItem(
                        '世界设定 (${widget.bundle.worldSettings.length})'),
                    _summaryItem(
                        '技能文档 (${widget.bundle.skillDocuments.length})'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
        ElevatedButton(
          onPressed:
              _selectedPath != null && !_isExporting ? _doExport : null,
          child: const Text('导出'),
        ),
      ],
    );
  }

  Widget _summaryItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 2),
      child: Row(
        children: [
          const Text('• ', style: TextStyle(fontSize: 12)),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  String _formatDescription(ExportFormat format) {
    return switch (format) {
      ExportFormat.txt => '纯文本格式，包含可读的稿件正文。',
      ExportFormat.markdown => 'Markdown 格式，保留段落分隔。',
      ExportFormat.json => '完整 JSON 格式，包含稿件文本和所有结构化故事数据。',
    };
  }
}

/// Simple dialog for entering a file path.
///
/// In production, this is replaced by file_picker's saveFile dialog.
/// This widget exists for testability and as a fallback.
class _PathInputDialog extends StatefulWidget {
  final String? initialPath;
  final String defaultExtension;

  const _PathInputDialog({
    this.initialPath,
    required this.defaultExtension,
  });

  @override
  State<_PathInputDialog> createState() => _PathInputDialogState();
}

class _PathInputDialogState extends State<_PathInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPath ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择保存路径'),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: '文件路径',
          hintText: '例如: ~/Documents/manuscript${widget.defaultExtension}',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () =>
              Navigator.of(context).pop(_controller.text),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
