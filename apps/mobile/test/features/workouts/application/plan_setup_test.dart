import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/workouts/application/plan_setup.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WO-023 D-089 plan setup starts empty; suggestions keep their target, '
      'others get 3 × 10; no duplicates; complete needs every day', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    const key = PlanSetupKey(visitId: 'v', plan: StarterPlan.pushPullLegs);
    final setup = container.read(planSetupProvider(key).notifier);
    PlanSetupState state() => container.read(planSetupProvider(key));
    const push = StarterTemplate.push;

    expect(state().chosenOf(push), isEmpty);
    expect(state().suggestionsOf(push), push.items);
    expect(state().complete, isFalse);

    setup
      ..add(push, ['ex:barbell_bench_press', 'ex:dumbbell_curl'])
      ..add(push, ['ex:barbell_bench_press']);
    expect(state().chosenOf(push), [
      push.items.first,
      (exerciseId: 'ex:dumbbell_curl', sets: 3, reps: 10),
    ]);
    expect(state().suggestionsOf(push), push.items.skip(1));

    setup
      ..setTarget(push, 'ex:dumbbell_curl', sets: 99, reps: 0)
      ..remove(push, 'ex:barbell_bench_press');
    expect(state().chosenOf(push), [
      (
        exerciseId: 'ex:dumbbell_curl',
        sets: WorkoutSetBounds.maxSets,
        reps: WorkoutSetBounds.minReps,
      ),
    ]);

    setup
      ..addAll(StarterTemplate.pull)
      ..addAll(StarterTemplate.legs);
    expect(state().chosenOf(StarterTemplate.pull), StarterTemplate.pull.items);
    expect(state().suggestionsOf(StarterTemplate.pull), isEmpty);
    expect(state().complete, isTrue);
  });
}
