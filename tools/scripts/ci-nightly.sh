#!/usr/bin/env bash
# Reports the latest nightly CI run on main (the schedule run that also runs the
# emulator job `android-it`, TD-086), without `gh`: its result, age,
# URL and any job that didn't succeed. The orchestrator runs it at session start
# and before a merge; a red nightly is stop-the-line.
#
# Usage: tools/scripts/ci-nightly.sh
# Environment (optional): CI_STATUS_REPO (default Abdelrahman-Hamza1/Fitness-Buddy),
# GITHUB_TOKEN or GH_TOKEN, else the private token file
# ${XDG_CONFIG_HOME:-$HOME/.config}/fitness-buddy/github-token (mode 600; TD-108,
# docs/runbooks/github-token.md): sent as a bearer token (raises the rate limit),
# never printed; a rejected token (HTTP 401) is dropped and the call repeated
# anonymously.
# Exit codes: 0 green · 1 red or cancelled · 2 still running or no nightly run yet ·
# 3 the GitHub API call failed (network, rate limit).
set -euo pipefail

readonly REPO="${CI_STATUS_REPO:-Abdelrahman-Hamza1/Fitness-Buddy}"
readonly API="https://api.github.com/repos/$REPO/actions"
# shellcheck source=tools/scripts/github-token.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/github-token.sh"
load_github_token
token=$gh_token

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

# One GET, body on stdout. The token reaches curl on stdin (`-H @-`), so it never
# shows up in the process list, and only over https.
get() {
  local code auth=() auth_header=""
  if [[ -n $token ]]; then
    auth=(--proto '=https' --proto-redir '=https' -H @-)
    auth_header="Authorization: Bearer $token"
  fi
  code=$(curl -sS --retry 3 -H 'Accept: application/vnd.github+json' \
    -H 'X-GitHub-Api-Version: 2022-11-28' -H 'User-Agent: fitness-buddy-ci-nightly' \
    "${auth[@]}" -o "$workdir/body" -w '%{http_code}' "$1" <<<"$auth_header") || code=000
  if [[ $code == 401 && -n $token ]]; then
    echo "ci-nightly: warning: the token from $gh_token_source was rejected (expired or revoked?); retrying anonymously. Renew it: docs/runbooks/github-token.md" >&2
    token=""
    get "$1"
    return
  fi
  if [[ $code != 200 ]]; then
    echo "ci-nightly: HTTP $code from $1: $(head -c 300 "$workdir/body" 2>/dev/null | tr -d '\n')" >&2
    return 1
  fi
  cat "$workdir/body"
}

run_json=$(get "$API/workflows/ci.yml/runs?event=schedule&branch=main&per_page=1") || exit 3
read -r id status conclusion started url < <(python3 -I -c '
import json, sys
runs = json.load(sys.stdin).get("workflow_runs", [])
if not runs: print("- none - - -"); sys.exit()
r = runs[0]
print(r["id"], r["status"], r["conclusion"] or "-", r["run_started_at"], r["html_url"])
' <<<"$run_json")

if [[ $id == - ]]; then
  echo "ci-nightly: no nightly run on main yet"
  exit 2
fi
echo "ci-nightly: run $id started $started: $status/$conclusion"
echo "  $url"
if [[ $status != completed ]]; then
  exit 2
fi
if [[ $conclusion == success ]]; then
  exit 0
fi
jobs_json=$(get "$API/runs/$id/jobs?per_page=50") || exit 3
python3 -I -c '
import json, sys
for j in json.load(sys.stdin)["jobs"]:
    if j["conclusion"] not in ("success", "skipped"):
        print("  not green: %s (%s), job id %s" % (j["name"], j["conclusion"], j["id"]))
' <<<"$jobs_json"
exit 1
