import 'package:fb_domain/fb_domain.dart';

/// A goal as the user set it (TG-010/011): direction, the expression in
/// canonical kg, and the unit it was typed in (TD-017, D17). Used by setup,
/// "Edit goal" and "Start a new goal". Sensitive: [toString] shows no
/// values.
final class GoalInput {
  /// A [type] goal expressed as [expression], typed in [weightInputUnit]
  /// (`kg` or `lb`, [GoalWeightUnits]).
  const new({
    required this.type,
    required this.expression,
    this.weightInputUnit = MassUnit.kilogram,
  });

  /// Maintain: weekly 0 (PA4).
  factory maintain({MassUnit weightInputUnit = MassUnit.kilogram}) => GoalInput(
    type: GoalType.maintain,
    expression: GoalExpression.weekly(0),
    weightInputUnit: weightInputUnit,
  );

  /// Goal direction.
  final GoalType type;

  /// The expression, canonical kg.
  final GoalExpression expression;

  /// How the goal's weights or rates were typed.
  final MassUnit weightInputUnit;

  /// A new phase record [id] from [start] (revision 1) named [name].
  GoalPhaseRecord toRecord({
    required String id,
    required LocalDate start,
    String? name,
    LocalDate? end,
  }) => GoalPhaseRecord(
    id: id,
    revision: 1,
    name: name,
    start: start,
    end: end,
    type: type,
    expression: expression,
    weightInputUnit: weightInputUnit,
  );

  @override
  String toString() => 'GoalInput(${type.name})';
}

/// The preferences setup offers (D9 page 4), each prefilled from the stored
/// setting; only the ones that differ are written (D10).
final class SetupPreferences {
  /// The chosen values; a null [cityId] means "Not set".
  const new({
    required this.unitSystem,
    required this.weekStart,
    required this.halal,
    this.cityId,
  });

  /// Display units (LC-010).
  final UnitSystem unitSystem;

  /// First day of the week (LC-021).
  final DayOfWeek weekStart;

  /// Halal food preference.
  final bool halal;

  /// The city identity, or null for none.
  final String? cityId;

  @override
  String toString() => 'SetupPreferences';
}

/// Everything setup saves (D9/D10): the profile as typed, the current
/// weight as typed (it becomes the first weigh-in once A14 is wired, and the
/// basis weight of the first target version), the goal and the preferences.
/// Values are canonical (cm, kg) with the typed units kept (TD-017).
/// Sensitive: [toString] shows no values.
final class SetupInput {
  /// The typed setup.
  const new({
    required this.sex,
    required this.birthYear,
    required this.height,
    required this.heightInputUnit,
    required this.weightValue,
    required this.weightUnit,
    required this.activity,
    required this.goal,
    required this.preferences,
    this.goalName,
  });

  /// Formula sex.
  final FormulaSex sex;

  /// Birth year.
  final int birthYear;

  /// Height (cm or ft + in, [Length.feetAndInches]).
  final Length height;

  /// How the height was typed.
  final HeightInputUnit heightInputUnit;

  /// The current weight as typed, in [weightUnit].
  final double weightValue;

  /// `kg` or `lb`.
  final MassUnit weightUnit;

  /// Activity category.
  final ActivityLevel activity;

  /// The first goal.
  final GoalInput goal;

  /// The goal's name, or null for the default label.
  final String? goalName;

  /// Units, week start, halal and city.
  final SetupPreferences preferences;

  /// The current weight, kg.
  double get weightKg => Mass.of(weightValue, weightUnit).kilograms;

  /// The stored profile (canonical cm, typed unit kept).
  ProfileRecord get profile => ProfileRecord(
    sex: sex,
    birthYear: birthYear,
    heightCm: height.centimeters,
    heightInputUnit: heightInputUnit,
    activity: activity,
  );

  @override
  String toString() => 'SetupInput';
}

/// Why a [SetupPreview] has no numbers.
enum SetupPreviewIssue {
  /// A profile, weight or goal field is outside [TargetRules.input].
  invalidInput,

  /// The goal can't be resolved: a deadline not after today, or a target
  /// weight on the wrong side of the current weight (PA3).
  goalUnresolvable,
}

