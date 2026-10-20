#!/usr/bin/env python3
"""B03 private laptop stack. Persistent state and credentials never live in git."""
import argparse
from contextlib import contextmanager
import datetime as dt
import fcntl
import hashlib
import ipaddress
import json
import os
from pathlib import Path
import re
import secrets
import select
import stat
import subprocess
import sys
import tarfile
import tempfile
import time
import urllib.error
import urllib.request
import uuid

# The installed timer runs a private copy, whose ancestors are not a checkout.
_CANDIDATE_REPO = Path(__file__).resolve().parents[2]
REPO = _CANDIDATE_REPO if (_CANDIDATE_REPO / '.git').exists() else None
DEFAULT_STATE = Path.home() / '.local/share/fitness-buddy/phone-server'
PROJECT = 'fitness-buddy-phone'
PASSWORD_KEYS = ('ADMIN', 'MIGRATOR', 'APP', 'BACKUP')


class Failure(Exception):
    """An operator-safe message; child output can contain secrets and is never echoed."""


def run(args, *, env=None, data=None, timeout=300):
    try:
        return subprocess.run(args, input=data, env=env, stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE, check=True, timeout=timeout).stdout
    except (subprocess.SubprocessError, OSError) as exc:
        raise Failure(f'{Path(args[0]).name} operation failed; no child output displayed') from exc


def private(path, *, directory=False, public_read=False):
    info = path.lstat()
    kind = stat.S_ISDIR if directory else stat.S_ISREG
    if not kind(info.st_mode) or info.st_uid != os.getuid() or info.st_mode & (0o033 if public_read else 0o077):
        raise Failure('State must be owner-only, owned by this user, and not a symlink')


def atomic(path, content):
    if path.exists() or path.is_symlink():
        private(path, public_read=path.name == 'init-roles.sh')
    fd, temp = tempfile.mkstemp(dir=path.parent, prefix='.pending-')
    try:
        with os.fdopen(fd, 'wb') as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temp, path)
        parent = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY)
        try:
            os.fsync(parent)
        finally:
            os.close(parent)
    finally:
        Path(temp).unlink(missing_ok=True)


def json_write(path, obj):
    atomic(path, (json.dumps(obj, indent=2) + '\n').encode())


def read_json(path):
    private(path)
    return json.loads(path.read_text())


def safe_dir(path):
    # Symlinks through a parent could place backups/state inside the shared checkout.
    if path.absolute() != path.resolve():
        raise Failure('State path must not contain symlinks')
    if ((REPO is not None and path.resolve().is_relative_to(REPO)) or
            any((parent / '.git').exists() for parent in (path, *path.parents))):
        raise Failure('Persistent state must be outside the repository')
    path.mkdir(parents=True, exist_ok=True, mode=0o700)
    private(path, directory=True)


def secrets_env(state):
    credentials = read_json(state / 'credentials.json')
    expected = {f'FB_PHONE_{key}_PASSWORD' for key in PASSWORD_KEYS}
    if set(credentials) != expected or any(not isinstance(v, str) or not re.fullmatch(r'[0-9a-f]{64}', v)
                                            for v in credentials.values()):
        raise Failure('Invalid persistent credentials; never regenerate against an existing volume')
    # Do not inherit DOTNET/Compose/.env overrides or telemetry credentials.
    env = {key: os.environ[key] for key in ('PATH', 'HOME', 'DOCKER_HOST', 'DOCKER_CONTEXT',
                                           'XDG_RUNTIME_DIR', 'DOCKER_CONFIG') if key in os.environ}
    env.update(credentials)
    env.update(FB_PHONE_IMAGE='sha256:' + '0' * 64, FB_PHONE_PROXY_CIDR='127.0.0.1/32')
    image = state / 'image.json'
    if image.exists():
        config = read_json(image)
        if not re.fullmatch(r'sha256:[0-9a-f]{64}', config['image']):
            raise Failure('Invalid immutable image ID')
        env['FB_PHONE_IMAGE'] = config['image']
    gateway = state / 'gateway.json'
    if gateway.exists():
        value = str(ipaddress.IPv4Address(read_json(gateway)['gateway']))
        env['FB_PHONE_PROXY_CIDR'] = value + '/32'
    return env


