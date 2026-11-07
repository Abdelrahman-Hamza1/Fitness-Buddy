import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/amount_text.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/body/body.dart' show weightText;
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:fb_mobile/features/buddy/presentation/cards/proposal_labels.dart';
import 'package:fb_mobile/features/buddy/presentation/cards/record_body_details.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// A record card in the thread (A67 D14, UX-020): edits before → after,
/// deletions, copies, saved meals, batches, personal foods, memory and
/// weigh-ins on the one card layout, or the row it resolves into. Every tap
/// goes to the thread controller; nothing here writes.
class RecordProposalCard extends ConsumerWidget {
  /// The card [card] of a message sent on [referenceDate]; [onReviewFood]
  /// opens the personal-food form for it (A67 D8).
  const new({
    required this.card,
    required this.referenceDate,
    this.onReviewFood,
    super.key,
  });

  /// The card.
  final RecordCard card;

  /// The message's day (other days are named).
  final LocalDate referenceDate;

  /// Opens the personal-food form prefilled from this card.
  final VoidCallback? onReviewFood;

  @override
  Widget build(BuildContext context, WidgetRef ref) => FbSizeFade(
    child: KeyedSubtree(
      key: ValueKey(switch (card.resolution) {
        CardResolution.open || CardResolution.confirming => 'open',
        final other => other.name,
      }),
      child: _body(context, ref),
    ),
  );

