import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fb_mobile/core/api/session_reachability_interceptor.dart';
import 'package:fb_mobile/core/session/auth_transport.dart';
import 'package:fb_mobile/core/session/session_retry_scheduler.dart';
import 'package:fb_mobile/core/session/session_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http.dart';
import 'session_fakes.dart';

Future<void> _drain() => Future<void>.delayed(Duration.zero);

final class _Timer implements Timer {
  new(this.at, this.callback);
  final Duration at;
  final void Function() callback;
  @override
  bool isActive = true;
  @override
  int tick = 0;
  @override
  void cancel() => isActive = false;
  void fire() {
    if (!isActive) return;
    isActive = false;
    tick++;
    callback();
  }
}

final class _Harness {
  final f = Fixture();
  final timers = <_Timer>[];
  late final scheduler = SessionRetryScheduler(
    service: f.service,
    clock: f.clock,
    schedule: (delay, callback) {
      final timer = _Timer(f.clock.elapsed + delay, callback);
      timers.add(timer);
      return timer;
    },
  );
  int get active => timers.where((timer) => timer.isActive).length;
  Future<void> advance(Duration value) async {
    f.clock.advance(value);
    for (final timer in timers.toList()) {
      if (timer.at <= f.clock.elapsed) timer.fire();
    }
    await _drain();
  }

  void dispose() {
    scheduler.dispose();
    f.service.dispose();
  }
}

