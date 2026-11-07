import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../proposals/proposal_fixtures.dart' show FixedIds;

final _now = EntryTime(DateTime.utc(2026, 10, 13, 12), 180);
final LocalDate _today = _now.localDate;

const _bench = ExerciseFacts(
  id: 'ex:bench_press',
  name: 'Bench press',
  type: ExerciseType.weightReps,
  equipment: Equipment.barbell,
);
const _incline = ExerciseFacts(
  id: 'ex:incline_db_press',
  name: 'Incline dumbbell press',
  type: ExerciseType.weightReps,
  equipment: Equipment.dumbbell,
);
const _dips = ExerciseFacts(
  id: 'ex:dips',
  name: 'Dips',
  type: ExerciseType.bodyweightReps,
  equipment: Equipment.bodyweight,
);

RecordFacts _facts({
  Map<int, List<ExerciseFacts>> candidates = const {},
  Map<String, List<LiftedSet>> lifted = const {},
  List<WeighIn> weighIns = const [],
  List<Measurement> measurements = const [],
  Set<String> customTypes = const {},
  MassUnit mass = MassUnit.kilogram,
}) => RecordFacts(
  now: _now,
  slots: DefaultSlots.all,
  exercises: {
    for (final e in [_bench, _incline, _dips]) e.id: e,
  },
  exerciseCandidates: candidates,
  liftedSets: lifted,
  weighIns: weighIns,
  measurements: measurements,
  customMeasurementTypes: customTypes,
  massUnit: mass,
);

RecordPlan _plan(
  RecordRequest r,
  RecordFacts f, {
  RecordAdjust adjust = RecordAdjust.none,
}) => RecordPlanner.plan(r, f, FixedIds(), adjust: adjust);

List<WorkoutSetInput> _sets(int n, int reps, double w, {String unit = 'kg'}) =>
    [
      for (var i = 0; i < n; i++)
        WorkoutSetInput(reps: reps, weight: w, unit: unit),
    ];

WorkoutRecord _workout(List<WorkoutExerciseInput> exercises, {String? day}) =>
    WorkoutRecord(
      name: 'Push',
      when: RecordDayHint(dateHint: day),
      exercises: exercises,
    );

LogWorkoutSession _session(RecordPlan p) =>
    p.ops.whereType<LogWorkoutSession>().single;

WeighIn _weighIn(String day, double kg) => WeighIn(
  id: '019a1b2c-0000-7000-8000-${day.replaceAll('-', '').padLeft(12, '0')}',
  version: 1,
  time: EntryTime.local(LocalTime(8).on(LocalDate.parse(day)), 180),
  localDate: LocalDate.parse(day),
  kg: kg,
  input: WeighInInput(kg, MassUnit.kilogram),
);

ImportRowsRecord _import(
  List<(String?, double?, String?)> rows, {
  String? kind,
}) => ImportRowsRecord(
  measurementKind: kind,
  rows: [
    for (final (d, v, u) in rows)
      ImportRowInput(original: '$d: $v$u', date: d, value: v, unit: u),
  ],
);

