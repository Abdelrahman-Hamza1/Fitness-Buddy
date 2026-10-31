import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/diary/application/slot_actions.dart';
import 'package:fb_mobile/features/diary/application/slot_providers.dart';
import 'package:fb_mobile/features/diary/presentation/slots/slot_edit_sheet.dart';
import 'package:fb_mobile/features/diary/presentation/slots/slot_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The Meal times screen (DY-010, A10 D13): the day's meals in order, each
/// with its time window and how many items it holds. Drag the grip (or use
/// the screen reader's Move up and Move down) to reorder; tap a meal to edit
/// its name and times or to remove it; Add meal adds one. Every change is a
/// direct action with Undo (UX-030).
class MealSlotsScreen extends ConsumerWidget {
  /// Creates the screen of [mode]'s meals (DY-012: the Ramadan set is
  /// customized separately).
  const new({this.mode = SlotMode.normal, super.key});

  /// The set shown.
  final SlotMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final records = ref.watch(activeSlotRecordsProvider(mode));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          mode == SlotMode.ramadan
              ? l10n.ramadanMealTimes
              : l10n.mealTimesTitle,
        ),
      ),
      body: switch (records) {
        AsyncData(:final value) => _Meals(stored: value, mode: mode),
        AsyncError() => Padding(
          padding: const EdgeInsetsDirectional.all(FbSpace.s4),
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: FbInlineBanner(
              kind: FbInlineBannerKind.error,
              message: l10n.mealTimesLoadFailed,
              actionLabel: l10n.mealTimesTryAgain,
              onAction: () => ref.invalidate(slotRecordsProvider(mode)),
            ),
          ),
        ),
        _ => const _Skeleton(),
      },
    );
  }
}

class _Skeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsetsDirectional.all(FbSpace.s4),
    child: Column(
      spacing: FbSpace.s4,
      children: [
        FbSkeleton.line(height: 40),
        FbSkeleton.line(height: 40),
        FbSkeleton.line(height: 40),
        FbSkeleton.line(height: 40),
      ],
    ),
  );
}

class _Meals extends ConsumerWidget {
  const new({required this.stored, required this.mode});

  /// The active meals as stored, in order.
  final List<SlotRecord> stored;

  /// The set shown.
  final SlotMode mode;

  Future<void> _reorder(
    BuildContext context,
    WidgetRef ref,
    List<SlotRecord> shown,
    int oldIndex,
    int newIndex,
  ) async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final outcome = await ref
        .read(mealTimesEditorProvider(mode).notifier)
        .reorder(shown, oldIndex, newIndex);
    if (!host.mounted) return;
    switch (outcome) {
      case SlotDone(:final undoEntryId):
        showUndoFeedback(
          host,
          message: host.l10n.mealTimesReordered,
          undoEntryId: undoEntryId,
        );
      case SlotUnchanged():
        break;
      case SlotFailed():
        showFbSnackBar(host, host.l10n.mealTimesReorderFailed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final editor = ref.watch(mealTimesEditorProvider(mode));
    final counts = ref.watch(slotEntryCountsProvider).value ?? const {};
    final busy = ref.watch(slotActionsProvider).isNotEmpty;
    final shown = arrangedSlots(stored, editor);
    final atLimit = shown.length >= MealSlotRules.maxActive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: FbReorderableList<SlotRecord>(
            items: shown,
            idOf: (record) => record.slot.id,
            enabled: !busy,
            onReorder: (oldIndex, newIndex) =>
                unawaited(_reorder(context, ref, shown, oldIndex, newIndex)),
            footer: Padding(
              padding: const EdgeInsetsDirectional.all(FbSpace.s4),
              child: Text(
                l10n.mealTimesFootnote,
                style: FbType.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            itemBuilder: (context, record, handle) => FbListRow(
              title: slotLabel(l10n, record.slot),
              subtitle: l10n.mealTimesRowSubtitle(
                RamadanSlots.followsPrayerTimes(record.slot)
                    ? l10n.mealTimesFollowsPrayer
                    : windowText(context, record.slot.window),
                l10n.slotItemsCount(counts[record.slot.id] ?? 0),
              ),
              trailing: handle,
              onTap: busy
                  ? null
                  : () => unawaited(showSlotEditSheet(context, record: record)),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              FbSpace.s4,
              FbSpace.s2,
              FbSpace.s4,
              FbSpace.s4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: FbSpace.s2,
              children: [
                if (atLimit)
                  Text(
                    l10n.mealTimesAddLimit(MealSlotRules.maxActive),
                    style: FbType.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                FbButton.secondary(
                  label: l10n.mealTimesAdd,
                  expand: true,
                  onPressed: atLimit || busy
                      ? null
                      : () => unawaited(showSlotEditSheet(context, mode: mode)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
