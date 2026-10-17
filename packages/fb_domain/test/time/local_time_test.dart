import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:glados/glados.dart';

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

  group('LocalTime:', () {
    test('fields are validated; minute of day round trip', () {
      expect(() => LocalTime(24), throwsRangeError);
      expect(() => LocalTime(0, 60), throwsRangeError);
      expect(() => LocalTime(0, 0, 60), throwsRangeError);
      expect(() => LocalTime(0, 0, 0, 1000), throwsRangeError);
      expect(() => LocalTime.ofMinuteOfDay(1440), throwsRangeError);
      expect(() => LocalTime.ofMinuteOfDay(-1), throwsRangeError);
      expect(LocalTime.ofMinuteOfDay(1185), LocalTime(19, 45));
      expect(LocalTime(19, 45).minuteOfDay, 1185);
      expect(LocalTime(0, 0, 1, 5).millisOfDay, 1005);
      expect(LocalTime.midnight, LocalTime(0));
      expect(LocalTime.minutesPerDay, 1440);
    });

    test('order, equality, text and date', () {
      final a = LocalTime(8, 5);
      final b = LocalTime(8, 5, 0, 1);
      expect(a.compareTo(b), lessThan(0));
      expect(a, LocalTime(8, 5));
      expect(a.hashCode, LocalTime(8, 5).hashCode);
      expect(a == b, isFalse);
      expect('$a', '08:05:00');
      expect('$b', '08:05:00.001');
      final date = LocalDate(2026, 10, 13);
      expect(
        b.on(date),
        LocalDateTime(date, hour: 8, minute: 5, millisecond: 1),
      );
      expect(b.on(date).time, b);
    });
  });

  group('DY-002 EntryTime from a local time:', () {
    test('EntryTime.local subtracts the given offset', () {
      final local = LocalDateTime(LocalDate(2026, 10, 13), minute: 30);
      final time = EntryTime.local(local, 180);
      expect(time.occurredAtUtc, DateTime.utc(2026, 10, 12, 21, 30));
      expect(time.tzOffsetMin, 180);
      expect(time.localDateTime, local);
      expect(() => EntryTime.local(local, 900), throwsArgumentError);
    });

    test('DY-001 an entry at 00:30 (and suhoor at 03:30) belongs to the new '
        'calendar day', () {
      final clock = ManualClock(
        DateTime.utc(2027, 2, 10, 12),
        offsetMinutes: 120,
      );
      final day = LocalDate(2027, 2, 10);
      final late = EntryTime.fromLocal(LocalDateTime(day, minute: 30), clock);
      expect(late.localDate, day);
      expect(late.occurredAtUtc, DateTime.utc(2027, 2, 9, 22, 30));
      final suhoor = EntryTime.fromLocal(
        LocalDateTime(day, hour: 3, minute: 30),
        clock,
      );
      expect(suhoor.localDate, day);
      expect(suhoor.occurredAtUtc, DateTime.utc(2027, 2, 10, 1, 30));
    });

    test('DY-002 EntryTime.fromLocal uses the offset at that instant; DST gap '
        'and overlap resolve deterministically', () {
      final clock = ManualClock(DateTime.utc(2026, 7), zone: _london);
      EntryTime at(int month, int day, int hour, [int minute = 0]) =>
          EntryTime.fromLocal(
            LocalDateTime(
              LocalDate(2026, month, day),
              hour: hour,
              minute: minute,
            ),
            clock,
          );
      // Plain summer and winter times.
      expect(at(7, 1, 12), EntryTime(DateTime.utc(2026, 7, 1, 11), 60));
      expect(at(1, 15, 12), EntryTime(DateTime.utc(2026, 1, 15, 12), 0));
      // The day before the spring change, far from it.
      expect(at(3, 28, 12), EntryTime(DateTime.utc(2026, 3, 28, 12), 0));
      // Gap (01:00–02:00 on 03-29 doesn't exist): moves forward by the gap.
      final gap = at(3, 29, 1, 30);
      expect(gap, EntryTime(DateTime.utc(2026, 3, 29, 1, 30), 60));
      expect(gap.localDateTime.time, LocalTime(2, 30));
      expect(at(3, 29, 1).localDateTime.time, LocalTime(2));
      expect(at(3, 29, 0, 59), EntryTime(DateTime.utc(2026, 3, 29, 0, 59), 0));
      expect(at(3, 29, 2), EntryTime(DateTime.utc(2026, 3, 29, 1), 60));
      // Overlap (01:00–02:00 on 10-25 happens twice): the earlier instant.
      final overlap = at(10, 25, 1, 30);
      expect(overlap, EntryTime(DateTime.utc(2026, 10, 25, 0, 30), 60));
      expect(overlap.localDateTime.time, LocalTime(1, 30));
      expect(
        at(10, 25, 0, 59),
        EntryTime(DateTime.utc(2026, 10, 24, 23, 59), 60),
      );
      expect(at(10, 25, 2), EntryTime(DateTime.utc(2026, 10, 25, 2), 0));
      // The same input gives the same result.
      expect(at(10, 25, 1, 30), overlap);
    });

    test("DY-002 a stored entry's local date and time don't change when the "
        "clock's zone changes", () {
      final clock = ManualClock(DateTime.utc(2026, 10, 13), offsetMinutes: 180);
      final local = LocalDateTime(
        LocalDate(2026, 10, 13),
        hour: 13,
        minute: 15,
      );
      final stored = EntryTime.fromLocal(local, clock);
      clock
        ..offsetMinutes = -240
        ..utc = DateTime.utc(2026, 11);
      expect(stored.localDateTime, local);
      expect(
        EntryTime(stored.occurredAtUtc, stored.tzOffsetMin).localDateTime,
        local,
      );
      // Edits keep the stored offset, not the device's new zone.
      final edited = stored.withLocalTime(LocalTime(19));
      expect(edited.tzOffsetMin, 180);
      expect(
        edited.localDateTime,
        LocalDateTime(LocalDate(2026, 10, 13), hour: 19),
      );
      final moved = stored.onDate(LocalDate(2026, 10, 10));
      expect(moved.tzOffsetMin, 180);
      expect(
        moved.localDateTime,
        LocalDateTime(LocalDate(2026, 10, 10), hour: 13, minute: 15),
      );
      expect(moved.occurredAtUtc, DateTime.utc(2026, 10, 10, 10, 15));
    });

    Glados2(
      any.intInRange(-2208988800000, 7258118400000), // 1900 … 2200
      any.intInRange(minTzOffsetMinutes, maxTzOffsetMinutes + 1),
      propertyRuns,
    ).test('property: DY-002 fromLocal inverts the wall time in a fixed zone', (
      ms,
      offset,
    ) {
      final instant = utcMillis(ms);
      final clock = ManualClock(instant, offsetMinutes: offset);
      final local = localDateTimeOf(instant, offset);
      expect(EntryTime.fromLocal(local, clock), EntryTime(instant, offset));
      expect(EntryTime.local(local, offset), EntryTime(instant, offset));
    });

    Glados(
      any.intInRange(
        DateTime.utc(2026).millisecondsSinceEpoch,
        DateTime.utc(2027).millisecondsSinceEpoch,
      ),
      propertyRuns,
    ).test('property: DY-002 fromLocal across DST gives the same wall time, '
        'the earlier instant in an overlap', (ms) {
      final clock = ManualClock(DateTime.utc(2026), zone: _london);
      final original = EntryTime.at(utcMillis(ms), clock);
      final local = original.localDateTime;
      final back = EntryTime.fromLocal(local, clock);
      expect(back.localDateTime, local);
      final earlierBy = original.occurredAtUtc.difference(back.occurredAtUtc);
      expect(earlierBy, anyOf(Duration.zero, const Duration(hours: 1)));
    });
  });
}
