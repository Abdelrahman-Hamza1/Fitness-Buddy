import 'package:alchemist/alchemist.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'support/today_support.dart';
import 'support/today_targets_support.dart';

/// Today with real numbers (A13 exit 4): a phone at [brightness] and text
/// [scale] showing [day] with [targets] on today.
Widget _phone(
  DiaryDay day,
  DayTargets targets,
  Brightness brightness,
  double scale,
) => SizedBox(
  width: 360,
  height: 640,
  child: ProviderScope(
    overrides: fakeToday(
      days: {testToday: day},
      targets: {testToday: targets},
      setup: SetupStatus.setUp,
    ),
    child: phoneApp(
      const TodayScreen(),
      brightness: brightness,
      textScale: scale,
    ),
  ),
);

Future<void> _golden(
  String name,
  String file,
  DiaryDay day,
  DayTargets targets,
) => goldenTest(
  name,
  fileName: file,
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
            child: _phone(day, targets, brightness, scale),
          ),
    ],
  ),
);

Future<void> main() async {
  // The numbers come from the engine for a Wednesday (Saturday and Sunday
  // under, Monday not logged), shown on the test's today.
  final midweek = [
    ate(weekDay(0), 1850),
    ate(weekDay(1), 1850),
    ate(weekDay(3), 2000),
  ];
  final full = fullDay(testToday);
  await _golden(
    'HM-001 HM-002 HM-003 today: under the target, weekly line',
    'today_targets_under',
    full,
    targetsOn(weekDay(4), intake: midweek),
  );
  await _golden(
    'HM-001 SF-021 today: over the target, neutral tone',
    'today_targets_over',
    fakeDay(testToday, [
      ...full.entries,
      fakeEntry(
        7,
        date: testToday,
        slotId: DefaultSlots.dinnerId,
        hour: 20,
        name: 'Mansaf',
        kcal: 1250,
      ),
    ], full.groups),
    targetsOn(weekDay(4), intake: midweek),
  );
  await _golden(
    'TG-044 today: same every day, no weekly line',
    'today_targets_fixed',
    full,
    targetsOn(
      weekDay(4),
      settings: [sampleVersion(mode: TargetMode.fixed, base: 2200)],
      intake: midweek,
    ),
  );
  await _golden(
    'TG-054 today: calories and protein only',
    'today_targets_protein_only',
    full,
    targetsOn(
      weekDay(4),
      settings: [
        sampleVersion(macros: MacroSettings(caloriesProteinOnly: true)),
      ],
      intake: midweek,
    ),
  );
}
