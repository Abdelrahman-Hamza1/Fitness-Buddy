import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:fb_mobile/features/buddy/application/food_card_view.dart';
import 'package:fb_mobile/features/buddy/presentation/cards/food_picker_sheet.dart';
import 'package:fb_mobile/features/buddy/presentation/cards/proposal_labels.dart';
import 'package:fb_mobile/features/buddy/presentation/cards/proposal_line_row.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

/// A food proposal card in the thread (`spec/10` §4.1, UX-020): the open
/// card with its items, assumption chips, questions, totals and "today
/// after this", or the one line it collapses to once resolved.
///
/// Every tap goes to the thread controller; nothing here writes.
class FoodProposalCard extends ConsumerWidget {
  /// The card of [view]; [onSearch] opens food search (a stale card
  /// without its answer offers it, A23 D13).
  const new({required this.view, this.onSearch, super.key});

  /// What the card shows.
  final FoodCardView view;

  /// Closes the sheet and opens food search.
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final thread = ref.read(buddyThreadControllerProvider.notifier);
    switch (view.resolution) {
      case CardResolution.logged:
        return _LoggedRow(view: view);
      case CardResolution.discarded:
        return _DiscardedRow(view: view);
      case CardResolution.superseded:
        return FbProposalResolvedRow(
          icon: FbIcons.info,
          text: l10n.proposalSuperseded,
        );
      case CardResolution.open || CardResolution.confirming:
        break;
    }
    final system = ref.watch(unitSystemProvider).value ?? UnitSystem.metric;
    final slots =
        ref.watch(slotRecordsProvider(SlotMode.normal)).value ?? const [];
    final slot = slots
        .map((r) => r.slot)
        .where((s) => s.id == view.slotId)
        .firstOrNull;
    final time = view.time?.localDateTime;
    final timeText = time == null
        ? ''
        : MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay(hour: time.hour, minute: time.minute),
            alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
          );
    final when = slot == null
        ? timeText
        : l10n.proposalSlotAtTime(slotLabel(l10n, slot), timeText);
    // Another day than the message's: say which (B09 D8 day hints).
    final day = view.otherDay
        ? dayLabel(context, view.date, view.referenceDate!)
        : null;
    final header = day == null ? when : l10n.proposalOnDay(day, when);
    final confirming = view.resolution == CardResolution.confirming;
    final blocked = view.blockedBy;
    // A reopened card whose food details changed: a read-only preview with
    // Update card (or Search) and Discard (A23 D13).
    final stale = view.factsChanged;
    final String? reason;
    if (stale && !confirming && !view.updating) {
      reason = l10n.proposalFactsChanged;
    } else if (confirming) {
      reason = l10n.proposalLogging;
    } else if (view.updating) {
      reason = l10n.proposalUpdating;
    } else if (view.couldNotLog) {
      reason = l10n.proposalCouldNotLog;
    } else if (!view.canLog) {
      reason = blockedText(l10n, blocked ?? ProposalIssue.sessionIncomplete);
    } else {
      reason = null;
    }
    final totals = view.totals;
    final scheme = Theme.of(context).colorScheme;
    // Read-only while it's being logged or a follow-up about it is in
    // flight (A22b review 1).
    final editable = !confirming && !view.updating && !stale;
    final discardable = !confirming && !view.updating;
    return FbProposalCard(
      header: header,
      onHeaderTap: editable
          ? () => unawaited(_editWhen(context, ref, slots, time))
          : null,
      title: view.dishName,
      details: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final line in view.lines)
            FbChangeHighlight(
              // Keyed by line: a swiped-off row's state never moves to the
              // next line.
              key: ValueKey(line.id),
              token: view.changedLineIds.contains(line.id)
                  ? view.changeToken
                  : null,
              child: _swipeable(
                context,
                editable,
                () => thread.removeLine(view.id, line.id),
                ProposalLineRow(
                  line: line,
                  system: system,
                  onStep: editable
                      ? (up) => thread.stepAmount(view.id, line.id, up: up)
                      : null,
                  onSwap: editable
                      ? () => unawaited(_swap(context, ref, line))
                      : null,
                  onSetAmount: editable
                      ? (q) => thread.setAmount(view.id, line.id, q)
                      : null,
                ),
              ),
            ),
          // Swiped-off items, each with its Undo (AI-042).
          for (final removed in view.removed)
            FbProposalResolvedRow(
              icon: FbIcons.delete,
              text: l10n.proposalLineRemoved(removed.name),
              undoLabel: editable ? l10n.proposalUndo : null,
              onUndo: editable
                  ? () => thread.restoreLine(view.id, removed.id)
                  : null,
            ),
          // Rebuilt with current details into its own message (A23 D11).
          if (view.rebuilt)
            FbProposalResolvedRow(
              icon: FbIcons.info,
              text: l10n.buddyCardUpdatedNote,
            ),
          // Kept on this phone until it fits (A23 D15).
          if (view.tooLargeToSync)
            FbProposalResolvedRow(
              icon: FbIcons.info,
              text: l10n.proposalTooLargeToSync,
            ),
          // Add an item picked in food search (AI-042); adding by text is
          // a follow-up message.
          if (editable)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FbButton.text(
                label: l10n.proposalAddItem,
                icon: FbIcons.add,
                onPressed: () => unawaited(_add(context, ref)),
              ),
            ),
        ],
      ),
      assumptions: [
        for (final chip in view.assumptions)
          _AssumptionChip(
            cardId: view.id,
            chip: chip,
            system: system,
            enabled: editable,
          ),
      ],
      questions: view.questions.isEmpty
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: FbSpace.s2,
              children: [
                for (final question in view.questions)
                  _Question(
                    question: question,
                    system: system,
                    onAnswer: !editable
                        ? null
                        : (optionId) => thread.adjust(
                            view.id,
                            ProposalSelect(question.dimension.id, optionId),
                          ),
                  ),
              ],
            ),
      impact: FbChangeHighlight(
        token: view.totalsChanged ? view.changeToken : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    view.isEstimate
                        ? l10n.proposalTotalKcalApprox(
                            kcalText(l10n, totals.kcal),
                          )
                        : l10n.proposalTotalKcal(kcalText(l10n, totals.kcal)),
                    style: FbType.numeric(FbType.headline)
                        .copyWith(color: scheme.onSurface),
                  ),
                ),
                // An estimate in the card makes the total one (SF-041).
                if (view.isEstimate)
                  FbEstimateMarker(
                    rangeText: switch (view.card.range) {
                      final range? => l10n.proposalEstimateRange(
                        kcalText(l10n, range.lowKcal),
                        kcalText(l10n, range.highKcal),
                      ),
                      null => kcalText(l10n, totals.kcal),
                    },
                    reason: l10n.proposalEstimateReasonTotal,
                  ),
              ],
            ),
            Text(
              l10n.proposalMacrosShort(
                _grams(l10n, totals.protein),
                _grams(l10n, totals.carbs),
                _grams(l10n, totals.fat),
                _grams(l10n, totals.fiber),
              ),
              style: FbType.numeric(FbType.bodySmall)
                  .copyWith(color: scheme.onSurfaceVariant),
            ),
            Text(
              todayAfterText(
                l10n,
                view.preview,
                day: day,
                approx: view.isEstimate,
              ),
              style: FbType.body.copyWith(color: scheme.onSurface),
            ),
          ],
        ),
      ),
      actions: FbProposalActions(
        discardLabel: l10n.proposalDiscard,
        confirmLabel: !stale
            ? l10n.proposalLogIt
            : view.canUpdate
            ? l10n.proposalUpdateCard
            : l10n.proposalSearchFoods,
        reason: reason,
        onDiscard: discardable
            ? () => unawaited(thread.discard(view.id))
            : null,
        onConfirm: stale
            ? (!discardable
                  ? null
                  : view.canUpdate
                  ? () => unawaited(thread.updateCard(view.id))
                  : onSearch)
            : view.canLog
            ? () {
                unawaited(HapticFeedback.lightImpact());
                unawaited(thread.confirm(view.id));
              }
            : null,
      ),
    );
  }

  Widget _swipeable(
    BuildContext context,
    bool enabled,
    VoidCallback onRemove,
    Widget child,
  ) => enabled
      ? FbSwipeActions(
          dismissAction: FbSwipeAction(
            label: context.l10n.proposalRemoveLine,
            icon: FbIcons.delete,
            onTriggered: onRemove,
          ),
          child: child,
        )
      : child;

  /// The alternatives of [line] (at most three) and "Search foods…" in a
  /// small sheet (AI-041); picking one swaps the food and recomputes the
  /// card. Search opens the food picker over the card.
  Future<void> _swap(
    BuildContext context,
    WidgetRef ref,
    FoodLineView line,
  ) async {
    final l10n = context.l10n;
    final alternatives = line.alternatives;
    const search = -1;
    final picked = await showFbOptionSheet<int>(
      context,
      title: l10n.proposalSwapTitle(line.food.names.en),
      selected: null,
      options: [
        for (final (i, food) in alternatives.indexed)
          FbOption(value: i, label: food.names.en),
        FbOption(value: search, label: l10n.proposalSearchFoods),
      ],
    );
    if (picked == null || !context.mounted) return;
    final thread = ref.read(buddyThreadControllerProvider.notifier);
    if (picked != search) {
      if (picked < alternatives.length) {
        thread.swapFood(view.id, line.id, alternatives[picked]);
      }
      return;
    }
    final row = await showBuddyFoodPicker(context);
    if (row != null) thread.swapPicked(view.id, line.id, row.choice);
  }

  /// "Add item": a food picked in search, at its default portion (AI-042).
  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final row = await showBuddyFoodPicker(context);
    if (row == null) return;
    ref
        .read(buddyThreadControllerProvider.notifier)
        .addPicked(view.id, row.choice, row.defaultPortion);
  }

  /// The header's meal-and-time sheet (AI-043): another active meal, or the
  /// time picker.
  Future<void> _editWhen(
    BuildContext context,
    WidgetRef ref,
    List<SlotRecord> slots,
    LocalDateTime? time,
  ) async {
    final l10n = context.l10n;
    const changeTime = '';
    final picked = await showFbOptionSheet<String>(
      context,
      title: l10n.proposalWhenTitle,
      selected: view.slotId,
      options: [
        for (final record in slots)
          if (record.slot.active)
            FbOption(
              value: record.slot.id,
              label: slotLabel(l10n, record.slot),
            ),
        FbOption(value: changeTime, label: l10n.proposalWhenChangeTime),
      ],
    );
    if (picked == null || !context.mounted) return;
    final thread = ref.read(buddyThreadControllerProvider.notifier);
    if (picked != changeTime) {
      if (picked != view.slotId) thread.setSlot(view.id, picked);
      return;
    }
    final now = time ?? LocalTime(12).on(view.date);
    final chosen = await showFbTimePicker(
      context,
      initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
    );
    if (chosen == null) return;
    thread.setTime(view.id, LocalTime(chosen.hour, chosen.minute));
  }

  static String _grams(AppLocalizations l10n, double grams) =>
      NumberFormat.decimalPattern(l10n.localeName)
          .format(DisplayRounding.nutrientGrams(grams));
}

