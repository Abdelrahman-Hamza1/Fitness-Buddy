import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/progress/application/progress_period.dart';
import 'package:fb_mobile/features/progress/application/progress_providers.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:intl/intl.dart';

// The Progress tab's words for numbers, dates and periods (A16).

DateTime _dateTime(LocalDate date) => DateTime(date.year, date.month, date.day);

/// Whole kilocalories with grouping ("1,850").
String kcalNumber(AppLocalizations l10n, double kcal) =>
    NumberFormat.decimalPattern(l10n.localeName).format(kcal.round());

/// Whole grams with grouping.
String gramsNumber(AppLocalizations l10n, double grams) =>
    NumberFormat.decimalPattern(l10n.localeName).format(grams.round());

/// A day with its weekday ("Sat, Oct 24" in the locale's order).
String weekdayDate(AppLocalizations l10n, LocalDate date) =>
    DateFormat.MMMEd(l10n.localeName).format(_dateTime(date));

/// A day and month ("Oct 24").
String dayMonth(AppLocalizations l10n, LocalDate date) =>
    DateFormat.MMMd(l10n.localeName).format(_dateTime(date));

/// A range of days ("Sat, Oct 24 – Fri, Oct 30").
String dayRange(AppLocalizations l10n, LocalDate from, LocalDate to) =>
    l10n.progressDateRange(weekdayDate(l10n, from), weekdayDate(l10n, to));

/// The stepper's label of [view]'s period: the week's dates, the month, or
/// the phase's name.
String periodLabel(AppLocalizations l10n, ProgressView view) =>
    switch (view.period) {
      WeekPeriod() => dayRange(l10n, view.from, view.end),
      MonthPeriod(:final year, :final month) => monthYear(
        l10n,
        LocalDate(year, month, 1),
      ),
      PhasePeriod() =>
        view.phase == null
            ? dayRange(l10n, view.from, view.end)
            : goalPhaseLabel(l10n, view.phase!),
    };

/// The label under a bar: the weekday for a week, the day number for a
/// month, the week's first day or the month for longer periods.
String barLabel(
  AppLocalizations l10n,
  LocalDate start,
  ProgressBucketSize size,
  int count,
) {
  final at = _dateTime(start);
  return switch (size) {
    ProgressBucketSize.day when count <= 7 => DateFormat.E(
      l10n.localeName,
    ).format(at),
    ProgressBucketSize.day => DateFormat.d(l10n.localeName).format(at),
    ProgressBucketSize.week => DateFormat.MMMd(l10n.localeName).format(at),
    ProgressBucketSize.month => DateFormat.MMM(l10n.localeName).format(at),
  };
}

/// A bar's name for screen readers and its details: the date, the week or
/// the month.
String bucketName(AppLocalizations l10n, ProgressBucket bucket) =>
    switch (bucket.size) {
      ProgressBucketSize.day => weekdayDate(l10n, bucket.start),
      ProgressBucketSize.week => l10n.progressWeekOf(
        dayMonth(l10n, bucket.start),
      ),
      ProgressBucketSize.month => monthYear(l10n, bucket.start),
    };

/// A calories bar in words (no colour needed, UX-071).
String caloriesBarWords(AppLocalizations l10n, ProgressBucket bucket) {
  final name = bucketName(l10n, bucket);
  final eaten = bucket.avgKcal;
  final target = bucket.avgTargetKcal;
  final base = eaten == null
      ? l10n.progressBarNothing(name)
      : target == null
      ? l10n.progressBarValueNoTarget(name, kcalNumber(l10n, eaten))
      : l10n.progressBarValue(
          name,
          kcalNumber(l10n, eaten),
          kcalNumber(l10n, target),
        );
  return switch (bucket.status) {
    DayStatus.incomplete => l10n.progressBarNotCounted(base),
    DayStatus.inProgress => l10n.progressBarSoFar(base),
    _ => base,
  };
}
