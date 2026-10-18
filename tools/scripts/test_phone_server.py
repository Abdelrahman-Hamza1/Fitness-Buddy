"""Rules 08.2-laptop-test-server / 08.5-backups / 09.4-privacy: operator failure boundaries."""
import importlib.util
import ipaddress
import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import time
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location('phone_server', Path(__file__).with_name('phone-server.py'))
phone = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(phone)
REAL_RUN = phone.run


class PhoneServerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='phone-safety-')
        self.state = Path(self.temp.name)
        self.state.chmod(0o700)
        self.run = patch.object(phone, 'run', return_value=b'').start()
        self.addCleanup(patch.stopall)
        self.addCleanup(self.temp.cleanup)
        phone.init(self.state)

    def write(self, name, value):
        phone.json_write(self.state / name, value)

    def selected(self):
        self.write('tailnet-policy.json', {'acls': [], 'grants': []})
        self.write('devices.json', {'laptop': 'laptop', 'phone': 'phone', 'laptopIps': ['100.64.0.2'],
                                    'phoneIps': ['100.64.0.3'], 'dns': 'test.example.ts.net'})
        phone.confirm_policy(self.state)
        return {'Self': {'ID': 'laptop', 'TailscaleIPs': ['100.64.0.2'], 'DNSName': 'test.example.ts.net.'},
                'Peer': {'p': {'ID': 'phone', 'TailscaleIPs': ['100.64.0.3']}},
                'CertDomains': ['test.example.ts.net']}

    def test_credentials_survive_repeated_init_and_have_distinct_roles(self):
        first = (self.state / 'credentials.json').read_bytes()
        phone.init(self.state)
        self.assertEqual(first, (self.state / 'credentials.json').read_bytes())
        values = json.loads(first)
        self.assertEqual(len(set(values.values())), 4)
        self.assertEqual(stat.S_IMODE((self.state / 'credentials.json').stat().st_mode), 0o600)

    def test_existing_data_without_credentials_refuses_regeneration(self):
        (self.state / 'credentials.json').unlink()
        self.run.return_value = b'phone-data\n'
        with self.assertRaisesRegex(phone.Failure, 'recover the original'):
            phone.init(self.state)
        self.assertFalse((self.state / 'credentials.json').exists())

    def test_symlink_and_group_readable_state_are_rejected(self):
        path = self.state / 'alias'
        path.symlink_to(self.state / 'credentials.json')
        with self.assertRaises(phone.Failure):
            phone.private(path)
        (self.state / 'credentials.json').chmod(0o640)
        with self.assertRaises(phone.Failure):
            phone.secrets_env(self.state)

    def test_state_inside_repo_is_rejected_before_creation(self):
        with self.assertRaisesRegex(phone.Failure, 'outside the repository'):
            phone.safe_dir(phone.REPO / 'never-created-phone-state')

    def test_child_errors_never_echo_body_password_or_command(self):
        with patch.object(phone.subprocess, 'run', side_effect=subprocess.CalledProcessError(
                1, ['docker', 'secret-token'], stderr=b'private-food private-password')):
            with self.assertRaises(phone.Failure) as caught:
                REAL_RUN(['docker', 'secret-token'])
        self.assertEqual(str(caught.exception), 'docker operation failed; no child output displayed')

    def test_compose_environment_drops_host_overrides_and_telemetry(self):
        with patch.dict(os.environ, {'COMPOSE_PROJECT_NAME': 'fitness-buddy', 'Sentry__Dsn': 'private',
                                     'FB_PHONE_APP_PASSWORD': 'bad', 'OTEL_EXPORTER_OTLP_ENDPOINT': 'https://private'}):
            env = phone.secrets_env(self.state)
        for key in ('COMPOSE_PROJECT_NAME', 'Sentry__Dsn', 'OTEL_EXPORTER_OTLP_ENDPOINT'):
            self.assertNotIn(key, env)
        self.assertNotEqual(env['FB_PHONE_APP_PASSWORD'], 'bad')

    def test_immutable_image_id_is_required(self):
        self.write('image.json', {'image': 'fitness-buddy-api:local'})
        with self.assertRaisesRegex(phone.Failure, 'immutable'):
            phone.secrets_env(self.state)

    def test_changed_policy_requires_new_confirmation_before_any_start(self):
        self.selected()
        self.write('tailnet-policy.json', {'changed': True})
        with self.assertRaisesRegex(phone.Failure, 'changed'):
            phone.activation_checks(self.state)

    def test_device_replacement_invalidates_confirmation(self):
        current = self.selected()
        current['Peer']['p']['ID'] = 'replacement'
        with patch.object(phone, 'tailnet', return_value=current):
            with self.assertRaisesRegex(phone.Failure, 'devices changed'):
                phone.activation_checks(self.state)

    def test_no_https_or_unencrypted_storage_cannot_enable_serve(self):
        current = self.selected()
        with patch.object(phone, 'tailnet', return_value=current), patch.object(phone, 'encrypted_path', return_value=False):
            self.run.return_value = b'"/var/lib/docker"'
            with self.assertRaisesRegex(phone.Failure, 'encrypted storage'):
                phone.activation_checks(self.state)
        current['CertDomains'] = []
        with patch.object(phone, 'tailnet', return_value=current):
            with self.assertRaisesRegex(phone.Failure, 'HTTPS certificates'):
                phone.activation_checks(self.state)
        self.assertFalse(any('serve' in call.args[0] for call in self.run.call_args_list))

    def test_all_three_storage_paths_checked_and_unrelated_serve_not_overwritten(self):
        current = self.selected()
        self.run.side_effect = [b'"/var/lib/docker"', b'{"Web":{"unrelated:443":{}}}']
        with patch.object(phone, 'tailnet', return_value=current), patch.object(phone, 'encrypted_path', return_value=True) as encrypted:
            with self.assertRaisesRegex(phone.Failure, 'Existing Tailscale Serve'):
                phone.activation_checks(self.state)
        self.assertEqual([call.args[0] for call in encrypted.call_args_list],
                         [Path('/var/lib/docker'), self.state, self.state / 'backups'])

    def test_backup_failure_keeps_existing_archive_and_never_writes_partial(self):
        old = self.state / 'backups/backup-20000101T000000-aabbcc.dump'
        old.write_bytes(b'PGDMP-old')
        old.chmod(0o600)
        os.utime(old, (0, 0))
        with patch.object(phone, 'compose', side_effect=phone.Failure('safe failure')):
            with self.assertRaises(phone.Failure):
                phone.backup(self.state)
        self.assertEqual(list(old.parent.iterdir()), [old])

    def test_successful_dump_uses_backup_role_and_prunes_only_owned_archives(self):
        old = self.state / 'backups/backup-20000101T000000-aabbcc.dump'
        old.write_bytes(b'PGDMP-old')
        old.chmod(0o600)
        os.utime(old, (0, 0))
        unrelated = old.parent / 'keep.dump'
        unrelated.write_bytes(b'keep')
        with patch.object(phone, 'compose', return_value=b'PGDMP-new') as compose:
            result = phone.backup(self.state)
        self.assertFalse(old.exists())
        self.assertTrue(unrelated.exists())
        self.assertEqual(result.read_bytes(), b'PGDMP-new')
        self.assertIn('fb_backup', str(compose.call_args))
        self.assertNotIn('POSTGRES_PASSWORD', str(compose.call_args))

    def test_failed_restore_drops_only_its_scratch_database(self):
        archive = self.state / 'backups/backup-20000101T000000-aabbcc.dump'
        archive.write_bytes(b'PGDMP-fixture')
        archive.chmod(0o600)
        with patch.object(phone, 'sql') as sql, patch.object(phone, 'compose', side_effect=phone.Failure('restore failed')):
            with self.assertRaises(phone.Failure):
                phone.restore_check(self.state)
        create = sql.call_args_list[0].args[1]
        drop = sql.call_args_list[1].args[1]
        self.assertRegex(create, r'^CREATE DATABASE fb_restore_[0-9a-f]{16};$')
        self.assertEqual(drop, create.replace('CREATE', 'DROP').replace(';', ' WITH (FORCE);'))
        self.assertNotIn('fitness_buddy', drop)

    def test_stop_refuses_unrelated_mapping_and_does_not_delete_data(self):
        self.write('serving.json', {'dns': 'test.example.ts.net'})
        self.run.return_value = b'{"Web":{"other:443":{}}}'
        with patch.object(phone, 'compose') as compose:
            with self.assertRaisesRegex(phone.Failure, 'unrelated mapping'):
                phone.stop(self.state)
        compose.assert_not_called()
        self.assertFalse(any('reset' in call.args[0] or 'down' in call.args[0] for call in self.run.call_args_list))

    def test_owned_serve_mapping_cannot_hide_funnel_or_extra_routes(self):
        config = {'TCP': {'443': {'HTTPS': True}},
                  'Web': {'test.example.ts.net:443': {'Handlers': {'/': {'Proxy': 'http://127.0.0.1:5199'}}}}}
        self.assertTrue(phone.owned_mapping(config, 'test.example.ts.net'))
        config['AllowFunnel'] = {'test.example.ts.net:443': True}
        self.assertFalse(phone.owned_mapping(config, 'test.example.ts.net'))
        config['AllowFunnel'] = {}
        config['TCP']['8443'] = {'HTTPS': True}
        self.assertFalse(phone.owned_mapping(config, 'test.example.ts.net'))

    def test_generated_policy_is_dual_stack_and_only_phone_to_https(self):
        current = {'Self': {'ID': 'laptop', 'TailscaleIPs': ['100.64.0.2', 'fd7a:115c:a1e0::2'],
                            'DNSName': 'test.example.ts.net.'},
                   'Peer': {'p': {'ID': 'phone', 'OS': 'android',
                                  'TailscaleIPs': ['100.64.0.3', 'fd7a:115c:a1e0::3']}}}
        with patch.object(phone, 'tailnet', return_value=current):
            phone.policy(self.state)
        policy = phone.read_json(self.state / 'tailnet-policy.json')
        self.assertEqual(policy['acls'], [])
        self.assertEqual(policy['grants'], [{'src': ['100.64.0.3', 'fd7a:115c:a1e0::3'],
                                             'dst': ['100.64.0.2', 'fd7a:115c:a1e0::2'], 'ip': ['tcp:443']}])
        self.assertIn('[fd7a:115c:a1e0::2]:443', policy['tests'][1]['accept'])
        for check in policy['tests']:
            for destination in check.get('accept', []) + check.get('deny', []):
                address = destination.rsplit(':', 1)[0].strip('[]')
                self.assertEqual(ipaddress.ip_address(check['src']).version, ipaddress.ip_address(address).version)
        self.assertFalse((self.state / 'policy-confirmed.json').exists())

    def test_copied_runtime_controller_executes_outside_checkout(self):
        self.write('image.json', {'revision': 'synthetic-main', 'image': 'sha256:' + 'a' * 64})
        snapshot = self.state / 'phone-server.py'
        phone.atomic(snapshot, Path(phone.__file__).read_bytes())
        result = subprocess.run([os.sys.executable, '-I', str(snapshot), '--state', str(self.state), 'status'],
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=10, check=False)
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertIn(b'Main revision: synthetic-main', result.stdout)
        self.assertNotIn(b'PASSWORD', result.stdout + result.stderr)

    def test_copied_runtime_still_rejects_state_inside_any_checkout(self):
        checkout = self.state / 'some-checkout'
        checkout.mkdir(mode=0o700)
        (checkout / '.git').mkdir()
        snapshot = self.state / 'phone-server.py'
        phone.atomic(snapshot, Path(phone.__file__).read_bytes())
        result = subprocess.run([os.sys.executable, '-I', str(snapshot), '--state', str(checkout / 'state'), 'status'],
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=10, check=False)
        self.assertEqual(result.returncode, 1)
        self.assertIn(b'outside the repository', result.stderr)
        self.assertFalse((checkout / 'state').exists())

    def test_unencrypted_laptop_requires_exact_owner_receipt_and_still_checks_serve(self):
        current = self.selected()
        self.write('storage-approved.json', {'scope': phone.PROJECT, 'sha256': 'approved-context'})
        self.run.side_effect = [b'"/var/lib/docker"', b'{}']
        with patch.object(phone, 'tailnet', return_value=current), patch.object(phone, 'encrypted_path', return_value=False), \
                patch.object(phone, 'storage_digest', return_value='approved-context'):
            self.assertEqual(phone.activation_checks(self.state), 'test.example.ts.net')
        self.run.side_effect = [b'"/var/lib/docker"']
        with patch.object(phone, 'tailnet', return_value=current), patch.object(phone, 'encrypted_path', return_value=False), \
                patch.object(phone, 'storage_digest', return_value='different-storage'):
            with self.assertRaisesRegex(phone.Failure, 'approval must be renewed'):
                phone.activation_checks(self.state)

    def test_unencrypted_exception_cannot_apply_to_a_different_project(self):
        current = self.selected()
        self.write('storage-approved.json', {'scope': 'production', 'sha256': 'approved-context'})
        self.run.return_value = b'"/var/lib/docker"'
        with patch.object(phone, 'tailnet', return_value=current), patch.object(phone, 'encrypted_path', return_value=False), \
                patch.object(phone, 'storage_digest', return_value='approved-context'):
            with self.assertRaisesRegex(phone.Failure, 'approval must be renewed'):
                phone.activation_checks(self.state)

    def test_storage_approval_digest_changes_with_location_device_or_mount(self):
        self.selected()
        self.run.return_value = b'/dev/synthetic'
        original = phone.storage_digest(self.state, '/var/lib/docker')
        self.assertNotEqual(original, phone.storage_digest(self.state, '/srv/docker'))
        self.run.return_value = b'/dev/replacement'
        self.assertNotEqual(original, phone.storage_digest(self.state, '/var/lib/docker'))
        self.run.return_value = b'/dev/synthetic'
        self.write('devices.json', {'device': 'replacement'})
        self.assertNotEqual(original, phone.storage_digest(self.state, '/var/lib/docker'))


if __name__ == '__main__':
    unittest.main()
