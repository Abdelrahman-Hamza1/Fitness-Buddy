import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/workouts/application/workout_actions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/catalog/support/catalog_support.dart';
import '../support/workout_harness.dart';

/// A pack with every exercise the starter plans use.
String _packSql() {
  final ids = {
    for (final t in StarterTemplate.values)
      for (final i in t.items) i.exerciseId,
  };
  final rows = [
    for (final id in ids)
      "  ('$id', '$id', 'weight_reps', 'barbell', 'chest', '', 1)",
  ];
  return 'INSERT INTO exercises VALUES\n${rows.join(',\n')};';
}

/// A harness over a database with the starter exercises' pack attached.
WorkoutHarness _harness() {
  final (db, catalog) = fixtureCatalog(extraSql: _packSql());
  addTearDown(catalog.dispose);
  return WorkoutHarness(database: db);
}

/// Every plan-day row, live or not: weekday ISO number → template ID.
Future<Map<int, String?>> _planRows(WorkoutHarness h) async => {
  for (final r
      in await h.db
          .customSelect(
            'SELECT weekday, template_id FROM weekly_plan_days '
            'WHERE deleted_at IS NULL',
          )
          .get())
    r.read<int>('weekday'): r.read<String?>('template_id'),
};

List<WorkoutOp> _ppl() => StarterPlan.pushPullLegs.ops(
  days: StarterPlan.pushPullLegs.defaultDays(DayOfWeek.saturday),
  weekStart: DayOfWeek.saturday,
  ids: SequenceIdGenerator(startMs: 0x0199e3c40000),
  nameOf: (t) => t.name,
);

void main() {
  test('WO-023 applying a starter plan creates templates and assigns them in '
      'one change set', () async {
    final h = _harness();
    final undo = UndoStack(
      revert: h.applier.revert,
      apply: h.applier.apply,
      clock: h.clock,
    );
    addTearDown(undo.dispose);
    final actions = WorkoutActions(
      apply: h.applier.apply,
      undoStack: undo,
      ids: SequenceIdGenerator(startMs: 0x0199e3c40000),
      repository: h.repository,
    );
    final outcome = await actions.applyStarterPlan(
      StarterPlan.pushPullLegs,
      days: [DayOfWeek.saturday, DayOfWeek.monday, DayOfWeek.wednesday],
      weekStart: DayOfWeek.saturday,
      nameOf: (t) => t.name,
    );
    expect(outcome, isA<WorkoutActionDone>());
    final templates = await h.repository.watchTemplates().first;
    expect(templates.map((t) => t.draft.name).toSet(), {
      'push',
      'pull',
      'legs',
    });
    final byName = {for (final t in templates) t.draft.name: t.ref.id};
    // The plan days see the templates created earlier in the same set.
    expect(await h.repository.plan(), {
      DayOfWeek.saturday: byName['push'],
      DayOfWeek.monday: byName['pull'],
      DayOfWeek.wednesday: byName['legs'],
    });
    // All seven weekdays written; the other four rest.
    final rows = await _planRows(h);
    expect(rows, hasLength(7));
    expect(rows.values.where((t) => t == null), hasLength(4));
    // One change set: one undo removes all of it.
    expect(
      await undo.undo((outcome as WorkoutActionDone).undoId),
      UndoOutcome.undone,
    );
    expect(await h.repository.watchTemplates().first, isEmpty);
    expect(await h.repository.plan(), isEmpty);
  });

  test('WO-023 a rejected op in the starter-plan set leaves no templates and '
      'no plan days', () async {
    final h = _harness();
    // The last op points at a template that doesn't exist: the whole set
    // is refused and nothing is persisted (reject checks the raw rows).
    await h.reject([..._ppl(), SetPlanDay(DayOfWeek.friday, wid(999))]);
    expect(await h.repository.watchTemplates().first, isEmpty);
    expect(await _planRows(h), isEmpty);
  });

  test('WO-023 replacing an existing plan, then Undo, restores the previous '
      'plan days and removes the new templates', () async {
    final h = _harness();
    await h.apply([
      CreateWorkoutTemplate(
        wid(5),
        WorkoutTemplateDraft(
          name: 'Mine',
          items: [
            TemplateItemDraft(
              id: wid(6),
              exerciseId: 'ex:barbell_bench_press',
              sets: 3,
              reps: 8,
            ),
          ],
        ),
      ),
      SetPlanDay(DayOfWeek.monday, wid(5)),
      SetPlanDay(DayOfWeek.thursday, wid(5)),
    ]);
    final before = await h.state();
    final applied = await h.apply(_ppl());
    final plan = await h.repository.plan();
    expect(plan.values.toSet(), isNot(contains(wid(5))));
    // Monday now trains a starter template; Thursday rests.
    expect(plan[DayOfWeek.monday], isNotNull);
    expect(plan.containsKey(DayOfWeek.thursday), isFalse);
    // The user's own template stays.
    expect(
      (await h.repository.watchTemplates().first).map((t) => t.ref.id),
      contains(wid(5)),
    );

    expect(await h.undo(applied), isA<Object>());
    expect(await h.state(), before);
    expect(await h.repository.plan(), {
      DayOfWeek.monday: wid(5),
      DayOfWeek.thursday: wid(5),
    });
    expect((await h.repository.watchTemplates().first).map((t) => t.ref.id), [
      wid(5),
    ]);
  });
}
