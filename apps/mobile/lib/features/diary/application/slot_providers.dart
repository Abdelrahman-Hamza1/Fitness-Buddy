import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/diary/application/slot_actions.dart';
import 'package:fb_mobile/features/diary/application/slot_editor_state.dart';
import 'package:fb_mobile/features/diary/data/diary_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:fb_mobile/features/diary/data/diary_repository.dart'
    show SlotRecord;

part 'slot_providers.g.dart';

/// Every normal meal with the version a sheet renders, in order, live (A10
/// D12). Includes removed (inactive) meals, so a sheet open on one can say
/// so; lists show [activeSlotRecords].
@riverpod
Stream<List<SlotRecord>> slotRecords(Ref ref) =>
    ref.watch(diaryRepositoryProvider).watchSlotRecords();

/// The meals in use, in order, with their versions.
@riverpod
AsyncValue<List<SlotRecord>> activeSlotRecords(Ref ref) => ref
    .watch(slotRecordsProvider)
    .whenData(
      (records) => [
        for (final record in records)
          if (record.slot.active) record,
      ],
    );

/// How many live entries each meal holds (by meal ID; absent means none).
@riverpod
Stream<Map<String, int>> slotEntryCounts(Ref ref) =>
    ref.watch(diaryRepositoryProvider).watchSlotEntryCounts();

/// What the remove sheet shows for meal [slotId]: every live entry and dish
/// group in it with its version, and the days they are on (PA1).
@riverpod
Stream<SlotContents> slotContents(Ref ref, String slotId) =>
    ref.watch(diaryRepositoryProvider).watchSlotContents(slotId);

/// The live meals (any mode, removed ones included) for sheets that offer a
/// choice of meal and must drop a removed one (A10 D12a).
@riverpod
Stream<List<MealSlot>> liveSlots(Ref ref) =>
    ref.watch(diaryRepositoryProvider).watchSlots();

/// The Meal times list's local order while a drag is being written (D12).
@riverpod
class MealTimesEditor extends _$MealTimesEditor {
  @override
  SlotEditorState build() {
    // A stored order that matches the dropped one acknowledges it.
    ref.listen(activeSlotRecordsProvider, (_, next) {
      final records = next.value;
      if (records == null) return;
      state = state.onEmission([for (final r in records) r.slot.id]);
    });
    return const SlotEditorState();
  }

  /// Moves the row at [oldIndex] to [newIndex] in [shown] (the list as
  /// displayed) and writes the new order. A refused write snaps the list
  /// back and returns the outcome for its message.
  Future<SlotOutcome> reorder(
    List<SlotRecord> shown,
    int oldIndex,
    int newIndex,
  ) async {
    final next = [...shown];
    next.insert(newIndex, next.removeAt(oldIndex));
    state = state.dropped([for (final r in next) r.slot.id]);
    final outcome = await ref.read(slotActionsProvider.notifier).reorder(next);
    if (outcome is! SlotDone) state = state.failed();
    return outcome;
  }
}

/// [stored] in the order the list shows: the local drop order while it is
/// being written, if it still covers exactly the same meals.
List<SlotRecord> arrangedSlots(
  List<SlotRecord> stored,
  SlotEditorState editor,
) {
  final order = editor.visible([for (final r in stored) r.slot.id]);
  final byId = {for (final r in stored) r.slot.id: r};
  if (order.length != stored.length || !order.every(byId.containsKey)) {
    return stored;
  }
  return [for (final id in order) byId[id]!];
}