def compose_command(state, *args):
    private(state / 'compose.yml')
    private(state / 'init-roles.sh', public_read=True)
    return ['docker', 'compose', '--env-file', '/dev/null', '-p', PROJECT,
            '-f', str(state / 'compose.yml'), *identity_compose_args(state), *recovery_compose_args(state), *args]


def compose(state, *args, data=None, timeout=300):
    return run(compose_command(state, *args), env=secrets_env(state), data=data, timeout=timeout)


def identity_compose_args(state):
    overlay = state / 'identity-compose.json'
    if not overlay.exists():
        return []
    private(overlay)
    safe_dir(state / 'identity')
    safe_dir(state / 'identity' / 'email')
    config = read_json(state / 'identity' / 'config.json')
    if config.get('Identity', {}).get('PrivateLaptop') is not True:
        raise Failure('Identity overlay is restricted to the private laptop')
    for secret in (state / 'identity').glob('*.key'):
        private(secret)
        if len(secret.read_bytes()) != 32:
            raise Failure('Invalid identity key; recover original private material')
    for name in ('v1.key', 'pepper'):
        private(state / 'identity' / name)
        if len((state / 'identity' / name).read_bytes()) != 32:
            raise Failure('Invalid identity secret; recover original private material')
    return ['-f', str(overlay)]


def recovery_compose_args(state):
    overlay = state / 'recovery-compose.json'
    if not overlay.exists():
        return []
    private(overlay)
    safe_dir(state / 'recovery')
    return ['-f', str(overlay)]


def configure_recovery(state):
    if os.getuid() == 0:
        raise Failure('Recovery runtime requires an unprivileged operator UID')
    folder = state / 'recovery'
    safe_dir(folder)
    # Do not create/recover a generation here: only the guarded migrate command can initialize it.
    runtime = {'user': str(os.getuid()), 'environment': {'Recovery__Directory': '/recovery'},
               'volumes': [{'type': 'bind', 'source': str(folder), 'target': '/recovery'}]}
    command = ['migrate']
    if (state / 'identity-compose.json').exists():
        command = read_json(state / 'identity-compose.json')['services']['migrate']['command']
    command = [arg for arg in command if not arg.startswith('--Recovery:Initialize=')] + ['--Recovery:Initialize=true']
    worker = {**runtime, 'volumes': [{**runtime['volumes'][0], 'read_only': True}]}
    json_write(state / 'recovery-compose.json', {'services': {
        'api': runtime, 'worker': worker, 'migrate': {**runtime, 'command': command}}})


def protected_generation(state):
    folder = state / 'recovery'
    private(folder, directory=True)
    marker = folder / 'generation'
    private(marker)
    if stat.S_IMODE(folder.stat().st_mode) != 0o700 or stat.S_IMODE(marker.stat().st_mode) != 0o600:
        raise Failure('Protected recovery state must be private and writable by its owner')
    raw = marker.read_text()
    if len(raw) != 37 or raw[-1] != '\n':
        raise Failure('Invalid protected recovery state; offline recovery required')
    try:
        generation = str(uuid.UUID(raw[:-1]))
    except ValueError as exc:
        raise Failure('Invalid protected recovery state; offline recovery required') from exc
    if generation != raw[:-1] or generation == str(uuid.UUID(int=0)):
        raise Failure('Invalid protected recovery state; offline recovery required')
    return generation


