class WritingSession {
  const WritingSession({
    required this.id,
    this.projectId,
    this.documentId,
    required this.startedAt,
    this.endedAt,
    this.humanUnits = 0,
    this.aiUnits = 0,
    this.editSeconds = 0,
  });

  final String id;
  final String? projectId;
  final String? documentId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int humanUnits;
  final int aiUnits;
  final int editSeconds;

  int get totalUnits => humanUnits + aiUnits;

  WritingSession copyWith({
    String? id,
    String? projectId,
    String? documentId,
    DateTime? startedAt,
    DateTime? endedAt,
    int? humanUnits,
    int? aiUnits,
    int? editSeconds,
  }) {
    return WritingSession(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      documentId: documentId ?? this.documentId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      humanUnits: humanUnits ?? this.humanUnits,
      aiUnits: aiUnits ?? this.aiUnits,
      editSeconds: editSeconds ?? this.editSeconds,
    );
  }

  factory WritingSession.fromJson(Map<String, dynamic> json) {
    return WritingSession(
      id: json['id'] as String,
      projectId: json['projectId'] as String?,
      documentId: json['documentId'] as String?,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      humanUnits: json['humanUnits'] as int? ?? 0,
      aiUnits: json['aiUnits'] as int? ?? 0,
      editSeconds: json['editSeconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'documentId': documentId,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'humanUnits': humanUnits,
      'aiUnits': aiUnits,
      'editSeconds': editSeconds,
    };
  }
}
