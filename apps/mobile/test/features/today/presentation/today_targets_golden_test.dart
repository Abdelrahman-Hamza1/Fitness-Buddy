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
}