@contextmanager
def recovery_lock(state):
    # One DB transaction excludes deletion across the complete dump/restore operation. The existing
    # controller flock also serializes local operator commands. No per-user deletion ledger exists.
    command = ('export PGPASSWORD="$FB_PHONE_BACKUP_PASSWORD" PGCONNECT_TIMEOUT=5; '
               'exec psql -X -q -w -h 127.0.0.1 -U fb_backup -d fitness_buddy -v ON_ERROR_STOP=1 -At')
    process = None
    try:
        process = subprocess.Popen(compose_command(state, 'exec', '-T', 'postgres', 'sh', '-c', command),
                                   env=secrets_env(state), stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE, bufsize=0)
        process.stdin.write(b"BEGIN; SET LOCAL lock_timeout='20s'; SELECT pg_advisory_xact_lock(460391206); SELECT 'fb_recovery_locked';\n")
        process.stdin.flush()
        deadline = time.monotonic() + 30
        output = b''
        while b'fb_recovery_locked\n' not in output:
            remaining = deadline - time.monotonic()
            if remaining <= 0 or process.poll() is not None:
                raise Failure('Recovery lock unavailable; no backup or restore was authorized')
            readable, _, _ = select.select([process.stdout], [], [], min(1, remaining))
            if readable:
                chunk = os.read(process.stdout.fileno(), 1024)
                if not chunk or len(output) + len(chunk) > 4096:
                    raise Failure('Recovery lock unavailable; no child output displayed')
                output += chunk
        generation = protected_generation(state)
        if sql(state, 'SELECT generation::text FROM ops.recovery WHERE singleton;', role='fb_backup').strip() != generation:
            raise Failure('Protected recovery state does not match database; offline recovery required')
        yield generation
        if process.poll() is not None or protected_generation(state) != generation or sql(state, 'SELECT generation::text FROM ops.recovery WHERE singleton;', role='fb_backup').strip() != generation:
            raise Failure('Recovery lock or generation changed; operation was not completed')
        process.stdin.write(b'COMMIT;\n\\q\n')
        process.stdin.flush()
        process.stdin.close()
        if process.wait(timeout=10) != 0:
            raise Failure('Recovery lock release failed; no child output displayed')
    except (OSError, subprocess.SubprocessError) as exc:
        raise Failure('Recovery operation failed; no child output displayed') from exc
    finally:
        if process is not None:
            if process.poll() is None:
                try:
                    if not process.stdin.closed:
                        process.stdin.write(b'ROLLBACK;\n\\q\n')
                        process.stdin.flush()
                        process.stdin.close()
                    process.wait(timeout=5)
                except (OSError, subprocess.TimeoutExpired):
                    process.terminate()
                    try:
                        process.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait(timeout=5)
            for stream in (process.stdin, process.stdout, process.stderr):
                if stream is not None:
                    stream.close()


def backup_manifest(archive):
    return archive.with_suffix('.json')


def verify_backup(archive, generation):
    private(archive)
    if not re.fullmatch(r'backup-[0-9]{8}T[0-9]{6}-[0-9a-f]{6}\.dump', archive.name):
        raise Failure('Invalid backup name')
    try:
        manifest = read_json(backup_manifest(archive))
    except (OSError, ValueError, KeyError) as exc:
        raise Failure('Backup has no valid deletion-safe manifest; direct restore refused') from exc
    if (set(manifest) != {'format', 'dump', 'sha256', 'generation'} or manifest.get('format') != 1 or
            manifest.get('dump') != archive.name or manifest.get('generation') != generation):
        raise Failure('Backup predates current deletion state or has no valid manifest; direct restore refused')
    with archive.open('rb') as stream:
        digest = hashlib.file_digest(stream, 'sha256').hexdigest()
    if manifest.get('sha256') != digest:
        raise Failure('Backup digest mismatch; restore refused')


def configure_identity(state, clients_path):
    init(state)
    if os.getuid() == 0:
        raise Failure('Identity runtime must use an unprivileged operator UID')
    clients = read_json(clients_path.absolute())
    if set(clients) != {'AndroidClientId', 'WebClientId'} or any(
            not isinstance(v, str) or not re.fullmatch(r'[0-9]+-[a-z0-9]+\.apps\.googleusercontent\.com', v)
            for v in clients.values()):
        raise Failure('Expected Android and web OAuth client IDs only')
    folder = state / 'identity'
    safe_dir(folder)
    safe_dir(folder / 'email')
    configured = (folder / 'config.json').exists()
    for name in ('v1.key', 'pepper'):
        secret = folder / name
        if secret.exists() or secret.is_symlink():
            private(secret)
            if len(secret.read_bytes()) != 32:
                raise Failure('Invalid identity secret; recover original private material')
        elif configured:
            raise Failure('Missing identity secret; recover it, never regenerate against existing identities')
        else:
            atomic(secret, secrets.token_bytes(32))
    # Android registration is for the app; native ID tokens must target our web/server client ID.
    json_write(folder / 'config.json', {'Identity': {
        'Enabled': True, 'PrivateLaptop': True, 'Issuer': 'fitness-buddy', 'Audience': 'fitness-buddy-api',
        'WrappingKeysDirectory': '/identity', 'PepperFile': '/identity/pepper',
        'GoogleClientIds': [clients['WebClientId']],
        'Email': {'LocalFile': {'Enabled': True, 'Directory': '/identity/email'}}}})
    runtime = {'user': str(os.getuid()), 'environment': {'FB_IDENTITY_CONFIG_FILE': '/identity/config.json'},
               'volumes': [{'type': 'bind', 'source': str(folder), 'target': '/identity', 'read_only': True},
                           {'type': 'bind', 'source': str(folder / 'email'), 'target': '/identity/email'}]}
    migrate = {**runtime, 'command': ['migrate', '--Identity:KeyOperation=ensure', '--Identity:WrappingVersion=v1']}
    json_write(state / 'identity-compose.json', {'services': {'api': runtime, 'worker': runtime, 'migrate': migrate}})
    identity_compose_args(state)
    if (state / 'recovery-compose.json').exists():
        configure_recovery(state)
    print('Private identity configuration prepared; takes effect on next main-image deployment')


