import 'package:alchemist/alchemist.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/targets/presentation/below_limit_screen.dart';
import 'package:fb_mobile/features/targets/presentation/manual_target_sheet.dart';
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

final GoalPhaseRecord _pastGoal =
    GoalInput(
      type: GoalType.lose,
      expression: GoalExpression.weekly(-.75),
    ).toRecord(
      id: '01890abc-def0-7123-8abc-0123456789ac',
      start: LocalDate(2026, 1, 3),
      end: LocalDate(2026, 4, 30),
    );

TargetSettingsRecord _version({
  double base = 2162.5,
  TargetMode mode = TargetMode.weekly,
  bool manual = false,
  bool acknowledged = false,
  Map<DayOfWeek, double> shifts = const {},
}) => TargetSettingsRecord(
  id: '01890abc-def0-7123-8abc-0123456789ad',
  revision: 1,
  effectiveFrom: LocalDate(2026, 10, 17),
  baseKcal: base,
  basisWeightKg: 80,
  mode: mode,
  manual: manual,
  acknowledged: acknowledged,
  shifts: shifts,
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

final ProfileGoalView _profileView = ProfileGoalView(
  today: _today,
  profile: const Versioned(_profile, 1),
  units: UnitSystem.metric,
  weightKg: 80,
  currentWeightKg: 79.4,
  active: Versioned(_goal, 1),
  past: [Versioned(_pastGoal, 2)],
  goalCalculation: goalPreviewOf(
    _profile,
    80,
    GoalInput(type: GoalType.lose, expression: GoalExpression.weekly(-.5)),
    _today,
  ).calculation,
);

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
                overrides: overrides,
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
  await _golden(
    'targets_profile_goal',
    'TG-001 TG-011 TG-012 Profile & goal',
    () => const ProfileGoalScreen(),
    overrides: [
      profileGoalViewProvider.overrideWith((ref) async => _profileView),
    ],
  );
  await _golden(
    'targets_screen_weekly',
    'TG-021 TG-040 TG-043 Targets, weekly budget with a higher-calorie Friday',
    () => const TargetsScreen(),
    overrides: [
      targetsViewProvider.overrideWith(
        (ref) async =>
            _targetsView(_version(shifts: const {DayOfWeek.friday: 1.3})),
      ),
    ],
    height: 1800,
  );
  await _golden(
    'targets_screen_forced_fixed',
    'SF-012 PA7 Targets, acknowledged own target below the floor',
    () => const TargetsScreen(),
    overrides: [
      targetsViewProvider.overrideWith(
        (ref) async => _targetsView(
          _version(
            base: 1300,
            mode: TargetMode.fixed,
            manual: true,
            acknowledged: true,
          ),
        ),
      ),
    ],
    height: 1800,
  );
  await _golden(
    'targets_below_limit_warning',
    'SF-012 SF-020 the below-limit warning screen',
    () => BelowLimitScreen(
      kcal: 1300,
      need: TargetsNeedsAcknowledgement(
        floorKcal: 1750,
        impliedKgPerWeek: -1.29,
        warnings: const {
          TargetWarning.manualBelowFloor,
          TargetWarning.manualLossRateExceeded,
        },
      ),
      units: UnitSystem.metric,
    ),
    height: 800,
  );
  await _golden(
    'targets_manual_sheet',
    'SF-012 the own-target sheet',
    () => Scaffold(body: ManualTargetSheet(view: _targetsView(_version()))),
    height: 600,
  );
}
