#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

status=0

editor_line="$(grep -E '^[[:space:]]+super_editor:[[:space:]]+' pubspec.yaml || true)"
if [[ -z "$editor_line" ]]; then
  echo "pubspec.yaml must keep super_editor as the active rich-text editor dependency" >&2
  status=1
  editor_version=""
else
  editor_version="$(sed -E 's/^[[:space:]]+super_editor:[[:space:]]+//' <<<"$editor_line")"
fi

for retired_dependency in appflowy_editor flutter_quill; do
  if grep -Eq "^[[:space:]]+$retired_dependency:[[:space:]]+" pubspec.yaml; then
    echo "pubspec.yaml reintroduced retired editor dependency: $retired_dependency" >&2
    status=1
  fi
done

if [[ -n "$editor_version" ]] && ! grep -Fq "| **super_editor** | $editor_version |" CLAUDE.md; then
  echo "CLAUDE.md must document the current super_editor version from pubspec.yaml ($editor_version)" >&2
  status=1
fi

if grep -Fq '**appflowy_editor**' CLAUDE.md; then
  echo "CLAUDE.md still documents appflowy_editor as an active editor dependency" >&2
  status=1
fi

if ! grep -Fq '![super_editor]' README.md; then
  echo "README.md must show the active super_editor badge" >&2
  status=1
fi

if ! grep -Fq '![super_editor]' README.en.md; then
  echo "README.en.md must show the active super_editor badge" >&2
  status=1
fi

if grep -Eq '!\[(appflowy_editor|flutter_quill)\]' README.md README.en.md; then
  echo "README badges must not advertise retired editor dependencies" >&2
  status=1
fi

if grep -Eq 'appflowy_editor|flutter_quill' README.md README.en.md; then
  echo "README files must not mention retired editor dependencies; document super_editor as the active editor" >&2
  status=1
fi

if ! grep -Fq 'super_editor 富文本编辑' README.md; then
  echo "README.md must describe super_editor as the active rich-text editor" >&2
  status=1
fi

if ! grep -Fq 'super_editor rich text editing' README.en.md; then
  echo "README.en.md must describe super_editor as the active rich-text editor" >&2
  status=1
fi

if ! grep -Fq 'scripts/check_editor_docs.sh' .github/workflows/ci.yml; then
  echo ".github/workflows/ci.yml must keep scripts/check_editor_docs.sh in CI" >&2
  status=1
fi

if ! grep -Fq 'scripts/check_editor_docs.sh' docs/release/RELEASE_CHECKLIST.md; then
  echo "docs/release/RELEASE_CHECKLIST.md must list scripts/check_editor_docs.sh in local verification" >&2
  status=1
fi

if ! grep -Fq 'scripts/check_editor_docs.sh' .github/PULL_REQUEST_TEMPLATE.md; then
  echo ".github/PULL_REQUEST_TEMPLATE.md must list scripts/check_editor_docs.sh in local verification" >&2
  status=1
fi

if ! grep -Fq 'scripts/check_editor_docs.sh' CONTRIBUTING.md; then
  echo "CONTRIBUTING.md must list scripts/check_editor_docs.sh in local checks" >&2
  status=1
fi

exit "$status"
