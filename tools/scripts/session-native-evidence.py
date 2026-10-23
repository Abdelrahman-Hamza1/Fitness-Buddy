#!/usr/bin/env python3
"""A20 disposable API-34 dev emulator only. No data clear between kill and check.

Install the separately built tool/session_durability_probe.dart APK first.
Only synthetic stage names/PIDs leave the app; never dump prefs or logcat.
"""
import argparse
import subprocess
import sys
import time

PACKAGE = 'io.github.abdelrahmanhamza1.fitnessbuddy.dev'
ACTIVITY = PACKAGE + '/io.github.abdelrahmanhamza1.fitnessbuddy.MainActivity'

# Kept in sync with session_probe_support.dart; never echo arbitrary app output.
FAILURE_CODES = {
    'identity', 'kind', 'pending', 'pair', 'pending_ready',
    'registered_recovery', 'consumed_token_resent', 'anonymous_send',
    'envelope_value', 'envelope_removed', 'pointer_value', 'pointer_removed',
    'kind_marker', 'barrier_counter', 'plugin_internal_0', 'plugin_internal_1',
    'plugin_internal_2', 'extra_key_added',
    'refresh_send', 'typed_storage', 'unavailable', 'raw_values_changed',
    'refresh_before_ack', 'unexpected_ready', 'unknown_phase', 'fault_ack',
    'present_readable', 'absent', 'wrong_failure_kind',
    'pointer_plaintext_changed', 'pointer_unreadable',
    'exception_PlatformException', 'exception_MissingPluginException',
    'exception_TimeoutException', 'exception_StateError', 'exception_other',
}


NOTICE_CODES = {'base64_wrapping_only'}


def split_notices(status):
    parts = status.split(':NOTICE:')
    notices = parts[1:]
    if (any(code not in NOTICE_CODES for code in notices)
            or len(notices) != len(set(notices))):
        return '', []
    return parts[0], notices


def failure_status(status, phase, iteration):
    prefix = f'{phase}-{iteration}:FAIL:'
    if status.startswith(prefix) and status[len(prefix):] in FAILURE_CODES:
        return 'FAIL:' + status[len(prefix):]
    return 'invalid_status'


def progress_status(status):
    # Diagnostic file is untrusted too: never include raw adb/app output.
    if not status:
        return 'no_status'
    # A stale intent is precisely what we need to diagnose here. Discard its
    # identity/prefix and emit only the fixed last progress code.
    for code in ('CLAIMED', 'CLAIM_SKIPPED'):
        if status.endswith(':' + code):
            return code
    return 'invalid_status'


def error_annotation(error):
    # All RuntimeErrors originate in this harness with fixed stage/code text.
    message = str(error) if isinstance(error, RuntimeError) else 'adb command timed out'
    return '::error title=A20 native evidence::' + message



def adb(*args, optional=False):
    result = subprocess.run(['adb', *args], capture_output=True, text=True, timeout=15)
    if result.returncode and not optional:
        raise RuntimeError('adb command failed: ' + ' '.join(args[:3]))
    return result.stdout.strip()


def pid():
    return adb('shell', 'pidof', PACKAGE, optional=True)


def stop(method):
    old = pid()
    if not old:
        raise RuntimeError('probe process already dead before external kill')
    if method == 'sigkill':
        # run-as shares the dev app UID and can SIGKILL its foreground process.
        adb('shell', 'run-as', PACKAGE, 'kill', '-9', old)
    else:
        adb('shell', 'am', 'force-stop', PACKAGE)
    until = time.monotonic() + 10
    while pid():
        if time.monotonic() > until:
            raise RuntimeError('external kill did not terminate probe')
        time.sleep(0.05)
    return old


def launch(phase, iteration, expected):
    # SIGKILL does not stop the package/task: Android may recreate the previous
    # Activity with its old intent (including the ciphertext fixture's save).
    # Stop that task before deleting status or launching the requested phase.
    # This preserves every preference and the post-fault raw-byte snapshot.
    adb('shell', 'am', 'force-stop', PACKAGE)
    adb('shell', 'run-as', PACKAGE, 'rm', '-f', 'files/a20-status')
    adb('shell', 'run-as', PACKAGE, 'rm', '-f', 'files/a20-progress')
    # force-stop kills processes but can retain task/intent history. Replace the
    # task as well, or a restored old write intent hits its one-shot claim and
    # returns without ACK after we have removed the original status file.
    # NEW_TASK | CLEAR_TASK changes no preferences, claims or fault snapshots.
    adb('shell', 'am', 'start', '-f', '0x10008000', '-n', ACTIVITY,
        '--es', 'phase', phase, '--es', 'iteration', str(iteration))
    wanted = f'{phase}-{iteration}:{expected}'
    until = time.monotonic() + 25
    while time.monotonic() < until:
        status = adb('shell', 'run-as', PACKAGE, 'cat', 'files/a20-status', optional=True)
        base, notices = split_notices(status)
        if base == wanted:
            for notice in notices:
                print('::notice title=A20 native evidence::' + notice, flush=True)
            return pid()
        if status:
            reason = failure_status(base, phase, iteration)
            raise RuntimeError(f'{phase} iteration {iteration}: {reason}')
        time.sleep(0.05)
    progress = adb('shell', 'run-as', PACKAGE, 'cat', 'files/a20-progress', optional=True)
    last = progress_status(progress)
    raise RuntimeError(
        f'{phase} iteration {iteration}: timed out waiting for {expected}; last_status={last}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--iterations', type=int, default=20)
    args = parser.parse_args()
    if args.iterations < 20:
        parser.error('PA2 requires at least 20 iterations')
    if adb('shell', 'getprop', 'ro.build.version.sdk') != '34':
        raise RuntimeError('requires the disposable CI API-34 emulator')
    if adb('shell', 'getprop', 'ro.kernel.qemu') != '1':
        raise RuntimeError('refusing destructive fixtures on a physical phone')
    # A single deliberate reset before the experiment, never across a kill/check.
    adb('shell', 'am', 'force-stop', PACKAGE)
    adb('shell', 'pm', 'clear', PACKAGE)
    for stage in ('pending', 'pair'):
        for n in range(args.iterations):
            launch(stage, n, 'ACKED')
            old = stop('sigkill' if n % 2 == 0 else 'force-stop')
            new = launch('check-' + stage, n, 'PASS')
            if not new or old == new:
                raise RuntimeError(f'{stage} iteration {n}: no new process')
            stop('force-stop')
        print(f'PA2 {stage}: {args.iterations} acknowledged writes survived external process death', flush=True)
    for fault in ('ciphertext', 'key'):
        # New independent fixture before each fault. Never between fault/check.
        adb('shell', 'pm', 'clear', PACKAGE)
        launch(fault, 0, 'ACKED')
        old = stop('sigkill')
        new = launch('check-' + fault, 0, 'PASS')
        if not new or old == new:
            raise RuntimeError(f'{fault}: no new process')
        stop('force-stop')
        retention = ('envelope, pointer and kind marker retained '
                     '(stored Base64 content identical, line breaks ignored)')
        print(f'PA1 {fault}: {retention}; typed unavailable and zero auth sends before and after restart', flush=True)
    print('::notice title=A20 native evidence::PA1 restart checks and PA2 40 kill cycles passed')


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, subprocess.TimeoutExpired) as error:
        print(error_annotation(error), file=sys.stderr)
        sys.exit(1)
