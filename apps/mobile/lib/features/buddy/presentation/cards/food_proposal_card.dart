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
  /// The card of [view].
  const new({required this.view, super.key});

  /// What the card shows.
  final FoodCardView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final thread = ref.read(buddyThreadControllerProvider.notifier);
    switch (view.resolution) {
      case CardResolution.logged:
        return _LoggedRow(view: view);
      case CardResolution.undone:
        return FbProposalResolvedRow(
          icon: FbIcons.info,
          text: l10n.proposalUndone,
        );
      case CardResolution.discarded:
        return FbProposalResolvedRow(
          icon: FbIcons.info,
          text: l10n.proposalDiscarded,
        );
      case CardResolution.open || CardResolution.confirming:
        break;
    }
    final system = ref.watch(unitSystemProvider).value ?? UnitSystem.metric;
    final slots = ref.watch(slotRecordsProvider).value ?? const [];
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
    final String? reason;
    if (confirming) {
      reason = l10n.proposalLogging;
    } else if (view.couldNotLog) {
      reason = l10n.proposalCouldNotLog;
    } else if (!view.canLog) {
      reason = blockedText(l10n, blocked ?? ProposalIssue.sessionIncomplete);
    } else {
      reason = null;
    }
    final totals = view.totals;
    final scheme = Theme.of(context).colorScheme;
    return FbProposalCard(
      header: header,
      title: view.dishName,
      details: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final line in view.lines)
            FbChangeHighlight(
              token: view.changedLineIds.contains(line.id)
                  ? view.changeToken
                  : null,
              child: ProposalLineRow(line: line, system: system),
            ),
        ],
      ),
      assumptions: [
        for (final chip in view.assumptions)
          _AssumptionChip(
            cardId: view.id,
            chip: chip,
            system: system,
            enabled: !confirming,
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
                    onAnswer: confirming
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
        confirmLabel: l10n.proposalLogIt,
        reason: reason,
        onDiscard: confirming ? null : () => unawaited(thread.discard(view.id)),
        onConfirm: view.canLog
            ? () {
                unawaited(HapticFeedback.lightImpact());
                unawaited(thread.confirm(view.id));
              }
            : null,
      ),
    );
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