def identity_recovery(state):
    if not (state / 'identity-compose.json').exists():
        return
    identity_compose_args(state)
    import base64
    folder = state / 'identity'
    names = ['config.json', 'pepper', *sorted(path.name for path in folder.glob('*.key'))]
    files = {}
    for name in names:
        private(folder / name)
        files[name] = base64.b64encode((folder / name).read_bytes()).decode('ascii')
    json_write(state / 'backups' / 'identity-recovery.json', {'format': 1, 'files': files})


def init(state):
    safe_dir(state)
    path = state / 'credentials.json'
    if path.exists():
        secrets_env(state)
    else:
        # Existing data must never silently acquire unrelated credentials.
        volumes = run(['docker', 'volume', 'ls', '--filter', f'label=com.docker.compose.project={PROJECT}', '-q'])
        if volumes.strip():
            raise Failure('Existing phone volume but no credentials; recover the original credentials')
        json_write(path, {f'FB_PHONE_{key}_PASSWORD': secrets.token_hex(32) for key in PASSWORD_KEYS})
    safe_dir(state / 'backups')


def prepare(state):
    if REPO is None:
        raise Failure('Prepare must run from the repository checkout, not the installed runtime snapshot')
    init(state)
    if (state / 'serving.json').exists():
        raise Failure('Stop the phone server before preparing an upgrade')
    if (state / 'compose.yml').exists() and compose(state, 'ps', '--status', 'running', '-q').strip():
        raise Failure('Stop the phone stack before preparing an upgrade')
    run(['git', '-C', str(REPO), 'fetch', 'origin', 'main'])
    revision = run(['git', '-C', str(REPO), 'rev-parse', 'origin/main']).decode().strip()
    # git archive excludes all uncommitted work and files outside backend, even on a step branch.
    archive = run(['git', '-C', str(REPO), 'archive', revision, 'backend'])
    with tempfile.TemporaryDirectory(prefix='fb-phone-build-') as temp:
        path = Path(temp)
        (path / 'backend.tar').write_bytes(archive)
        with tarfile.open(path / 'backend.tar') as source:
            source.extractall(path, filter='data')
        run(['docker', 'build', '--label', f'org.opencontainers.image.revision={revision}',
             '--iidfile', str(path / 'image-id'), str(path / 'backend')], timeout=1200)
        image = (path / 'image-id').read_text().strip()
    for name in ('compose.yml', 'init-roles.sh'):
        atomic(state / name, (REPO / 'infra/phone-server' / name).read_bytes())
        if name == 'init-roles.sh':
            (state / name).chmod(0o644)
    configure_recovery(state)
    atomic(state / 'phone-server.py', Path(__file__).read_bytes())
    json_write(state / 'image.json', {'revision': revision, 'image': image})
    print(f'Prepared immutable backend from main {revision[:12]}; private state outside git')


def tailnet():
    status = json.loads(run(['tailscale', 'status', '--json']))
    if status.get('BackendState') != 'Running':
        raise Failure('Tailscale must be connected')
    return status


