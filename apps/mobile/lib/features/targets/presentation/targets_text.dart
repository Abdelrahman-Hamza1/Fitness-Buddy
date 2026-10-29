import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/targets/application/target_form_input.dart';
import 'package:intl/intl.dart';

// Words for targets values (A13b WP5), shared by setup, Today, Me and the
// progress charts (A15 PA9: `goalTypeLabel` is exported from the targets
// barrel). Numbers are rounded here for display only; nothing is written.

/// The name of a goal direction: "Lose weight" (TG-010). Also the default
/// name of a phase without one (A10 D10 pattern).
String goalTypeLabel(AppLocalizations l10n, GoalType type) => switch (type) {
  GoalType.lose => l10n.goalTypeLose,
  GoalType.maintain => l10n.goalTypeMaintain,
  GoalType.gain => l10n.goalTypeGain,
};

/// A phase's name: its own, else the default label of its direction.
String goalPhaseLabel(AppLocalizations l10n, GoalPhaseRecord phase) =>
    phase.name ?? goalTypeLabel(l10n, phase.type);

/// The name of an activity level ("Moderately active", TG-001).
String activityLabel(AppLocalizations l10n, ActivityLevel level) =>
    switch (level) {
      ActivityLevel.sedentary => l10n.profileActivitySedentary,
      ActivityLevel.light => l10n.profileActivityLight,
      ActivityLevel.moderate => l10n.profileActivityModerate,
      ActivityLevel.high => l10n.profileActivityHigh,
    };

/// The plain description of an activity level.
String activityDescription(AppLocalizations l10n, ActivityLevel level) =>
    switch (level) {
      ActivityLevel.sedentary => l10n.profileActivitySedentaryHint,
      ActivityLevel.light => l10n.profileActivityLightHint,
      ActivityLevel.moderate => l10n.profileActivityModerateHint,
      ActivityLevel.high => l10n.profileActivityHighHint,
    };

/// An activity level inside a sentence ("moderately active").
String activityInline(AppLocalizations l10n, ActivityLevel level) =>
    switch (level) {
      ActivityLevel.sedentary => l10n.profileActivityShortSedentary,
      ActivityLevel.light => l10n.profileActivityShortLight,
      ActivityLevel.moderate => l10n.profileActivityShortModerate,
      ActivityLevel.high => l10n.profileActivityShortHigh,
    };

/// The name of a formula sex.
String sexLabel(AppLocalizations l10n, FormulaSex sex) => switch (sex) {
  FormulaSex.male => l10n.profileSexMale,
  FormulaSex.female => l10n.profileSexFemale,
};

/// The word of a body-weight unit ("kg" or "lb").
String massUnitLabel(AppLocalizations l10n, MassUnit unit) =>
    unit == MassUnit.pound ? l10n.unitLb : l10n.unitKg;

/// [value] with at most [decimals] decimals (ties away from zero) and the
/// locale's grouping: "1,102.3", "0.46".
String targetsNumber(AppLocalizations l10n, double value, {int decimals = 1}) {
  final format = NumberFormat.decimalPattern(l10n.localeName)
    ..minimumFractionDigits = 0
    ..maximumFractionDigits = decimals;
  return format.format(roundHalfAwayFromZero(value, decimals));
}

/// A weight or weight change of [kg] in [unit]: "0.46 kg", "1 lb". With
/// [signed], a loss starts with a minus sign and a gain with a plus
/// ("−2 kg", "+0.5 kg").
String massText(
  AppLocalizations l10n,
  double kg,
  MassUnit unit, {
  int decimals = 1,
  bool signed = false,
}) {
  final value = Mass.kilograms(kg).inUnit(unit);
  final number = targetsNumber(l10n, value.abs(), decimals: decimals);
  final rounded = roundHalfAwayFromZero(value, decimals);
  final sign = !signed || rounded == 0
      ? ''
      : rounded < 0
      ? '\u2212' // minus sign
      : '+';
  return l10n.targetsMassValue('$sign$number', massUnitLabel(l10n, unit));
}

/// A weekly rate of [kgPerWeek] in [unit], two decimals: "0.46 kg".
String rateText(
  AppLocalizations l10n,
  double kgPerWeek,
  MassUnit unit, {
  bool signed = false,
}) => massText(l10n, kgPerWeek, unit, decimals: 2, signed: signed);

/// [month]'s name ("November").
String monthName(AppLocalizations l10n, LocalDate month) =>
    DateFormat.MMMM(l10n.localeName).format(_dateTime(month));

