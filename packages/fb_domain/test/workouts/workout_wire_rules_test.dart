import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

/// A set written as the app's `setColumns` does (TD-017): a weight typed in
/// kg stores its kg as the typed value; no weight, no typed value.
bool _columnsHold(LoggedSet set) {
  final kg = set.values.kg;
  return WorkoutWireRules.setShapeHolds(
    reps: set.values.reps,
    kg: kg,
    inputValue: kg == null ? null : set.inputValue ?? kg,
    inputUnit: kg == null ? null : set.inputUnit.code,
    durationSeconds: set.values.durationSeconds,
    distanceMeters: set.values.distanceMeters,
  );
}

extension on Any {
  /// Values around and inside every type's bounds, often null.
  Generator<SetValues> get setValues => combine4(
    either(intInRange(-1, 1002), intInRange(1, 13)).nullable,
    either(doubleInRange(-1, 1001), doubleInRange(0, 200)).nullable,
    intInRange(-1, 86402).nullable,
    doubleInRange(-1, 1000001).nullable,
    (reps, kg, duration, distance) => SetValues(
      reps: reps,
      kg: kg,
      durationSeconds: duration,
      distanceMeters: distance,
    ),
  );

  Generator<Muscle?> get muscle => choose(Muscle.values).nullable;
}