void main() {
  group('AC-002 Rule:04.5-session-rotation PA3 foreground scheduler', () {
    for (final failure in ['offline', '503', '429']) {
      test('$failure: sequential callers, public successes and resume bursts '
          'retain one deadline, one flight and one timer', () async {
        final h = _Harness();
        addTearDown(h.dispose);
        final f = h.f;
        f.auth.create = () async => throw AuthFailure(
          failure == '429'
              ? AuthFailureKind.throttled
              : AuthFailureKind.retryable,
          retryAt: failure == '429'
              ? f.clock.elapsed + const Duration(seconds: 120)
              : null,
        );
        final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
          ..httpClientAdapter = FakeHttpAdapter(respond: config('0.0.0'))
          ..interceptors.add(
            SessionReachabilityInterceptor(
              apiBaseUrl: Uri.parse('https://api.example.test'),
              onSuccess: h.scheduler.wake,
            ),
          );
        addTearDown(dio.close);
        h.scheduler.start(foreground: true);
        await _drain();
        for (var attempt = 1; attempt <= 8; attempt++) {
          expect(f.auth.creates, attempt);
          expect(h.active, 1);
          final expected = failure == '429'
              ? 120
              : (1 << (attempt - 1)).clamp(1, 60);
          final deadline = f.service.nextAttemptAt;
          expect(deadline - f.clock.elapsed, Duration(seconds: expected));
          for (var burst = 0; burst < 10; burst++) {
            await expectLater(
              f.service.ensureAvailable(),
              throwsA(
                isA<SessionFailure>().having(
                  (e) => e.retryAfter,
                  'remaining cooldown',
                  Duration(seconds: expected),
                ),
              ),
            );
            await dio.get<Object?>('/v1/config');
            h.scheduler.setForeground(foreground: false);
            expect(h.active, 0);
            h.scheduler.setForeground(foreground: true);
            h.scheduler.setForeground(foreground: true);
          }
          expect(f.auth.creates, attempt);
          expect(f.service.nextAttemptAt, deadline);
          expect(h.active, 1);
          await h.advance(
            Duration(seconds: expected) - const Duration(milliseconds: 1),
          );
          expect(f.auth.creates, attempt);
          await h.advance(const Duration(milliseconds: 1));
          expect(f.auth.creates, attempt + 1);
          expect(h.active, 1);
        }
        // Only auth success resets exponential progression and throttle floor.
        f.auth.create = () async => tokens();
        await h.advance(f.service.nextAttemptAt - f.clock.elapsed);
        expect(h.active, 0);
        expect(f.service.nextAttemptAt, Duration.zero);
        f.auth.rotate = (_) async => throw const AuthFailure(
          AuthFailureKind.retryable,
          refreshNotConsumed: true,
        );
        final lease = await f.service.ensureAvailable();
        await expectLater(
          f.service.refreshIfCurrent(lease.generation),
          throwsA(isA<SessionFailure>()),
        );
        await _drain();
        expect(
          f.service.nextAttemptAt - f.clock.elapsed,
          const Duration(seconds: 1),
        );
        expect(
          h.active,
          1,
          reason: 'interceptor-initiated failure also arms timer',
        );
      });
    }

    test('construction and background first-frame start do no I/O; '
        'resume bursts join hung flight', () async {
      final h = _Harness();
      addTearDown(h.dispose);
      final held = Completer<void>();
      h.f.auth.create = () async {
        await held.future;
        return tokens();
      };
      expect(h.f.secrets.reads, 0);
      expect(h.f.auth.creates, 0);
      h.scheduler.start(foreground: false);
      h.scheduler.wake();
      await _drain();
      expect(h.f.secrets.reads, 0);
      h.scheduler.setForeground(foreground: true);
      await _drain();
      for (var i = 0; i < 20; i++) {
        h.scheduler.setForeground(foreground: true);
        h.scheduler.wake();
      }
      expect(h.f.auth.creates, 1);
      expect(h.active, 0);
      held.complete();
      await _drain();
      expect(h.active, 0);
    });

    test('background preserves elapsed deadline, wall jumps cannot change it; '
        'resume after deadline attempts once', () async {
      final h = _Harness();
      addTearDown(h.dispose);
      h.f.auth.create = () async => throw const AuthFailure(
        AuthFailureKind.throttled,
        retryAt: Duration(minutes: 5),
      );
      h.scheduler.start(foreground: true);
      await _drain();
      h.scheduler.setForeground(foreground: false);
      h.f.clock.wallNow = DateTime.utc(2030);
      await h.advance(const Duration(minutes: 4));
      expect(h.f.auth.creates, 1);
      h.scheduler.setForeground(foreground: true);
      expect(h.active, 1);
      h.f.clock.wallNow = DateTime.utc(2020);
      await h.advance(const Duration(seconds: 59));
      expect(h.f.auth.creates, 1);
      h.scheduler.setForeground(foreground: false);
      await h.advance(const Duration(seconds: 2));
      expect(h.active, 0);
      h.scheduler.setForeground(foreground: true);
      h.scheduler.wake();
      await _drain();
      expect(h.f.auth.creates, 2);
    });

    for (final mode in ['storage', 'rejected', 'registered-expired']) {
      test('$mode never arms an automatic retry timer', () async {
        final h = _Harness();
        addTearDown(h.dispose);
        if (mode == 'storage') h.f.secrets.failRead = true;
        if (mode == 'rejected') {
          h.f.auth.create = () async =>
              throw const AuthFailure(AuthFailureKind.rejected);
        }
        if (mode == 'registered-expired') {
          await h.f.seed(registered: true, pending: true);
        }
        h.scheduler.start(foreground: true);
        await _drain();
        expect(h.active, 0);
        final creates = h.f.auth.creates;
        final reads = h.f.secrets.reads;
        for (var i = 0; i < 10; i++) {
          h.scheduler.wake();
          await _drain();
        }
        expect(h.active, 0);
        expect(h.f.auth.creates, creates);
        expect(h.f.secrets.reads, reads);
      });
    }

    test('failed guest recovery acquisition shares refresh throttle floor; '
        'concurrent 401s never consume again during cooldown', () async {
      final h = _Harness();
      addTearDown(h.dispose);
      await h.f.seed();
      h.f.auth.rotate = (_) async => throw AuthFailure(
        AuthFailureKind.throttled,
        retryAt: h.f.clock.elapsed + const Duration(seconds: 90),
      );
      h.scheduler.start(foreground: true);
      await _drain();
      for (var i = 0; i < 10; i++) {
        await expectLater(
          h.f.service.refreshIfCurrent(0),
          throwsA(isA<SessionFailure>()),
        );
      }
      expect(h.f.auth.refreshes, 1);
      h.f.auth.rotate = (_) async =>
          throw const AuthFailure(AuthFailureKind.unauthorized);
      h.f.auth.create = () async =>
          throw const AuthFailure(AuthFailureKind.retryable);
      await h.advance(const Duration(seconds: 90));
      expect(h.f.auth.refreshes, 2);
      expect(h.f.auth.creates, 1);
      expect(h.f.service.nextAttemptAt, const Duration(seconds: 92));
      final calls = List.generate(
        10,
        (_) => expectLater(
          h.f.service.refreshIfCurrent(0),
          throwsA(isA<SessionFailure>()),
        ),
      );
      await Future.wait(calls);
      h.scheduler.wake();
      expect(h.f.auth.creates, 1);
      expect(h.active, 1);
      await h.advance(const Duration(seconds: 2));
      expect(
        h.f.auth.refreshes,
        2,
        reason: 'pending consumed refresh never resent',
      );
      expect(h.f.auth.creates, 2);
    });

    test('A33 acceptance supersedes a hung startup without stranding '
        'the new account retry timer', () async {
      final h = _Harness();
      addTearDown(h.dispose);
      final release = Completer<void>();
      h.f.auth.create = () async {
        await release.future;
        return tokens();
      };
      h.scheduler.start(foreground: true);
      await _drain();
      final accepted = await h.f.service.acceptAuthenticatedSession(
        tokens(anonymous: false, id: 'synthetic-registered'),
      );
      h.f.auth.rotate = (_) async => throw const AuthFailure(
        AuthFailureKind.retryable,
        refreshNotConsumed: true,
      );
      await expectLater(
        h.f.service.refreshIfCurrent(accepted.generation),
        throwsA(isA<SessionFailure>()),
      );
      await _drain();
      expect(h.active, 1);
      await h.advance(const Duration(seconds: 1));
      expect(h.f.auth.refreshes, 2);
      expect(h.active, 1);
      release.complete();
      await _drain();
      expect(h.f.service.state.accountReference, accepted.accountReference);
      expect(h.active, 1);
    });

    test('flight failure after backgrounding cannot rearm timer', () async {
      final h = _Harness();
      addTearDown(h.dispose);
      final release = Completer<void>();
      h.f.auth.create = () async {
        await release.future;
        throw const AuthFailure(AuthFailureKind.retryable);
      };
      h.scheduler.start(foreground: true);
      await _drain();
      h.scheduler.setForeground(foreground: false);
      release.complete();
      await _drain();
      expect(h.active, 0);
      await h.advance(const Duration(seconds: 1));
      expect(h.f.auth.creates, 1);
      h.scheduler.setForeground(foreground: true);
      await _drain();
      expect(h.f.auth.creates, 2);
      expect(h.active, 1);
    });

    for (final held in [false, true]) {
      test(
        'dispose cancels timer and fences late completion (held=$held)',
        () async {
          final h = _Harness();
          addTearDown(h.f.service.dispose);
          final release = Completer<void>();
          h.f.auth.create = () async {
            if (held) await release.future;
            throw const AuthFailure(AuthFailureKind.retryable);
          };
          h.scheduler.start(foreground: true);
          await _drain();
          expect(h.active, held ? 0 : 1);
          h.scheduler.dispose();
          release.complete();
          await _drain();
          await h.advance(const Duration(hours: 1));
          h.scheduler.setForeground(foreground: true);
          h.scheduler.wake();
          expect(h.active, 0);
          expect(h.f.auth.creates, 1);
        },
      );
    }
  });
}
