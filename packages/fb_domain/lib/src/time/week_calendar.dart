import 'package:fb_domain/src/time/local_date.dart';

/// Weeks that start on a chosen day (LC-021): the user setting, default
/// **Saturday** (D-070).
final class WeekCalendar {
  /// Weeks starting on [weekStart].
  const new({this.weekStart = DayOfWeek.saturday});

  /// The first day of every week.
  final DayOfWeek weekStart;

  /// The first day of the week [date] is in (on or before [date]).
  LocalDate weekStartOf(LocalDate date) =>
      date.plusDays(-((date.weekday.isoNumber - weekStart.isoNumber) % 7));

  /// The week [date] is in: [weekStartOf] to six days later, inclusive.
  ({LocalDate start, LocalDate end}) weekOf(LocalDate date) {
    final start = weekStartOf(date);
    return (start: start, end: start.plusDays(6));
  }

  /// The seven days in week order, starting with [weekStart] (for headers).
  List<DayOfWeek> get daysInOrder => [
    for (var i = 0; i < 7; i++)
      DayOfWeek.fromIso((weekStart.isoNumber - 1 + i) % 7 + 1),
  ];

  @override
  bool operator ==(Object other) =>
      other is WeekCalendar && other.weekStart == weekStart;

  @override
  int get hashCode => weekStart.hashCode;
}
