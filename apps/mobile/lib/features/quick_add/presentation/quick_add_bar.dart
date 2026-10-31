import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/quick_add/application/quick_add_controller.dart';
import 'package:fb_mobile/features/quick_add/application/quick_add_model.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The quick-add chips above Today's input bar (DY-030, HM-008, UX-004, A09
/// D14): what you most likely eat now, best first, then "+" for the full
/// search. **One tap logs** the last-used amount (or the saved meal) into
/// the viewed [date], and the snackbar offers Undo.
///
/// Nothing shows until there is something to suggest (a new user sees only
/// the input bar), and nothing shows while the suggestions are still loading
/// or if they can't be read: they are a shortcut, never a blocker. The row
/// grows in (not at all when the system asks for no animations). A chip that
/// was refused because what it showed changed says so calmly.
class QuickAddBar extends ConsumerWidget {
  /// Creates the bar for the viewed day [date].
  const new({required this.date, super.key});

  /// The diary day a tap logs into.
  final LocalDate date;

  Future<void> _log(
    BuildContext context,
    WidgetRef ref,
    QuickAddChip chip,
  ) async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final controller = ref.read(quickAddControllerProvider.notifier);
    final today = EntryTime.now(ref.read(clockProvider)).localDate;
    final outcome = await controller.logChip(chip, date);
    if (!host.mounted) return;
    // Read when the message is made, so the first frame never reads settings.
    final system = await ref
        .read(unitSystemProvider.future)
        .then<UnitSystem>((value) => value, onError: (_) => UnitSystem.metric);
    if (!host.mounted) return;
    switch (outcome) {
      case QuickAddLogged(
        :final undoEntryId,
        :final name,
        :final amount,
        :final itemCount,
      ):
        final l10n = host.l10n;
        showUndoFeedback(
          host,
          message: withDayClause(
            host,
            amount != null
                ? l10n.quickAddLoggedAmount(
                    name,
                    entryAmountText(l10n, amount, system),
                  )
                : l10n.quickAddLoggedItems(name, itemCount ?? 0),
            date,
            today,
          ),
          undoEntryId: undoEntryId,
        );
      case QuickAddFailed(:final reason):
        showFbSnackBar(
          host,
          reason == QuickAddFailure.changed
              ? host.l10n.quickAddChanged
              : host.l10n.diaryActionFailed,
        );
      case QuickAddPending() || QuickAddUnchanged():
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final chips = ref.watch(quickAddChipsProvider(date)).value ?? const [];
    final language = ref.watch(foodNameLanguageProvider);
    final row = chips.isEmpty
        ? const SizedBox(key: ValueKey('empty'), width: double.infinity)
        : FbQuickAddRow(
            key: const ValueKey('row'),
            semanticLabel: l10n.quickAddRowSemantics,
            addLabel: l10n.todayQuickAddMore,
            onAdd: () => ref
                .read(appNavigatorProvider)
                .push(FoodSearchRoute(date: date)),
            chips: [
              for (final chip in chips)
                FbQuickAddChip(
                  key: ValueKey(chip.key),
                  label: chip.nameIn(language),
                  icon: chip.ranked.candidate is SavedMealCandidate
                      ? FbIcons.meal
                      : null,
                  semanticLabel: chip.ranked.candidate is SavedMealCandidate
                      ? l10n.quickAddSavedMealChipSemantics(
                          chip.nameIn(language),
                        )
                      : l10n.quickAddChipSemantics(chip.nameIn(language)),
                  onTap: () => unawaited(_log(context, ref, chip)),
                ),
            ],
          );
    final duration = FbMotion.of(context);
    // No animation at all when the system asks for none (a zero-length
    // AnimatedSize is not allowed to relayout while it lays out).
    if (duration == Duration.zero) return row;
    return AnimatedSize(
      duration: duration,
      curve: FbMotion.curve,
      alignment: AlignmentDirectional.topStart,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: FbMotion.curve,
        child: row,
      ),
    );
  }
}
