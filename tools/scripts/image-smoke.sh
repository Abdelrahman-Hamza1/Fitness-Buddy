#!/usr/bin/env bash
# S03 D15/D16: exercise the shipped image, including its identity, exporters and process lifecycle.
set -euo pipefail
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
image="fitness-buddy-api:smoke"
container=""
work="$(mktemp -d)"
cleanup() {
  local result=$?
  if [[ -n "$container" ]]; then
    if (( result != 0 )); then docker logs "$container" >&2 || true; fi
    docker rm -f "$container" >/dev/null 2>&1 || true
  fi
  rm -rf -- "$work"
  exit "$result"
}
trap cleanup EXIT

# Dependabot updates the SDK and Docker pins independently; fail before building if they drift.
python3 - "$repo_root" <<'PY'
import json, pathlib, re, sys
root = pathlib.Path(sys.argv[1])
expected = json.loads((root / 'backend/global.json').read_text())['sdk']['version']
text = (root / 'backend/Dockerfile').read_text()
actual = re.search(r'^FROM mcr.microsoft.com/dotnet/sdk:([^-]+)-', text, re.M)
if actual is None or actual[1] != expected:
    sys.exit('image-smoke: SDK image must match backend/global.json; bump both pins together')
PY

if ! docker build --tag "$image" --file "$repo_root/backend/Dockerfile" "$repo_root/backend"; then
  echo 'image-smoke: first build failed; retrying once (registry/network may be transient)' >&2
  docker build --tag "$image" --file "$repo_root/backend/Dockerfile" "$repo_root/backend"
fi
user="$(docker image inspect --format '{{.Config.User}}' "$image")"
[[ "$user" == 1654 ]] || { echo "image-smoke: expected configured UID 1654, got $user" >&2; exit 1; }
container="$(docker run -d --read-only --tmpfs /tmp --cap-drop ALL --security-opt no-new-privileges:true \
  -e ASPNETCORE_ENVIRONMENT=Development -e Observability__ConsoleExporter=true \
  -p 127.0.0.1::8080 "$image")"
port="$(docker port "$container" 8080/tcp | sed -n 's/^127\.0\.0\.1://p')"
[[ "$port" =~ ^[0-9]+$ ]]
base_url="http://127.0.0.1:$port"
ready=false
for (( attempt=0; attempt<30; attempt++ )); do
  if curl --fail --silent --max-time 1 "$base_url/health/ready" >"$work/ready"; then ready=true; break; fi
  sleep 1
done
[[ "$ready" == true ]] || { echo 'image-smoke: readiness timed out' >&2; exit 1; }
curl --fail --silent --show-error --max-time 5 "$base_url/health/live" >"$work/live"
uid="$(docker top "$container" -eo pid,uid | awk 'NR > 1 { print $2 }' | sort -u | tr -d '[:space:]')"
[[ "$uid" == 1654 ]] || { echo "image-smoke: process UID is $uid" >&2; exit 1; }
curl --fail --silent --show-error --max-time 5 -D "$work/headers" \
  -H 'X-App-Version: 0.1.0' -H 'X-Platform: android' \
  -H 'X-Device-Id: 0192a5d4-7c3e-7b1a-9f2e-3c4d5e6f7a8b' \
  "$base_url/v1/config" >"$work/config.json"
trace_id="$(python3 - "$work" <<'PY'
import json, pathlib, re, sys
work = pathlib.Path(sys.argv[1])
value = json.loads((work / 'config.json').read_text())
assert sorted(value) == ['featureFlags', 'minimumAppVersion', 'thresholds'], value
assert value['minimumAppVersion'] == '0.1.0', value
assert isinstance(value['featureFlags'], dict) and isinstance(value['thresholds'], dict), value
headers = (work / 'headers').read_text()
match = re.search(r'^x-request-id: ([0-9a-f]{32})\s*$', headers, re.I | re.M)
assert match, headers
print(match[1])
PY
)"
trace_seen=false
for (( attempt=0; attempt<10; attempt++ )); do
  docker logs "$container" >"$work/logs" 2>&1
  if grep -Eq "Activity.TraceId:[[:space:]]*$trace_id" "$work/logs"; then trace_seen=true; break; fi
  sleep 1
done
[[ "$trace_seen" == true ]] || { echo 'image-smoke: matching console trace not found' >&2; exit 1; }
docker run --rm --read-only --tmpfs /tmp --cap-drop ALL --security-opt no-new-privileges:true "$image" migrate >"$work/migrate"
started=$SECONDS
docker stop --timeout 10 "$container" >/dev/null
elapsed=$((SECONDS - started))
exit_code="$(docker inspect --format '{{.State.ExitCode}}' "$container")"
[[ "$exit_code" == 0 && "$elapsed" -lt 10 ]] || { echo "image-smoke: stop exit=$exit_code elapsed=${elapsed}s" >&2; exit 1; }
size="$(docker image inspect --format '{{.Size}}' "$image")"
compressed="$(docker image save "$image" | gzip -c | wc -c | tr -d '[:space:]')"
printf 'image-smoke: PASS UID=%s config=200 trace=%s migrate=0 stop=%ss/exit=%s size=%s bytes gzip-archive=%s bytes\n' \
  "$uid" "$trace_id" "$elapsed" "$exit_code" "$size" "$compressed"