/// An assumption chip (AI-033): its option label; a tap offers the
/// dimension's options and recomputes the card.
class _AssumptionChip extends ConsumerWidget {
  const new({
    required this.cardId,
    required this.chip,
    required this.system,
    required this.enabled,
  });

  final String cardId;
  final FoodChipView chip;
  final UnitSystem system;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final label = chipLabel(l10n, chip, system: system);
    return FbAssumptionChip(
      label: label,
      semanticLabel: l10n.proposalChipSemantics(label),
      tapHint: l10n.proposalChipTapHint,
      // Disabled while the card is being logged.
      onTap: !enabled
          ? null
          : () async {
              final picked = await showFbOptionSheet<String>(
                context,
                title: l10n.proposalAssumptionTitle,
                selected: chip.selected.id,
                options: [
                  for (final option in chip.dimension.options)
                    FbOption(
                      value: option.id,
                      label: optionLabel(
                        l10n,
                        chip.dimension,
                        option,
                        system: system,
                      ),
                    ),
                ],
              );
              if (picked == null || picked == chip.selected.id) return;
              ref
                  .read(buddyThreadControllerProvider.notifier)
                  .adjust(cardId, ProposalSelect(chip.dimension.id, picked));
            },
    );
  }
}

/// One in-card question with its answer chips, the default labelled
/// (AI-034).
class _Question extends StatelessWidget {
  const new({
    required this.question,
    required this.system,
    required this.onAnswer,
  });

