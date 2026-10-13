#!/usr/bin/env bash
# Server conformance (S02 D10): the server's build-time OpenAPI document must
# describe exactly the API in the contract, and the contract wins.
#
# Runs `oasdiff changelog <contract> <server-doc> --fail-on INFO` in the pinned,
# offline container (tools/contract-tools/compose.yaml). Every API difference
# fails: paths, operations, parameters, status codes, media types, schema
# fields, types, formats, required/nullable, operationId, tags.
# Documentation-only differences (info, servers, descriptions, summaries,
# examples, key order, component names, $ref vs inline) are not API changes, so
# they never fail. contracts/oasdiff/conformance-levels.txt turns off the three
# checks that make no sense between two different documents (schema removed
# from components, API version decreased / not bumped).
#
# Usage: contract-conformance.sh [<contract> [<server-doc>]]
#   <contract>    default: contracts/openapi.yaml
#   <server-doc>  default: $SERVER_DOC, else backend/artifacts/openapi/server.json
# Both files must be inside the repository (the container only sees the repo).
# In GitHub Actions (GITHUB_ACTIONS=true) it also prints one ::error annotation
# per difference (every level fails here, so info and warning become errors),
# and prints the contract- and oasdiff-derived text with workflow commands
# stopped (see untrusted_begin).
# Exit: 0 = the server matches, 1 = it doesn't, 2 = usage or tool error.
set -euo pipefail

name="contract-conformance"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
compose_file="$repo_root/tools/contract-tools/compose.yaml"

die() { printf '%s: error: %s\n' "$name" "$*" >&2; exit 2; }
in_actions() { [[ "${GITHUB_ACTIONS:-}" == "true" ]]; }
# Text from the contract, the server document or oasdiff could contain a line
# like "::set-env ...". In GitHub Actions it is printed between these two calls,
# so the runner doesn't execute workflow commands in it. The token is random
# per block. Print begin and end on the same stream as the text.
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

# The compose file needs these (the Makefile exports them too).
export REPO_ROOT="$repo_root"
export UID
GID="${GID:-$(id -g)}"
export GID
# build/contract must exist before a container starts: it is the only writable
# mount (tools/contract-tools/compose.yaml).
tool() {
  mkdir -p "$repo_root/build/contract"
  docker compose --progress quiet -f "$compose_file" run --rm -T "$@"
}

# Repository-relative form of a path: the tools see the repository at /work.
in_repo() {
  local abs
  abs="$(realpath -m -- "$1")"
  case "$abs" in
    "$repo_root"/*) printf '%s\n' "${abs#"$repo_root"/}" ;;
    *) die "$1 is outside the repository ($repo_root); the contract tools can't see it" ;;
  esac
}

(($# <= 2)) || die "usage: $0 [<contract> [<server-doc>]]"
contract="${1:-$repo_root/contracts/openapi.yaml}"
server="${2:-${SERVER_DOC:-$repo_root/backend/artifacts/openapi/server.json}}"

[[ -f "$contract" ]] || die "contract not found: $contract"
[[ -f "$server" ]] || die "server OpenAPI document not found: $server
  It is written when the Host builds (make contract-conformance builds it first)."
contract_rel="$(in_repo "$contract")"
server_rel="$(in_repo "$server")"

args=(changelog "$contract_rel" "$server_rel"
  --fail-on INFO
  --allow-external-refs=false
  --severity-levels contracts/oasdiff/conformance-levels.txt)

out="$(mktemp)"
trap 'rm -f "$out"' EXIT

rc=0
# --color is only accepted with the text format.
tool oasdiff "${args[@]}" --color never >"$out" 2>&1 || rc=$?

case "$rc" in
  0)
    echo "$name: OK, the server API ($server_rel) matches the contract ($contract_rel)"
    ;;
  1)
    {
      echo "$name: FAILED"
      echo "Server API does not match the contract (the contract wins):"
      echo "  contract: $contract_rel"
      echo "  server:   $server_rel (generated from the C# endpoints at build time)"
      echo "Read the list from the contract's side: 'removed' = the contract has it and the"
      echo "server doesn't; 'added' = the server has it and the contract doesn't."
      echo
      # oasdiff ends with blank lines: drop them.
      untrusted_begin
      sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$out" | sed 's/^/  /'
      untrusted_end
      echo
      echo "How to fix it:"
      echo "  - The server is wrong (the usual case): change the C# endpoint or DTO in"
      echo "    backend/ to match $contract_rel, then run 'make contract-conformance'."
      echo "  - The API should change: edit contracts/openapi/ first, run 'make gen'"
      echo "    (bundle + Dart client), then change the server. See contracts/README.md."
    } >&2
    if in_actions; then
      # One annotation per difference on the run page (exit 1 = differences,
      # expected here). oasdiff writes ::notice/::warning for info/warn-level
      # changes; every level fails conformance (--fail-on INFO), so all of them
      # are shown as ::error. Lines that are not annotations are dropped.
      ann_rc=0
      tool oasdiff "${args[@]}" --format githubactions >"$out" || ann_rc=$?
      if ((ann_rc <= 1)); then
        # stderr, like the report above: one stream keeps the order with its
        # stop-commands block. The runner reads workflow commands on both.
        sed -n -E 's/^::(error|warning|notice)( |::)/::error\2/p' "$out" >&2
      else
        echo "$name: warning: could not print the annotations" >&2
      fi
    fi
    exit 1
    ;;
  *)
    {
      echo "$name: error: oasdiff failed (exit $rc):"
      untrusted_begin
      cat "$out"
      untrusted_end
    } >&2
    exit 2
    ;;
esac
