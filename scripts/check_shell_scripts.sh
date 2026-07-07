#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

status=0

while IFS= read -r -d '' script; do
  if ! bash -n "$script"; then
    status=1
  fi

  if [[ "$(head -n 1 "$script")" != '#!/usr/bin/env bash' ]]; then
    echo "$script must use #!/usr/bin/env bash" >&2
    status=1
  fi

  if ! grep -Fqx 'set -euo pipefail' "$script"; then
    echo "$script must enable set -euo pipefail" >&2
    status=1
  fi
done < <(find scripts -maxdepth 1 -type f -name '*.sh' -print0 | sort -z)

exit "$status"