  Widget _body(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    switch (card.resolution) {
      case CardResolution.logged:
      case CardResolution.discarded:
        return _ResolvedRow(card: card);
      case CardResolution.superseded:
        return FbProposalResolvedRow(
          icon: FbIcons.info,
          text: l10n.proposalSuperseded,
        );
      case CardResolution.open || CardResolution.confirming:
        break;
    }
    final thread = ref.read(buddyThreadControllerProvider.notifier);
    final view = card.plan.view;
    final scheme = Theme.of(context).colorScheme;
    final system = ref.watch(unitSystemProvider).value ?? UnitSystem.metric;
    final slots = <String, MealSlot>{
      for (final r in [
        ...?ref.watch(slotRecordsProvider(SlotMode.normal)).value,
      ])
        r.slot.id: r.slot,
    };
    String where(LocalDate? date, String? slotId) {
      final slot = slots[slotId];
      final slotText = slot == null ? null : slotLabel(l10n, slot);
      final day = date == null || date == referenceDate
          ? null
          : dayLabelInline(context, date, referenceDate);
      return [?slotText, ?day].join(', ');
    }

    final confirming = card.resolution == CardResolution.confirming;
    final muted = FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant);
    final kind = card.kind;
    final forget = view?.memory?.forget ?? false;
    final header = [
      switch (kind) {
        RecordKind.diaryEdit ||
        RecordKind.ambiguousReference => l10n.recordKindEdit,
        RecordKind.diaryDelete => l10n.recordKindDelete,
        RecordKind.diaryCopy => l10n.recordKindCopy,
        RecordKind.savedMealLog => l10n.recordKindSavedMeal,
        RecordKind.savedMealCreate => l10n.recordKindSaveMeal,
        RecordKind.batch => l10n.recordKindBatch,
        RecordKind.batchPortion => l10n.recordKindBatchPortion,
        RecordKind.batchClose => l10n.recordKindBatchClose,
        RecordKind.personalFoodCreate => l10n.recordKindFood,
        RecordKind.memoryChange =>
          forget ? l10n.recordKindForget : l10n.recordKindRemember,
        RecordKind.weighIn => l10n.recordKindWeighIn,
        RecordKind.workout => l10n.recordKindWorkout,
        RecordKind.measurement => l10n.recordKindMeasurement,
        RecordKind.importRows => l10n.recordKindImport,
      },
      if (view != null && view.choices.isEmpty)
        if (where(view.date, view.slotId) case final w when w.isNotEmpty) w,
    ].join(' · ');
    final details = <Widget>[];
    if (view != null && view.choices.isNotEmpty) {
      details
        ..add(Text(l10n.recordWhichOne, style: FbType.body))
        ..add(
          Wrap(
            spacing: FbSpace.s2,
            runSpacing: FbSpace.s2,
            children: [
              for (final c in view.choices)
                FbAnswerChip(
                  label: l10n.recordChoice(
                    watchFoodNames(ref, c.entry.food.names).primary,
                    where(c.entry.localDate, c.entry.slotId),
                    kcalText(l10n, c.entry.snapshot.kcal),
                  ),
                  onTap: () => unawaited(thread.pickRecord(card.id, c.id)),
                ),
            ],
          ),
        );
    }
    String amount(RecordAmount a) => servingText(
      l10n,
      input: a.input,
      basis: NutrientBasis.per100g,
      system: system,
    );
    for (final line in view?.lines ?? const <RecordLine>[]) {
      final before = line.before;
      final after = line.after;
      final names = watchFoodNames(ref, line.names);
      final newNames = line.newNames == null
          ? null
          : watchFoodNames(ref, line.newNames!).primary;
      details.add(
        FbProposalLine(
          name: newNames == null
              ? names.primary
              : l10n.recordBeforeAfter(names.primary, newNames),
          secondaryName: names.secondary,
          amount: switch ((before, after)) {
            (final b?, final a?) when amount(b) != amount(a) =>
              l10n.recordBeforeAfter(amount(b), amount(a)),
            (_, final a?) => amount(a),
            (final b?, null) => amount(b),
            _ => '',
          },
          kcal: switch ((before, after)) {
            (final b?, final a?) when b.kcal.round() != a.kcal.round() =>
              l10n.recordBeforeAfter(
                kcalText(l10n, b.kcal),
                l10n.proposalItemKcal(kcalText(l10n, a.kcal)),
              ),
            (_, final a?) => l10n.proposalItemKcal(kcalText(l10n, a.kcal)),
            (final b?, null) => l10n.proposalItemKcal(kcalText(l10n, b.kcal)),
            _ => '',
          },
          marker: const SizedBox.shrink(),
          note: line.removed
              ? l10n.recordRemoved
              : kind == RecordKind.diaryCopy
              ? l10n.recordCopiesTo(where(line.toDate, line.toSlotId))
              : line.toDate != null || line.toSlotId != null
              ? l10n.recordMovesTo(
                  where(line.toDate ?? line.date, line.toSlotId ?? line.slotId),
                )
              : null,
        ),
      );
    }
    if (view?.batch case final b?) {
      details.addAll([
        if (b.wholeGrams case final w?)
          Text(
            l10n.recordBatchWhole(foodMassText(l10n, w, system: system)),
            style: FbType.body,
          ),
        Text(
          l10n.recordBatchPer100(kcalText(l10n, b.per100.kcal)),
          style: muted,
        ),
        if (b.eatenGrams case final g? when g > 0)
          Text(
            l10n.recordBatchEaten(
              foodMassText(l10n, g, system: system),
              l10n.proposalItemKcal(kcalText(l10n, b.eatenKcal ?? 0)),
            ),
            style: FbType.body,
          ),
        if (b.remainingGrams case final left? when left > 0)
          Text(
            l10n.recordBatchLeft(foodMassText(l10n, left, system: system)),
            style: muted,
          ),
        if (kind == RecordKind.batch)
          FbSegmented<BatchPath>(
            options: [
              FbOption(
                value: BatchPath.quick,
                label: l10n.recordBatchPathQuick,
              ),
              FbOption(
                value: BatchPath.leftovers,
                label: l10n.recordBatchPathLeftovers,
              ),
            ],
            selected: b.path,
            enabled: !confirming,
            onSelected: (p) => unawaited(thread.setRecordPath(card.id, p)),
          ),
      ]);
    }
    if (view?.food case final f?) {
      details.addAll([
        if (f.aliases.isNotEmpty)
          Text(l10n.recordFoodAliases(f.aliases.join(', ')), style: muted),
        if (f.per100 case final n?)
          Text(
            l10n.recordBatchPer100(kcalText(l10n, n.kcal)),
            style: FbType.body,
          ),
        if (f.stated?.kcal case final k?)
          Text(
            l10n.recordFoodStated(l10n.proposalItemKcal(kcalText(l10n, k))),
            style: FbType.body,
          ),
      ]);
    }
    if (view?.memory case final m?) {
      details.add(Text(_memoryText(l10n, m), style: FbType.body));
    }
    if (view?.weighIn case final w?) {
      final unit = w.draft.input.unit;
      details.addAll([
        Text(
          l10n.recordWeighIn(
            weightText(l10n, w.draft.kg, unit),
            dayLabelInline(context, w.draft.localDate, referenceDate),
          ),
          style: FbType.numeric(FbType.headline),
        ),
        if (w.trendDeltaKg case final d?)
          Text(
            l10n.recordWeighInTrend(
              '${d >= 0 ? '+' : '−'}${weightText(l10n, d.abs(), unit)}',
            ),
            style: muted,
          ),
      ]);
    }
    if (view?.workout case final w?) {
      details.addAll(
        workoutDetails(
          context,
          card: card,
          view: w,
          thread: thread,
          enabled: !confirming,
        ),
      );
    }
    if (view?.measurement case final m?) {
      details.addAll(
        measurementDetails(context, view: m, referenceDate: referenceDate),
      );
    }
    if (view?.imports case final i?) {
      details.addAll(
        importDetails(
          context,
          card: card,
          view: i,
          referenceDate: referenceDate,
          thread: thread,
          enabled: !confirming,
        ),
      );
    }
    for (final note in view?.notes ?? const <RecordNote>{}) {
      details.add(Text(_noteText(l10n, note, system), style: muted));
    }
    if (card.changedMeanwhile) {
      details.add(Text(l10n.buddyChangedMeanwhile, style: muted));
    }
    final lines = view?.lines ?? const [];
    final delta = view?.kcalDelta ?? 0;
    final showDelta =
        lines.isNotEmpty &&
        (kind == RecordKind.diaryEdit ||
            kind == RecordKind.diaryDelete ||
            kind == RecordKind.ambiguousReference) &&
        delta.round() != 0;
    final showTotal =
        lines.isNotEmpty &&
        (kind == RecordKind.diaryCopy || kind == RecordKind.savedMealLog);
    final viaForm = kind == RecordKind.personalFoodCreate;
    final canConfirm =
        !confirming && (viaForm ? onReviewFood != null : card.plan.canConfirm);
    return FbProposalCard(
      header: header,
      title: view?.title,
      details: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s1,
        children: details,
      ),
      impact: showDelta || showTotal
          ? Text(
              showDelta
                  ? l10n.recordKcalChange(
                      '${delta > 0 ? '+' : '−'}'
                      '${l10n.proposalItemKcal(kcalText(l10n, delta.abs()))}',
                    )
                  : l10n.recordKcalTotal(
                      l10n.proposalItemKcal(
                        kcalText(
                          l10n,
                          lines.fold(0, (s, l) => s + (l.after?.kcal ?? 0)),
                        ),
                      ),
                    ),
              style: FbType.numeric(FbType.headline)
                  .copyWith(color: scheme.onSurface),
            )
          : null,
      actions: FbProposalActions(
        discardLabel: l10n.proposalDiscard,
        reserveReason: true,
        confirmLabel: switch (kind) {
          RecordKind.diaryEdit || RecordKind.ambiguousReference =>
            card.plan.ops.whereType<DeleteEntries>().isNotEmpty
                ? l10n.recordConfirmDelete
                : l10n.recordConfirmEdit,
          RecordKind.diaryDelete => l10n.recordConfirmDelete,
          RecordKind.diaryCopy => l10n.recordConfirmCopy,
          RecordKind.savedMealLog ||
          RecordKind.batchPortion => l10n.proposalLogIt,
          RecordKind.savedMealCreate ||
          RecordKind.batch ||
          RecordKind.weighIn ||
          RecordKind.workout ||
          RecordKind.measurement => l10n.recordConfirmSave,
          RecordKind.importRows => l10n.recordConfirmImport(
            view?.imports?.includedCount ?? 0,
          ),
          RecordKind.batchClose => l10n.recordConfirmClose,
          RecordKind.personalFoodCreate => l10n.recordConfirmReview,
          RecordKind.memoryChange =>
            forget ? l10n.recordConfirmForget : l10n.recordConfirmRemember,
        },
        reason: confirming
            ? l10n.proposalLogging
            : card.couldNotSave
            ? l10n.recordCouldNotSave
            : null,
        onDiscard: confirming
            ? null
            : () => unawaited(thread.discardRecord(card.id)),
        onConfirm: !canConfirm
            ? null
            : viaForm
            ? onReviewFood
            : () {
                unawaited(HapticFeedback.lightImpact());
                unawaited(thread.confirmRecord(card.id));
              },
      ),
    );
  }

  static String _noteText(
    AppLocalizations l10n,
    RecordNote note,
    UnitSystem system,
  ) => switch (note) {
    RecordNote.timeIgnored => l10n.recordNoteTimeIgnored,
    RecordNote.rawWeight => l10n.recordNoteRawWeight,
    RecordNote.closesBatch => l10n.recordNoteClosesBatch,
    RecordNote.quickPath => l10n.recordNoteQuickPath,
    RecordNote.leftovers => l10n.recordNoteLeftovers,
    RecordNote.plateAssumed => l10n.recordNotePlate(
      foodMassText(l10n, batchPlateGrams, system: system),
    ),
    RecordNote.estimate => l10n.recordNoteEstimate,
  };
}

