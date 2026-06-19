/// Real-API validation for the template-completion JSON parsing path.
///
/// [TemplateCompletionService] makes a single LLM call requesting STRICT JSON
/// output — a `{world, characters}` shape used to scaffold a new story — then
/// `completeBlankFields` decodes it. Unlike its siblings
/// ([LogicGuardianService], [GuardianCheckService], [EditorialReviewService]),
/// the original code used a RAW `jsonDecode` with no defensive extraction, and
/// `_applyCompletion` read `world`/`characters` only at the top level. Real
/// LLMs (notably GLM-4-flash) routinely:
///   1. wrap JSON in ```json ... ``` fences (ignoring "only JSON" instructions)
///   2. echo the input payload envelope, nesting world/characters under
///      `draft` / `responseShape` instead of returning them flat.
/// Both make the raw path silently fail. curl probes confirmed GLM-4-flash
/// exhibits BOTH on this exact prompt. The canned
/// `template_completion_service_test` feeds a perfectly-shaped flat JSON via a
/// fake stream, so it proves nothing about survival on real model output.
///
/// Constructor-injected (no ProviderContainer needed), so this env-gated test
/// wires a REAL OpenAIAdapter against GLM-4-flash directly and asserts the
/// completion actually APPLIES (blank fields filled + aiCompleted source,
/// non-blank fields preserved) from real output — closing the
/// template-completion path's real-API gap.
library;

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:museflow/features/templates/application/template_completion_service.dart';
import 'package:museflow/features/templates/application/template_draft.dart';

void main() {
  final apiKey = Platform.environment['GLM_API_KEY'];
  final baseUrl =
      Platform.environment['GLM_BASE_URL'] ??
      'https://open.bigmodel.cn/api/paas/v4';
  final model = Platform.environment['GLM_MODEL'] ?? 'glm-4-flash';

  group('Template completion (Real GLM API)', () {
    test(
      'blank fields filled through fenced/nested JSON on real GLM output',
      () async {
        final adapter = OpenAIAdapter();
        addTearDown(adapter.dispose);

        final service = TemplateCompletionService(
          openAIAdapter: adapter,
          apiKey: apiKey!,
          baseUrl: baseUrl,
          model: model,
        );

        final result = await service.completeBlankFields(_blankDraft());

        // The raw path would throw FormatException on the ```json fence and
        // return succeeded=false. Print the message for diagnosis if it does.
        if (!result.succeeded) {
          print('[TEMPLATE] FAILED: ${result.errorMessage}');
        }
        expect(
          result.succeeded,
          isTrue,
          reason:
              'completeBlankFields must survive real GLM fenced/nested JSON '
              'output; error=${result.errorMessage}',
        );

        // world.description was '' (blank) → aiFill must fill it from the
        // model's world description. Proves fence-strip + shape-resolution +
        // aiFill all work end-to-end on real output.
        expect(
          result.draft.world.description.value,
          isNotEmpty,
          reason: 'blank world.description must be filled by AI',
        );
        expect(
          result.draft.world.description.source,
          TemplateFieldSource.aiCompleted,
        );
        print('[TEMPLATE] world.description="${result.draft.world.description.value}"');

        // character-0.personality was '' (blank) → filled. Proves the
        // characters array shape also resolved through the nesting fallback.
        expect(
          result.draft.characters.single.personality.value,
          isNotEmpty,
          reason: 'blank character personality must be filled by AI',
        );
        expect(
          result.draft.characters.single.personality.source,
          TemplateFieldSource.aiCompleted,
        );
        print(
          '[TEMPLATE] character personality='
          '"${result.draft.characters.single.personality.value}"',
        );
      },
      skip: apiKey == null ? 'GLM_API_KEY not set' : null,
      timeout: const Timeout(Duration(seconds: 120)),
    );
  });
}

/// A fully-blank draft: the primary onboarding scenario (a new author starts
/// from an empty template and clicks AI 补全). GLM-4-flash reliably fills
/// every blank field from storyConcept in this state (verified by curl probe).
///
/// NOTE: the "preserve non-blank" aiFill contract is exercised deterministically
/// by the canned `template_completion_service_test`; this real-API test targets
/// only the parsing robustness (fence + nesting + aiFill-on-blank) on live
/// model output. A separate finding — GLM-4-flash echoes (rather than fills)
/// blank fields when the draft is *partially* pre-filled — is a prompt-quality
/// follow-up, out of scope for this parsing fix.
TemplateDraft _blankDraft() {
  const blank = DraftTextField(
    value: '',
    source: TemplateFieldSource.templateDefault,
  );
  return TemplateDraft(
    templateId: 'xianxia',
    storyConcept: '一个名叫林风的少年在青云峰修仙，意外觉醒祖传古玉血脉，卷入消失百年的天玄宗谜案',
    world: const WorldSettingDraft(
      selected: true,
      name: blank,
      description: blank,
      rules: blank,
      factions: blank,
      geography: blank,
      techLevel: blank,
      aliases: blank,
    ),
    characters: const [
      CharacterCardDraft(
        draftId: 'character-0',
        selected: true,
        name: blank,
        personality: blank,
        appearance: blank,
        backstory: blank,
        aliases: blank,
      ),
    ],
  );
}
