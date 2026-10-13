#!/usr/bin/env bash
# Breaking-change gate for the contract (TD-023, S02 D12 + A1).
#
# Compares contracts/openapi.yaml with an older version of itself using
# `oasdiff breaking` in the pinned, offline container. Breaking = would break
# an app already in use: a removed endpoint or response field, a new required
# request field, a changed type, and so on. contracts/oasdiff/breaking-levels.txt
# downgrades five additions to info because clients have fallbacks for them
# (new enum value, new oneOf/anyOf branch: 04 §4.2 forward compatibility).
#
# Which version it compares with, and what happens:
#   CONTRACT_BASE_REF=<git ref>   that ref's contracts/openapi.yaml; breaking
#                                 changes FAIL (exit 1). For proofs and for
#                                 checking against a specific release.
#   a contracts-v* tag reachable  the newest one; breaking changes FAIL.
#   no tag yet (pre-release, A1)  the merge-base with origin/main (on main
#                                 itself: the previous commit); breaking changes
#                                 are listed as a NOTICE and the gate passes.
#                                 The first tag, contracts-v1.0.0, comes with the
#                                 first app release that calls the API.
#
# Usage: contract-breaking.sh
#        contract-breaking.sh [--report-only] --files <base> <revision>
#            Two files in the repo; breaking changes fail. With --report-only
#            they are a notice instead, as before the first tag. Used by the
#            self-test.
# oasdiff always runs with --fail-on WARN, and its exit code decides: 1 means
# breaking changes (a failure, or a notice before the first tag), 0 none.
# In GitHub Actions it also writes a table to $GITHUB_STEP_SUMMARY and prints
# annotations; text that comes from the contract or from oasdiff is printed
# with workflow commands stopped (see untrusted_begin). Exit: 0 = no breaking
# change (or pre-release notice), 1 = breaking changes, 2 = usage or tool error.
set -euo pipefail

name="contract-breaking"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
compose_file="$repo_root/tools/contract-tools/compose.yaml"
contract_rel="contracts/openapi.yaml"
work_rel="build/contract"

die() { printf '%s: error: %s\n' "$name" "$*" >&2; exit 2; }
in_actions() { [[ "${GITHUB_ACTIONS:-}" == "true" ]]; }
# Annotation text: GitHub's escapes for %, CR and LF.
escape_data() { local s="${1//%/%25}"; s="${s//$'\r'/%0D}"; printf '%s' "${s//$'\n'/%0A}"; }
# A notice: an annotation in GitHub Actions, a plain line elsewhere.
notice() {
  if in_actions; then printf '::notice title=%s::%s\n' "$name" "$(escape_data "$*")"; else printf '%s: NOTICE: %s\n' "$name" "$*"; fi
}
# Text from the contract or from oasdiff (paths, descriptions, git output) could
# contain a line like "::set-env ...". In GitHub Actions it is printed between
# these two calls, so the runner doesn't execute workflow commands in it. The
# token is random per block. Print begin and end on the same stream as the text.
stop_token=""
untrusted_begin() {
  in_actions || return 0
  stop_token="$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')"
  printf '::stop-commands::%s\n' "$stop_token"
}
untrusted_end() {
  [[ -n "$stop_token" ]] || return 0
  printf '::%s::\n' "$stop_token"
  stop_token=""
}

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