/// "rice: weighed raw", "my bowl: 350 g", "shake: whey shake".
String _memoryText(AppLocalizations l10n, MemoryView m) {
  final value = memoryValueText(m.value ?? '');
  if (m.forget || m.value == null) return m.subject;
  final what = switch (m.dimension) {
    'state' => l10n.buddyMemoryDimensionState,
    'fat' => l10n.buddyMemoryDimensionFat,
    'variant' => l10n.buddyMemoryDimensionVariant,
    'portion' => l10n.buddyMemoryDimensionPortion,
    _ => null,
  };
  return what == null
      ? l10n.recordMemoryLine(m.subject, value)
      : l10n.recordMemoryDefault(m.subject, what, value);
}

/// A stored memory value as words: an option code `oil:1.0:tsp` reads
/// "oil 1 tsp". User content.
String memoryValueText(String value) {
  final parts = value.split(':');
  if (parts.length != 3) return value;
  final n = double.tryParse(parts[1]);
  final number = n == null
      ? parts[1]
      : n == n.roundToDouble()
      ? n.toInt().toString()
      : n.toString();
  return '${parts[0]} $number ${parts[2]}';
}

/// A resolved record card: what happened, with Undo for the undo window.
class _ResolvedRow extends ConsumerStatefulWidget {
  const new({required this.card});

