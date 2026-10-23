import 'package:fb_domain/src/time/clock.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/time/local_time.dart';

/// Bounded ascending diary pages, with no future days (HM-009).
final class DayPager {
  /// Ten years of history by default.
  new(this.today, {this.maxDays = 3650}) {
    if (maxDays < 0) throw ArgumentError.value(maxDays, 'maxDays');
  }

  /// The latest allowed date.
  final LocalDate today;

  /// History bound in calendar days.
  final int maxDays;

  /// Includes today.
  int get pageCount => maxDays + 1;

  /// Dates outside the history window clamp to its ends.
  int indexOf(LocalDate date) =>
      (maxDays - date.daysUntil(today)).clamp(0, maxDays);

  /// Clamps indices to the available pages.
  LocalDate dateAt(int index) =>
      today.plusDays(index.clamp(0, maxDays) - maxDays);

  /// Whether a next date is available.
  bool canGoNext(LocalDate date) => date.isBefore(today);

  /// At most three days, bounded by both history and today.
  Set<LocalDate> window(LocalDate viewed) {
    final index = indexOf(viewed);
    return Set.unmodifiable({
      for (var i = index - 1; i <= index + 1; i++)
        if (i >= 0 && i < pageCount) dateAt(i),
    });
  }
}

/// Resolves tomorrow's midnight using its offset, including DST (DY-001).
DateTime nextDayStartUtc(LocalDate today, Clock clock) => EntryTime.fromLocal(
  LocalTime.midnight.on(today.plusDays(1)),
  clock,
).occurredAtUtc;
