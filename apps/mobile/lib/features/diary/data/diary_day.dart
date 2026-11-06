import 'package:fb_domain/fb_domain.dart';

/// Everything the diary shows for one day (A06 §3.3), read in one go.
final class DiaryDay {
  /// The day [date] with its [slots], [groups], [entries] and [mark].
  new({
    required this.date,
    required Iterable<MealSlot> slots,
    required Iterable<DishGroup> groups,
    required Iterable<DiaryEntry> entries,
    this.mark,
  }) : slots = List.unmodifiable(slots),
       groups = List.unmodifiable(groups),
       entries = List.unmodifiable(entries);

  /// The day.
  final LocalDate date;

  /// Every live meal slot, by `sort_order`: the UI picks the ones of the
  /// mode in use. Unmodifiable.
  final List<MealSlot> slots;

  /// The day's live dish groups. Unmodifiable.
  final List<DishGroup> groups;

  /// The day's live entries, by time then ID. Unmodifiable.
  final List<DiaryEntry> entries;

  /// The day's marks, or `null` when it has none.
  final DayMark? mark;

  /// The day's totals (sum of the stored snapshots).
  Nutrients get totals => DiaryTotals.day(entries);

  /// The day's knowledge-aware totals (A62 D8): its entries', or its day
  /// estimate when it has no live food (DY-006, A62 D9, D13).
  IntakeTotals get intake => switch (mark?.estimateKcal) {
    final kcal? when entries.isEmpty => IntakeTotals.ofDayEstimate(kcal),
    _ => DiaryTotals.intake(entries),
  };

  /// Counts only: entries carry user content.
  @override
  String toString() =>
      'DiaryDay($date, ${entries.length} entries, ${groups.length} groups)';
}

/// The stored-precision totals of one day, from the range query (A06 D12),
/// knowledge-aware since A62 (D9): [intake] carries which macros are known
/// and whether an estimate is included. A day with no live food and a day
/// estimate (DY-006) has the estimate as its intake ([dayEstimate]).
final class DailyTotals {
  /// [date] has [entryCount] live entries in [mealCount] meals (distinct
  /// slots; defaults to [entryCount], an upper bound) adding up to fully
  /// known [totals].
  new(LocalDate date, Nutrients totals, int entryCount, {int? mealCount})
    : this.ofIntake(
        date,
        IntakeTotals.known(totals, items: entryCount),
        entryCount,
        mealCount: mealCount,
      );

  /// [date] with [intake] over [entryCount] live entries; [estimateKcal] is
  /// the day mark's stored estimate, if any.
  const new ofIntake(
    this.date,
    this.intake,
    this.entryCount, {
    int? mealCount,
    this.estimateKcal,
  }) : mealCount = mealCount ?? entryCount;

  /// [date] with no live food and a day estimate of [kcal] (A62 D9).
  factory dayEstimate(LocalDate date, double kcal) => DailyTotals.ofIntake(
    date,
    IntakeTotals.ofDayEstimate(kcal),
    0,
    estimateKcal: kcal,
  );

  /// The day.
  final LocalDate date;

  /// The sum of the snapshots with what is known (A62 D9), or the day
  /// estimate on a day with no live food.
  final IntakeTotals intake;

  /// The sum of the snapshots (core five, unknowns as 0): use [intake] for
  /// anything shown or averaged.
  Nutrients get totals => intake.sum;

  /// How many live entries.
  final int entryCount;

  /// How many meals (distinct slots) have them (DY-004's "fewer than 2
  /// meals", A38 D3).
  final int mealCount;

  /// The day mark's stored estimate, kcal, active or superseded by food
  /// (D13), or null. User content.
  final double? estimateKcal;

  /// Whether the day holds a day estimate (active or superseded): it is left
  /// out of the adaptive target (TG-032).
  bool get hasDayEstimate => estimateKcal != null;

  /// Whether the day estimate stands in for the day's food (no live food).
  bool get dayEstimate => entryCount == 0 && estimateKcal != null;

  /// Without the estimate's value.
  @override
  String toString() =>
      'DailyTotals($date, $entryCount entries'
      '${hasDayEstimate ? ', day estimate' : ''})';
}
