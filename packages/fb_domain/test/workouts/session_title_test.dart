import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

NamingExercise _ex(Muscle? primary, int sets, {bool cardio = false}) =>
    (primary: primary, isCardio: cardio, sets: sets);

void main() {
  test('WO-010 single dominant group names the session by it', () {
    // Chest 7 of 10 sets (70 %): the chest alone.
    expect(
      SessionNaming.titleOf(null, [
        _ex(Muscle.chest, 4),
        _ex(Muscle.triceps, 3),
        _ex(Muscle.chest, 3),
      ]),
      MuscleGroupsTitle([MuscleGroup.chest]),
    );
    // Muscles of one group add up: traps + upper back are "Back".
    expect(
      SessionNaming.titleOf(null, [
        _ex(Muscle.upperBack, 3),
        _ex(Muscle.traps, 3),
        _ex(Muscle.lowerBack, 3),
        _ex(Muscle.biceps, 2),
      ]),
      MuscleGroupsTitle([MuscleGroup.back]),
    );
  });

  test('WO-010 two groups give "A & B" in set-weighted order', () {
    expect(
      SessionNaming.titleOf(null, [
        _ex(Muscle.triceps, 3),
        _ex(Muscle.chest, 4),
        _ex(Muscle.chest, 2),
        _ex(Muscle.shoulders, 1),
      ]),
      MuscleGroupsTitle([MuscleGroup.chest, MuscleGroup.triceps]),
    );
    // Ties go to the group that appears first.
    expect(
      SessionNaming.titleOf(null, [
        _ex(Muscle.biceps, 3),
        _ex(Muscle.upperBack, 3),
      ]),
      MuscleGroupsTitle([MuscleGroup.biceps, MuscleGroup.back]),
    );
  });

  test('WO-010 four spread groups give Full body', () {
    expect(
      SessionNaming.titleOf(null, [
        _ex(Muscle.quadriceps, 3),
        _ex(Muscle.chest, 3),
        _ex(Muscle.upperBack, 3),
        _ex(Muscle.shoulders, 3),
        _ex(Muscle.abs, 3),
      ]),
      const FullBodyTitle(),
    );
    // Four groups, but the top two reach 60 %: still the top two.
    expect(
      SessionNaming.titleOf(null, [
        _ex(Muscle.chest, 4),
        _ex(Muscle.triceps, 2),
        _ex(Muscle.shoulders, 2),
        _ex(Muscle.abs, 2),
      ]),
      MuscleGroupsTitle([MuscleGroup.chest, MuscleGroup.triceps]),
    );
  });

  test('WO-010 cardio-only is Cardio; cardio ignored beside strength', () {
    expect(
      SessionNaming.titleOf(null, [
        _ex(Muscle.quadriceps, 1, cardio: true),
        _ex(null, 1, cardio: true),
      ]),
      const CardioTitle(),
    );
    expect(
      SessionNaming.titleOf(null, [
        _ex(Muscle.quadriceps, 5, cardio: true),
        _ex(Muscle.chest, 3),
      ]),
      MuscleGroupsTitle([MuscleGroup.chest]),
    );
  });

  test('WO-010 exercises without a primary are ignored; none named → '
      'Untitled', () {
    expect(
      SessionNaming.titleOf(null, [_ex(null, 10), _ex(Muscle.biceps, 1)]),
      MuscleGroupsTitle([MuscleGroup.biceps]),
    );
    expect(SessionNaming.titleOf(null, [_ex(null, 3)]), const UntitledTitle());
    expect(SessionNaming.titleOf(null, const []), const UntitledTitle());
    expect(
      SessionNaming.titleOf(null, [_ex(Muscle.chest, 0)]),
      const UntitledTitle(),
    );
  });

  test('WO-010 explicit name wins', () {
    expect(
      SessionNaming.titleOf(' Push ', [_ex(Muscle.upperBack, 9)]),
      const NamedTitle('Push'),
    );
    expect(
      SessionNaming.titleOf('  ', [_ex(Muscle.upperBack, 9)]),
      MuscleGroupsTitle([MuscleGroup.back]),
    );
    expect(const NamedTitle('Push').toString(), isNot(contains('Push')));
  });
}
