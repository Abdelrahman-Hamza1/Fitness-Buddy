import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

String _id(int n) =>
    '0199e3c2-5b1a-7c3d-8e4f-${n.toRadixString(16).padLeft(12, '0')}';

LogFormSet _set(int n, {required bool checked, int? reps = 8}) => LogFormSet(
  id: _id(n),
  checked: checked,
  value: reps == null ? null : LoggedSet(_id(n), SetValues(reps: reps, kg: 80)),
);

final _date = LocalDate(2026, 10, 30);

void main() {
  test('WO-034 saved draft keeps only checked sets and exercises with one', () {
    final form = [
      LogFormExercise(
        id: _id(1),
        exerciseId: 'ex:barbell_bench_press',
        sets: [
          _set(11, checked: true),
          _set(12, checked: false),
          _set(13, checked: true, reps: 6),
        ],
      ),
      // No checked set: left out of the saved session, card stays.
      LogFormExercise(
        id: _id(2),
        exerciseId: 'ex:pull_up',
        sets: [_set(21, checked: false)],
      ),
      // Checked without values yet: nothing to save.
      LogFormExercise(
        id: _id(3),
        exerciseId: 'ex:push_up',
        sets: [_set(31, checked: true, reps: null)],
      ),
      LogFormExercise(
        id: _id(4),
        exerciseId: 'ex:squat',
        sets: [_set(41, checked: true)],
      ),
    ];
    final draft = LogFormDraft.savedDraftOf(form, date: _date, name: ' ')!;
    expect(draft.name, isNull);
    expect([for (final e in draft.exercises) e.id], [_id(1), _id(4)]);
    expect(
      [for (final s in draft.exercises.first.sets) s.id],
      [_id(11), _id(13)],
    );
    expect(draft.exercises.first.sets.last.values.reps, 6);

    // Unchecking the last checked set of an exercise drops the exercise;
    // nothing checked at all is no session.
    expect(
      LogFormDraft.savedDraftOf([
        LogFormExercise(
          id: _id(1),
          exerciseId: 'ex:barbell_bench_press',
          sets: [_set(11, checked: false)],
        ),
      ], date: _date),
      isNull,
    );
    expect(LogFormDraft.savedDraftOf(const [], date: _date), isNull);
    expect(
      () => LogFormSet(
        id: _id(1),
        checked: true,
        value: LoggedSet(_id(2), const SetValues(reps: 1, kg: 1)),
      ),
      throwsArgumentError,
    );
  });

  Glados(
    any.list(any.list(any.bool)),
    propertyRuns,
  ).test('WO-034 saved draft = checked sets in form order', (form) {
    var n = 0;
    final exercises = [
      for (final (i, checks) in form.take(30).indexed)
        LogFormExercise(
          id: _id(100000 + i),
          exerciseId: 'ex:e$i',
          sets: [
            for (final checked in checks.take(40)) _set(++n, checked: checked),
          ],
        ),
    ];
    final saved = LogFormDraft.exercisesOf(exercises);
    // One string per exercise: its ID, then its set IDs.
    final expected = [
      for (final e in exercises)
        if (e.sets.any((s) => s.checked))
          [
            e.id,
            for (final s in e.sets)
              if (s.checked) s.id,
          ].join(' '),
    ];
    expect([
      for (final e in saved) [e.id, for (final s in e.sets) s.id].join(' '),
    ], expected);
  });
}
