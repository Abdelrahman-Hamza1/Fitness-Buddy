import 'package:alchemist/alchemist.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../today/presentation/support/today_support.dart';
import 'quick_add_support.dart';

/// Today on a phone with the quick-add row (foods, a meal, "+"): light and
/// dark at text scale 1.0 and 2.0, LTR only in R1 (`09` §3).
Widget _phone(Brightness brightness, double scale, {required bool empty}) =>
    SizedBox(
      width: 360,
      height: 640,
      child: ProviderScope(
        overrides: fakeToday(
          days: {testToday: fullDay(testToday)},
          chips: empty
              ? const []
              : [
                  fakeFoodChip(1, 'Labaneh'),
                  fakeMealChip(2, 'Usual breakfast'),
                  fakeFoodChip(3, 'Pita bread, white'),
                  fakeFoodChip(4, 'Greek yoghurt with honey and walnuts'),
                ],
        ),
        child: phoneApp(
          const TodayScreen(),
          brightness: brightness,
          textScale: scale,
        ),
      ),
    );

Future<void> main() async {
  await goldenTest(
    'DY-030 HM-008 UX-070 today: quick-add chip row',
    fileName: 'today_quick_add_row',
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
              child: _phone(brightness, scale, empty: false),
            ),
      ],
    ),
  );
  await goldenTest(
    'HM-008 today: no chip row without suggestions',
    fileName: 'today_no_quick_add_row',
    builder: () => GoldenTestGroup(
      columns: 2,
      children: [
        for (final (label, brightness) in const [
          ('light', Brightness.light),
          ('dark', Brightness.dark),
        ])
          GoldenTestScenario(
            name: label,
            child: _phone(brightness, 1, empty: true),
          ),
      ],
    ),
  );
}