/// [date] as month and year ("March 2027").
String monthYear(AppLocalizations l10n, LocalDate date) =>
    DateFormat.yMMMM(l10n.localeName).format(_dateTime(date));

/// [date] as a short date ("30 Apr 2027" in the locale's order).
String shortDate(AppLocalizations l10n, LocalDate date) =>
    DateFormat.yMMMd(l10n.localeName).format(_dateTime(date));

DateTime _dateTime(LocalDate date) => DateTime(date.year, date.month, date.day);

/// The message of a birth year [error] on [today], or null.
String? birthYearErrorText(
  AppLocalizations l10n,
  TypedFieldError? error,
  LocalDate today,
) {
  if (error == null) return null;
  if (error != TypedFieldError.outOfRange) return l10n.targetsEnterNumber;
  final range = TargetRules.input.birthYears(today);
  return l10n.profileBirthYearRange(range.min, range.max);
}

/// The message of a height [error] typed in [unit], or null.
String? heightErrorText(
  AppLocalizations l10n,
  TypedFieldError? error,
  HeightInputUnit unit,
) {
  if (error == null) return null;
  if (error != TypedFieldError.outOfRange) return l10n.targetsEnterNumber;
  switch (unit) {
    case HeightInputUnit.centimeter:
      final range = TypedRanges.heightCm();
      return l10n.profileHeightRangeCm(range.min, range.max);
    case HeightInputUnit.feetInches:
      final (:min, :max) = TypedRanges.heightFeetInches();
      return l10n.profileHeightRangeFtIn(
        min.feet,
        min.inches,
        max.feet,
        max.inches,
      );
  }
}

/// The message of a body or target weight [error] typed in [unit], or null.
String? weightErrorText(
  AppLocalizations l10n,
  TypedFieldError? error,
  MassUnit unit,
) {
  if (error == null) return null;
  if (error != TypedFieldError.outOfRange) return l10n.targetsEnterNumber;
  final range = TypedRanges.weight(unit);
  return l10n.targetsWeightRange(
    range.min,
    range.max,
    massUnitLabel(l10n, unit),
  );
}

/// The message of goal field [field]'s [error] in [unit], or null.
String? goalFieldErrorText(
  AppLocalizations l10n,
  GoalField field,
  TypedFieldError? error,
  MassUnit unit,
) {
  if (error == null) return null;
  final unitWord = massUnitLabel(l10n, unit);
  return switch ((field, error)) {
    (GoalField.targetDate, TypedFieldError.outOfRange) =>
      l10n.goalTargetDateTooFar,
    (GoalField.targetDate, _) => l10n.goalTargetDateMissing,
    (GoalField.targetWeight, _) => weightErrorText(l10n, error, unit),
    (_, TypedFieldError.outOfRange) when field == GoalField.month =>
      l10n.goalMonthRange(TypedRanges.maxMonth(unit), unitWord),
    (_, TypedFieldError.outOfRange) => l10n.goalRateRange(
      TypedRanges.maxRate(unit),
      unitWord,
    ),
    _ => l10n.targetsEnterNumber,
  };
}

/// Why a typed goal shows no numbers (PA3), in the goal form.
String goalProblemText(AppLocalizations l10n, GoalProblem problem) =>
    switch (problem) {
      GoalProblem.deadline => l10n.goalProblemDeadline,
      GoalProblem.targetNotBelow => l10n.goalProblemTargetNotBelow,
      GoalProblem.targetNotAbove => l10n.goalProblemTargetNotAbove,
    };

/// The neutral line for a saved goal that needs an update (PA3,
/// `TargetIssue.goalNeedsUpdate`; Me in A13c).
String storedGoalProblemText(AppLocalizations l10n, GoalProblem problem) =>
    switch (problem) {
      GoalProblem.deadline => l10n.goalStoredDatePassed,
      GoalProblem.targetNotBelow ||
      GoalProblem.targetNotAbove => l10n.goalStoredTargetReached,
    };

/// The message of a refused goal command (`TargetsFailure.goalUnresolvable`
/// / `goalNeedsUpdate`), or null for any other failure.
String? goalFailureText(AppLocalizations l10n, TargetsFailure failure) =>
    switch (failure) {
      TargetsFailure.goalUnresolvable => l10n.goalFailedUnresolvable,
      TargetsFailure.goalNeedsUpdate => l10n.goalFailedNeedsUpdate,
      _ => null,
    };
