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

  /// Counts only: entries carry user content.
  @override
  String toString() =>
      'DiaryDay($date, ${entries.length} entries, ${groups.length} groups)';
}

/// The stored-precision totals of one day, from the range query (A06 D12).
final class DailyTotals {
  /// [date] has [entryCount] live entries in [mealCount] meals (distinct
  /// slots; defaults to [entryCount], an upper bound) adding up to
  /// [totals].
  const new(this.date, this.totals, this.entryCount, {int? mealCount})
    : mealCount = mealCount ?? entryCount;

  /// The day.
  final LocalDate date;

  /// The sum of the snapshots (core five).
  final Nutrients totals;

  /// How many live entries.
  final int entryCount;

  /// How many meals (distinct slots) have them (DY-004's "fewer than 2
  /// meals", A38 D3).
  final int mealCount;

  @override
  String toString() => 'DailyTotals($date, $entryCount entries)';
}
