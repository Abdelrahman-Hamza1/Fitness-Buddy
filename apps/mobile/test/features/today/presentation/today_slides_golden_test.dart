// Covers: HM-005, HM-006, UX-051
import 'package:alchemist/alchemist.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/today/application/today_slide.dart';
import 'package:fb_mobile/features/today/presentation/today_slide_card.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';

import '../../body/support/weigh_in_harness.dart' show weighInDraft;
import 'support/today_support.dart';

List<Override> slidesOverrides(int index) => [
  ...fakeToday(
    weighIns: [
      for (var i = 0; i < 4; i++)
        WeighIn(
          id: '0199e3c2-5b1a-7000-8000-${i.toString().padLeft(12, '0')}',
          version: 1,
          time: weighInDraft(
            80 - i.toDouble(),
            date: testToday.plusDays(-i * 7 - 1),
          ).time,
          localDate: testToday.plusDays(-i * 7 - 1),
          kg: 80 - i.toDouble(),
          input: WeighInInput(80 - i.toDouble(), MassUnit.kilogram),
        ),
    ],
  ).where((o) => o.origin != todayWorkoutProvider),
  todayWorkoutProvider.overrideWith(
    (ref, date) => TodayWorkoutLogged(
      summary: SessionSummary(
        session: (
          ref: VersionedId('0199e3c2-5b1a-7000-8000-000000000090', 1),
          draft: WorkoutSessionDraft(date: date, name: 'Push', exercises: []),
        ),
        title: const NamedTitle('Push'),
        exerciseCount: 5,
        setCount: 15,
        prCount: 1,
        muscles: MuscleUnion.of(const [
          (primary: Muscle.chest, secondaries: [Muscle.triceps]),
        ]),
      ),
      more: 1,
    ),
  ),
  todaySlideProvider.overrideWithBuild((ref, notifier) => index),
];
Widget cell(int index, Brightness brightness, double scale) => SizedBox(
  width: 360,
  height: 960,
  child: ProviderScope(
    overrides: [...slidesOverrides(index)],
    child: phoneApp(
      Scaffold(
        body: TodaySlideCard(
          date: testToday,
          isToday: true,
          totals: Nutrients.zero,
        ),
      ),
      brightness: brightness,
      textScale: scale,
    ),
  ),
);
Future<void> main() async {
  await goldenTest(
    'weight and workout slides',
    fileName: 'today_slides',
    builder: () => GoldenTestGroup(
      columns: 4,
      children: [
        for (final index in [1, 2])
          for (final scale in [1.0, 2.0])
            for (final b in Brightness.values)
              GoldenTestScenario(
                name: 'slide $index ${b.name} x$scale',
                child: cell(index, b, scale),
              ),
      ],
    ),
  );
}
