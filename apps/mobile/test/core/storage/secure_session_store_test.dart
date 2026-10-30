import 'dart:async';

import 'package:fb_mobile/core/session/session_state.dart';
import 'package:fb_mobile/core/storage/secure_session_store.dart';
import 'package:fb_mobile/core/storage/session_storage_durability.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final class FakeSecrets implements SessionSecretStorage {
  final values = <String, String>{};
  final events = <String>[];
  Exception? failure;
  int? failWrite;
  int writes = 0;

  @override
  Future<String?> read(String key) async {
    events.add('read');
    if (failure case final failure?) throw failure;
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    events.add('write');
    if (++writes == failWrite) throw StateError('synthetic secret');
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    events.add('delete');
    if (++writes == failWrite) throw StateError('synthetic secret');
    values.remove(key);
  }
}

final class FakeDurability implements SessionStorageDurability {
  new(this.events);
  final List<String> events;
  Completer<void>? hold;
  bool fail = false;
  int commits = 0;
  int? failAt;

  @override
  Future<void> commit() async {
    events.add('barrier');
    commits++;
    await hold?.future;
    if (fail || commits == failAt) throw StateError('synthetic secret');
  }
}

SessionEnvelope envelope({
  String id = 'synthetic-a',
  SessionKind kind = SessionKind.registered,
  bool pending = false,
  bool expired = false,
}) => SessionEnvelope(
  userId: id,
  kind: kind,
  rotationPending: pending,
  credentials: expired
      ? null
      : SessionCredentials(
          accessToken: 'synthetic-access-canary',
          refreshToken: 'synthetic-refresh-canary',
          expiresAt: DateTime.utc(2026, 10, 23),
          refreshExpiresAt: DateTime.utc(2026, 11, 23),
        ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeSecrets secrets;
  late FakeDurability barrier;
  SecureSessionStore store({
    String flavor = 'dev',
    String url = 'https://api.example.test',
  }) => SecureSessionStore(
    flavor: flavor,
    origin: Uri.parse(url),
    storage: secrets,
    durability: barrier,
  );

  setUp(() {
    secrets = FakeSecrets();
    barrier = FakeDurability(secrets.events);
  });

  test(
    'AC-001 pair barrier precedes pointer barrier and publication',
    () async {
      final session = store();
      barrier.hold = Completer<void>();
      var published = false;
      final save = session.save(envelope()).then((_) => published = true);
      await Future<void>.delayed(Duration.zero);
      expect(secrets.events.where((e) => e != 'read'), ['write', 'barrier']);
      expect(secrets.values.length, 1);
      expect(published, isFalse);
      barrier.hold!.complete();
      await save;
      expect(secrets.events.where((e) => e != 'read'), [
        'write', 'barrier', // Recovery intent.
        'write', 'barrier', // Complete pair.
        'write', 'barrier', // Active pointer.
        'delete', 'barrier', // Clear intent only after both are durable.
      ]);
      expect(
        (await session.readActive())!.credentials!.refreshToken,
        'synthetic-refresh-canary',
      );
    },
  );

  for (final position in [1, 2, 3, 4]) {
    test(
      'AC-001 barrier $position failure never publishes or retries',
      () async {
        final session = store();
        barrier.failAt = position;
        await expectLater(
          session.save(envelope()),
          throwsA(isA<SessionStorageFailure>()),
        );
        final before = List<String>.of(secrets.events);
        barrier.failAt = null;
        await expectLater(
          session.readActive(),
          throwsA(isA<SessionStorageFailure>()),
        );
        await expectLater(
          session.save(envelope()),
          throwsA(isA<SessionStorageFailure>()),
        );
        expect(secrets.events, before);
      },
    );
    test(
      'AC-001 plugin write $position failure fails closed without fallback',
      () async {
        final session = store();
        secrets.failWrite = position;
        await expectLater(
          session.save(envelope()),
          throwsA(isA<SessionStorageFailure>()),
        );
        expect(
          secrets.events.where((e) => e == 'delete').length,
          position == 4 ? 1 : 0,
        );
        await expectLater(
          session.readActive(),
          throwsA(isA<SessionStorageFailure>()),
        );
      },
    );
  }

  test(
    'AC-001 queued reads and saves cannot overtake pending commit',
    () async {
      final session = store();
      barrier.hold = Completer<void>();
      final first = session.save(envelope());
      final second = session.save(envelope(id: 'synthetic-b'));
      final read = session.readActive();
      await Future<void>.delayed(Duration.zero);
      expect(secrets.events.where((e) => e != 'read'), ['write', 'barrier']);
      barrier.hold!.complete();
      await Future.wait([first, second]);
      expect((await read)!.userId, 'synthetic-b');
    },
  );

  test(
    'AC-001 origin/flavor/account isolation and canonical effective port',
    () async {
      final a = store();
      await a.save(envelope());
      await a.save(envelope(id: 'synthetic-b', kind: SessionKind.anonymous));
      expect(
        (await a.read(a.accountKey('synthetic-a')))!.kind,
        SessionKind.registered,
      );
      expect(
        (await store(
          url: 'https://API.EXAMPLE.TEST:443/path',
        ).readActive())!.userId,
        'synthetic-b',
      );
      for (final other in [
        store(flavor: 'prod'),
        store(url: 'http://api.example.test'),
        store(url: 'https://api.example.test:444'),
      ]) {
        expect(await other.readActive(), isNull);
        await expectLater(
          other.select(a.accountKey('synthetic-a')),
          throwsA(isA<SessionStorageFailure>()),
        );
      }
      await a.select(a.accountKey('synthetic-a'));
      expect((await a.readActive())!.userId, 'synthetic-a');
    },
  );

  test(
    'AC-001 registered expired and rotationPending survive reopen',
    () async {
      await store().save(envelope(pending: true));
      expect((await store().readActive())!.rotationPending, isTrue);
      await store().save(envelope(expired: true));
      final restored = (await store().readActive())!;
      expect(restored.kind, SessionKind.registered);
      expect(restored.credentials, isNull);
      expect(restored.rotationPending, isFalse);
    },
  );

  for (final phase in ['key-unwrapping', 'initialization', 'decryption']) {
    test(
      'AC-001 $phase exception retains bytes and never means no account',
      () async {
        await store().save(envelope());
        final before = Map<String, String>.of(secrets.values);
        secrets.failure = PlatformException(
          code: phase,
          message: 'synthetic-refresh-canary',
        );
        final session = store();
        for (var attempt = 0; attempt < 2; attempt++) {
          await expectLater(
            session.readActive(),
            throwsA(
              isA<SessionStorageFailure>().having(
                (e) => e.toString(),
                'redacted',
                isNot(contains('canary')),
              ),
            ),
          );
        }
        expect(secrets.values, before);
        expect(secrets.events.where((e) => e == 'delete').length, 1);
        secrets.failure = null;
        expect((await session.readActive())!.kind, SessionKind.registered);
      },
    );
  }

  test(
    'AC-001 interrupted first registered save retains recovery identity',
    () async {
      final session = store();
      barrier.failAt = 2; // Intent durable, pair commit ambiguous, no pointer.
      await expectLater(
        session.save(envelope()),
        throwsA(isA<SessionStorageFailure>()),
      );
      await expectLater(
        store().readActive(),
        throwsA(
          isA<SessionStorageFailure>().having(
            (e) => e.knownState!.status,
            'retained',
            SessionStatus.registered,
          ),
        ),
      );
    },
  );

  test(
    'AC-001 readable registered pointer survives malformed credentials',
    () async {
      final session = store();
      await session.save(envelope());
      secrets.values[session.accountKey('synthetic-a')] =
          '{bad synthetic-access-canary';
      await expectLater(
        store().readActive(),
        throwsA(
          isA<SessionStorageFailure>()
              .having(
                (e) => e.knownState!.status,
                'identity',
                SessionStatus.registered,
              )
              .having(
                (e) => e.knownState!.readiness,
                'availability',
                SessionReadiness.unavailable,
              ),
        ),
      );
      expect(
        secrets.values[session.accountKey('synthetic-a')],
        contains('canary'),
      );
    },
  );

  test('AC-001 mismatched user, kind and version fail closed', () async {
    final session = store();
    await session.save(envelope());
    final key = session.accountKey('synthetic-a');
    final original = secrets.values[key]!;
    for (final malformed in [
      original.replaceFirst('synthetic-a', 'synthetic-z'),
      original.replaceFirst('registered', 'anonymous'),
      original.replaceFirst('"v":1', '"v":2'),
    ]) {
      secrets.values[key] = malformed;
      await expectLater(
        store().readActive(),
        throwsA(isA<SessionStorageFailure>()),
      );
    }
  });

  test(
    'AC-001 remove deletes only envelope and commits; selected kind survives',
    () async {
      final session = store();
      await session.save(envelope());
      await session.save(envelope(id: 'synthetic-b'));
      await session.remove(session.accountKey('synthetic-b'));
      expect(secrets.events.sublist(secrets.events.length - 2), [
        'delete',
        'barrier',
      ]);
      expect(await session.read(session.accountKey('synthetic-a')), isNotNull);
      await expectLater(
        store().readActive(),
        throwsA(
          isA<SessionStorageFailure>().having(
            (e) => e.knownState!.status,
            'retained kind',
            SessionStatus.registered,
          ),
        ),
      );
    },
  );

  test(
    'AC-001 invalid envelopes and absent selection perform no writes',
    () async {
      final session = store();
      await expectLater(
        session.save(envelope(kind: SessionKind.anonymous, expired: true)),
        throwsA(isA<SessionStorageFailure>()),
      );
      await expectLater(
        session.select(session.accountKey('missing')),
        throwsA(isA<SessionStorageFailure>()),
      );
      expect(secrets.values, isEmpty);
      expect(envelope().toString(), isNot(contains('synthetic')));
      expect(envelope().credentials.toString(), isNot(contains('synthetic')));
    },
  );

  test('AC-001 plugin boundary forwards non-destructive options', () async {
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    const adapter = PluginSessionSecretStorage();
    await adapter.read('synthetic-key');
    await adapter.write('synthetic-key', 'synthetic-canary');
    await adapter.delete('synthetic-key');
    expect(calls.map((c) => c.method), ['read', 'write', 'delete']);
    for (final call in calls) {
      final options = (call.arguments as Map)['options'] as Map;
      expect(options['resetOnError'], 'false');
      expect(options['migrateOnAlgorithmChange'], 'false');
      expect(options['storageNamespace'], 'fb.session.secure.v1');
      expect(
        options['keyCipherAlgorithm'],
        'RSA_ECB_OAEPwithSHA_256andMGF1Padding',
      );
      expect(options['storageCipherAlgorithm'], 'AES_GCM_NoPadding');
    }
  });

  for (final response in [true, false, null, 'throw']) {
    test(
      'AC-001 Android acknowledgement $response has no secret arguments',
      () async {
        const channel = MethodChannel('fitness_buddy/session_storage');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              expect(call.method, 'commit');
              expect(call.arguments, isNull);
              if (response == 'throw') {
                throw PlatformException(code: 'synthetic');
              }
              return response;
            });
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(channel, null),
        );
        final future = const AndroidSessionStorageDurability().commit();
        if (response == true) {
          await future;
        } else {
          await expectLater(
            future,
            throwsA(anyOf(isA<Exception>(), isA<Error>())),
          );
        }
      },
    );
  }

  testWidgets('AC-001 lost barrier acknowledgement times out', (tester) async {
    const channel = MethodChannel('fitness_buddy/session_storage');
    final held = Completer<Object?>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) => held.future);
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final expectation = expectLater(
      const AndroidSessionStorageDurability().commit(),
      throwsA(isA<SessionStorageFailure>()),
    );
    await tester.pump(const Duration(seconds: 11));
    await expectation;
    held.complete(true);
    await tester.pump();
  });

  test('AC-003 A33 crash point: an envelope written before the pointer is '
      'completed by reconciliation', () async {
    barrier.failAt = 2; // The pair's commit fails: no pointer, intent left.
    await expectLater(store().save(envelope()), throwsA(anything));
    barrier.failAt = null;
    final restarted = store();
    await expectLater(
      restarted.readActive(),
      throwsA(isA<SessionStorageFailure>()),
      reason: 'the intent blocks everything until reconciled',
    );
    expect(await restarted.reconcileIntent(), isTrue);
    expect((await restarted.readActive())!.userId, 'synthetic-a');
    expect(await restarted.reconcileIntent(), isFalse);
  });

  test(
    'AC-003 A33 crash point: an intent without its envelope is discarded and '
    'the previous selection stays',
    () async {
      await store().save(envelope(id: 'synthetic-previous'));
      barrier
        ..commits = 0
        ..failAt = 1; // Only the intent was written.
      await expectLater(
        store().save(envelope(id: 'synthetic-new')),
        throwsA(anything),
      );
      barrier.failAt = null;
      final restarted = store();
      expect(await restarted.reconcileIntent(), isTrue);
      expect((await restarted.readActive())!.userId, 'synthetic-previous');
    },
  );

  test(
    'AC-003 A33 reconciliation fails closed when the store cannot be read',
    () async {
      barrier.failAt = 2;
      await expectLater(store().save(envelope()), throwsA(anything));
      barrier.failAt = null;
      secrets.failure = Exception('keystore');
      await expectLater(store().reconcileIntent(), throwsA(anything));
      secrets.failure = null;
      expect(
        secrets.values.keys.where((k) => k.contains('intent')),
        hasLength(1),
      );
    },
  );
}
