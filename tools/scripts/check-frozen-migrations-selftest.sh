#!/usr/bin/env bash
# Self-test of check-frozen-migrations.sh (A01 plan D15, §5): in a throwaway
# git repo with a "shipped" schema dump and step on main, proves that
# modifying, deleting or renaming them fails, and that adding a new version
# or editing other files passes. Covers both base rules: a branch (merge base
# with origin/main) and main itself (HEAD^).
#
# Usage: check-frozen-migrations-selftest.sh   Exit: 0 = all as expected.
set -euo pipefail

name="check-frozen-migrations-selftest"
check="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/check-frozen-migrations.sh"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT

g() { git -C "$1" -c user.name=selftest -c user.email=selftest@invalid \
  -c commit.gpgsign=false "${@:2}"; }

schemas=apps/mobile/drift_schemas/user
steps=apps/mobile/lib/core/db/migrations

# The "remote" (bare): main with the v1 dump + the 1->2 step shipped, in a
# single commit (the HEAD-without-parent case).
origin="$work/origin.git" seed="$work/seed"
git init -q --bare -b main "$origin"
mkdir -p "$seed/$schemas" "$seed/$steps"
git init -q -b main "$seed"
echo '{"v":1}' >"$seed/$schemas/drift_schema_v1.json"
echo '// 1 -> 2' >"$seed/$steps/from_1_to_2.dart"
echo '// db' >"$seed/apps/mobile/lib/core/db/app_database.dart"
g "$seed" add -A && g "$seed" commit -qm shipped
g "$seed" push -q "$origin" main

failures=0
# expect <pass|fail> <description> <repo>
expect() {
  local want="$1" what="$2" repo="$3" got out
  # The caller's FROZEN_MIGRATIONS_BASE must not leak into the cases.
  if out="$(env -u FROZEN_MIGRATIONS_BASE bash "$check" --repo "$repo" 2>&1)"; then
    got=pass
  else
    got=fail
  fi
  if [[ "$got" == "$want" ]]; then
    echo "  ok    $what ($got)"
  else
    echo "  FAIL  $what: expected $want, got $got" >&2
    echo "$out" | sed 's/^/        /' >&2
    failures=$((failures + 1))
  fi
}

# A fresh step branch, cloned from origin (so origin/main exists).
branch() {
  local dir="$work/$1"
  git clone -q "$origin" "$dir"
  g "$dir" checkout -qb "step/$1"
  echo "$dir"
}

echo "$name:"
d="$(branch clean)"; expect pass 'nothing changed' "$d"

d="$(branch add)"
echo '{"v":2}' >"$d/$schemas/drift_schema_v2.json"
echo '// 2 -> 3' >"$d/$steps/from_2_to_3.dart"
g "$d" add -A && g "$d" commit -qm v2
expect pass 'added dump and step (committed)' "$d"
echo '{"v":2,"x":1}' >"$d/$schemas/drift_schema_v2.json"
expect pass 'edit of a dump that is not shipped yet' "$d"

d="$(branch other)"; echo '// changed' >"$d/apps/mobile/lib/core/db/app_database.dart"
expect pass 'edit outside the frozen paths' "$d"

d="$(branch modify)"; echo '{"v":1,"x":1}' >"$d/$schemas/drift_schema_v1.json"
expect fail 'modified shipped dump (worktree)' "$d"

d="$(branch modify-commit)"; echo '// edited' >"$d/$steps/from_1_to_2.dart"
g "$d" commit -qam edit
expect fail 'modified shipped step (committed)' "$d"

d="$(branch delete)"; rm "$d/$steps/from_1_to_2.dart"
expect fail 'deleted shipped step' "$d"

d="$(branch rename)"; g "$d" mv "$schemas/drift_schema_v1.json" "$schemas/v1.json"
expect fail 'renamed shipped dump' "$d"

# On main itself: HEAD is origin/main, so the base is HEAD^.
d="$work/main"; git clone -q "$origin" "$d"
echo '{"v":2}' >"$d/$schemas/drift_schema_v2.json"
g "$d" add -A && g "$d" commit -qm v2 && g "$d" push -q origin main
g "$d" fetch -q origin
expect pass 'main: last commit adds a version' "$d"
echo '{"v":1,"x":1}' >"$d/$schemas/drift_schema_v1.json"
g "$d" commit -qam edit && g "$d" push -q origin main && g "$d" fetch -q origin
expect fail 'main: last commit edits a shipped dump' "$d"

d="$work/no-origin"; git init -q -b main "$d"
expect fail 'no origin/main (fails closed)' "$d"

if [[ $failures -gt 0 ]]; then
  echo "$name: $failures case(s) not as expected" >&2
  exit 1
fi
echo "$name: OK"
