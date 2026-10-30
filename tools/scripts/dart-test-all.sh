#!/usr/bin/env bash
# Runs the tests of every pub workspace member, one at a time, and stops at the
# first failure. Members that depend on the Flutter SDK run with `flutter test`,
# the others with `dart test`. Members without a test/ folder are skipped.
# Members listed in COVERAGE_MIN also get a line-coverage gate (S08 D15): the
# same single test run writes lcov, and the script fails below the minimum.
# Called by `make test-dart`, which passes the tool paths through the
# environment (DART, FLUTTER). Usage: DART=... FLUTTER=... dart-test-all.sh
# Optional environment (CI's parallel test shards, TD-086):
#   DART_TEST_SHARD  empty = every member (default); `packages` = every member
#                    except apps/mobile; `app:<i>/<n>` = only apps/mobile,
#                    shard i of n (1-based) via flutter test's --shard-index.
#                    There are no host timing tests and no `perf` shard
#                    (TD-104).
#   DART_TEST_JOBS   test concurrency per member (default 2 for the 7 GB
#                    laptop; CI's 4-core runners use 4).
#   PROPERTY_RUNS    glados property runs per test (default 100; CI's nightly
#                    and manual runs set 1000; TD-104). Read by the
#                    `test/helpers/property.dart` of fb_domain and fb_text.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
: "${DART:?dart-test-all: error: DART is not set (the Makefile passes it)}"
: "${FLUTTER:?dart-test-all: error: FLUTTER is not set (the Makefile passes it)}"

cd "$repo_root"

shard="${DART_TEST_SHARD:-}"
jobs="${DART_TEST_JOBS:-2}"
[[ $jobs =~ ^[1-9][0-9]*$ ]] || { echo "dart-test-all: error: DART_TEST_JOBS must be a positive integer" >&2; exit 64; }
app_shard=()
case "$shard" in
  '' | packages) ;;
  app:*)
    [[ $shard =~ ^app:([1-9][0-9]*)/([1-9][0-9]*)$ ]] && (( BASH_REMATCH[1] <= BASH_REMATCH[2] )) \
      || { echo "dart-test-all: error: bad DART_TEST_SHARD '$shard' (app:<i>/<n>, 1 <= i <= n)" >&2; exit 64; }
    app_shard=(--total-shards "${BASH_REMATCH[2]}" --shard-index "$((BASH_REMATCH[1] - 1))") ;;
  *) echo "dart-test-all: error: bad DART_TEST_SHARD '$shard' (empty, packages or app:<i>/<n>)" >&2; exit 64 ;;
esac

# Minimum line coverage of lib/ in percent, per package name (S08 D15).
declare -A COVERAGE_MIN=([fb_domain]=95 [fb_text]=95)

# check_coverage <package dir> <lcov file> <minimum percent>
# Sums LH/LF over the package's lib/ files. lcov only lists files a test
# loads, so each gated package needs a barrel test (every lib/src file is
# exported) or an untested file would be left out of the percentage.
check_coverage() {
  python3 -I - "$1" "$2" "$3" <<'PY'
import math, os, sys

pkg_dir, lcov, minimum = sys.argv[1], sys.argv[2], float(sys.argv[3])
name = os.path.basename(pkg_dir)
lib = os.path.join(os.path.realpath(pkg_dir), "lib") + os.sep
if not os.path.isfile(lcov):
    sys.exit(f"dart-test-all: error: {name}: no coverage file at {lcov}")

found = hit = lib_files = 0
any_files = False
in_lib = False
with open(lcov, encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if line.startswith("SF:"):
            any_files = True
            in_lib = os.path.realpath(line[3:]).startswith(lib)
            lib_files += in_lib
        elif in_lib and line.startswith("LF:"):
            found += int(line[3:])
        elif in_lib and line.startswith("LH:"):
            hit += int(line[3:])

if not any_files:
    print(f"-- coverage {name}: no source files in coverage (passes)")
    sys.exit(0)
if lib_files == 0:
    sys.exit(f"dart-test-all: error: {name}: no lib/ files in coverage")
if found == 0:
    print(f"-- coverage {name}: no executable lines in lib/ (passes)")
    sys.exit(0)
# Truncate, so 94.96% never prints as 95.0%.
shown = math.floor(hit * 1000 / found) / 10
summary = f"coverage {name}: {shown:.1f}% ({hit}/{found} lines), minimum {minimum:g}%"
if hit * 100 < minimum * found:
    sys.exit(f"dart-test-all: error: {summary}")
print(f"-- {summary}")
PY
}

# `dart pub workspace list --json` prints {"packages":[{"name":...,"path":...}]}.
members="$("$DART" pub workspace list --json |
  python3 -I -c 'import json,sys; [print(p["path"]) for p in json.load(sys.stdin)["packages"]]')"

ran=0
while IFS= read -r dir; do
  [[ -d "$dir/test" ]] || { echo "-- skip $(basename "$dir"): no test/ folder"; continue; }
  name="$(basename "$dir")"
  is_app=false
  [[ $dir == apps/mobile || $dir == */apps/mobile ]] && is_app=true
  if [[ $shard == packages && $is_app == true ]] || [[ $shard == app:* && $is_app == false ]]; then
    echo "-- skip $name: not in shard $shard"; continue
  fi
  if grep -Eq '^[[:space:]]+sdk:[[:space:]]*flutter[[:space:]]*$' "$dir/pubspec.yaml"; then
    echo "== $name: flutter test${shard:+ ($shard)}"
    (cd "$dir" && "$FLUTTER" test -j "$jobs" "${app_shard[@]}")
  elif [[ -n "${COVERAGE_MIN[$name]:-}" ]]; then
    echo "== $name: dart test (coverage >= ${COVERAGE_MIN[$name]}%)"
    lcov="$dir/build/coverage/$name.lcov"
    rm -f "$lcov"
    (cd "$dir" && "$DART" test -j "$jobs" --coverage-path="$lcov")
    check_coverage "$dir" "$lcov" "${COVERAGE_MIN[$name]}"
  else
    echo "== $name: dart test"
    (cd "$dir" && "$DART" test -j "$jobs")
  fi
  ran=$((ran + 1))
done <<<"$members"

((ran > 0)) || { echo "dart-test-all: error: no packages tested" >&2; exit 1; }
echo "dart-test-all: $ran package(s) passed"
