import 'package:fb_domain/fb_domain.dart';

/// What Today's numbers block shows for one day (A13 D12, HM-001–003), as
/// display-rounded numbers: the presentation only formats them.
///
/// [TodayNumbersView.of] picks the mode: [EatenNumbers] when no target
/// settings version is in effect on the day (the layout before targets),
/// [TargetNumbers] otherwise. Content-free [toString].
sealed class TodayNumbersView {
  const new _();

  /// The view of a day that ate [totals] with [targets] (null: no targets
  /// that day).
  static TodayNumbersView of(Nutrients totals, DayTargets? targets) {
    if (targets == null) return EatenNumbers.of(totals);
    final macros = targets.day.macros;
    MacroNumbers macro(double eaten, double? target) => MacroNumbers._(
      eatenGrams: DisplayRounding.nutrientGrams(eaten),
      targetGrams: target == null
          ? null
          : DisplayRounding.macroTargetGrams(target),
    );
    return TargetNumbers._(
      targetKcal: DisplayRounding.kcal(targets.day.kcal),
      eatenKcal: DisplayRounding.kcal(totals.kcal),
      week: switch (targets.week) {
        final week? => WeekLine._(
          kcal: DisplayRounding.kcal(week.kcal),
          uncountedDays: week.uncountedDays,
        ),
        null => null,
      },
      protein: macro(totals.protein, macros.proteinGrams),
      carbs: macro(totals.carbs, macros.carbsGrams),
      fat: macro(totals.fat, macros.fatGrams),
      fiber: macro(totals.fiber, macros.fiberGrams),
    );
  }
}

/// No targets on the day: the calories eaten and the four macros, as before
/// A13 ("kcal eaten").
final class EatenNumbers extends TodayNumbersView {
  /// The eaten numbers of [totals] (also shown when the targets can't be
  /// read).
  factory of(Nutrients totals) => EatenNumbers._(
    eatenKcal: DisplayRounding.kcal(totals.kcal),
    protein: DisplayRounding.nutrientGrams(totals.protein),
    carbs: DisplayRounding.nutrientGrams(totals.carbs),
    fat: DisplayRounding.nutrientGrams(totals.fat),
    fiber: DisplayRounding.nutrientGrams(totals.fiber),
  );

  const new _({
    required this.eatenKcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  }) : super._();

  /// Calories eaten, whole.
  final int eatenKcal;

  /// Grams eaten, display-rounded (`DisplayRounding.nutrientGrams`).
  final double protein;

  /// Grams eaten, display-rounded.
  final double carbs;

  /// Grams eaten, display-rounded.
  final double fat;

  /// Grams eaten, display-rounded.
  final double fiber;

  @override
  String toString() => 'EatenNumbers';
}

/// The day has targets: remaining calories, the bar, the weekly line and the
/// macros against their targets.
final class TargetNumbers extends TodayNumbersView {
  const new _({
    required this.targetKcal,
    required this.eatenKcal,
    required this.week,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  }) : super._();

  /// The day's calorie target, whole (as shown).
  final int targetKcal;

  /// Calories eaten, whole (as shown).
  final int eatenKcal;

  /// The weekly line; null in fixed mode (TG-044).
  final WeekLine? week;

  /// Protein eaten and its target.
  final MacroNumbers protein;

  /// Carbs eaten and its target (none in "calories and protein only").
  final MacroNumbers carbs;

  /// Fat eaten and its target (none in "calories and protein only").
  final MacroNumbers fat;

  /// Fiber eaten and its target.
  final MacroNumbers fiber;

  /// The shown target minus the shown eaten, so the three numbers always
  /// agree (D12); negative when over.
  int get remainingKcal => targetKcal - eatenKcal;

  /// Over the day's target: the big number shows how much, in the neutral
  /// over tone (SF-021).
  bool get over => remainingKcal < 0;

  @override
  String toString() => 'TargetNumbers';
}

/// "This week: X kcal under/over" (A13 D7, HM-002, TG-045).
final class WeekLine {
  const new _({required this.kcal, required this.uncountedDays});

  /// Whole kcal; positive: over, negative: under, 0: on track.
  final int kcal;

  /// Earlier days of the week with unknown intake (TG-032).
  final int uncountedDays;

  @override
  String toString() => 'WeekLine';
}

/// One macro: grams eaten and its target, if it has one (TG-054).
final class MacroNumbers {
  const new _({required this.eatenGrams, required this.targetGrams});

  /// Grams eaten, display-rounded (`DisplayRounding.nutrientGrams`).
  final double eatenGrams;

  /// Whole grams, or null for a macro with no target.
  final int? targetGrams;

  @override
  String toString() => 'MacroNumbers';
}