def policy(state):
    init(state)
    status = tailnet()
    phones = [peer for peer in status.get('Peer', {}).values() if peer.get('OS') == 'android']
    if len(phones) != 1:
        raise Failure('Expected exactly one Android peer; select the A55 manually before continuing')
    laptop, phone = status['Self'], phones[0]
    laptop_ips = [str(ipaddress.ip_address(ip)) for ip in laptop['TailscaleIPs']]
    phone_ips = [str(ipaddress.ip_address(ip)) for ip in phone['TailscaleIPs']]
    target = lambda ip, port: f'[{ip}]:{port}' if ':' in ip else f'{ip}:{port}'
    denied_ip = next(f'100.64.0.{n}' for n in range(1, 255) if f'100.64.0.{n}' not in laptop_ips + phone_ips)
    denied_v6 = next(f'fd7a:115c:a1e0::{n:x}' for n in range(1, 255)
                     if f'fd7a:115c:a1e0::{n:x}' not in laptop_ips + phone_ips)
    same_family = lambda src, dst: ipaddress.ip_address(src).version == ipaddress.ip_address(dst).version
    config = {
        'acls': [],
        'grants': [{'src': phone_ips, 'dst': laptop_ips, 'ip': ['tcp:443']}],
        'tests': [
            *({'src': ip, 'accept': [target(dst, 443) for dst in laptop_ips if same_family(ip, dst)],
               'deny': [target(dst, port) for dst in laptop_ips if same_family(ip, dst) for port in (22, 5199)]} for ip in phone_ips),
            *({'src': ip, 'deny': [target(dst, 443) for dst in laptop_ips if same_family(ip, dst)]}
              for ip in (denied_ip, denied_v6) if any(same_family(ip, dst) for dst in laptop_ips)),
        ],
    }
    json_write(state / 'tailnet-policy.json', config)
    json_write(state / 'devices.json', {'laptop': laptop['ID'], 'phone': phone['ID'],
                                       'laptopIps': laptop_ips, 'phoneIps': phone_ips,
                                       'dns': laptop['DNSName'].rstrip('.')})
    print(f'Private policy: {state / "tailnet-policy.json"}')
    print('Apply it in Tailscale Access controls (replaces allow-all on this dedicated two-device tailnet).')
    print('Enable HTTPS certificates in Tailscale DNS, then run confirm-policy yourself after verifying the tests.')


def policy_digest(state):
    private(state / 'tailnet-policy.json')
    private(state / 'devices.json')
    return hashlib.sha256((state / 'tailnet-policy.json').read_bytes() +
                          (state / 'devices.json').read_bytes()).hexdigest()


def confirm_policy(state):
    # Deliberate operator attestation, not a claim that the LocalAPI can inspect the admin policy.
    digest = policy_digest(state)
    json_write(state / 'policy-confirmed.json', {'sha256': digest})
    print('Recorded operator confirmation of the exact policy/device files; activation still checks storage/HTTPS')


def encrypted_path(path):
    source = run(['findmnt', '-n', '-o', 'SOURCE', '--target', str(path)]).decode().strip()
    devices = json.loads(run(['lsblk', '--json', '--inverse', '--output', 'TYPE,NAME', source]))
    def crypt(nodes):
        return any(node['type'] == 'crypt' or crypt(node.get('children', [])) for node in nodes)
    return crypt(devices['blockdevices'])



def storage_digest(state, docker_root):
    # Bind the explicit laptop exception to this machine, device policy and storage locations.
    paths = [Path(docker_root), state, state / 'backups']
    context = {'project': PROJECT, 'machine': hashlib.sha256(Path('/etc/machine-id').read_bytes()).hexdigest(),
               'policy': policy_digest(state), 'paths': [str(path.resolve()) for path in paths],
               'sources': [run(['findmnt', '-n', '-o', 'SOURCE', '--target', str(path)]).decode().strip()
                           for path in paths]}
    return hashlib.sha256(json.dumps(context, sort_keys=True).encode()).hexdigest()


def accept_unencrypted_storage(state):
    # Only after explicit owner approval (PROCESS.md A6); never a production option.
    docker_root = json.loads(run(['docker', 'info', '--format', '{{json .DockerRootDir}}']))
    json_write(state / 'storage-approved.json', {'scope': PROJECT, 'sha256': storage_digest(state, docker_root),
                                               'acceptedAt': dt.datetime.now(dt.timezone.utc).isoformat()})
    print('Recorded owner-approved unencrypted storage for this private laptop only; no production change')


