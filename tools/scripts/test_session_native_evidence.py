"""Synthetic status/annotation tests; no adb or app data required."""
import importlib.util
from pathlib import Path
import re
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    'session_native_evidence', Path(__file__).with_name('session-native-evidence.py'))
harness = importlib.util.module_from_spec(spec)
spec.loader.exec_module(harness)


class FakeAdb:
    """Persistent app data, one-shot writes, task recreation and external kills.

    No launch/stop mocks: main drives the real harness through this adb seam.
    A retained task may restore the first write intent on the second cycle.
    """

    def __init__(self):
        self.files = {}
        self.claims = set()
        self.envelope = None
        self.snapshot = None
        self.process = ''
        self.next_pid = 100
        self.launches = []
        self.clears = []
        self.kills = []
        self.stopped = True
        self.first_intent = None
        self.recreate = True
        self.fault = None

    def __call__(self, *args, optional=False):
        if args[:2] == ('shell', 'getprop'):
            return {'ro.build.version.sdk': '34', 'ro.kernel.qemu': '1'}[args[2]]
        if args == ('shell', 'pidof', harness.PACKAGE):
            return self.process
        if args == ('shell', 'am', 'force-stop', harness.PACKAGE):
            self.process = ''
            self.stopped = True
            self.kills.append('force-stop')
            return ''
        if args == ('shell', 'pm', 'clear', harness.PACKAGE):
            assert self.stopped
            self.clears.append(len(self.launches))
            self.files.clear()
            self.claims.clear()
            self.envelope = self.snapshot = self.fault = self.first_intent = None
            return 'Success'
        if args[:3] == ('shell', 'run-as', harness.PACKAGE):
            if args[3:5] == ('rm', '-f'):
                assert self.stopped, 'status removal raced a live probe'
                self.files.pop(args[5], None)
            elif args[3] == 'cat':
                return self.files.get(args[4], '')
            elif args[3:5] == ('kill', '-9'):
                assert args[5] == self.process and self.process
                self.process = ''
                # SIGKILL permits spontaneous recreation with the same intent.
                # Its one-shot claim must preserve both evidence and status.
                stage, iteration = self.launches[-1]
                assert (stage, iteration) in self.claims
                self.files['files/a20-progress'] = f'{stage}-{iteration}:CLAIM_SKIPPED'
                self.kills.append('sigkill')
            else:
                raise AssertionError(args)
            return ''
        if args[:3] == ('shell', 'am', 'start'):
            assert self.stopped and not self.process
            assert 'files/a20-status' not in self.files
            phase = args[args.index('phase') + 1]
            iteration = args[args.index('iteration') + 1]
            requested = (phase, iteration)
            self.launches.append(requested)
            self.next_pid += 1
            self.process = str(self.next_pid)
            self.stopped = False
            fresh_task = '-f' in args and args[args.index('-f') + 1] == '0x10008000'
            if self.first_intent is None:
                self.first_intent = requested
            if self.recreate and requested == ('pending', '1') and not fresh_task:
                phase, iteration = self.first_intent
            check = phase.startswith('check-')
            stage = phase.removeprefix('check-')
            if not check:
                claim = (phase, iteration)
                if claim in self.claims:
                    self.files['files/a20-progress'] = f'{phase}-{iteration}:CLAIM_SKIPPED'
                    return ''
                self.claims.add(claim)
                self.files['files/a20-progress'] = f'{phase}-{iteration}:CLAIMED'
                self.envelope = (stage, iteration)
                if stage in ('ciphertext', 'key'):
                    self.fault = stage
                    self.snapshot = self.envelope
            else:
                assert self.envelope == (stage, iteration), 'lost/overwritten durable fixture'
                if stage in ('ciphertext', 'key'):
                    assert self.fault == stage and self.snapshot == self.envelope
                if stage == 'pending':
                    # Registered uncertain rotation becomes an expired marker.
                    self.envelope = ('expired', iteration)
            code = 'PASS' if check else 'ACKED'
            notice = (':NOTICE:base64_wrapping_only'
                      if stage in ('ciphertext', 'key', 'pending', 'pair') else '')
            self.files['files/a20-status'] = f'{phase}-{iteration}:{code}{notice}'
            return ''
        raise AssertionError(args)


