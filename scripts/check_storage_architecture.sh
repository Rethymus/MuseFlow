#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

status=0

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required for storage architecture validation" >&2
  exit 1
fi

type_id_count="$(grep -Ec '^[[:space:]]+static const int [[:alnum:]_]+ = [0-9]+;' lib/core/infrastructure/hive_adapters.dart)"
registered_adapter_count="$(grep -Ec '^[[:space:]]+Hive\.registerAdapter\(' lib/main.dart)"
mapfile -t source_boxes < <(
  python3 - <<'PY' | sort -u
import pathlib
import re

pattern = re.compile(r"""Hive\.openBox(?:<[^>]+>)?\s*\(\s*(['"])([^'"]+)\1""", re.S)
for path in pathlib.Path("lib").rglob("*.dart"):
    text = path.read_text(encoding="utf-8")
    for match in pattern.finditer(text):
        print(match.group(2))
PY
)
source_box_count="${#source_boxes[@]}"
mapfile -t documented_boxes < <(
  grep -E '^\| [0-9]+ \| `[^`]+` \|' docs/storage-architecture.md |
    sed -E 's/^\| [0-9]+ \| `([^`]+)`.*/\1/' |
    sort -u
)

require_in_file() {
  local file="$1"
  local needle="$2"
  local message="$3"

  if ! grep -Fq "$needle" "$file"; then
    echo "$message" >&2
    status=1
  fi
}

require_regex_in_file() {
  local file="$1"
  local pattern="$2"
  local message="$3"

  if ! grep -Eq "$pattern" "$file"; then
    echo "$message" >&2
    status=1
  fi
}

require_in_file \
  docs/storage-architecture.md \
  "$source_box_count 个 Box" \
  "docs/storage-architecture.md must document the current $source_box_count Hive boxes"

require_in_file \
  docs/storage-architecture.md \
  "注册 $type_id_count 个 TypeAdapter" \
  "docs/storage-architecture.md must document the current $type_id_count Hive TypeAdapters"

require_in_file \
  docs/storage-architecture.md \
  '| 4 | `chapter_summaries` | 🔓 | ChapterSummary | 11 |' \
  'docs/storage-architecture.md must list the chapter_summaries box with TypeId 11'

require_in_file \
  docs/storage-architecture.md \
  '| `chapterId` | String | 必填 | 所属章节；同时作为 `chapter_summaries` box key |' \
  'docs/storage-architecture.md must document chapter_summaries as keyed by chapterId'

require_in_file \
  docs/storage-architecture.md \
  'lib/core/presentation/providers_core.dart' \
  'docs/storage-architecture.md must point encrypted settings and ai_providers wiring at providers_core.dart'

require_in_file \
  docs/storage-architecture.md \
  'lib/core/presentation/providers_structure.dart' \
  'docs/storage-architecture.md must point style_profiles wiring at providers_structure.dart'

require_in_file \
  docs/platform/SECRET_STORAGE_BOUNDARY.md \
  'AI provider API keys | Provider ID, prefixed by `api_key_` inside `SecureStorageService`' \
  'docs/platform/SECRET_STORAGE_BOUNDARY.md must define the AI API key secure-storage owner'

require_in_file \
  docs/platform/SECRET_STORAGE_BOUNDARY.md \
  'Hive settings encryption key | `hive_encryption_key`, passed through `SecureStorageService`' \
  'docs/platform/SECRET_STORAGE_BOUNDARY.md must define the Hive encryption key boundary'

require_in_file \
  docs/platform/SECRET_STORAGE_BOUNDARY.md \
  'scripts/check_storage_architecture.sh' \
  'docs/platform/SECRET_STORAGE_BOUNDARY.md must list scripts/check_storage_architecture.sh as the boundary guard'

for boundary_check in \
  'scripts/check_storage_architecture.sh' \
  'test/infrastructure/secure_storage_test.dart' \
  'test/features/ai/application/provider_service_test.dart'
do
  require_in_file \
    docs/platform/SECRET_STORAGE_BOUNDARY.md \
    "$boundary_check" \
    "docs/platform/SECRET_STORAGE_BOUNDARY.md must list $boundary_check in focused verification"

  if [[ ! -e "$boundary_check" ]]; then
    echo "docs/platform/SECRET_STORAGE_BOUNDARY.md references missing verification target: $boundary_check" >&2
    status=1
  fi
done

require_in_file \
  SECURITY.md \
  'Plaintext fallback storage for secrets is not allowed.' \
  'SECURITY.md must keep the plaintext fallback prohibition in the Secret Storage Policy'

require_in_file \
  SECURITY.md \
  'docs/platform/SECRET_STORAGE_BOUNDARY.md' \
  'SECURITY.md must link to docs/platform/SECRET_STORAGE_BOUNDARY.md'

require_in_file \
  CLAUDE.md \
  'API Key 通过平台安全存储加密保存，不写入 Hive 数据库' \
  'CLAUDE.md must keep API keys outside the Hive/local database privacy claim'

require_in_file \
  .claude/rules/02-museflow-architecture.md \
  'API Key 通过平台安全存储保存，不写入 Hive' \
  '.claude/rules/02-museflow-architecture.md must keep API keys out of the Hive storage rule'

require_in_file \
  .claude/skills/run-museflow/SKILL.md \
  'API key 仅通过 flutter_secure_storage 保存，不写入 Hive' \
  '.claude/skills/run-museflow/SKILL.md must keep API keys out of the Hive storage note'

if grep -Fq 'API Key加密存储在本地数据库' CLAUDE.md; then
  echo "CLAUDE.md must not describe API keys as stored in the local database" >&2
  status=1
fi

