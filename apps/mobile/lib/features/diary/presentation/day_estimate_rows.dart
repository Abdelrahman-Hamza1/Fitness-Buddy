import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/approx_text.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/ui/success_haptic.dart';
import 'package:fb_mobile/features/diary/application/diary_actions.dart';
import 'package:fb_mobile/features/diary/presentation/entry_actions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:material_ui/material_ui.dart';

// A62b (DY-006, E2 A): a past day with nothing logged offers "about ___
// kcal" for the whole day; once saved the day shows "~2,300". Minimal text:
// only the "~" popup explains it.

/// [kcal] rounded, in the locale ("2,300").
String _kcalNumber(AppLocalizations l10n, double kcal) =>
    NumberFormat.decimalPattern(l10n.localeName).format(kcal.round());

/// Saves [kcal] as [date]'s day estimate, or (null) removes it, against the
/// mark [shown], and says so with Undo (DY-006, A62 D12). The container and
/// the root context are taken before the await: the row that started it is
/// gone once the day changes.
Future<DiaryActionOutcome> setDayEstimateWithUndo(
  BuildContext context,
  LocalDate date, {
  required double? kcal,
  required DayMark? shown,
}) async {
  final container = ProviderScope.containerOf(context);
  final host = Navigator.of(context, rootNavigator: true).context;
  final outcome = await container
      .read(diaryActionsControllerProvider.notifier)
      .setDayEstimate(date, kcal: kcal, shown: shown);
  if (!host.mounted) return outcome;
  if (outcome is DiaryActionDone && kcal != null) successHaptic();
  reportDiaryOutcome(
    host,
    outcome,
    () => kcal == null
        ? host.l10n.dayEstimateRemoved
        : host.l10n.dayEstimateSaved(_kcalNumber(host.l10n, kcal)),
  );
  return outcome;
}

/// "Didn't log {weekday}?" with "about ___ kcal" and Save (A62 E2 A): the
/// compact card on a past day with nothing logged and no estimate.
class DayEstimatePrompt extends ConsumerStatefulWidget {
  /// The card for [date], whose mark (if any) is [mark].
  const new({required this.date, this.mark, super.key});

  /// The past day.
  final LocalDate date;

  /// The day's live mark as shown, or null.
  final DayMark? mark;

  @override
  ConsumerState<DayEstimatePrompt> createState() => _DayEstimatePromptState();
}

