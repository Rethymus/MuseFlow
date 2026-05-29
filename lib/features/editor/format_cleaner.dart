/// 格式清洗工具
/// 用于清理Markdown格式残留和其他格式问题
class FormatCleaner {
  // 需要清洗的格式模式
  static final List<_CleanRule> _cleanRules = [
    // 清除多余空行
    _CleanRule(
      pattern: RegExp(r'\n\s*\n\s*\n+'),
      replacement: '\n\n',
      description: '清除多余空行',
    ),

    // 清除行尾空格
    _CleanRule(
      pattern: RegExp(r'[ \t]+$', multiLine: true),
      replacement: '',
      description: '清除行尾空格',
    ),

    // 清除行首空格（保留缩进）
    _CleanRule(
      pattern: RegExp(r'^[^\S\n]+$', multiLine: true),
      replacement: '',
      description: '清除仅包含空格的行',
    ),

    // 统一中英文标点
    _CleanRule(
      pattern: RegExp(r'，'),
      replacement: ',',
      description: '中文逗号转英文',
    ),
    _CleanRule(
      pattern: RegExp(r'。'),
      replacement: '.',
      description: '中文句号转英文',
    ),
    _CleanRule(
      pattern: RegExp(r'；'),
      replacement: ';',
      description: '中文分号转英文',
    ),
    _CleanRule(
      pattern: RegExp(r'：'),
      replacement: ':',
      description: '中文冒号转英文',
    ),

    // 清除HTML注释
    _CleanRule(
      pattern: RegExp(r'<!--.*?-->', dotAll: true),
      replacement: '',
      description: '清除HTML注释',
    ),

    // 清除HTML标签（选择性）
    _CleanRule(
      pattern: RegExp(r'<\/?(?!br|p|strong|em|code)[a-z]+[^>]*>',
          multiLine: true, caseSensitive: false),
      replacement: '',
      description: '清除HTML标签',
    ),

    // 清除特殊格式的Markdown残留
    _CleanRule(
      pattern: RegExp(r'\*\*(.+?)\*\*'),
      replacement: r'\1',
      description: '清除粗体标记',
    ),
    _CleanRule(
      pattern: RegExp(r'__(.+?)__'),
      replacement: r'\1',
      description: '清除粗体标记（下划线）',
    ),
    _CleanRule(
      pattern: RegExp(r'\*(.+?)\*'),
      replacement: r'\1',
      description: '清除斜体标记',
    ),
    _CleanRule(
      pattern: RegExp(r'_(.+?)_'),
      replacement: r'\1',
      description: '清除斜体标记（下划线）',
    ),
    _CleanRule(
      pattern: RegExp(r'~~(.+?)~~'),
      replacement: r'\1',
      description: '清除删除线标记',
    ),

    // 清除链接语法（保留文本）
    _CleanRule(
      pattern: RegExp(r'\[([^\]]+)\]\([^\)]+\)'),
      replacement: r'\1',
      description: '清除Markdown链接',
    ),

    // 清除图片语法
    _CleanRule(
      pattern: RegExp(r'!\[([^\]]*)\]\([^\)]+\)'),
      replacement: r'\1',
      description: '清除Markdown图片',
    ),

    // 清除脚注
    _CleanRule(
      pattern: RegExp(r'\[\^([^\]]+)\]'),
      replacement: '',
      description: '清除脚注标记',
    ),

    // 清除多余空格
    _CleanRule(
      pattern: RegExp(r'  +'),
      replacement: ' ',
      description: '清除多余空格',
    ),

    // 清除制表符
    _CleanRule(
      pattern: RegExp(r'\t'),
      replacement: ' ',
      description: '制表符转空格',
    ),

    // 清除Unicode空白字符
    _CleanRule(
      pattern: RegExp(r'[​‌‍ ]'),
      replacement: '',
      description: '清除零宽字符',
    ),
  ];

  /// 清洗Markdown格式
  /// 返回清洗后的文本
  String cleanMarkdown(String text) {
    if (text.isEmpty) return text;

    String cleaned = text;

    // 应用所有清洗规则
    for (final rule in _cleanRules) {
      try {
        cleaned = cleaned.replaceAll(rule.pattern, rule.replacement);
      } catch (e) {
        // 忽略单个规则的错误，继续处理
        continue;
      }
    }

    // 后处理：确保文档格式正确
    cleaned = _postProcess(cleaned);

    return cleaned;
  }

  /// 轻量级清洗（只清除明显的格式残留）
  String cleanLight(String text) {
    if (text.isEmpty) return text;

    return text
        .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n') // 清除多余空行
        .replaceAll(RegExp(r'[ \t]+$', multiLine: true), '') // 清除行尾空格
        .replaceAll(RegExp(r'  +'), ' ') // 清除多余空格
        .trim();
  }

