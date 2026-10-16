#!/usr/bin/env bash
# B01: synthetic-data protocol checks against the shipped image and app-role Postgres.
set -euo pipefail
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
: "${DART:?make sync-spike passes DART}"
image="${SYNC_SPIKE_IMAGE:-fitness-buddy-api:sync-spike}"
network=""
postgres=""
api=""
work="$(mktemp -d)"
cleanup() {
  local result=$?
  for container in "$api" "$postgres"; do
    if [[ -n "$container" ]]; then
      if (( result != 0 )); then docker logs "$container" >&2 || true; fi
      docker rm -f "$container" >/dev/null 2>&1 || true
    fi
  done
  if [[ -n "$network" ]]; then docker network rm "$network" >/dev/null 2>&1 || true; fi
  rm -rf -- "$work"
  exit "$result"
}
trap cleanup EXIT
if [[ "${SYNC_SPIKE_SKIP_BUILD:-0}" != 1 ]]; then
  docker build --tag "$image" --file "$repo_root/backend/Dockerfile" "$repo_root/backend"
fi
pg_image="$(python3 - "$repo_root" <<'PY'
import pathlib,re,sys
text=(pathlib.Path(sys.argv[1])/'infra/compose/docker-compose.yml').read_text()
print(re.search(r'image: (postgres:[^\s]+)',text)[1])
PY
)"
network="$(docker network create "fitness-buddy-sync-spike-$$")"
postgres="$(docker run -d --network "$network" --network-alias postgres --tmpfs /var/lib/postgresql \
  -e POSTGRES_DB=fitness_buddy -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=local-admin-only \
  -v "$repo_root/infra/compose/postgres/001-roles.sql:/docker-entrypoint-initdb.d/001-roles.sql:ro" "$pg_image" \
  postgres -c log_min_messages=fatal -c log_min_error_statement=panic -c log_error_verbosity=terse \
  -c log_statement=none -c log_parameter_max_length=0 -c log_parameter_max_length_on_error=0)"
ready=false
for (( attempt=0; attempt<60; attempt++ )); do
  if docker exec "$postgres" pg_isready -h 127.0.0.1 -U postgres -d fitness_buddy >/dev/null 2>&1; then ready=true; break; fi
  sleep 1
done
[[ "$ready" == true ]] || { echo 'sync-spike: database readiness timed out' >&2; exit 1; }
runtime_flags=(--read-only --tmpfs /tmp --cap-drop ALL --security-opt no-new-privileges:true --network "$network")
app_connection='Host=postgres;Database=fitness_buddy;Username=fb_app;Password=local-app-only'
migrator_connection='Host=postgres;Database=fitness_buddy;Username=fb_migrator;Password=local-migrator-only'
docker run --rm "${runtime_flags[@]}" -e "ConnectionStrings__Migrator=$migrator_connection" "$image" migrate >"$work/migrate"
# Ephemeral access key never goes into the repo, output or production configuration.
SYNC_SPIKE_KEY="$(python3 -c 'import secrets; print(secrets.token_hex(32))')"
export SYNC_SPIKE_KEY
api="$(docker run -d "${runtime_flags[@]}" -p 127.0.0.1::8080 \
  -e ASPNETCORE_ENVIRONMENT=SyncSpike -e SyncSpike__Enabled=true \
  -e "SyncSpike__Key=$SYNC_SPIKE_KEY" -e SyncSpike__UserId=00000000-0000-7000-8000-000000000001 \
  -e RateLimiting__PerIp__PermitLimit=100000 -e "ConnectionStrings__Application=$app_connection" "$image")"
port="$(docker port "$api" 8080/tcp | sed -n 's/^127\.0\.0\.1://p')"
[[ "$port" =~ ^[0-9]+$ ]]
base_url="http://127.0.0.1:$port"
ready=false
for (( attempt=0; attempt<30; attempt++ )); do
  if curl --fail --silent --max-time 1 "$base_url/health/ready" >/dev/null; then ready=true; break; fi
  sleep 1
done
[[ "$ready" == true ]] || { echo 'sync-spike: API readiness timed out' >&2; exit 1; }
cd "$repo_root/tools/sync_sim"
"$DART" run bin/sync_sim.dart "$base_url"
# Independent database assertions supplement the Dart oracle. No payload output.
docker exec "$postgres" psql -U postgres -d fitness_buddy -v ON_ERROR_STOP=1 -Atc \
  "SELECT CASE WHEN count(*)=5000 THEN '5000 benchmark documents stored' ELSE 'FAILED' END FROM userdata.documents WHERE id>='00000000-0000-7000-8000-000000989680' AND id<'00000000-0000-7000-8000-00000098aa08'" >"$work/count"
grep -qx '5000 benchmark documents stored' "$work/count"
cat "$work/count"
