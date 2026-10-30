import 'dart:io';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('WO-023 starter plan exercises all exist in data/exercises.yaml', () {
    final yaml = loadYaml(File('../../data/exercises.yaml').readAsStringSync());
    final rows = (yaml is YamlMap ? yaml['exercises'] : yaml) as YamlList;
    final types = {
      for (final row in rows.cast<YamlMap>())
        row['id'] as String: row['type'] as String,
    };
    for (final template in StarterTemplate.values) {
      expect(template.items, isNotEmpty, reason: template.name);
      for (final item in template.items) {
        expect(types, contains(item.exerciseId), reason: template.name);
        // Template lines are sets × reps: never time or cardio (A37 D17).
        expect(
          types[item.exerciseId],
          isNot(anyOf('duration', 'distance_duration')),
          reason: item.exerciseId,
        );
      }
    }
  });

  test('WO-023 PPL cycles over 3–6 picked days', () {
    const plan = StarterPlan.pushPullLegs;
    const start = DayOfWeek.saturday;
    expect(plan.defaultDays(start), [
      DayOfWeek.saturday,
      DayOfWeek.monday,
      DayOfWeek.wednesday,
    ]);
    // Four days, given out of order: rotation follows the week from Saturday.
    expect(
      plan.assign([
        DayOfWeek.tuesday,
        DayOfWeek.saturday,
        DayOfWeek.wednesday,
        DayOfWeek.sunday,
      ], weekStart: start),
      {
        DayOfWeek.saturday: StarterTemplate.push,
        DayOfWeek.sunday: StarterTemplate.pull,
        DayOfWeek.tuesday: StarterTemplate.legs,
        DayOfWeek.wednesday: StarterTemplate.push,
      },
    );
    final six = DayOfWeek.values.where((d) => d != DayOfWeek.friday);
    expect(plan.assign(six, weekStart: start), hasLength(6));
    expect(plan.fits(2), isFalse);
    expect(plan.fits(7), isFalse);
    expect(
      () =>
          plan.assign([DayOfWeek.monday, DayOfWeek.tuesday], weekStart: start),
      throwsArgumentError,
    );
    // Full body is A, B, A on its three days.
    expect(
      StarterPlan.fullBody
          .assign(StarterPlan.fullBody.defaultDays(start), weekStart: start)
          .values,
      [
        StarterTemplate.fullBodyA,
        StarterTemplate.fullBodyB,
        StarterTemplate.fullBodyA,
      ],
    );
  });

  test('WO-023 a starter plan is templates then all seven plan days', () {
    final ops = StarterPlan.upperLower.ops(
      days: StarterPlan.upperLower.defaultDays(DayOfWeek.saturday),
      weekStart: DayOfWeek.saturday,
      ids: SequenceIdGenerator(),
      nameOf: (t) => t.name,
    );
    final creates = ops.whereType<CreateWorkoutTemplate>().toList();
    final days = ops.whereType<SetPlanDay>().toList();
    expect(creates, hasLength(4));
    // Creates come first, so the plan days can point at them.
    expect(ops.take(4), everyElement(isA<CreateWorkoutTemplate>()));
    expect(days.map((d) => d.weekday).toSet(), DayOfWeek.values.toSet());
    final ids = {for (final c in creates) c.id};
    expect(
      days.where((d) => d.templateId != null).map((d) => d.templateId),
      everyElement(isIn(ids)),
    );
    expect(days.where((d) => d.templateId == null), hasLength(3));
  });

  test('WO-020 save as template uses targets from the session', () {
    String id(int n) =>
        '0199e3c2-5b1a-7c3d-8e4f-${n.toRadixString(16).padLeft(12, '0')}';
    LoggedSet set(int n, int reps) =>
        LoggedSet(id(n), SetValues(reps: reps, kg: 80));
    final session = WorkoutSessionDraft(
      date: LocalDate(2026, 10, 1),
      exercises: [
        SessionExerciseDraft(
          id: id(1),
          exerciseId: 'ex:barbell_bench_press',
          sets: [set(2, 8), set(3, 8), set(4, 7)],
        ),
        SessionExerciseDraft(
          id: id(5),
          exerciseId: 'ex:pull_up',
          sets: [set(6, 10), set(7, 12)],
        ),
      ],
    );
    expect(TemplateMatch.targetsFrom(sessionDoneOf(session)), [
      (exerciseId: 'ex:barbell_bench_press', sets: 3, reps: 8),
      // A tie takes the higher reps.
      (exerciseId: 'ex:pull_up', sets: 2, reps: 12),
    ]);
  });
}
