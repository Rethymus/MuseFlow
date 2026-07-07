#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

status=0

tracked_artifacts="$(
  git ls-files |
    grep -E '(^|/)(build|\.dart_tool|ephemeral|coverage|\.vscode|\.idea)(/|$)|(^|/)local\.properties$|flutter_.*\.log$|\.(pem|p12|jks|keystore|key)$' || true
)"

if [[ -n "$tracked_artifacts" ]]; then
  echo "Tracked generated/local/secret-like artifacts found:" >&2
  echo "$tracked_artifacts" >&2
  status=1
fi

while IFS= read -r -d '' script; do
  if [[ ! -x "$script" ]]; then
    echo "$script must be executable because CI invokes repository scripts directly" >&2
    status=1
  fi

  indexed_mode="$(git ls-files -s -- "$script" | awk '{print $1}')"
  if [[ -n "$indexed_mode" && "$indexed_mode" != "100755" ]]; then
    echo "$script must be tracked with executable mode 100755; current mode is $indexed_mode" >&2
    status=1
  fi
done < <(find scripts -maxdepth 1 -type f -name '*.sh' -print0 | sort -z)

secret_pattern='(gho_[A-Za-z0-9_]+|github_pat_[A-Za-z0-9_]+|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY|password[[:space:]]*[:=][[:space:]]*["'\''][^"'\'']{8,}|api[_-]?key[[:space:]]*[:=][[:space:]]*["'\''][^"'\'']{8,})'
secret_scan_files=()

while IFS= read -r -d '' file; do
  if [[ -f "$file" ]]; then
    secret_scan_files+=("$file")
  fi
done < <(
  git ls-files -z --cached --others --exclude-standard -- \
    ':!pubspec.lock' \
    ':!*.png' \
    ':!*.ico' \
    ':!*.jar'
)

secret_hits=""
if [[ "${#secret_scan_files[@]}" -gt 0 ]]; then
  secret_hits="$(grep -IInE "$secret_pattern" -- "${secret_scan_files[@]}" || true)"
fi

if [[ -n "$secret_hits" ]]; then
  # Tests sometimes need deterministic fake credentials to prove sensitive
  # values do not leak into Hive or logs. Allow obviously fake test fixtures,
  # but keep scanning tests for realistic GitHub/AWS/private-key material.
  filtered_secret_hits="$(
    printf '%s\n' "$secret_hits" |
      grep -Ev '^test/.*(test-key|fake|dummy|placeholder|sk-[A-Za-z0-9._-]*(test|fake|dummy|placeholder)|sk-(secure|cleanup|delete|clear|metadata|mock|unit))' || true
  )"

  if [[ -n "$filtered_secret_hits" ]]; then
    echo "Potential plaintext secret patterns found:" >&2
    echo "$filtered_secret_hits" >&2
    status=1
  fi
fi

require_reference() {
  local script="$1"
  local file="$2"

  if ! grep -Fq "$script" "$file"; then
    echo "$file must list $script in repository verification" >&2
    status=1
  fi
}

mapfile -t repository_check_scripts < <(
  find scripts -maxdepth 1 -type f \( -name 'check_*.sh' -o -name 'validate_*.sh' \) -printf 'scripts/%f\n' | sort
)

release_gate_scripts=(
  'scripts/check_repo_hygiene.sh'
  'scripts/check_shell_scripts.sh'
  'scripts/check_storage_architecture.sh'
)

for script in "${repository_check_scripts[@]}"; do
  require_reference "$script" .github/workflows/ci.yml
  require_reference "$script" docs/release/RELEASE_CHECKLIST.md
  require_reference "$script" .github/PULL_REQUEST_TEMPLATE.md
  require_reference "$script" CONTRIBUTING.md
  require_reference "$script" CLAUDE.md
done

for script in "${release_gate_scripts[@]}"; do
  require_reference "$script" .github/workflows/release.yml
done

exit "$status"
