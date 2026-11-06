import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/nutrition/nutrient_field.dart';
import 'package:fb_domain/src/nutrition/nutrients.dart';

/// How much of a summed nutrient is known (A62 D8, D-096).
enum NutrientCoverage {
  /// Every item gave it: the sum is the value.
  full,

  /// Some items gave it: the sum is a lower bound ("~").
  partial,

  /// No item gave it: unknown ("—"), never 0.
  none,
}

/// A knowledge-aware total of logged food (A62 D8, TD-114): the stored sum
/// (unknown nutrients are stored as 0, W3, so each sum is a true lower
/// bound), which of protein/carbs/fat/fiber every item knew, and whether
/// any item is an estimate. Every display and aggregate of entries reads
/// this, never a bare [Nutrients] sum. kcal is always known.
///
/// Content-free [toString].
final class IntakeTotals {
  const new _({
    required this.sum,
    required this.items,
    required this._unknown,
    required this.estimated,
    this.dayEstimate = false,
  });

  /// [sum] of [items] items that all knew every nutrient; [estimated] when
  /// any of them is an estimate.
  factory known(Nutrients sum, {int items = 1, bool estimated = false}) =>
      IntakeTotals._(
        sum: sum,
        items: items,
        unknown: const {},
        estimated: estimated,
      );

  /// The totals of [entries] at storage precision (`DiaryTotals.day`).
  factory ofEntries(Iterable<DiaryEntry> entries) {
    final list = entries.toList(growable: false);
    return IntakeTotals.ofFoods([for (final e in list) (e.food, e.snapshot)]);
  }

  /// The totals of [foods] (a food with its stored snapshot), rounded to
  /// storage precision after summing.
  factory ofFoods(Iterable<(EntryFood, Nutrients)> foods) {
    final unknown = <NutrientField, int>{};
    var items = 0;
    var estimated = false;
    final snapshots = <Nutrients>[];
    for (final (food, snapshot) in foods) {
      items++;
      snapshots.add(snapshot);
      if (food.provenance.isEstimate) estimated = true;
      for (final field in unknowable) {
        if (!food.known.contains(field)) {
          unknown[field] = (unknown[field] ?? 0) + 1;
        }
      }
    }
    return IntakeTotals._(
      sum: Nutrients.sum(snapshots).rounded(),
      items: items,
      unknown: unknown,
      estimated: estimated,
    );
  }

  /// From SQL aggregates: [items] rows summing to [sum], [estimates] of them
  /// estimates, and per nutrient how many rows didn't know it.
  factory fromCounts({
    required Nutrients sum,
    required int items,
    required int estimates,
    int proteinUnknown = 0,
    int carbsUnknown = 0,
    int fatUnknown = 0,
    int fiberUnknown = 0,
  }) {
    final counts = [proteinUnknown, carbsUnknown, fatUnknown, fiberUnknown];
    if (items < 0 ||
        estimates < 0 ||
        estimates > items ||
        counts.any((c) => c < 0 || c > items)) {
      throw ArgumentError('counts out of range');
    }
    return IntakeTotals._(
      sum: sum,
      items: items,
      unknown: {
        for (final (i, field) in unknowable.indexed)
          if (counts[i] > 0) field: counts[i],
      },
      estimated: estimates > 0,
    );
  }

  /// A day estimate of [kcal] standing for a day with no live food (DY-006,
  /// A62 D9): kcal is the estimate, every macro unknown ("—"), estimated.
  factory ofDayEstimate(double kcal) => IntakeTotals._(
    sum: Nutrients(kcal: kcal, protein: 0, carbs: 0, fat: 0, fiber: 0),
    items: 1,
    unknown: {for (final field in unknowable) field: 1},
    estimated: true,
    dayEstimate: true,
  );

  /// Nothing logged: zero, everything known.
  static final IntakeTotals empty = IntakeTotals.known(
    Nutrients.zero,
    items: 0,
  );

  /// The nutrients that can be unknown (kcal never is).
  static const List<NutrientField> unknowable = [
    NutrientField.protein,
    NutrientField.carbs,
    NutrientField.fat,
    NutrientField.fiber,
  ];

  /// The stored sum: unknowns count as 0, so each value is a lower bound.
  final Nutrients sum;

  /// How many items (entries, saved items, days) were summed.
  final int items;

  final Map<NutrientField, int> _unknown;

  /// Whether any item is an estimate (yours, Buddy's or a day estimate).
  final bool estimated;

  /// Whether a day estimate stands in for a day's food in it (A62b): such
  /// a day has no macro values and is left out of the adaptive target.
  final bool dayEstimate;

  /// How much of [field] is known. kcal and the extras are always full
  /// here (extras keep their own "only when every item has it" rule):
  /// [NutrientCoverage.full].
  NutrientCoverage coverage(NutrientField field) {
    final unknown = _unknown[field] ?? 0;
    if (unknown == 0) return NutrientCoverage.full;
    return unknown >= items ? NutrientCoverage.none : NutrientCoverage.partial;
  }

