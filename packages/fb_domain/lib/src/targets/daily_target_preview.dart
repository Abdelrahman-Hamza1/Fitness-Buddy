import 'package:fb_domain/src/targets/macros.dart';
import 'package:fb_domain/src/targets/target_profile.dart';
import 'package:fb_domain/src/targets/target_settings.dart';

/// What one number for every day would mean (TG-046, D-102): the Change
/// sheet's live preview. The same macro maths as the stored plan
/// ([TargetPlan.macrosFor]): with every day at [kcal] the macro base is
/// [kcal]. Content-free [toString].
final class DailyTargetPreview {
  /// The preview of [kcal] every day over [plan] (its macro settings), at
  /// the macro weight [macroWeightKg] (`DayTargets.macroWeightKg`).
  /// [expenditureKcal], when known, gives the rough weekly rate.
  factory of({
    required TargetPlan plan,
    required double kcal,
    required double macroWeightKg,
    double? expenditureKcal,
    TargetDefaults defaults = const TargetDefaults(),
  }) {
    checkTargetNumber(kcal);
    final current = plan.dailyKcal;
    final after = MacroPlan.calculate(
      baseKcal: kcal,
      weightKg: macroWeightKg,
      settings: plan.macros,
      defaults: defaults,
    ).forDay(kcal);
    return DailyTargetPreview._(
      kcal: kcal,
      macros: after,
      currentKcal: current,
      currentMacros: plan.macrosFor(current, weightKg: macroWeightKg),
      kgPerWeek: expenditureKcal == null
          ? null
          : (kcal - expenditureKcal) * 7 / defaults.kcalPerKg,
    );
  }

  const new _({
    required this.kcal,
    required this.macros,
    required this.currentKcal,
    required this.currentMacros,
    required this.kgPerWeek,
  });

  /// The previewed number.
  final double kcal;

  /// Its day's macros.
  final DailyMacros macros;

  /// Today's daily number ([TargetPlan.dailyKcal]).
  final double currentKcal;

  /// Its day's macros ("was").
  final DailyMacros currentMacros;

  /// The rough weekly weight change at [kcal] (negative: losing), or null
  /// without an expenditure estimate.
  final double? kgPerWeek;

  /// The protein, fat and carbs shares of [macros]' energy (each 0–1,
  /// summing to 1), or null without fat/carb targets (TG-054) or energy.
  ({double protein, double fat, double carbs})? get shares {
    final fat = macros.fatGrams;
    final carbs = macros.carbsGrams;
    if (fat == null || carbs == null) return null;
    final p = macros.proteinGrams * 4;
    final f = fat * 9;
    final c = carbs * 4;
    final total = p + f + c;
    if (!(total > 0)) return null;
    return (protein: p / total, fat: f / total, carbs: c / total);
  }

  @override
  String toString() => 'DailyTargetPreview';
}
