import 'package:drift/drift.dart' show Value;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/unit_feed.dart';
import '../../diary/application/diary_edit_commands_test.dart'
    show choice, setup;
import '../../diary/support/diary_fixtures.dart';
import '../../diary/support/diary_harness.dart';
import '../presentation/support/sheet_support.dart' as catalog;

const String lunch = DefaultSlots.lunchId;
Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 30));
Future<
  ({
    ProviderContainer c,
    FoodAmountController controller,
    FoodAmountControllerProvider provider,
  })
>
open(
  DiaryHarness h, {
  bool autoPick = false,
  VersionedId? replacing,
  Future<ApplyResult> Function(ChangeSet)? apply,
}) async {
  final unit = UnitFeed();
  final undo = UndoStack(revert: h.applier.revert, clock: h.clock);
  addTearDown(undo.dispose);
  final container = ProviderContainer(
    overrides: [
      diaryRepositoryProvider.overrideWithValue(DiaryRepository(h.db)),
      foodChoiceProvider.overrideWith(
        (ref, id) async => catalogChoice(
          catalog.riceCooked,
          siblings: [catalog.riceDry],
          yields: catalog.yields,
        ),
      ),
      foodSlotsProvider.overrideWith(
        (ref, _) => DiaryRepository(h.db).watchSlots(),
      ),
      unit.override,
      clockProvider.overrideWithValue(h.clock),
      logFoodProvider.overrideWithValue(
        LogFood(
          apply: apply ?? h.applier.apply,
          undoStack: undo,
          clock: h.clock,
          ids: h.ids,
        ),
      ),
      replaceEntryFoodProvider.overrideWithValue(
        ReplaceEntryFood(apply: h.applier.apply, undoStack: undo),
      ),
    ],
  );
  addTearDown(container.dispose);
  final provider = foodAmountControllerProvider(
    FoodChoiceRef(FoodRef.catalog('rice', version: '6')),
    today,
    slotId: autoPick ? null : lunch,
    replacing: replacing,
  );
  final sub = container.listen(provider, (_, _) {});
  addTearDown(sub.close);
  await container.read(provider.future);
  return (
    c: container,
    controller: container.read(provider.notifier),
    provider: provider,
  );
}