def owned_mapping(config, dns):
    return (config.get('Web') == {dns + ':443': {'Handlers': {'/': {'Proxy': 'http://127.0.0.1:5199'}}}} and
            config.get('TCP') == {'443': {'HTTPS': True}} and
            not any((config.get('AllowFunnel') or {}).values()))


def activation_checks(state):
    if read_json(state / 'policy-confirmed.json').get('sha256') != policy_digest(state):
        raise Failure('Policy/device files changed; apply and confirm the exact policy again')
    selected = read_json(state / 'devices.json')
    status = tailnet()
    phone = next((p for p in status.get('Peer', {}).values() if p['ID'] == selected['phone']), None)
    if (status['Self']['ID'] != selected['laptop'] or phone is None or
            set(selected['laptopIps']) != set(status['Self']['TailscaleIPs']) or
            set(selected['phoneIps']) != set(phone['TailscaleIPs']) or
            selected['dns'] != status['Self']['DNSName'].rstrip('.')):
        raise Failure('Selected devices changed; regenerate and reapply the policy')
    if selected['dns'] not in (status.get('CertDomains') or []):
        raise Failure('Enable HTTPS certificates in Tailscale DNS first')
    docker_root = json.loads(run(['docker', 'info', '--format', '{{json .DockerRootDir}}']))
    protected = [encrypted_path(path) for path in (Path(docker_root), state, state / 'backups')]
    if not all(protected):
        receipt = state / 'storage-approved.json'
        if not receipt.exists():
            raise Failure('Database/state/backups need encrypted storage or explicit owner approval for this private laptop')
        approval = read_json(receipt)
        if approval.get('scope') != PROJECT or approval.get('sha256') != storage_digest(state, docker_root):
            raise Failure('Storage or device configuration changed; owner storage approval must be renewed')
    serving = json.loads(run(['tailscale', 'serve', 'status', '--json']))
    if serving:
        receipt = state / 'serving.json'
        if not (receipt.exists() and read_json(receipt).get('dns') == selected['dns'] and owned_mapping(serving, selected['dns'])):
            raise Failure('Existing Tailscale Serve configuration; inspect it before starting this stack')
    return selected['dns']


def ready(url, *, forwarded=False):
    headers = {}
    if forwarded:
        headers = {'X-Forwarded-Proto': 'https', 'X-Forwarded-For': '100.64.0.1'}
    try:
        with urllib.request.urlopen(urllib.request.Request(url + '/health/ready', headers=headers), timeout=3) as response:
            return response.status == 200
    except (OSError, urllib.error.URLError):
        return False


def up(state):
    read_json(state / 'image.json')
    dns = activation_checks(state)
    if (state / 'serving.json').exists():
        serving = json.loads(run(['tailscale', 'serve', 'status', '--json']))
        if serving:
            run(['tailscale', 'serve', '--https=443', 'off'])
        (state / 'serving.json').unlink()
    # Create only Postgres/network first, so the exact host proxy hop can be discovered.
    compose(state, 'up', '-d', '--wait', 'postgres')
    networks = json.loads(run(['docker', 'network', 'inspect', PROJECT + '_default']))
    gateway = networks[0]['IPAM']['Config'][0]['Gateway']
    json_write(state / 'gateway.json', {'gateway': str(ipaddress.IPv4Address(gateway))})
    compose(state, 'up', '-d', '--force-recreate', 'migrate', 'api', 'worker')
    for _ in range(60):
        if ready('http://127.0.0.1:5199'):
            break
        time.sleep(1)
    else:
        raise Failure('API readiness timed out; Serve was not enabled')
    # Never invoke Funnel. This command uses only the already-confirmed tailnet policy.
    run(['tailscale', 'serve', '--bg', '--yes', '--https=443', 'http://127.0.0.1:5199'], timeout=30)
    json_write(state / 'serving.json', {'dns': dns})
    print('Started phone server; run status to check HTTPS (URL stays outside git)')


