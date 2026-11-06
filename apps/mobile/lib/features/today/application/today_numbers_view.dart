import 'package:fb_domain/fb_domain.dart';

/// What Today's numbers block shows for one day (A13 D12, HM-001–003), as
/// display-rounded numbers: the presentation only formats them.
///
/// [TodayNumbersView.of] picks the mode: [EatenNumbers] when no target
/// settings version is in effect on the day (the layout before targets),
/// [TargetNumbers] otherwise. Content-free [toString].
sealed class TodayNumbersView {
  const new _();

  /// The view of a day that ate [intake] with [targets] (null: no targets
  /// that day). "~" and "—" follow [intake] (A62 D16, HM-001): an unknown
  /// macro has no grams, a lower bound or an estimate is approximate.
  static TodayNumbersView of(IntakeTotals intake, DayTargets? targets) {
    if (targets == null) return EatenNumbers.of(intake);
    final macros = targets.day.macros;
    MacroNumbers macro(NutrientField field, double? target) => MacroNumbers._(
      eatenGrams: switch (intake.valueOf(field)) {
        final grams? => DisplayRounding.nutrientGrams(grams),
        null => null,
      },
      approximate: intake.isApproximate(field),
      targetGrams: target == null
          ? null
          : DisplayRounding.macroTargetGrams(target),
    );
    return TargetNumbers._(
      targetKcal: DisplayRounding.kcal(targets.day.kcal),
      eatenKcal: DisplayRounding.kcal(intake.sum.kcal),
      estimated: intake.estimated,
      week: switch (targets.week) {
        final week? => WeekLine._(
          kcal: DisplayRounding.kcal(week.kcal),
          uncountedDays: week.uncountedDays,
          estimated: week.estimated,
        ),
        null => null,
      },
      protein: macro(NutrientField.protein, macros.proteinGrams),
      carbs: macro(NutrientField.carbs, macros.carbsGrams),
      fat: macro(NutrientField.fat, macros.fatGrams),
      fiber: macro(NutrientField.fiber, macros.fiberGrams),
      ramadanMaintain: targets.ramadanMaintain,
    );
  }
}

/// No targets on the day: the calories eaten and the four macros, as before
/// A13 ("kcal eaten").
final class EatenNumbers extends TodayNumbersView {
  /// The eaten numbers of [intake] (also shown when the targets can't be
  /// read).
  factory of(IntakeTotals intake) {
    double? grams(NutrientField f) => switch (intake.valueOf(f)) {
      final g? => DisplayRounding.nutrientGrams(g),
      null => null,
    };
    return EatenNumbers._(
      eatenKcal: DisplayRounding.kcal(intake.sum.kcal),
      estimated: intake.estimated,
      protein: grams(NutrientField.protein),
      carbs: grams(NutrientField.carbs),
      fat: grams(NutrientField.fat),
      fiber: grams(NutrientField.fiber),
      approximate: {
        for (final f in IntakeTotals.unknowable)
          if (intake.isApproximate(f)) f,
      },
    );
  }

  const new _({
    required this.eatenKcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    this.estimated = false,
    this.approximate = const {},
  }) : super._();

  /// Calories eaten, whole.
  final int eatenKcal;

  /// Whether the calories include an estimate ("~").
  final bool estimated;

  /// Grams eaten, display-rounded (`DisplayRounding.nutrientGrams`); null
  /// when unknown ("—").
  final double? protein;

  /// Grams eaten, display-rounded; null when unknown.
  final double? carbs;

  /// Grams eaten, display-rounded; null when unknown.
  final double? fat;

  /// Grams eaten, display-rounded; null when unknown.
  final double? fiber;

  /// The macros shown with "~".
  final Set<NutrientField> approximate;

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
    this.estimated = false,
    this.ramadanMaintain = false,
  }) : super._();

  /// Whether the eaten calories include an estimate ("~", HM-001).
  final bool estimated;

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

  /// The target is maintenance during Ramadan, not the goal's (A41a D8,
  /// #259): the block says so next to it.
  final bool ramadanMaintain;

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
  const new _({
    required this.kcal,
    required this.uncountedDays,
    this.estimated = false,
  });

  /// Whether an earlier counted day includes an estimate (HM-002, "~").
  final bool estimated;

  /// Whole kcal; positive: over, negative: under, 0: on track.
  final int kcal;

  /// Earlier days of the week with unknown intake (TG-032).
  final int uncountedDays;

  @override
  String toString() => 'WeekLine';
}

/// One macro: grams eaten and its target, if it has one (TG-054).
final class MacroNumbers {
  const new _({
    required this.eatenGrams,
    required this.targetGrams,
    this.approximate = false,
  });

  /// Grams eaten, display-rounded (`DisplayRounding.nutrientGrams`); null
  /// when unknown ("—", never 0).
  final double? eatenGrams;

  /// Whether the grams are shown with "~" (a lower bound or an estimate).
  final bool approximate;

  /// Whole grams, or null for a macro with no target.
  final int? targetGrams;

  @override
  String toString() => 'MacroNumbers';
}