void main() {
  test('DY-011 FoodAmountController keeps the typed amount, unit and '
      'chosen meal when a slot is renamed, re-windowed or reordered '
      '(no rebuild loses input)', () async {
    final h = DiaryHarness();
    final rig = await open(h);
    rig.controller.setAmount('123.45');
    rig.controller.setUnit('g');
    for (final patch in [
      const MealSlotsCompanion(name: Value('Noon')),
      const MealSlotsCompanion(
        windowStartMin: Value(5),
        windowEndMin: Value(10),
      ),
      const MealSlotsCompanion(sortOrder: Value(9)),
    ]) {
      await h.editSlot(lunch, patch);
      await tick();
      final state = rig.c.read(rig.provider).requireValue;
      expect(state.amountBuffer, '123.45');
      expect(state.unit, 'g');
      expect(state.slotId, lunch);
    }
  });
  test('DY-011 PA3 the auto-picked meal is computed once at open and '
      'not recomputed after a window edit', () async {
    final h = DiaryHarness();
    final rig = await open(h, autoPick: true);
    await h.editSlot(
      lunch,
      const MealSlotsCompanion(
        windowStartMin: Value(5),
        windowEndMin: Value(10),
      ),
    );
    await tick();
    expect(rig.c.read(rig.provider).requireValue.slotId, lunch);
  });
  test('DY-011 PA3 the chosen meal deactivated → choice cleared, Add '
      'disabled until a pick; typed input kept', () async {
    final h = DiaryHarness();
    final rig = await open(h);
    rig.controller.setAmount('123');
    rig.controller.setUnit('g');
    await h.editSlot(lunch, const MealSlotsCompanion(active: Value(false)));
    await tick();
    final state = rig.c.read(rig.provider).requireValue;
    expect(state.slotId, isNull);
    expect(state.canAdd, isFalse);
    expect(state.amountBuffer, '123');
    expect(state.unit, 'g');
    rig.controller.setSlot(DefaultSlots.snacksId);
    expect(rig.c.read(rig.provider).requireValue.canAdd, isTrue);
  });
  test('DY-011 R1-2 the chosen meal deactivated → state.slotId is '
      'really null (not the old ID), Add disabled; submit() returns '
      'noMeal and issues no LogEntries (no automatic reassignment)', () async {
    final h = DiaryHarness();
    var calls = 0;
    final rig = await open(
      h,
      apply: (change) async {
        calls++;
        return await h.applier.apply(change);
      },
    );
    await h.editSlot(lunch, const MealSlotsCompanion(active: Value(false)));
    await tick();
    expect(rig.c.read(rig.provider).requireValue.slotId, isNull);
    expect((await rig.controller.submit() as FoodLogFailed).code, 'noMeal');
    expect(calls, 0);
  });
  test("DY-011 R1-2 a slot write doesn't rebuild the controller "
      '(typed buffer, unit and food sibling choice survive; '
      'build() runs once)', () async {
    final h = DiaryHarness();
    final rig = await open(h);
    rig.controller.setAmount('2.5');
    rig.controller.setUnit('g');
    expect(rig.controller.switchState(catalog.riceDry.id), isTrue);
    final before = rig.c.read(rig.provider).requireValue;
    await h.editSlot(lunch, const MealSlotsCompanion(name: Value('Noon')));
    await tick();
    expect(rig.c.read(rig.provider).requireValue, same(before));
  });
  test('DY-011 R1-1 replace mode: the incidental slot removed → Use '
      'this food still enabled and replaces the food keeping the '
      "entry's slot, date and group", () async {
    final h = DiaryHarness();
    await h.apply([
      CreateDishGroup(
        id: fixtureId(50),
        name: 'Group',
        date: today,
        slotId: DefaultSlots.snacksId,
      ),
      LogEntries([newEntry(1, slotId: DefaultSlots.snacksId, group: 50)]),
    ]);
    final before = await h.entry(1);
    final rig = await open(h, replacing: VersionedId(fixtureId(1), 1));
    await h.editSlot(lunch, const MealSlotsCompanion(active: Value(false)));
    await tick();
    expect(rig.c.read(rig.provider).requireValue.canAdd, isTrue);
    expect(await rig.controller.submit(), isA<FoodLogged>());
    final after = await h.entry(1);
    expect(after.slotId, before.slotId);
    expect(after.localDate, before.localDate);
    expect(after.dishGroupId, before.dishGroupId);
  });
  test(
    'DY-011 R1-1 replace mode: an entry moved under the open sheet '
    'still rebases (move-only) and keeps the typed amount, as A08b',
    () async {
      final h = DiaryHarness();
      await h.apply([
        LogEntries([newEntry(1, slotId: lunch)]),
      ]);
      final rig = await open(h, replacing: VersionedId(fixtureId(1), 1));
      rig.controller.setAmount('77');
      rig.controller.setUnit('g');
      await h.apply([
        MoveEntries([
          VersionedId(fixtureId(1), 1),
        ], toSlotId: DefaultSlots.snacksId),
      ]);
      rig.controller.rebase(VersionedId(fixtureId(1), 2));
      expect(rig.c.read(rig.provider).requireValue.amountBuffer, '77');
      expect(await rig.controller.submit(), isA<FoodLogged>());
      expect((await h.entry(1)).slotId, DefaultSlots.snacksId);
      expect((await h.entry(1)).amount, 77);
    },
  );
  test('DY-011 PA3 inactive and unknown slot failures map to '
      'slotRemoved for food and diary commands', () async {
    final h = DiaryHarness();
    await h.apply([
      LogEntries([newEntry(1, slotId: DefaultSlots.snacksId)]),
    ]);
    for (final code in ['inactiveSlot', 'unknownSlot']) {
      expect(foodLogFailure(InvalidOp(code)).code, 'slotRemoved');
      final c = setup(h, apply: (_) async => Rejected(InvalidOp(code)));
      final entry = (await h.reads.entriesOn(today)).single;
      final result =
          await c
                  .read(diaryActionsControllerProvider.notifier)
                  .moveEntry(entry, lunch)
              as DiaryActionFailed;
      expect(result.reason, DiaryActionFailure.slotRemoved);
      final log = LogFood(
        apply: (_) async => Rejected(InvalidOp(code)),
        undoStack: c.read(undoStackProvider),
        clock: h.clock,
        ids: h.ids,
      );
      expect(
        (await log(
          choice: choice(),
          input: Quantity(100, 'g'),
          date: today,
          slotId: lunch,
        ) as FoodLogFailed).code,
        'slotRemoved',
      );
    }
  });
}
