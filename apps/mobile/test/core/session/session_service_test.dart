import 'dart:async';

import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_mobile/core/session/auth_transport.dart';
import 'package:fb_mobile/core/session/session_service.dart';
import 'package:fb_mobile/core/session/session_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'session_fakes.dart';

Matcher failure(SessionFailureKind kind) =>
    throwsA(isA<SessionFailure>().having((e) => e.kind, 'kind', kind));

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late Fixture f;
  setUp(() => f = Fixture());

  test('UX-001 construction and pre-frame ensure perform no I/O', () async {
    expect(f.service.state.status, SessionStatus.none);
    await expectLater(
      f.service.ensureAvailable(),
      failure(SessionFailureKind.notStarted),
    );
    expect(f.secrets.reads, 0);
    expect(f.auth.creates, 0);
  });

  test('AC-002 ten concurrent acquisitions share one durable flight', () async {
    final response = Completer<AuthTokens>();
    f.auth.create = () => response.future;
    final first = f.service.startAfterFirstFrame();
    final waiters = List.generate(9, (_) => f.service.ensureAvailable());
    await settle();
    expect(f.auth.creates, 1);
    response.complete(tokens());
    final leases = await Future.wait([first, ...waiters]);
    expect(leases.map((l) => l.generation).toSet().length, 1);
    expect(f.service.state.readiness, SessionReadiness.ready);
    expect((await f.store.readActive())!.rotationPending, isFalse);
  });

  test(
    'Rule:04.5-session-rotation ten 401s and stale 401 rotate once',
    () async {
      final lease = await f.service.startAfterFirstFrame();
      final response = Completer<AuthTokens>();
      f.auth.rotate = (_) => response.future;
      final calls = List.generate(
        10,
        (_) => f.service.refreshIfCurrent(lease.generation),
      );
      await settle();
      expect(f.auth.refreshes, 1);
      expect((await f.store.readActive())!.rotationPending, isTrue);
      response.complete(tokens(suffix: '2'));
      final renewed = (await Future.wait(calls)).first;
      expect(renewed.generation, greaterThan(lease.generation));
      expect(
        (await f.service.refreshIfCurrent(lease.generation)).generation,
        renewed.generation,
      );
      expect(f.auth.refreshes, 1);
    },
  );

  test(
    'Rule:04.5-session-rotation waiter timeout cannot cancel shared refresh',
    () async {
      final lease = await f.service.startAfterFirstFrame();
      final response = Completer<AuthTokens>();
      f.auth.rotate = (_) => response.future;
      final shared = f.service.refreshIfCurrent(lease.generation);
      await expectLater(
        shared.timeout(Duration.zero),
        throwsA(isA<TimeoutException>()),
      );
      final other = f.service.ensureAvailable();
      response.complete(tokens(suffix: '2'));
      await other;
      expect(f.auth.refreshes, 1);
    },
  );

  test(
    'Rule:04.5-session-rotation pending barrier precedes physical send',
    () async {
      final lease = await f.service.startAfterFirstFrame();
      f.barrier.hold = Completer<void>();
      final rotation = f.service.refreshIfCurrent(lease.generation);
      await settle();
      expect(f.auth.refreshes, 0);
      f.barrier.hold!.complete();
      await rotation;
      expect(f.auth.refreshes, 1);
    },
  );

  for (final phase in [1, 2, 3, 4]) {
    test('AC-001 pending commit $phase failure sends zero refreshes', () async {
      final lease = await f.service.startAfterFirstFrame();
      f.barrier.failAt = f.barrier.commits + phase;
      await expectLater(
        f.service.refreshIfCurrent(lease.generation),
        failure(SessionFailureKind.storage),
      );
      expect(f.auth.refreshes, 0);
      await expectLater(
        f.service.ensureAvailable(),
        failure(SessionFailureKind.storage),
      );
      expect(f.auth.creates, 1);
    });
    test(
      'AC-001 rotated pair commit $phase failure never publishes new pair',
      () async {
        await f.seed(registered: true);
        // A restore triggers one server-driven refresh.
        f.auth.rotate = (_) async => tokens(anonymous: false, suffix: '2');
        f.barrier.failAt = f.barrier.commits + 4 + phase;
        await expectLater(
          f.service.startAfterFirstFrame(),
          failure(SessionFailureKind.storage),
        );
        expect(f.auth.refreshes, 1);
        expect(f.service.state.status, SessionStatus.registered);
        expect(
          f.states.where((s) => s.readiness == SessionReadiness.ready),
          isEmpty,
        );
        await expectLater(
          f.service.ensureAvailable(),
          failure(SessionFailureKind.storage),
        );
        expect(f.auth.refreshes, 1);
        final restarted = f.newService(storage: f.newStore());
        try {
          await restarted.startAfterFirstFrame();
        } on SessionFailure {
          /* Fail closed. */
        }
        expect(
          f.auth.consumed.where((v) => v == 'synthetic-refresh-1'),
          hasLength(1),
        );
        expect(f.auth.creates, 0);
      },
    );
  }

  for (final registered in [false, true]) {
    test(
      'AC-002 terminal rejection registered=$registered preserves account kind',
      () async {
        await f.seed(registered: registered);
        f.auth.rotate = (_) async =>
            throw const AuthFailure(AuthFailureKind.unauthorized);
        if (registered) {
          await expectLater(
            f.service.startAfterFirstFrame(),
            failure(SessionFailureKind.sessionExpired),
          );
          expect(f.service.state.status, SessionStatus.sessionExpired);
          final restarted = f.newService(storage: f.newStore());
          await expectLater(
            restarted.startAfterFirstFrame(),
            failure(SessionFailureKind.sessionExpired),
          );
          expect(f.auth.creates, 0);
        } else {
          final lease = await f.service.startAfterFirstFrame();
          expect(lease.accountReference, isNotEmpty);
          expect(f.auth.creates, 1);
          expect(f.service.state.status, SessionStatus.anonymous);
        }
        expect(f.auth.refreshes, 1);
      },
    );
    test(
      'AC-001 pending restart registered=$registered never resends',
      () async {
        await f.seed(registered: registered, pending: true);
        if (registered) {
          await expectLater(
            f.service.startAfterFirstFrame(),
            failure(SessionFailureKind.sessionExpired),
          );
          expect((await f.store.readActive())!.credentials, isNull);
        } else {
          await f.service.startAfterFirstFrame();
          expect(f.auth.creates, 1);
        }
        expect(f.auth.refreshes, 0);
      },
    );
    test(
      'OF-01 lost response registered=$registered retains pending in cooldown',
      () async {
        await f.seed(registered: registered);
        f.auth.rotate = (_) async =>
            throw const AuthFailure(AuthFailureKind.retryable);
        await expectLater(
          f.service.startAfterFirstFrame(),
          failure(SessionFailureKind.retryable),
        );
        expect((await f.store.readActive())!.rotationPending, isTrue);
        expect(
          f.service.state.status,
          registered ? SessionStatus.registered : SessionStatus.anonymous,
        );
        for (var i = 0; i < 10; i++) {
          await expectLater(
            f.service.ensureAvailable(),
            failure(SessionFailureKind.retryable),
          );
        }
        expect(f.auth.refreshes, 1);
        f.clock.advance(const Duration(seconds: 1));
        if (registered) {
          await expectLater(
            f.service.ensureAvailable(),
            failure(SessionFailureKind.sessionExpired),
          );
          expect(f.auth.creates, 0);
        } else {
          await f.service.ensureAvailable();
          expect(f.auth.creates, 1);
        }
        expect(f.auth.refreshes, 1);
      },
    );
  }

  test(
    'AC-001 unreadable registered storage never acquires anonymous',
    () async {
      await f.seed(registered: true);
      final before = Map.of(f.secrets.values);
      f.secrets.failRead = true;
      await expectLater(
        f.service.startAfterFirstFrame(),
        failure(SessionFailureKind.storage),
      );
      await expectLater(
        f.service.ensureAvailable(),
        failure(SessionFailureKind.storage),
      );
      expect(f.auth.creates, 0);
      expect(f.secrets.values, before);
    },
  );

  for (final fault in ['unavailable', 'malformed', 'missing', 'intent']) {
    test(
      'AC-001 PA1 $fault cold restore and repeated ensure write nothing',
      () async {
        await f.seed(registered: true);
        final key = f.store.accountKey('synthetic-guest');
        switch (fault) {
          case 'unavailable':
            // Keep the pointer readable: only the selected envelope fails.
            f.secrets.failReadKey = key;
          case 'malformed':
            f.secrets.values[key] = 'invalid-ciphertext';
          case 'missing':
            f.secrets.values.remove(key);
          case 'intent':
            final pointer = f.secrets.values.keys.singleWhere(
              (key) => key.startsWith('fb.session.active.v1.'),
            );
            f.secrets.values[pointer.replaceFirst('.active.', '.intent.')] =
                f.secrets.values[pointer]!;
        }
        final before = Map.of(f.secrets.values);
        f.secrets.writes = 0;
        f.secrets.deletes = 0;
        final commits = f.barrier.commits;
        // Separate store/service instances model two process cold starts.
        for (var restart = 0; restart < 2; restart++) {
          final service = f.newService(storage: f.newStore());
          addTearDown(service.dispose);
          await expectLater(
            service.startAfterFirstFrame(),
            failure(SessionFailureKind.storage),
          );
          for (var attempt = 0; attempt < 3; attempt++) {
            await expectLater(
              service.ensureAvailable(),
              failure(SessionFailureKind.storage),
            );
          }
          expect(service.state.status, SessionStatus.registered);
          expect(service.state.readiness, SessionReadiness.unavailable);
          // Equal plaintext would miss a same-value encrypted pointer rewrite.
          expect(f.secrets.writes, 0);
          expect(f.secrets.deletes, 0);
          expect(f.barrier.commits, commits);
          expect(f.secrets.values, before);
        }
        expect(f.auth.creates, 0);
        expect(f.auth.refreshes, 0);
      },
    );
  }

  test(
    'Rule:04.5-session-rotation A33 acceptance fences late network result',
    () async {
      final lease = await f.service.startAfterFirstFrame();
      final response = Completer<AuthTokens>();
      f.auth.rotate = (_) => response.future;
      final old = f.service.refreshIfCurrent(lease.generation);
      final oldCheck = expectLater(old, failure(SessionFailureKind.superseded));
      await settle();
      final accepted = await f.service.acceptAuthenticatedSession(
        tokens(id: 'synthetic-account-b', anonymous: false),
      );
      response.complete(tokens(suffix: 'late'));
      await oldCheck;
      expect(
        (await f.service.ensureAvailable()).generation,
        accepted.generation,
      );
      expect((await f.store.readActive())!.userId, 'synthetic-account-b');
      expect(f.service.state.status, SessionStatus.registered);
    },
  );

  test(
    'AC-001 acceptance queues behind an in-flight old durable mutation',
    () async {
      final lease = await f.service.startAfterFirstFrame();
      f.barrier.hold = Completer<void>();
      final old = f.service.refreshIfCurrent(lease.generation);
      final oldCheck = expectLater(old, failure(SessionFailureKind.superseded));
      await settle();
      var published = false;
      final accepted = f.service
          .acceptAuthenticatedSession(
            tokens(id: 'synthetic-b', anonymous: false),
          )
          .then((v) {
            published = true;
            return v;
          });
      await settle();
      expect(published, isFalse);
      f.barrier.hold!.complete();
      await oldCheck;
      await accepted;
      expect(f.auth.refreshes, 0);
      expect((await f.store.readActive())!.userId, 'synthetic-b');
    },
  );

  test('Rule:04.5-session-rotation PA3 paces ten sequential callers', () async {
    f.auth.create = () async =>
        throw const AuthFailure(AuthFailureKind.retryable);
    await expectLater(
      f.service.startAfterFirstFrame(),
      failure(SessionFailureKind.retryable),
    );
    var expectedCalls = 1;
    for (final seconds in [1, 2, 4, 8, 16, 32, 60, 60]) {
      for (var i = 0; i < 10; i++) {
        await expectLater(
          f.service.ensureAvailable(),
          failure(SessionFailureKind.retryable),
        );
        await expectLater(
          f.service.refreshIfCurrent(0),
          failure(SessionFailureKind.retryable),
        );
      }
      expect(f.auth.creates, expectedCalls);
      f.clock.advance(
        Duration(seconds: seconds) - const Duration(microseconds: 1),
      );
      await expectLater(
        f.service.ensureAvailable(),
        failure(SessionFailureKind.retryable),
      );
      expect(f.auth.creates, expectedCalls);
      f.clock.advance(const Duration(microseconds: 1));
      await expectLater(
        f.service.ensureAvailable(),
        failure(SessionFailureKind.retryable),
      );
      expect(f.auth.creates, ++expectedCalls);
    }
    f.clock.advance(const Duration(seconds: 60));
    f.auth.create = () async => tokens();
    await f.service.ensureAvailable();
    expect(f.service.nextAttemptAt, Duration.zero);
    f.auth.rotate = (_) async =>
        throw const AuthFailure(AuthFailureKind.throttled);
    final lease = await f.service.ensureAvailable();
    await expectLater(
      f.service.refreshIfCurrent(lease.generation),
      failure(SessionFailureKind.retryable),
    );
    expect(
      f.service.nextAttemptAt - f.clock.elapsed,
      const Duration(seconds: 1),
    );
  });

  test('Rule:04.5-session-rotation Retry-After survives wall jumps', () async {
    final lease = await f.service.startAfterFirstFrame();
    f.auth.rotate = (_) async => throw const AuthFailure(
      AuthFailureKind.throttled,
      retryAt: Duration(seconds: 180),
    );
    await expectLater(
      f.service.refreshIfCurrent(lease.generation),
      failure(SessionFailureKind.retryable),
    );
    expect((await f.store.readActive())!.rotationPending, isFalse);
    f.clock.wallNow = f.clock.wallNow.add(const Duration(days: 40));
    f.clock.advance(const Duration(seconds: 179));
    await expectLater(
      f.service.ensureAvailable(),
      failure(SessionFailureKind.retryable),
    );
    expect(f.auth.refreshes, 1);
    f.clock.advance(const Duration(seconds: 1));
    f.auth.rotate = (_) async => tokens(suffix: '2');
    await f.service.ensureAvailable();
    // The still-fresh bearer can be reused; a 401 obeys the same now-open gate.
    await f.service.refreshIfCurrent(lease.generation);
    expect(f.auth.refreshes, 2);
  });

  test(
    'AC-002 failed guest recovery acquisition shares the same deadline',
    () async {
      await f.seed(pending: true);
      f.auth.create = () async => throw const AuthFailure(
        AuthFailureKind.throttled,
        retryAt: Duration(seconds: 300),
      );
      await expectLater(
        f.service.startAfterFirstFrame(),
        failure(SessionFailureKind.retryable),
      );
      for (var i = 0; i < 10; i++) {
        await expectLater(
          f.service.ensureAvailable(),
          failure(SessionFailureKind.retryable),
        );
      }
      expect(f.auth.creates, 1);
      expect(f.auth.refreshes, 0);
      expect((await f.store.readActive())!.rotationPending, isTrue);
      expect(f.service.nextAttemptAt, const Duration(seconds: 300));
    },
  );

  for (final days in [-40, 40]) {
    test(
      'AC-001 skew $days days cannot invalidate account or repeat refresh',
      () async {
        f.clock.wallNow = f.clock.wallNow.add(Duration(days: days));
        await f.seed(registered: true);
        f.auth.rotate = (_) async => tokens(anonymous: false, suffix: '2');
        final lease = await f.service.startAfterFirstFrame();
        f.clock.wallNow = f.clock.wallNow.add(Duration(days: -2 * days));
        await f.service.ensureAvailable();
        expect(f.auth.refreshes, 1);
        await f.service.refreshIfCurrent(lease.generation);
        expect(f.auth.refreshes, 2);
        expect(f.service.state.status, SessionStatus.registered);
      },
    );
  }

  for (final kind in [
    AuthFailureKind.rejected,
    AuthFailureKind.upgradeRequired,
  ]) {
    test(
      'AC-001 $kind stops automatic retries without guest downgrade',
      () async {
        await f.seed(registered: true);
        f.auth.rotate = (_) async => throw AuthFailure(kind);
        await expectLater(
          f.service.startAfterFirstFrame(),
          failure(SessionFailureKind.rejected),
        );
        f.clock.advance(const Duration(days: 1));
        await expectLater(
          f.service.ensureAvailable(),
          failure(SessionFailureKind.rejected),
        );
        expect(f.auth.refreshes, 1);
        expect(f.auth.creates, 0);
        expect(f.service.state.status, SessionStatus.registered);
      },
    );
  }

  test(
    'Rule:09.4-no-content-logging state leases and failures redact canaries',
    () async {
      final output = <String>[];
      await runZoned(
        () async {
          final lease = await f.service.startAfterFirstFrame();
          expect(lease.toString(), isNot(contains('synthetic')));
          f.auth.rotate = (_) async =>
              throw StateError('synthetic-content-canary');
          await expectLater(
            f.service.refreshIfCurrent(lease.generation),
            throwsA(
              isA<SessionFailure>().having(
                (e) => e.toString(),
                'safe',
                isNot(contains('canary')),
              ),
            ),
          );
        },
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, line) => output.add(line),
        ),
      );
      expect(output, isEmpty);
      expect(f.states.join(), isNot(contains('synthetic')));
    },
  );

  test(
    'AC-001 pair acknowledgement precedes readiness and waiter release',
    () async {
      final lease = await f.service.startAfterFirstFrame();
      final response = Completer<AuthTokens>();
      f.auth.rotate = (_) => response.future;
      var released = false;
      final rotation = f.service.refreshIfCurrent(lease.generation).then((v) {
        released = true;
        return v;
      });
      await settle();
      f.barrier.hold = Completer<void>();
      response.complete(tokens(suffix: '2'));
      await settle();
      expect(released, isFalse);
      expect(f.service.state.readiness, SessionReadiness.pending);
      f.barrier.hold!.complete();
      await rotation;
      expect(f.service.state.readiness, SessionReadiness.ready);
    },
  );

  test('AC-001 death after consumption never resends old secret', () async {
    await f.seed(registered: true);
    final response = Completer<AuthTokens>();
    f.auth.rotate = (_) => response.future;
    final old = f.service.startAfterFirstFrame();
    final check = expectLater(old, failure(SessionFailureKind.superseded));
    await settle();
    expect(f.auth.consumed, ['synthetic-refresh-1']);
    f.service.dispose();
    final restarted = f.newService(storage: f.newStore());
    await expectLater(
      restarted.startAfterFirstFrame(),
      failure(SessionFailureKind.sessionExpired),
    );
    response.complete(tokens(anonymous: false, suffix: 'late'));
    await check;
    expect(f.auth.consumed, ['synthetic-refresh-1']);
    expect(f.auth.creates, 0);
  });

  test(
    'AC-001 A33 storage failure preserves registered marker and blocks auth',
    () async {
      await f.service.startAfterFirstFrame();
      f.barrier.failAt = f.barrier.commits + 2;
      await expectLater(
        f.service.acceptAuthenticatedSession(
          tokens(id: 'synthetic-b', anonymous: false),
        ),
        failure(SessionFailureKind.storage),
      );
      expect(f.service.state.status, SessionStatus.registered);
      expect(f.service.state.readiness, SessionReadiness.unavailable);
      await expectLater(
        f.service.ensureAvailable(),
        failure(SessionFailureKind.storage),
      );
      expect(f.auth.creates, 1);
    },
  );

  test(
    'AC-001 server account/kind mismatch fails closed with pending retained',
    () async {
      await f.seed(registered: true);
      f.auth.rotate = (_) async => tokens(id: 'synthetic-other');
      await expectLater(
        f.service.startAfterFirstFrame(),
        failure(SessionFailureKind.rejected),
      );
      expect((await f.store.readActive())!.rotationPending, isTrue);
      expect(f.service.state.status, SessionStatus.registered);
      expect(f.auth.creates, 0);
    },
  );

  test(
    'AC-001 wall jumps never extend monotonic access freshness cap',
    () async {
      final lease = await f.service.startAfterFirstFrame();
      f.clock.wallNow = f.clock.wallNow.add(const Duration(days: 500));
      f.clock.advance(const Duration(minutes: 14));
      expect((await f.service.ensureAvailable()).generation, lease.generation);
      f.clock.advance(const Duration(minutes: 1));
      await f.service.ensureAvailable();
      expect(f.auth.refreshes, 1);
      // The now-past newly issued wall hint still permits use and a server 401.
      final current = await f.service.ensureAvailable();
      expect(f.auth.refreshes, 1);
      await f.service.refreshIfCurrent(current.generation);
      expect(f.auth.refreshes, 2);
    },
  );

  test(
    'OF-01 proven pre-dispatch failure retries without expiring registered',
    () async {
      await f.seed(registered: true);
      f.auth.rotate = (_) async => throw const AuthFailure(
        AuthFailureKind.retryable,
        refreshNotConsumed: true,
      );
      await expectLater(
        f.service.startAfterFirstFrame(),
        failure(SessionFailureKind.retryable),
      );
      expect((await f.store.readActive())!.rotationPending, isFalse);
      expect(f.service.state.status, SessionStatus.registered);
      f.clock.advance(const Duration(seconds: 1));
      f.auth.rotate = (_) async => tokens(anonymous: false, suffix: '2');
      await f.service.ensureAvailable();
      expect(f.auth.refreshes, 2);
      expect(f.auth.creates, 0);
    },
  );

  test('AC-001 wall jump during issuance cannot cause an auth loop', () async {
    final response = Completer<AuthTokens>();
    f.auth.create = () => response.future;
    final pending = f.service.startAfterFirstFrame();
    await settle();
    f.clock.wallNow = f.clock.wallNow.add(const Duration(days: 90));
    response.complete(tokens());
    await pending;
    for (var i = 0; i < 10; i++) {
      await f.service.ensureAvailable();
    }
    expect(f.auth.creates, 1);
    expect(f.auth.refreshes, 0);
  });

  test(
    'Rule:04.5-session-rotation disposal fences late auth publication',
    () async {
      final response = Completer<AuthTokens>();
      f.auth.create = () => response.future;
      final pending = f.service.startAfterFirstFrame();
      final check = expectLater(
        pending,
        failure(SessionFailureKind.superseded),
      );
      await settle();
      f.service.dispose();
      response.complete(tokens());
      await check;
      expect(f.secrets.values, isEmpty);
    },
  );
}
