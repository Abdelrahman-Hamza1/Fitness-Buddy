import 'dart:math' as math;

import 'package:fb_domain/fb_domain.dart';

/// The weight graph's ranges (WB-020, A15 D5). 3M by default.
enum GraphRange {
  /// One calendar month.
  m1(1),

  /// Three months.
  m3(3),

  /// Six months.
  m6(6),

  /// One year.
  y1(12),

  /// The whole history.
  all(null);

  new(this.months);

  /// How many calendar months back, or null for [all].
  final int? months;
}

/// The visible window of a range, in naive wall-clock UTC (A15 PA7).
final class ChartWindow {
  const new _({
    required this.start,
    required this.end,
    required this.panMin,
    required this.panMax,
  });

  /// The window of [range] on [today] (WB-020): it ends today plus
  /// [futureDays] (room for a projection) and starts 1/3/6/12 calendar
  /// months before today (day clamped: 31 March − 1 month = 28/29
  /// February). All runs from [firstDate] to today, at least a month, and
  /// doesn't pan. [panStart] moves a panned window (continuous). Pan bounds
  /// are [firstDate] − 7 days to the window's end.
  factory of(
    GraphRange range,
    LocalDate today, {
    LocalDate? firstDate,
    DateTime? panStart,
    int futureDays = 0,
  }) {
    final end = _utc(today.plusDays(1 + futureDays));
    final monthBack = _minusMonths(today, range.months ?? 1);
    final first = firstDate ?? today;
    final startDate = range == GraphRange.all
        ? (first.isBefore(monthBack) ? first : monthBack)
        : _minusMonths(today, range.months!);
    final start = _utc(startDate);
    final panMin = _utc(first.plusDays(-7));
    final span = end.difference(start);
    if (range == GraphRange.all || panStart == null) {
      return ChartWindow._(
        start: start,
        end: end,
        panMin: range == GraphRange.all ? start : _earlier(panMin, start),
        panMax: end,
      );
    }
    final latest = end.subtract(span);
    final earliest = _earlier(panMin, start);
    final moved = panStart.isBefore(earliest)
        ? earliest
        : panStart.isAfter(latest)
        ? latest
        : panStart;
    return ChartWindow._(
      start: moved,
      end: moved.add(span),
      panMin: earliest,
      panMax: end,
    );
  }

  /// The first moment shown.
  final DateTime start;

  /// The last moment shown.
  final DateTime end;

  /// How far back a drag may go.
  final DateTime panMin;

  /// How far forward a drag may go.
  final DateTime panMax;

  /// Whether the window can pan at all.
  bool get pans => panMin.isBefore(start) || panMax.isAfter(end);

  static DateTime _earlier(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

  static DateTime _utc(LocalDate date) =>
      DateTime.utc(date.year, date.month, date.day);

  static LocalDate _minusMonths(LocalDate date, int months) {
    final index = date.year * 12 + date.month - 1 - months;
    final year = index ~/ 12;
    final month = index % 12 + 1;
    final days = DateTime.utc(year, month + 1, 0).day;
    return LocalDate(year, month, math.min(date.day, days));
  }
}
