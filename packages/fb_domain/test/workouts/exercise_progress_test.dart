import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

const _bench = 'ex:barbell_bench_press';
const _other = 'ex:squat';

String _id(int n) =>
    '0199e3c2-5b1a-7c3d-8e4f-${n.toRadixString(16).padLeft(12, '0')}';

var _next = 1000;

LoggedSet _set({int? reps, double? kg, int? seconds, double? meters}) =>
    LoggedSet(
      _id(_next++),
      SetValues(
        reps: reps,
        kg: kg,
        durationSeconds: seconds,
        distanceMeters: meters,
      ),
    );

SessionEntry _session(
  int id,
  LocalDate date,
  Map<String, List<LoggedSet>> exercises,
) => (
  id: _id(id),
  draft: WorkoutSessionDraft(
    date: date,
    exercises: [
      for (final MapEntry(:key, :value) in exercises.entries)
        SessionExerciseDraft(id: _id(_next++), exerciseId: key, sets: value),
    ],
  ),
);

final _d1 = LocalDate(2026, 10, 1);
final _d2 = LocalDate(2026, 10, 3);
final _d3 = LocalDate(2026, 10, 5);

void main() {
  test('WO-041 heaviest-set series per session; e1RM series by Epley', () {
    final history = [
      _session(3, _d3, {
        _bench: [_set(reps: 5, kg: 85), _set(reps: 10, kg: 75)],
      }),
      _session(1, _d1, {
        _bench: [_set(reps: 8, kg: 80), _set(reps: 8, kg: 80)],
      }),
      // A session without the exercise has no point.
      _session(2, _d2, {
        _other: [_set(reps: 5, kg: 100)],
      }),
    ];
    final progress = ExerciseProgress.of(
      history,
      _bench,
      ExerciseType.weightReps,
    );
    expect(progress.main, ExerciseMetric.heaviest);
    expect(progress.hasE1rm, isTrue);
    expect(progress.sessions.map((s) => s.sessionId), [_id(1), _id(3)]);
    expect(progress.series(ExerciseMetric.heaviest).map((p) => p.value), [
      80,
      85,
    ]);
    // Session 3: 75 × 10 → 100.0 beats 85 × 5 → 99.17.
    expect(progress.series(ExerciseMetric.e1rm).map((p) => p.value), [
      closeTo(80 * (1 + 8 / 30), 1e-9),
      closeTo(100, 1e-9),
    ]);
    expect(progress.records.heaviestKg, 85);
    expect(
      progress.best(ExerciseMetric.e1rm),
      closeTo(80 * (1 + 8 / 30), 1e-9),
    );
  });

  test('WO-041 reps-only and cardio series use best reps / longest', () {
    final pushUps = ExerciseProgress.of(
      [
        _session(1, _d1, {
          _bench: [_set(reps: 20), _set(reps: 25)],
        }),
        _session(2, _d2, {
          _bench: [_set(reps: 22)],
        }),
      ],
      _bench,
      ExerciseType.repsOnly,
    );
    expect(pushUps.main, ExerciseMetric.mostReps);
    expect(pushUps.hasE1rm, isFalse);
    expect(pushUps.series(ExerciseMetric.mostReps).map((p) => p.value), [
      25,
      22,
    ]);
    // No weight line for reps-only sets.
    expect(pushUps.series(ExerciseMetric.heaviest), isEmpty);

    final run = ExerciseProgress.of(
      [
        _session(1, _d1, {
          _bench: [_set(seconds: 1200, meters: 3000)],
        }),
        _session(2, _d2, {
          _bench: [_set(seconds: 1800), _set(seconds: 600, meters: 4000)],
        }),
      ],
      _bench,
      ExerciseType.distanceDuration,
    );
    expect(run.main, ExerciseMetric.longest);
    expect(run.series(ExerciseMetric.longest).map((p) => p.value), [
      1200,
      1800,
    ]);
    expect(run.farthestMeters, 4000);
    expect(run.records.heaviestKg, isNull);

    // Assisted: kg is help, never a weight line.
    final assisted = ExerciseProgress.of(
      [
        _session(1, _d1, {
          _bench: [_set(reps: 8, kg: 30)],
        }),
      ],
      _bench,
      ExerciseType.assisted,
    );
    expect(assisted.main, ExerciseMetric.mostReps);
    expect(assisted.series(ExerciseMetric.heaviest), isEmpty);
  });
}
