#!/usr/bin/env bash
# Shipped migrations are never edited (A01 plan D15). Fails if a file that is
# already on main under
#   apps/mobile/drift_schemas/                         (schema dumps)
#   apps/mobile/lib/core/db/migrations/from_*          (one step per version)
# is modified, deleted, renamed or retyped in the worktree. Adding files is
# fine: a schema change is a new version (`make db-migrations`).
#
# "On main" means the merge base of HEAD with origin/main. When HEAD is
# already on main's history (main itself, or a fast-forward merge/<ID>
# branch, or a step branch without commits yet), it compares with HEAD^, so
# the newest commit can't edit a shipped file either. CI needs the full history (checkout fetch-depth: 0).
#
# Usage: check-frozen-migrations.sh [--repo DIR] [--base REF]
#   --repo DIR   the repository (default: this one)
#   --base REF   compare with REF instead (also FROZEN_MIGRATIONS_BASE)
# Exit: 0 = nothing shipped changed, 1 = a shipped file changed, 2 = usage or
# no base (fails closed).
set -euo pipefail

name="check-frozen-migrations"
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
base="${FROZEN_MIGRATIONS_BASE:-}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) repo="$2"; shift 2 ;;
    --base) base="$2"; shift 2 ;;
    *) echo "$name: unknown argument $1" >&2; exit 2 ;;
  esac
done

frozen=(
  'apps/mobile/drift_schemas'
  ':(glob)apps/mobile/lib/core/db/migrations/from_*'
)

git_() { git -C "$repo" "$@"; }

if [[ -z "$base" ]]; then
  if ! git_ rev-parse --verify -q origin/main >/dev/null; then
    echo "$name: error: no origin/main to compare with (CI: checkout with fetch-depth: 0)" >&2
    exit 2
  fi
  head="$(git_ rev-parse HEAD)"
  base="$(git_ merge-base HEAD origin/main)" || {
    echo "$name: error: HEAD has no merge base with origin/main" >&2; exit 2; }
  # On main's history: the newest commit is under test too. With no parent,
  # HEAD itself (worktree edits still count).
  if [[ "$base" == "$head" ]]; then
    base="$(git_ rev-parse --verify -q 'HEAD^')" || base="$head"
  fi
fi
# Resolve the base once, to a SHA (`--end-of-options`: a base starting with
# `-` is a ref, never an option), and use only that from here on.
base_sha="$(git_ rev-parse --verify -q --end-of-options "$base^{commit}")" || {
  echo "$name: error: base $base is not a commit" >&2; exit 2; }

# Base commit vs the worktree (staged and unstaged edits count). No rename
# detection: a rename shows as a deletion of the shipped path.
changed="$(git_ diff --no-renames --name-status --diff-filter=MDT "$base_sha" -- "${frozen[@]}")"
if [[ -n "$changed" ]]; then
  echo "$name: shipped migration files changed (compared with ${base_sha:0:12}):" >&2
  echo "$changed" | sed 's/^/  /' >&2
  echo "Never edit a shipped migration or schema dump: bump schemaVersion, run" >&2
  echo "'make db-migrations' and add lib/core/db/migrations/from_<n>_to_<n+1>.dart (A01 D15)." >&2
  exit 1
fi
echo "$name: OK, no shipped migration or schema dump changed"
