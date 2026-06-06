import 'dart:async';
import 'dart:convert';

import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:museflow/features/knowledge/domain/skill_document.dart';
import 'package:museflow/features/stats/application/token_audit_service.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:openai_dart/openai_dart.dart';

class SkillGenerationService {
  final OpenAIAdapter openAIAdapter;
  final String apiKey;
  final String baseUrl;
  final String model;
  final TokenAuditService? auditService;

  const SkillGenerationService({
    required this.openAIAdapter,
    required this.apiKey,
    required this.baseUrl,
    required this.model,
    this.auditService,
  });

  Stream<String> generateSkillStream(String conceptDescription, {String? manuscriptId}) async* {
    final messages = [
      ChatMessage.system(
        '你是小说世界观设定顾问。请根据作者的概念生成结构化中文设定文档，必须包含以下 Markdown 二级标题：## 力量等级体系、## 门派/势力关系、## 世界规则、## 禁忌/限制、## 专用术语。内容要可执行、具体、避免空泛。',
      ),
      ChatMessage.user('设定概念：\n$conceptDescription'),
    ];

    // Capture input for audit (use concept description)
    final inputText = conceptDescription;
    final buffer = StringBuffer();

    final stream = openAIAdapter.createStream(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      messages: messages,
      maxTokens: 4096,
      onUsage: (usage) {
        // Only record if audit service is provided
        auditService?.recordAudit(
          usage: usage,
          modelName: model,
          operationType: AuditOperationType.skillGen,
          manuscriptId: manuscriptId ?? '',
          chapterId: null,
          inputText: inputText,
          outputText: buffer.toString(),
        );
      },
    );

    await for (final chunk in stream) {
      buffer.write(chunk);
      yield chunk;
    }
  }

  SkillDocument parseSkillDocument({
    required String name,
    required String description,
    required String rawContent,
  }) {
    final sections = _parseJson(rawContent) ?? _parseMarkdown(rawContent);
    return SkillDocument(
      id: '',
      name: name,
      description: description,
      content: rawContent,
      sections: sections.isEmpty
          ? SkillSections(rawContent: rawContent)
          : sections.copyWith(rawContent: rawContent),
      createdAt: DateTime.now(),
    );
  }

  SkillSections? _parseJson(String rawContent) {
    try {
      final decoded = jsonDecode(rawContent);
      if (decoded is! Map<String, dynamic>) return null;
      return SkillSections(
        powerHierarchy: decoded['powerHierarchy'] as String?,
        factionRelations: decoded['factionRelations'] as String?,
        rules: decoded['rules'] as String?,
        taboos: decoded['taboos'] as String?,
        terminology: decoded['terminology'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  SkillSections _parseMarkdown(String rawContent) {
    final sections = <String, String>{};
    final current = StringBuffer();
    String? currentTitle;

    void flush() {
      final title = currentTitle;
      if (title == null) return;
      sections[title] = current.toString().trim();
      current.clear();
    }

    for (final line in rawContent.split('\n')) {
      if (line.startsWith('## ')) {
        flush();
        currentTitle = line.substring(3).trim();
      } else {
        current.writeln(line);
      }
    }
    flush();

    String? pick(List<String> titles) {
      for (final title in titles) {
        final value = sections.entries
            .where((entry) => entry.key.contains(title))
            .map((entry) => entry.value)
            .firstOrNull;
        if (value != null && value.isNotEmpty) return value;
      }
      return null;
    }

    return SkillSections(
      powerHierarchy: pick(['力量', '等级']),
      factionRelations: pick(['门派', '势力', '关系']),
      rules: pick(['规则']),
      taboos: pick(['禁忌', '限制']),
      terminology: pick(['术语', '专用']),
    );
  }
}
