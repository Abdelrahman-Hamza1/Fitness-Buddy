import 'dart:async';

import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/features/notifications/notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_notifications.dart';

final DateTime _now = DateTime.utc(2026, 10, 31, 9);
const _tag = 'p1';

ScheduledNotification _n(
  int id,
  DateTime at, {
  String title = 'Today',
  String body = 'Anything to log?',
  String location = '/today',
}) => ScheduledNotification(
  id: id,
  at: at,
  title: title,
  body: body,
  payload: NotificationScheduler.payloadOf(
    profileTag: _tag,
    at: at,
    title: title,
    body: body,
    location: location,
  ),
);

void main() {
  late FakeNotificationPlatform platform;
  late MemoryNotificationDeviceStore store;
  late ManualClock clock;
  late NotificationScheduler scheduler;

  setUp(() {
    platform = FakeNotificationPlatform();
    store = MemoryNotificationDeviceStore();
    clock = ManualClock(_now);
    scheduler = NotificationScheduler(
      platform: platform,
      store: store,
      clock: clock,
    );
  });

  final plan = [
    _n(1, _now.add(const Duration(hours: 2))),
    _n(2, _now.add(const Duration(days: 1))),
    _n(3, _now.add(const Duration(days: 2)), location: '/progress'),
  ];

  test(
    'A40 D5 idempotent: re-planning the same plan twice changes nothing',
    () async {
      final first = await scheduler.sync(plan);
      expect(first, (scheduled: 3, cancelled: 0, kept: 0));
      final calls = List.of(platform.calls);
      final ledger = Map.of(store.ledger);

      final second = await scheduler.sync(plan);
      final third = await scheduler.sync([...plan.reversed]);
      expect(second, (scheduled: 0, cancelled: 0, kept: 3));
      expect(third, (scheduled: 0, cancelled: 0, kept: 3));
      expect(platform.calls, calls, reason: 'no platform call');
      expect(store.ledger, ledger);
    },
  );

  test('A40 D5 the diff: a moved time, new words or a new link replace the '
      'ID; an unplanned future one is cancelled; others are kept', () async {
    await scheduler.sync(plan);
    platform.calls.clear();
    final changed = [
      _n(1, _now.add(const Duration(hours: 3))), //       moved
      _n(2, _now.add(const Duration(days: 1)), body: 'New words'),
      _n(4, _now.add(const Duration(days: 3))), //        new
      // 3 dropped
    ];
    final result = await scheduler.sync(changed);
    expect(result, (scheduled: 3, cancelled: 1, kept: 0));
    expect(platform.calls, [
      'cancel 3',
      'schedule 1',
      'schedule 2',
      'schedule 4',
    ]);
    expect(platform.scheduled.keys, unorderedEquals([1, 2, 4]));
    expect(store.ledger.keys, unorderedEquals([1, 2, 4]));
  });

  test('A40 review 2 a due pending notification (an inexact alarm on its '
      'way) is kept while it still applies, cancelled once it does not; a '
      'past planned time is never scheduled', () async {
    await scheduler.sync([
      _n(1, _now.add(const Duration(minutes: 5))),
      _n(2, _now.add(const Duration(minutes: 5))),
    ]);
    clock.advance(const Duration(minutes: 6)); // due, not delivered yet
    platform.calls.clear();
    final result = await scheduler.sync(
      [_n(9, _now.subtract(const Duration(minutes: 1)))],
      stillApplying: {1},
    );
    expect(result, (scheduled: 0, cancelled: 1, kept: 0));
    expect(platform.calls, ['cancel 2']);
    expect(platform.scheduled.keys, [1]);
    // The cancelled one never showed: it doesn't count toward the cap.
    expect(store.ledger.keys, [1]);
    // Off (master switch, permission): cancelAll removes due ones too.
    expect(await scheduler.cancelAll(), 1);
    expect(platform.scheduled, isEmpty);
  });

  test(
    "A40 review 2 a prior day's undelivered alarm (late, or restored "
    'after a reboot) is cancelled, never delivered across midnight',
    () async {
      await scheduler.sync([_n(5, _now.add(const Duration(hours: 12)))]);
      clock.advance(const Duration(hours: 16)); // the next morning
      final result = await scheduler.sync(const [], stillApplying: {7, 8});
      expect(result.cancelled, 1);
      expect(platform.scheduled, isEmpty);
    },
  );

  test(
    'A40 review 1 a run that stops being current schedules nothing more; '
    'purge removes everything, shown ones included, and the ledger',
    () async {
      var current = true;
      platform.gate = Completer<void>();
      final run = scheduler.sync(plan, isCurrent: () => current);
      await Future<void>.delayed(Duration.zero);
      current = false; // the profile changed mid-run
      platform.gate!.complete();
      await run;
      expect(platform.scheduled.length, lessThanOrEqualTo(1));
      await scheduler.purge();
      expect(platform.calls.last, 'cancelEverything');
      expect(platform.scheduled, isEmpty);
      expect(store.ledger, isEmpty);
    },
  );

  test('NT-022 the ledger counts what was shown today; an ID shown today is '
      'not scheduled again', () async {
    final soon = _now.add(const Duration(minutes: 30));
    await scheduler.sync([
      _n(1, soon),
      _n(2, _now.add(const Duration(hours: 5))),
    ]);
    clock.advance(const Duration(hours: 1));
    platform.fireDue(clock.nowUtc());
    final startOfDay = DateTime.utc(2026, 10, 31);
    expect(await scheduler.shownSince(startOfDay), 1);
    // The same type and day planned again later today (a time change after
    // it fired): one per type and day.
    platform.calls.clear();
    await scheduler.sync([
      _n(1, _now.add(const Duration(hours: 4))),
      _n(2, _now.add(const Duration(hours: 5))),
    ]);
    expect(platform.calls, isEmpty);
    expect(await scheduler.shownSince(startOfDay), 1);
  });

  test('A40 D5 cancelAll removes every future notification; old ledger '
      'entries are pruned', () async {
    store.ledger = {
      77: _now.subtract(const Duration(days: 3)).millisecondsSinceEpoch,
    };
    await scheduler.sync(plan);
    expect(store.ledger.containsKey(77), isFalse);
    expect(await scheduler.cancelAll(), 3);
    expect(platform.scheduled, isEmpty);
    expect(store.ledger, isEmpty);
  });

  test('NT-024 a payload opens only a relative app path', () {
    final at = DateTime.utc(2026, 11);
    String payload(String location) => NotificationScheduler.payloadOf(
      profileTag: _tag,
      at: at,
      title: 't',
      body: 'b',
      location: location,
    );
    expect(
      NotificationScheduler.locationOf(
        payload('/progress/week/2026-10-24'),
        profileTag: _tag,
      ),
      '/progress/week/2026-10-24',
    );
    expect(
      NotificationScheduler.locationOf(
        payload('/today?open=buddy'),
        profileTag: _tag,
      ),
      '/today?open=buddy',
    );
    for (final bad in [
      null,
      '',
      'v2|p1|1|2|/today',
      'v1|p1|1|/today',
      payload('https://example.com/x'),
      payload('//example.com/x'),
      payload('today'),
    ]) {
      expect(
        NotificationScheduler.locationOf(bad, profileTag: _tag),
        isNull,
        reason: bad,
      );
    }
    expect(NotificationScheduler.atOf(payload('/today')), at);
    // Another profile's notification opens nothing (A40 review 1).
    expect(
      NotificationScheduler.locationOf(payload('/today'), profileTag: 'p2'),
      isNull,
    );
  });

  test('fix-check 1 a due alarm of another profile is cancelled even when '
      'its ID still applies', () async {
    await scheduler.sync([_n(1, _now.add(const Duration(minutes: 5)))]);
    clock.advance(const Duration(minutes: 6));
    final kept = await scheduler.sync(
      const [],
      stillApplying: {1},
      profileTag: _tag,
    );
    expect(kept.cancelled, 0);
    final foreign = await scheduler.sync(
      const [],
      stillApplying: {1},
      profileTag: 'p2',
    );
    expect(foreign.cancelled, 1);
    expect(platform.scheduled, isEmpty);
  });

  test(
    'fix-check 1 claim purges only when another profile owns the phone',
    () async {
      expect(await scheduler.claim(_tag), isFalse); // fresh install
      await scheduler.sync(plan);
      expect(await scheduler.claim(_tag), isFalse);
      expect(platform.scheduled, isNotEmpty);
      expect(await scheduler.claim('p2'), isTrue);
      expect(platform.scheduled, isEmpty);
      expect(store.owner, 'p2');
    },
  );
}
