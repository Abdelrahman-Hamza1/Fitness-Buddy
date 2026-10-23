// Separate dev-debug target for android-it. Never imported by the app.
import 'package:fb_mobile/core/session/session_service.dart';
import 'package:fb_mobile/core/session/session_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_probe_support.dart';

Future<void> main() async {
  if (!kDebugMode) throw StateError('debug_probe_only');
  WidgetsFlutterBinding.ensureInitialized();
  final args = await probeHook.invokeMapMethod<String, String>('arguments');
  final phase = args?['phase'] ?? 'missing';
  final iteration = args?['iteration'] ?? 'missing';
  var status = 'FAIL:exception_other';
  try {
    if (!await claimProbeWritePhase(phase, iteration)) {
      // Keep the original ACK/status and raw snapshot intact on task recreation.
      runApp(const ProviderScope(child: SizedBox.shrink()));
      return;
    }
    final store = probeStore();
    switch (phase) {
      case 'pending':
        await store.save(probeEnvelope('old-$iteration'));
        await store.save(probeEnvelope('old-$iteration', pending: true));
        status = 'ACKED';
      case 'pair':
        // Represents a consumed token and a committed response.
        await store.save(probeEnvelope('old-$iteration', pending: true));
        await store.save(probeEnvelope('rotated-$iteration'));
        status = 'ACKED';
      case 'check-pending':
      case 'check-pair':
        final pending = phase == 'check-pending';
        final restored = await store.readActive();
        final suffix = pending ? 'old-$iteration' : 'rotated-$iteration';
        probeRequire(restored?.userId == 'synthetic-registered', 'identity');
        probeRequire(restored?.kind == SessionKind.registered, 'kind');
        probeRequire(restored?.rotationPending == pending, 'pending');
        probeRequire(
          restored?.credentials?.accessToken == 'synthetic-access-$suffix' &&
              restored?.credentials?.refreshToken ==
                  'synthetic-refresh-$suffix',
          'pair',
        );
        if (pending) {
          final transport = CountingProbeTransport();
          final service = SessionService(
            store: probeStore(),
            transport: transport,
            clock: ProbeClock(),
          );
          try {
            await service.startAfterFirstFrame();
            throw const ProbeFailure('pending_ready');
          } on SessionFailure catch (failure) {
            probeRequire(
              failure.kind == SessionFailureKind.sessionExpired,
              'registered_recovery',
            );
          } finally {
            service.dispose();
          }
          probeRequire(transport.refreshes == 0, 'consumed_token_resent');
          probeRequire(transport.anonymous == 0, 'anonymous_send');
        }
        status = 'PASS';
      case 'ciphertext':
      case 'key':
        await store.save(probeEnvelope(iteration));
        final faultAcknowledged = await probeHook.invokeMethod<bool>('fault', {
          'mode': phase,
          'key': store.accountKey('synthetic-registered'),
        });
        probeRequire(faultAcknowledged == true, 'fault_ack');
        await assertProbeUnavailable(pointerPlaintext: phase == 'ciphertext');
        status = 'ACKED';
      case 'check-ciphertext':
      case 'check-key':
        await assertProbeUnavailable(
          pointerPlaintext: phase == 'check-ciphertext',
        );
        status = 'PASS';
      default:
        throw const ProbeFailure('unknown_phase');
    }
  } on Object catch (error) {
    status = 'FAIL:${probeFailureCode(error)}';
  }
  final notice = probeNoticeCodes
      .where(probeNotices.contains)
      .map((code) => ':NOTICE:$code')
      .join();
  await probeHook.invokeMethod<bool>(
    'signal',
    '$phase-$iteration:$status$notice',
  );
  runApp(const ProviderScope(child: SizedBox.shrink()));
}
