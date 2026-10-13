import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/clocks.dart';
import '../helpers/property.dart';

/// London's zone rules for 2026: UTC+1 from 03-29 01:00Z to 10-25 01:00Z.
int _london(DateTime utc) =>
    !utc.isBefore(DateTime.utc(2026, 3, 29, 1)) &&
        utc.isBefore(DateTime.utc(2026, 10, 25, 1))
    ? 60
    : 0;

void main() {
  group('DY-001 local date of an instant:', () {
    test('DY-001 an instant maps to the local calendar date of its offset', () {
      final instant = DateTime.utc(2026, 10, 12, 22, 30);
      expect(localDateOf(instant, 180), LocalDate(2026, 10, 13));
      expect(localDateOf(instant, 0), LocalDate(2026, 10, 12));
      expect(localDateOf(instant, -300), LocalDate(2026, 10, 12));
      expect(
        localDateTimeOf(instant, -300),
        LocalDateTime(LocalDate(2026, 10, 12), hour: 17, minute: 30),
      );
      expect(
        localDateOf(DateTime.utc(2026, 12, 31, 23), 60),
        LocalDate(2027, 1, 1),
      );
    });

    test('DY-001 suhoor at 03:30 counts toward that calendar day (T31)', () {
      // 03:30 in Cairo (UTC+2) on the fasting day 2027-02-10.
      final clock = ManualClock(
        DateTime.utc(2027, 2, 10, 1, 30),
        offsetMinutes: 120,
      );
      final suhoor = EntryTime.now(clock);
      expect(suhoor.localDate, LocalDate(2027, 2, 10));
      expect(suhoor.localDateTime.minuteOfDay, 3 * 60 + 30);
    });

    test('DST: offsetMinutesAt is used for the instant, not "now"', () {
      // Now is summer (UTC+1); the entry is a winter evening (UTC+0).
      final clock = ManualClock(DateTime.utc(2026, 7), zone: _london);
      expect(clock.offsetMinutesAt(clock.nowUtc()), 60);
      final winter = EntryTime.at(DateTime.utc(2026, 1, 15, 23, 30), clock);
      expect(winter.tzOffsetMin, 0);
      expect(winter.localDate, LocalDate(2026, 1, 15));
      // Across the spring change: 00:59Z is still 00:59 local, 01:00Z is
      // 02:00 local.
      final before = EntryTime.at(DateTime.utc(2026, 3, 29, 0, 59), clock);
      final after = EntryTime.at(DateTime.utc(2026, 3, 29, 1), clock);
      expect(before.localDateTime.hour, 0);
      expect(after.localDateTime.hour, 2);
    });
  });

  group('DY-002 entry time keeps its stored offset:', () {
    test('DY-002 an entry keeps its stored local time and date after the '
        'device zone changes', () {
      // Logged in Cairo (UTC+3) at 00:30 local on 2026-10-13.
      final clock = ManualClock(
        DateTime.utc(2026, 10, 12, 21, 30),
        offsetMinutes: 180,
      );
      final entry = EntryTime.now(clock);
      expect(entry.tzOffsetMin, 180);

      // The owner flies to New York (UTC−4); the device zone changes.
      clock
        ..offsetMinutes = -240
        ..utc = DateTime.utc(2026, 10, 20);
      expect(entry.localDate, LocalDate(2026, 10, 13));
      expect(entry.localDateTime.minuteOfDay, 30);

      // The row read back from its columns gives the same day and time.
      final stored = EntryTime(entry.occurredAtUtc, entry.tzOffsetMin);
      expect(stored, entry);
      expect(stored.localDateTime, entry.localDateTime);

      // Only the device's *current* zone would have moved it to 10-12.
      expect(
        EntryTime.at(entry.occurredAtUtc, clock).localDate,
        isNot(entry.localDate),
      );
    });

    test('DY-002 tz offset outside −720…+840 is rejected', () {
      final utc = DateTime.utc(2026, 10, 13);
      expect(EntryTime(utc, -720).tzOffsetMin, -720);
      expect(EntryTime(utc, 840).tzOffsetMin, 840);
      expect(() => EntryTime(utc, -721), throwsArgumentError);
      expect(() => EntryTime(utc, 841), throwsArgumentError);
      expect(() => localDateOf(utc, 900), throwsArgumentError);
      expect(checkTzOffset(330), 330);
      expect(minTzOffsetMinutes, -720);
      expect(maxTzOffsetMinutes, 840);
    });

    test('DY-002 a non-UTC instant is rejected', () {
      final local = DateTime(2026, 10, 13);
      expect(() => EntryTime(local, 0), throwsArgumentError);
      expect(() => localDateTimeOf(local, 0), throwsArgumentError);
    });

    test('entry time equality and text', () {
      final utc = DateTime.utc(2026, 10, 12, 21, 30);
      expect(EntryTime(utc, 180).toString(), '2026-10-13T00:30:00+03:00');
      expect(EntryTime(utc, -30).toString(), '2026-10-12T21:00:00-00:30');
      expect(EntryTime(utc, 345).toString(), '2026-10-13T03:15:00+05:45');
      expect(EntryTime(utc, 180) == EntryTime(utc, 120), isFalse);
      expect(EntryTime(utc, 180).hashCode, EntryTime(utc, 180).hashCode);
    });
  });

  group('LocalDateTime:', () {
    test('fields are validated', () {
      final date = LocalDate(2026, 10, 13);
      expect(() => LocalDateTime(date, hour: 24), throwsRangeError);
      expect(() => LocalDateTime(date, minute: 60), throwsRangeError);
      expect(() => LocalDateTime(date, second: -1), throwsRangeError);
      expect(() => LocalDateTime(date, millisecond: 1000), throwsRangeError);
    });

    test('minute of day, order, equality and ISO text', () {
      final date = LocalDate(2026, 10, 13);
      final dinner = LocalDateTime(date, hour: 19, minute: 45);
      final later = LocalDateTime(date, hour: 19, minute: 45, millisecond: 5);
      expect(dinner.minuteOfDay, 1185);
      expect(dinner.toString(), '2026-10-13T19:45:00');
      expect(later.toString(), '2026-10-13T19:45:00.005');
      expect(dinner.compareTo(later), lessThan(0));
      expect(LocalDateTime(date.plusDays(1)).compareTo(dinner), greaterThan(0));
      expect(dinner, LocalDateTime(date, hour: 19, minute: 45));
      expect(
        dinner.hashCode,
        LocalDateTime(date, hour: 19, minute: 45).hashCode,
      );
      expect(dinner == later, isFalse);
    });
  });

  group('DY-001 property: local date-time of an instant', () {
    Glados2(
      any.intInRange(-2208988800000, 7258118400000), // 1900 … 2200
      any.intInRange(minTzOffsetMinutes, maxTzOffsetMinutes + 1),
      propertyRuns,
    ).test('wall time minus the offset is the instant again', (ms, offset) {
      final instant = utcMillis(ms);
      final local = localDateTimeOf(instant, offset);
      final wall = DateTime.utc(
        local.date.year,
        local.date.month,
        local.date.day,
        local.hour,
        local.minute,
        local.second,
        local.millisecond,
      );
      expect(wall.subtract(Duration(minutes: offset)), instant);
      expect(EntryTime(instant, offset).localDate, local.date);
    });
  });

  test('an instant at the year 1 or 9999 bounds plus an offset throws', () {
    final last = DateTime.utc(9999, 12, 31, 23);
    expect(() => localDateTimeOf(last, 120), throwsArgumentError);
    expect(localDateTimeOf(last, 0).date, LocalDate(9999, 12, 31));
    final first = EntryTime(DateTime.utc(1), -60);
    expect(() => first.localDate, throwsArgumentError);
  });
}