def stop(state):
    owned = state / 'serving.json'
    if owned.exists():
        dns = read_json(owned)['dns']
        serving = json.loads(run(['tailscale', 'serve', 'status', '--json']))
        if serving and not owned_mapping(serving, dns):
            raise Failure('Serve mapping changed; refusing to modify an unrelated mapping')
        if serving:
            run(['tailscale', 'serve', '--https=443', 'off'])
        owned.unlink()
    compose(state, 'stop')
    print('Stopped phone stack; persistent volume and backups preserved')


def sql(state, statement, database='fitness_buddy', role='postgres'):
    if not re.fullmatch(r'(fitness_buddy|fb_restore_[0-9a-f]{16})', database):
        raise Failure('Unsafe database name')
    if role not in ('postgres', 'fb_backup'):
        raise Failure('Invalid database role')
    # exec environment exists inside the Postgres container already; do not send a secret as a command argument.
    command = 'export PGPASSWORD="$POSTGRES_PASSWORD"; exec psql -X -w -h 127.0.0.1 -U postgres -d "$1" -v ON_ERROR_STOP=1 -At'
    if role == 'fb_backup':
        command = command.replace('$POSTGRES_PASSWORD', '$FB_PHONE_BACKUP_PASSWORD').replace('-U postgres', '-U fb_backup')
    return compose(state, 'exec', '-T', 'postgres', 'sh', '-c', command, 'sh', database, data=statement.encode()).decode()


def backup(state):
    folder = state / 'backups'
    private(folder, directory=True)
    name = 'backup-' + dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%S') + '-' + secrets.token_hex(3) + '.dump'
    with recovery_lock(state) as generation:
        # pg_dump's stderr may contain a private row; never echo it, including on failure.
        archive = compose(state, 'exec', '-T', 'postgres', 'sh', '-c',
                          'export PGPASSWORD="$FB_PHONE_BACKUP_PASSWORD"; exec pg_dump -w -h 127.0.0.1 -U fb_backup -d fitness_buddy -Fc', timeout=900)
        if not archive.startswith(b'PGDMP'):
            raise Failure('Invalid dump output; old backups retained')
        identity_recovery(state)
        atomic(folder / name, archive)
        json_write(backup_manifest(folder / name), {'format': 1, 'dump': name,
                   'sha256': hashlib.sha256(archive).hexdigest(), 'generation': generation})
    cutoff = time.time() - 7 * 86400
    for path in folder.iterdir():
        if re.fullmatch(r'backup-[0-9]{8}T[0-9]{6}-[0-9a-f]{6}\.dump', path.name):
            private(path)
            if path.stat().st_mtime < cutoff:
                manifest = backup_manifest(path)
                if manifest.exists() or manifest.is_symlink():
                    private(manifest)
                    manifest.unlink()
                path.unlink()
    print('Backup complete with protected generation/digest; seven-day local retention')
    return folder / name


def restore_check(state):
    folder = state / 'backups'
    private(folder, directory=True)
    dumps = sorted(folder.glob('backup-*.dump'))
    if not dumps:
        raise Failure('No backup; create one first')
    archive = max(dumps, key=lambda path: (path.stat().st_mtime_ns, path.name))
    with recovery_lock(state) as generation:
        # Validate BEFORE even a scratch database is created. There is no automatic live restore/reset.
        verify_backup(archive, generation)
        scratch = 'fb_restore_' + secrets.token_hex(8)
        sql(state, f'CREATE DATABASE {scratch} OWNER fb_migrator;')
        try:
            compose(state, 'exec', '-T', 'postgres', 'sh', '-c',
                    'export PGPASSWORD="$POSTGRES_PASSWORD"; exec pg_restore -w -h 127.0.0.1 -U postgres --role=fb_migrator --exit-on-error --no-owner -d "$1"',
                    'sh', scratch, data=archive.read_bytes(), timeout=900)
            count = sql(state, "SELECT count(*) FROM pg_tables WHERE schemaname IN ('ops','userdata','identity','account');", database=scratch).strip()
            if not count.isdecimal() or int(count) < 1:
                raise Failure('Restore has no expected module tables')
            restored = sql(state, 'SELECT generation::text FROM ops.recovery WHERE singleton;', database=scratch).strip()
            if restored != generation:
                raise Failure('Restored recovery state does not match protected generation')
            before = sql(state, 'SELECT id::text FROM userdata.dataset WHERE singleton;', database=scratch).strip()
            sql(state, 'UPDATE userdata.dataset SET id=gen_random_uuid() WHERE singleton;', database=scratch)
            after = sql(state, 'SELECT id::text FROM userdata.dataset WHERE singleton;', database=scratch).strip()
            if not before or before == after:
                raise Failure('Scratch restore dataset rotation failed')
        finally:
            sql(state, f'DROP DATABASE {scratch} WITH (FORCE);')
    print(f'Restore succeeded into isolated scratch database; {count} module tables; recovery matched and dataset rotated')


