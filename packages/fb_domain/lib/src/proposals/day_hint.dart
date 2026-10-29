import 'package:fb_domain/src/time/day_pager.dart';
import 'package:fb_domain/src/time/local_date.dart';

/// The closed day grammar of a Buddy `dateHint` (B09 D8, contract
/// `BuddyFoodLog.dateHint`): `today`, `yesterday`, `daysAgo:N` (2–999),
/// `lastWeekday:mon…sun` (the most recent such day strictly before today),
/// `date:[YYYY-]MM-DD` (a date the user stated; a missing year is the most
/// recent past occurrence). Resolved on the phone, never by the model.
abstract final class DayHint {
  static final _pattern = RegExp(
    '^(today|yesterday|daysAgo:([2-9]|[1-9][0-9]{1,2})|'
    'lastWeekday:(mon|tue|wed|thu|fri|sat|sun)|'
    r'date:([0-9]{4}-)?(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01]))$',
  );

  static const _weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  /// Whether [hint] is in the grammar (format only).
  static bool isValid(String hint) => _pattern.hasMatch(hint);

  /// The day [hint] names relative to [today], or null when it isn't in the
  /// grammar, names a date that doesn't exist, lies after [today] (the app
  /// rejects future dates, DY-003), or lies outside the diary's reach: more
  /// than [DayPager.defaultMaxDays] back or before 1970-01-01.
  static LocalDate? resolve(String hint, LocalDate today) {
    final day = _resolve(hint, today);
    if (day == null) return null;
    final back = day.daysUntil(today);
    if (back > DayPager.defaultMaxDays || day.epochDay < 0) return null;
    return day;
  }

  static LocalDate? _resolve(String hint, LocalDate today) {
    final m = _pattern.firstMatch(hint);
    if (m == null) return null;
    if (hint == 'today') return today;
    if (hint == 'yesterday') return today.plusDays(-1);
    if (m.group(2) case final n?) return today.plusDays(-int.parse(n));
    if (m.group(3) case final day?) {
      final target = _weekdays.indexOf(day) + 1;
      final back = (today.weekday.isoNumber - target - 1) % 7 + 1;
      return today.plusDays(-back);
    }
    final month = int.parse(m.group(5)!);
    final dayOfMonth = int.parse(m.group(6)!);
    if (m.group(4) case final y?) {
      final year = int.parse(y.substring(0, 4));
      if (!LocalDate.isValid(year, month, dayOfMonth)) return null;
      final date = LocalDate(year, month, dayOfMonth);
      return date.isAfter(today) ? null : date;
    }
    // Most recent past occurrence; 02-29 looks up to 4 years back.
    for (var year = today.year; year >= today.year - 4 && year >= 1; year--) {
      if (!LocalDate.isValid(year, month, dayOfMonth)) continue;
      final date = LocalDate(year, month, dayOfMonth);
      if (!date.isAfter(today)) return date;
    }
    return null;
  }
}