void main() {
  group('workout (A69 D3)', () {
    test('AI-053 WO-030 a session logs each exercise with its sets in kg', () {
      final p = _plan(
        _workout([
          WorkoutExerciseInput(
            mention: 'bench',
            exerciseRef: _bench.id,
            sets: _sets(3, 8, 80),
          ),
          WorkoutExerciseInput(
            mention: 'incline db',
            exerciseRef: _incline.id,
            sets: [
              for (var i = 0; i < 3; i++)
                const WorkoutSetInput(
                  reps: 10,
                  weight: 24,
                  unit: 'kg',
                  perDumbbell: true,
                ),
            ],
          ),
        ]),
        _facts(),
      );
      expect(p.canConfirm, isTrue);
      final draft = _session(p).draft;
      expect(draft.date, _today);
      expect(draft.name, 'Push');
      expect(draft.exercises.map((e) => e.exerciseId), [
        _bench.id,
        _incline.id,
      ]);
      expect(draft.exercises.first.sets.map((s) => s.values.kg), [80, 80, 80]);
      expect(draft.exercises.last.sets.first.values.kg, 24);
      expect(p.view!.workout!.exercises.last.splitPerDumbbell, isFalse);
    });

    test('WO-031 lb keeps the typed value; a dumbbell total is split', () {
      final p = _plan(
        _workout([
          WorkoutExerciseInput(
            mention: 'bench',
            exerciseRef: _bench.id,
            sets: _sets(1, 5, 225, unit: 'lb'),
          ),
          const WorkoutExerciseInput(
            mention: 'incline',
            exerciseRef: 'ex:incline_db_press',
            sets: [WorkoutSetInput(reps: 8, weight: 60, unit: 'kg')],
          ),
          const WorkoutExerciseInput(
            mention: 'dips',
            exerciseRef: 'ex:dips',
            sets: [WorkoutSetInput(reps: 8, weight: 0, unit: 'kg')],
          ),
        ]),
        _facts(),
      );
      final ex = _session(p).draft.exercises;
      final lb = ex.first.sets.single;
      expect(lb.values.kg, closeTo(102.06, 0.01));
      expect((lb.inputValue, lb.inputUnit), (225, MassUnit.pound));
      expect(ex[1].sets.single.values.kg, 30);
      expect(p.view!.workout!.exercises[1].splitPerDumbbell, isTrue);
      expect(ex[2].sets.single.values.kg, isNull);
    });

    test('WO-042 a set beating the earlier best is a PR hint', () {
      final p = _plan(
        _workout([
          WorkoutExerciseInput(
            mention: 'bench',
            exerciseRef: _bench.id,
            sets: [
              const WorkoutSetInput(reps: 8, weight: 80, unit: 'kg'),
              const WorkoutSetInput(reps: 5, weight: 90, unit: 'kg'),
            ],
          ),
          WorkoutExerciseInput(
            mention: 'incline',
            exerciseRef: _incline.id,
            sets: _sets(1, 10, 24),
          ),
        ]),
        _facts(
          lifted: {
            _bench.id: [(kg: 85.0, reps: 8)],
          },
        ),
      );
      final views = p.view!.workout!.exercises;
      expect(views.first.prSets, {1});
      // No history: not a record hint.
      expect(views.last.prSets, isEmpty);
    });

    test('WO-033 an unmatched exercise waits for a pick; a pick, a new '
        'exercise or leaving it out makes the card confirmable', () {
      final request = _workout([
        WorkoutExerciseInput(
          mention: 'bench',
          exerciseRef: _bench.id,
          sets: _sets(1, 8, 80),
        ),
        WorkoutExerciseInput(mention: 'zercher thing', sets: _sets(2, 5, 60)),
      ]);
      final facts = _facts(
        candidates: {
          1: [_bench],
        },
      );
      final waiting = _plan(request, facts);
      expect(waiting.canConfirm, isFalse);
      expect(waiting.view!.workout!.needsPick, isTrue);
      expect(waiting.view!.workout!.exercises.last.candidates, [_bench]);

      final picked = _plan(
        request,
        facts,
        adjust: RecordAdjust.none.pick(1, _bench.id),
      );
      expect(_session(picked).draft.exercises.last.exerciseId, _bench.id);

      final created = _plan(
        request,
        facts,
        adjust: RecordAdjust.none.pick(1, RecordAdjust.newExercise),
      );
      final custom = created.ops.whereType<CreateCustomExercise>().single;
      expect(custom.draft.name, 'zercher thing');
      expect(custom.draft.type, ExerciseType.weightReps);
      expect(_session(created).draft.exercises.last.exerciseId, custom.id);
      expect(created.view!.workout!.exercises.last.created, isTrue);

      final skipped = _plan(
        request,
        facts,
        adjust: RecordAdjust.none.pick(1, RecordAdjust.leaveOut),
      );
      expect(_session(skipped).draft.exercises, hasLength(1));
    });

    test('a new exercise takes its type from the sets', () {
      RecordPlan created(List<WorkoutSetInput> sets) => _plan(
        _workout([WorkoutExerciseInput(mention: 'x', sets: sets)]),
        _facts(),
        adjust: RecordAdjust.none.pick(0, RecordAdjust.newExercise),
      );
      ExerciseType typeOf(RecordPlan p) {
        // The card shows the sets with the type the new exercise gets.
        expect(
          p.view!.workout!.exercises.single.type,
          p.ops.whereType<CreateCustomExercise>().single.draft.type,
        );
        return p.ops.whereType<CreateCustomExercise>().single.draft.type;
      }

      expect(
        typeOf(created(const [WorkoutSetInput(durationSeconds: 60)])),
        ExerciseType.duration,
      );
      expect(
        typeOf(
          created(const [
            WorkoutSetInput(durationSeconds: 600, distanceMeters: 2000),
          ]),
        ),
        ExerciseType.distanceDuration,
      );
      expect(
        typeOf(created(const [WorkoutSetInput(reps: 20)])),
        ExerciseType.repsOnly,
      );
      expect(typeOf(created(const [])), ExerciseType.weightReps);
    });

    test('every exercise left out: nothing to confirm', () {
      final p = _plan(
        _workout([WorkoutExerciseInput(mention: 'x', sets: _sets(1, 5, 5))]),
        _facts(),
        adjust: RecordAdjust.none.pick(0, RecordAdjust.leaveOut),
      );
      expect(p.canConfirm, isFalse);
    });

    test(
      'a future day, a set not fitting the type or no exercises: no card',
      () {
        expect(
          _plan(
            _workout([
              WorkoutExerciseInput(
                mention: 'bench',
                exerciseRef: _bench.id,
                sets: _sets(1, 5, 5),
              ),
            ], day: 'date:2026-12-01'),
            _facts(),
          ).issue,
          RecordIssue.invalid,
        );
        expect(
          _plan(
            _workout([
              WorkoutExerciseInput(
                mention: 'bench',
                exerciseRef: _bench.id,
                sets: const [WorkoutSetInput(durationSeconds: 30)],
              ),
            ]),
            _facts(),
          ).issue,
          RecordIssue.invalid,
        );
        expect(_plan(_workout(const []), _facts()).issue, RecordIssue.invalid);
      },
    );

    test('a past day and a time phrase', () {
      final p = _plan(
        WorkoutRecord(
          when: const RecordDayHint(dateHint: 'yesterday', timeHint: 'evening'),
          exercises: [
            WorkoutExerciseInput(
              mention: 'bench',
              exerciseRef: _bench.id,
              sets: _sets(1, 5, 5),
            ),
          ],
        ),
        _facts(),
      );
      expect(_session(p).draft.date, _today.plusDays(-1));
      expect(_session(p).draft.name, isNull);
      expect(p.view!.notes, {RecordNote.timeIgnored});
    });
  });

  group('measurement (A69 D4)', () {
    test('WB-040 a waist measurement with the change since the last one', () {
      final p = _plan(
        const MeasurementRecord(
          kindCode: 'waist',
          value: 90,
          unit: 'cm',
          when: RecordDayHint(),
        ),
        _facts(
          measurements: [
            Measurement(
              id: '019a1b2c-0000-7000-8000-0000000000aa',
              version: 1,
              type: MeasurementTypeRef.builtIn(MeasurementKind.waist),
              time: _now.onDate(_today.plusDays(-7)),
              localDate: _today.plusDays(-7),
              value: 92,
              input: const MeasurementInput(92, MeasurementUnit.cm),
            ),
          ],
        ),
      );
      final op = p.ops.single as CreateMeasurement;
      expect(op.draft.value, 90);
      expect(p.view!.measurement!.delta, -2);
    });

    test('a unit not fitting the kind, an unknown custom type, bad values', () {
      expect(
        _plan(
          const MeasurementRecord(
            kindCode: 'bodyFat',
            value: 20,
            unit: 'cm',
            when: RecordDayHint(),
          ),
          _facts(),
        ).issue,
        RecordIssue.unsupportedUnit,
      );
      expect(
        _plan(
          const MeasurementRecord(
            kindCode: 'custom',
            customTypeId: '019a1b2c-0000-7000-8000-0000000000bb',
            value: 20,
            unit: 'cm',
            when: RecordDayHint(),
          ),
          _facts(),
        ).issue,
        RecordIssue.notFound,
      );
      final custom = _plan(
        const MeasurementRecord(
          kindCode: 'custom',
          customTypeId: '019a1b2c-0000-7000-8000-0000000000bb',
          value: 20,
          unit: 'cm',
          when: RecordDayHint(),
        ),
        _facts(customTypes: {'019a1b2c-0000-7000-8000-0000000000bb'}),
      );
      expect(custom.canConfirm, isTrue);
      expect(
        _plan(
          const MeasurementRecord(
            kindCode: 'waist',
            value: 900,
            unit: 'cm',
            when: RecordDayHint(),
          ),
          _facts(),
        ).issue,
        RecordIssue.invalid,
      );
      expect(
        _plan(
          const MeasurementRecord(
            kindCode: 'wing',
            value: 9,
            unit: 'cm',
            when: RecordDayHint(),
          ),
          _facts(),
        ).issue,
        RecordIssue.invalid,
      );
    });
  });

  group('import rows (A69 D5, WB-031)', () {
    List<ImportRowView> rows(RecordPlan p) => p.view!.imports!.rows;

    test('WB-030 "110k" is read as kg and flagged until accepted', () {
      final request = _import([
        ('2026-10-01', 110, 'k'),
        ('2026-10-05', 109.5, 'kg'),
      ]);
      final p = _plan(request, _facts());
      expect(rows(p).first.flags, {ImportFlag.unitInferred});
      expect(rows(p).first.canAccept, isTrue);
      expect(rows(p).map((r) => r.included), [false, true]);
      expect(p.ops, hasLength(1));
      final accepted = _plan(
        request,
        _facts(),
        adjust: RecordAdjust.none.accept(0, on: true),
      );
      expect(accepted.ops.whereType<CreateWeighIn>(), hasLength(2));
      expect(accepted.view!.imports!.includedCount, 2);
      final off = RecordAdjust.none.accept(0, on: true).accept(0, on: false);
      expect(_plan(request, _facts(), adjust: off).ops, hasLength(1));
    });

    test('WB-031 unclear dates and future rows are blocked; a missing unit '
        'uses the profile unit, flagged', () {
      final p = _plan(
        _import([
          (null, 100, 'kg'),
          ('2026-11-30', 100, 'kg'),
          ('2026-10-02', 220, null),
          ('2026-10-03', 100, 'stone'),
        ]),
        _facts(mass: MassUnit.pound),
      );
      expect(rows(p)[0].flags, contains(ImportFlag.unclearDate));
      expect(rows(p)[0].canAccept, isFalse);
      expect(rows(p)[1].flags, contains(ImportFlag.future));
      expect(rows(p)[2].flags, {ImportFlag.unitMissing});
      expect(rows(p)[2].unit, 'lb');
      expect(rows(p)[3].flags, contains(ImportFlag.unknownUnit));
      expect(p.ops, isEmpty);
      expect(p.canConfirm, isFalse);
    });

    test('WB-031 duplicates and implausible jumps are excluded until '
        'accepted', () {
      final request = _import([
        ('2026-10-01', 110, 'kg'),
        ('2026-10-06', 150, 'kg'),
      ]);
      final facts = _facts(weighIns: [_weighIn('2026-10-01', 110)]);
      final p = _plan(request, facts);
      expect(rows(p)[0].flags, contains(ImportFlag.duplicate));
      expect(rows(p)[1].flags, contains(ImportFlag.implausible));
      expect(p.ops, isEmpty);
      final kept = _plan(
        request,
        facts,
        adjust: RecordAdjust.none.accept(1, on: true),
      );
      expect(kept.ops.single, isA<CreateWeighIn>());
      expect(rows(kept)[1].included, isTrue);
    });

    test('WB-032 measurement rows: units, duplicates, jumps', () {
      final p = _plan(
        _import([
          ('2026-10-01', 90, 'cm'),
          ('2026-10-01', 90, 'cm'),
          ('2026-10-05', 120, 'cm'),
          ('2026-10-06', 35, '"'),
          ('2026-10-07', 89, null),
          (null, 89, 'cm'),
          ('2026-10-08', 5000, 'cm'),
          ('2026-10-09', 89, 'kg'),
        ], kind: 'waist'),
        _facts(),
      );
      final r = rows(p);
      expect(r[0].included, isTrue);
      expect(r[1].flags, contains(ImportFlag.duplicate));
      expect(r[2].flags, contains(ImportFlag.implausible));
      expect((r[3].unit, r[3].included), ('in', true));
      expect(r[4].flags, {ImportFlag.unitMissing});
      expect(r[5].flags, contains(ImportFlag.unclearDate));
      expect(r[6].flags, contains(ImportFlag.outOfRange));
      expect(r[7].flags, contains(ImportFlag.unknownUnit));
      expect(p.ops.whereType<CreateMeasurement>(), hasLength(2));
      expect(p.view!.imports!.measurementKind, MeasurementKind.waist);
    });

    test('body fat rows read percent; a big jump is flagged; same day '
        'informs', () {
      final p = _plan(
        _import([
          ('2026-10-01', 20, '%'),
          ('2026-10-01', 21, null),
          ('2026-10-03', 30, 'percent'),
          ('2026-10-04', 20, 'cm'),
        ], kind: 'bodyFat'),
        _facts(),
      );
      final r = rows(p);
      expect(r[0].included, isTrue);
      expect(r[1].flags, {ImportFlag.sameDay});
      expect(r[2].flags, contains(ImportFlag.implausible));
      expect(r[3].flags, contains(ImportFlag.unknownUnit));
    });

    test('an unknown measurement kind or no rows: no card', () {
      expect(
        _plan(
          _import([('2026-10-01', 1, 'cm')], kind: 'custom'),
          _facts(),
        ).issue,
        RecordIssue.invalid,
      );
      expect(_plan(_import(const []), _facts()).issue, RecordIssue.invalid);
    });
  });
}