  final RecordCard card;

  @override
  ConsumerState<_ResolvedRow> createState() => _ResolvedRowState();
}

class _ResolvedRowState extends ConsumerState<_ResolvedRow> {
  Timer? _window;
  bool _offered = true;

  @override
  void initState() {
    super.initState();
    final at = widget.card.appliedAt;
    final left = at == null
        ? Duration.zero
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
    final card = widget.card;
    final discarded = card.resolution == CardResolution.discarded;
    final canUndo =
        _offered && card.undoEntryId != null && card.undoRefused == null;
    return FbProposalResolvedRow(
      icon: discarded ? FbIcons.delete : FbIcons.check,
      text: discarded
          ? l10n.proposalDiscarded
          : switch (card.plan.view) {
              final v? when card.kind != RecordKind.personalFoodCreate =>
                '${l10n.recordDone} ${_summary(l10n, v)}'.trim(),
              _ => l10n.recordDone,
            },
      note: switch (card.undoRefused) {
        UndoOutcome.expired => l10n.diaryUndoExpired,
        UndoOutcome.conflict => l10n.diaryUndoConflict,
        _ => null,
      },
      undoLabel: canUndo ? l10n.proposalUndo : null,
      onUndo: canUndo
          ? () => unawaited(
              ref
                  .read(buddyThreadControllerProvider.notifier)
                  .undoRecord(card.id),
            )
          : null,
    );
  }

  static String _summary(AppLocalizations l10n, RecordView v) {
    if (v.memory case final m?) return _memoryText(l10n, m);
    return v.title ?? '';
  }
}
