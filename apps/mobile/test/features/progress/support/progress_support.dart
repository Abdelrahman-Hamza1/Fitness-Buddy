import 'dart:math' as math;

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/progress/application/progress_providers.dart';
import 'package:fb_mobile/features/progress/application/weight_graph_providers.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';

import '../../body/support/weigh_in_harness.dart'
    show storedWeighIn, weighInDraft;
import '../../today/presentation/support/today_support.dart' show phoneApp;

/// The Progress tests' today: Friday 23 October 2026, the last day of the
/// Saturday week 17–23 October.
final LocalDate progressToday = LocalDate(2026, 10, 23);

String _id(int n) =>
    '0199e3c2-5b1a-7000-8000-${n.toRadixString(16).padLeft(12, '0')}';

/// A male, 180 cm, sedentary profile.
const ProfileRecord progressProfile = ProfileRecord(
  heightInputUnit: HeightInputUnit.centimeter,
  sex: FormulaSex.male,
  birthYear: 1990,
  heightCm: 180,
  activity: ActivityLevel.sedentary,
);

/// Fixed 2,200 kcal a day since 1 June.
final TargetSettingsRecord progressSettings = TargetSettingsRecord(
  id: _id(1),
  revision: 1,
  effectiveFrom: LocalDate(2026, 6, 1),
  baseKcal: 2200,
  basisWeightKg: 88,
  mode: TargetMode.fixed,
);

/// "Lose to 82 kg at 0.5 kg/week" from 1 July.
final Versioned<GoalPhaseRecord> progressPhase = Versioned(
  GoalPhaseRecord(
    id: _id(2),
    revision: 1,
    start: LocalDate(2026, 7, 1),
    type: GoalType.lose,
    expression: GoalExpression.targetRate(82, .5),
    weightInputUnit: MassUnit.kilogram,
    name: 'Autumn cut',
  ),
  1,
);

Nutrients _food(double kcal) => Nutrients(
  kcal: kcal,
  protein: kcal / 16,
  carbs: kcal / 9,
  fat: kcal / 32,
  fiber: 18 + kcal / 400,
);

/// The key week (17–23 October): logged Sat and Sun, over target on Mon,
/// incomplete Tue (logged intake), nothing on Wed, logged Thu, today so
/// far; and steady logging before it from 1 June.
List<DayLog> progressLogs() => [
  for (
    var d = LocalDate(2026, 6, 1);
    d.isBefore(LocalDate(2026, 10, 17));
    d = d.plusDays(1)
  )
    if (d.day % 9 != 0)
      DayLog(date: d, totals: _food(1900 + (d.day * 53) % 500), entryCount: 4),
  DayLog(date: LocalDate(2026, 10, 17), totals: _food(2050), entryCount: 4),
  DayLog(date: LocalDate(2026, 10, 18), totals: _food(1980), entryCount: 5),
  DayLog(date: LocalDate(2026, 10, 19), totals: _food(2650), entryCount: 6),
  DayLog(
    date: LocalDate(2026, 10, 20),
    totals: _food(900),
    entryCount: 2,
    incomplete: true,
  ),
  DayLog(date: LocalDate(2026, 10, 22), totals: _food(2120), entryCount: 4),
  DayLog(date: progressToday, totals: _food(1150), entryCount: 2),
];

/// Daily weigh-ins from 1 July to today: a slow loss from 88 kg.
List<WeighIn> progressWeighIns() {
  final first = LocalDate(2026, 7, 1);
  final days = first.daysUntil(progressToday) + 1;
  return [
    for (var i = 0; i < days; i++)
      storedWeighIn(
        i + 1,
        weighInDraft(
          ((88 - i * 0.03 + math.sin(i * 1.3) * 0.3) * 10).roundToDouble() / 10,
          date: first.plusDays(i),
        ),
      ),
  ];
}

/// The Progress tab's providers without a database: [progressToday], a
/// Saturday week, fixed targets, one phase, [logs], the weigh-ins, no
/// workouts and a fixed week card. While [failLogs] returns true the diary
/// read fails (error-state tests).
List<Override> progressOverrides({
  List<DayLog>? logs,
  bool Function()? failLogs,
}) {
  final all = logs ?? progressLogs();
  return [
    clockProvider.overrideWithValue(
      ManualClock(DateTime.utc(2026, 10, 23, 9), offsetMinutes: 180),
    ),
    todayProvider.overrideWith((ref) => Stream.value(progressToday)),
    weekStartProvider.overrideWith((ref) => Stream.value(DayOfWeek.saturday)),
    targetsDataProvider.overrideWith(
      (ref) => Stream.value(
        TargetsData(
          profile: const Versioned(progressProfile, 1),
          phases: [progressPhase],
          settings: [Versioned(progressSettings, 1)],
        ),
      ),
    ),
    weighInsProvider.overrideWith((ref) => Stream.value(progressWeighIns())),
    unitSystemProvider.overrideWith((ref) => Stream.value(UnitSystem.metric)),
    chartHighlightPeriodsProvider.overrideWithValue(const []),
    progressLogsProvider.overrideWith(
      (ref, range) async => (failLogs?.call() ?? false)
          ? throw StateError('synthetic read failure')
          : [
              for (final log in all)
                if (!log.date.isBefore(range.$1) && !log.date.isAfter(range.$2))
                  log,
            ],
    ),
    trainingShiftProvider.overrideWith((ref, range) async => null),
    progressEarliestDateProvider.overrideWith(
      (ref) async => LocalDate(2026, 6, 1),
    ),
    weekGlanceProvider.overrideWith(
      (ref) async => WeekGlance(
        start: LocalDate(2026, 10, 17),
        end: progressToday,
        countedDays: 4,
        elapsedDays: 6,
        unit: MassUnit.kilogram,
        averageEaten: 2200,
        averageTarget: 2200,
        trendChangeKg: -.4,
      ),
    ),
  ];
}

/// The Progress screen on a phone, tall enough that every section builds.
Widget progressApp(
  List<Override> overrides, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) => ProviderScope(
  // Nothing retries on its own: a failure stays until Try again (UX-052).
  retry: (retryCount, error) => null,
  overrides: overrides,
  child: phoneApp(
    const ProgressScreen(),
    brightness: brightness,
    textScale: textScale,
  ),
);
