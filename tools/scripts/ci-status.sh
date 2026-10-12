#!/usr/bin/env bash
# Waits for the CI result of one commit and reports it, without `gh` or a token
# (S01 D20, A6). Polls the GitHub REST API for the commit's check runs and
# finishes when the required check `ci` (the gate job of .github/workflows/ci.yml)
# has completed. Only check runs created by GitHub Actions (app id 15368) count,
# so another app cannot fake a `ci` result. If the commit has several `ci` runs
# (e.g. push + pull_request, or a re-run), all must be completed and the newest
# one (highest id) decides.
#
# Usage: tools/scripts/ci-status.sh <sha> [timeout-minutes]
#   <sha>             commit to check (7-40 hex characters, normally a full SHA)
#   timeout-minutes   give up after this long, initial wait included (default 25)
#
# Environment (all optional):
#   CI_STATUS_INITIAL_WAIT    seconds to wait before the first poll (default 180,
#                             CI needs a few minutes anyway; saves API calls).
#                             Capped at timeout - 60 s, so at least one poll
#                             always happens.
#   CI_STATUS_POLL_INTERVAL   seconds between polls (default 60)
#   CI_STATUS_REPO            owner/repo (default Abdelrahman-Hamza1/Fitness-Buddy)
#   CI_STATUS_CHECK           name of the required check run (default ci)
#   GITHUB_TOKEN or GH_TOKEN  sent as a bearer token if set (raises the rate
#                             limit from 60 to 5000 requests/hour); never printed
#   CI_STATUS_API             API base URL, for testing against a local fake
#                             server (default https://api.github.com). A token
#                             is only ever sent to the default.
#
# Anonymous access works because the repo is public: 60 requests/hour per IP,
# shared with everything else on this machine. One poll = one request.
#
# Exit codes: 0 `ci` succeeded · 1 `ci` failed (failure, cancelled, timed_out,
# or any other non-success conclusion) · 2 timed out waiting · 64 usage error.
set -euo pipefail

readonly DEFAULT_API="https://api.github.com"
readonly API="${CI_STATUS_API:-$DEFAULT_API}"
readonly REPO="${CI_STATUS_REPO:-Abdelrahman-Hamza1/Fitness-Buddy}"
readonly CHECK_NAME="${CI_STATUS_CHECK:-ci}"
readonly INITIAL_WAIT="${CI_STATUS_INITIAL_WAIT:-180}"
readonly POLL_INTERVAL="${CI_STATUS_POLL_INTERVAL:-60}"

log() { printf '%s ci-status: %s\n' "$(date -u +%H:%M:%SZ)" "$*"; }
warn() { printf '%s ci-status: warning: %s\n' "$(date -u +%H:%M:%SZ)" "$*" >&2; }
usage_error() {
  printf 'ci-status: error: %s\n' "$*" >&2
  printf 'usage: %s <sha> [timeout-minutes]\n' "$(basename "$0")" >&2
  exit 64
}

# Plain decimals only: a leading zero would make bash read the number as octal.
is_uint() { [[ "$1" =~ ^(0|[1-9][0-9]*)$ ]]; }
is_positive() { [[ "$1" =~ ^[1-9][0-9]*$ ]]; }

