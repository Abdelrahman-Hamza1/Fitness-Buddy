import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/diary/application/diary_actions.dart';
import 'package:fb_mobile/features/diary/presentation/move_to_slot_sheet.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  _report(
    host,
    outcome,
    () => host.l10n.diaryEntryDeleted(entry.food.names.en),
  );
}

/// Asks which meal to move [entry] to, then moves it with Undo.
Future<void> chooseSlotAndMove(
  BuildContext context,
  DiaryEntry entry,
  List<MealSlot> slots,
) async {
  final container = ProviderScope.containerOf(context);
  final host = Navigator.of(context, rootNavigator: true).context;
  final target = await showMoveToSlotSheet(
    context,
    slots: slots,
    currentSlotId: entry.slotId,
  );
  if (target == null || !host.mounted) return;
  final outcome = await container
      .read(diaryActionsControllerProvider.notifier)
      .moveEntry(entry, target.id);
  if (!host.mounted) return;
  _report(
    host,
    outcome,
    () => host.l10n.diaryEntryMoved(
      entry.food.names.en,
      slotLabel(host.l10n, target),
    ),
  );
}

void _report(
  BuildContext host,
  DiaryActionOutcome outcome,
  String Function() doneMessage,
) {
  switch (outcome) {
    case DiaryActionDone(:final undoEntryId):
      showUndoFeedback(host, message: doneMessage(), undoEntryId: undoEntryId);
    case DiaryActionUnchanged():
      break;
    case DiaryActionFailed(:final reason):
      showFbSnackBar(
        host,
        reason == DiaryActionFailure.invalid
            ? host.l10n.diaryActionFailed
            : host.l10n.diaryItemChanged,
      );
  }
}
