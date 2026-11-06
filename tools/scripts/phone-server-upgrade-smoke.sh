#!/usr/bin/env bash
# B23 T17 (acceptance a6): a REAL existing-volume upgrade of the private laptop stack, synthetic data only.
# 1. Builds the base image from the pinned baseline (default bd9f9ffe, the last main before B23; override with
#    UPGRADE_BASE_REV) and runs it with ITS OWN compose file, non-default remote config and synthetic data (an account + a
#    synced weigh-in, an RLS table). Captures /v1/config and the account's pull.
# 2. Upgrades the same volume to the current image with the current compose file exactly as `serve-phone` does
#    (ensure-admin-role, ensure-worker-role, migrate, api, worker, admin; no Tailscale), then checks /v1/config is identical, version 1 is seeded
#    with those values, the data is unchanged, the console is ready, and backup + restore-check pass.
# The baseline is pinned on purpose: this script assumes the pre-B23 layout (no fb_admin role, config in x-environment).
# Move it forward deliberately, together with those assumptions, when a later layout change needs a newer baseline.
# Heavy (two image builds): run it manually through tools/scripts/heavy.sh, and CI runs it nightly. Every push runs the
# light variant inside phone-server-smoke.sh. Never touches the owner's phone stack or Tailscale.
# Env: UPGRADE_BASE_REV, UPGRADE_BASE_IMAGE (skip the base build), PHONE_SERVER_SMOKE_IMAGE (skip the current build).
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$repo_root"
base_rev=${UPGRADE_BASE_REV:-bd9f9ffe4d6f8b310ef6527080c9a454ddffd12d}
base_rev=$(git rev-parse --verify "$base_rev^{commit}")
work=$(mktemp -d "${TMPDIR:-/tmp}/fb-upgrade-smoke-XXXXXX")
trap 'rm -rf -- "$work"' EXIT
git archive "$base_rev" backend infra/phone-server | tar -x -C "$work"
base_image=${UPGRADE_BASE_IMAGE:-}
if [[ -z $base_image ]]; then
  base_image=fitness-buddy-api:upgrade-base
  docker build --quiet --tag "$base_image" "$work/backend" >/dev/null
fi
image=${PHONE_SERVER_SMOKE_IMAGE:-fitness-buddy-api:phone-smoke}
if [[ -z ${PHONE_SERVER_SMOKE_IMAGE:-} ]]; then
  docker build --quiet --tag "$image" "$repo_root/backend" >/dev/null
fi
echo "T17 upgrade: base ${base_rev:0:12} -> working tree"
PYTHONDONTWRITEBYTECODE=1 python3 -I - "$repo_root" "$work/infra/phone-server" "$base_image" "$image" <<'PY'
import importlib.util
import datetime as dt
import json
import os
from pathlib import Path
import secrets
import sys
import tempfile
import time
import urllib.error
import urllib.request
import uuid

repo, base_files, base_tag, current_tag = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3], sys.argv[4]
spec = importlib.util.spec_from_file_location('phone_server', repo / 'tools/scripts/phone-server.py')
phone = importlib.util.module_from_spec(spec)
spec.loader.exec_module(phone)
os.umask(0o077)
phone.PROJECT = 'fitness-buddy-phone-upgrade-' + secrets.token_hex(4)
image_id = lambda tag: phone.run(['docker', 'image', 'inspect', '--format', '{{.Id}}', tag]).decode().strip()
# Non-default values for every part of the served config, set the way each revision's compose file takes them.
NON_DEFAULT = {'Clients__MinimumAppVersion': '"0.0.9"', 'Account__ClientConfig__FeatureFlags__upgradeFlag': '"true"',
               'Account__ClientConfig__Thresholds__proposalQuestionKcalDelta': '"70"', 'FeatureFlags__upgradeServer': '"true"'}
HEADERS = {'Host': 'phone.example.ts.net', 'X-App-Version': '0.1.0', 'X-Platform': 'android',
           'X-Device-Id': '0192a5d4-7c3e-7b1a-9f2e-3c4d5e6f7a8b', 'Content-Type': 'application/json'}


