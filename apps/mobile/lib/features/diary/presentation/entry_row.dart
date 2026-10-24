import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/amount_text.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/diary/application/diary_actions.dart';
import 'package:fb_mobile/features/diary/application/diary_view_state.dart';
import 'package:fb_mobile/features/diary/presentation/entry_actions.dart';
import 'package:fb_mobile/features/diary/presentation/large_text.dart';
import 'package:fb_mobile/features/diary/presentation/move_entry_sheet.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// "150 g", "2 loaves": the amount as the user logged it (DY-021), in the
/// unit system's words (LC-010): a logged "8 oz" reads "227 g" in metric.
String entryAmountText(
  AppLocalizations l10n,
  EntryAmount amount,
  UnitSystem system,
) =>
    servingText(l10n, input: amount.input, basis: amount.basis, system: system);

/// The badge of [entry]: "yours" once the user changed its numbers (AI-072),
/// else where they come from (FD-010).
FbSource entrySourceOf(DiaryEntry entry) => entry.editedByUser
    ? FbSource.yours
    : fbSourceOf(entry.food.provenance.source);

/// One logged item (DY-020): the source badge, the English name, the amount
/// and the calories; a tap opens its details (DY-021). Drag end to start
/// to delete with Undo, start to end to pick another meal
/// (DY-022); both are also screen-reader actions. While a command for the
/// item runs, it takes no further input (A08 D12).
class DiaryEntryTile extends ConsumerWidget {
  /// Creates the row for [entry]. [slots] are the meals a move can pick
  /// from; [expanded] says whether its details are open below; [indented]
  /// shows it as a member of a dish.
  const new({
    required this.entry,
    required this.slots,
    required this.expanded,
    this.indented = false,
    super.key,
  });

  /// The item, at the version shown (commands use it, A08 D12(1)).
  final DiaryEntry entry;

  /// Every live meal of the day.
  final List<MealSlot> slots;

  /// Whether the details are open.
  final bool expanded;

  /// Whether the row sits under a dish.
  final bool indented;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final pending = ref.watch(
      diaryActionsControllerProvider.select(
        (s) => s.pending.contains(entry.id),
      ),
    );
    final kcal = l10n.diaryKcal(DisplayRounding.kcal(entry.snapshot.kcal));
    final system = ref.watch(unitSystemProvider).value ?? UnitSystem.metric;
    final amount = entryAmountText(l10n, entry.amount, system);
    final large = usesLargeText(context);
    Widget row = Semantics(
      expanded: expanded,
      child: FbListRow(
        title: entry.food.names.en,
        subtitle: large ? kcal : amount,
        leading: FbSourceBadge(source: entrySourceOf(entry)),
        trailing: large
            ? null
            : MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: Text(kcal, style: FbType.numeric(FbType.body)),
              ),
        onTap: pending
            ? null
            : () =>
                  ref.read(diaryViewStateProvider.notifier).toggleEntry(entry),
      ),
    );
    if (indented) {
      row = Padding(
        padding: const EdgeInsetsDirectional.only(start: FbSpace.s4),
        child: row,
      );
    }
    if (pending) return row;
    return FbSwipeActions(
      dismissAction: FbSwipeAction(
        label: l10n.diaryDelete,
        icon: FbIcons.delete,
        onTriggered: () => unawaited(deleteEntryWithUndo(context, entry)),
      ),
      confirmAction: FbSwipeAction(
        label: l10n.diaryMoveToAnotherMeal,
        icon: FbIcons.move,
        onTriggered: () => unawaited(chooseSlotAndMove(context, entry, slots)),
      ),
      child: row,
    );
  }
}