  /// 智能清洗（保留基本结构）
  String cleanSmart(String text) {
    if (text.isEmpty) return text;

    // 保留标题、列表、代码块等基本结构
    // 只清除内联格式标记
    return text
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'\1') // 清除粗体
        .replaceAll(RegExp(r'_(.+?)_'), r'\1') // 清除斜体
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'\1') // 清除链接
        .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n') // 清除多余空行
        .trim();
  }

  /// 转换为纯文本
  String toPlainText(String text) {
    if (text.isEmpty) return text;

    return text
        .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '') // 清除标题标记
        .replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '') // 清除列表标记
        .replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '') // 清除有序列表
        .replaceAll(RegExp(r'^>\s+', multiLine: true), '') // 清除引用
        .replaceAll(RegExp(r'```[\s\S]*?```'), '') // 清除代码块
        .replaceAll(RegExp(r'`[^`]+`'), r'') // 清除行内代码
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'\1') // 清除链接
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'\1') // 清除粗体
        .replaceAll(RegExp(r'_(.+?)_'), r'\1') // 清除斜体
        .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n') // 清除多余空行
        .trim();
  }

  /// 格式化文本（美化显示）
  String format(String text) {
    if (text.isEmpty) return text;

    return _formatText(text);
  }

  /// 检测文本格式
  FormatInfo detectFormat(String text) {
    final lines = text.split('\n');

    int markdownHeaders = 0;
    int markdownLists = 0;
    int htmlTags = 0;
    int codeBlocks = 0;

    for (final line in lines) {
      if (RegExp(r'^#{1,6}\s+').hasMatch(line)) {
        markdownHeaders++;
      }
      if (RegExp(r'^\s*[-*+]\s+').hasMatch(line)) {
        markdownLists++;
      }
      if (RegExp(r'<[a-z]+[^>]*>', caseSensitive: false).hasMatch(line)) {
        htmlTags++;
      }
      if (RegExp(r'```').hasMatch(line)) {
        codeBlocks++;
      }
    }

    return FormatInfo(
      hasMarkdown: markdownHeaders > 0 || markdownLists > 0,
      hasHTML: htmlTags > 0,
      hasCodeBlocks: codeBlocks > 0,
      markdownHeaderCount: markdownHeaders,
      markdownListCount: markdownLists,
      htmlTagCount: htmlTags,
    );
  }

  /// 获取清洗预览（显示将要执行的操作）
  List<CleanPreview> getCleanPreview(String text) {
    final List<CleanPreview> previews = [];

    for (final rule in _cleanRules) {
      final matches = rule.pattern.allMatches(text);
      if (matches.isNotEmpty) {
        previews.add(CleanPreview(
          description: rule.description,
          matchCount: matches.length,
          examples: matches.take(3).map((m) => m.group(0)!).toList(),
        ));
      }
    }

    return previews;
  }

  // 后处理：确保文本格式正确
  String _postProcess(String text) {
    // 确保文档不以空行开头
    text = text.trimLeft();

    // 确保文档有适当的结尾
    text = text.trimRight();

    // 确保段落之间只有一个空行
    text = text.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');

    return text;
  }

  // 智能格式化
  String _formatText(String text) {
    final lines = text.split('\n');
    final formatted = <String>[];

    for (var line in lines) {
      // 跳过空行和代码块
      if (line.trim().isEmpty || line.trim().startsWith('```')) {
        formatted.add(line);
        continue;
      }

      // 处理标题
      if (RegExp(r'^#{1,6}\s+').hasMatch(line)) {
        // 标题保持原样
        formatted.add(line);
        continue;
      }

      // 处理列表
      if (RegExp(r'^\s*[-*+]\s+').hasMatch(line)) {
        // 列表项保持原样
        formatted.add(line);
        continue;
      }

      // 处理引用
      if (RegExp(r'^>\s+').hasMatch(line)) {
        // 引用保持原样
        formatted.add(line);
        continue;
      }

      // 普通文本：首字母大写
      if (line.isNotEmpty) {
        final firstChar = line[0];
        final rest = line.substring(1);
        formatted.add(firstChar.toUpperCase() + rest);
      }
    }

    return formatted.join('\n');
  }

  void dispose() {
    // 清理资源
  }
}

// 清洗规则
class _CleanRule {
  final RegExp pattern;
  final String replacement;
  final String description;

  _CleanRule({
    required this.pattern,
    required this.replacement,
    required this.description,
  });
}

// 格式信息
class FormatInfo {
  final bool hasMarkdown;
  final bool hasHTML;
  final bool hasCodeBlocks;
  final int markdownHeaderCount;
  final int markdownListCount;
  final int htmlTagCount;

  FormatInfo({
    required this.hasMarkdown,
    required this.hasHTML,
    required this.hasCodeBlocks,
    required this.markdownHeaderCount,
    required this.markdownListCount,
    required this.htmlTagCount,
  });

  @override
  String toString() {
    return 'FormatInfo(hasMarkdown: $hasMarkdown, hasHTML: $hasHTML, '
        'hasCodeBlocks: $hasCodeBlocks, headers: $markdownHeaderCount, '
        'lists: $markdownListCount, htmlTags: $htmlTagCount)';
  }
}

// 清洗预览
class CleanPreview {
  final String description;
  final int matchCount;
  final List<String> examples;

  CleanPreview({
    required this.description,
    required this.matchCount,
    required this.examples,
  });

  @override
  String toString() {
    return 'CleanPreview(description: $description, matches: $matchCount, '
        'examples: ${examples.take(2).join(', ')}...)';
  }
}
