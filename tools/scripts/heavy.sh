#!/usr/bin/env bash
# Runs a heavy command (full test suites, `make check`, Gradle/Android builds,
# Testcontainers runs) under a machine-wide lock, so the three lane folders
# (TD-087) never run two of them at once on the 7 GB laptop. Waits for the lock.
# Usage: tools/scripts/heavy.sh <command> [args...]
#   e.g. tools/scripts/heavy.sh make check test-dart
set -euo pipefail
(($# > 0)) || { echo "usage: heavy.sh <command> [args...]" >&2; exit 64; }
lock="${FB_HEAVY_LOCK:-${XDG_CACHE_HOME:-$HOME/.cache}/fb-heavy.lock}"
mkdir -p "$(dirname "$lock")"
exec 9>"$lock"
if ! flock -n 9; then
  echo "heavy: waiting for another lane's heavy job ($lock)" >&2
  flock 9
fi
"$@"