# --- Arguments -----------------------------------------------------------------
(($# >= 1 && $# <= 2)) || usage_error "expected 1 or 2 arguments, got $#"
sha="$1"
timeout_min="${2:-25}"
[[ "$sha" =~ ^[0-9a-fA-F]{7,40}$ ]] || usage_error "not a commit SHA: '$sha'"
is_positive "$timeout_min" || usage_error "timeout must be a positive number of minutes: '$timeout_min'"
is_uint "$INITIAL_WAIT" || usage_error "CI_STATUS_INITIAL_WAIT must be whole seconds: '$INITIAL_WAIT'"
is_positive "$POLL_INTERVAL" || usage_error "CI_STATUS_POLL_INTERVAL must be positive whole seconds: '$POLL_INTERVAL'"
[[ "$REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || usage_error "CI_STATUS_REPO must be owner/repo: '$REPO'"
for tool in curl python3; do
  command -v "$tool" >/dev/null 2>&1 || usage_error "$tool is not installed"
done

token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
[[ "$API" == "$DEFAULT_API" ]] || token=""
url="$API/repos/$REPO/commits/$sha/check-runs?filter=latest&per_page=100"
deadline=$(($(date +%s) + timeout_min * 60))

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
body="$workdir/body.json"
headers="$workdir/headers.txt"

# Sleeps for $1 seconds, but never past the deadline. Returns 1 if the deadline
# has been reached (so the caller can stop).
sleep_until_deadline() {
  local want="$1" left
  left=$((deadline - $(date +%s)))
  ((left > 0)) || return 1
  ((want < left)) || want=$left
  ((want <= 0)) || sleep "$want"
  (($(date +%s) < deadline))
}

# Prints the value of response header $1 (case-insensitive), or nothing.
header() {
  awk -v name="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" -F': *' '
    { key = tolower($1); sub(/\r$/, "", $2) }
    key == name { value = $2 }
    END { if (value != "") print value }' "$headers"
}

# One GET. Sets http_code ("000" if curl itself failed). The token reaches curl
# on stdin (`-H @-`, here-string), so it never shows up in the process list, and
# only over https (redirects included). Without a token, http stays allowed for
# a local fake server (CI_STATUS_API).
fetch() {
  local auth=() auth_header=""
  if [[ -n "$token" ]]; then
    auth=(--proto '=https' --proto-redir '=https' -H @-)
    auth_header="Authorization: Bearer $token"
  fi
  : >"$headers"
  : >"$body"
  http_code="$(
    curl --silent --show-error --location \
      --connect-timeout 10 --max-time 30 \
      -H 'Accept: application/vnd.github+json' \
      -H 'X-GitHub-Api-Version: 2022-11-28' \
      -H 'User-Agent: fitness-buddy-ci-status' \
      "${auth[@]}" \
      --dump-header "$headers" --output "$body" \
      --write-out '%{http_code}' \
      "$url" <<<"$auth_header"
  )" || http_code="000"
}

# Reads the check runs JSON ($1) and prints one line per check run. Exit code:
# 0 = check $2 succeeded, 1 = it completed without success, 3 = still pending
# (missing, queued or in progress), 4 = the response could not be parsed.
# Only runs created by GitHub Actions count for the decision; with several runs
# of check $2, all must be completed and the newest (highest id) decides.
readonly SUMMARIZE_PY='
import json, sys

GITHUB_ACTIONS_APP_ID = 15368
path, wanted = sys.argv[1], sys.argv[2]
try:
    with open(path, encoding="utf-8") as f:
        runs = json.load(f)["check_runs"]
except (OSError, ValueError, KeyError, TypeError) as e:
    print(f"  cannot parse the API response: {e}")
    sys.exit(4)

def app_id(r):
    app = r.get("app")
    return app.get("id") if isinstance(app, dict) else None

def run_id(r):
    return r.get("id") if isinstance(r.get("id"), int) else -1

runs = sorted(runs, key=lambda r: (r.get("name") != wanted, r.get("name") or "", run_id(r)))
if not runs:
    print("  (no check runs yet)")
for r in runs:
    note = "" if app_id(r) == GITHUB_ACTIONS_APP_ID else "  [not GitHub Actions: ignored]"
    print("  {:<12} {:<12} {:<16} {}{}".format(
        r.get("name") or "?", r.get("status") or "?",
        r.get("conclusion") or "-", r.get("html_url") or "", note))

gate = [r for r in runs if r.get("name") == wanted and app_id(r) == GITHUB_ACTIONS_APP_ID]
if not gate or any(r.get("status") != "completed" for r in gate):
    sys.exit(3)
newest = max(gate, key=run_id)
sys.exit(0 if newest.get("conclusion") == "success" else 1)
'

log "repo $REPO, commit $sha, waiting for check '$CHECK_NAME' (timeout ${timeout_min} min)"
[[ -z "$token" ]] || log "using the token from GITHUB_TOKEN/GH_TOKEN"
# Cap the initial wait at timeout - 60 s (never negative), so at least one poll
# happens before the deadline whatever CI_STATUS_INITIAL_WAIT says.
initial_wait=$((timeout_min * 60 - 60))
if ((INITIAL_WAIT < initial_wait)); then initial_wait=$INITIAL_WAIT; fi
if ((initial_wait < 0)); then initial_wait=0; fi
if ((initial_wait > 0)); then
  log "first poll in ${initial_wait}s (CI_STATUS_INITIAL_WAIT=${INITIAL_WAIT}, capped at timeout - 60 s)"
  sleep "$initial_wait"
fi

previous=""
while :; do
  fetch
  remaining="$(header x-ratelimit-remaining || true)"
  wait_s="$POLL_INTERVAL"

  case "$http_code" in
    200)
      rc=0
      summary="$(python3 -I -c "$SUMMARIZE_PY" "$body" "$CHECK_NAME")" || rc=$?
      if [[ "$summary" != "$previous" ]]; then
        log "check runs (API requests left this hour: ${remaining:-?}):"
        printf '%s\n' "$summary"
        previous="$summary"
      fi
      case "$rc" in
        0) log "'$CHECK_NAME' succeeded on $sha"; exit 0 ;;
        1) log "'$CHECK_NAME' did NOT succeed on $sha (see the URLs above)"; exit 1 ;;
        3) log "'$CHECK_NAME' pending (requests left: ${remaining:-?})" ;;
        *) warn "unexpected API response, retrying" ;;
      esac
      ;;
    403 | 429)
      reset="$(header x-ratelimit-reset || true)"
      retry_after="$(header retry-after || true)"
      if [[ "$remaining" == 0 ]] && is_uint "${reset:-}"; then
        wait_s=$((reset - $(date +%s) + 1))
        ((wait_s > 0)) || wait_s=1
        warn "rate limit reached (HTTP $http_code), sleeping ${wait_s}s until it resets at $(date -u -d "@$reset" +%H:%M:%SZ)"
      elif is_uint "${retry_after:-}"; then
        wait_s=$((retry_after + 1))
        warn "throttled (HTTP $http_code), retrying in ${wait_s}s (Retry-After)"
      else
        warn "HTTP $http_code: $(head -c 300 "$body" 2>/dev/null | tr -d '\n'), retrying in ${wait_s}s"
      fi
      ;;
    404 | 422)
      # Unknown commit: not pushed yet, or a typo. Keep waiting until the timeout.
      warn "GitHub does not know commit $sha yet (HTTP $http_code); is it pushed?"
      ;;
    000)
      warn "network error talking to $API, retrying in ${wait_s}s"
      ;;
    *)
      warn "HTTP $http_code from the API, retrying in ${wait_s}s"
      ;;
  esac

  if ! sleep_until_deadline "$wait_s"; then
    log "timed out after ${timeout_min} min: '$CHECK_NAME' has not completed on $sha"
    exit 2
  fi
done
