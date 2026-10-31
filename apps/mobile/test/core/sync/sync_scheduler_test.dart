import 'dart:async';
import 'dart:math';

import 'package:fb_mobile/core/sync/sync_scheduler.dart';
import 'package:fb_sync/fb_sync.dart';
import 'package:flutter_test/flutter_test.dart';

/// Manual timers: [fire] runs the earliest due one.
final class _Timers {
  final List<_FakeTimer> timers = [];

  Timer make(Duration delay, void Function() callback) {
    final t = _FakeTimer(delay, callback);
    timers.add(t);
    return t;
  }

  List<_FakeTimer> get active => [
    for (final t in timers)
      if (t.isActive) t,
  ];

  Future<void> fire() async {
    active.first.fireNow();
    await pumpEventQueue();
  }
}

final class _FakeTimer implements Timer {
  new(this.delay, this._callback);
  final Duration delay;
  final void Function() _callback;
  bool _active = true;

  void fireNow() {
    _active = false;
    _callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

void main() {
  late _Timers timers;
  late List<Completer<SyncRunOutcome>> runs;
  late SyncScheduler scheduler;
  late DateTime now;

  setUp(() {
    timers = _Timers();
    runs = [];
    now = DateTime.utc(2026, 10, 30, 12);
    scheduler = SyncScheduler(
      () {
        final c = Completer<SyncRunOutcome>();
        runs.add(c);
        return c.future;
      },
      schedule: timers.make,
      random: Random(1),
      now: () => now,
    );
  });

  // covers: UX-001
  test('start makes one attempt (after the first frame), no timer', () async {
    scheduler.start(foreground: true);
    expect(runs, hasLength(1));
    expect(timers.active, isEmpty);
    runs.single.complete(const SyncRunSkipped());
    await pumpEventQueue();
    expect(timers.active, isEmpty, reason: 'a skip arms nothing');
    final background = SyncScheduler(
      () async => const SyncRunSucceeded(),
      schedule: timers.make,
    )..start(foreground: false);
    expect(background.running, isFalse);
  });

  test(
    'local changes are debounced; changes during a run queue one more',
    () async {
      scheduler
        ..start(foreground: false)
        ..setForeground(foreground: true);
      expect(runs, hasLength(1), reason: 'foreground runs now');
      scheduler
        ..localChange()
        ..localChange();
      expect(timers.active, isEmpty, reason: 'running: queued instead');
      runs.single.complete(const SyncRunSucceeded());
      await pumpEventQueue();
      expect(runs, hasLength(2), reason: 'exactly one queued run');
      runs.last.complete(const SyncRunSucceeded());
      await pumpEventQueue();
      scheduler
        ..localChange()
        ..localChange();
      expect(timers.active.single.delay, scheduler.debounce);
      await timers.fire();
      expect(runs, hasLength(3));
    },
  );

  test(
    'failures back off 30 s × 2ⁿ with ±20 % jitter, capped at 15 min',
    () async {
      for (var n = 1; n <= 12; n++) {
        final base = min(30000 * pow(2, n - 1).toInt(), 900000);
        final delay = scheduler.backoff(n).inMilliseconds;
        expect(delay, inInclusiveRange(base * 0.8, base * 1.2), reason: '$n');
      }
      scheduler
        ..start(foreground: false)
        ..setForeground(foreground: true);
      runs.single.complete(const SyncRunFailed(SyncFailureKind.offline));
      await pumpEventQueue();
      expect(scheduler.failures, 1);
      final retry = timers.active.single.delay.inMilliseconds;
      expect(retry, inInclusiveRange(24000, 36000));
    },
  );

  test(
    'Retry-After wins; auth failures wait for a signal, not a timer',
    () async {
      scheduler
        ..start(foreground: false)
        ..setForeground(foreground: true);
      runs.last.complete(
        const SyncRunFailed(
          SyncFailureKind.rateLimited,
          retryAfter: Duration(seconds: 90),
        ),
      );
      await pumpEventQueue();
      expect(timers.active.single.delay, const Duration(seconds: 90));
      now = now.add(const Duration(seconds: 90));
      await timers.fire();
      runs.last.complete(const SyncRunFailed(SyncFailureKind.unauthorized));
      await pumpEventQueue();
      expect(timers.active, isEmpty);
      scheduler.reconnected();
      expect(runs, hasLength(3), reason: 'the session came back');
    },
  );

  test('background cancels timers; no runs while backgrounded', () async {
    scheduler.start(foreground: true);
    runs.single.complete(const SyncRunSucceeded());
    await pumpEventQueue();
    scheduler.setForeground(foreground: false);
    expect(timers.active, isEmpty);
    scheduler
      ..localChange()
      ..reconnected();
    expect(runs, hasLength(1));
    expect(timers.active, isEmpty);
  });

  test('syncNow runs now and completes with the run', () async {
    scheduler.start(foreground: false);
    final done = scheduler.syncNow();
    expect(runs, hasLength(1));
    runs.single.complete(const SyncRunSucceeded());
    expect(await done, isA<SyncRunSucceeded>());
    scheduler.dispose();
    expect(await scheduler.syncNow(), isA<SyncRunSkipped>());
  });

  // A34 fix round 1, finding 6.
  test('a run queued during a run does not start after backgrounding; the '
      'next foreground runs', () async {
    scheduler.start(foreground: true);
    expect(runs, hasLength(1));
    scheduler
      ..localChange()
      ..setForeground(foreground: false);
    runs.single.complete(const SyncRunSucceeded());
    await pumpEventQueue();
    expect(runs, hasLength(1), reason: 'no run in the background');
    expect(timers.active, isEmpty);
    scheduler.setForeground(foreground: true);
    expect(runs, hasLength(2));
  });

  // A34 fix round 1, finding 7.
  test('local edits never undercut Retry-After or the backoff', () async {
    scheduler.start(foreground: true);
    runs.single.complete(
      const SyncRunFailed(
        SyncFailureKind.rateLimited,
        retryAfter: Duration(seconds: 90),
      ),
    );
    await pumpEventQueue();
    now = now.add(const Duration(seconds: 10));
    scheduler.localChange();
    expect(timers.active.single.delay, const Duration(seconds: 80));
    // A reconnect resets the backoff, not the server's Retry-After.
    scheduler.reconnected();
    expect(runs, hasLength(1));
    expect(timers.active.single.delay, const Duration(seconds: 80));
    now = now.add(const Duration(seconds: 80));
    await timers.fire();
    expect(runs, hasLength(2));
    runs.last.complete(const SyncRunFailed(SyncFailureKind.offline));
    await pumpEventQueue();
    final backoff = timers.active.single.delay;
    scheduler.localChange();
    expect(timers.active.single.delay, backoff, reason: 'not the debounce');
  });
}
