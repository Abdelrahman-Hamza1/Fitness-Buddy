#!/usr/bin/env bash
# Self-test of the contract checks (S02 D7, D14): proves, on every run, that
# the checks still catch what they must, so a loosened rule or a tool bump that
# changes behaviour fails CI instead of silently letting things through.
#
#   1. Spectral: each contracts/selftest/spectral/*.yaml (files starting with
#      "_" are shared parts) starts with "# expect: <rule-code>" and must fail
#      with exactly that rule ("# expect: none" = must pass). The real bundle,
#      contracts/openapi.yaml, must pass.
#   2. Breaking (contract-breaking.sh --files): field-removed must fail;
#      additive and enum-value-added must pass. The pre-release (non-blocking)
#      path, via --report-only: an identical base passes quietly, and
#      field-removed passes with a NOTICE.
#   3. Conformance (contract-conformance.sh): server-match must pass;
#      server-renamed (a renamed response field) and server-retagged (another
#      tag) must fail, the first with the readable message (printed below).
#
# Usage: contract-selftest.sh     Exit: 0 = all as expected, 1 = not.
set -euo pipefail

name="contract-selftest"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
scripts="$repo_root/tools/scripts"
compose_file="$repo_root/tools/contract-tools/compose.yaml"
selftest_rel="contracts/selftest"
work_rel="build/contract"

die() { printf '%s: error: %s\n' "$name" "$*" >&2; exit 2; }

export REPO_ROOT="$repo_root"
export UID
GID="${GID:-$(id -g)}"
export GID
# build/contract must exist before a container starts: it is the only writable
# mount (tools/contract-tools/compose.yaml).
tool() {
  mkdir -p "$repo_root/$work_rel"
  docker compose --progress quiet -f "$compose_file" run --rm -T "$@"
}

# The nested checks must not write GitHub annotations or job summaries: their
# failures are expected here.
quiet_ci() { env -u GITHUB_ACTIONS -u GITHUB_STEP_SUMMARY "$@"; }

failures=0
ok() { printf '  ok    %s\n' "$*"; }
bad() { printf '  FAIL  %s\n' "$*"; failures=$((failures + 1)); }
indent() { sed 's/^/        | /'; }

mkdir -p "$repo_root/$work_rel"

