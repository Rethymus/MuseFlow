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

secret_hits="$(
  grep -RInE \
    --exclude-dir=.git \
    --exclude-dir=.dart_tool \
    --exclude-dir=build \
    --exclude=pubspec.lock \
    --exclude='*.png' \
    --exclude='*.ico' \
    --exclude='*.jar' \
    '(gho_[A-Za-z0-9_]+|github_pat_[A-Za-z0-9_]+|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY|password[[:space:]]*[:=][[:space:]]*["'\''][^"'\'']{8,}|api[_-]?key[[:space:]]*[:=][[:space:]]*["'\''][^"'\'']{8,})' \
    . || true
)"

if [[ -n "$secret_hits" ]]; then
  echo "Potential plaintext secret patterns found:" >&2
  echo "$secret_hits" >&2
  status=1
fi

exit "$status"