/// The numbers setup's last page shows (D9 page 5), computed by the A12
/// engine: the calculation (TG-021 explanation, cap/floor warnings), the
/// first day's macros and the TG-011 figures, or an [issue] instead.
/// Content-free [toString].
final class SetupPreview {
  new _({
    this.calculation,
    this.goal,
    this.macros,
    this.issue,
    Set<TargetRuleViolation> violations = const {},
  }) : violations = Set.unmodifiable(violations);

  /// Previews [input] on [today].
  factory of(
    SetupInput input,
    LocalDate today, {
    TargetDefaults defaults = const TargetDefaults(),
  }) {
    const rules = TargetRules.input;
    final weightKg = input.weightKg;
    final profileViolations = {
      ...rules.profile(input.profile, today: today),
      if (!rules.weight(weightKg)) TargetRuleViolation.weight,
    };
    if (profileViolations.isNotEmpty) {
      return SetupPreview._(
        issue: SetupPreviewIssue.invalidInput,
        violations: profileViolations,
      );
    }
    final goal = _resolve(input.goal, weightKg, today);
    if (goal == null) {
      return SetupPreview._(issue: SetupPreviewIssue.goalUnresolvable);
    }
    final goalViolations = rules.goalPhase(
      input.goal.toRecord(id: _previewId, start: today, name: input.goalName),
      today: today,
    );
    if (goalViolations.isNotEmpty) {
      return SetupPreview._(
        issue: SetupPreviewIssue.invalidInput,
        violations: goalViolations,
      );
    }
    try {
      final calculation = TargetCalculator.calculate(
        profile: input.profile.toProfile(weightKg),
        goal: goal,
        date: today,
        defaults: defaults,
      );
      final macros = MacroPlan.calculate(
        baseKcal: calculation.kcal,
        weightKg: goal.targetKg ?? weightKg,
        defaults: defaults,
      ).forDay(calculation.kcal);
      return SetupPreview._(
        calculation: calculation,
        goal: goal,
        macros: macros,
      );
    }
    // The engine's content-free signal for an impossible input (D11).
    // ignore: avoid_catching_errors
    on ArgumentError {
      return SetupPreview._(issue: SetupPreviewIssue.invalidInput);
    }
  }

  // The preview never stores this record; the rules only need a v7 shape.
  static const String _previewId = '00000000-0000-7000-8000-000000000000';

  /// The generated calculation (base, floor, rates, projected date,
  /// lossRateCapped / calorieFloorApplied), or null with an [issue].
  final TargetCalculation? calculation;

  /// The resolved goal (requested rate, target weight), or null.
  final ResolvedGoal? goal;

  /// The first day's macro targets (default macro settings), or null.
  final DailyMacros? macros;

  /// Why there are no numbers, or null.
  final SetupPreviewIssue? issue;

  /// The [TargetRules.input] codes behind [SetupPreviewIssue.invalidInput]
  /// (empty when the engine refused). Unmodifiable.
  final Set<TargetRuleViolation> violations;

  /// The daily target, kcal, or null.
  double? get dailyKcal => calculation?.kcal;

  /// The weekly budget (seven equal days before any shifting), or null.
  double? get weeklyKcal => calculation == null ? null : calculation!.kcal * 7;

  /// TG-011: the planned signed change over [month]'s calendar month at the
  /// achievable rate, or null.
  double? monthKg(LocalDate month) => calculation == null
      ? null
      : monthlyKgFromWeeklyRate(calculation!.achievableKgPerWeek, month);

  @override
  String toString() => 'SetupPreview(${issue == null ? 'ok' : issue!.name})';

  static ResolvedGoal? _resolve(
    GoalInput goal,
    double weightKg,
    LocalDate today,
  ) {
    try {
      return ResolvedGoal.resolve(
        type: goal.type,
        expression: goal.expression,
        currentKg: weightKg,
        date: today,
      );
    }
    // The engine's content-free signal for an unresolvable goal (PA3).
    // ignore: avoid_catching_errors
    on ArgumentError {
      return null;
    }
  }
}