def install_timer(state):
    private(state / 'phone-server.py')
    units = Path.home() / '.config/systemd/user'
    units.mkdir(parents=True, exist_ok=True)
    # systemd escaping is not shell quoting. Reject unsafe paths rather than interpolate them.
    if not re.fullmatch(r'[/A-Za-z0-9_.-]+', str(state)):
        raise Failure('Timer path must contain only simple filesystem characters')
    service = f'''[Unit]
Description=Fitness Buddy laptop private database backup
[Service]
Type=oneshot
UMask=0077
ExecStart=/usr/bin/python3 {state}/phone-server.py --state {state} backup
'''
    timer = '''[Unit]
Description=Nightly Fitness Buddy laptop backup
[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true
[Install]
WantedBy=timers.target
'''
    # Never replace an unrelated user unit with the same name.
    for name, content in [('fitness-buddy-phone-backup.service', service), ('fitness-buddy-phone-backup.timer', timer)]:
        path = units / name
        if path.exists() and 'Fitness Buddy laptop' not in path.read_text():
            raise Failure('Unrelated existing systemd unit; inspect before replacing')
        atomic(path, content.encode())
    run(['systemctl', '--user', 'daemon-reload'])
    run(['systemctl', '--user', 'enable', '--now', 'fitness-buddy-phone-backup.timer'])
    print('Nightly user timer enabled; runs while logged in, catches up after missed ticks')


def status(state):
    image = read_json(state / 'image.json')
    print('Main revision: ' + image['revision'])
    print('Loopback ready: ' + str(ready('http://127.0.0.1:5199')))
    if (state / 'serving.json').exists():
        dns = read_json(state / 'serving.json')['dns']
        print('Private HTTPS: https://' + dns)
        print('HTTPS from laptop (A55-only policy may deny): ' + str(ready('https://' + dns)))
    backups = list((state / 'backups').glob('backup-*.dump'))
    print('Backup count: ' + str(len(backups)))
    if backups:
        age = (time.time() - max(p.stat().st_mtime for p in backups)) / 3600
        print(f'Newest backup age: {age:.1f} hours' + (' — OVERDUE' if age > 26 else ''))
        try:
            verify_backup(max(backups, key=lambda path: path.stat().st_mtime), protected_generation(state))
            safe = True
        except (Failure, OSError, ValueError, KeyError):
            safe = False
        print('Newest backup matches protected generation/digest: ' + str(safe))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--state', type=Path, default=DEFAULT_STATE)
    parser.add_argument('--google-clients', type=Path, default=Path.home() / '.local/share/fitness-buddy/identity/google-clients.json')
    parser.add_argument('command', choices=['configure-identity', 'prepare', 'policy', 'confirm-policy', 'accept-unencrypted-storage', 'up', 'stop', 'backup', 'restore-check', 'install-timer', 'status'])
    args = parser.parse_args()
    os.umask(0o077)
    state = args.state.absolute()
    try:
        safe_dir(state)
        lock = state / '.lock'
        if lock.exists() or lock.is_symlink():
            private(lock)
        with lock.open('a') as handle:
            fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
            {'configure-identity': lambda target: configure_identity(target, args.google_clients), 'prepare': prepare, 'policy': policy, 'confirm-policy': confirm_policy, 'up': up,
             'accept-unencrypted-storage': accept_unencrypted_storage,
             'stop': stop, 'backup': backup, 'restore-check': restore_check,
             'install-timer': install_timer, 'status': status}[args.command](state)
    except (Failure, OSError, ValueError, KeyError, StopIteration) as exc:
        message = str(exc) if isinstance(exc, Failure) else 'operation failed; inspect private setup and prerequisites'
        print('phone-server: ' + message, file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
