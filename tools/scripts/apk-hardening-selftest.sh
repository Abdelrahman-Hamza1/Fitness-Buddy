#!/usr/bin/env bash
# Self-test of the APK hardening check (tools/scripts/apk_hardening_check.py,
# S06 plan A8): proves it still fails each known-bad APK, with its message, and
# passes the real good ones. No Android SDK needed: it runs on captured aapt2
# dumps in tools/scripts/testdata/apk-hardening/<case>/:
#   flavor   dev | staging | prod
#   expect   "pass", or "fail" + a line the check must print as an error
#   base     optional: the case whose files this one starts from; its own files
#            replace them (so a bad case holds only what it breaks)
#   badging.txt, resources.txt, xmltree/<path in the APK>.txt   the dumps
# staging-good and prod-good are real dumps (aapt2 36.0.0 on S06b builds); the
# others are derived from them. To recapture after a build:
#   python3 -I tools/scripts/apk_hardening_check.py --capture <dir> \
#     --aapt2 "$ANDROID_HOME/build-tools/36.0.0/aapt2" <apk>
#
# Usage: apk-hardening-selftest.sh     Exit: 0 = all as expected, 1 = not.
set -euo pipefail

name="apk-hardening-selftest"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
check="$repo_root/tools/scripts/apk_hardening_check.py"
fixtures="$repo_root/tools/scripts/testdata/apk-hardening"

work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT

# assemble <case> <dest>: the case's files over its base chain.
assemble() {
  local dir="$fixtures/$1"
  [[ -d "$dir" ]] || { echo "$name: no fixture $1" >&2; exit 2; }
  if [[ -f "$dir/base" ]]; then
    assemble "$(<"$dir/base")" "$2"
  fi
  cp -R -- "$dir/." "$2/"
}

failures=0 count=0
for dir in "$fixtures"/*/; do
  case_name="$(basename "$dir")"
  count=$((count + 1))
  mkdir "$work/$case_name"
  assemble "$case_name" "$work/$case_name"
  flavor="$(<"$work/$case_name/flavor")"
  { read -r verdict; read -r message || message=""; } <"$dir/expect"
  rc=0
  python3 -I "$check" --flavor "$flavor" --dumps "$work/$case_name" \
    >"$work/$case_name.out" 2>"$work/$case_name.err" || rc=$?
  if [[ "$verdict" == pass && $rc -eq 0 ]]; then
    printf '  ok    %-26s passes\n' "$case_name"
  elif [[ "$verdict" == fail && $rc -eq 1 ]] \
    && grep -qxF -- "apk-hardening: error: $message" "$work/$case_name.err"; then
    printf '  ok    %-26s fails: %s\n' "$case_name" "$message"
  else
    printf '  FAIL  %-26s expected %s%s, got exit %d:\n' "$case_name" "$verdict" "${message:+ ($message)}" "$rc"
    sed 's/^/        | /' "$work/$case_name.err" "$work/$case_name.out"
    failures=$((failures + 1))
  fi
done

if ((failures > 0)); then
  echo "$name: $failures of $count cases not as expected" >&2
  exit 1
fi
echo "$name: OK, $count cases as expected"