class NativeEvidenceTest(unittest.TestCase):
    def test_known_failure_reaches_ci_annotation(self):
        for code in harness.FAILURE_CODES:
            with self.subTest(code=code), patch.object(
                    harness, 'adb', side_effect=['', '', '', '', f'check-ciphertext-0:FAIL:{code}']):
                with self.assertRaises(RuntimeError) as caught:
                    harness.launch('check-ciphertext', 0, 'PASS')
                self.assertEqual(
                    harness.error_annotation(caught.exception),
                    f'::error title=A20 native evidence::check-ciphertext iteration 0: FAIL:{code}')

    def test_untrusted_output_is_never_echoed(self):
        for status in ('secret-canary', 'check-ciphertext-0:FAIL:secret_canary',
                       'check-ciphertext-0:FAIL:absent\n::error::canary',
                       'ciphertext-0:FAIL:absent', 'check-ciphertext-1:FAIL:absent',
                       'check-ciphertext-0:PASS', 'check-ciphertext-0:FAIL'):
            with self.subTest(status=status), patch.object(
                    harness, 'adb', side_effect=['', '', '', '', status]):
                with self.assertRaisesRegex(RuntimeError, 'iteration 0: invalid_status$'):
                    harness.launch('check-ciphertext', 0, 'ACKED')

    def test_success_and_timeouts(self):
        with patch.object(harness, 'adb', side_effect=['', '', '', '', 'pair-3:ACKED']), \
                patch.object(harness, 'pid', return_value='123'):
            self.assertEqual(harness.launch('pair', 3, 'ACKED'), '123')
        with patch.object(harness, 'adb', return_value=''), \
                patch.object(harness.time, 'monotonic', side_effect=[0, 26]):
            with self.assertRaisesRegex(RuntimeError, 'timed out waiting for PASS; last_status=no_status$'):
                harness.launch('check-ciphertext', 0, 'PASS')
        self.assertEqual(harness.error_annotation(harness.subprocess.TimeoutExpired(
            'secret-canary', 15, output='secret-canary')),
            '::error title=A20 native evidence::adb command timed out')

    def test_restart_stops_old_write_phase_before_launching_check(self):
        with patch.object(harness, 'adb', side_effect=[
                '', '', '', '', 'check-ciphertext-0:PASS']) as adb, \
                patch.object(harness, 'pid', return_value='456'):
            self.assertEqual(harness.launch('check-ciphertext', 0, 'PASS'), '456')
        self.assertEqual(adb.call_args_list, [
            unittest.mock.call('shell', 'am', 'force-stop', harness.PACKAGE),
            unittest.mock.call('shell', 'run-as', harness.PACKAGE,
                               'rm', '-f', 'files/a20-status'),
            unittest.mock.call('shell', 'run-as', harness.PACKAGE,
                               'rm', '-f', 'files/a20-progress'),
            unittest.mock.call('shell', 'am', 'start', '-f', '0x10008000', '-n', harness.ACTIVITY,
                               '--es', 'phase', 'check-ciphertext', '--es', 'iteration', '0'),
            unittest.mock.call('shell', 'run-as', harness.PACKAGE,
                               'cat', 'files/a20-status', optional=True),
        ])

    def test_allowed_notice_sets_are_informational(self):
        for stage in ('ciphertext', 'key', 'pending', 'pair'):
            for phase, expected in [(stage, 'ACKED'), ('check-' + stage, 'PASS')]:
                for notices in [[], ['base64_wrapping_only']]:
                    suffix = ''.join(':NOTICE:' + code for code in notices)
                    with self.subTest(phase=phase, notices=notices), patch.object(harness, 'adb', side_effect=[
                            '', '', '', '', f'{phase}-0:{expected}' + suffix]), \
                            patch.object(harness, 'pid', return_value='456'), \
                            patch('builtins.print') as output:
                        self.assertEqual(harness.launch(phase, 0, expected), '456')
                        self.assertEqual(output.call_args_list, [unittest.mock.call(
                            '::notice title=A20 native evidence::' + code, flush=True) for code in notices])

    def test_failure_is_not_hidden_by_informational_notices(self):
        for code in harness.FAILURE_CODES:
            with self.subTest(code=code), patch.object(harness, 'adb', side_effect=[
                    '', '', '', '', f'check-ciphertext-0:FAIL:{code}'
                    ':NOTICE:base64_wrapping_only']), \
                    patch('builtins.print') as output:
                with self.assertRaisesRegex(RuntimeError, f'FAIL:{code}$'):
                    harness.launch('check-ciphertext', 0, 'PASS')
                output.assert_not_called()

    def test_full_multi_iteration_flow(self):
        fake = FakeAdb()
        with patch.object(harness, 'adb', side_effect=fake), \
                patch.object(harness.sys, 'argv', ['probe']), patch('builtins.print') as output:
            harness.main()
        expected = [(phase, str(n)) for stage in ('pending', 'pair')
                    for n in range(20) for phase in (stage, 'check-' + stage)]
        expected += [(phase, '0') for stage in ('ciphertext', 'key')
                     for phase in (stage, 'check-' + stage)]
        self.assertEqual(fake.launches, expected)
        self.assertEqual(fake.clears, [0, 80, 82])
        self.assertEqual(len(fake.claims), 1)  # Only the final independent fault.
        self.assertEqual(fake.kills.count('sigkill'), 22)
        for fault in ('ciphertext', 'key'):
            output.assert_any_call(
                f'PA1 {fault}: envelope, pointer and kind marker retained '
                '(stored Base64 content identical, line breaks ignored); '
                'typed unavailable and zero auth sends before and after restart', flush=True)


    def test_retained_intent_claim_reproduces_missing_ack_without_task_clear(self):
        fake = FakeAdb()

        def old_launch_adb(*args, **kwargs):
            if args[:3] == ('shell', 'am', 'start'):
                args = tuple(x for x in args if x not in ('-f', '0x10008000'))
            return fake(*args, **kwargs)

        # Advance fake time on sleep so a broken launch times out locally.
        now = [0]
        with patch.object(harness, 'adb', side_effect=old_launch_adb), \
                patch.object(harness.time, 'monotonic', side_effect=lambda: now[0]), \
                patch.object(harness.time, 'sleep', side_effect=lambda _: now.__setitem__(0, now[0] + 1)), \
                patch.object(harness.sys, 'argv', ['probe']), patch('builtins.print'):
            with self.assertRaisesRegex(RuntimeError, 'pending iteration 1: timed out.*last_status=CLAIM_SKIPPED$'):
                harness.main()

    def test_timeout_progress_is_fixed_codes_only(self):
        for status, expected in [('', 'no_status'), ('pending-1:CLAIMED', 'CLAIMED'),
                                 ('pending-1:CLAIM_SKIPPED', 'CLAIM_SKIPPED'),
                                 ('pending-0:CLAIM_SKIPPED', 'CLAIM_SKIPPED'),
                                 ('secret\n::error::canary', 'invalid_status')]:
            with self.subTest(status=status), patch.object(harness, 'adb', side_effect=[
                    '', '', '', '', status]), \
                    patch.object(harness.time, 'monotonic', side_effect=[0, 26]):
                with self.assertRaises(RuntimeError) as caught:
                    harness.launch('pending', 1, 'ACKED')
                self.assertEqual(harness.error_annotation(caught.exception),
                                 '::error title=A20 native evidence::pending iteration 1: '
                                 f'timed out waiting for ACKED; last_status={expected}')

    def test_untrusted_notice_is_rejected(self):
        for suffix in ['', 'secret-canary', 'base64_wrapping_only\n::error::canary',
                       'base64_wrapping_only:NOTICE:base64_wrapping_only',
                       'base64_wrapping_only:NOTICE:secret-canary']:
            with self.subTest(suffix=suffix), patch.object(harness, 'adb', side_effect=[
                    '', '', '', '', '', 'check-ciphertext-0:PASS:NOTICE:' + suffix]):
                with self.assertRaisesRegex(RuntimeError, 'invalid_status$'):
                    harness.launch('check-ciphertext', 0, 'PASS')

    def test_code_allowlist_matches_dart(self):
        root = Path(__file__).resolve().parents[2]
        dart = (root / 'apps/mobile/tool/session_probe_support.dart').read_text()
        codes = dart.split('const Set<String> probeFailureCodes = {', 1)[1].split('};', 1)[0]
        retention = dart.split('const probeRetentionCodes = {', 1)[1].split('};', 1)[0]
        self.assertEqual(set(re.findall(r"'([a-zA-Z0-9_]+)'", codes + retention)),
                         harness.FAILURE_CODES)

    def test_notice_allowlist_matches_dart(self):
        root = Path(__file__).resolve().parents[2]
        dart = (root / 'apps/mobile/tool/session_probe_support.dart').read_text()
        codes = dart.split('const probeNoticeCodes = {', 1)[1].split('};', 1)[0]
        self.assertEqual(set(re.findall(r"'([a-zA-Z0-9_]+)'", codes)), harness.NOTICE_CODES)
