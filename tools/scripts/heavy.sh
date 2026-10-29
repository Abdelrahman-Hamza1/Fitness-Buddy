#!/usr/bin/env bash
# Runs a heavy command (golden regeneration, drift migration dumps, focused
# Testcontainers runs) under a machine-wide lock, so the three lane folders
# (TD-087) never run two of them at once on the 7 GB laptop. Waits for the lock.
# Full test suites run in CI, not here (2026-10-29).
# The command runs with the lock's file descriptor closed, so daemons it starts
# (the .NET compiler server, MSBuild nodes, Gradle) can't keep holding the lock
# after it exits. Each run appends "wait/run seconds" to the log next to the lock.
# Usage: tools/scripts/heavy.sh <command> [args...]
#   e.g. tools/scripts/heavy.sh make goldens
set -euo pipefail
(($# > 0)) || { echo "usage: heavy.sh <command> [args...]" >&2; exit 64; }
lock="${FB_HEAVY_LOCK:-${XDG_CACHE_HOME:-$HOME/.cache}/fb-heavy.lock}"
mkdir -p "$(dirname "$lock")"
exec 9>"$lock"
start=$SECONDS
if ! flock -n 9; then
  echo "heavy: waiting for another lane's heavy job ($lock)" >&2
  flock 9
fi
waited=$((SECONDS - start))
rc=0
"$@" 9>&- || rc=$?
printf '%s wait=%ss run=%ss rc=%s dir=%s cmd=%s\n' "$(date -u +%FT%TZ)" "$waited" "$((SECONDS - start - waited))" \
  "$rc" "$PWD" "$*" >>"$lock.log" 2>/dev/null || true
exit "$rc"
