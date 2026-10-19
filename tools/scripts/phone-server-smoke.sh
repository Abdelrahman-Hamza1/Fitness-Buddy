#!/usr/bin/env bash
# B03: only ephemeral synthetic projects; never touches the owner's phone stack or Tailscale.
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
image=${PHONE_SERVER_SMOKE_IMAGE:-fitness-buddy-api:phone-smoke}
if [[ -z ${PHONE_SERVER_SMOKE_IMAGE:-} ]]; then
  docker build --tag "$image" "$repo_root/backend"
fi
PYTHONDONTWRITEBYTECODE=1 python3 -I - "$repo_root" "$image" <<'PY'
import importlib.util
import json
import os
from pathlib import Path
import secrets
import subprocess
import sys
import tempfile
import time
import urllib.request

repo = Path(sys.argv[1])
spec = importlib.util.spec_from_file_location('phone_server', repo / 'tools/scripts/phone-server.py')
phone = importlib.util.module_from_spec(spec)
spec.loader.exec_module(phone)
os.umask(0o077)
phone.PROJECT = 'fitness-buddy-phone-smoke-' + secrets.token_hex(4)
dev_project = 'fitness-buddy-dev-smoke-' + secrets.token_hex(4)
image = phone.run(['docker', 'image', 'inspect', '--format', '{{.Id}}', sys.argv[2]]).decode().strip()
with tempfile.TemporaryDirectory(prefix='b03-smoke-') as temp:
    state = Path(temp)
    phone.init(state)
    for name in ('compose.yml', 'init-roles.sh'):
        text = (repo / 'infra/phone-server' / name).read_text()
        if name == 'compose.yml':
            text = text.replace('127.0.0.1:5199:8080', '127.0.0.1::8080')
        phone.atomic(state / name, text.encode())
        if name == 'init-roles.sh':
            (state / name).chmod(0o644)
    phone.json_write(state / 'image.json', {'image': image, 'revision': 'synthetic-smoke'})
    env = phone.secrets_env(state)
    dev_args = ['docker', 'compose', '--env-file', '/dev/null', '-p', dev_project, '-f', str(repo / 'infra/compose/docker-compose.yml')]
    try:
        phone.compose(state, 'up', '-d', '--wait', 'postgres')
        network = json.loads(phone.run(['docker', 'network', 'inspect', phone.PROJECT + '_default']))[0]
        gateway = network['IPAM']['Config'][0]['Gateway']
        phone.json_write(state / 'gateway.json', {'gateway': gateway})
        phone.compose(state, 'up', '-d', 'migrate', 'api', 'worker')
        port = phone.compose(state, 'port', 'api', '8080').decode().strip().split(':')[-1]
        base = 'http://127.0.0.1:' + port
        for _ in range(60):
            if phone.ready(base):
                break
            time.sleep(1)
        else:
            raise AssertionError('synthetic phone API did not become ready')
        api = phone.compose(state, 'ps', '-q', 'api').decode().strip()
        meta = json.loads(phone.run(['docker', 'inspect', api]))[0]
        assert meta['Image'] == image
        assert meta['Config']['User'] == '1654'
        assert meta['HostConfig']['ReadonlyRootfs']
        assert meta['HostConfig']['CapDrop'] == ['ALL']
        assert all('127.0.0.1' == entry['HostIp'] for entries in meta['NetworkSettings']['Ports'].values() for entry in entries)
        app_env = dict(item.split('=', 1) for item in meta['Config']['Env'])
        assert app_env['DOTNET_ENVIRONMENT'] == 'Production'
        assert 'ConnectionStrings__Migrator' not in app_env
        assert not any('ADMIN_PASSWORD' in key or 'BACKUP_PASSWORD' in key for key in app_env)
        assert app_env['Observability__ConsoleExporter'] == 'false'
        headers = {'Host': 'phone.example.ts.net', 'X-App-Version': '0.1.0', 'X-Platform': 'android',
                   'X-Device-Id': '0192a5d4-7c3e-7b1a-9f2e-3c4d5e6f7a8b',
                   'X-Sync-Spike-Key': 'synthetic-disabled-spike-header'}
        with urllib.request.urlopen(urllib.request.Request(base + '/v1/config', headers=headers)) as response:
            config = json.load(response)
            assert set(config) == {'featureFlags', 'minimumAppVersion', 'thresholds'}
            assert 'Strict-Transport-Security' not in response.headers
        forwarded = dict(headers, **{'X-Forwarded-Proto': 'https', 'X-Forwarded-For': '100.64.0.3'})
        with urllib.request.urlopen(urllib.request.Request(base + '/v1/config', headers=forwarded)) as response:
            assert 'max-age=' in response.headers['Strict-Transport-Security']
        # Build-time document and experimental sync must not be exposed on this real-data stack.
        for path, expected in [('/openapi/v1.json', 404), ('/v1/sync/pull?cursor=0&limit=100', 401)]:
            try:
                urllib.request.urlopen(urllib.request.Request(base + path, headers=headers))
            except urllib.error.HTTPError as error:
                assert error.code == expected, (path, error.code)
            else:
                raise AssertionError('dark route unexpectedly exposed')
        # FORCE RLS data from two synthetic principals must survive a backup, without granting writes.
        phone.sql(state, '''CREATE TABLE userdata.b03_smoke (user_id uuid NOT NULL, value integer NOT NULL);
ALTER TABLE userdata.b03_smoke ENABLE ROW LEVEL SECURITY;
ALTER TABLE userdata.b03_smoke FORCE ROW LEVEL SECURITY;
CREATE POLICY isolated ON userdata.b03_smoke USING (user_id = NULLIF(current_setting('app.user_id', true), '')::uuid);
INSERT INTO userdata.b03_smoke VALUES ('0192a5d4-7c3e-7b1a-9f2e-3c4d5e6f7a8b', 11), ('0192a5d4-7c3e-7b1a-9f2e-3c4d5e6f7a8c',22);''')
        assert phone.sql(state, 'SELECT sum(value) FROM userdata.b03_smoke;', role='fb_backup').strip() == '33'
        rights = phone.sql(state, "SELECT rolsuper,rolcreatedb,rolcreaterole,rolreplication,rolbypassrls FROM pg_roles WHERE rolname='fb_backup';").strip()
        assert rights == 'f|f|f|f|t'
        try:
            phone.sql(state, 'DELETE FROM userdata.b03_smoke;', role='fb_backup')
        except phone.Failure:
            pass
        else:
            raise AssertionError('backup role could write')
        # Execute the relocated entry point exactly as the timer does, on a random synthetic project.
        snapshot = (repo / 'tools/scripts/phone-server.py').read_text().replace("PROJECT = 'fitness-buddy-phone'", f"PROJECT = '{phone.PROJECT}'")
        phone.atomic(state / 'phone-server.py', snapshot.encode())
        phone.run(['/usr/bin/python3', str(state / 'phone-server.py'), '--state', str(state), 'backup'])
        phone.run(['/usr/bin/python3', str(state / 'phone-server.py'), '--state', str(state), 'restore-check'])
        # Also check protected data content/count in a disposable restore, independently of controller success.
        scratch = 'fb_restore_' + secrets.token_hex(8)
        phone.sql(state, f'CREATE DATABASE {scratch};')
        try:
            archive = sorted((state / 'backups').glob('*.dump'))[-1]
            phone.compose(state, 'exec', '-T', 'postgres', 'sh', '-c',
                          'export PGPASSWORD="$POSTGRES_PASSWORD"; exec pg_restore -w -h 127.0.0.1 -U postgres --exit-on-error --no-owner --no-acl -d "$1"',
                          'sh', scratch, data=archive.read_bytes())
            assert phone.sql(state, 'SELECT count(*),sum(value) FROM userdata.b03_smoke;', database=scratch).strip() == '2|33'
        finally:
            phone.sql(state, f'DROP DATABASE {scratch} WITH (FORCE);')
        # A disposable development project can be destroyed without changing the phone volume.
        phone.run([*dev_args, 'up', '-d', '--wait', 'postgres'], env=env)
        phone_volume = json.loads(phone.run(['docker', 'volume', 'inspect', phone.PROJECT + '_phone-data']))[0]['Name']
        dev_volume = json.loads(phone.run(['docker', 'volume', 'inspect', dev_project + '_postgres-data']))[0]['Name']
        assert phone_volume != dev_volume
        phone.run([*dev_args, 'down', '-v'], env=env)
        assert phone.sql(state, 'SELECT count(*),sum(value) FROM userdata.b03_smoke;').strip() == '2|33'
        phone.compose(state, 'stop')
        phone.compose(state, 'up', '-d', '--wait', 'postgres')
        phone.compose(state, 'up', '-d', '--force-recreate', 'migrate', 'api', 'worker')
        assert phone.sql(state, 'SELECT count(*),sum(value) FROM userdata.b03_smoke;').strip() == '2|33'
        # Migrations can repeat and the worker must register its durable schedule.
        for _ in range(30):
            if phone.sql(state, "SELECT count(*) FROM ops.schedules WHERE name='ops.cleanup';").strip() == '1':
                break
            time.sleep(1)
        else:
            raise AssertionError('worker schedule missing')
        # B04: enable the private overlay using synthetic IDs/keys, never Google or paid APIs.
        clients = state / 'synthetic-google.json'
        phone.json_write(clients, {'AndroidClientId': '123-android.apps.googleusercontent.com',
                                   'WebClientId': '123-server.apps.googleusercontent.com'})
        phone.configure_identity(state, clients)
        phone.compose(state, 'up', '-d', '--force-recreate', 'migrate', 'api', 'worker')
        port = phone.compose(state, 'port', 'api', '8080').decode().strip().split(':')[-1]
        base = 'http://127.0.0.1:' + port
        for _ in range(60):
            if phone.ready(base):
                break
            time.sleep(1)
        else:
            raise AssertionError('identity-enabled synthetic image did not become ready')
        def auth_call(path, payload=None, token=None, method='POST'):
            request_headers = {key: value for key, value in headers.items() if key != 'X-Sync-Spike-Key'}
            request_headers['Content-Type'] = 'application/json'
            if token:
                request_headers['Authorization'] = 'Bearer ' + token
            request = urllib.request.Request(base + path, data=json.dumps(payload).encode() if payload is not None else (b'' if method == 'POST' else None), headers=request_headers, method=method)
            with urllib.request.urlopen(request) as response:
                data = response.read()
                return response.status, json.loads(data) if data else None, response.headers
        status, first, response_headers = auth_call('/v1/auth/anonymous')
        assert status == 200 and first['isAnonymous'] and response_headers['Cache-Control'] == 'no-store'
        status, me, _ = auth_call('/v1/me', token=first['accessToken'], method='GET')
        assert status == 200 and me['userId'] == first['userId']
        status, refreshed, _ = auth_call('/v1/auth/refresh', {'refreshToken': first['refreshToken']})
        assert status == 200 and refreshed['refreshToken'] != first['refreshToken']
        try:
            auth_call('/v1/auth/refresh', {'refreshToken': first['refreshToken']})
            raise AssertionError('refresh reuse was accepted')
        except urllib.error.HTTPError as error:
            assert error.code == 401
        try:
            auth_call('/v1/me', token=refreshed['accessToken'], method='GET')
            raise AssertionError('revoked successor remained authenticated')
        except urllib.error.HTTPError as error:
            assert error.code == 401
        status, challenge, _ = auth_call('/v1/auth/email/start', {'email': 'synthetic@example.invalid', 'purpose': 'signIn'})
        assert status == 200
        email_file = state / 'identity' / 'email' / (challenge['challengeId'] + '.json')
        delivered = phone.read_json(email_file)
        status, signed_in, _ = auth_call('/v1/auth/email/verify', {'challengeId': challenge['challengeId'], 'code': delivered['code']})
        assert status == 200 and not signed_in['isAnonymous']
        auth_call('/v1/auth/logout', token=signed_in['accessToken'])
        api = phone.compose(state, 'ps', '-q', 'api').decode().strip()
        assert json.loads(phone.run(['docker', 'inspect', api]))[0]['Config']['User'] == str(os.getuid())
        phone.backup(state)
        phone.restore_check(state)
        recovery = phone.read_json(state / 'backups' / 'identity-recovery.json')
        assert set(recovery['files']) == {'config.json', 'pepper', 'v1.key'}
        print('B04 synthetic Production image: private UID/secret mounts, explicit key provisioning, guest/me/refresh/reuse/email/logout, backup and recovery passed; no live provider calls')
        print('B03 synthetic smoke: immutable Production image, loopback-only hardened API, exact gateway/HSTS, dark routes, read-only complete RLS backup, scratch restore 2 rows/sum 33, dev-volume isolation, restart persistence and worker passed')
    finally:
        # These names are random and hold synthetic data only, never fitness-buddy-phone.
        phone.run([*dev_args, 'down', '-v'], env=env)
        phone.compose(state, 'down', '-v')
PY