  /// The value of [field], or null when nothing about it is known.
  double? valueOf(NutrientField field) =>
      coverage(field) == NutrientCoverage.none ? null : sum.valueOf(field);

  /// Whether [field]'s value is only a lower bound (shown with "~").
  bool isLowerBound(NutrientField field) =>
      coverage(field) == NutrientCoverage.partial;

  /// Whether the value of [field] is shown approximate: the total holds an
  /// estimate, or the value is a lower bound.
  bool isApproximate(NutrientField field) => estimated || isLowerBound(field);

  /// Both summed (storage precision).
  IntakeTotals operator +(IntakeTotals other) => IntakeTotals._(
    sum: (sum + other.sum).rounded(),
    items: items + other.items,
    unknown: {
      for (final field in unknowable)
        if ((_unknown[field] ?? 0) + (other._unknown[field] ?? 0) case final n
            when n > 0)
          field: n,
    },
    estimated: estimated || other.estimated,
    dayEstimate: dayEstimate || other.dayEstimate,
  );

  /// The sum of [all], [empty] without any.
  static IntakeTotals sumOf(Iterable<IntakeTotals> all) =>
      all.fold(empty, (a, b) => a + b);

  @override
  bool operator ==(Object other) =>
      other is IntakeTotals &&
      other.sum == sum &&
      other.items == items &&
      other.estimated == estimated &&
      other.dayEstimate == dayEstimate &&
      unknowable.every((f) => other._unknown[f] == _unknown[f]);

  @override
  int get hashCode => Object.hash(
    sum,
    items,
    estimated,
    dayEstimate,
    Object.hashAll([for (final f in unknowable) _unknown[f]]),
  );

  /// Coverage only: no values.
  @override
  String toString() =>
      'IntakeTotals($items items${estimated ? ', estimated' : ''}, '
      '${[for (final f in unknowable) coverage(f).name].join('/')})';
}

/// Averages of a group of days (A62 D10): kcal over the counted days, each
/// macro over the days that knew it fully (null without one), and whether
/// any day was estimated. For a single day, [lowerBound] names the macros
/// that are only lower bounds.
///
/// Content-free [toString].
final class IntakeAverages {
  /// The averages.
  new({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    this.estimated = false,
    Set<NutrientField> lowerBound = const {},
  }) : lowerBound = Set.unmodifiable(lowerBound);

  /// One day's [intake]: unknown macros are null, partial ones flagged.
  factory ofDay(IntakeTotals intake) => IntakeAverages(
    kcal: intake.sum.kcal,
    protein: intake.valueOf(NutrientField.protein),
    carbs: intake.valueOf(NutrientField.carbs),
    fat: intake.valueOf(NutrientField.fat),
    fiber: intake.valueOf(NutrientField.fiber),
    estimated: intake.estimated,
    lowerBound: {
      for (final f in IntakeTotals.unknowable)
        if (intake.isLowerBound(f)) f,
    },
  );

  /// The mean of [days]: kcal over all of them, each macro over the days
  /// whose coverage is full (partial and none are left out, never 0).
  /// Null without a day.
  static IntakeAverages? over(Iterable<IntakeTotals> days) {
    final list = days.toList(growable: false);
    if (list.isEmpty) return null;
    double? mean(NutrientField field) {
      var sum = 0.0;
      var n = 0;
      for (final day in list) {
        if (day.coverage(field) != NutrientCoverage.full) continue;
        sum += day.sum.valueOf(field)!;
        n++;
      }
      return n == 0 ? null : sum / n;
    }

    return IntakeAverages(
      kcal: list.fold<double>(0, (s, d) => s + d.sum.kcal) / list.length,
      protein: mean(NutrientField.protein),
      carbs: mean(NutrientField.carbs),
      fat: mean(NutrientField.fat),
      fiber: mean(NutrientField.fiber),
      estimated: list.any((d) => d.estimated),
    );
  }

  /// Calories.
  final double? kcal;

  /// Protein, g; null when unknown.
  final double? protein;

  /// Carbs, g; null when unknown.
  final double? carbs;

  /// Fat, g; null when unknown.
  final double? fat;

  /// Fiber, g; null when unknown.
  final double? fiber;

  /// Whether an estimate is included ("~").
  final bool estimated;

  /// Macros whose value is only a lower bound (single days).
  final Set<NutrientField> lowerBound;

  /// The value of [field] (core five), or null.
  double? valueOf(NutrientField field) => switch (field) {
    NutrientField.kcal => kcal,
    NutrientField.protein => protein,
    NutrientField.carbs => carbs,
    NutrientField.fat => fat,
    NutrientField.fiber => fiber,
    _ => null,
  };

  /// Whether [field] is shown approximate ("~").
  bool isApproximate(NutrientField field) =>
      estimated || lowerBound.contains(field);

  @override
  String toString() => 'IntakeAverages${estimated ? '(estimated)' : ''}';
}
