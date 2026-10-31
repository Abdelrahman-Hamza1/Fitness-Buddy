import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

String _id(int n) =>
    '0199e3c2-5b1a-7c3d-8e4f-${n.toRadixString(16).padLeft(12, '0')}';

SessionEntry _session(
  int id,
  LocalDate date,
  Map<String, List<SetValues>> exercises,
) {
  var n = id * 100;
  return (
    id: _id(id),
    draft: WorkoutSessionDraft(
      date: date,
      exercises: [
        for (final MapEntry(:key, :value) in exercises.entries)
          SessionExerciseDraft(
            id: _id(++n),
            exerciseId: key,
            sets: [for (final v in value) LoggedSet(_id(++n), v)],
          ),
      ],
    ),
  );
}

SetValues _kg(double kg, int reps) => SetValues(kg: kg, reps: reps);

void main() {
  test('A52 D4 a union keeps main muscles primary, in exercise order', () {
    final union = MuscleUnion.of([
      (primary: Muscle.chest, secondaries: [Muscle.triceps, Muscle.shoulders]),
      (primary: Muscle.shoulders, secondaries: [Muscle.triceps]),
      (primary: null, secondaries: [Muscle.abs]),
      (primary: Muscle.chest, secondaries: const []),
    ]);
    expect(union.primary, [Muscle.chest, Muscle.shoulders]);
    expect(union.secondary, [Muscle.triceps, Muscle.abs]);
  });

  Glados(any.list(any.list(any.intInRange(0, Muscle.values.length)))).test(
    'A52 D4 primary and secondary never overlap; nothing is lost',
    (raw) {
      final exercises = [
        for (final codes in raw)
          (
            primary: codes.isEmpty ? null : Muscle.values[codes.first],
            secondaries: [for (final c in codes.skip(1)) Muscle.values[c]],
          ),
      ];
      final union = MuscleUnion.of(exercises);
      expect(
        union.primary.toSet().intersection(union.secondary.toSet()),
        isEmpty,
      );
      expect(union.primary.toSet(), hasLength(union.primary.length));
      expect(union.secondary.toSet(), hasLength(union.secondary.length));
      final all = {
        for (final e in exercises) ...[?e.primary, ...e.secondaries],
      };
      expect({...union.primary, ...union.secondary}, all);
    },
  );

  test('WO-001 A52 D3 recent exercises: newest first, distinct, top set', () {
    final sessions = [
      _session(1, LocalDate(2026, 10, 20), {
        'ex:bench': [_kg(60, 8)],
        'ex:squat': [_kg(80, 6), _kg(80, 5)],
      }),
      _session(2, LocalDate(2026, 10, 27), {
        'ex:bench': [_kg(62.5, 8), _kg(62.5, 7), _kg(60, 10)],
        'ex:plank': [const SetValues(durationSeconds: 60)],
        'ex:empty': const [],
      }),
    ];
    ExerciseType? typeOf(String id) =>
        id == 'ex:plank' ? ExerciseType.duration : ExerciseType.weightReps;
    final recent = RecentExercises.of(sessions, typeOf);
    expect(
      [for (final r in recent) r.exerciseId],
      ['ex:bench', 'ex:plank', 'ex:squat'],
    );
    // The newest session's heaviest set, most reps on equal weight.
    expect(recent.first.top.kg, 62.5);
    expect(recent.first.top.reps, 8);
    expect(recent.first.date, LocalDate(2026, 10, 27));
    expect(recent[1].top.durationSeconds, 60);
    expect(recent[2].top.reps, 6);
    expect(RecentExercises.of(sessions, typeOf, limit: 1), hasLength(1));
  });
}
