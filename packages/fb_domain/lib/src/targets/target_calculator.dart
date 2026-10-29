import 'dart:math' as math;

import 'package:fb_domain/src/targets/goals.dart';
import 'package:fb_domain/src/targets/target_profile.dart';
import 'package:fb_domain/src/time/local_date.dart';

/// Typed explanation/warning codes, localized by the app (TG-021).
enum TargetWarning {
  /// Requested loss exceeded SF-011.
  lossRateCapped,

  /// Generated calories were raised to the SF-010 floor.
  calorieFloorApplied,

  /// Explicit acknowledged manual target below SF-010.
  manualBelowFloor,

  /// Explicit manual calories imply loss beyond SF-011.
  manualLossRateExceeded,
}

/// Pure initial-target math; manual output is never a generated plan.
abstract final class TargetCalculator {
  /// Mifflin-St Jeor using the caller's evaluation date (TG-020).
  static double resting(TargetProfile profile, LocalDate date) =>
      10 * profile.weightKg +
      6.25 * profile.heightCm -
      5 * profile.ageOn(date) +
      (profile.sex == FormulaSex.male ? 5 : -161);

  /// The SF-010 floor on [date]: the larger of resting energy and the sex
  /// minimum. Recompute it per date and weight; never persist it.
  static double floor(
    TargetProfile profile,
    LocalDate date, {
    TargetDefaults defaults = const TargetDefaults(),
  }) => math.max(resting(profile, date), defaults.minimumKcal(profile.sex));

  /// Builds typed numeric explanation fields. Below-limit manual targets
  /// require acknowledgement; WeeklyBudget never accepts a below-floor base.
  static TargetCalculation calculate({
    required TargetProfile profile,
    required ResolvedGoal goal,
    required LocalDate date,
    double? manualKcal,
    bool acknowledged = false,
    TargetDefaults defaults = const TargetDefaults(),
  }) {
    final restingKcal = resting(profile, date);
    final floor = TargetCalculator.floor(profile, date, defaults: defaults);
    final factor = defaults.activityFactor(profile.activity);
    final expenditure = restingKcal * factor;
    // An impossible formula profile must not produce negative expenditure.
    checkTargetNumber(expenditure);
    final maxLoss = profile.weightKg * defaults.maxLossFraction;
    final cappedRate = math.max(goal.requestedKgPerWeek, -maxLoss);
    final rawKcal = expenditure + cappedRate * defaults.kcalPerKg / 7;
    final generatedKcal = math.max(rawKcal, floor);
    final warnings = <TargetWarning>{
      if (cappedRate != goal.requestedKgPerWeek) TargetWarning.lossRateCapped,
      if (manualKcal == null && rawKcal < floor)
        TargetWarning.calorieFloorApplied,
    };
    final double kcal;
    if (manualKcal != null) {
      checkTargetNumber(manualKcal);
      final rate = (manualKcal - expenditure) * 7 / defaults.kcalPerKg;
      if ((manualKcal < floor || rate < -maxLoss) && !acknowledged) {
        throw ArgumentError('manual target needs safety acknowledgement');
      }
      kcal = manualKcal;
      if (kcal < floor) warnings.add(TargetWarning.manualBelowFloor);
      if (rate < -maxLoss) warnings.add(TargetWarning.manualLossRateExceeded);
    } else {
      kcal = generatedKcal;
    }
    checkTargetNumber(kcal);
    final achievableRate = (kcal - expenditure) * 7 / defaults.kcalPerKg;
    LocalDate? projected;
    if (goal.targetKg case final target?) {
      final change = target - profile.weightKg;
      if (change != 0 &&
          achievableRate != 0 &&
          change.sign == achievableRate.sign) {
        final days = (change / achievableRate * 7).ceil();
        // No fictional date when a tiny deficit projects past supported years.
        if (date.epochDay + days <= LocalDate(9999, 12, 31).epochDay) {
          projected = date.plusDays(days);
        }
      }
    }
    return TargetCalculation._(
      restingKcal: restingKcal,
      activityFactor: factor,
      expenditureKcal: expenditure,
      floorKcal: floor,
      requestedKgPerWeek: goal.requestedKgPerWeek,
      cappedKgPerWeek: cappedRate,
      achievableKgPerWeek: achievableRate,
      kcal: kcal,
      manual: manualKcal != null,
      acknowledged: acknowledged,
      projectedDate: projected,
      warnings: warnings,
    );
  }
}

/// Numeric explanation for TG-021; carries no generated text or writes.
final class TargetCalculation {
  new _({
    required this.restingKcal,
    required this.activityFactor,
    required this.expenditureKcal,
    required this.floorKcal,
    required this.requestedKgPerWeek,
    required this.cappedKgPerWeek,
    required this.achievableKgPerWeek,
    required this.kcal,
    required this.manual,
    required this.acknowledged,
    required this.projectedDate,
    required Set<TargetWarning> warnings,
  }) : warnings = Set.unmodifiable(warnings);

  /// Estimated resting energy.
  final double restingKcal;

  /// Applied activity factor.
  final double activityFactor;

  /// Initial expenditure estimate.
  final double expenditureKcal;

  /// Maximum of resting energy and sex minimum.
  final double floorKcal;

  /// Original requested signed weekly change.
  final double requestedKgPerWeek;

  /// Requested rate after SF-011, before floor clamp.
  final double cappedKgPerWeek;

  /// Rate implied by final calories, including floor/manual changes.
  final double achievableKgPerWeek;

  /// Unrounded daily calories. An explicit manual value may be below floor.
  final double kcal;

  /// Whether calories came from an explicit manual override.
  final bool manual;

  /// Whether the caller supplied the required manual warning acknowledgement.
  final bool acknowledged;

  /// Estimated completion using achievable rate, rounding days upward.
  final LocalDate? projectedDate;

  /// Immutable warning codes; the UI renders ARB strings.
  final Set<TargetWarning> warnings;
}