void main() {
  group('WO-004 property: W3 is sound', () {
    Glados3(
      any.setValues,
      any.doubleInRange(0, 2205).nullable,
      any.choose([MassUnit.kilogram, MassUnit.pound]),
      propertyRuns,
    ).test('any SetValues that issueFor accepts for some type, written as '
        'columns, satisfies the set shape', (values, typed, unit) {
      final fits = ExerciseType.values.any((t) => values.issueFor(t) == null);
      if (!fits) return;
      final set = LoggedSet(
        '0199e3c2-5b1a-7c3d-8e4f-0123456789d4',
        values,
        inputValue: values.kg == null ? null : typed,
        inputUnit: unit,
      );
      expect(_columnsHold(set), isTrue, reason: '$values $typed $unit');
    });
  });

  group('WO-003 WO-020 property: valid drafts satisfy W1, W2, W4', () {
    Glados3(
      any.muscle,
      any.listWithLengthInRange(0, 6, any.choose(Muscle.values)),
      any.intInRange(0, 12),
      propertyRuns,
    ).test('a custom exercise draft writes wire-valid muscles and aliases', (
      primary,
      secondaries,
      aliasCount,
    ) {
      final CustomExerciseDraft draft;
      try {
        draft = CustomExerciseDraft(
          name: 'Press',
          type: ExerciseType.weightReps,
          equipment: Equipment.barbell,
          aliases: [for (var i = 0; i < aliasCount; i++) 'alias $i'],
          primaryMuscle: primary,
          secondaryMuscles: secondaries,
        );
        // The draft's constructor reports an invalid draft as an
        // ArgumentError; such drafts are skipped.
        // ignore: avoid_catching_errors
      } on ArgumentError {
        return; // Not a draft the app can write.
      }
      final muscles = jsonEncode([
        for (final m in draft.secondaryMuscles) m.code,
      ]);
      expect(
        WorkoutWireRules.musclesHold(
          draft.primaryMuscle?.code,
          jsonDecode(muscles),
        ),
        isTrue,
      );
      expect(
        WorkoutWireRules.aliasesHold(jsonDecode(jsonEncode(draft.aliases))),
        isTrue,
      );
    });

    Glados(
      any.choose([
        'ex:bench_press',
        'ex:${'a' * 60}',
        'ex:${'a' * 61}',
        'ex:',
        'ex:Bench',
        'EX:bench',
        'ex:bench\n',
        '0199e3c2-5b1a-7c3d-8e4f-0123456789c4',
        '0199E3C2-5B1A-7C3D-8E4F-0123456789C4',
        '',
      ]),
      propertyRuns,
    ).test('checkExerciseId agrees with isExerciseRef', (id) {
      final valid = WorkoutWireRules.isExerciseRef(id);
      if (valid) {
        expect(checkExerciseId(id, 'exerciseId'), id);
        final item = TemplateItemDraft(
          id: '0199e3c2-5b1a-7c3d-8e4f-0123456789d6',
          exerciseId: id,
          sets: 3,
          reps: 8,
        );
        expect(item.exerciseId, id);
      } else {
        expect(() => checkExerciseId(id, 'exerciseId'), throwsArgumentError);
      }
    });
  });

  test('B21 W1 muscles: codes, at most 4, distinct, never the primary', () {
    expect(WorkoutWireRules.musclesHold(null, <Object?>[]), isTrue);
    expect(
      WorkoutWireRules.musclesHold('chest', ['shoulders', 'triceps']),
      isTrue,
    );
    expect(
      WorkoutWireRules.musclesHold(null, ['chest', 'abs', 'calves', 'traps']),
      isTrue,
    );
    for (final (primary, value) in <(String?, Object?)>[
      (null, ['chest', 'abs', 'calves', 'traps', 'glutes']),
      (null, ['abs', 'abs']),
      ('chest', ['chest']),
      (null, ['back']),
      (null, ['Chest']),
      (null, [1]),
      (null, [null]),
      (null, {'chest': 1}),
      (null, 'chest'),
      (null, null),
    ]) {
      expect(
        WorkoutWireRules.musclesHold(primary, value),
        isFalse,
        reason: '$primary $value',
      );
    }
    expect(Muscle.secondariesMax, 4);
  });

  test('B21 W2 aliases: a list of at most 10 strings', () {
    expect(WorkoutWireRules.aliasesHold(<Object?>[]), isTrue);
    expect(WorkoutWireRules.aliasesHold(List.filled(10, 'a')), isTrue);
    expect(WorkoutWireRules.aliasesHold(List.filled(11, 'a')), isFalse);
    expect(WorkoutWireRules.aliasesHold(['a', 1]), isFalse);
    expect(WorkoutWireRules.aliasesHold({'a': 'b'}), isFalse);
    expect(WorkoutWireRules.aliasesHold('a'), isFalse);
  });

  test('B21 W3 set shape: reps or duration; kg with reps, typed together; '
      'distance with duration', () {
    bool hold({
      int? reps,
      double? kg,
      double? inputValue,
      String? inputUnit,
      int? durationSeconds,
      double? distanceMeters,
    }) => WorkoutWireRules.setShapeHolds(
      reps: reps,
      kg: kg,
      inputValue: inputValue,
      inputUnit: inputUnit,
      durationSeconds: durationSeconds,
      distanceMeters: distanceMeters,
    );
    expect(hold(reps: 8, kg: 80, inputValue: 80, inputUnit: 'kg'), isTrue);
    expect(hold(reps: 8), isTrue);
    expect(hold(durationSeconds: 60, distanceMeters: 100), isTrue);
    expect(hold(reps: 0, kg: 0, inputValue: 0, inputUnit: 'lb'), isTrue);
    expect(hold(), isFalse);
    expect(hold(reps: 8, durationSeconds: 60), isFalse);
    expect(
      hold(durationSeconds: 60, kg: 1, inputValue: 1, inputUnit: 'kg'),
      isFalse,
    );
    expect(hold(reps: 8, distanceMeters: 100), isFalse);
    expect(hold(reps: 8, kg: 80), isFalse);
    expect(hold(reps: 8, kg: 80, inputValue: 80), isFalse);
    expect(hold(reps: 8, inputUnit: 'kg'), isFalse);
    expect(hold(reps: 8, inputValue: 10), isFalse);
  });

  test('B21 W4 exercise reference and W5 plan-day IDs', () {
    expect(WorkoutWireRules.isExerciseRef('ex:3_4_sit_up'), isTrue);
    expect(WorkoutWireRules.isExerciseRef('ex:bench-press'), isFalse);
    expect(WorkoutWireRules.maxCatalogIdLength, 60);
    expect(WorkoutWireRules.planDayIds, hasLength(7));
    expect(WorkoutWireRules.planDayIds.toSet(), hasLength(7));
    for (final (i, id) in WorkoutWireRules.planDayIds.indexed) {
      expect(isUuid(id), isTrue);
      expect(id[14], '5', reason: 'UUIDv5');
      expect(WorkoutWireRules.planDayIdHolds(id, i + 1), isTrue);
      expect(WorkoutWireRules.planDayIdHolds(id, (i + 1) % 7 + 1), isFalse);
    }
    final monday = WorkoutWireRules.planDayIds.first;
    expect(WorkoutWireRules.planDayIdHolds(monday, 0), isFalse);
    expect(WorkoutWireRules.planDayIdHolds(monday, 8), isFalse);
    expect(WorkoutWireRules.planDayIdHolds(monday.toUpperCase(), 1), isFalse);
  });
}
