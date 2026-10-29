import 'package:fb_domain/src/time/local_date.dart';

/// How often the user weighs in, for the honesty line (WB-012, A14 D10).
enum CadenceKind {
  /// No weigh-in on or before the day at all.
  none,

  /// 8 or more weigh-in days in the last 28: nothing to say.
  frequent,

  /// 1–7 weigh-in days in the last 28: "the trend updates slowly".
  sparse,

  /// None in the last 28 days, but older ones: "the trend is from {date}".
  stale,
}

/// The weigh-in days of the last 28 days, as of a day (WB-012, A14 D10).
final class WeighInCadence {
  /// See [WeighInCadence.of].
  const new _({
    required this.countLast28,
    required this.lastDate,
    required this.kind,
  });

  /// The cadence as of [today] from the days that have a weigh-in
  /// ([weighInDays], e.g. the trend's day choices; repeats and days after
  /// [today] are ignored). The window is [today] and the 27 days before.
  factory of(Iterable<LocalDate> weighInDays, LocalDate today) {
    final firstInWindow = today.plusDays(1 - windowDays);
    final days = {
      for (final day in weighInDays)
        if (!day.isAfter(today)) day,
    };
    final count = days.where((day) => !day.isBefore(firstInWindow)).length;
    final last = days.isEmpty
        ? null
        : days.reduce((a, b) => a.isAfter(b) ? a : b);
    final kind = last == null
        ? CadenceKind.none
        : count == 0
        ? CadenceKind.stale
        : count < frequentMin
        ? CadenceKind.sparse
        : CadenceKind.frequent;
    return WeighInCadence._(countLast28: count, lastDate: last, kind: kind);
  }

  /// The days the window covers.
  static const int windowDays = 28;

  /// Weigh-in days in the window from which the cadence counts as frequent.
  static const int frequentMin = 8;

  /// Weigh-in days in the window.
  final int countLast28;

  /// The last weigh-in day on or before the day, or `null`.
  final LocalDate? lastDate;

  /// What the honesty line says.
  final CadenceKind kind;

  @override
  bool operator ==(Object other) =>
      other is WeighInCadence &&
      other.countLast28 == countLast28 &&
      other.lastDate == lastDate &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(countLast28, lastDate, kind);

  @override
  String toString() => 'WeighInCadence($kind, $countLast28, $lastDate)';
}

/// When the "weigh in 2–3 times a week" suggestion was shown (a display
/// preference, not user data; A14 D10).
final class CadenceTipState {
  /// Shown last on [shownOn] (`null`: never), and [dismissed] that day.
  const new({this.shownOn, this.dismissed = false});

  /// Never shown.
  static const CadenceTipState initial = CadenceTipState();

  /// The day it was last shown first, or `null`.
  final LocalDate? shownOn;

  /// Whether "Got it" was tapped since [shownOn].
  final bool dismissed;

  /// After it shows on [today]: unchanged when it already showed today,
  /// else shown today and not dismissed.
  CadenceTipState shownToday(LocalDate today) =>
      shownOn == today ? this : CadenceTipState(shownOn: today);

  /// After "Got it".
  CadenceTipState dismiss() =>
      CadenceTipState(shownOn: shownOn, dismissed: true);

  @override
  bool operator ==(Object other) =>
      other is CadenceTipState &&
      other.shownOn == shownOn &&
      other.dismissed == dismissed;

  @override
  int get hashCode => Object.hash(shownOn, dismissed);

  @override
  String toString() => 'CadenceTipState($shownOn, dismissed: $dismissed)';
}

/// Whether the suggestion shows (WB-012 "at most once a month, never as a
/// nag", A14 D10).
abstract final class CadenceTipRule {
  /// The fewest days between two showings.
  static const int intervalDays = 30;

  /// Only with a sparse cadence. On the day it first showed it stays until
  /// dismissed; after that day, not again until [intervalDays] have passed.
  /// A [CadenceTipState.shownOn] after [today] (the clock moved back) counts
  /// as long ago.
  static bool shouldShow(
    CadenceTipState state,
    LocalDate today,
    WeighInCadence cadence,
  ) {
    if (cadence.kind != CadenceKind.sparse) return false;
    final shownOn = state.shownOn;
    if (shownOn == null) return true;
    if (shownOn == today) return !state.dismissed;
    final since = shownOn.daysUntil(today);
    return since < 0 || since >= intervalDays;
  }
}
