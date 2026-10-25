import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/diary/application/diary_actions.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart'
    show MaterialLocalizations, TimeOfDay;

// What a swipe on a diary item does (DY-022): run the command, then say what
// happened. The container and the root context are taken before the first
// await, because the row that started the action may be gone by then (a
// deleted row leaves the tree in the same frame).

/// Deletes [entry] (a direct action): the row disappears at once, the
/// snackbar offers Undo (UX-030).
Future<void> deleteEntryWithUndo(BuildContext context, DiaryEntry entry) async {
  final container = ProviderScope.containerOf(context);
  final host = Navigator.of(context, rootNavigator: true).context;
  final outcome = await container
      .read(diaryActionsControllerProvider.notifier)
      .deleteEntry(entry);
  if (!host.mounted) return;
  reportDiaryOutcome(
    host,
    outcome,
    () => host.l10n.diaryEntryDeleted(entry.food.names.en),
  );
}

/// Opens the time picker on [entry]'s time and, once a time is picked,
/// changes it with Undo (DY-021). The same time writes nothing.
Future<void> chooseTimeAndChange(BuildContext context, DiaryEntry entry) async {
  final container = ProviderScope.containerOf(context);
  final host = Navigator.of(context, rootNavigator: true).context;
  final now = entry.time.localDateTime.time;
  final picked = await showFbTimePicker(
    context,
    initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
  );
  if (picked == null || !host.mounted) return;
  final time = LocalTime(picked.hour, picked.minute);
  final outcome = await container
      .read(diaryActionsControllerProvider.notifier)
      .changeTime(entry, time);
  if (!host.mounted) return;
  reportDiaryOutcome(
    host,
    outcome,
    () => host.l10n.diaryTimeChanged(
      entry.food.names.en,
      timeText(host, time.hour, time.minute),
    ),
  );
}

/// Opens the food search in change-food mode for [entry] (DY-021, A08 D7):
/// the route carries the entry and the version shown, so a swap on a stale
/// item is refused instead of overwriting a newer edit.
void changeFoodOf(WidgetRef ref, DiaryEntry entry) => ref
    .read(appNavigatorProvider)
    .push(
      FoodSearchRoute(
        date: entry.localDate,
        slotId: entry.slotId,
        replace: VersionedId(entry.id, entry.version),
      ),
    );

/// A clock time in the device's 12 or 24 hour format.
String timeText(BuildContext context, int hour, int minute) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: hour, minute: minute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

/// Says what a diary command did: the Undo snackbar with [done]'s text, or a
/// calm sentence for a refusal (A08 D12(3)). [changedMessage] replaces the
/// item sentence for commands on something other than one item (a meal).
void reportDiaryOutcome(
  BuildContext host,
  DiaryActionOutcome outcome,
  String Function() done, {
  String Function()? changedMessage,
}) {
  switch (outcome) {
    case DiaryActionDone(:final undoEntryId):
      showUndoFeedback(host, message: done(), undoEntryId: undoEntryId);
    case DiaryActionUnchanged():
      break;
    case DiaryActionFailed(:final reason):
      showFbSnackBar(host, switch (reason) {
        DiaryActionFailure.slotRemoved => host.l10n.diarySlotRemoved,
        DiaryActionFailure.invalid => host.l10n.diaryActionFailed,
        DiaryActionFailure.removed => host.l10n.diaryActionRemoved,
        DiaryActionFailure.changed =>
          changedMessage?.call() ?? host.l10n.diaryItemChanged,
      });
  }
}
