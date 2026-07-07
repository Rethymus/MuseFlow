#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required for dependency documentation validation" >&2
  exit 1
fi

python3 - <<'PY'
import pathlib
import re
import sys

pubspec = pathlib.Path("pubspec.yaml").read_text(encoding="utf-8")
claude = pathlib.Path("CLAUDE.md").read_text(encoding="utf-8")
storage_doc = pathlib.Path("docs/storage-architecture.md").read_text(encoding="utf-8")

tracked_dependencies = [
    "flutter_riverpod",
    "riverpod_annotation",
    "riverpod_generator",
    "freezed",
    "freezed_annotation",
    "super_editor",
    "openai_dart",
    "anthropic_sdk_dart",
    "ollama_dart",
    "flutter_secure_storage",
    "go_router",
]


def dart_sdk_constraint() -> str | None:
    environment_match = re.search(
        r"^environment:\n(?P<body>(?:^[ \t]+[^\n]*\n)+)",
        pubspec,
        re.MULTILINE,
    )
    if not environment_match:
        return None

    sdk_match = re.search(
        r"^[ \t]+sdk:[ \t]+(.+)$",
        environment_match.group("body"),
        re.MULTILINE,
    )
    return sdk_match.group(1).strip() if sdk_match else None


def dependency_constraint(name: str) -> str | None:
    pattern = re.compile(rf"^[ \t]+{re.escape(name)}:[ \t]+(.+)$", re.MULTILINE)
    match = pattern.search(pubspec)
    return match.group(1).strip() if match else None


status = 0
if not pathlib.Path(".planning/PROJECT.md").is_file():
    print(".planning/PROJECT.md is missing; CLAUDE.md project baseline references would be ambiguous", file=sys.stderr)
    status = 1

for file_name, text in {
    "CLAUDE.md": claude,
    "docs/storage-architecture.md": storage_doc,
    "lib/features/ai/application/anti_ai_scent_lexicon.dart": pathlib.Path(
        "lib/features/ai/application/anti_ai_scent_lexicon.dart"
    ).read_text(encoding="utf-8"),
}.items():
    for stale_reference in (
        "Project constraint (PROJECT.md)",
        "Constraint from PROJECT.md",
        "PROJECT.md constraint",
        "PROJECT.md explicitly excludes",
        "PROJECT mandates",
        "符合 PROJECT.md",
    ):
        if stale_reference in text:
            print(
                f"{file_name} must reference .planning/PROJECT.md instead of stale root-level PROJECT.md wording: {stale_reference}",
                file=sys.stderr,
            )
            status = 1

dart_constraint = dart_sdk_constraint()
if dart_constraint is None:
    print("pubspec.yaml is missing environment.sdk", file=sys.stderr)
    status = 1
else:
    dart_row_pattern = re.compile(
        rf"^\|[ \t]*Dart SDK[ \t]*\|[ \t]*{re.escape(dart_constraint)}[ \t]*\|",
        re.MULTILINE,
    )
    if not dart_row_pattern.search(claude):
        print(
            "CLAUDE.md must document the current pubspec.yaml Dart SDK "
            f"constraint: {dart_constraint}",
            file=sys.stderr,
        )
        status = 1

for dependency in tracked_dependencies:
    constraint = dependency_constraint(dependency)
    if constraint is None:
        print(f"pubspec.yaml is missing tracked dependency: {dependency}", file=sys.stderr)
        status = 1
        continue

    row_pattern = re.compile(
        rf"^\|[ \t]*(?:\*\*)?{re.escape(dependency)}(?:\*\*)?[ \t]*\|[ \t]*"
        rf"{re.escape(constraint)}[ \t]*\|",
        re.MULTILINE,
    )
    if not row_pattern.search(claude):
        print(
            "CLAUDE.md must document the current pubspec.yaml constraint "
            f"for {dependency}: {constraint}",
            file=sys.stderr,
        )
        status = 1

sys.exit(status)
PY

status=0
for file in \
  .github/workflows/ci.yml \
  docs/release/RELEASE_CHECKLIST.md \
  .github/PULL_REQUEST_TEMPLATE.md \
  CONTRIBUTING.md
do
  if ! grep -Fq 'scripts/check_dependency_docs.sh' "$file"; then
    echo "$file must list scripts/check_dependency_docs.sh in repository verification" >&2
    status=1
  fi
done

exit "$status"
