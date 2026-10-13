/// A day of the week, with its ISO 8601 number (Monday = 1 … Sunday = 7).
enum DayOfWeek {
  /// ISO 1.
  monday(1),

  /// ISO 2.
  tuesday(2),

  /// ISO 3.
  wednesday(3),

  /// ISO 4.
  thursday(4),

  /// ISO 5.
  friday(5),

  /// ISO 6.
  saturday(6),

  /// ISO 7.
  sunday(7);

  new(this.isoNumber);

  /// The day with ISO number [isoNumber] (1–7).
  static DayOfWeek fromIso(int isoNumber) {
    if (isoNumber < 1 || isoNumber > 7) {
      throw RangeError.range(isoNumber, 1, 7, 'isoNumber');
    }
    return values[isoNumber - 1];
  }

  /// Monday = 1 … Sunday = 7, as `DateTime.weekday`.
  final int isoNumber;
}

/// A calendar date without a time or a zone, e.g. a diary day
/// (`local_date`, `05` §1). Years 1–9999, so the ISO text is always
/// `YYYY-MM-DD`.
final class LocalDate implements Comparable<LocalDate> {
  /// The date [year]-[month]-[day]. Throws an `ArgumentError` for a date that
  /// doesn't exist (2026-02-30) or a year outside 1–9999.
  new(this.year, this.month, this.day) {
    if (!isValid(year, month, day)) {
      throw ArgumentError('$year-$month-$day is not a date in years 1–9999');
    }
  }

  /// The date [epochDay] days after 1970-01-01 (negative: before).
  new fromEpochDay(int epochDay) : this._fromUtc(_utcOfEpochDay(epochDay));

  new _fromUtc(DateTime utc) : this(utc.year, utc.month, utc.day);

  /// Parses ISO `YYYY-MM-DD` exactly (no time, no zone, no other forms).
  /// Throws a `FormatException` otherwise.
  static LocalDate parse(String text) {
    final date = tryParse(text);
    if (date == null) throw FormatException('not a YYYY-MM-DD date', text);
    return date;
  }

  /// Like [parse], but `null` instead of throwing.
  static LocalDate? tryParse(String text) {
    final match = _iso.matchAsPrefix(text);
    if (match == null || match.end != text.length) return null;
    final [year, month, day] = [
      for (final group in [1, 2, 3]) int.parse(match[group]!),
    ];
    return isValid(year, month, day) ? LocalDate(year, month, day) : null;
  }

  /// Whether [year]-[month]-[day] is a real date in years 1–9999.
  static bool isValid(int year, int month, int day) =>
      year >= 1 &&
      year <= 9999 &&
      month >= 1 &&
      month <= 12 &&
      day >= 1 &&
      day <= 31 &&
      // DateTime.utc rolls 2026-02-30 over to March; a real date doesn't.
      DateTime.utc(year, month, day).month == month;

  static final _iso = RegExp(r'(\d{4})-(\d{2})-(\d{2})');

  /// 0001-01-01 and 9999-12-31 as epoch days.
  static const int _minEpochDay = -719162;
  static const int _maxEpochDay = 2932896;

  static DateTime _utcOfEpochDay(int epochDay) {
    if (epochDay < _minEpochDay || epochDay > _maxEpochDay) {
      throw RangeError.range(epochDay, _minEpochDay, _maxEpochDay, 'epochDay');
    }
    final ms = _msPerDay * epochDay;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  static const int _msPerDay = Duration.millisecondsPerDay;

  /// The year, 1–9999.
  final int year;

  /// The month, 1–12.
  final int month;

  /// The day of the month, 1–31.
  final int day;

  DateTime get _utcMidnight => DateTime.utc(year, month, day);

  /// Days since 1970-01-01 (negative before it).
  int get epochDay => _utcMidnight.millisecondsSinceEpoch ~/ _msPerDay;

  /// The day of the week.
  DayOfWeek get weekday => DayOfWeek.fromIso(_utcMidnight.weekday);

  /// The date [days] later (earlier when negative).
  LocalDate plusDays(int days) => LocalDate.fromEpochDay(epochDay + days);

  /// The number of days from this date to [other] (negative when [other] is
  /// earlier).
  int daysUntil(LocalDate other) => other.epochDay - epochDay;

  /// Whether this date is before [other].
  bool isBefore(LocalDate other) => compareTo(other) < 0;

  /// Whether this date is after [other].
  bool isAfter(LocalDate other) => compareTo(other) > 0;

  @override
  int compareTo(LocalDate other) => year != other.year
      ? year.compareTo(other.year)
      : month != other.month
      ? month.compareTo(other.month)
      : day.compareTo(other.day);

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// ISO `YYYY-MM-DD`, the stored form.
  @override
  String toString() => '${_pad(year, 4)}-${_pad(month, 2)}-${_pad(day, 2)}';
}

String _pad(int value, int width) => value.toString().padLeft(width, '0');
