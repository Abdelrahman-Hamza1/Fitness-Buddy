// Covers: HM-006, WO-021
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/today/application/today_slide.dart';
import 'package:fb_mobile/features/today/presentation/today_slide_card.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:fb_mobile/features/workouts/presentation/exercise_muscle_map.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_log_screen.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_slide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart' as app;
import '../../today/presentation/support/today_support.dart';

List<Override> overrides(
  RecordingNavigator nav, {
  TodayWorkout row = const TodayWorkoutNone(),
}) => [
  ...fakeToday(navigator: nav).where((o) => o.origin != todayWorkoutProvider),
  todayWorkoutProvider(testToday).overrideWith((ref) async => row),
];
const _id = '0199e3c2-5b1a-7000-8000-000000000001';
final Stored<WorkoutTemplateDraft> _template = (
  ref: VersionedId(_id, 1),
  draft: WorkoutTemplateDraft(name: 'Push', items: []),
);
final _summary = SessionSummary(
  session: (
    ref: VersionedId(_id, 1),
    draft: WorkoutSessionDraft(date: testToday, name: 'Push', exercises: []),
  ),
  title: const NamedTitle('Push'),
  exerciseCount: 5,
  setCount: 12,
  prCount: 1,
  muscles: MuscleUnion.of(const []),
);

void main() {
  testWidgets('HM-006 empty slide action reaches the real Today log screen', (
    tester,
  ) async {
    final c = await app.pumpApp(tester);
    c.read(todaySlideProvider.notifier).select(2);
    await tester.pumpAndSettle();
    expect(find.byType(TodaySlideCard), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('today-workout-log')).first);
    await tester.pumpAndSettle();
    final screen = tester.widget<WorkoutLogScreen>(
      find.byType(WorkoutLogScreen),
    );
    expect(screen.template, isNull);
    expect(screen.inToday, isTrue);
    expect(
      c.read(appRouterProvider).config.state.matchedLocation,
      TodayWorkoutLogRoute.path,
    );
    await app.unmountApp(tester, c);
  });

  testWidgets('HM-006 empty slide logs a free workout on the viewed day', (
    tester,
  ) async {
    final nav = RecordingNavigator();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...overrides(nav)],
        child: phoneApp(Scaffold(body: WorkoutSlide(date: testToday))),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('today-workout-log')));
    expect(
      nav.pushed.single.location,
      TodayWorkoutLogRoute(date: testToday).location,
    );
  });
  for (final row in <TodayWorkout>[
    TodayWorkoutPlanned(template: _template),
    TodayWorkoutLogged(summary: _summary, more: 1),
    TodayWorkoutLast(summary: _summary, daysAgo: 3),
  ]) {
    testWidgets('HM-006 session and planned route ${row.runtimeType}', (
      tester,
    ) async {
      final nav = RecordingNavigator();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...overrides(nav, row: row)],
          child: phoneApp(Scaffold(body: WorkoutSlide(date: testToday))),
        ),
      );
      await tester.pumpAndSettle();
      if (row is TodayWorkoutPlanned) {
        await tester.tap(find.byKey(const ValueKey('today-workout-log')));
        expect((nav.pushed.single as TodayWorkoutLogRoute).template, _id);
      } else {
        expect(find.byType(ExerciseMuscleMap), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('workout-today-row')));
        expect((nav.pushed.single as TodayWorkoutSessionRoute).id, _id);
      }
    });
  }
  testWidgets('HM-006 muscle map steps back at large text', (tester) async {
    final nav = RecordingNavigator();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...overrides(
            nav,
            row: TodayWorkoutLogged(summary: _summary, more: 0),
          ),
        ],
        child: phoneApp(
          Scaffold(body: WorkoutSlide(date: testToday)),
          textScale: 2,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseMuscleMap), findsNothing);
  });
}
