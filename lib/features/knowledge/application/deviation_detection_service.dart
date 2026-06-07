import 'dart:convert';

import 'package:museflow/features/ai/domain/ai_adapter.dart';
import 'package:museflow/features/knowledge/domain/skill_document.dart';
import 'package:museflow/features/stats/application/token_audit_service.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:openai_dart/openai_dart.dart';

enum DeviationSeverity { low, medium, clear }

class DeviationWarning {
  final String description;
  final DeviationSeverity severity;
  final String skillName;
  final String? suggestedFix;

  const DeviationWarning({
    required this.description,
    required this.severity,
    required this.skillName,
    this.suggestedFix,
  });

  factory DeviationWarning.fromJson(Map<String, dynamic> json) {
    return DeviationWarning(
      description: json['description'] as String? ?? '',
      severity: _parseSeverity(json['severity'] as String?),
      skillName: json['skillName'] as String? ?? '',
      suggestedFix: json['suggestedFix'] as String?,
    );
  }

  static DeviationSeverity _parseSeverity(String? value) {
    return switch (value) {
      'clear' => DeviationSeverity.clear,
      'medium' => DeviationSeverity.medium,
      _ => DeviationSeverity.low,
    };
  }
}

class DeviationResult {
  final List<DeviationWarning> warnings;

  const DeviationResult({required this.warnings});

  bool get hasWarnings => warnings.isNotEmpty;
}

class DeviationDetectionService {
  final AIAdapter openAIAdapter;
  final String apiKey;
  final String baseUrl;
  final String model;
  final TokenAuditService? auditService;

  const DeviationDetectionService({
    required this.openAIAdapter,
    required this.apiKey,
    required this.baseUrl,
    required this.model,
    this.auditService,
  });

  Future<DeviationResult> detectDeviations(
    String text,
    List<SkillDocument> activeSkills, {
    String? manuscriptId,
    String? chapterId,
  }) async {
    if (text.trim().isEmpty || activeSkills.isEmpty) {
      return const DeviationResult(warnings: []);
    }

    final prompt = _buildPrompt(text, activeSkills);
    // Capture input for audit
    final inputText = 'System: 你是小说设定一致性审校员，只输出 JSON。\nUser: $prompt';

    try {
      final buffer = StringBuffer();
      final stream = openAIAdapter.createStream(
        apiKey: apiKey,
        baseUrl: baseUrl,
        model: model,
        messages: [
          ChatMessage.system('你是小说设定一致性审校员，只输出 JSON。'),
          ChatMessage.user(prompt),
        ],
        maxTokens: 1024,
        onUsage: (usage) {
          // Only record if audit service is provided
          auditService?.recordAudit(
            usage: usage,
            modelName: model,
            operationType: AuditOperationType.deviationDetect,
            manuscriptId: manuscriptId ?? '',
            chapterId: chapterId,
            inputText: inputText,
            outputText: buffer.toString(),
          );
        },
      );
      await for (final token in stream) {
        buffer.write(token);
      }
      return _parseResult(buffer.toString());
    } catch (_) {
      return const DeviationResult(warnings: []);
    }
  }

  String _buildPrompt(String text, List<SkillDocument> activeSkills) {
    final buffer = StringBuffer();
    buffer.writeln('检查下面文本是否违背激活的世界观设定。');
    buffer.writeln(
      '只返回 JSON 数组，每项包含 description、severity(low|medium|clear)、skillName、suggestedFix。',
    );
    buffer.writeln('只报告 medium 或 clear 级别的问题；低置信度不要报告。');
    buffer.writeln('\n【待检查文本】\n$text');
    buffer.writeln('\n【激活设定】');
    for (final skill in activeSkills) {
      buffer.writeln('\n### ${skill.name}');
      buffer.writeln(skill.toContextString);
    }
    return buffer.toString();
  }

  DeviationResult _parseResult(String raw) {
    try {
      final cleaned = raw
          .trim()
          .replaceAll('```json', '')
          .replaceAll('```', '');
      final decoded = jsonDecode(cleaned);
      if (decoded is! List) return const DeviationResult(warnings: []);
      final warnings = decoded
          .whereType<Map>()
          .map(
            (item) =>
                DeviationWarning.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((warning) => warning.severity != DeviationSeverity.low)
          .toList();
      return DeviationResult(warnings: warnings);
    } catch (_) {
      return const DeviationResult(warnings: []);
    }
  }
}
