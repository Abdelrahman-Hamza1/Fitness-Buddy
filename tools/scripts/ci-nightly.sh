#!/usr/bin/env bash
# Reports the latest nightly CI run on main (the schedule run that also runs the
# emulator job `android-it`, TD-086), without `gh` or a token: its result, age,
# URL and any job that didn't succeed. The orchestrator runs it at session start
# and before a merge; a red nightly is stop-the-line.
#
# Usage: tools/scripts/ci-nightly.sh
# Environment (optional): CI_STATUS_REPO (default Abdelrahman-Hamza1/Fitness-Buddy),
# GITHUB_TOKEN or GH_TOKEN (sent as a bearer token; raises the rate limit).
# Exit codes: 0 green · 1 red or cancelled · 2 still running or no nightly run yet.
set -euo pipefail

readonly REPO="${CI_STATUS_REPO:-Abdelrahman-Hamza1/Fitness-Buddy}"
readonly API="https://api.github.com/repos/$REPO/actions"
token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
auth=()
[[ -n $token ]] && auth=(-H "Authorization: Bearer $token")

get() { curl -fsS --retry 3 -H 'Accept: application/vnd.github+json' "${auth[@]}" "$1"; }

run_json=$(get "$API/workflows/ci.yml/runs?event=schedule&branch=main&per_page=1")
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
get "$API/runs/$id/jobs?per_page=50" | python3 -I -c '
import json, sys
for j in json.load(sys.stdin)["jobs"]:
    if j["conclusion"] not in ("success", "skipped"):
        print("  not green: %s (%s), job id %s" % (j["name"], j["conclusion"], j["id"]))
'
exit 1
