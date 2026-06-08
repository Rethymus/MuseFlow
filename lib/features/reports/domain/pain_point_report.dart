/// A single pain point issue from the development journey.
///
/// Categories match Phase 14/15 ISSUE-LOG format:
/// 功能缺陷, 体验摩擦, 缺失需求.
/// Severity: 高, 中, 低.
class PainPointIssue {
  const PainPointIssue({
    required this.id,
    required this.category,
    required this.severity,
    required this.requirement,
    required this.title,
    required this.description,
    required this.status,
  });

  /// Unique issue identifier (e.g. 'I-01').
  final String id;

  /// Category: 功能缺陷, 体验摩擦, or 缺失需求.
  final String category;

  /// Severity: 高, 中, or 低.
  final String severity;

  /// Associated requirement ID.
  final String requirement;

  /// Short issue title.
  final String title;

  /// Detailed description.
  final String description;

  /// Current status (e.g. 'open', 'closed').
  final String status;

  PainPointIssue copyWith({
    String? id,
    String? category,
    String? severity,
    String? requirement,
    String? title,
    String? description,
    String? status,
  }) {
    return PainPointIssue(
      id: id ?? this.id,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      requirement: requirement ?? this.requirement,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PainPointIssue &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          category == other.category &&
          severity == other.severity &&
          requirement == other.requirement &&
          title == other.title &&
          description == other.description &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      category.hashCode ^
      severity.hashCode ^
      requirement.hashCode ^
      title.hashCode ^
      description.hashCode ^
      status.hashCode;
}

/// Structured report aggregating pain points from the development journey.
///
/// Issues are classified by category (功能缺陷, 体验摩擦, 缺失需求)
/// and severity (高, 中, 低). Total counts are computed from the issues list.
class PainPointReport {
  PainPointReport({required this.issues});

  /// All pain point issues.
  final List<PainPointIssue> issues;

  /// Count of issues with severity '高'.
  int get totalHigh =>
      issues.where((i) => i.severity == '高').length;

  /// Count of issues with severity '中'.
  int get totalMedium =>
      issues.where((i) => i.severity == '中').length;

  /// Count of issues with severity '低'.
  int get totalLow =>
      issues.where((i) => i.severity == '低').length;

  PainPointReport copyWith({List<PainPointIssue>? issues}) {
    return PainPointReport(issues: issues ?? this.issues);
  }
}
