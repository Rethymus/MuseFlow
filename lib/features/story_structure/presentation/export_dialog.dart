import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
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
  ///
  /// For text formats (TXT, Markdown, JSON), [textContent] is populated and
  /// [binaryContent] is null. For binary formats (DOCX), [binaryContent]
  /// is populated and [textContent] is null.
  final Future<void> Function(
    ExportFormat format,
    String path, {
    String? textContent,
    List<int>? binaryContent,
  })
  onExport;

  const ExportDialog({super.key, required this.bundle, required this.onExport});

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  ExportFormat _selectedFormat = ExportFormat.txt;
  String? _selectedPath;
  bool _isExporting = false;
  String? _errorMessage;
  bool _exportSuccess = false;

  static final _exportService = ExportService(fileWriter: _noopWriter);

  // No-op writer for content building (actual writing happens via onExport)
  static Future<void> _noopWriter(String path, String content) async {}

  Future<void> _pickPath() async {
    final currentPath = _selectedPath;
    setState(() {
      _errorMessage = null;
    });

    final suggestedPath = currentPath ?? _suggestedPath(_selectedFormat);
    final path = await showDialog<String>(
      context: context,
      builder: (ctx) =>
          _PathInputDialog(initialPath: suggestedPath, format: _selectedFormat),
    );

    if (path != null) {
      setState(() {
        _selectedPath = path;
        _errorMessage = null;
        _exportSuccess = false;
      });
    }
  }

  Future<void> _doExport() async {
    final path = _selectedPath;
    if (path == null) return;

    setState(() {
      _isExporting = true;
      _errorMessage = null;
      _exportSuccess = false;
    });

    try {
      if (_selectedFormat.isBinary) {
        final bytes = _exportService.buildDocxBytes(widget.bundle);
        await widget.onExport(_selectedFormat, path, binaryContent: bytes);
      } else {
        final content = _exportService.buildContent(
          widget.bundle,
          _selectedFormat,
        );
        await widget.onExport(_selectedFormat, path, textContent: content);
      }

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info text
              Text(
                kIsWeb ? '文件会由浏览器下载到默认下载位置。' : '文件只会保存到你选择的本地路径。',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),

              // Format selector
              const Text('导出格式', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<ExportFormat>(
                segments: const [
                  ButtonSegment(value: ExportFormat.txt, label: Text('TXT')),
                  ButtonSegment(
                    value: ExportFormat.markdown,
                    label: Text('Markdown'),
                  ),
                  ButtonSegment(value: ExportFormat.json, label: Text('JSON')),
                  ButtonSegment(value: ExportFormat.docx, label: Text('DOCX')),
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
              Text(
                kIsWeb ? '下载文件名' : '保存路径',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedPath ?? _suggestedPath(_selectedFormat),
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
                    child: Text(kIsWeb ? '设置文件名' : '选择路径'),
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
                        kIsWeb
                            ? '已开始下载: $_selectedPath'
                            : '已导出至: $_selectedPath',
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
                        '伏笔条目 (${widget.bundle.foreshadowingEntries.length})',
                      ),
                      _summaryItem('情节点 (${widget.bundle.plotNodes.length})'),
                      _summaryItem(
                        '守护标注 (${widget.bundle.guardianAnnotations.length})',
                      ),
                      _summaryItem(
                        '角色卡 (${widget.bundle.characterCards.length})',
                      ),
                      _summaryItem(
                        '世界设定 (${widget.bundle.worldSettings.length})',
                      ),
                      _summaryItem(
                        '技能文档 (${widget.bundle.skillDocuments.length})',
                      ),
                    ],
                  ),
                ),
              ],

              // Content summary for DOCX
              if (_selectedFormat == ExportFormat.docx) ...[
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
                        'DOCX 导出包含:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (widget.bundle.chapters.isNotEmpty) ...[
                        _summaryItem(
                          '${widget.bundle.chapters.length} 个章节（标题 + 正文）',
                        ),
                      ] else ...[
                        _summaryItem('完整稿件正文'),
                      ],
                      _summaryItem('Word Heading1 / BodyText 排版'),
                      _summaryItem('可在 Word / WPS / LibreOffice 中打开'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
        ElevatedButton(
          key: const Key('export_button'),
          onPressed: _selectedPath != null && !_isExporting ? _doExport : null,
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
      ExportFormat.docx => 'Word 文档格式，支持章节标题和段落排版。',
    };
  }

  String _suggestedPath(ExportFormat format) {
    return 'museflow-export${format.extension}';
  }
}

/// Simple dialog for entering a file path.
///
/// In production, this is replaced by file_picker's saveFile dialog.
/// This widget exists for testability and as a fallback.
class _PathInputDialog extends StatefulWidget {
  final String? initialPath;
  final ExportFormat format;

  const _PathInputDialog({this.initialPath, required this.format});

  @override
  State<_PathInputDialog> createState() => _PathInputDialogState();
}

class _PathInputDialogState extends State<_PathInputDialog> {
  late final TextEditingController _controller;
  String? _errorText;

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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kIsWeb
                ? '请输入以 ${widget.format.extension} 结尾的下载文件名。'
                : '请输入以 ${widget.format.extension} 结尾的本地文件路径。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '文件路径',
              hintText: kIsWeb
                  ? '例如: manuscript${widget.format.extension}'
                  : '例如: ~/Documents/manuscript${widget.format.extension}',
              errorText: _errorText,
            ),
            onChanged: (_) {
              if (_errorText == null) return;
              setState(() {
                _errorText = null;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(onPressed: _confirm, child: const Text('确定')),
      ],
    );
  }

  void _confirm() {
    final normalized = _controller.text.trim();
    final validation = _validatePath(normalized, widget.format);
    if (validation != null) {
      setState(() {
        _errorText = validation;
      });
      return;
    }
    Navigator.of(context).pop(normalized);
  }
}

String? _validatePath(String path, ExportFormat format) {
  if (path.isEmpty) {
    return '请输入保存路径';
  }
  if (path.endsWith('/') || path.endsWith(r'\')) {
    return '请输入包含文件名的完整路径';
  }
  final filename = path.split(RegExp(r'[/\\]')).last;
  if (filename.trim().isEmpty || filename == '.' || filename == '..') {
    return '请输入有效文件名';
  }
  if (!filename.toLowerCase().endsWith(format.extension)) {
    return '文件名必须以 ${format.extension} 结尾';
  }
  return null;
}
