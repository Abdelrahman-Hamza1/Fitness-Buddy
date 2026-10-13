#!/usr/bin/env bash
# Runs the tests of every pub workspace member, one at a time, and stops at the
# first failure. Members that depend on the Flutter SDK run with `flutter test`,
# the others with `dart test`. Members without a test/ folder are skipped.
# Members listed in COVERAGE_MIN also get a line-coverage gate (S08 D15): the
# same single test run writes lcov, and the script fails below the minimum.
# Called by `make test-dart`, which passes the tool paths through the
# environment (DART, FLUTTER). Usage: DART=... FLUTTER=... dart-test-all.sh
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
: "${DART:?dart-test-all: error: DART is not set (the Makefile passes it)}"
: "${FLUTTER:?dart-test-all: error: FLUTTER is not set (the Makefile passes it)}"

cd "$repo_root"

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
  if grep -Eq '^[[:space:]]+sdk:[[:space:]]*flutter[[:space:]]*$' "$dir/pubspec.yaml"; then
    echo "== $name: flutter test"
    (cd "$dir" && "$FLUTTER" test -j 2)
  elif [[ -n "${COVERAGE_MIN[$name]:-}" ]]; then
    echo "== $name: dart test (coverage >= ${COVERAGE_MIN[$name]}%)"
    lcov="$dir/build/coverage/$name.lcov"
    rm -f "$lcov"
    (cd "$dir" && "$DART" test -j 2 --coverage-path="$lcov")
    check_coverage "$dir" "$lcov" "${COVERAGE_MIN[$name]}"
  else
    echo "== $name: dart test"
    (cd "$dir" && "$DART" test -j 2)
  fi
  ran=$((ran + 1))
done <<<"$members"

((ran > 0)) || { echo "dart-test-all: error: no packages tested" >&2; exit 1; }
echo "dart-test-all: $ran package(s) passed"
