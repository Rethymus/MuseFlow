#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

status=0
tmp_refs="$(mktemp)"
trap 'rm -f "$tmp_refs"' EXIT

for readme in README.md README.en.md; do
  while IFS= read -r image; do
    [[ -z "$image" ]] && continue
    if [[ ! -f "$image" ]]; then
      echo "Missing README image: $readme -> $image" >&2
      status=1
    fi
    printf '%s\n' "$image" >> "$tmp_refs"
  done < <(grep -Eo '!\[[^]]*\]\(docs/readme/screenshots/[^)]+' "$readme" | sed -E 's/^!\[[^]]*\]\(//' || true)
done

sort -u "$tmp_refs" -o "$tmp_refs"

while IFS= read -r screenshot; do
  if ! grep -Fxq "$screenshot" "$tmp_refs"; then
    echo "Unreferenced screenshot: $screenshot" >&2
    status=1
  fi
done < <(find docs/readme/screenshots -maxdepth 1 -type f -name '*.png' | sort)

expected_count="$(find docs/readme/screenshots -maxdepth 1 -type f -name '*.png' | wc -l | tr -d ' ')"
readme_count="$(grep -Eo '!\[[^]]*\]\(docs/readme/screenshots/[^)]+' README.md | sed -E 's/^!\[[^]]*\]\(//' | sort -u | wc -l | tr -d ' ')"
english_count="$(grep -Eo '!\[[^]]*\]\(docs/readme/screenshots/[^)]+' README.en.md | sed -E 's/^!\[[^]]*\]\(//' | sort -u | wc -l | tr -d ' ')"

if [[ "$readme_count" != "$expected_count" || "$english_count" != "$expected_count" ]]; then
  echo "README screenshot count mismatch: files=$expected_count README.md=$readme_count README.en.md=$english_count" >&2
  status=1
fi

exit "$status"