  final FoodQuestionView question;
  final UnitSystem system;
  final ValueChanged<String>? onAnswer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FbSpace.s1,
      children: [
        Text(
          questionText(l10n, question),
          style: FbType.label.copyWith(color: scheme.onSurface),
        ),
        Wrap(
          spacing: FbSpace.s2,
          runSpacing: FbSpace.s2,
          children: [
            for (final option in question.options)
              FbAnswerChip(
                label: optionLabel(
                  l10n,
                  question.dimension,
                  option,
                  system: system,
                ),
                selected: option.id == question.selectedOptionId,
                isDefault: option.id == question.defaultOptionId,
                onTap: () => onAnswer?.call(option.id),
              ),
          ],
        ),
      ],
    );
  }
}

/// The logged card (AI-035): "Logged ✓ …" and one Undo for 5 s (D25).
class _LoggedRow extends ConsumerStatefulWidget {
  const new({required this.view});

  final FoodCardView view;

  @override
  ConsumerState<_LoggedRow> createState() => _LoggedRowState();
}

class _LoggedRowState extends ConsumerState<_LoggedRow> {
  Timer? _window;
  bool _offered = true;

  @override
  void initState() {
    super.initState();
    // The window runs from when it was logged (a row redrawn later, e.g.
    // the sheet reopened, gets only what's left).
    final at = widget.view.logged?.loggedAt;
    final left = at == null
        ? FbMotion.undoWindow
        : FbMotion.undoWindow - ref.read(clockProvider).nowUtc().difference(at);
    if (left <= Duration.zero) {
      _offered = false;
      return;
    }
    _window = Timer(left, () {
      if (mounted) setState(() => _offered = false);
    });
  }

