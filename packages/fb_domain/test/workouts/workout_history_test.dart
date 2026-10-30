import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

const _bench = 'ex:barbell_bench_press';
const _pullUp = 'ex:pull_up';
const _pushUp = 'ex:push_up';
const _assisted = 'ex:assisted_pull_up';
const _plank = 'ex:plank';
const _run = 'ex:treadmill';

/// A deterministic UUID; [n] orders IDs like UUIDv7 time order.
String _id(int n) =>
    '0199e3c2-5b1a-7c3d-8e4f-${n.toRadixString(16).padLeft(12, '0')}';

var _next = 1000;

LoggedSet _set({int? reps, double? kg, int? seconds}) => LoggedSet(
  _id(_next++),
  SetValues(reps: reps, kg: kg, durationSeconds: seconds),
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

ExerciseType? _types(String id) => switch (id) {
  _bench => ExerciseType.weightReps,
  _pullUp => ExerciseType.bodyweightReps,
  _pushUp => ExerciseType.repsOnly,
  _assisted => ExerciseType.assisted,
  _plank => ExerciseType.duration,
  _run => ExerciseType.distanceDuration,
  _ => null,
};

final _d1 = LocalDate(2026, 10, 1);
final _d2 = LocalDate(2026, 10, 3);
final _d3 = LocalDate(2026, 10, 5);

void main() {
  test('WO-034 last performance picks the latest earlier session per set '
      'index', () {
    final sessions = [
      _session(3, _d2, {
        _bench: [_set(reps: 8, kg: 80), _set(reps: 7, kg: 80)],
      }),
      _session(1, _d1, {
        _bench: [_set(reps: 8, kg: 75)],
      }),
      // Same day as session 3 but logged later (bigger UUIDv7): the latest.
      _session(4, _d2, {
        _bench: [_set(reps: 6, kg: 82.5), _set(reps: 6, kg: 82.5)],
        _pullUp: [_set(reps: 10)],
      }),
      // An earlier session without the exercise doesn't hide older ones.
      _session(5, _d2, {
        _pullUp: [_set(reps: 9)],
      }),
    ];
    final last = LastPerformance.of(
      sessions,
      _bench,
      date: _d3,
      sessionId: _id(9),
    );
    expect(last, const [
      SetValues(reps: 6, kg: 82.5),
      SetValues(reps: 6, kg: 82.5),
    ]);
    expect(
      LastPerformance.of(sessions, _plank, date: _d3, sessionId: _id(9)),
      isEmpty,
    );
  });

  test('WO-034 last performance ignores the session being edited and later '
      'dates', () {
    final sessions = [
      _session(1, _d1, {
        _bench: [_set(reps: 8, kg: 75)],
      }),
      _session(2, _d2, {
        _bench: [_set(reps: 8, kg: 80)],
      }),
      _session(3, _d3, {
        _bench: [_set(reps: 8, kg: 85)],
      }),
    ];
    // Editing session 2: what came before it, not itself or session 3.
    expect(
      LastPerformance.of(sessions, _bench, date: _d2, sessionId: _id(2)),
      const [SetValues(reps: 8, kg: 75)],
    );
    // A new session back-dated to the first day sees nothing earlier.
    expect(
      LastPerformance.of(sessions, _bench, date: _d1, sessionId: _id(1)),
      isEmpty,
    );
  });

  test('WO-042 first session of an exercise never marks a PR', () {
    final first = _session(1, _d1, {
      _bench: [_set(reps: 8, kg: 80)],
      _pullUp: [_set(reps: 12)],
    });
    final prs = SessionPrs.of([first], _types);
    expect(prs.countOf(first.id), 0);
    for (final exercise in first.draft.exercises) {
      expect(prs.ofExercise(exercise.id), isEmpty);
      for (final set in exercise.sets) {
        expect(prs.ofSet(set.id), isEmpty);
      }
    }
  });

  test('WO-042 heavier set marks a PR against earlier sessions only', () {
    final heavy = _set(reps: 5, kg: 85);
    final light = _set(reps: 5, kg: 80);
    final sessions = [
      _session(1, _d1, {
        _bench: [_set(reps: 8, kg: 80)],
      }),
      // Two heavier sets in one session: both beat the earlier records,
      // they don't compete with each other.
      _session(2, _d2, {
        _bench: [heavy, _set(reps: 5, kg: 87.5)],
      }),
      // Lighter than session 2: no PR, though heavier than session 1.
      _session(3, _d3, {
        _bench: [light],
      }),
    ];
    final prs = SessionPrs.of(sessions, _types);
    expect(prs.ofSet(heavy.id), contains(PrKind.heaviest));
    expect(prs.ofExercise(sessions[1].draft.exercises.single.id), {
      PrKind.heaviest,
      PrKind.e1rm,
    });
    expect(prs.countOf(sessions[1].id), 1);
    expect(prs.ofSet(light.id), isEmpty);
    expect(prs.countOf(sessions[2].id), 0);
  });

  test('WO-042 reps at a new weight is not a PR, more reps at a known '
      'weight is', () {
    final newWeight = _set(reps: 3, kg: 60);
    final moreReps = _set(reps: 10, kg: 80);
    final sessions = [
      _session(1, _d1, {
        _bench: [_set(reps: 8, kg: 80)],
      }),
      _session(2, _d2, {
        _bench: [newWeight],
      }),
      _session(3, _d3, {
        _bench: [moreReps],
      }),
    ];
    final prs = SessionPrs.of(sessions, _types);
    expect(prs.ofSet(newWeight.id), isEmpty);
    expect(prs.ofSet(moreReps.id), contains(PrKind.repsAtWeight));
    // Bodyweight: most reps only, never "heaviest".
    final more = _set(reps: 12);
    final loaded = _set(reps: 5, kg: 10);
    final bodyweight = [
      _session(1, _d1, {
        _pullUp: [_set(reps: 10)],
      }),
      _session(2, _d2, {
        _pullUp: [more, loaded],
      }),
    ];
    final bodyweightPrs = SessionPrs.of(bodyweight, _types);
    expect(bodyweightPrs.ofSet(more.id), {PrKind.repsAtWeight});
    expect(bodyweightPrs.ofSet(loaded.id), isEmpty);
  });

  test('WO-042 assisted, time and cardio never mark PRs', () {
    final sessions = [
      _session(1, _d1, {
        _assisted: [_set(reps: 8, kg: 30)],
        _plank: [_set(seconds: 60)],
        _run: [_set(seconds: 600)],
      }),
      _session(2, _d2, {
        _assisted: [_set(reps: 12, kg: 30)],
        _plank: [_set(seconds: 120)],
        _run: [_set(seconds: 1800)],
      }),
    ];
    final prs = SessionPrs.of(sessions, _types);
    expect(prs.countOf(sessions[1].id), 0);
    expect(
      liftedSetOf(ExerciseType.assisted, const SetValues(reps: 8)),
      isNull,
    );
    expect(liftedSetOf(ExerciseType.repsOnly, const SetValues(reps: 20)), (
      kg: 0.0,
      reps: 20,
    ));
  });

  test('WO-042 PR count counts exercises, not sets', () {
    final sessions = [
      _session(1, _d1, {
        _bench: [_set(reps: 8, kg: 80)],
        _pushUp: [_set(reps: 20)],
      }),
      _session(2, _d2, {
        _bench: [
          _set(reps: 8, kg: 82.5),
          _set(reps: 8, kg: 85),
          _set(reps: 9, kg: 80),
        ],
        _pushUp: [_set(reps: 25)],
        _id(77): [_set(reps: 5, kg: 50)], // unknown exercise: no records
      }),
    ];
    expect(SessionPrs.of(sessions, _types).countOf(sessions[1].id), 2);
  });
}
