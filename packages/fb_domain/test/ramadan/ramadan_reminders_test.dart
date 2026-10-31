import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:test/test.dart';

// Ramadan 1447: 2026-02-18 … 2026-03-19.
final _season = RamadanSeason(hijriYear: 1447, on: true);
RamadanCalendar _cal([RamadanSeason? season]) =>
    RamadanCalendar(RamadanSettings([season ?? _season]));

/// The device: Palestine in winter (UTC+2).
final _clock = ManualClock(DateTime.utc(2026), offsetMinutes: 120);

/// Fajr 04:58 and Maghrib 17:29 local (UTC+2) on [date] (Ramallah,
/// 1 Ramadan), as instants.
FajrMaghrib? _times(LocalDate date) => (
  fajrUtc: DateTime.utc(date.year, date.month, date.day, 2, 58),
  maghribUtc: DateTime.utc(date.year, date.month, date.day, 15, 29),
);

List<(NotificationType, LocalDate, int)> _plan(
  LocalDate today,
  int now, {
  NotificationPrefs? prefs,
  RamadanCalendar? calendar,
  FajrMaghrib? Function(LocalDate)? prayer,
  int shown = 0,
  Clock? clock,
}) => [
  for (final c in NotificationPlanner.plan(
    prefs: prefs ?? _ramadanOnly(),
    today: today,
    nowMinute: now,
    state: NotificationState(mealsToday: 3),
    shownToday: shown,
    extra: RamadanReminders.candidates(
      calendar: calendar ?? _cal(),
      today: today,
      prayer: prayer ?? _times,
      clock: clock ?? _clock,
    ),
  ))
    if (c.type == NotificationType.suhoor || c.type == NotificationType.iftar)
      (c.type, c.date, c.minute),
];

/// Suhoor and iftar on; quiet hours 23:00–07:00 (the defaults).
NotificationPrefs _ramadanOnly() => NotificationPrefs(
  types: {
    for (final t in NotificationType.values)
      t: NotificationTypePrefs(
        enabled: t == NotificationType.suhoor || t == NotificationType.iftar,
        minute: t.defaultMinute ?? 0,
      ),
  },
);

/// No quiet hours (06:59 would be inside the default 23:00–07:00).
final NotificationPrefs _noQuiet = _ramadanOnly().copyWith(
  quietStart: 0,
  quietEnd: 0,
);

