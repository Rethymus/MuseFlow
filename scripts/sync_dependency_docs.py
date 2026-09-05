#!/usr/bin/env python3
"""Sync CLAUDE.md dependency table rows with pubspec.yaml constraints.

Companion to scripts/check_dependency_docs.sh (the CI gate that enforces
consistency). This script performs the mechanical rewrite, so dependency
bumps can keep the gate green by just running it.

Exits non-zero when a tracked dependency row is missing from CLAUDE.md
(and therefore cannot be synced) — new rows must be written by hand with
a real description.
"""

import pathlib
import re
import sys

TRACKED_DEPENDENCIES = [
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


def read_pubspec() -> str:
    return pathlib.Path("pubspec.yaml").read_text(encoding="utf-8")


def dependency_constraint(pubspec: str, name: str) -> str | None:
    pattern = re.compile(rf"^[ \t]+{re.escape(name)}:[ \t]+(.+)$", re.MULTILINE)
    match = pattern.search(pubspec)
    return match.group(1).strip() if match else None


def dart_sdk_constraint(pubspec: str) -> str | None:
    environment_match = re.search(
        r"^environment:\n(?P<body>(?:^[ \t]+[^\n]*\n)+)", pubspec, re.MULTILINE
    )
    if not environment_match:
        return None
    sdk_match = re.search(
        r"^[ \t]+sdk:[ \t]+(.+)$", environment_match.group("body"), re.MULTILINE
    )
    return sdk_match.group(1).strip() if sdk_match else None


def sync_row(claude: str, name: str, constraint: str) -> tuple[str, bool, bool]:
    """Rewrite the constraint cell of `name`'s CLAUDE.md table row.

    Returns (new_text, row_found, cell_changed). Preserves bold markup and
    every other column of the row.
    """
    row_pattern = re.compile(
        rf"^(\|[ \t]*(?:\*\*)?{re.escape(name)}(?:\*\*)?[ \t]*\|[ \t]*)"
        rf"[^|\n]*?"
        rf"([ \t]*\|)",
        re.MULTILINE,
    )
    match = row_pattern.search(claude)
    if not match:
        return claude, False, False
    replacement = rf"\g<1>{constraint}\g<2>"
    new_text = row_pattern.sub(replacement, claude, count=1)
    return new_text, True, new_text != claude


def main() -> int:
    pubspec = read_pubspec()
    claude_path = pathlib.Path("CLAUDE.md")
    claude = claude_path.read_text(encoding="utf-8")
    status = 0
    changed = False

    sdk = dart_sdk_constraint(pubspec)
    if sdk is None:
        print("pubspec.yaml is missing environment.sdk", file=sys.stderr)
        return 1
    claude, found, cell_changed = sync_row(claude, "Dart SDK", sdk)
    if not found:
        print("CLAUDE.md is missing a 'Dart SDK' table row", file=sys.stderr)
        status = 1
    changed = changed or cell_changed

    for name in TRACKED_DEPENDENCIES:
        constraint = dependency_constraint(pubspec, name)
        if constraint is None:
            print(f"pubspec.yaml is missing tracked dependency: {name}", file=sys.stderr)
            status = 1
            continue
        claude, found, cell_changed = sync_row(claude, name, constraint)
        if not found:
            print(f"CLAUDE.md is missing a table row for {name}", file=sys.stderr)
            status = 1
        changed = changed or cell_changed

    if changed:
        claude_path.write_text(claude, encoding="utf-8", newline="\n")
        print("CLAUDE.md dependency table synced with pubspec.yaml")
    else:
        print("CLAUDE.md dependency table already in sync")
    return status


if __name__ == "__main__":
    sys.exit(main())
