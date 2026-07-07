#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

status=0

require_at_least_occurrences() {
  local file="$1"
  local needle="$2"
  local minimum="$3"
  local message="$4"
  local actual

  actual="$(grep -Fc "$needle" "$file")"
  if [[ "$actual" -lt "$minimum" ]]; then
    echo "$message (expected at least $minimum, found $actual)" >&2
    status=1
  fi
}

# NOTE: this guard must stay portable across minimal CI runners (ubuntu-latest
# does not ship ripgrep). Use grep -rEn / grep -qF instead of rg.

mapfile -t direct_adapter_refs < <(
  grep -rEn --exclude='providers_ai.dart' \
    'openaiAdapterProvider|claudeAdapterProvider' lib || true
)

if [[ "${#direct_adapter_refs[@]}" -gt 0 ]]; then
  echo "Production code must route AI service calls through activeAdapterProvider:" >&2
  printf '%s\n' "${direct_adapter_refs[@]}" >&2
  status=1
fi

mapfile -t direct_openai_client_refs < <(
  grep -rEn --exclude='openai_adapter.dart' \
    'OpenAIClient\.withApiKey|OpenAIClient\(' lib || true
)

for ref in "${direct_openai_client_refs[@]}"; do
  # ProviderService uses a bounded, non-streaming SDK client for the explicit
  # "Test Connection" probe. Feature generation paths must still go through
  # activeAdapterProvider and AIAdapter.
  if [[ "$ref" =~ ^lib/features/ai/application/provider_service\.dart:[0-9]+:[[:space:]]+(final[[:space:]]+)?client[[:space:]]*=[[:space:]]*OpenAIClient\($ ]]; then
    continue
  fi

  echo "Production AI code must use injected AIAdapter instead of constructing OpenAIClient directly:" >&2
  echo "$ref" >&2
  status=1
done

mapfile -t direct_openai_adapter_refs < <(
  grep -rEn --exclude='providers_ai.dart' --exclude='openai_adapter.dart' \
    'OpenAIAdapter\(' lib || true
)

if [[ "${#direct_openai_adapter_refs[@]}" -gt 0 ]]; then
  echo "Production code must obtain OpenAIAdapter through provider wiring instead of constructing it directly:" >&2
  printf '%s\n' "${direct_openai_adapter_refs[@]}" >&2
  status=1
fi

mapfile -t direct_claude_adapter_refs < <(
  grep -rEn --exclude='providers_ai.dart' --exclude='claude_adapter.dart' \
    'ClaudeAdapter\(' lib || true
)

if [[ "${#direct_claude_adapter_refs[@]}" -gt 0 ]]; then
  echo "Production code must obtain ClaudeAdapter through provider wiring instead of constructing it directly:" >&2
  printf '%s\n' "${direct_claude_adapter_refs[@]}" >&2
  status=1
fi

mapfile -t direct_anthropic_client_refs < <(
  grep -rEn --exclude='claude_adapter.dart' \
    'anthropic\.AnthropicClient\(' lib || true
)

for ref in "${direct_anthropic_client_refs[@]}"; do
  # ProviderService uses a bounded, non-streaming SDK client for the explicit
  # "Test Connection" probe. Feature generation paths must still go through
  # activeAdapterProvider and AIAdapter.
  if [[ "$ref" =~ ^lib/features/ai/application/provider_service\.dart:[0-9]+:[[:space:]]+(final[[:space:]]+)?client[[:space:]]*=[[:space:]]*anthropic\.AnthropicClient\($ ]]; then
    continue
  fi

  echo "Production Claude code must use injected AIAdapter instead of constructing AnthropicClient directly:" >&2
  echo "$ref" >&2
  status=1
done

if ! grep -qF 'final activeAdapterProvider = Provider<AIAdapter>' lib/core/presentation/providers_ai.dart; then
  echo "providers_ai.dart must keep activeAdapterProvider as the central AI adapter dispatch point" >&2
  status=1
fi

if ! grep -Fq 'provider?.type == AiProviderType.claude' lib/core/presentation/providers_ai.dart; then
  echo "activeAdapterProvider must dispatch Claude providers by AiProviderType.claude" >&2
  status=1
fi

if ! grep -Fq 'return ref.watch(claudeAdapterProvider);' lib/core/presentation/providers_ai.dart; then
  echo "activeAdapterProvider must return claudeAdapterProvider for Claude providers" >&2
  status=1
fi

if ! grep -Fq 'return ref.watch(openaiAdapterProvider);' lib/core/presentation/providers_ai.dart; then
  echo "activeAdapterProvider must return openaiAdapterProvider for OpenAI-compatible providers" >&2
  status=1
fi

if ! grep -qF 'final modelListFetcherProvider = Provider<OpenAIAdapter>' lib/core/presentation/providers_ai.dart; then
  echo "providers_ai.dart must keep modelListFetcherProvider as the dedicated OpenAI-compatible model-list fetcher" >&2
  status=1
fi

if ! grep -Fq 'ref.read(modelListFetcherProvider)' lib/features/ai/presentation/provider_management_notifier.dart; then
  echo "ProviderManagementNotifier.fetchModels must use modelListFetcherProvider for /v1/models discovery" >&2
  status=1
fi

mapfile -t model_management_streaming_adapter_refs < <(
  grep -En 'ref\.(read|watch)\((activeAdapterProvider|openaiAdapterProvider|claudeAdapterProvider)\)' \
    lib/features/ai/presentation/provider_management_notifier.dart || true
)

if [[ "${#model_management_streaming_adapter_refs[@]}" -gt 0 ]]; then
  echo "ProviderManagementNotifier must not use streaming adapters for provider setup model discovery:" >&2
  printf '%s\n' "${model_management_streaming_adapter_refs[@]}" >&2
  status=1
fi

require_at_least_occurrences \
  lib/core/presentation/providers_ai.dart \
  'final adapter = ref.watch(activeAdapterProvider);' \
  1 \
  'chapterSummarizationServiceProvider must inject activeAdapterProvider at least once'

require_at_least_occurrences \
  lib/core/presentation/providers_knowledge.dart \
  'openAIAdapter: ref.watch(activeAdapterProvider),' \
  3 \
  'knowledge/report AI services must all inject activeAdapterProvider'

require_at_least_occurrences \
  lib/core/presentation/providers_structure.dart \
  'openAIAdapter: ref.watch(activeAdapterProvider),' \
  2 \
  'template/opening AI services must inject activeAdapterProvider'

require_at_least_occurrences \
  lib/core/presentation/providers_structure.dart \
  'aiAdapter: ref.watch(activeAdapterProvider),' \
  2 \
  'guardian AI services must inject activeAdapterProvider'

for service in GuardianCheckService LogicGuardianService; do
  if ! grep -Fq "$service" lib/core/presentation/providers_structure.dart; then
    echo "providers_structure.dart must continue wiring $service" >&2
    status=1
  fi
done

guardian_active_adapter_injections="$(
  grep -Fc 'aiAdapter: ref.watch(activeAdapterProvider),' \
    lib/core/presentation/providers_structure.dart
)"
if [[ "$guardian_active_adapter_injections" -lt 2 ]]; then
  echo "GuardianCheckService and LogicGuardianService must both inject ref.watch(activeAdapterProvider)" >&2
  status=1
fi

if ! grep -Fq 'required AIAdapter aiAdapter' \
  lib/features/story_structure/application/guardian_check_service.dart; then
  echo "GuardianCheckService must keep AIAdapter constructor injection instead of constructing a concrete client" >&2
  status=1
fi

if ! grep -Fq 'required AIAdapter aiAdapter' \
  lib/features/story_structure/application/logic_guardian_service.dart; then
  echo "LogicGuardianService must keep AIAdapter constructor injection instead of constructing a concrete client" >&2
  status=1
fi

for file in \
  docs/release/RELEASE_CHECKLIST.md \
  .github/PULL_REQUEST_TEMPLATE.md \
  CONTRIBUTING.md \
  README.md \
  README.en.md
do
  if ! grep -Fq 'test/core/presentation/active_adapter_wiring_test.dart' "$file"; then
    echo "$file must list the active adapter wiring regression test" >&2
    status=1
  fi
done

if ! grep -Fq 'scripts/check_ai_adapter_wiring.sh' .github/workflows/ci.yml; then
  echo ".github/workflows/ci.yml must keep scripts/check_ai_adapter_wiring.sh in CI" >&2
  status=1
fi

if ! grep -Fq 'scripts/check_ai_adapter_wiring.sh' .github/PULL_REQUEST_TEMPLATE.md; then
  echo ".github/PULL_REQUEST_TEMPLATE.md must list scripts/check_ai_adapter_wiring.sh in local verification" >&2
  status=1
fi

if ! grep -Fq 'scripts/check_ai_adapter_wiring.sh' CONTRIBUTING.md; then
  echo "CONTRIBUTING.md must list scripts/check_ai_adapter_wiring.sh in local checks" >&2
  status=1
fi

exit "$status"
