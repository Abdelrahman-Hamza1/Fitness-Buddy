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

  /// Minutes since local midnight, 0–1439 (e.g. for meal-slot windows).
  int get minuteOfDay => hour * 60 + minute;

  int get _millisOfDay =>
      ((hour * 60 + minute) * 60 + second) * 1000 + millisecond;

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
  String toString() {
    final time = '${_pad(hour)}:${_pad(minute)}:${_pad(second)}';
    final millis = millisecond == 0
        ? ''
        : '.${millisecond.toString().padLeft(3, '0')}';
    return '${date}T$time$millis';
  }
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

  /// The instant, in UTC.
  final DateTime occurredAtUtc;

  /// The zone offset in minutes ahead of UTC where it happened.
  final int tzOffsetMin;

  /// The wall-clock date and time where it happened.
  LocalDateTime get localDateTime =>
      localDateTimeOf(occurredAtUtc, tzOffsetMin);

  /// The diary day it belongs to (`local_date`).
  LocalDate get localDate => localDateTime.date;

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

void _checkRange(int value, int max, String name) {
  if (value < 0 || value > max) throw RangeError.range(value, 0, max, name);
}

String _pad(int value) => value.toString().padLeft(2, '0');