void main() {
  const suhoor = NotificationType.suhoor;
  const iftar = NotificationType.iftar;

  test('NT-008 suhoor 45 min before Fajr fires inside quiet hours; NT-009 '
      'iftar 90 min after Maghrib; each keeps its exact instant', () {
    final day = LocalDate(2026, 3, 1);
    final rows = _plan(day, 0);
    expect(rows.take(2), [(suhoor, day, 253), (iftar, day, 1139)]);
    expect(rows, hasLength(14), reason: 'seven fasting days');
    final c = RamadanReminders.candidates(
      calendar: _cal(),
      today: day,
      prayer: _times,
      clock: _clock,
    );
    // The day before comes first (a day either side of the horizon).
    expect(c[2].atUtc, DateTime.utc(2026, 3, 1, 2, 13));
    expect(c[3].atUtc, DateTime.utc(2026, 3, 1, 16, 59));
  });

  test('NT-022 outside the daily cap: two other reminders already shown', () {
    final day = LocalDate(2026, 3, 1);
    expect(_plan(day, 0, shown: 5).take(2), [
      (suhoor, day, 253),
      (iftar, day, 1139),
    ]);
  });

  test('only on fasting days: none before Ramadan, after its end, or on a '
      'not-fasting day', () {
    final before = LocalDate(2026, 2, 12);
    expect(_plan(before, 0).first.$2, LocalDate(2026, 2, 18));
    final end = LocalDate(2026, 3, 18);
    expect(_plan(end, 0).map((r) => r.$2).toSet(), {
      LocalDate(2026, 3, 18),
      LocalDate(2026, 3, 19),
    });
    final day = LocalDate(2026, 3, 1);
    expect(
      _plan(
        day,
        0,
        calendar: RamadanCalendar(
          RamadanSettings([_season]),
          notFasting: [day],
        ),
      ).map((r) => r.$2),
      isNot(contains(day)),
    );
  });

  test('switched off in settings or no prayer times: none', () {
    final day = LocalDate(2026, 3, 1);
    expect(_plan(day, 0, prayer: (_) => null), isEmpty);
    expect(_plan(day, 0, prefs: NotificationPrefs(enabled: false)), isEmpty);
    final off = _ramadanOnly().withType(
      suhoor,
      NotificationTypePrefs(enabled: false, minute: 0),
    );
    expect(_plan(day, 0, prefs: off).map((r) => r.$1).toSet(), {iftar});
  });

  test(
    'the iftar nudge respects quiet hours; a passed time is not planned',
    () {
      final day = LocalDate(2026, 3, 1);
      final late = _plan(
        day,
        0,
        prayer: (d) => (
          fajrUtc: DateTime.utc(d.year, d.month, d.day, 2, 58),
          maghribUtc: DateTime.utc(d.year, d.month, d.day, 19, 40),
        ),
      );
      expect(late.where((r) => r.$1 == iftar), isEmpty, reason: '23:10 quiet');
      expect(_plan(day, 600).first, (iftar, day, 1139));
    },
  );

  test('defaults: suhoor on, iftar off (spec/17)', () {
    final day = LocalDate(2026, 3, 1);
    expect(
      _plan(day, 0, prefs: NotificationPrefs.defaults).map((r) => r.$1).toSet(),
      {suhoor},
    );
  });

  test('A41a fix 2: a city east of the device: the iftar nudge after local '
      'midnight lands on the next device day, never 24 h early', () {
    // Device at UTC−5 (New York in March: −4 after its DST change on
    // 2026-03-08); the city's Maghrib 15:29 UTC + 90 min = 16:59 UTC =
    // 12:59 device time; its Fajr 02:58 UTC − 45 min = 02:13 UTC =
    // 22:13 the evening before on the device.
    final ny = ManualClock(DateTime.utc(2026), offsetMinutes: -240);
    final c = RamadanReminders.candidates(
      calendar: _cal(),
      today: LocalDate(2026, 3, 10),
      prayer: _times,
      clock: ny,
    );
    expect((c[2].date, c[2].minute), (LocalDate(2026, 3, 9), 22 * 60 + 13));
    expect((c[3].date, c[3].minute), (LocalDate(2026, 3, 10), 12 * 60 + 59));
    // A city west of the device: Maghrib 23:00 UTC + 90 min crosses the
    // device's midnight (UTC+2): 02:30 on the next day.
    final c2 = RamadanReminders.candidates(
      calendar: _cal(),
      today: LocalDate(2026, 3, 1),
      prayer: (d) => (
        fajrUtc: DateTime.utc(d.year, d.month, d.day, 10),
        maghribUtc: DateTime.utc(d.year, d.month, d.day, 23),
      ),
      clock: _clock,
    );
    expect((c2[3].date, c2[3].minute), (LocalDate(2026, 3, 2), 2 * 60 + 30));
    expect(c2[3].atUtc, DateTime.utc(2026, 3, 2, 0, 30));
  });

  test('a DST change: the device offset at the reminder instant is used', () {
    // A device that moves from UTC+2 to UTC+3 at 2026-03-01 00:00 UTC.
    final dst = _DstClock(DateTime.utc(2026, 3));
    final c = RamadanReminders.candidates(
      calendar: _cal(),
      today: LocalDate(2026, 2, 28),
      prayer: _times,
      clock: dst,
    );
    // 28 Feb (before): suhoor 02:13 UTC = 04:13; 1 Mar (after): 05:13.
    expect(c[2].minute, 4 * 60 + 13);
    expect(c[4].minute, 5 * 60 + 13);
  });

  test('A41a fix round 2: a replan after the device midnight keeps the '
      "iftar nudge of the city's previous day", () {
    // Ramallah's Maghrib 15:29 UTC + 90 min = 16:59 UTC = 06:59 on the next
    // day for a phone at UTC+14. Replanning at 06:00 on 2 March keeps it.
    final kiritimati = ManualClock(DateTime.utc(2026), offsetMinutes: 14 * 60);
    final rows = _plan(
      LocalDate(2026, 3, 2),
      6 * 60,
      clock: kiritimati,
      prefs: _noQuiet,
    );
    expect(rows.first, (iftar, LocalDate(2026, 3, 2), 6 * 60 + 59));
  });

  test('A41a fix round 2: after the last fasting day, its iftar nudge past '
      'the device midnight is still planned', () {
    final kiritimati = ManualClock(DateTime.utc(2026), offsetMinutes: 14 * 60);
    // Ramadan 1447 ends on 19 March; it is 20 March 06:00 on the phone.
    final rows = _plan(
      LocalDate(2026, 3, 20),
      6 * 60,
      clock: kiritimati,
      prefs: _noQuiet,
    );
    expect(rows, [(iftar, LocalDate(2026, 3, 20), 6 * 60 + 59)]);
  });
}

/// UTC+2 before [change], UTC+3 from it.
final class _DstClock implements Clock {
  new(this.change);

  final DateTime change;

  @override
  DateTime nowUtc() => DateTime.utc(2026);

  @override
  int offsetMinutesAt(DateTime utc) => utc.isBefore(change) ? 120 : 180;
}
