import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/diary/application/diary_actions.dart';
import 'package:fb_mobile/features/diary/application/slot_providers.dart';
import 'package:fb_mobile/features/diary/presentation/entry_actions.dart';
import 'package:fb_mobile/features/diary/presentation/live_entry.dart';
import 'package:fb_mobile/features/diary/presentation/move_to_slot_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Asks which meal to move [entry] to, then moves it with Undo (DY-022). The
/// sheet follows its item like every edit sheet (A08 D12(4)).
Future<void> chooseSlotAndMove(
  BuildContext context,
  DiaryEntry entry,
  List<MealSlot> slots,
) => showFbSheet<void>(
  context,
  title: context.l10n.diaryMoveTitle,
  builder: (_) => MoveEntrySheet(entry: entry, slots: slots),
);

/// The meals as rows for [entry]; one tap on another meal moves it. If the
/// item is deleted the list is disabled and says so; a move or time change
/// elsewhere keeps it usable; a real change offers Reload; a refused move
/// keeps the sheet open.
class MoveEntrySheet extends ConsumerStatefulWidget {
  /// Creates the sheet for [entry], at the version it was opened with.
  const new({required this.entry, required this.slots, super.key});

  /// The item.
  final DiaryEntry entry;

  /// The meals to offer.
  final List<MealSlot> slots;

  @override
  ConsumerState<MoveEntrySheet> createState() => _MoveEntrySheetState();
}

class _MoveEntrySheetState extends ConsumerState<MoveEntrySheet> {
  bool _moving = false;
  DiaryActionFailure? _failure;

  Future<void> _pick(LiveEntry live, MealSlot target) async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final nav = Navigator.of(context);
    final entry = live.entry;
    setState(() => _moving = true);
    final outcome = await ref
        .read(diaryActionsControllerProvider.notifier)
        .moveEntry(entry, target.id);
    if (!mounted) return;
    setState(() => _moving = false);
    switch (outcome) {
      case DiaryActionFailed(:final reason):
        setState(() => _failure = reason);
      case DiaryActionUnchanged():
        nav.pop();
      case DiaryActionDone():
        nav.pop();
        if (host.mounted) {
          reportDiaryOutcome(
            host,
            outcome,
            () => host.l10n.diaryEntryMoved(
              entry.food.names.en,
              slotLabel(host.l10n, target),
            ),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) => LiveEntryBuilder(
    opened: widget.entry,
    builder: (context, live) {
      final l10n = context.l10n;
      final pending = ref.watch(
        diaryActionsControllerProvider.select(
          (s) => s.pending.contains(live.entry.id),
        ),
      );
      final usable = live.canSave && !_moving && !pending;
      // The live meals, so a meal removed while the sheet is open leaves the
      // list (A10 D12a); the meals it was opened with until they load.
      final slots = ref.watch(liveSlotsProvider).value ?? widget.slots;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s3,
        children: [
          StaleEntryBanner(freshness: live.freshness, onReload: live.reload),
          if (_failure == DiaryActionFailure.slotRemoved)
            FbInlineBanner(
              kind: FbInlineBannerKind.info,
              message: l10n.diarySlotRemoved,
            )
          else if (_failure == DiaryActionFailure.invalid)
            FbInlineBanner(
              kind: FbInlineBannerKind.error,
              message: l10n.diaryActionFailed,
            )
          else if (_failure == DiaryActionFailure.changed &&
              live.freshness == EntryFreshness.fresh)
            FbInlineBanner(
              kind: FbInlineBannerKind.info,
              message: l10n.diaryItemChanged,
            ),
          MoveToSlotList(
            slots: movableSlots(slots),
            currentSlotId: live.entry.slotId,
            enabled: usable,
            onPick: (slot) => _pick(live, slot),
          ),
        ],
      );
    },
  );
}
