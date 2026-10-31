import 'package:alchemist/alchemist.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/targets/presentation/day_target_sheet.dart';
import 'package:fb_mobile/features/targets/presentation/how_sheet.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../today/presentation/support/today_support.dart' show phoneApp;

// Fixed views (no database): a man born 1990, 180 cm, moderate, 80 kg,
// losing 0.5 kg a week since 1 Oct; today is Monday 2026-10-19 in a
// Saturday week.
final LocalDate _today = LocalDate(2026, 10, 19);

const ProfileRecord _profile = ProfileRecord(
  sex: FormulaSex.male,
  birthYear: 1990,
  heightCm: 180,
  heightInputUnit: HeightInputUnit.centimeter,
  activity: ActivityLevel.moderate,
);

final GoalPhaseRecord _goal = GoalInput(
  type: GoalType.lose,
  expression: GoalExpression.weekly(-.5),
).toRecord(id: '01890abc-def0-7123-8abc-0123456789ab', start: _today);

TargetSettingsRecord _version({
  double base = 2162.5,
  TargetMode mode = TargetMode.weekly,
  bool manual = false,
  bool acknowledged = false,
  Map<DayOfWeek, double> dayFactors = const {},
}) => TargetSettingsRecord(
  id: '01890abc-def0-7123-8abc-0123456789ad',
  revision: 1,
  effectiveFrom: LocalDate(2026, 10, 17),
  baseKcal: base,
  basisWeightKg: 80,
  mode: mode,
  manual: manual,
  acknowledged: acknowledged,
  dayFactors: dayFactors,
);

TargetsView _targetsView(TargetSettingsRecord version) {
  const calendar = WeekCalendar();
  final day = TargetsTimeline.day(
    date: _today,
    settings: [version],
    profile: _profile,
    goals: [_goal],
    intake: [
      DayIntake(date: LocalDate(2026, 10, 17), kcal: 2400, entryCount: 4),
    ],
  )!;
  return TargetsView(
    today: _today,
    shown: VersionedId(version.id, 1),
    day: day,
    profile: _profile,
    units: UnitSystem.metric,
    calendar: calendar,
    explanation: TargetsTimeline.explain(
      date: _today,
      settings: [version],
      profile: _profile,
      goals: [_goal],
    ),
    trendKg: 78.6,
  );
}

// The screen's midnight rollover reads the clock (#197).
final List<Override> _fixedClock = [
  clockProvider.overrideWithValue(ManualClock(DateTime.utc(2026, 10, 17, 12))),
];

Future<void> _golden(
  String name,
  String description,
  Widget Function() screen, {
  List<Override> overrides = const [],
  double height = 1100,
}) => goldenTest(
  '$description, light/dark at text scale 1.0 and 2.0',
  fileName: name,
  builder: () => GoldenTestGroup(
    columns: 4,
    children: [
      for (final scale in const [1.0, 2.0])
        for (final (label, brightness) in const [
          ('light', Brightness.light),
          ('dark', Brightness.dark),
        ])
          GoldenTestScenario(
            name: '$label, x$scale',
            child: SizedBox(
              width: 360,
              height: height,
              child: ProviderScope(
                overrides: [..._fixedClock, ...overrides],
                child: phoneApp(
                  screen(),
                  brightness: brightness,
                  textScale: scale,
                ),
              ),
            ),
          ),
    ],
  ),
);

Future<void> main() async {
  final view = _targetsView(
    _version(dayFactors: const {DayOfWeek.friday: 1.2}),
  );
  await _golden(
    'targets_screen_weekly',
    'D-090 TG-040 Targets, the suggestion with a higher Friday',
    () => const TargetsScreen(),
    overrides: [targetsViewProvider.overrideWith((ref) async => view)],
    height: 1400,
  );
  await _golden(
    'targets_day_sheet',
    "D-090 the day sheet: Friday's number, chips and the week line",
    () => Scaffold(
      body: Align(
        alignment: AlignmentDirectional.bottomCenter,
        child: DayTargetSheet(view: view, weekday: DayOfWeek.friday),
      ),
    ),
    height: 900,
  );
  await _golden(
    'targets_how_sheet',
    'D-090 TG-021 how the target is worked out, as steps',
    () => Scaffold(
      body: Align(
        alignment: AlignmentDirectional.bottomCenter,
        child: SingleChildScrollView(child: HowSheet(view: view)),
      ),
    ),
    height: 1300,
  );
}
