import 'package:fb_domain/src/time/clock.dart';
import 'package:fb_domain/src/time/local_date.dart';

/// The smallest UTC offset a zone has, in minutes (UTC−12:00).
const int minTzOffsetMinutes = -720;

/// The largest UTC offset a zone has, in minutes (UTC+14:00).
const int maxTzOffsetMinutes = 840;

/// [minutes] if it is a real zone offset (−720…+840), else an
/// `ArgumentError` (S08 D7).
int checkTzOffset(int minutes) {
  if (minutes < minTzOffsetMinutes || minutes > maxTzOffsetMinutes) {
    throw ArgumentError.value(
      minutes,
      'tzOffsetMin',
      'must be $minTzOffsetMinutes…$maxTzOffsetMinutes',
    );
  }
  return minutes;
}

/// A wall-clock time of day without a date or a zone, e.g. the time a meal
/// was eaten (DY-002).
final class LocalTime implements Comparable<LocalTime> {
  /// [hour]:[minute]:[second].[millisecond]. Throws a `RangeError` for a
  /// field out of range.
  new(this.hour, [this.minute = 0, this.second = 0, this.millisecond = 0]) {
    _checkRange(hour, 23, 'hour');
    _checkRange(minute, 59, 'minute');
    _checkRange(second, 59, 'second');
    _checkRange(millisecond, 999, 'millisecond');
  }

  /// The start of the minute [minuteOfDay] (0–1439) after midnight.
  new ofMinuteOfDay(int minuteOfDay)
    : this(
        _checkRange(minuteOfDay, minutesPerDay - 1, 'minuteOfDay') ~/ 60,
        minuteOfDay % 60,
      );

  /// Minutes in a day.
  static const int minutesPerDay = 1440;

  /// Midnight, 00:00.
  static final LocalTime midnight = LocalTime(0);

  /// The hour, 0–23.
  final int hour;

  /// The minute, 0–59.
  final int minute;

  /// The second, 0–59.
  final int second;

  /// The millisecond, 0–999.
  final int millisecond;

  /// Minutes since midnight, 0–1439 (e.g. for meal-slot windows).
  int get minuteOfDay => hour * 60 + minute;

  /// Milliseconds since midnight.
  int get millisOfDay =>
      ((hour * 60 + minute) * 60 + second) * 1000 + millisecond;

  /// This time on [date].
  LocalDateTime on(LocalDate date) => LocalDateTime(
    date,
    hour: hour,
    minute: minute,
    second: second,
    millisecond: millisecond,
  );

  @override
  int compareTo(LocalTime other) => millisOfDay.compareTo(other.millisOfDay);

  @override
  bool operator ==(Object other) =>
      other is LocalTime && other.millisOfDay == millisOfDay;

  @override
  int get hashCode => millisOfDay.hashCode;

  /// ISO `HH:MM:SS`, plus `.mmm` when the milliseconds aren't 0.
  @override
  String toString() {
    final text = '${_pad(hour)}:${_pad(minute)}:${_pad(second)}';
    return millisecond == 0
        ? text
        : '$text.${millisecond.toString().padLeft(3, '0')}';
  }
}

/// A wall-clock date and time without a zone: what a clock on the wall
/// showed where something happened.
final class LocalDateTime implements Comparable<LocalDateTime> {
  /// [date] at [hour]:[minute]:[second].[millisecond]. Throws an
  /// `ArgumentError` for a field out of range.
  new(
    this.date, {
    this.hour = 0,
    this.minute = 0,
    this.second = 0,
    this.millisecond = 0,
  }) {
    _checkRange(hour, 23, 'hour');
    _checkRange(minute, 59, 'minute');
    _checkRange(second, 59, 'second');
    _checkRange(millisecond, 999, 'millisecond');
  }

  /// The calendar date.
  final LocalDate date;

  /// The hour, 0–23.
  final int hour;

  /// The minute, 0–59.
  final int minute;

  /// The second, 0–59.
  final int second;

  /// The millisecond, 0–999.
  final int millisecond;

  /// The time of day.
  LocalTime get time => LocalTime(hour, minute, second, millisecond);

  /// Minutes since local midnight, 0–1439 (e.g. for meal-slot windows).
  int get minuteOfDay => hour * 60 + minute;

  int get _millisOfDay => time.millisOfDay;

  /// This wall-clock time read as if it were UTC (no offset applied).
  DateTime get _asUtc => DateTime.utc(
    date.year,
    date.month,
    date.day,
    hour,
    minute,
    second,
    millisecond,
  );

  @override
  int compareTo(LocalDateTime other) {
    final byDate = date.compareTo(other.date);
    return byDate != 0 ? byDate : _millisOfDay.compareTo(other._millisOfDay);
  }

  @override
  bool operator ==(Object other) =>
      other is LocalDateTime &&
      other.date == date &&
      other._millisOfDay == _millisOfDay;

  @override
  int get hashCode => Object.hash(date, _millisOfDay);

  /// ISO `YYYY-MM-DDTHH:MM:SS`, plus `.mmm` when the milliseconds aren't 0.
  @override
  String toString() => '${date}T$time';
}

/// The wall-clock date and time of the UTC instant [utc] in a zone that is
/// [tzOffsetMin] minutes ahead of UTC (DY-001). Milliseconds are kept,
/// microseconds dropped. Throws an `ArgumentError` when the wall-clock time
/// falls outside the years 1–9999 that `LocalDate` holds (an instant at
/// those bounds plus the offset).
LocalDateTime localDateTimeOf(DateTime utc, int tzOffsetMin) {
  _checkUtc(utc, 'utc');
  final wall = utc.add(Duration(minutes: checkTzOffset(tzOffsetMin)));
  return LocalDateTime(
    LocalDate(wall.year, wall.month, wall.day),
    hour: wall.hour,
    minute: wall.minute,
    second: wall.second,
    millisecond: wall.millisecond,
  );
}

