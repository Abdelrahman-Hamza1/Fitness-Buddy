import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

/// Runs per property test, locally and in CI (S08 D14, exit criterion
/// "≥ 1,000 runs each"). Never lower it in a single test.
const int propertyRunCount = 1000;

/// The explore settings every property test uses. A fresh value per test, so
/// each test has its own seeded random and doesn't depend on test order.
ExploreConfig get propertyRuns => ExploreConfig(numRuns: propertyRunCount);

/// Bounded generators for domain values: never NaN or infinity, sizes that
/// real food data has.
extension DomainAnys on Any {
  /// An amount at storage precision (whole hundredths), 0 to 5,000.
  Generator<double> get storedAmount =>
      intInRange(0, 500001).map((hundredths) => hundredths / 100);

  /// A positive amount, 0.001 to 10,000, for round trips.
  Generator<double> get positiveAmount => doubleInRange(0.001, 10000);

  /// A per-100 value of a core nutrient, 0 to 900.
  Generator<double> get per100Value => doubleInRange(0, 900);

  /// Per-100 nutrient values (core five, sometimes with sugar and sodium).
  Generator<Nutrients> get per100Nutrients => combine7(
    per100Value,
    doubleInRange(0, 100),
    doubleInRange(0, 100),
    doubleInRange(0, 100),
    doubleInRange(0, 40),
    doubleInRange(0, 100).nullable,
    doubleInRange(0, 5000).nullable,
    (kcal, protein, carbs, fat, fiber, sugar, sodium) => Nutrients(
      kcal: kcal,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      extras: {NutrientKey.sugar: ?sugar, NutrientKey.sodium: ?sodium},
    ),
  );

  /// Any mass unit.
  Generator<MassUnit> get massUnit => choose(MassUnit.values);

  /// Any volume unit.
  Generator<VolumeUnit> get volumeUnit => choose(VolumeUnit.values);

  /// Any length unit.
  Generator<LengthUnit> get lengthUnit => choose(LengthUnit.values);

  /// Any food state.
  Generator<FoodState> get foodState => choose(FoodState.values);

  /// A yield factor as the catalog has them, 0.2 to 5.
  Generator<double> get yieldFactor => doubleInRange(0.2, 5);

  /// A date from 1900 to 2199.
  Generator<LocalDate> get localDate => intInRange(
    LocalDate(1900, 1, 1).epochDay,
    LocalDate(2200, 1, 1).epochDay,
  ).map(LocalDate.fromEpochDay);

  /// Any day of the week.
  Generator<DayOfWeek> get dayOfWeek => choose(DayOfWeek.values);

  /// A lowercase canonical UUID from 16 random bytes (any version).
  Generator<String> get uuid =>
      listWithLength(16, intInRange(0, 256)).map(uuidOfBytes);

  /// One of three fixed device IDs, so ties on wall time and counter
  /// happen often.
  Generator<String> get fewDeviceIds => choose(_devices);

  /// An HLC wall time: often one of a few values (ties), else anywhere in
  /// the 13-digit range.
  Generator<int> get hlcWallMs =>
      either(intInRange(0, 3), intInRange(0, Hlc.maxWallMs + 1));

  /// An HLC counter: often small (ties), else anywhere in its range.
  Generator<int> get hlcCounter =>
      either(intInRange(0, 3), intInRange(0, Hlc.maxCounter + 1));

  /// An HLC with frequent ties in every field.
  Generator<Hlc> get hlc => combine3(
    hlcWallMs,
    hlcCounter,
    either(fewDeviceIds, uuid),
    (wallMs, counter, deviceId) =>
        Hlc(wallMs: wallMs, counter: counter, deviceId: deviceId),
  );
}

const _devices = [
  '00000000-0000-7000-8000-000000000000',
  '0199e3c2-5b1a-7c3d-8e4f-0123456789ab',
  'ffffffff-ffff-4fff-bfff-ffffffffffff',
];

/// [bytes] (16) as lowercase canonical UUID text.
String uuidOfBytes(List<int> bytes) {
  final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')]
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Whether [actual] equals [expected] within [relative] (relative error,
/// with an absolute floor of [relative] near zero).
bool closeRelative(double actual, double expected, {double relative = 1e-9}) =>
    (actual - expected).abs() <=
    relative * (expected.abs() > 1 ? expected.abs() : 1);
