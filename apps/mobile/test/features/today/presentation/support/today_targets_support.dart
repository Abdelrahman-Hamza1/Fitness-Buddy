import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

import 'today_support.dart';

String _id(int value) =>
    '0199e3c2-5b1a-7000-8000-${value.toRadixString(16).padLeft(12, '0')}';

/// A Saturday-start week: Sat 24 … Fri 30 October 2026.
final LocalDate weekSat = LocalDate(2026, 10, 24);

/// The day [n] days after [weekSat] (0 = Saturday … 6 = Friday).
LocalDate weekDay(int n) => weekSat.plusDays(n);

/// A male born 1990, 180 cm, sedentary: resting energy at w kg in 2026 is
/// 10w + 950 (80 kg → the floor 1,750 kcal).
const ProfileRecord sampleProfile = ProfileRecord(
  heightInputUnit: HeightInputUnit.centimeter,
  sex: FormulaSex.male,
  birthYear: 1990,
  heightCm: 180,
  activity: ActivityLevel.sedentary,
);

/// A target settings version [id], effective two weeks before [weekSat]
/// unless [from] is given.
TargetSettingsRecord sampleVersion({
  int id = 1,
  LocalDate? from,
  double base = 2000,
  TargetMode mode = TargetMode.weekly,
  bool manual = false,
  bool acknowledged = false,
  Map<DayOfWeek, double> shifts = const {},
  MacroSettings? macros,
}) => TargetSettingsRecord(
  id: _id(id),
  revision: 1,
  effectiveFrom: from ?? weekSat.plusDays(-14),
  baseKcal: base,
  basisWeightKg: 80,
  mode: mode,
  manual: manual,
  acknowledged: acknowledged,
  shifts: shifts,
  macros: macros,
);

/// A day that ate [kcal] in [entries] entries.
DayIntake ate(LocalDate date, double kcal, {int entries = 3}) =>
    DayIntake(date: date, kcal: kcal, entryCount: entries);

/// What the provider computes for [date] (D6): [TargetsTimeline.day] on
/// [sampleProfile] at 80 kg.
DayTargets targetsOn(
  LocalDate date, {
  List<TargetSettingsRecord>? settings,
  List<DayIntake> intake = const [],
}) => TargetsTimeline.day(
  date: date,
  settings: settings ?? [sampleVersion()],
  profile: sampleProfile,
  bodyWeightKg: 80,
  intake: intake,
)!;

/// A day's totals: [kcal] with fixed macros.
Nutrients eatenTotals(
  double kcal, {
  double protein = 82.4,
  double carbs = 151.6,
  double fat = 40.2,
  double fiber = 12.3,
}) => Nutrients(
  kcal: kcal,
  protein: protein,
  carbs: carbs,
  fat: fat,
  fiber: fiber,
);

/// Whole kcal with thousands separators, as Today shows them.
String kcalText(num kcal) =>
    NumberFormat.decimalPattern('en').format(DisplayRounding.kcal(kcal * 1.0));

/// Overrides for a numbers block of [date] showing [targets] (null: no
/// targets) with setup at [setup].
List<Override> numbersOverrides(
  LocalDate date,
  DayTargets? targets, {
  SetupStatus setup = SetupStatus.setUp,
}) => [
  dayTargetsProvider.overrideWith((ref, d) => d == date ? targets : null),
  setupStatusProvider.overrideWith((ref) => setup),
];

/// Pumps [block] alone on a 360 dp phone, scrollable, in a new provider
/// scope.
Future<void> pumpBlock(
  WidgetTester tester,
  Widget block,
  List<Override> overrides, {
  double textScale = 1,
}) async {
  usePhone(tester);
  await tester.pumpWidget(
    // A fresh container each time: no value carries over from the last pump.
    ProviderScope(
      key: UniqueKey(),
      overrides: overrides,
      child: phoneApp(
        Scaffold(body: SingleChildScrollView(child: block)),
        textScale: textScale,
      ),
    ),
  );
  await tester.pump();
}
