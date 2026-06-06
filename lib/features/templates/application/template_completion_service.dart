import 'dart:convert';

import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:museflow/features/templates/application/template_draft.dart';
import 'package:museflow/features/stats/application/token_audit_service.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:openai_dart/openai_dart.dart';

typedef TemplateCompletionStream =
    Stream<String> Function(List<ChatMessage> messages);

class TemplateCompletionResult {
  const TemplateCompletionResult({
    required this.draft,
    required this.succeeded,
    this.errorMessage,
  });

  final TemplateDraft draft;
  final bool succeeded;
  final String? errorMessage;
}

class TemplateCompletionService {
  TemplateCompletionService({
    this.openAIAdapter,
    this.apiKey,
    this.baseUrl,
    this.model,
    this.completionStream,
    this.auditService,
  });

  final OpenAIAdapter? openAIAdapter;
  final String? apiKey;
  final String? baseUrl;
  final String? model;
  final TemplateCompletionStream? completionStream;
  final TokenAuditService? auditService;

  Future<TemplateCompletionResult> completeBlankFields(
    TemplateDraft draft, {
    String? manuscriptId,
  }) async {
    try {
      final messages = _buildMessages(draft);
      // Capture input for audit (use story concept)
      final inputText = draft.storyConcept;

      final buffer = StringBuffer();

      if (completionStream != null) {
        // Test path
        final stream = completionStream!.call(messages);
        await for (final chunk in stream) {
          buffer.write(chunk);
        }
      } else {
        // Production path with audit
        final stream = openAIAdapter!.createStream(
          apiKey: apiKey!,
          baseUrl: baseUrl!,
          model: model!,
          messages: messages,
          onUsage: (usage) {
            // Only record if audit service is provided
            auditService?.recordAudit(
              usage: usage,
              modelName: model!,
              operationType: AuditOperationType.templateComplete,
              manuscriptId: manuscriptId ?? '',
              chapterId: null,
              inputText: inputText,
              outputText: buffer.toString(),
            );
          },
        );
        await for (final chunk in stream) {
          buffer.write(chunk);
        }
      }

      final decoded = jsonDecode(buffer.toString()) as Map<String, dynamic>;
      return TemplateCompletionResult(
        draft: _applyCompletion(draft, decoded),
        succeeded: true,
      );
    } catch (error) {
      return TemplateCompletionResult(
        draft: draft,
        succeeded: false,
        errorMessage: error.toString(),
      );
    }
  }

  List<ChatMessage> _buildMessages(TemplateDraft draft) {
    return [
      ChatMessage.system(
        '你是 MuseFlow 模板补全助手。只返回严格 JSON，不要返回 Markdown。只补全空白字段，保留模板默认值和用户编辑值。',
      ),
      ChatMessage.user(
        jsonEncode({
          'storyConcept': draft.storyConcept,
          'draft': _draftToJson(draft),
          'responseShape': {
            'world': {
              'name': '',
              'description': '',
              'rules': '',
              'factions': '',
              'geography': '',
              'techLevel': '',
              'aliases': '',
            },
            'characters': [
              {
                'draftId': 'character-0',
                'name': '',
                'personality': '',
                'appearance': '',
                'backstory': '',
                'aliases': '',
              },
            ],
          },
        }),
      ),
    ];
  }

  Map<String, dynamic> _draftToJson(TemplateDraft draft) {
    return {
      'templateId': draft.templateId,
      'world': {
        'name': draft.world.name.value,
        'description': draft.world.description.value,
        'rules': draft.world.rules.value,
        'factions': draft.world.factions.value,
        'geography': draft.world.geography.value,
        'techLevel': draft.world.techLevel.value,
        'aliases': draft.world.aliases.value,
      },
      'characters': [
        for (final character in draft.characters)
          {
            'draftId': character.draftId,
            'name': character.name.value,
            'personality': character.personality.value,
            'appearance': character.appearance.value,
            'backstory': character.backstory.value,
            'aliases': character.aliases.value,
          },
      ],
    };
  }

  TemplateDraft _applyCompletion(
    TemplateDraft draft,
    Map<String, dynamic> json,
  ) {
    final worldJson = json['world'] as Map<String, dynamic>? ?? const {};
    final characterItems = json['characters'] as List<dynamic>? ?? const [];

    final updatedWorld = draft.world.copyWith(
      name: draft.world.name.aiFill(worldJson['name'] as String? ?? ''),
      description: draft.world.description.aiFill(
        worldJson['description'] as String? ?? '',
      ),
      rules: draft.world.rules.aiFill(worldJson['rules'] as String? ?? ''),
      factions: draft.world.factions.aiFill(
        worldJson['factions'] as String? ?? '',
      ),
      geography: draft.world.geography.aiFill(
        worldJson['geography'] as String? ?? '',
      ),
      techLevel: draft.world.techLevel.aiFill(
        worldJson['techLevel'] as String? ?? '',
      ),
      aliases: draft.world.aliases.aiFill(
        worldJson['aliases'] as String? ?? '',
      ),
    );

    final completionsById = <String, Map<String, dynamic>>{};
    for (final item in characterItems) {
      if (item is! Map<String, dynamic>) continue;
      final id = item['draftId'] as String?;
      if (id != null) completionsById[id] = item;
    }

    final updatedCharacters = [
      for (final character in draft.characters)
        _applyCharacterCompletion(
          character,
          completionsById[character.draftId] ?? const {},
        ),
    ];

    return draft.copyWith(world: updatedWorld, characters: updatedCharacters);
  }

  CharacterCardDraft _applyCharacterCompletion(
    CharacterCardDraft character,
    Map<String, dynamic> json,
  ) {
    return character.copyWith(
      name: character.name.aiFill(json['name'] as String? ?? ''),
      personality: character.personality.aiFill(
        json['personality'] as String? ?? '',
      ),
      appearance: character.appearance.aiFill(
        json['appearance'] as String? ?? '',
      ),
      backstory: character.backstory.aiFill(json['backstory'] as String? ?? ''),
      aliases: character.aliases.aiFill(json['aliases'] as String? ?? ''),
    );
  }
}
