import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/diary_harness.dart';

void main() {
  test('DY-004 markDay marks and unmarks with one undo; already as asked is '
      'unchanged; a future day is refused', () async {
    final h = DiaryHarness();
    final c = ProviderContainer(
      overrides: [
        diaryRepositoryProvider.overrideWithValue(DiaryRepository(h.db)),
        changeSetApplierProvider.overrideWithValue(h.applier),
        clockProvider.overrideWithValue(h.clock),
        idGeneratorProvider.overrideWithValue(h.ids),
        diaryApplyProvider.overrideWithValue(h.applier.apply),
      ],
    );
    addTearDown(c.dispose);
    final actions = c.read(diaryActionsControllerProvider.notifier);
    final undo = c.read(undoStackProvider);
    final day = today.plusDays(-2);

    // Mark incomplete: one direct change set with one Undo entry.
    final marked = await actions.markDay(day, incomplete: true);
    expect(marked, isA<DiaryActionDone>());
    expect(
      (marked as DiaryActionDone).kind,
      DiaryActionKind.dayMarkedIncomplete,
    );
    expect((await h.reads.markOn(day))!.incomplete, isTrue);
    expect(undo.entries, hasLength(1));
    expect(c.read(diaryActionsControllerProvider).pending, isEmpty);

    // Already incomplete: nothing written, no new Undo entry.
    expect(
      await actions.markDay(day, incomplete: true),
      isA<DiaryActionUnchanged>(),
    );
    expect(undo.entries, hasLength(1));

    // Undo restores the unmarked day.
    expect(await undo.undo(marked.undoEntryId), UndoOutcome.undone);
    expect((await h.reads.markOn(day))?.incomplete ?? false, isFalse);

    // Mark again, then count it again: its own Undo puts the mark back.
    await actions.markDay(day, incomplete: true);
    final counted = await actions.markDay(day, incomplete: false);
    expect(
      (counted as DiaryActionDone).kind,
      DiaryActionKind.dayMarkedComplete,
    );
    expect((await h.reads.markOn(day))!.incomplete, isFalse);
    expect(await undo.undo(counted.undoEntryId), UndoOutcome.undone);
    expect((await h.reads.markOn(day))!.incomplete, isTrue);

    // Today is allowed; tomorrow is refused and writes nothing.
    expect(
      await actions.markDay(today, incomplete: true),
      isA<DiaryActionDone>(),
    );
    final future = await actions.markDay(today.plusDays(1), incomplete: true);
    expect((future as DiaryActionFailed).reason, DiaryActionFailure.invalid);
    expect(await h.reads.markOn(today.plusDays(1)), isNull);
  });
}
