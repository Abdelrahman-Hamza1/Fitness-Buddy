import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/diary_harness.dart';
import 'diary_edit_commands_test.dart' show setup;

void main() {
  test('DY-010 SlotActions: one command in flight per slot; Rejected → '
      'typed Failed (changed / removed / invalid reason)', () async {
    final h = DiaryHarness();
    final pending = Completer<ApplyResult>();
    final c = setup(h, apply: (_) => pending.future);
    final actions = c.read(slotActionsProvider.notifier);
    final slot = (await DiaryRepository(h.db).watchSlotRecords().first).first;
    final patch = MealSlotPatch(name: 'Private', setName: true);
    final first = actions.updateSlot(slot, patch);
    expect(c.read(slotActionsProvider), {slot.slot.id});
    expect(await actions.updateSlot(slot, patch), isA<SlotUnchanged>());
    expect(await actions.reorder([slot]), isA<SlotUnchanged>());
    pending.complete(const Rejected(InvalidOp('sourceChanged')));
    expect((await first as SlotFailed).reason, SlotFailure.changed);
    expect(c.read(slotActionsProvider), isEmpty);
    for (final (failure, expected, code)
        in <(ChangeFailure, SlotFailure, String?)>[
          (
            VersionConflict(
              entity: 'mealSlot',
              id: slot.slot.id,
              expected: 1,
              actual: 2,
            ),
            SlotFailure.changed,
            null,
          ),
          (
            RowNotFound(entity: 'mealSlot', id: slot.slot.id),
            SlotFailure.removed,
            null,
          ),
          (const InvalidOp('inactiveSlot'), SlotFailure.removed, null),
          (const InvalidOp('lastSlot'), SlotFailure.invalid, 'lastSlot'),
        ]) {
      final container = setup(
        h,
        apply: (_) async => throw ChangeRejected(failure),
      );
      final result =
          await container
                  .read(slotActionsProvider.notifier)
                  .updateSlot(slot, patch)
              as SlotFailed;
      expect(result.reason, expected);
      expect(result.code, code);
      expect(container.read(slotActionsProvider), isEmpty);
    }
  });
  test(
    'UX-030 SlotActions records direct slot commands and no-op writes no Undo',
    () async {
      final h = DiaryHarness();
      final c = setup(h);
      final actions = c.read(slotActionsProvider.notifier);
      expect(await actions.addSlot(' '), isA<SlotFailed>());
      final added =
          await actions.addSlot('Custom', window: TimeWindow(1, 2)) as SlotDone;
      expect(added.kind, SlotKind.slotAdded);
      expect(added.args['name'], 'Custom');
      final records = await DiaryRepository(h.db).watchSlotRecords().first;
      final record = records.singleWhere((r) => r.slot.name == 'Custom');
      expect(
        await actions.updateSlot(
          record,
          MealSlotPatch(name: 'Custom', setName: true),
        ),
        isA<SlotUnchanged>(),
      );
      expect(
        (await actions.updateSlot(
          record,
          MealSlotPatch(name: 'Renamed', setName: true),
        ) as SlotDone).kind,
        SlotKind.slotUpdated,
      );
      expect(
        (await actions.reorder(
          (await DiaryRepository(
            h.db,
          ).watchSlotRecords().first).reversed.toList(),
        ) as SlotDone).kind,
        SlotKind.slotsReordered,
      );
      final current = (await DiaryRepository(h.db).watchSlotRecords().first)
          .singleWhere((r) => r.slot.id == record.slot.id);
      expect(
        (await actions.removeSlot(
          current,
          shown: SlotContents.empty,
        ) as SlotDone).kind,
        SlotKind.slotRemoved,
      );
    },
  );
  test('DY-010 SlotEditorState holds dropped order until matching '
      'emission or command failure', () {
    const initial = SlotEditorState();
    final dropped = initial.dropped(['b', 'a']);
    expect(dropped.visible(['a', 'b']), ['b', 'a']);
    expect(dropped.onEmission(['a', 'b']), same(dropped));
    expect(dropped.onEmission(['a']), same(dropped));
    expect(dropped.onEmission(['b', 'a']).orderOverride, isNull);
    expect(dropped.failed().visible(['a', 'b']), ['a', 'b']);
  });
}
