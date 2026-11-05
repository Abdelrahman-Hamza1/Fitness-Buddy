// Covers: HM-005, HM-006, WO-021, UX-045
import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/today/presentation/today_glance_line.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../body/support/weigh_in_harness.dart';
import 'support/today_support.dart';

const _id = '0199e3c2-5b1a-7000-8000-000000000001';
final Stored<WorkoutTemplateDraft> _template = (
  ref: VersionedId(_id, 1),
  draft: WorkoutTemplateDraft(name: 'Push', items: []),
);
final SessionSummary _summary = SessionSummary(
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

final List<WeighIn> _weekly = [
  for (final (i, ago) in [29, 22, 15, 8, 1].indexed)
    storedWeighIn(
      600 + i,
      weighInDraft(98 - i * 0.5, date: testToday.plusDays(-ago)),
    ),
];

/// The weight states: loading, error, none, a trend.
final Map<String, List<Override>> _weights = {
  // Nothing awaits the weigh-ins' first value while loading.
  'weight loading': [
    weighInsProvider.overrideWith(
      (ref) => StreamController<List<WeighIn>>().stream,
    ),
    weightTrendProvider.overrideWith(
      (ref) => StreamController<WeightTrend>().stream,
    ),
  ],
  'weight error': [
    weighInsProvider.overrideWith(
      (ref) => Stream.error(StateError('read failed')),
    ),
  ],
  'weight none': [weighInsProvider.overrideWith((ref) => Stream.value([]))],
  'weight trend': [
    weighInsProvider.overrideWith((ref) => Stream.value(_weekly)),
  ],
};

/// The workout states: loading, error, logged, planned, none.
final Map<String, TodayWorkout? Function()> _workouts = {
  'workout loading': () => null,
  'workout error': () => throw StateError('read failed'),
  'workout logged': () => TodayWorkoutLogged(summary: _summary, more: 0),
  'workout planned': () => TodayWorkoutPlanned(template: _template),
  'workout none': () => const TodayWorkoutNone(),
};

Override _workout(TodayWorkout? Function() row) =>
    todayWorkoutProvider.overrideWith((ref, date) {
      final value = row();
      return value ?? Completer<TodayWorkout>().future;
    });

Future<void> _pump(
  WidgetTester tester, {
  required List<Override> weight,
  required Override workout,
  RecordingNavigator? navigator,
  LocalDate? date,
  double scale = 1,
}) async {
  usePhone(tester);
  final base = fakeToday(navigator: navigator).where(
    (o) => o.origin != weighInsProvider && o.origin != todayWorkoutProvider,
  );
  final day = date ?? testToday;
  // A fresh scope per state: no provider carries over.
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...base, ...weight, workout],
      child: phoneApp(
        Scaffold(
          body: Column(
            children: [TodayGlanceLine(date: day, isToday: day == testToday)],
          ),
        ),
        textScale: scale,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

const ValueKey<String> _line = ValueKey('today-glance-line');
const ValueKey<String> _weightKey = ValueKey('today-glance-weight');
const ValueKey<String> _workoutKey = ValueKey('today-glance-workout');

void main() {
  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('UX-045 A57 T-T3 the line is the same height in every state '
        '(scale $scale)', (tester) async {
      final heights = <String, double>{};
      for (final MapEntry(key: w, value: weight) in _weights.entries) {
        for (final MapEntry(key: o, value: row) in _workouts.entries) {
          for (final date in [testToday, testYesterday]) {
            await _pump(
              tester,
              weight: weight,
              workout: _workout(row),
              date: date,
              scale: scale,
            );
            heights['$w, $o, $date'] = tester.getSize(find.byKey(_line)).height;
            expect(tester.takeException(), isNull, reason: '$w, $o');
          }
        }
      }
      expect(heights.values.toSet(), hasLength(1), reason: '$heights');
      // From 1.5 the halves stack: two rows, chosen by the scale only.
      final weightTop = tester.getTopLeft(find.byKey(_weightKey)).dy;
      final workoutTop = tester.getTopLeft(find.byKey(_workoutKey)).dy;
      expect(workoutTop > weightTop, scale >= TodayGlanceLine.stackFromScale);
      expect(
        tester.getSize(find.byKey(_weightKey)).height,
        greaterThanOrEqualTo(48),
      );
    });
  }

  testWidgets('HM-006 WO-021 A57 T-T5 workout half: logged opens the '
      'session, planned starts the template, none starts a free session on '
      'the viewed day; never a missed note', (tester) async {
    Future<String> tapWith(TodayWorkout row, {LocalDate? date}) async {
      final navigator = RecordingNavigator();
      await _pump(
        tester,
        weight: _weights['weight none']!,
        workout: _workout(() => row),
        navigator: navigator,
        date: date,
      );
      await tester.tap(find.byKey(_workoutKey));
      await tester.pump();
      return navigator.pushed.single.location;
    }

    expect(
      await tapWith(TodayWorkoutLogged(summary: _summary, more: 0)),
      TodayWorkoutSessionRoute(id: _summary.id).location,
    );
    expect(
      await tapWith(TodayWorkoutPlanned(template: _template)),
      TodayWorkoutLogRoute(date: testToday, template: _id).location,
    );
    expect(
      await tapWith(const TodayWorkoutNone()),
      TodayWorkoutLogRoute(date: testToday).location,
    );
    // A past day with only an earlier session: a free session on that day,
    // no last-session text.
    expect(
      await tapWith(
        TodayWorkoutLast(summary: _summary, daysAgo: 3),
        date: testYesterday,
      ),
      TodayWorkoutLogRoute(date: testYesterday).location,
    );
    final tile = tester.widget<FbGlanceTile>(find.byKey(_workoutKey));
    expect(tile.text, isNot(contains('Push')));
  });

  testWidgets('A57 D5 a failed read shows a quiet half whose tap retries', (
    tester,
  ) async {
    var reads = 0;
    await _pump(
      tester,
      weight: _weights['weight none']!,
      workout: todayWorkoutProvider.overrideWith((ref, date) {
        reads++;
        throw StateError('read failed');
      }),
    );
    expect(tester.widget<FbGlanceTile>(find.byKey(_workoutKey)).muted, isTrue);
    final before = reads;
    await tester.tap(find.byKey(_workoutKey));
    await tester.pump();
    expect(reads, greaterThan(before));
  });
}
