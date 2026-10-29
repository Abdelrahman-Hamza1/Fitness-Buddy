import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

const _id = '0199e3c2-5b1a-7c3d-8e4f-0123456789ab';
const _id2 = '0199e3c2-5b1a-7c3d-8e4f-0123456789ac';
const _bench = 'ex:barbell_bench_press';
const _set1 = '0199e3c2-5b1a-7c3d-8e4f-0123456789b1';
const _set2 = '0199e3c2-5b1a-7c3d-8e4f-0123456789b2';

WorkoutSessionDraft _session({LocalDate? date}) => WorkoutSessionDraft(
  date: date ?? LocalDate(2026, 10, 28),
  name: ' Push ',
  exercises: [
    SessionExerciseDraft(
      id: _id2,
      exerciseId: _bench,
      sets: [
        LoggedSet(_set1, const SetValues(reps: 8, kg: 80)),
        LoggedSet(_set2, const SetValues(reps: 7, kg: 80)),
      ],
    ),
  ],
);

void main() {
  test(
    'WO-003 a custom exercise trims its name and drops duplicate aliases',
    () {
      final draft = CustomExerciseDraft(
        name: '  Cable fly low to high ',
        type: ExerciseType.weightReps,
        equipment: Equipment.cable,
        aliases: ['low fly', 'low fly ', 'lth fly'],
      );
      expect(draft.name, 'Cable fly low to high');
      expect(draft.aliases, ['low fly', 'lth fly']);
      expect(draft.toString(), isNot(contains('fly')));
    },
  );

  test('WO-003 a blank or long name and too many aliases are rejected', () {
    expect(
      () => CustomExerciseDraft(
        name: ' ',
        type: ExerciseType.repsOnly,
        equipment: Equipment.bodyweight,
      ),
      throwsArgumentError,
    );
    expect(
      () => CustomExerciseDraft(
        name: 'x' * 81,
        type: ExerciseType.repsOnly,
        equipment: Equipment.bodyweight,
      ),
      throwsArgumentError,
    );
    expect(
      () => CustomExerciseDraft(
        name: 'Fly',
        type: ExerciseType.repsOnly,
        equipment: Equipment.bodyweight,
        aliases: [for (var i = 0; i < 11; i++) 'a$i'],
      ),
      throwsArgumentError,
    );
  });

  test('WO-002 exercise IDs are catalog IDs or custom UUIDs', () {
    expect(checkExerciseId(_bench, 'id'), _bench);
    expect(checkExerciseId(_id, 'id'), _id);
    expect(() => checkExerciseId('bench', 'id'), throwsArgumentError);
    expect(() => checkExerciseId('ex:Bench Press', 'id'), throwsArgumentError);
  });

  test('WO-010 a session keeps date, name, exercises and sets in order', () {
    final draft = _session();
    expect(draft.name, 'Push');
    expect(draft.exercises.single.sets.map((s) => s.values.reps), [8, 7]);
    expect(draft, _session());
    expect(draft.toString(), isNot(contains('Push')));
  });

  test('WO-011 sessions can be for any past date, never a future one', () {
    final today = LocalDate(2026, 10, 29);
    expect(_session(date: LocalDate(2025, 1, 1)).isAfter(today), isFalse);
    expect(_session(date: today).isAfter(today), isFalse);
    expect(_session(date: today.plusDays(1)).isAfter(today), isTrue);
  });

  test('WO-010 session duration and exercise count are bounded', () {
    expect(
      () => WorkoutSessionDraft(
        date: LocalDate(2026, 10, 28),
        exercises: const [],
        durationMinutes: 0,
      ),
      throwsArgumentError,
    );
    expect(
      () => WorkoutSessionDraft(
        date: LocalDate(2026, 10, 28),
        exercises: const [],
        templateId: 'push',
      ),
      throwsArgumentError,
    );
  });

  test('A36 D1 a set keeps the weight as typed', () {
    final set = LoggedSet(
      _set1,
      const SetValues(reps: 8, kg: 79.832257),
      inputValue: 176,
      inputUnit: MassUnit.pound,
    );
    expect(set.inputValue, 176);
    expect(set.inputUnit, MassUnit.pound);
    expect(
      () => LoggedSet(_set1, const SetValues(reps: 8), inputValue: 10),
      throwsArgumentError,
    );
    expect(
      () => LoggedSet(
        _set1,
        const SetValues(reps: 8, kg: 1),
        inputUnit: MassUnit.gram,
      ),
      throwsArgumentError,
    );
  });

  test('A36 D7 child row IDs are UUIDs, unique within the aggregate', () {
    expect(
      () => LoggedSet('set-1', const SetValues(reps: 8, kg: 80)),
      throwsArgumentError,
    );
    expect(
      () => WorkoutSessionDraft(
        date: LocalDate(2026, 10, 28),
        exercises: [
          SessionExerciseDraft(
            id: _id2,
            exerciseId: _bench,
            sets: [
              LoggedSet(_set1, const SetValues(reps: 8, kg: 80)),
              LoggedSet(_set1, const SetValues(reps: 8, kg: 80)),
            ],
          ),
        ],
      ),
      throwsArgumentError,
    );
    expect(
      () => WorkoutSessionDraft(
        date: LocalDate(2026, 10, 28),
        exercises: [
          SessionExerciseDraft(id: _id2, exerciseId: _bench, sets: const []),
          SessionExerciseDraft(id: _id2, exerciseId: _bench, sets: const []),
        ],
      ),
      throwsArgumentError,
    );
    expect(
      () => WorkoutTemplateDraft(
        name: 'Push',
        items: [
          TemplateItemDraft(id: _id2, exerciseId: _bench, sets: 3, reps: 8),
          TemplateItemDraft(id: _id2, exerciseId: _bench, sets: 3, reps: 8),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('WO-020 template items need 1–20 sets and positive reps', () {
    final template = WorkoutTemplateDraft(
      name: 'Push',
      items: [
        TemplateItemDraft(id: _id2, exerciseId: _bench, sets: 3, reps: 8),
      ],
    );
    expect(template.items.single.sets, 3);
    expect(
      () => TemplateItemDraft(id: _id2, exerciseId: _bench, sets: 0, reps: 8),
      throwsArgumentError,
    );
    expect(
      () => TemplateItemDraft(id: _id2, exerciseId: _bench, sets: 3, reps: 0),
      throwsArgumentError,
    );
  });

  test('WO-021 plan days name a weekday and a template or rest', () {
    expect(SetPlanDay(DayOfWeek.saturday, _id).templateId, _id);
    expect(SetPlanDay(DayOfWeek.monday, null).templateId, isNull);
    expect(() => SetPlanDay(DayOfWeek.monday, 'push'), throwsArgumentError);
  });

  test('every workout op is in the workout family with value equality', () {
    final v = VersionedId(_id, 1);
    final exercise = CustomExerciseDraft(
      name: 'Fly',
      type: ExerciseType.weightReps,
      equipment: Equipment.cable,
    );
    final template = WorkoutTemplateDraft(name: 'Push', items: const []);
    final ops = <WorkoutOp Function()>[
      () => CreateCustomExercise(_id, exercise),
      () => UpdateCustomExercise(v, exercise),
      () => DeleteCustomExercise(v),
      () => LogWorkoutSession(_id, _session()),
      () => UpdateWorkoutSession(v, _session()),
      () => DeleteWorkoutSession(v),
      () => CreateWorkoutTemplate(_id, template),
      () => UpdateWorkoutTemplate(v, template),
      () => DeleteWorkoutTemplate(v),
      () => SetPlanDay(DayOfWeek.sunday, _id),
    ];
    for (final make in ops) {
      final op = make();
      expect(op.family, WorkoutOp.familyName);
      expect(make(), op);
      expect(make().hashCode, op.hashCode);
      expect(op.toString(), isNot(contains('Fly')));
      expect(op.toString(), isNot(contains('Push')));
    }
    expect(() => CreateCustomExercise('x', exercise), throwsArgumentError);
  });
}
