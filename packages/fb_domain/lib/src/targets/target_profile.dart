import 'package:fb_domain/src/time/local_date.dart';

/// Formula sex in R1 (TG-001). The average formula is R2.
enum FormulaSex {
  /// Mifflin constant +5, minimum 1,500 kcal.
  male,

  /// Mifflin constant -161, minimum 1,200 kcal.
  female,
}

/// Four activity categories; the app supplies localized descriptions.
enum ActivityLevel {
  /// Little activity.
  sedentary,

  /// Light activity.
  light,

  /// Moderate activity.
  moderate,

  /// High activity.
  high,
}

/// The single numeric defaults object for spec13§8 and SF-010/011.
/// No configurable safety bypasses: explicit manual targets are separate.
final class TargetDefaults {
  /// The R1 defaults, unchanged by A12.
  const new();

  /// Energy approximation per kg of change (TG-020).
  double get kcalPerKg => 7700;

  /// Maximum generated weekly loss fraction (SF-011).
  double get maxLossFraction => .01;

  /// Rebalancing distance from base (TG-042).
  double get dailyFlex => .25;

  /// Daily protein per kg (TG-050).
  double get proteinPerKg => 1.8;

  /// Default fat energy fraction (TG-051).
  double get fatFraction => .30;

  /// Minimum daily fat per kg (TG-051).
  double get fatPerKgFloor => .6;

  /// Fiber per thousand base calories (TG-053).
  double get fiberPer1000Kcal => 14;

  /// Adaptive total-day threshold; behaviour belongs to A38 (TG-031).
  int get adaptiveDays => 14;

  /// Adaptive complete-day threshold (TG-031).
  int get adaptiveCompleteDays => 10;

  /// Adaptive weigh-in threshold (TG-031).
  int get adaptiveWeighIns => 3;

  /// Minimum spread of weigh-ins (TG-031).
  int get adaptiveWeighInSpanDays => 10;

  /// Strictly above this difference, propose a change (TG-034).
  double get checkInThresholdKcal => 50;

  /// Maximum adaptive change per day per check-in (TG-035).
  double get checkInMaxChangeKcal => 150;

  /// Initial estimation factors, centralized for A13 explanations.
  double activityFactor(ActivityLevel level) => switch (level) {
    ActivityLevel.sedentary => 1.2,
    ActivityLevel.light => 1.375,
    ActivityLevel.moderate => 1.55,
    ActivityLevel.high => 1.725,
  };

  /// Absolute floor before considering resting energy.
  double minimumKcal(FormulaSex sex) => sex == FormulaSex.male ? 1500 : 1200;
}

/// Canonical profile input, with time supplied by the caller (TG-001/002).
final class TargetProfile {
  /// Heights are cm and weights kg, converted by the existing unit helpers.
  new({
    required this.sex,
    required this.birthYear,
    required this.heightCm,
    required this.weightKg,
    required this.activity,
  }) {
    if (birthYear < 1 || birthYear > 9999) {
      throw ArgumentError('invalid birth year');
    }
    checkTargetNumber(heightCm);
    checkTargetNumber(weightKg);
  }

  /// Formula choice.
  final FormulaSex sex;

  /// Only birth year is stored, so age is evaluation year minus birth year.
  final int birthYear;

  /// Height in centimetres.
  final double heightCm;

  /// Current weight in kilograms.
  final double weightKg;

  /// Initial expenditure category.
  final ActivityLevel activity;

  /// Formula age on [date]; no clock or inferred birthday.
  int ageOn(LocalDate date) {
    if (date.year < birthYear) throw ArgumentError('profile predates birth');
    return date.year - birthYear;
  }
}

/// Rejects nonfinite, negative, zero (unless allowed), or unbounded input.
/// Errors never include private profile or target values.
void checkTargetNumber(double value, {bool allowZero = false}) {
  if (!value.isFinite ||
      value > TargetLimits.maxNumber ||
      (allowZero ? value < 0 : value <= 0)) {
    throw ArgumentError('target number outside supported range');
  }
}

/// Technical bounds shared by target input validation and allocation.
abstract final class TargetLimits {
  /// Maximum supported numeric input, avoiding unbounded arithmetic.
  static const double maxNumber = 1000000;

  /// Smallest supported positive weight (retired weekday weights; kept as a
  /// guard for settings that still read one).
  static const double minWeight = .001;

  /// Largest retired weekday weight.
  static const double maxWeight = 1000;

  /// Smallest per-weekday factor of the suggestion (D-090, A53 D1).
  static const double minDayFactor = .5;

  /// Largest per-weekday factor of the suggestion.
  static const double maxDayFactor = 2;

  /// Bisections for the bounded monotonic allocation solver.
  static const int allocationIterations = 80;

  /// Whether [factor] is a supported per-weekday factor.
  static bool isDayFactor(double factor) =>
      factor.isFinite && factor >= minDayFactor && factor <= maxDayFactor;

  /// Shared factor validation, with content-free errors.
  static void checkDayFactor(double factor) {
    if (!isDayFactor(factor)) {
      throw ArgumentError('weekday factors must be in supported range');
    }
  }
}
