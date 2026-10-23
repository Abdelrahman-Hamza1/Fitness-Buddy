import 'dart:async';
import 'dart:convert';

import 'package:fb_mobile/core/storage/secure_session_store.dart';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../tool/session_probe_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AC-001 probe write phases require a one-shot native claim', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    addTearDown(() => messenger.setMockMethodCallHandler(probeHook, null));
    final claimed = <String>{};
    var calls = 0;
    messenger.setMockMethodCallHandler(probeHook, (call) async {
      calls++;
      expect(call.method, 'claimWritePhase');
      final args = call.arguments as Map;
      return claimed.add('${args['phase']}-${args['iteration']}');
    });
    for (final phase in ['pending', 'pair', 'ciphertext', 'key']) {
      expect(await claimProbeWritePhase(phase, '0'), isTrue);
      expect(await claimProbeWritePhase(phase, '0'), isFalse);
      expect(await claimProbeWritePhase(phase, '1'), isTrue);
    }
    expect(calls, 12);
    for (final phase in ['check-pending', 'check-pair', 'check-fault']) {
      expect(await claimProbeWritePhase(phase, '0'), isTrue);
    }
    expect(calls, 12);
  });

  test(
    'AC-001 retention checks keep every identity and plugin category',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      addTearDown(() => messenger.setMockMethodCallHandler(probeHook, null));
      for (final code in probeRetentionCodes) {
        messenger.setMockMethodCallHandler(probeHook, (call) async {
          expect(call.method, 'retentionChanges');
          return ['barrier_counter', code];
        });
        if (code == 'barrier_counter') {
          await assertProbeRetained();
        } else {
          await expectLater(
            assertProbeRetained(),
            throwsA(isA<ProbeFailure>().having((e) => e.code, 'code', code)),
          );
        }
      }
      messenger.setMockMethodCallHandler(probeHook, (_) async => <String>[]);
      await assertProbeRetained();
      messenger.setMockMethodCallHandler(
        probeHook,
        (_) async => ['secret-canary'],
      );
      await expectLater(
        assertProbeRetained(),
        throwsA(
          isA<ProbeFailure>().having(
            (e) => e.code,
            'code',
            'raw_values_changed',
          ),
        ),
      );
    },
  );

  test(
    'AC-001 ciphertext fault checks plaintext and strict retention',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      addTearDown(() => messenger.setMockMethodCallHandler(probeHook, null));
      probeNotices.clear();
      addTearDown(probeNotices.clear);
      final key = probeStore().accountKey('synthetic-registered');
      final storage = _PointerStorage(
        jsonEncode({'v': 1, 'key': key, 'kind': 'registered'}),
      );
      messenger.setMockMethodCallHandler(
        probeHook,
        (_) async => ['base64_wrapping_only'],
      );
      await assertProbeRetained(pointerPlaintext: true, storage: storage);
      expect(storage.key, 'fb.session.active.v1.${key.split('.')[3]}');
      expect(probeNotices, {'base64_wrapping_only'});
      probeNotices.clear();
      await assertProbeRetained();
      expect(probeNotices, {'base64_wrapping_only'});
      for (final code in probeRetentionCodes.where(
        (code) => code != 'barrier_counter',
      )) {
        messenger.setMockMethodCallHandler(
          probeHook,
          (_) async => ['base64_wrapping_only', code],
        );
        await expectLater(
          assertProbeRetained(pointerPlaintext: true, storage: storage),
          throwsA(isA<ProbeFailure>().having((e) => e.code, 'code', code)),
        );
      }
    },
  );

  test(
    'AC-001 pointer failures use fixed unreadable or changed codes',
    () async {
      final key = probeStore().accountKey('synthetic-registered');
      for (final value in <String?>[
        null,
        'private-canary',
        'null',
        jsonEncode({'v': 1, 'key': 'different-account', 'kind': 'registered'}),
        jsonEncode({'v': 1, 'key': key, 'kind': 'anonymous'}),
        jsonEncode({'v': 2, 'key': key, 'kind': 'registered'}),
      ]) {
        await expectLater(
          assertProbePointer(storage: _PointerStorage(value)),
          throwsA(
            isA<ProbeFailure>().having(
              (e) => e.code,
              'code',
              value == null || value == 'private-canary'
                  ? 'pointer_unreadable'
                  : 'pointer_plaintext_changed',
            ),
          ),
        );
      }
      await expectLater(
        assertProbePointer(storage: _PointerStorage(null, fail: true)),
        throwsA(
          isA<ProbeFailure>().having(
            (e) => e.code,
            'code',
            'pointer_unreadable',
          ),
        ),
      );
    },
  );

  test('AC-001 probe diagnostics expose only fixed codes', () {
    for (final code in probeFailureCodes) {
      expect(probeFailureCode(ProbeFailure(code)), code);
    }
    const canary = 'private-content-canary';
    expect(probeFailureCode(const ProbeFailure(canary)), 'exception_other');
    expect(
      probeFailureCode(PlatformException(code: canary, message: canary)),
      'exception_PlatformException',
    );
    expect(
      probeFailureCode(MissingPluginException(canary)),
      'exception_MissingPluginException',
    );
    expect(
      probeFailureCode(TimeoutException(canary)),
      'exception_TimeoutException',
    );
    expect(probeFailureCode(StateError(canary)), 'exception_StateError');
    expect(probeFailureCode(Exception(canary)), 'exception_other');
    expect(
      () => probeRequire(false, 'absent'),
      throwsA(isA<ProbeFailure>().having((e) => e.code, 'code', 'absent')),
    );
  });
}

final class _PointerStorage implements SessionSecretStorage {
  new(this.value, {this.fail = false});
  final String? value;
  final bool fail;
  String? key;

  @override
  Future<String?> read(String key) async {
    this.key = key;
    if (fail) throw PlatformException(code: 'private-canary');
    return value;
  }

  @override
  Future<void> write(String key, String value) =>
      throw StateError('unexpected_write');
  @override
  Future<void> delete(String key) => throw StateError('unexpected_delete');
}