in_repo() {
  local abs
  abs="$(realpath -m -- "$1")"
  case "$abs" in
    "$repo_root"/*) printf '%s\n' "${abs#"$repo_root"/}" ;;
    *) die "$1 is outside the repository ($repo_root); the contract tools can't see it" ;;
  esac
}

git_() { git -C "$repo_root" "$@"; }

# --- Decide what to compare with ------------------------------------------------
usage="usage: $0 [[--report-only] --files <base> <revision>]"
blocking=true
if (($# > 0)); then
  if [[ "$1" == "--report-only" ]]; then
    blocking=false
    shift
  fi
  [[ "${1:-}" == "--files" && $# -eq 3 ]] || die "$usage"
  [[ -f "$2" ]] || die "base not found: $2"
  [[ -f "$3" ]] || die "revision not found: $3"
  base_rel="$(in_repo "$2")"
  rev_rel="$(in_repo "$3")"
  base_label="$base_rel"
else
  rev_rel="$contract_rel"
  [[ -f "$repo_root/$rev_rel" ]] || die "$rev_rel not found (run: make gen-contract)"
  if [[ -n "${CONTRACT_BASE_REF:-}" ]]; then
    ref="$CONTRACT_BASE_REF"
    # Never let a value reach git as an option (e.g. --output=...).
    [[ "$ref" != -* ]] || die "CONTRACT_BASE_REF must be a git ref, not an option: $ref"
    why="CONTRACT_BASE_REF"
  elif tag="$(git_ describe --tags --abbrev=0 --match 'contracts-v*' HEAD 2>/dev/null)"; then
    ref="$tag"
    why="the latest contract tag"
  else
    blocking=false
    if ! git_ rev-parse -q --verify 'origin/main^{commit}' >/dev/null; then
      notice "pre-release (no contracts-v* tag) and no origin/main to compare with: skipped. Run 'git fetch origin main' to see the report."
      exit 0
    fi
    if ! ref="$(git_ merge-base HEAD origin/main 2>/dev/null)"; then
      notice "pre-release (no contracts-v* tag) and no merge-base with origin/main (shallow clone?): skipped."
      exit 0
    fi
    why="pre-release: no contracts-v* tag yet, so the merge-base with origin/main"
    if [[ "$ref" == "$(git_ rev-parse HEAD)" ]] && git_ rev-parse -q --verify 'HEAD^' >/dev/null; then
      ref="$(git_ rev-parse HEAD^)"
      why="pre-release: no contracts-v* tag yet, and HEAD is on origin/main, so the previous commit"
    fi
  fi
  git_ rev-parse -q --verify "$ref^{commit}" >/dev/null || die "not a commit: $ref ($why)"
  short="$(git_ rev-parse --short "$ref^{commit}")"
  # A raw commit ID is shown short; a named ref with its short commit ID.
  if [[ "$ref" =~ ^[0-9a-f]{40}$ ]]; then at="$short"; else at="$ref ($short)"; fi
  base_label="$contract_rel at $at ($why)"
  if ! git_ cat-file -e "$ref:$contract_rel" 2>/dev/null; then
    if [[ "$blocking" == true ]]; then
      die "$contract_rel does not exist at $at ($why)"
    fi
    notice "$contract_rel does not exist at $at ($why): nothing to compare yet."
    exit 0
  fi
  mkdir -p "$repo_root/$work_rel"
  base_rel="$work_rel/breaking-base.yaml"
  git_ show "$ref:$contract_rel" >"$repo_root/$base_rel"
fi

# --- Compare --------------------------------------------------------------------
# --fail-on WARN in both modes: exit 1 = breaking changes (WARN or ERR level),
# 0 = none. Info-level findings (breaking-levels.txt) never count. oasdiff's
# wording for "nothing found" differs between versions, so it is never parsed.
args=(breaking "$base_rel" "$rev_rel"
  --allow-external-refs=false
  --severity-levels contracts/oasdiff/breaking-levels.txt
  --fail-on WARN)

out="$(mktemp)"
json="$(mktemp)"
trap 'rm -f "$out" "$json"' EXIT

rc=0
# --color is only accepted with the text format.
tool oasdiff "${args[@]}" --color never >"$out" 2>&1 || rc=$?
if ((rc > 1)); then
  {
    echo "$name: error: oasdiff failed (exit $rc):"
    untrusted_begin
    cat "$out"
    untrusted_end
  } >&2
  exit 2
fi
found=false
((rc == 1)) && found=true

# A Markdown table of the findings for the GitHub job summary.
write_summary() {
  [[ -n "${GITHUB_STEP_SUMMARY:-}" ]] || return 0
  local rc=0
  tool oasdiff "${args[@]}" --format json >"$json" || rc=$?
  ((rc <= 1)) || { echo "$name: warning: could not write the job summary (oasdiff exit $rc)" >&2; return 0; }
  python3 -I - "$json" "$1" "$base_label" >>"$GITHUB_STEP_SUMMARY" <<'PY'
import json, sys
path, heading, base = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    items = json.load(open(path, encoding="utf-8")) or []
except (OSError, ValueError):
    items = []
levels = {3: "error", 2: "warning", 1: "info"}
cell = lambda s: str(s).replace("|", "\\|").replace("\n", " ")
print(f"### {heading}\n\nCompared with {cell(base)}.\n")
print("| Level | Check | Operation | Change |\n|---|---|---|---|")
for i in items:
    op = f"{i.get('operation', '')} {i.get('path', '')}".strip()
    print(f"| {levels.get(i.get('level'), i.get('level'))} | `{cell(i.get('id', ''))}` | `{cell(op)}` | {cell(i.get('text', ''))} |")
print()
PY
}

if [[ "$found" == false ]]; then
  echo "$name: OK, no breaking changes (compared with $base_label)"
  exit 0
fi

# oasdiff ends with blank lines: drop them.
report() { sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$out" | sed 's/^/  /'; }

if [[ "$blocking" != true ]]; then
  notice "pre-release: breaking changes compared with $base_label. Allowed until the first contracts-v* tag (contracts/README.md, 'Breaking changes')."
  untrusted_begin
  report
  untrusted_end
  write_summary "Contract: breaking changes (pre-release notice, not blocking)"
  exit 0
fi

{
  echo "$name: FAILED: breaking changes compared with $base_label"
  echo
  untrusted_begin
  report
  untrusted_end
  echo
  echo "Within /v1 only additive changes are allowed once a contract version is"
  echo "tagged (04 §8, TD-023): make the change additive (e.g. add a field instead"
  echo "of renaming it), or add the new shape under /v2 next to /v1."
  echo "See contracts/README.md, 'Breaking changes'."
} >&2
if in_actions; then
  # One annotation per finding (exit 1 = findings, expected here). On stderr,
  # like the report above, so it stays after the stop-commands block ends.
  tool oasdiff "${args[@]}" --format githubactions >&2 || (($? == 1)) || echo "$name: warning: could not print the annotations" >&2
fi
write_summary "Contract: breaking changes (blocking)"
exit 1
