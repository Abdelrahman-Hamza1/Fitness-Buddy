import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:test/test.dart';

String _id(int n) =>
    '0199e3c2-5b1a-7c3d-8e4f-${n.toRadixString(16).padLeft(12, '0')}';

const _bench = 'ex:barbell_bench_press';
const _ohp = 'ex:standing_barbell_overhead_press';
const _plank = 'ex:plank';

ExerciseType? _types(String id) => switch (id) {
  _bench || _ohp => ExerciseType.weightReps,
  _plank => ExerciseType.duration,
  _ => null,
};

final _template = WorkoutTemplateDraft(
  name: 'Push',
  items: [
    TemplateItemDraft(id: _id(1), exerciseId: _bench, sets: 3, reps: 8),
    TemplateItemDraft(id: _id(2), exerciseId: _ohp, sets: 3, reps: 10),
  ],
);

var _next = 100;

WorkoutSessionDraft _session(Map<String, List<SetValues>> exercises) =>
    WorkoutSessionDraft(
      date: LocalDate(2026, 10, 1),
      templateId: _id(50),
      exercises: [
        for (final MapEntry(:key, :value) in exercises.entries)
          SessionExerciseDraft(
            id: _id(_next++),
            exerciseId: key,
            sets: [for (final v in value) LoggedSet(_id(_next++), v)],
          ),
      ],
    );

SetValues _r(int reps) => SetValues(reps: reps, kg: 60);

void main() {
  test('WO-022 the offer content exists only when the session differs from '
      'its template', () {
    // As planned, with trailing fatigue: no offer.
    expect(
      templateUpdateFor(
        _template,
        _session({
          _bench: [_r(8), _r(8), _r(7)],
          _ohp: [_r(10), _r(10), _r(9)],
        }),
        _types,
      ),
      isNull,
    );
    // A plank added: time exercises can't be lines, still no offer.
    expect(
      templateUpdateFor(
        _template,
        _session({
          _bench: [_r(8), _r(8), _r(8)],
          _ohp: [_r(10), _r(10), _r(10)],
          _plank: [const SetValues(durationSeconds: 60)],
        }),
        _types,
      ),
      isNull,
    );
    // A fourth bench set: offer the new lines.
    final targets = templateUpdateFor(
      _template,
      _session({
        _bench: [_r(8), _r(8), _r(8), _r(8)],
        _ohp: [_r(10), _r(10), _r(10)],
      }),
      _types,
    );
    expect(targets, [
      (exerciseId: _bench, sets: 4, reps: 8),
      (exerciseId: _ohp, sets: 3, reps: 10),
    ]);
    // Kept exercises keep their item IDs; a new one gets a new ID.
    final updated = templateWithTargets(_template, [
      ...targets!,
      (exerciseId: 'ex:dumbbell_lateral_raise', sets: 3, reps: 15),
    ], SequenceIdGenerator());
    expect(updated.name, 'Push');
    expect(updated.items.map((i) => i.id).take(2), [_id(1), _id(2)]);
    expect(updated.items.last.id, isNot(anyOf(_id(1), _id(2))));
    expect(updated.items.first.sets, 4);
  });

  test('WO-043 weekly summary counts sessions, planned only with a plan, and '
      'PRs', () {
    final start = LocalDate(2026, 10, 24);
    SessionEntry entry(int n, LocalDate date) => (
      id: _id(n),
      draft: WorkoutSessionDraft(date: date, exercises: const []),
    );
    final history = [
      entry(1, LocalDate(2026, 10, 23)), // the week before
      entry(2, start),
      entry(3, LocalDate(2026, 10, 27)),
      entry(4, LocalDate(2026, 10, 30)), // the last day
      entry(5, LocalDate(2026, 10, 31)), // the week after
    ];
    int prs(String id) => {_id(1): 5, _id(3): 2, _id(4): 1}[id] ?? 0;
    expect(
      WeeklyWorkoutSummary.of(
        history: history,
        plan: const {},
        weekStart: start,
        prCountOf: prs,
      ),
      const WeeklyWorkoutSummary(sessions: 3, planned: null, prs: 3),
    );
    expect(
      WeeklyWorkoutSummary.of(
        history: history,
        plan: {DayOfWeek.saturday: _id(9), DayOfWeek.tuesday: _id(9)},
        weekStart: start,
        prCountOf: prs,
      ).planned,
      2,
    );
  });
}