  @override
  void dispose() {
    _window?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final view = widget.view;
    final logged = view.logged;
    final refused = view.undoRefused;
    final canUndo = _offered && view.undoEntryId != null && refused == null;
    return FbProposalResolvedRow(
      icon: FbIcons.check,
      text: logged == null
          ? l10n.proposalLoggedPlain
          : loggedText(
              l10n,
              logged.kcal,
              logged.preview,
              dayInline: view.otherDay
                  ? dayLabelInline(context, view.date, view.referenceDate!)
                  : null,
              approx: view.isEstimate,
            ),
      note: switch (refused) {
        UndoOutcome.expired => l10n.diaryUndoExpired,
        UndoOutcome.conflict => l10n.diaryUndoConflict,
        _ => null,
      },
      undoLabel: canUndo ? l10n.proposalUndo : null,
      onUndo: canUndo
          ? () => unawaited(
              ref.read(buddyThreadControllerProvider.notifier).undo(view.id),
            )
          : null,
    );
  }
}

/// The discarded card: "Discarded" and, for the undo window, Undo that puts
/// the card back as stored (backlog #142, A23 D10); a refused Undo says so.
class _DiscardedRow extends ConsumerStatefulWidget {
  const new({required this.view});

  final FoodCardView view;

  @override
  ConsumerState<_DiscardedRow> createState() => _DiscardedRowState();
}

class _DiscardedRowState extends ConsumerState<_DiscardedRow> {
  Timer? _window;
  bool _offered = false;

  @override
  void initState() {
    super.initState();
    final at = widget.view.discardUndoFrom;
    if (at == null) return;
    final left =
        FbMotion.undoWindow - ref.read(clockProvider).nowUtc().difference(at);
    if (left <= Duration.zero) return;
    _offered = true;
    _window = Timer(left, () {
      if (mounted) setState(() => _offered = false);
    });
  }

  @override
  void dispose() {
    _window?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final refused = widget.view.undoRefused;
    final canUndo = _offered && refused == null;
    return FbProposalResolvedRow(
      icon: FbIcons.info,
      text: l10n.proposalDiscarded,
      note: switch (refused) {
        UndoOutcome.expired => l10n.diaryUndoExpired,
        UndoOutcome.conflict => l10n.diaryUndoConflict,
        _ => null,
      },
      undoLabel: canUndo ? l10n.proposalUndo : null,
      onUndo: canUndo
          ? () => unawaited(
              ref
                  .read(buddyThreadControllerProvider.notifier)
                  .restoreDiscarded(widget.view.id),
            )
          : null,
    );
  }
}

/// A stored card that couldn't be reopened (A23 D13): "This card couldn't
/// be reopened." with Discard (its row alone); once discarded, "Discarded"
/// with Undo for the undo window.
class UnrestorableCardRow extends ConsumerStatefulWidget {
  /// The row of [card].
  const new({required this.card, super.key});

  /// The placeholder.
  final UnrestorableCard card;

  @override
  ConsumerState<UnrestorableCardRow> createState() =>
      _UnrestorableCardRowState();
}

class _UnrestorableCardRowState extends ConsumerState<UnrestorableCardRow> {
  Timer? _window;
  bool _offered = false;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(UnrestorableCardRow old) {
    super.didUpdateWidget(old);
    if (old.card.discardedAt != widget.card.discardedAt) _arm();
  }

  void _arm() {
    _window?.cancel();
    final at = widget.card.discardedAt;
    _offered = false;
    if (at == null || widget.card.undoEntryId == null) return;
    final left =
        FbMotion.undoWindow - ref.read(clockProvider).nowUtc().difference(at);
    if (left <= Duration.zero) return;
    _offered = true;
    _window = Timer(left, () {
      if (mounted) setState(() => _offered = false);
    });
  }

  @override
  void dispose() {
    _window?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final thread = ref.read(buddyThreadControllerProvider.notifier);
    final card = widget.card;
    if (card.discarded) {
      return FbProposalResolvedRow(
        icon: FbIcons.info,
        text: l10n.proposalDiscarded,
        undoLabel: _offered ? l10n.proposalUndo : null,
        onUndo: _offered
            ? () => unawaited(thread.restoreUnrestorable(card.id))
            : null,
      );
    }
    return FbProposalResolvedRow(
      icon: FbIcons.info,
      text: l10n.proposalUnrestorable,
      undoLabel: l10n.proposalDiscard,
      onUndo: () => unawaited(thread.discardUnrestorable(card.id)),
    );
  }
}
