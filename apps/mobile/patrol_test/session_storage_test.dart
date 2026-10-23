import 'package:fb_mobile/core/session/session_state.dart';
import 'package:fb_mobile/core/storage/secure_session_store.dart';
import 'package:fb_mobile/core/storage/session_storage_durability.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../tool/session_probe_support.dart';

void main() {
  for (final mode in ['ciphertext', 'key']) {
    patrolTest(
      'AC-001 native $mode failure retains identity and blocks acquisition',
      ($) async {
        final store = probeStore();
        await store.save(probeEnvelope('fault'));
        expect(
          await probeHook.invokeMethod<bool>('fault', {
            'mode': mode,
            'key': store.accountKey('synthetic-registered'),
          }),
          isTrue,
        );
        await assertProbeUnavailable(pointerPlaintext: mode == 'ciphertext');
      },
      timeout: const Timeout(Duration(minutes: 4)),
    );
  }
  for (final mode in ['false', 'lost']) {
    patrolTest('AC-001 native $mode acknowledgement prevents refresh send', (
      $,
    ) async {
      await probeStore().save(probeEnvelope('barrier'));
      expect(await probeHook.invokeMethod<bool>('barrier', mode), isTrue);
      // A fresh coordinator tries to mark rotation pending, then fails closed.
      await assertBarrierBlocksSend();
    }, timeout: const Timeout(Duration(minutes: 4)));
  }
  patrolTest(
    'AC-001 real secure plugin round trip selection removal and commit barrier',
    ($) async {
      const barrier = AndroidSessionStorageDurability();
      SecureSessionStore open() => SecureSessionStore(
        flavor: 'a20-plugin-test',
        origin: Uri.parse('https://session.example.test'),
        storage: const PluginSessionSecretStorage(),
        durability: barrier,
      );
      SessionEnvelope envelope(String id) => SessionEnvelope(
        userId: id,
        kind: SessionKind.registered,
        credentials: SessionCredentials(
          accessToken: 'synthetic-access',
          refreshToken: 'synthetic-refresh',
          expiresAt: DateTime.utc(2026, 10, 23),
          refreshExpiresAt: DateTime.utc(2026, 11, 23),
        ),
      );
      // The production adapter explicitly pins resetOnError:false on all calls.
      // commit() completes only for a native acknowledgement of true.
      await barrier.commit();
      await open().save(envelope('synthetic-a'));
      await open().save(envelope('synthetic-b'));
      final fresh = open();
      final a = fresh.accountKey('synthetic-a');
      final b = fresh.accountKey('synthetic-b');
      expect((await fresh.readActive())?.userId == 'synthetic-b', isTrue);
      await fresh.select(a);
      final restored = await open().readActive();
      expect(restored?.userId == 'synthetic-a', isTrue);
      expect(restored?.credentials?.accessToken == 'synthetic-access', isTrue);
      await fresh.remove(b);
      expect(await open().read(b), isNull);
      expect((await open().readActive())?.userId == 'synthetic-a', isTrue);
      await fresh.remove(a);
      expect(await open().read(a), isNull);
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