# --- 1. Spectral --------------------------------------------------------------------
echo "$name: 1. Spectral rules (contracts/spectral.yaml)"
files=()
expects=()
for f in "$repo_root/$selftest_rel"/spectral/*.yaml; do
  base="$(basename "$f")"
  [[ "$base" == _* ]] && continue
  expect="$(sed -n '1s/^# expect: *\([^ ]*\) *$/\1/p' "$f")"
  if [[ -z "$expect" ]]; then
    bad "$base: the first line must be '# expect: <rule-code>' or '# expect: none'"
    continue
  fi
  files+=("$selftest_rel/spectral/$base")
  expects+=("$expect")
done
((${#files[@]} > 0)) || die "no fixtures in $selftest_rel/spectral"
files+=("contracts/openapi.yaml")
expects+=("none")

report_rel="$work_rel/selftest-spectral.json"
rm -f "$repo_root/$report_rel"
rc=0
tool spectral lint "${files[@]}" --ruleset contracts/spectral.yaml --fail-severity=warn \
  --format json --output "$report_rel" >/dev/null 2>&1 || rc=$?
# Spectral: 0 = no findings, 1 = findings, 2 = it could not run.
if ((rc > 1)) || [[ ! -s "$repo_root/$report_rel" ]]; then
  tool spectral lint "${files[@]}" --ruleset contracts/spectral.yaml --fail-severity=warn >&2 || true
  die "Spectral failed to run (exit $rc), see above"
fi

pairs=()
for i in "${!files[@]}"; do pairs+=("${files[$i]}" "${expects[$i]}"); done
spectral_result=0
python3 -I - "$repo_root/$report_rel" "${pairs[@]}" <<'PY' || spectral_result=$?
import json, sys
from collections import defaultdict

report, args = sys.argv[1], sys.argv[2:]
found = defaultdict(set)   # repo-relative file -> codes at warn or error
for r in json.load(open(report, encoding="utf-8")):
    if r.get("severity", 3) <= 1:   # 0 = error, 1 = warn
        found[r["source"].removeprefix("/work/")].add(r["code"])

failed = 0
for path, expect in zip(args[0::2], args[1::2]):
    codes = found.pop(path, set())
    want = set() if expect == "none" else {expect}
    label = "passes" if not want else f"fails with {expect}"
    if codes == want:
        print(f"  ok    {path} {label}")
    else:
        failed += 1
        got = ", ".join(sorted(codes)) or "nothing"
        print(f"  FAIL  {path}: expected it to {'pass' if not want else 'fail with ' + expect}, got {got}")
for path, codes in found.items():   # findings in files we didn't lint directly
    failed += 1
    print(f"  FAIL  unexpected findings in {path}: {', '.join(sorted(codes))}")
sys.exit(min(failed, 100))
PY
failures=$((failures + spectral_result))

# --- 2. Breaking changes -------------------------------------------------------------
echo "$name: 2. Breaking-change gate (contract-breaking.sh, contracts/oasdiff/breaking-levels.txt)"
breaking() { # <revision> <expected exit> <description>
  local out rc=0
  out="$(quiet_ci bash "$scripts/contract-breaking.sh" --files \
    "$repo_root/$selftest_rel/breaking/base.yaml" "$repo_root/$selftest_rel/breaking/$1.yaml" 2>&1)" || rc=$?
  if ((rc == $2)); then
    ok "breaking/$1.yaml $3"
  else
    bad "breaking/$1.yaml: expected exit $2 ($3), got $rc:"
    printf '%s\n' "$out" | indent
  fi
}
breaking field-removed 1 "fails (a removed response field is breaking)"
breaking additive 0 "passes (new endpoint + new response field)"
breaking enum-value-added 0 "passes (new response enum value: clients fall back to unknown)"

# The pre-release path (no contracts-v* tag yet): never fails, and shows a
# NOTICE only when there are breaking changes.
breaking_report_only() { # <revision> <yes|no: NOTICE expected> <description>
  local out rc=0 has=no
  out="$(quiet_ci bash "$scripts/contract-breaking.sh" --report-only --files \
    "$repo_root/$selftest_rel/breaking/base.yaml" "$repo_root/$selftest_rel/breaking/$1.yaml" 2>&1)" || rc=$?
  [[ "$out" == *NOTICE* ]] && has=yes
  if ((rc == 0)) && [[ "$has" == "$2" ]]; then
    ok "breaking/$1.yaml (report only) $3"
  else
    bad "breaking/$1.yaml (report only): expected exit 0 and NOTICE=$2 ($3), got exit $rc and NOTICE=$has:"
    printf '%s\n' "$out" | indent
  fi
}
breaking_report_only base no "passes quietly (identical contract: no notice)"
breaking_report_only field-removed yes "passes with a NOTICE (breaking, but not blocking before the first tag)"

# --- 3. Conformance --------------------------------------------------------------------
echo "$name: 3. Server conformance (contract-conformance.sh, contracts/oasdiff/conformance-levels.txt)"
conformance() { # <server doc> <expected exit> <description> [<text the message must contain>]
  local out rc=0
  out="$(quiet_ci bash "$scripts/contract-conformance.sh" \
    "$repo_root/$selftest_rel/conformance/contract.yaml" "$repo_root/$selftest_rel/conformance/$1" 2>&1)" || rc=$?
  if ((rc != $2)); then
    bad "conformance/$1: expected exit $2 ($3), got $rc:"
    printf '%s\n' "$out" | indent
  elif [[ -n "${4:-}" && "$out" != *"$4"* ]]; then
    bad "conformance/$1: exit $rc as expected, but the message lacks '$4':"
    printf '%s\n' "$out" | indent
  else
    ok "conformance/$1 $3"
    [[ -n "${4:-}" ]] && printf '%s\n' "$out" | indent
  fi
  return 0
}
conformance server-match.json 0 "passes (only documentation differs)"
conformance server-renamed.json 1 "fails (response field renamed), with this message:" \
  "Server API does not match the contract (the contract wins)"
conformance server-retagged.json 1 "fails (operation tag changed: it is the Dart client class)"

echo
if ((failures > 0)); then
  echo "$name: FAILED ($failures problem(s) above)" >&2
  exit 1
fi
echo "$name: OK"