def install(state, source, anchor, image):
    """Copies one revision's compose files into the state, with the non-default config added under `anchor`."""
    for name in ('compose.yml', 'init-roles.sh', 'admin-serve.json'):
        if not (source / name).exists():
            continue
        text = (source / name).read_text()
        if name == 'compose.yml':
            text = text.replace('127.0.0.1:5199:8080', '127.0.0.1::8080').replace('127.0.0.1:5197:8081', '127.0.0.1::8081')
            lines = [line for line in text.splitlines(keepends=True) if not line.strip().startswith('Clients__MinimumAppVersion:')]
            text = ''.join(lines)
            assert anchor in text, anchor
            text = text.replace(anchor, anchor + ''.join(f'  {key}: {value}\n' for key, value in NON_DEFAULT.items()), 1)
        phone.atomic(state / name, text.encode())
        if name == 'init-roles.sh':
            (state / name).chmod(0o644)
    phone.json_write(state / 'image.json', {'image': image_id(image), 'revision': 'synthetic-upgrade'})


def start(state, *services):
    phone.compose(state, 'up', '-d', '--wait', 'postgres')
    gateway = json.loads(phone.run(['docker', 'network', 'inspect', phone.PROJECT + '_default']))[0]['IPAM']['Config'][0]['Gateway']
    phone.json_write(state / 'gateway.json', {'gateway': gateway})
    if 'admin' in services:
        phone.ensure_admin_role(state)  # exactly what `up` does before migrate
        phone.ensure_worker_role(state)
    phone.compose(state, 'up', '-d', '--force-recreate', *services)
    base = 'http://127.0.0.1:' + phone.compose(state, 'port', 'api', '8080').decode().strip().split(':')[-1]
    for _ in range(90):
        if phone.ready(base):
            return base
        time.sleep(1)
    raise AssertionError('synthetic API did not become ready')


def call(base, path, payload=None, token=None, method='POST'):
    headers = dict(HEADERS, **({'Authorization': 'Bearer ' + token} if token else {}))
    data = json.dumps(payload).encode() if payload is not None else (b'' if method == 'POST' else None)
    with urllib.request.urlopen(urllib.request.Request(base + path, data=data, headers=headers, method=method), timeout=15) as response:
        body = response.read()
        return body.decode(), (json.loads(body) if body else None)


