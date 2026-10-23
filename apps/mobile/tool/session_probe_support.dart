// Shared only by the synthetic Patrol tests and the debug probe entrypoint.
import 'dart:async';
import 'dart:convert';

import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_mobile/core/session/auth_transport.dart';
import 'package:fb_mobile/core/session/session_clock.dart';
import 'package:fb_mobile/core/session/session_service.dart';
import 'package:fb_mobile/core/session/session_state.dart';
import 'package:fb_mobile/core/storage/secure_session_store.dart';
import 'package:fb_mobile/core/storage/session_storage_durability.dart';
import 'package:flutter/services.dart';

const probeHook = MethodChannel('fitness_buddy/session_test');

/// A recreated Android Activity must not replay an acknowledged write fixture.
/// Claims survive process death; the harness clears data between PA1 faults.
Future<bool> claimProbeWritePhase(String phase, String iteration) async {
  if (!{'pending', 'pair', 'ciphertext', 'key'}.contains(phase)) return true;
  final claimed = await probeHook.invokeMethod<bool>('claimWritePhase', {
    'phase': phase,
    'iteration': iteration,
  });
  probeRequire(claimed != null, 'fault_ack');
  return claimed!;
}

SecureSessionStore probeStore() => SecureSessionStore(
  flavor: 'a20-native-evidence',
  origin: Uri.parse('https://session.example.test'),
  storage: const PluginSessionSecretStorage(),
  durability: const AndroidSessionStorageDurability(),
);

SessionEnvelope probeEnvelope(String iteration, {bool pending = false}) =>
    SessionEnvelope(
      userId: 'synthetic-registered',
      kind: SessionKind.registered,
      rotationPending: pending,
      credentials: SessionCredentials(
        accessToken: 'synthetic-access-$iteration',
        refreshToken: 'synthetic-refresh-$iteration',
        expiresAt: DateTime.utc(2026, 10, 23),
        refreshExpiresAt: DateTime.utc(2026, 11, 23),
      ),
    );

final class ProbeClock implements SessionClock {
  @override
  DateTime get wallNow => DateTime.utc(2026, 10, 23);
  @override
  Duration get elapsed => Duration.zero;
}

final class CountingProbeTransport implements AuthTransport {
  int anonymous = 0;
  int refreshes = 0;

  @override
  Future<AuthTokens> createAnonymous() async {
    anonymous++;
    throw StateError('unexpected_anonymous');
  }

  @override
  Future<AuthTokens> refresh(String token) async {
    refreshes++;
    throw StateError('unexpected_refresh');
  }
}

// The condition-first shape mirrors an assertion in this synthetic harness.
// ignore: avoid_positional_boolean_parameters
void probeRequire(bool condition, String stage) {
  if (!condition) throw ProbeFailure(stage);
}

// Native code compares ciphertext locally. Only fixed categories cross
// the channel.
const probeRetentionCodes = {
  'envelope_value',
  'envelope_removed',
  'pointer_value',
  'pointer_removed',
  'kind_marker',
  'barrier_counter',
  'plugin_internal_0',
  'plugin_internal_1',
  'plugin_internal_2',
  'extra_key_added',
};

// Fixed notices only; no pointer plaintext or ciphertext crosses the channel.
const probeNoticeCodes = {'base64_wrapping_only'};
final probeNotices = <String>{};

Future<void> assertProbePointer({
  SessionSecretStorage storage = const PluginSessionSecretStorage(),
}) async {
  final expected = probeStore().accountKey('synthetic-registered');
  final namespace = expected.split('.')[3];
  Object? decoded;
  try {
    final raw = await storage.read('fb.session.active.v1.$namespace');
    if (raw == null) throw const ProbeFailure('pointer_unreadable');
    decoded = jsonDecode(raw);
  } on Object {
    throw const ProbeFailure('pointer_unreadable');
  }
  probeRequire(
    decoded is Map<String, dynamic> &&
        decoded['v'] == 1 &&
        decoded['key'] == expected &&
        decoded['kind'] == SessionKind.registered.name,
    'pointer_plaintext_changed',
  );
}

