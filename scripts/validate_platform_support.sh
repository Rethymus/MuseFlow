#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

status=0

require_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    echo "Missing expected platform runner directory: $dir" >&2
    status=1
  fi
}

for dir in android linux windows web; do
  require_dir "$dir"
done

for dir in macos ios; do
  if [[ -d "$dir" ]]; then
    echo "docs/platform/PLATFORM_SUPPORT.md must be updated before $dir/ is treated as supported" >&2
    status=1
  fi
done

support_doc="docs/platform/PLATFORM_SUPPORT.md"
if [[ ! -f "$support_doc" ]]; then
  echo "Missing $support_doc" >&2
  exit 1
fi

for expected in \
  "| Android | Tier 1 |" \
  "| Linux | Tier 1 |" \
  "| Windows | Tier 1 |" \
  "| Web | Testing / UAT |" \
  "| macOS | Future / unsupported for this release |" \
  "| iOS | Future / unsupported for this release |"
do
  if ! grep -Fq "$expected" "$support_doc"; then
    echo "$support_doc is missing expected support-tier row: $expected" >&2
    status=1
  fi
done

for readme in README.md README.en.md; do
  if ! grep -Fq 'Android' "$readme" ||
     ! grep -Fq 'Linux' "$readme" ||
     ! grep -Fq 'Windows' "$readme" ||
     ! grep -Fq 'Web' "$readme"; then
    echo "$readme must mention the Android/Linux/Windows/Web platform split" >&2
    status=1
  fi
done

if ! grep -Fq 'Android、Linux、Windows 是发布目标，Web 提供 GitHub Pages 浏览器工作区预览' README.md; then
  echo "README.md must describe Web as a GitHub Pages browser-workspace preview" >&2
  status=1
fi

if ! grep -Fq 'Android, Linux, and Windows are release targets; Web provides a GitHub Pages browser-workspace preview' README.en.md; then
  echo "README.en.md must describe Web as a GitHub Pages browser-workspace preview" >&2
  status=1
fi

for readme in README.md README.en.md; do
  if ! grep -Fq 'BYOK' "$readme"; then
    echo "$readme must document the AI Provider BYOK boundary" >&2
    status=1
  fi
done

if grep -Eiq 'macOS|iOS' README.md README.en.md; then
  echo "README files must not advertise macOS/iOS until platform runners and storage validation exist" >&2
  status=1
fi

for file in \
  .github/workflows/ci.yml \
  docs/release/RELEASE_CHECKLIST.md \
  .github/PULL_REQUEST_TEMPLATE.md \
  CONTRIBUTING.md \
  CLAUDE.md
do
  if ! grep -Fq 'scripts/validate_platform_support.sh' "$file"; then
    echo "$file must list scripts/validate_platform_support.sh in repository verification" >&2
    status=1
  fi
done

exit "$status"
