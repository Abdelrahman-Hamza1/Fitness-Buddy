import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/application/food_choice.dart';
import 'package:fb_mobile/features/foods/application/log_food.dart';
import 'package:fb_mobile/features/foods/application/replace_entry_food.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/changes/support/test_db.dart' show ScriptOp;
import '../../foods/presentation/support/sheet_support.dart' as catalog;
import '../support/diary_fixtures.dart';
import '../support/diary_harness.dart';

ProviderContainer setup(
  DiaryHarness h, {
  Future<ApplyResult> Function(ChangeSet)? apply,
  UndoStack? undoStack,
}) {
  final c = ProviderContainer(
    overrides: [
      diaryRepositoryProvider.overrideWithValue(DiaryRepository(h.db)),
      changeSetApplierProvider.overrideWithValue(h.applier),
      clockProvider.overrideWithValue(h.clock),
      idGeneratorProvider.overrideWithValue(h.ids),
      diaryApplyProvider.overrideWithValue(apply ?? h.applier.apply),
      if (undoStack != null) undoStackProvider.overrideWithValue(undoStack),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

Future<DiaryEntry> entry(DiaryHarness h) async =>
    (await h.reads.entriesOn(today)).first;
FoodChoice choice({String unit = 'g'}) => FoodChoice(
  food: foodOf(99),
  measures: FoodMeasures(
    basis: NutrientBasis.per100g,
    servingUnits: [if (unit == 'loaf') ServingUnit.grams('loaf', 60)],
  ),
);

final class BrokenUndoClock implements Clock {
  @override
  DateTime nowUtc() => throw StateError('undo clock');
  @override
  int offsetMinutesAt(DateTime utc) => 0;
}

void main() {
  for (final delete in [false, true]) {
    test('DY-021 unexpected Undo error rethrows and clears pending '
        '(delete=$delete)', () async {
      final h = DiaryHarness();
      await h.apply([
        LogEntries([newEntry(1)]),
      ]);
      final undo = UndoStack(
        revert: h.applier.revert,
        clock: BrokenUndoClock(),
      );
      addTearDown(undo.dispose);
      final c = setup(h, undoStack: undo);
      final e = await entry(h);
      final actions = c.read(diaryActionsControllerProvider.notifier);
      await expectLater(
        delete ? actions.deleteEntry(e) : actions.changeTime(e, LocalTime(9)),
        throwsStateError,
      );
      expect(c.read(diaryActionsControllerProvider).pending, isEmpty);
      expect(c.read(diaryActionsControllerProvider).hidden, isEmpty);
      final rows = await h.reads.entriesOn(today);
      if (delete) {
        expect(rows, isEmpty);
      } else {
        expect(rows.single.time.localDateTime.time, LocalTime(9));
      }
    });
  }

  for (final replace in [false, true]) {
    for (final amount in [100.0, 200.0]) {
      test('FD-010 history estimate range follows original amount '
          '(replace=$replace, amount=$amount)', () async {
        final h = DiaryHarness();
        await h.apply([
          LogEntries([
            newEntry(
              1,
              grams: 100,
              provenance: Provenance(
                source: FoodSource.database,
                isEstimate: true,
                range: EstimateRange(80, 120),
                assumptions: ['historic'],
              ),
            ),
            newEntry(2),
          ]),
        ]);
        final history = await DiaryRepository(h.db).watchFoodHistory().first;
        final picked = historyChoice(
          history.singleWhere((item) => item.food.provenance.range != null),
        );
        final c = setup(h);
        final undo = c.read(undoStackProvider);
        final LogFoodOutcome result;
        if (replace) {
          result = await ReplaceEntryFood(
            apply: h.applier.apply,
            undoStack: undo,
          )(VersionedId(fixtureId(2), 1), picked, Quantity(amount, 'g'));
        } else {
          result =
              await LogFood(
                apply: h.applier.apply,
                undoStack: undo,
                clock: h.clock,
                ids: h.ids,
              )(
                choice: picked,
                input: Quantity(amount, 'g'),
                date: today,
                slotId: DefaultSlots.lunchId,
              );
        }
        expect(result, isA<FoodLogged>());
        final rows = await h.reads.entriesOn(today);
        final written = replace
            ? rows.singleWhere((e) => e.id == fixtureId(2))
            : rows.singleWhere(
                (e) => e.id != fixtureId(1) && e.id != fixtureId(2),
              );
        expect(
          written.food.provenance.range,
          amount == 100 ? EstimateRange(80, 120) : isNull,
        );
        expect(written.food.provenance.assumptions, ['historic']);
        expect(written.food.provenance.source, FoodSource.database);
        expect(written.food.provenance.isEstimate, isTrue);
      });
    }
  }

  test(
    'AI-072 huge override input returns typed invalid without writing',
    () async {
      final h = DiaryHarness();
      await h.apply([
        LogEntries([newEntry(1)]),
      ]);
      var writes = 0;
      final c = setup(
        h,
        apply: (change) {
          writes++;
          return h.applier.apply(change);
        },
      );
      final before = await h.state();
      final e = await entry(h);
      final result = await c
          .read(diaryActionsControllerProvider.notifier)
          .overrideNutrients(e, {NutrientField.kcal: 1e308});
      expect((result as DiaryActionFailed).reason, DiaryActionFailure.invalid);
      expect(writes, 0);
      expect(await h.state(), before);
    },
  );

  test('AI-072 a live catalog choice clears edited history flag '
      'on log and replace', () async {
    final h = DiaryHarness();
    await h.apply([
      LogEntries([newEntry(1)]),
      OverrideNutrients(fixtureId(1), 1, {NutrientField.protein: 30}),
    ]);
    final history = (await DiaryRepository(
      h.db,
    ).watchFoodHistory().first).single;
    final picked = catalogChoice(catalog.pita, history: history);
    expect(picked.food.editedByUser, isFalse);
    final c = setup(h);
    final undo = c.read(undoStackProvider);
    expect(
      await LogFood(
        apply: h.applier.apply,
        undoStack: undo,
        clock: h.clock,
        ids: h.ids,
      )(
        choice: picked,
        input: Quantity(100, 'g'),
        date: today,
        slotId: DefaultSlots.lunchId,
      ),
      isA<FoodLogged>(),
    );
    expect(
      await ReplaceEntryFood(apply: h.applier.apply, undoStack: undo)(
        VersionedId(fixtureId(1), 2),
        picked,
        Quantity(100, 'g'),
      ),
      isA<FoodLogged>(),
    );
    expect(
      (await h.reads.entriesOn(today)).every((e) => !e.editedByUser),
      isTrue,
    );
  });

  for (final replace in [false, true]) {
    test(
      replace
          ? 'AI-072 replacing with an edited history snapshot '
                'keeps edited_by_user'
          : 'AI-072 FD-010 re-logging an edited history snapshot '
                'keeps edited_by_user',
      () async {
        final h = DiaryHarness();
        await h.apply([
          LogEntries([newEntry(1), newEntry(2)]),
          OverrideNutrients(fixtureId(1), 1, {NutrientField.protein: 30}),
        ]);
        final history = await DiaryRepository(h.db).watchFoodHistory().first;
        final picked = historyChoice(history.firstWhere((e) => e.editedByUser));
        final c = setup(h);
        final undo = c.read(undoStackProvider);
        final LogFoodOutcome result;
        if (replace) {
          result = await ReplaceEntryFood(
            apply: h.applier.apply,
            undoStack: undo,
          )(VersionedId(fixtureId(2), 1), picked, Quantity(100, 'g'));
        } else {
          result =
              await LogFood(
                apply: h.applier.apply,
                undoStack: undo,
                clock: h.clock,
                ids: h.ids,
              )(
                choice: picked,
                input: Quantity(100, 'g'),
                date: today,
                slotId: DefaultSlots.lunchId,
              );
        }
        expect(result, isA<FoodLogged>());
        final rows = await h.reads.entriesOn(today);
        final written = replace
            ? rows.singleWhere((e) => e.id == fixtureId(2))
            : rows.singleWhere(
                (e) => e.id != fixtureId(1) && e.id != fixtureId(2),
              );
        expect(written.editedByUser, isTrue);
        expect(written.snapshot.protein, picked.per100.protein);
        expect(written.food.provenance, picked.food.provenance);
      },
    );
  }

  test("DY-021 changeAmount uses the entry's per-100 (an "
      'override survives); same value → Unchanged', () async {
    final h = DiaryHarness();
    await h.apply([
      LogEntries([newEntry(1, grams: 200)]),
    ]);
    await h.apply([
      OverrideNutrients(fixtureId(1), 1, {NutrientField.protein: 30}),
    ]);
    final c = setup(h);
    final actions = c.read(diaryActionsControllerProvider.notifier);
    final e = await entry(h);
    final before = await h.state();
    expect(
      await actions.changeAmount(e, e.amount.input),
      isA<DiaryActionUnchanged>(),
    );
    expect(await h.state(), before);
    final outcome =
        await actions.changeAmount(e, Quantity(400, 'g')) as DiaryActionDone;
    expect((await entry(h)).snapshot.protein, 60);
    expect((await entry(h)).editedByUser, isTrue);
    await c.read(undoStackProvider).undo(outcome.undoEntryId);
    expect(await h.state(), before);
    final current = await entry(h);
    final overridden = await actions.overrideNutrients(current, {
      NutrientField.carbs: 42,
    }) as DiaryActionDone;
    expect((await entry(h)).snapshot.carbs, 42);
    await c.read(undoStackProvider).undo(overridden.undoEntryId);
    expect(await h.state(), before);
  });
  test(
    'DY-021 changeTime keeps the date, the slot and the stored offset',
    () async {
      final h = DiaryHarness(offsetMinutes: 180);
      await h.apply([
        LogEntries([newEntry(1)]),
      ]);
      final c = setup(h);
      final actions = c.read(diaryActionsControllerProvider.notifier);
      final e = await entry(h);
      final before = await h.state();
      expect(
        await actions.changeTime(e, e.time.localDateTime.time),
        isA<DiaryActionUnchanged>(),
      );
      final outcome =
          await actions.changeTime(e, LocalTime(22, 30)) as DiaryActionDone;
      final changed = await entry(h);
      expect(changed.localDate, e.localDate);
      expect(changed.slotId, e.slotId);
      expect(changed.time.tzOffsetMin, e.time.tzOffsetMin);
      expect(changed.time.localDateTime.time, LocalTime(22, 30));
      await c.read(undoStackProvider).undo(outcome.undoEntryId);
      expect(await h.state(), before);
    },
  );
  test('DY-021 ReplaceEntryFood: food + amount replaced, '
      'date/slot/group kept, flag cleared; a stale version → '
      'changed', () async {
    final h = DiaryHarness();
    await h.apply([
      CreateDishGroup(
        id: fixtureId(50),
        name: 'Dish',
        date: today,
        slotId: DefaultSlots.lunchId,
      ),
      LogEntries([newEntry(1, group: 50, slotId: DefaultSlots.lunchId)]),
      OverrideNutrients(fixtureId(1), 1, {NutrientField.protein: 30}),
    ]);
    final c = setup(h);
    final e = await entry(h);
    final before = await h.state();
    final command = ReplaceEntryFood(
      apply: h.applier.apply,
      undoStack: c.read(undoStackProvider),
    );
    final outcome = await command(
      VersionedId(e.id, e.version),
      choice(),
      Quantity(50, 'g'),
    ) as FoodLogged;
    final changed = await entry(h);
    expect(changed.food, choice().food);
    expect(changed.amount.amount, 50);
    expect(changed.editedByUser, isFalse);
    expect(
      (changed.localDate, changed.slotId, changed.dishGroupId),
      (e.localDate, e.slotId, e.dishGroupId),
    );
    final after = await h.state();
    expect(
      (await command(
        VersionedId(e.id, e.version),
        choice(),
        Quantity(50, 'g'),
      ) as FoodLogFailed).code,
      'changed',
    );
    expect(await h.state(), after);
    await c.read(undoStackProvider).undo(outcome.undoEntryId);
    expect(await h.state(), before);
  });
  test('DY-023 copyMeal observes a split group but copies an Other '
      'selection ungrouped', () async {
    final h = DiaryHarness();
    await h.apply([
      CreateDishGroup(
        id: fixtureId(50),
        name: 'Dish',
        date: today,
        slotId: DefaultSlots.lunchId,
      ),
      LogEntries([
        newEntry(1, group: 50, slotId: DefaultSlots.lunchId),
        newEntry(2, group: 50, slotId: DefaultSlots.lunchId),
      ]),
    ]);
    // Imported split groups remain visible; their source subset is explicit.
    await h.applier.apply(
      ChangeSet([
        ScriptOp.rows([
          UpdateRow(
            h.db.diaryEntries,
            fixtureId(2),
            DiaryEntriesCompanion(slotId: Value(fixtureId(55))),
          ),
        ]),
      ], origin: Origin.direct),
    );
    final sent = <ChangeSet>[];
    final c = setup(
      h,
      apply: (change) {
        sent.add(change);
        return h.applier.apply(change);
      },
    );
    final day = await h.reads.day(today);
    final section = DayLayout.build(
      day.slots,
      day.groups,
      day.entries,
    ).sections.singleWhere((s) => s.slot == null);
    expect(section.entryCopyGroupIds, isEmpty);
    final before = await h.state();
    final done =
        await c
                .read(diaryActionsControllerProvider.notifier)
                .copyMeal(section, today.plusDays(-1))
            as DiaryActionDone;
    final op = sent.single.ops.single as CopyMeal;
    expect(op.expected.groups, [VersionedId(fixtureId(50), 1)]);
    expect(op.copyIds.keys, [fixtureId(2)]);
    expect(
      (await h.reads.entriesOn(today.plusDays(-1))).single.dishGroupId,
      isNull,
    );
    await c.read(undoStackProvider).undo(done.undoEntryId);
    expect(await h.state(), before);
  });
  test('D12 edit commands drop duplicate pending work and clear '
      'pending after rejection or exception', () async {
    final h = DiaryHarness();
    await h.apply([
      LogEntries([newEntry(1)]),
    ]);
    final release = Completer<ApplyResult>();
    var calls = 0;
    final c = setup(
      h,
      apply: (_) {
        calls++;
        return release.future;
      },
    );
    final actions = c.read(diaryActionsControllerProvider.notifier);
    final e = await entry(h);
    final first = actions.changeAmount(e, Quantity(2, 'g'));
    expect(
      await actions.changeTime(e, LocalTime(9)),
      isA<DiaryActionUnchanged>(),
    );
    expect(calls, 1);
    release.complete(const Rejected(InvalidOp('sourceChanged')));
    expect(
      (await first as DiaryActionFailed).reason,
      DiaryActionFailure.changed,
    );
    expect(c.read(diaryActionsControllerProvider).pending, isEmpty);
    final errorContainer = setup(
      h,
      apply: (_) async => throw StateError('test'),
    );
    final failing = errorContainer.read(
      diaryActionsControllerProvider.notifier,
    );
    for (final command in [
      () => failing.changeTime(e, LocalTime(9)),
      () => failing.deleteEntry(e),
      () => failing.moveEntry(e, DefaultSlots.dinnerId),
      () => failing.overrideNutrients(e, {NutrientField.kcal: 200}),
    ]) {
      await expectLater(command(), throwsStateError);
      expect(
        errorContainer.read(diaryActionsControllerProvider).pending,
        isEmpty,
      );
      expect(
        errorContainer.read(diaryActionsControllerProvider).hidden,
        isEmpty,
      );
    }
    expect(
      errorContainer.read(diaryActionsControllerProvider).pending,
      isEmpty,
    );
  });
  test('FD-010 a history re-log of an edited retired snapshot '
      'shows the yours badge', () async {
    final h = DiaryHarness();
    await h.apply([
      LogEntries([newEntry(1)]),
    ]);
    await h.apply([
      OverrideNutrients(fixtureId(1), 1, {NutrientField.protein: 30}),
    ]);
    final history = await DiaryRepository(h.db).watchFoodHistory().first;
    expect(historyChoice(history.single).badge, FoodSource.yours);
    expect(history.single.food.provenance.source, FoodSource.database);
  });
}