if grep -Fq 'API Key 加密、文稿仅存本地' docs/storage-architecture.md; then
  echo "docs/storage-architecture.md must not use the old ambiguous API Key privacy summary" >&2
  status=1
fi

if grep -Fq 'API Key 加密存储' .claude/rules/02-museflow-architecture.md; then
  echo ".claude/rules/02-museflow-architecture.md must not use the ambiguous old API Key storage wording" >&2
  status=1
fi

if grep -Fq 'API key 等配置仅存本地 Hive + flutter_secure_storage' .claude/skills/run-museflow/SKILL.md; then
  echo ".claude/skills/run-museflow/SKILL.md must not imply API keys are stored in Hive" >&2
  status=1
fi

if grep -Fq '无原生安全后端，被代码主动绕过' docs/storage-architecture.md; then
  echo "docs/storage-architecture.md must not imply Web API-key storage bypasses SecureStorageService" >&2
  status=1
fi

if grep -Fq '(绕过)' docs/storage-architecture.md; then
  echo "docs/storage-architecture.md must not describe Web secret handling as a bypass; document the flutter_secure_storage Web backend limitation instead" >&2
  status=1
fi

require_regex_in_file \
  lib/core/infrastructure/secure_storage_service.dart \
  "static const String _apiKeyPrefix = 'api_key_';" \
  'SecureStorageService must keep the documented api_key_ prefix for AI provider API keys'

require_regex_in_file \
  lib/core/infrastructure/secure_storage_service.dart \
  'FlutterSecureStorage' \
  'SecureStorageService must continue delegating secret persistence to flutter_secure_storage'

for forbidden_secure_storage_pattern in \
  "import 'dart:io'" \
  'path_provider' \
  'SharedPreferences' \
  'Hive.openBox' \
  'File(' \
  'Directory('
do
  if grep -Fq "$forbidden_secure_storage_pattern" lib/core/infrastructure/secure_storage_service.dart; then
    echo "SecureStorageService must not reintroduce plaintext or Hive fallback storage: $forbidden_secure_storage_pattern" >&2
    status=1
  fi
done

require_regex_in_file \
  lib/core/infrastructure/hive_adapters.dart \
  'static const int chapterSummary = 11;' \
  'HiveTypeIds.chapterSummary must remain TypeId 11 unless storage docs are updated'

require_regex_in_file \
  lib/core/presentation/providers_structure.dart \
  "Hive\\.openBox<dynamic>\\('chapter_summaries'\\)" \
  'chapterSummaryRepositoryProvider must continue opening the documented chapter_summaries box'

require_regex_in_file \
  lib/core/presentation/providers_core.dart \
  "Hive\\.openBox<dynamic>\\('ai_providers'\\)" \
  'providerRepositoryProvider must continue opening the documented ai_providers box'

require_regex_in_file \
  lib/features/ai/infrastructure/provider_repository.dart \
  '_secureStorage\.deleteApiKey\(id\)' \
  'ProviderRepository.delete must continue deleting the associated API key from secure storage'

require_regex_in_file \
  lib/core/presentation/providers_core.dart \
  'const encryptionKeyStoreKey = '\''hive_encryption_key'\'';' \
  'settingsRepositoryProvider must continue using the documented hive_encryption_key owner'

if [[ "$registered_adapter_count" -ne "$type_id_count" ]]; then
  echo "lib/main.dart registers $registered_adapter_count Hive adapters, but HiveTypeIds defines $type_id_count IDs" >&2
  status=1
fi

if [[ "${#documented_boxes[@]}" -ne "$source_box_count" ]]; then
  echo "docs/storage-architecture.md documents ${#documented_boxes[@]} Hive boxes, but source opens $source_box_count unique boxes" >&2
  status=1
fi

tmp_source_boxes="$(mktemp)"
tmp_documented_boxes="$(mktemp)"
trap 'rm -f "$tmp_source_boxes" "$tmp_documented_boxes"' EXIT
printf '%s\n' "${source_boxes[@]}" > "$tmp_source_boxes"
printf '%s\n' "${documented_boxes[@]}" > "$tmp_documented_boxes"

while IFS= read -r box; do
  [[ -z "$box" ]] && continue
  echo "docs/storage-architecture.md is missing Hive box opened by source: $box" >&2
  status=1
done < <(comm -23 "$tmp_source_boxes" "$tmp_documented_boxes")

while IFS= read -r box; do
  [[ -z "$box" ]] && continue
  echo "docs/storage-architecture.md documents Hive box not opened by source: $box" >&2
  status=1
done < <(comm -13 "$tmp_source_boxes" "$tmp_documented_boxes")

if ! grep -Fq 'scripts/check_storage_architecture.sh' .github/workflows/ci.yml; then
  echo ".github/workflows/ci.yml must keep scripts/check_storage_architecture.sh in CI" >&2
  status=1
fi

if ! grep -Fq 'scripts/check_storage_architecture.sh' docs/release/RELEASE_CHECKLIST.md; then
  echo "docs/release/RELEASE_CHECKLIST.md must list scripts/check_storage_architecture.sh in local verification" >&2
  status=1
fi

if ! grep -Fq 'scripts/check_storage_architecture.sh' .github/PULL_REQUEST_TEMPLATE.md; then
  echo ".github/PULL_REQUEST_TEMPLATE.md must list scripts/check_storage_architecture.sh in local verification" >&2
  status=1
fi

if ! grep -Fq 'scripts/check_storage_architecture.sh' CONTRIBUTING.md; then
  echo "CONTRIBUTING.md must list scripts/check_storage_architecture.sh in local checks" >&2
  status=1
fi

exit "$status"
