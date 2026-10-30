import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

CustomExerciseDraft _custom({
  Muscle? primary = Muscle.chest,
  List<Muscle> secondaries = const [],
}) => CustomExerciseDraft(
  name: 'Cable fly',
  type: ExerciseType.weightReps,
  equipment: Equipment.cable,
  primaryMuscle: primary,
  secondaryMuscles: secondaries,
);

void main() {
  test('WO-007 the vocabulary has the 15 D2 codes, each in one group', () {
    expect(Muscle.values.map((m) => m.code), [
      'chest',
      'shoulders',
      'biceps',
      'triceps',
      'forearms',
      'traps',
      'upper_back',
      'lower_back',
      'abs',
      'obliques',
      'quadriceps',
      'hamstrings',
      'glutes',
      'calves',
      'adductors',
    ]);
    expect(Muscle.upperBack.group, MuscleGroup.back);
    expect(Muscle.traps.group, MuscleGroup.back);
    expect(Muscle.obliques.group, MuscleGroup.core);
    expect(Muscle.adductors.group, MuscleGroup.legs);
    for (final muscle in Muscle.values) {
      expect(Muscle.fromCode(muscle.code), muscle);
    }
  });

  test('WO-007 legacy catalog codes map back→upper_back, core→abs, '
      'full_body→none; unknown dropped', () {
    expect(Muscle.fromCatalogCode('back'), Muscle.upperBack);
    expect(Muscle.fromCatalogCode('core'), Muscle.abs);
    expect(Muscle.fromCatalogCode('full_body'), isNull);
    expect(Muscle.fromCatalogCode('neck'), isNull);
    expect(Muscle.fromCatalogCode('chest'), Muscle.chest);
    // The strict reader knows only the vocabulary.
    expect(Muscle.fromCode('back'), isNull);
    expect(
      Muscle.secondariesFromCatalog([
        'triceps',
        'neck',
        'chest',
        'triceps',
        'core',
      ], primary: Muscle.chest),
      [Muscle.triceps, Muscle.abs],
    );
    expect(Muscle.secondariesFromCatalog(const []), isEmpty);
  });

  test('WO-003 custom exercise draft rejects >4, duplicate or primary-equal '
      'secondaries', () {
    final ok = _custom(
      secondaries: [
        Muscle.triceps,
        Muscle.shoulders,
        Muscle.abs,
        Muscle.forearms,
      ],
    );
    expect(ok.secondaryMuscles, hasLength(4));
    expect(
      () => _custom(
        secondaries: [
          Muscle.triceps,
          Muscle.shoulders,
          Muscle.abs,
          Muscle.forearms,
          Muscle.biceps,
        ],
      ),
      throwsArgumentError,
    );
    expect(
      () => _custom(secondaries: [Muscle.triceps, Muscle.triceps]),
      throwsArgumentError,
    );
    expect(() => _custom(secondaries: [Muscle.chest]), throwsArgumentError);
    // A legacy row has no primary muscle (A37 D2).
    expect(_custom(primary: null).primaryMuscle, isNull);
  });

  test('WO-003 muscles take part in custom exercise equality', () {
    expect(_custom(), _custom());
    expect(_custom(), isNot(_custom(primary: Muscle.triceps)));
    expect(
      _custom(secondaries: [Muscle.triceps]),
      isNot(_custom(secondaries: [Muscle.shoulders])),
    );
    expect(
      _custom(secondaries: [Muscle.triceps]).hashCode,
      _custom(secondaries: [Muscle.triceps]).hashCode,
    );
  });
}
