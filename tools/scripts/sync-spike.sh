#!/usr/bin/env bash
# B05: authenticated synthetic production sync against the shipped image and app-role Postgres.
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
# Keys and local email deliveries are ephemeral; never use an owner identity or external provider.
mkdir -p "$work/identity/email" "$work/email" "$work/recovery"
chmod 700 "$work" "$work/identity" "$work/email" "$work/recovery"
python3 - "$work/identity" <<'PYKEY'
import os,pathlib,secrets,sys
for name in ['v1.key','pepper']:
 p=pathlib.Path(sys.argv[1])/name;p.write_bytes(secrets.token_bytes(32));os.chmod(p,0o600)
PYKEY
identity_flags=(--user "$(id -u):$(id -g)" -v "$work/recovery:/recovery:rw" -e Recovery__Directory=/recovery -v "$work/identity:/identity:ro" -v "$work/email:/identity/email:rw"
  -e Identity__Enabled=true -e Identity__WrappingKeysDirectory=/identity -e Identity__PepperFile=/identity/pepper
  -e Identity__Email__LocalFile__Enabled=true -e Identity__PrivateLaptop=true
  -e Identity__Email__LocalFile__Directory=/identity/email)
docker run --rm "${runtime_flags[@]}" "${identity_flags[@]}" -e "ConnectionStrings__Migrator=$migrator_connection" "$image" migrate --Identity:KeyOperation=ensure --Recovery:Initialize=true >"$work/keys"
api="$(docker run -d "${runtime_flags[@]}" "${identity_flags[@]}" -p 127.0.0.1::8080 \
  -e ASPNETCORE_ENVIRONMENT=Production -e RateLimiting__PerUser__PermitLimit=100000 \
  -e Logging__LogLevel__FitnessBuddy.Modules.UserData.Infrastructure.SyncTelemetry=Debug \
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
SYNC_ACCESS_TOKEN="$(python3 - "$base_url" "$work/email" <<'PYAUTH'
import json,pathlib,sys,urllib.request
base,folder=sys.argv[1:]
def post(path,body):
 request=urllib.request.Request(base+path,data=json.dumps(body).encode(),headers={'Content-Type':'application/json','X-App-Version':'0.1.0','X-Platform':'android','X-Device-Id':'00000000-0000-7000-8000-000000000001'})
 with urllib.request.urlopen(request) as response:return json.load(response)
challenge=post('/v1/auth/email/start',{'email':'sync-smoke@example.invalid','purpose':'signIn'})
files=list(pathlib.Path(folder).glob('*.json'))
assert len(files)==1
code=json.loads(files[0].read_text())
result=post('/v1/auth/email/verify',{'challengeId':challenge['challengeId'],'code':code['code']})
print(result['accessToken'])
PYAUTH
)"
export SYNC_ACCESS_TOKEN
cd "$repo_root/tools/sync_sim"
"$DART" run bin/sync_sim.dart "$base_url"
# Independent database assertions supplement the Dart oracle. No payload output.
docker exec "$postgres" psql -U postgres -d fitness_buddy -v ON_ERROR_STOP=1 -Atc \
  "SELECT CASE WHEN count(*)=10000 THEN '10000 benchmark documents stored' ELSE 'FAILED' END FROM userdata.documents WHERE id>='00000000-0000-7000-8000-000000989680' AND id<'00000000-0000-7000-8000-00000098bd90'" >"$work/count"
grep -qx '10000 benchmark documents stored' "$work/count"
cat "$work/count"

# Synthetic measurements only: bounded operation/duration fields, no request values.
docker logs "$api" >"$work/api-log" 2>&1
python3 - "$work/api-log" <<'PYPERF'
import json,math,sys
samples={}
for line in open(sys.argv[1]):
 try: row=json.loads(line)
 except (ValueError,TypeError):continue
 state=row.get('State',{})
 if row.get('Category')=='FitnessBuddy.Modules.UserData.Infrastructure.SyncTelemetry' and 'Milliseconds' in state:
  samples.setdefault(state['Operation'],[]).append(state['Milliseconds'])
assert samples, 'server duration measurements missing'
for operation,values in sorted(samples.items()):
 values.sort();print(f'server handler {operation}: requests={len(values)} p95={values[math.ceil(len(values)*.95)-1]:.2f} ms')
PYPERF
docker exec "$postgres" psql -U postgres -d fitness_buddy -v ON_ERROR_STOP=1 -Atc \
  "SELECT 'receipt rows='||count(*) FROM userdata.version_receipts; SELECT 'receipt bytes='||pg_total_relation_size('userdata.version_receipts');"
# A faithful dump transfer retains both data and epoch; a rollback operator rotates before traffic.
docker exec "$postgres" pg_dump -U postgres -d fitness_buddy --format=custom >"$work/transfer.dump"
epoch="$(docker exec "$postgres" psql -U postgres -d fitness_buddy -Atc 'SELECT id FROM userdata.dataset')"
docker exec "$postgres" psql -U postgres -d fitness_buddy -v ON_ERROR_STOP=1 -c 'CREATE DATABASE fitness_buddy_restore OWNER fb_migrator' >/dev/null
docker exec -i "$postgres" pg_restore -U postgres --role=fb_migrator --no-owner --exit-on-error -d fitness_buddy_restore <"$work/transfer.dump"
restored_epoch="$(docker exec "$postgres" psql -U postgres -d fitness_buddy_restore -Atc 'SELECT id FROM userdata.dataset')"
[[ "$epoch" == "$restored_epoch" ]]
for database in fitness_buddy fitness_buddy_restore; do
  docker exec "$postgres" psql -U postgres -d "$database" -Atc \
    'SELECT (SELECT count(*) FROM userdata.documents),(SELECT count(*) FROM userdata.row_history),(SELECT count(*) FROM userdata.version_receipts)' >"$work/$database.counts"
done
cmp "$work/fitness_buddy.counts" "$work/fitness_buddy_restore.counts"
docker run --rm "${runtime_flags[@]}" "${identity_flags[@]}" \
  -e 'ConnectionStrings__Migrator=Host=postgres;Database=fitness_buddy_restore;Username=fb_migrator;Password=local-migrator-only' \
  "$image" migrate --Sync:RotateDataset=true >"$work/restore-epoch"
rotated_epoch="$(docker exec "$postgres" psql -U postgres -d fitness_buddy_restore -Atc 'SELECT id FROM userdata.dataset')"
[[ "$rotated_epoch" != "$epoch" ]]
echo 'faithful dump transfer preserved counts/epoch; rollback operator rotated epoch before traffic'
