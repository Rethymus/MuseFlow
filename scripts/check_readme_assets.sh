#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

status=0
tmp_refs="$(mktemp)"
tmp_readme_refs="$(mktemp)"
tmp_english_refs="$(mktemp)"
tmp_readme_sequence="$(mktemp)"
tmp_english_sequence="$(mktemp)"
trap 'rm -f "$tmp_refs" "$tmp_readme_refs" "$tmp_english_refs" "$tmp_readme_sequence" "$tmp_english_sequence"' EXIT

for readme in README.md README.en.md; do
  per_readme_refs="$tmp_readme_refs"
  per_readme_sequence="$tmp_readme_sequence"
  if [[ "$readme" == "README.en.md" ]]; then
    per_readme_refs="$tmp_english_refs"
    per_readme_sequence="$tmp_english_sequence"
  fi

  while IFS= read -r image; do
    [[ -z "$image" ]] && continue
    if [[ ! -f "$image" ]]; then
      echo "Missing README image: $readme -> $image" >&2
      status=1
    fi
    printf '%s\n' "$image" >> "$tmp_refs"
    printf '%s\n' "$image" >> "$per_readme_refs"
    printf '%s\n' "$image" >> "$per_readme_sequence"
  done < <(grep -Eo '!\[[^]]*\]\(docs/readme/screenshots/[^)]+' "$readme" | sed -E 's/^!\[[^]]*\]\(//' || true)
done

required_verification_commands=(
  'dart format --set-exit-if-changed .'
  'flutter analyze'
  'flutter test'
  'scripts/check_readme_assets.sh'
  'scripts/check_repo_hygiene.sh'
  'scripts/check_shell_scripts.sh'
)

for readme in README.md README.en.md; do
  for command in "${required_verification_commands[@]}"; do
    if ! grep -Fq "$command" "$readme"; then
      echo "$readme must list $command in Run and Verify" >&2
      status=1
    fi
  done
done

if ! cmp -s "$tmp_readme_sequence" "$tmp_english_sequence"; then
  echo "README screenshot order differs between README.md and README.en.md" >&2
  diff -u --label README.md --label README.en.md "$tmp_readme_sequence" "$tmp_english_sequence" >&2 || true
  status=1
fi

sort -u "$tmp_refs" -o "$tmp_refs"
sort -u "$tmp_readme_refs" -o "$tmp_readme_refs"
sort -u "$tmp_english_refs" -o "$tmp_english_refs"

if ! cmp -s "$tmp_readme_refs" "$tmp_english_refs"; then
  echo "README screenshot sets differ between README.md and README.en.md" >&2
  while IFS= read -r image; do
    echo "Only in README.md: $image" >&2
  done < <(comm -23 "$tmp_readme_refs" "$tmp_english_refs")
  while IFS= read -r image; do
    echo "Only in README.en.md: $image" >&2
  done < <(comm -13 "$tmp_readme_refs" "$tmp_english_refs")
  status=1
fi

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
