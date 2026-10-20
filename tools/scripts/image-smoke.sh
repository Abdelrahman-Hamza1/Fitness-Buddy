#!/usr/bin/env bash
# S03 D15/D16: exercise the shipped image, including its identity, exporters and process lifecycle.
set -euo pipefail
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
image="fitness-buddy-api:smoke"
container=""
worker=""
postgres=""
network=""
recovery_volume=""
work="$(mktemp -d)"
cleanup() {
  local result=$?
  for running in "$container" "$worker" "$postgres"; do
    if [[ -n "$running" ]]; then
      if (( result != 0 )); then docker logs "$running" >&2 || true; fi
      docker rm -f "$running" >/dev/null 2>&1 || true
    fi
  done
  if [[ -n "$network" ]]; then docker network rm "$network" >/dev/null 2>&1 || true; fi
  if [[ -n "$recovery_volume" ]]; then docker volume rm "$recovery_volume" >/dev/null 2>&1 || true; fi
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
# Read the one production-like local pin; fixture and compose must use the same engine.
pg_image="$(python3 - "$repo_root" <<'PYPG'
import pathlib,re,sys
root=pathlib.Path(sys.argv[1])
text=(root/'infra/compose/docker-compose.yml').read_text()
image=re.search(r'image: (postgres:[^\s]+)',text)[1]
assert image in (root/'backend/tests/Persistence.Tests/PostgresFixture.cs').read_text(), 'compose/Testcontainers database pins differ'
print(image)
PYPG
)"
network="$(docker network create "fitness-buddy-smoke-$$")"
postgres="$(docker run -d --network "$network" --network-alias postgres --tmpfs /var/lib/postgresql \
  -e POSTGRES_DB=fitness_buddy -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=local-admin-only \
  -v "$repo_root/infra/compose/postgres/001-roles.sql:/docker-entrypoint-initdb.d/001-roles.sql:ro" "$pg_image" \
  postgres -c log_min_messages=fatal -c log_min_error_statement=panic -c log_error_verbosity=terse \
  -c log_statement=none -c log_parameter_max_length=0 -c log_parameter_max_length_on_error=0)"
pg_ready=false
for (( attempt=0; attempt<60; attempt++ )); do
  if docker exec "$postgres" pg_isready -U postgres -d fitness_buddy >/dev/null 2>&1; then pg_ready=true; break; fi
  sleep 1
done
[[ "$pg_ready" == true ]] || { echo 'image-smoke: database readiness timed out' >&2; exit 1; }
# pg_isready can see the temporary bootstrap server; wait for the final TCP listener as well.
for (( attempt=0; attempt<30; attempt++ )); do
  if docker exec "$postgres" pg_isready -h 127.0.0.1 -U postgres -d fitness_buddy >/dev/null 2>&1; then break; fi
  sleep 1
done
runtime_flags=(--read-only --tmpfs /tmp --cap-drop ALL --security-opt no-new-privileges:true --network "$network")
recovery_volume="$(docker volume create "fitness-buddy-smoke-recovery-$$")"
docker run --rm --user 0 -v "$recovery_volume:/recovery" "$pg_image" sh -c 'chown 1654:1654 /recovery && chmod 700 /recovery'
recovery_flags=(-v "$recovery_volume:/recovery:rw" -e Recovery__Directory=/recovery)
app_connection='Host=postgres;Database=fitness_buddy;Username=fb_app;Password=local-app-only'
migrator_connection='Host=postgres;Database=fitness_buddy;Username=fb_migrator;Password=local-migrator-only'
for migration_run in 1 2; do
  docker run --rm "${runtime_flags[@]}" "${recovery_flags[@]}" -e "ConnectionStrings__Migrator=$migrator_connection" "$image" migrate --Recovery:Initialize=true >"$work/migrate-$migration_run"
done
container="$(docker run -d "${runtime_flags[@]}" "${recovery_flags[@]}" \
  -e ASPNETCORE_ENVIRONMENT=Development -e Observability__ConsoleExporter=true \
  -e "ConnectionStrings__Application=$app_connection" -p 127.0.0.1::8080 "$image")"
worker="$(docker run -d "${runtime_flags[@]}" -v "$recovery_volume:/recovery:ro" -e Recovery__Directory=/recovery -e "ConnectionStrings__Application=$app_connection" "$image" worker)"
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
schedule_seen=false
for (( attempt=0; attempt<15; attempt++ )); do
  count="$(docker exec "$postgres" psql -U postgres -d fitness_buddy -Atc "SELECT count(*) FROM ops.schedules WHERE name='ops.cleanup'")"
  if [[ "$count" == 1 ]]; then schedule_seen=true; break; fi
  sleep 1
done
[[ "$schedule_seen" == true ]] || { echo 'image-smoke: worker did not register its durable schedule' >&2; exit 1; }
if docker exec "$postgres" psql -U postgres -d fitness_buddy -c 'SELECT "CANARY-SQL-CONTENT"' >"$work/sql-error" 2>&1; then
  echo 'image-smoke: expected synthetic SQL error' >&2; exit 1
fi
docker logs "$postgres" >"$work/pg-logs" 2>&1
if grep -q CANARY-SQL-CONTENT "$work/pg-logs"; then echo 'image-smoke: private SQL leaked to database logs' >&2; exit 1; fi
# The running API must stop advertising readiness when its only stateful dependency disappears.
docker stop --timeout 10 "$postgres" >/dev/null
status="$(curl --silent --max-time 5 -o /dev/null -w '%{http_code}' "$base_url/health/ready")"
[[ "$status" == 503 ]] || { echo "image-smoke: database-down readiness=$status" >&2; exit 1; }
curl --fail --silent --max-time 5 "$base_url/health/live" >/dev/null
worker_uid="$(docker top "$worker" -eo pid,uid | awk 'NR > 1 { print $2 }' | sort -u | tr -d '[:space:]')"
[[ "$worker_uid" == 1654 ]] || { echo "image-smoke: worker UID is $worker_uid" >&2; exit 1; }
docker stop --timeout 10 "$worker" >/dev/null
[[ "$(docker inspect --format '{{.State.ExitCode}}' "$worker")" == 0 ]] || { echo 'image-smoke: worker did not shut down cleanly' >&2; exit 1; }
started=$SECONDS
docker stop --timeout 10 "$container" >/dev/null
elapsed=$((SECONDS - started))
exit_code="$(docker inspect --format '{{.State.ExitCode}}' "$container")"
[[ "$exit_code" == 0 && "$elapsed" -lt 10 ]] || { echo "image-smoke: stop exit=$exit_code elapsed=${elapsed}s" >&2; exit 1; }
size="$(docker image inspect --format '{{.Size}}' "$image")"
compressed="$(docker image save "$image" | gzip -c | wc -c | tr -d '[:space:]')"
printf 'image-smoke: PASS UID=%s config=200 trace=%s migrate=0/repeat=0 worker=0 ready-down=503/live=200 stop=%ss/exit=%s size=%s bytes gzip-archive=%s bytes\n' \
  "$uid" "$trace_id" "$elapsed" "$exit_code" "$size" "$compressed"