Future<void> assertProbeRetained({
  bool pointerPlaintext = false,
  SessionSecretStorage storage = const PluginSessionSecretStorage(),
}) async {
  if (pointerPlaintext) await assertProbePointer(storage: storage);
  final changes = await probeHook.invokeListMethod<String>('retentionChanges');
  if (changes == null) throw const ProbeFailure('raw_values_changed');
  for (final code in changes) {
    // The forced disk-commit counter carries no account or crypto state.
    if (code == 'barrier_counter') continue;
    if (probeNoticeCodes.contains(code)) {
      probeNotices.add(code);
      continue;
    }
    throw ProbeFailure(
      probeRetentionCodes.contains(code) ? code : 'raw_values_changed',
    );
  }
}

// Explicit allowlist: exception messages and dynamic type names stay in Dart.
const Set<String> probeFailureCodes = {
  'identity',
  'kind',
  'pending',
  'pair',
  'pending_ready',
  'registered_recovery',
  'consumed_token_resent',
  'anonymous_send',
  'refresh_send',
  'typed_storage',
  'unavailable',
  'raw_values_changed',
  'pointer_plaintext_changed',
  'pointer_unreadable',
  ...probeRetentionCodes,
  'refresh_before_ack',
  'unexpected_ready',
  'unknown_phase',
  'fault_ack',
  'present_readable',
  'absent',
  'wrong_failure_kind',
  'exception_PlatformException',
  'exception_MissingPluginException',
  'exception_TimeoutException',
  'exception_StateError',
  'exception_other',
};

final class ProbeFailure implements Exception {
  const new(this.code);
  final String code;
}

String probeFailureCode(Object error) {
  if (error is ProbeFailure && probeFailureCodes.contains(error.code)) {
    return error.code;
  }
  return switch (error) {
    PlatformException() => 'exception_PlatformException',
    MissingPluginException() => 'exception_MissingPluginException',
    TimeoutException() => 'exception_TimeoutException',
    StateError() => 'exception_StateError',
    _ => 'exception_other',
  };
}

/// Both faults require stored Base64 content identity, line breaks ignored.
Future<void> assertProbeUnavailable({bool pointerPlaintext = false}) async {
  // Diagnose absence separately before the coordinator could acquire a guest.
  // This uses the production read path, including native cold initialization.
  try {
    final restored = await probeStore().readActive();
    await assertProbeRetained(pointerPlaintext: pointerPlaintext);
    throw ProbeFailure(restored == null ? 'absent' : 'present_readable');
  } on SessionStorageFailure catch (failure) {
    probeRequire(
      failure.kind == SessionStorageFailureKind.unavailable ||
          failure.kind == SessionStorageFailureKind.malformed,
      'wrong_failure_kind',
    );
  }
  await assertProbeRetained(pointerPlaintext: pointerPlaintext);
  final transport = CountingProbeTransport();
  final service = SessionService(
    store: probeStore(),
    transport: transport,
    clock: ProbeClock(),
  );
  try {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await (attempt == 0
            ? service.startAfterFirstFrame()
            : service.ensureAvailable());
        throw const ProbeFailure('unexpected_ready');
      } on SessionFailure catch (failure) {
        probeRequire(
          failure.kind == SessionFailureKind.storage,
          'typed_storage',
        );
      }
    }
    probeRequire(
      service.state.readiness == SessionReadiness.unavailable,
      'unavailable',
    );
    probeRequire(transport.anonymous == 0, 'anonymous_send');
    probeRequire(transport.refreshes == 0, 'refresh_send');
    await assertProbeRetained(pointerPlaintext: pointerPlaintext);
  } finally {
    service.dispose();
  }
}

Future<void> assertBarrierBlocksSend() async {
  final transport = CountingProbeTransport();
  final service = SessionService(
    store: probeStore(),
    transport: transport,
    clock: ProbeClock(),
  );
  try {
    await service.startAfterFirstFrame();
    throw const ProbeFailure('unexpected_ready');
  } on SessionFailure catch (failure) {
    probeRequire(failure.kind == SessionFailureKind.storage, 'typed_storage');
    probeRequire(
      service.state.readiness == SessionReadiness.unavailable,
      'unavailable',
    );
    probeRequire(transport.refreshes == 0, 'refresh_before_ack');
    probeRequire(transport.anonymous == 0, 'anonymous_send');
  } finally {
    service.dispose();
  }
}