/// The calendar date the UTC instant [utc] falls on in a zone that is
/// [tzOffsetMin] minutes ahead of UTC: the diary day (DY-001). Food eaten
/// after local midnight, suhoor included, belongs to the new date.
LocalDate localDateOf(DateTime utc, int tzOffsetMin) =>
    localDateTimeOf(utc, tzOffsetMin).date;

/// When something happened: the instant plus the zone offset in effect
/// where it happened (`occurred_at_utc` + `tz_offset_min`, `05` §1).
///
/// The local date and time come from the **stored** offset, never from the
/// device's current zone, so travelling doesn't move past entries (DY-002).
final class EntryTime {
  /// [occurredAtUtc] (a UTC `DateTime`) with the offset [tzOffsetMin]
  /// (−720…+840) it happened in. Throws an `ArgumentError` otherwise.
  ///
  /// [localDateTime] and [localDate] throw an `ArgumentError` when the
  /// instant plus the offset falls outside the years 1–9999 (see
  /// [localDateTimeOf]).
  new(this.occurredAtUtc, this.tzOffsetMin) {
    _checkUtc(occurredAtUtc, 'occurredAtUtc');
    checkTzOffset(tzOffsetMin);
  }

  /// [occurredAtUtc] with the device zone's offset **at that instant**
  /// (right across DST), from [clock].
  new at(DateTime occurredAtUtc, Clock clock)
    : this(occurredAtUtc, clock.offsetMinutesAt(occurredAtUtc));

  /// Now, in the device's zone, from [clock].
  new now(Clock clock) : this.at(clock.nowUtc(), clock);

  /// The wall-clock time [local] in a zone [tzOffsetMin] minutes ahead of
  /// UTC: the instant is `local − offset`. Used to edit a stored entry with
  /// its own stored offset (A06 D6).
  new local(LocalDateTime local, int tzOffsetMin)
    : this(
        local._asUtc.subtract(Duration(minutes: checkTzOffset(tzOffsetMin))),
        tzOffsetMin,
      );

  /// The wall-clock time [local] in the device's zone, with the offset in
  /// effect at that instant (A06 D6), from [clock].
  ///
  /// DST edges resolve deterministically, like `java.time`:
  /// - **overlap** (the wall time happens twice, clocks go back): the
  ///   earlier instant, with the offset from before the change;
  /// - **gap** (the wall time doesn't exist, clocks go forward): the
  ///   instant at the offset from before the change, so the wall time moves
  ///   forward by the gap (02:30 in a 02:00→03:00 gap becomes 03:30).
  ///
  /// Assumes at most one offset change within a day of [local].
  factory fromLocal(LocalDateTime local, Clock clock) {
    final wall = local._asUtc;
    const day = Duration(days: 1);
    final before = clock.offsetMinutesAt(wall.subtract(day));
    final after = clock.offsetMinutesAt(wall.add(day));
    DateTime instantAt(int offset) => wall.subtract(Duration(minutes: offset));
    bool fits(int offset) => clock.offsetMinutesAt(instantAt(offset)) == offset;
    // The earlier instant first (the larger offset), so an overlap picks it.
    final offsets = before >= after ? [before, after] : [after, before];
    for (final offset in offsets) {
      if (fits(offset)) return EntryTime(instantAt(offset), offset);
    }
    // A gap: the offset from before the change, then that instant's offset.
    final instant = instantAt(before);
    return EntryTime(instant, clock.offsetMinutesAt(instant));
  }

  /// The instant, in UTC.
  final DateTime occurredAtUtc;

  /// The zone offset in minutes ahead of UTC where it happened.
  final int tzOffsetMin;

  /// The wall-clock date and time where it happened.
  LocalDateTime get localDateTime =>
      localDateTimeOf(occurredAtUtc, tzOffsetMin);

  /// The diary day it belongs to (`local_date`).
  LocalDate get localDate => localDateTime.date;

  /// The same date at the local time [time], with the same stored offset
  /// (a time edit, A06 D6).
  EntryTime withLocalTime(LocalTime time) =>
      EntryTime.local(time.on(localDate), tzOffsetMin);

  /// The same local time of day on [date], with the same stored offset
  /// (a day move or a copy, A06 D6/D9).
  EntryTime onDate(LocalDate date) =>
      EntryTime.local(localDateTime.time.on(date), tzOffsetMin);

  @override
  bool operator ==(Object other) =>
      other is EntryTime &&
      other.occurredAtUtc == occurredAtUtc &&
      other.tzOffsetMin == tzOffsetMin;

  @override
  int get hashCode => Object.hash(occurredAtUtc, tzOffsetMin);

  @override
  String toString() {
    final sign = tzOffsetMin < 0 ? '-' : '+';
    final abs = tzOffsetMin.abs();
    return '$localDateTime$sign${_pad(abs ~/ 60)}:${_pad(abs % 60)}';
  }
}

void _checkUtc(DateTime value, String name) {
  if (!value.isUtc) throw ArgumentError.value(value, name, 'must be UTC');
}

int _checkRange(int value, int max, String name) {
  if (value < 0 || value > max) throw RangeError.range(value, 0, max, name);
  return value;
}

String _pad(int value) => value.toString().padLeft(2, '0');