class _DayEstimatePromptState extends ConsumerState<DayEstimatePrompt> {
  final _kcal = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _kcal.dispose();
    super.dispose();
  }

  double? get _value => double.tryParse(
    _kcal.text.trim().replaceAll(',', '').replaceAll(' ', ''),
  );

  Future<void> _save(double kcal) async {
    setState(() => _saving = true);
    await setDayEstimateWithUndo(
      context,
      widget.date,
      kcal: kcal,
      shown: widget.mark,
    );
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final date = widget.date;
    final weekday = DateFormat.EEEE(Localizations.localeOf(context).toString())
        .format(DateTime(date.year, date.month, date.day));
    final value = _value;
    final typed = _kcal.text.trim().isNotEmpty;
    final valid = value != null && DayEstimate.isValid(value);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        FbSpace.s4,
        0,
        FbSpace.s4,
        FbDensity.cardGap,
      ),
      child: FbCard(
        key: const ValueKey('day-estimate-prompt'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FbSpace.s3,
          children: [
            Text(
              l10n.dayEstimatePrompt(weekday),
              style: FbType.title.copyWith(color: scheme.onSurface),
            ),
            Row(
              spacing: FbSpace.s2,
              children: [
                Text(l10n.dayEstimateAbout, style: FbType.body),
                Expanded(
                  child: FbNumberField(
                    key: const ValueKey('day-estimate-kcal'),
                    controller: _kcal,
                    label: l10n.dayEstimateKcalLabel,
                    unit: l10n.diaryUnitKcal,
                    maxDecimals: 0,
                    semanticLabel: l10n.dayEstimateKcalLabel,
                    errorText: typed && !valid
                        ? l10n.dayEstimateOutOfRange
                        : null,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) {
                      if (valid && !_saving) unawaited(_save(value));
                    },
                  ),
                ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FbButton.secondary(
                key: const ValueKey('day-estimate-save'),
                label: l10n.dayEstimateSave,
                busy: _saving,
                onPressed: valid && !_saving ? () => _save(value) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The day's own estimate (DY-006, A62 D16): "~2,300". A tap edits it, "~"
/// opens "~ Your estimate" (Edit, Swap for foods) and a swipe removes it,
/// with Undo. [superseded] (the day also has food, D13): food wins, the
/// number is muted, there is no Edit and Swap for foods clears it.
class DayEstimateTile extends ConsumerWidget {
  /// The estimate of [mark].
  const new({required this.mark, required this.superseded, super.key});

  /// The day's mark, holding the estimate.
  final DayMark mark;

  /// Whether the day's food replaces it in every total.
  final bool superseded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final kcal = mark.estimateKcal!;
    final pending = ref.watch(
      diaryActionsControllerProvider.select(
        (s) => s.pending.contains('day:${mark.localDate}'),
      ),
    );
    final number = approxText(
      l10n,
      l10n.diaryKcal(DisplayRounding.kcal(kcal)),
      approximate: true,
    );
    final row = FbListRow(
      key: ValueKey(
        superseded ? 'day-estimate-superseded' : 'day-estimate-row',
      ),
      title: l10n.dayEstimateTitle,
      leading: FbEstimateMarker.action(
        key: const ValueKey('day-estimate-marker'),
        semanticsLabel: l10n.estimateMarkerLabel,
        onTap: () => unawaited(
          showDayEstimatePopup(context, mark, superseded: superseded),
        ),
      ),
      trailing: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: FbNumberSlot(
          text: number,
          sample: l10n.diaryKcal(88888),
          style: superseded
              ? FbType.body.copyWith(color: scheme.onSurfaceVariant)
              : FbType.body,
        ),
      ),
      onTap: pending || superseded
          ? null
          : () => unawaited(showDayEstimateSheet(context, mark)),
    );
    if (pending) return row;
    return FbSwipeActions(
      dismissAction: FbSwipeAction(
        label: l10n.diaryDelete,
        icon: FbIcons.delete,
        onTriggered: () => unawaited(
          setDayEstimateWithUndo(
            context,
            mark.localDate,
            kcal: null,
            shown: mark,
          ),
        ),
      ),
      child: row,
    );
  }
}

/// "~ Your estimate" for a day estimate (AI-032, A62 D16, D13): Edit opens
/// the sheet prefilled; Swap for foods opens the food search for the day,
/// keeping the estimate until a food is logged (which replaces it in the
/// same change set, D12). A [superseded] estimate has no Edit; its Swap for
/// foods removes it (the day already has food), with Undo.
Future<void> showDayEstimatePopup(
  BuildContext context,
  DayMark mark, {
  required bool superseded,
}) => showFbSheet<void>(
  context,
  title: context.l10n.estimatePopupTitle,
  // The one action-sheet style (A65 m9).
  builder: (sheet) => Consumer(
    builder: (context, ref, _) => FbActionList<VoidCallback>(
      onSelected: (run) => run(),
      actions: [
        if (!superseded)
          FbAction(
            key: const ValueKey('day-estimate-popup-edit'),
            label: context.l10n.estimateEdit,
            icon: FbIcons.edit,
            value: () {
              final host = Navigator.of(context, rootNavigator: true).context;
              Navigator.of(sheet).pop();
              unawaited(showDayEstimateSheet(host, mark));
            },
          ),
        FbAction(
          key: const ValueKey('day-estimate-popup-swap'),
          label: context.l10n.estimateSwap,
          icon: FbIcons.search,
          value: () {
            final host = Navigator.of(context, rootNavigator: true).context;
            Navigator.of(sheet).pop();
            if (superseded) {
              unawaited(
                setDayEstimateWithUndo(
                  host,
                  mark.localDate,
                  kcal: null,
                  shown: mark,
                ),
              );
            } else {
              ref
                  .read(appNavigatorProvider)
                  .push(FoodSearchRoute(date: mark.localDate));
            }
          },
        ),
      ],
    ),
  ),
);

/// Opens the day-estimate sheet on [mark]'s estimate (prefilled): one
/// calorie number, "Save ~{kcal} kcal".
Future<void> showDayEstimateSheet(BuildContext context, DayMark mark) =>
    showFbStatefulSheet<void>(
      context,
      builder: (_) => DayEstimateSheet(mark: mark),
    );

/// The body of the day-estimate sheet.
class DayEstimateSheet extends ConsumerStatefulWidget {
  /// Edits [mark]'s estimate.
  const new({required this.mark, super.key});

  /// The day's mark at the version shown.
  final DayMark mark;

  @override
  ConsumerState<DayEstimateSheet> createState() => _DayEstimateSheetState();
}

class _DayEstimateSheetState extends ConsumerState<DayEstimateSheet> {
  late NumberPadBuffer _kcal = NumberPadBuffer(
    maxDigits: 5,
    maxDecimals: 0,
    text: '${widget.mark.estimateKcal?.round() ?? ''}',
  );
  bool _padOpen = true;
  bool _saving = false;
  DiaryActionFailure? _failure;

  Future<void> _submit(double kcal) async {
    final nav = Navigator.of(context);
    setState(() {
      _saving = true;
      _failure = null;
    });
    final outcome = await setDayEstimateWithUndo(
      context,
      widget.mark.localDate,
      kcal: kcal,
      shown: widget.mark,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (outcome) {
      case DiaryActionFailed(:final reason):
        setState(() => _failure = reason);
      case DiaryActionUnchanged() || DiaryActionDone():
        nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final kcal = _kcal.value;
    final shown = kcal == null ? '0' : _kcalNumber(l10n, kcal);
    final valid = kcal != null && DayEstimate.isValid(kcal);
    final message = switch ((kcal, valid, _failure)) {
      (null, _, _) => l10n.estimateKcalNeeded,
      (_, false, _) => l10n.dayEstimateOutOfRange,
      (_, _, DiaryActionFailure.changed) => l10n.diaryItemChanged,
      (_, _, DiaryActionFailure.removed) => l10n.diaryActionRemoved,
      (_, _, final _?) => l10n.diaryActionFailed,
      _ => '',
    };
    final error = (kcal != null && !valid) || _failure != null;
    return FbSheet(
      title: l10n.dayEstimateTitle,
      actions: FbButton.primary(
        key: const ValueKey('day-estimate-submit'),
        label: l10n.estimateSave(shown),
        expand: true,
        busy: _saving,
        onPressed: valid && !_saving ? () => _submit(kcal) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s3,
        children: [
          FbAmountDisplay(
            key: const ValueKey('day-estimate-sheet-kcal'),
            amount: shown,
            unit: l10n.diaryUnitKcal,
            semanticLabel: l10n.estimateKcalLabel(shown),
            active: _padOpen,
            onTap: () => setState(() => _padOpen = !_padOpen),
            onKey: _onKey,
          ),
          if (_padOpen)
            FbNumberPad(
              onKey: _onKey,
              onDone: () => setState(() => _padOpen = false),
              allowDecimal: false,
            ),
          Text(
            message,
            key: const ValueKey('day-estimate-message'),
            maxLines: 2,
            style: FbType.bodySmall.copyWith(
              color: error ? scheme.error : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _onKey(NumberPadKey key) => setState(() {
    _kcal = _kcal.apply(key);
    _failure = null;
  });
}