with tempfile.TemporaryDirectory(prefix='b23-upgrade-') as temp:
    state = Path(temp)
    phone.init(state)
    phone.configure_recovery(state)
    clients = state / 'synthetic-google.json'
    phone.json_write(clients, {'AndroidClientId': '123-android.apps.googleusercontent.com', 'WebClientId': '123-server.apps.googleusercontent.com'})
    phone.configure_identity(state, clients)
    try:
        # ---- 1. The base revision, as deployed before this change --------------------------------------------------
        install(state, base_files, 'x-environment: &environment\n', base_tag)
        base = start(state, 'migrate', 'api', 'worker')
        assert phone.sql(state, "SELECT count(*) FROM pg_roles WHERE rolname IN ('fb_admin','fb_worker');").strip() == '0', 'base volume already has the console or worker role'
        config_before, parsed = call(base, '/v1/config', method='GET')
        assert parsed['minimumAppVersion'] == '0.0.9' and parsed['featureFlags'] == {'upgradeFlag': True}, parsed
        assert parsed['thresholds'] == {'proposalQuestionKcalDelta': 70}, parsed
        # A registered account (guests don't sync), through the local email delivery of the identity overlay.
        _, challenge = call(base, '/v1/auth/email/start', {'email': 'upgrade@example.invalid', 'purpose': 'signIn'})
        delivered = phone.read_json(state / 'identity' / 'email' / (challenge['challengeId'] + '.json'))
        _, account = call(base, '/v1/auth/email/verify', {'challengeId': challenge['challengeId'], 'code': delivered['code']})
        _, page = call(base, '/v1/sync/pull?cursor=0&limit=100', token=account['accessToken'], method='GET')
        payload = json.loads((repo / 'contracts/testdata/sync/entity-payloads.json').read_text())['weighIn']
        row = {'entity': 'weighIn', 'id': str(uuid.uuid4()), 'schemaVersion': 1, 'hlc': f"{int(time.time()*1000):013d}-00000-{HEADERS['X-Device-Id']}",
               'deviceId': HEADERS['X-Device-Id'], 'deletedAt': None, 'payload': payload}
        _, pushed = call(base, '/v1/sync/push', {'datasetId': page['datasetId'], 'changes': [row]}, account['accessToken'])
        assert pushed['results'][0]['status'] == 'accepted', pushed
        _, pulled_before = call(base, '/v1/sync/pull?cursor=0&limit=100', token=account['accessToken'], method='GET')
        phone.sql(state, '''CREATE TABLE userdata.b23_upgrade (user_id uuid NOT NULL, value integer NOT NULL);
ALTER TABLE userdata.b23_upgrade ENABLE ROW LEVEL SECURITY; ALTER TABLE userdata.b23_upgrade FORCE ROW LEVEL SECURITY;
INSERT INTO userdata.b23_upgrade VALUES (gen_random_uuid(), 11), (gen_random_uuid(), 22);''')
        phone.compose(state, 'stop')  # serve-phone-stop

        # ---- 2. Upgrade the same volume exactly like serve-phone (minus Tailscale) ----------------------------------
        install(state, repo / 'infra/phone-server', '  Clients__MinimumAppVersionOverride: ${FB_PHONE_MIN_VERSION_OVERRIDE:-}\n', current_tag)
        phone.configure_console(state, '1234567890-upgrade.apps.googleusercontent.com')
        phone.json_write(state / 'console' / 'allow-list.json', {'admins': [{'handle': 'owner', 'googleSubject': '1234567890',
                         'email': 'owner@example.invalid', 'role': 'operator'}], 'pending': []})
        base = start(state, 'migrate', 'api', 'worker', 'admin')
        config_after, _ = call(base, '/v1/config', method='GET')
        assert config_after == config_before, (config_before, config_after)
        seeded = phone.sql(state, "SELECT version, published_by, document->>'minimumAppVersion', document->'featureFlags'->>'upgradeFlag', document->'serverFlags'->>'upgradeServer', document->'thresholds'->>'proposalQuestionKcalDelta' FROM account.config_versions;").strip()
        assert seeded == '1|seed|0.0.9|true|true|70', seeded
        # The same account keeps working (refresh token, signing keys) and sees exactly its data.
        _, renewed = call(base, '/v1/auth/refresh', {'refreshToken': account['refreshToken']})
        _, pulled_after = call(base, '/v1/sync/pull?cursor=0&limit=100', token=renewed['accessToken'], method='GET')
        assert pulled_after['changes'] == pulled_before['changes'] and pulled_after['datasetId'] == pulled_before['datasetId']
        assert phone.sql(state, 'SELECT count(*), sum(value) FROM userdata.b23_upgrade;').strip() == '2|33'
        console = 'http://127.0.0.1:' + phone.compose(state, 'port', 'admin', '8081').decode().strip().split(':')[-1]
        for _ in range(60):
            if phone.ready(console):
                break
            time.sleep(1)
        else:
            raise AssertionError('console did not become ready on the upgraded volume')
        # A second start (the next serve-phone) is a no-op for roles, seed and data.
        start(state, 'migrate', 'api', 'worker', 'admin')
        assert phone.sql(state, 'SELECT count(*) FROM account.config_versions;').strip() == '1'
        # B23b: the upgraded worker runs on its own login and beats; the API login can't write heartbeats.
        for _ in range(60):
            if phone.sql(state, 'SELECT count(*) FROM ops.worker_heartbeats;').strip() != '0':
                break
            time.sleep(1)
        else:
            raise AssertionError('the upgraded worker wrote no heartbeat on fb_worker')
        assert phone.sql(state, "SELECT has_table_privilege('fb_app','ops.worker_heartbeats','INSERT'), has_table_privilege('fb_worker','ops.worker_heartbeats','INSERT');").strip() == 'f|t'
        phone.backup(state)
        phone.restore_check(state)  # requires admin.* and account.config_versions in the restored dump
        print('B23 T17 upgrade: base image -> current on one volume; /v1/config byte-identical with non-default values; v1 seeded once; '
              'account, synced data and RLS rows preserved; console ready; backup + restore-check passed')
    finally:
        phone.compose(state, 'down', '-v')
PY
