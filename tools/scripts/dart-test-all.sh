#!/usr/bin/env bash
# Runs the tests of every pub workspace member, one at a time, and stops at the
# first failure. Members that depend on the Flutter SDK run with `flutter test`,
# the others with `dart test`. Members without a test/ folder are skipped.
# Called by `make test-dart`, which passes the tool paths through the
# environment (DART, FLUTTER). Usage: DART=... FLUTTER=... dart-test-all.sh
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
: "${DART:?dart-test-all: error: DART is not set (the Makefile passes it)}"
: "${FLUTTER:?dart-test-all: error: FLUTTER is not set (the Makefile passes it)}"

cd "$repo_root"

# `dart pub workspace list --json` prints {"packages":[{"name":...,"path":...}]}.
members="$("$DART" pub workspace list --json |
  python3 -I -c 'import json,sys; [print(p["path"]) for p in json.load(sys.stdin)["packages"]]')"

ran=0
while IFS= read -r dir; do
  [[ -d "$dir/test" ]] || { echo "-- skip $(basename "$dir"): no test/ folder"; continue; }
  name="$(basename "$dir")"
  if grep -Eq '^[[:space:]]+sdk:[[:space:]]*flutter[[:space:]]*$' "$dir/pubspec.yaml"; then
    echo "== $name: flutter test"
    (cd "$dir" && "$FLUTTER" test -j 2)
  else
    echo "== $name: dart test"
    (cd "$dir" && "$DART" test -j 2)
  fi
  ran=$((ran + 1))
done <<<"$members"

((ran > 0)) || { echo "dart-test-all: error: no packages tested" >&2; exit 1; }
echo "dart-test-all: $ran package(s) passed"
