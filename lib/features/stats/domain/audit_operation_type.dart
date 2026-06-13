/// Enhanced enum for AI operation types with Chinese labels and functional groups.
///
/// Per D-04: 4 functional groups:
/// - organize: 碎片整理
/// - edit: 语气改写、段落润色、自由输入、扩写、缩写、对话生成、场景描写
/// - worldview: Skill生成、开篇生成、偏离检测
/// - template: 模板补全
enum AuditOperationType {
  synthesis('碎片整理', 'organize'),
  rewrite('语气改写', 'edit'),
  polish('段落润色', 'edit'),
  freeInput('自由输入', 'edit'),
  expand('扩写', 'edit'),
  compress('缩写', 'edit'),
  dialogue('对话生成', 'edit'),
  scene('场景描写', 'edit'),
  skillGen('Skill生成', 'worldview'),
  opening('开篇生成', 'worldview'),
  deviationDetect('偏离检测', 'worldview'),
  editorialReview('编辑评审', 'worldview'),
  templateComplete('模板补全', 'template');

  const AuditOperationType(this.label, this.group);

  /// Chinese display label for UI
  final String label;

  /// Functional group per D-04: organize, edit, worldview, template
  final String group;
}
