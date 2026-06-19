import 'dart:convert';

import 'package:museflow/features/ai/domain/ai_adapter.dart';
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

  final AIAdapter? openAIAdapter;
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
        // Production path with audit.
        // temperature 0.3 (aligned with LogicGuardianService /
        // GuardianCheckService structured-JSON calls): structured JSON output
        // is far less likely to malform (unescaped quotes / truncation) at low
        // temperature, which keeps the completion reliably parseable on real
        // providers like GLM-4-flash.
        final stream = openAIAdapter!.createStream(
          apiKey: apiKey!,
          baseUrl: baseUrl!,
          model: model!,
          messages: messages,
          temperature: 0.3,
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

      // Real LLMs (notably GLM-4-flash) wrap JSON in ```json fences despite
      // the "only JSON" instruction; a raw jsonDecode would throw and silently
      // fail the whole AI-completion. Defensive extraction mirrors
      // LogicGuardianService / GuardianCheckService / EditorialReview.
      final decoded = jsonDecode(
        _extractJsonObject(buffer.toString()),
      ) as Map<String, dynamic>;
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
        '你是 MuseFlow 模板补全助手。根据故事概念，为模板中【值为空】的字段生成具体、丰富的中文内容'
        '（每处空白都必须填入生成的设定，禁止返回空字符串，禁止原样复制输入）。'
        '已有值的字段（如 name/rules/backstory）保持原值不变。'
        '只返回严格 JSON，不要 Markdown。'
        '输出顶层结构：{"world":{...},"characters":[{...}]}（world 对象 + characters 数组），'
        '不要包裹在 draft 或 responseShape 键下。',
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

  /// Resolves the {world, characters} shape from a model response that may
  /// nest it under a wrapper key instead of returning it flat at the top level.
  ///
  /// The prompt's `responseShape` hint shows the model a `{storyConcept,
  /// draft, responseShape}` envelope, so real LLMs (notably GLM-4-flash)
  /// frequently echo that envelope and nest `world`/`characters` under `draft`
  /// or `responseShape` rather than returning the flat shape the canned
  /// contract assumes. Prefer top-level, then fall back to `draft` then
  /// `responseShape`. Returns [root] unchanged if no nested shape is found.
  Map<String, dynamic> _resolveShape(Map<String, dynamic> root) {
    if (root['world'] != null || root['characters'] != null) {
      return root;
    }
    for (final key in const ['draft', 'responseShape']) {
      final nested = root[key];
      if (nested is Map<String, dynamic> &&
          (nested['world'] != null || nested['characters'] != null)) {
        return nested;
      }
    }
    return root;
  }

  /// Extracts a JSON object from a model response that may wrap it in a
  /// markdown code fence (```json ... ```) or surround it with prose.
  ///
  /// Mirrors the defensive extraction in LogicGuardianService._extractJson /
  /// GuardianCheckService._extractJson / EditorialReview.parseFromLLM: real
  /// LLMs routinely ignore "only JSON" instructions and wrap structured output
  /// in fences, which would make a raw [jsonDecode] throw and silently fail
  /// the whole AI-completion. Isolates the first `{` ... last `}` when no
  /// fence is present so leading/trailing prose is also tolerated.
  String _extractJsonObject(String response) {
    final trimmed = response.trim();

    // Handle ```json ... ``` code-block wrapping.
    if (trimmed.startsWith('```')) {
      var withoutOpen = trimmed.replaceFirst(
        RegExp(r'^```(?:json)?\s*\n?'),
        '',
      );
      withoutOpen = withoutOpen.replaceFirst(RegExp(r'\n?```\s*$'), '');
      return withoutOpen.trim();
    }

    // Fall back to isolating the JSON object from surrounding prose.
    final startIndex = trimmed.indexOf('{');
    final endIndex = trimmed.lastIndexOf('}');
    if (startIndex != -1 && endIndex > startIndex) {
      return trimmed.substring(startIndex, endIndex + 1);
    }

    return trimmed;
  }

  TemplateDraft _applyCompletion(
    TemplateDraft draft,
    Map<String, dynamic> json,
  ) {
    // Real LLMs (notably GLM-4-flash) frequently echo the input payload
    // envelope, nesting world/characters under 'draft' / 'responseShape'
    // instead of returning the flat shape. Resolve to whichever level holds
    // the shape; canned callers that pass flat JSON are unaffected.
    final shape = _resolveShape(json);
    final worldJson = shape['world'] as Map<String, dynamic>? ?? const {};
    final characterItems = shape['characters'] as List<dynamic>? ?? const [];

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
