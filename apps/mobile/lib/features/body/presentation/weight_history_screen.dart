import 'dart:async';
import 'dart:math' as math;

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/ui/revealed_column.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/body/application/weigh_in_actions.dart';
import 'package:fb_mobile/features/body/application/weight_history_form.dart';
import 'package:fb_mobile/features/body/application/weight_providers.dart';
import 'package:fb_mobile/features/body/presentation/weight_history_discard_sheet.dart';
import 'package:fb_mobile/features/body/presentation/weight_text.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Past weigh-ins typed as rows (WB-001, WB-005, WB-031, A15b D17): each
/// row a date and a value, kg/lb chips, flags for duplicates, unit mix-ups
/// and jumps (left out until kept), and one Save that adds every included
/// row as one change set with one undo. Opened from the weight graph,
/// outside the tabs. Renders a [WeightHistoryForm]; the checks are
/// [WeighInBatchCheck]'s.
class WeightHistoryScreen extends ConsumerStatefulWidget {
  /// Creates the screen, starting from [initial] when given (previews and
  /// goldens), else one empty row in the unit setting.
  const new({this.initial, super.key});

  /// The form to start from, or `null`.
  final WeightHistoryForm? initial;

  /// The value field of the row with the stable key [rowKey] (the form's
  /// row keys count up from 0), for tests and journeys.
  static Key valueKey(int rowKey) => ValueKey('weight-history-value-$rowKey');

  /// The key of a row's reserved message line.
  static Key lineKey(int rowKey) => ValueKey('weight-history-line-$rowKey');

  @override
  ConsumerState<WeightHistoryScreen> createState() =>
      _WeightHistoryScreenState();
}

class _WeightHistoryScreenState extends ConsumerState<WeightHistoryScreen> {
  WeightHistoryForm? _form;
  bool _saving = false;
  bool _leaving = false;
  WeighInFailure? _failure;

  void _update(WeightHistoryForm Function(WeightHistoryForm form) change) =>
      setState(() {
        _form = change(_form!);
        _failure = null;
      });

  /// Removes [row]; one with something typed or picked can come back
  /// through Undo (A57 A69). A draft, not stored data: the Undo is local.
  void _remove(WeightHistoryRow row, int index) {
    _update((f) => f.remove(row.key));
    if (!row.isTouched) return;
    showFbUndoSnackBar(
      context,
      message: context.l10n.weightHistoryRowRemoved,
      onUndo: () {
        if (!mounted || _form == null) return;
        _update((f) => f.restore(row, index));
      },
    );
  }

  /// The last check and what it was made from (A57 A78): the batch check
  /// runs again only when the draft, the stored weigh-ins or the day
  /// changed, not on every rebuild.
  ({
    WeightHistoryForm form,
    List<WeighIn> existing,
    LocalDate today,
    WeighInBatchResult result,
  })?
  _checked;

  WeighInBatchResult _check(
    WeightHistoryForm form,
    List<WeighIn> existing,
    LocalDate today,
    Clock clock,
  ) {
    final last = _checked;
    if (last != null &&
        identical(last.form, form) &&
        identical(last.existing, existing) &&
        last.today == today) {
      return last.result;
    }
    final result = form.check(
      existing: existing,
      today: today,
      timeFor: (date) => WeighInBatch.timeFor(date, clock),
    );
    _checked = (form: form, existing: existing, today: today, result: result);
    return result;
  }

  LocalDate _today() => EntryTime.now(ref.read(clockProvider)).localDate;

  Future<void> _pickDate(WeightHistoryRow row) async {
    final today = _today();
    final initial = row.date ?? today;
    final picked = await showFbDatePicker(
      context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: DateTime(1970),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (picked == null || !mounted) return;
    _update(
      (form) => form.withDate(
        row.key,
        LocalDate(picked.year, picked.month, picked.day),
      ),
    );
  }

  Future<void> _confirmLeave() async {
    final discard = await showWeightHistoryDiscardSheet(context);
    if (!discard || !mounted) return;
    setState(() => _leaving = true);
    ref.read(appNavigatorProvider).pop();
  }

  Future<void> _save(WeighInBatchResult result) async {
    if (_saving || !result.canSave) return;
    final host = Navigator.of(context, rootNavigator: true).context;
    final drafts = result.included;
    setState(() {
      _saving = true;
      _failure = null;
    });
    final outcome = await ref
        .read(weighInActionsProvider.notifier)
        .logMany(drafts);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (outcome) {
      case WeighInDone(:final undoId):
        setState(() => _leaving = true);
        ref.read(appNavigatorProvider).pop();
        if (host.mounted) {
          showUndoFeedback(
            host,
            message: host.l10n.weightHistorySaved(drafts.length),
            undoEntryId: undoId,
          );
        }
      case WeighInFailed(:final reason):
        // Nothing typed is lost (UX-052).
        setState(() => _failure = reason);
      case WeighInUnchanged() || WeighInPending():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final weighIns = ref.watch(weighInsProvider);
    final units = ref.watch(unitSystemProvider);
    _form ??= widget.initial;
    if (_form == null && !units.isLoading) {
      _form = WeightHistoryForm.start(
        (units.value ?? UnitSystem.defaultSystem).bodyMass,
      );
    }
    final form = _form;
    final clock = ref.read(clockProvider);
    final today = EntryTime.now(clock).localDate;
    final result = form == null || weighIns.value == null
        ? null
        : _check(form, weighIns.value!, today, clock);
    final pending = ref.watch(
      weighInActionsProvider.select(
        (keys) => keys.contains(WeighInActions.logManyKey),
      ),
    );
    final busy = _saving || pending;
    return PopScope(
      canPop: _leaving || !(form?.isDirty ?? false),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmLeave());
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.weightHistoryTitle)),
        body: switch (weighIns) {
          AsyncError() when weighIns.value == null => FbEmptyState(
            icon: FbIcons.chart,
            title: l10n.weightHistoryTitle,
            message: l10n.weightHistoryError,
            action: FbButton.secondary(
              label: l10n.weightHistoryTryAgain,
              onPressed: () => ref.invalidate(weighInsProvider),
            ),
          ),
          _ when form == null || result == null => const Padding(
            padding: EdgeInsetsDirectional.all(FbSpace.s4),
            child: Column(
              spacing: FbSpace.s3,
              children: [
                FbSkeleton.line(height: 56),
                FbSkeleton.line(height: 56),
              ],
            ),
          ),
          _ => _rows(context, form, result, today),
        },
        bottomNavigationBar: form == null || result == null
            ? null
            : SafeArea(
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
                      Text(
                        result.rows.any(
                              (r) => r.blocking == WeighInRowFlag.incomplete,
                            )
                            ? l10n.weightHistoryIncomplete
                            : l10n.weightHistoryToSave(result.included.length),
                        style: FbType.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      FbButton.primary(
                        label: l10n.weightHistorySave,
                        expand: true,
                        onPressed: result.canSave && !busy
                            ? () => unawaited(_save(result))
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _rows(
    BuildContext context,
    WeightHistoryForm form,
    WeighInBatchResult result,
    LocalDate today,
  ) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsetsDirectional.all(FbSpace.s4),
      children: [
        Text(
          l10n.weightHistoryIntro,
          style: FbType.body.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: FbSpace.s3),
        Wrap(
          spacing: FbSpace.s2,
          children: [
            for (final unit in WeighInInput.units)
              FbChoiceChip(
                label: weightUnitLabel(l10n, unit),
                selected: form.unit == unit,
                dropdown: false,
                onTap: () => _update((f) => f.withUnit(unit)),
              ),
          ],
        ),
        const SizedBox(height: FbSpace.s3),
        // Added rows grow in, removed ones shrink away (A57 A22).
        RevealedColumn(
          children: [
            for (final (i, row) in form.rows.indexed)
              _RowEditor(
                key: ValueKey<int>(row.key),
                row: row,
                result: result.rows[i],
                today: today,
                onPickDate: () => unawaited(_pickDate(row)),
                onText: (text) => _update((f) => f.withText(row.key, text)),
                onRemove: () => _remove(row, i),
                onKeep: (token) => _update((f) => f.keep(row.key, token)),
                onUseUnit: (unit) =>
                    _update((f) => f.withRowUnit(row.key, unit)),
              ),
          ],
        ),
        if (form.canAddRow)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FbButton.text(
              label: l10n.weightHistoryAddRow,
              icon: FbIcons.add,
              onPressed: () => _update((f) => f.addRow(today)),
            ),
          ),
        if (_failure case final failure?)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: FbSpace.s3),
            child: FbInlineBanner(
              kind: FbInlineBannerKind.error,
              message: failure == WeighInFailure.future
                  ? l10n.weightHistoryFailedFuture
                  : l10n.weightHistoryFailed,
            ),
          ),
      ],
    );
  }
}

/// One row: the date chip, the value field, remove, and the row's flag
/// with its answers. The row owns its field's text: a removed row stays
/// mounted while it shrinks away (A57 A22), so its controller lives (and
/// is disposed) with the row, and an Undo during the exit keeps the text.
class _RowEditor extends StatefulWidget {
  const new({
    required this.row,
    required this.result,
    required this.today,
    required this.onPickDate,
    required this.onText,
    required this.onRemove,
    required this.onKeep,
    required this.onUseUnit,
    super.key,
  });

  final WeightHistoryRow row;
  final WeighInRowResult result;
  final LocalDate today;
  final VoidCallback onPickDate;
  final ValueChanged<String> onText;
  final VoidCallback onRemove;
  final ValueChanged<WeighInKeep> onKeep;
  final ValueChanged<MassUnit> onUseUnit;

  @override
  State<_RowEditor> createState() => _RowEditorState();
}

class _RowEditorState extends State<_RowEditor> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.row.text,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _RowEditor(
      :row,
      :result,
      :today,
      :onPickDate,
      :onText,
      :onRemove,
      :onKeep,
      :onUseUnit,
    ) = widget;
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final note = FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant);
    final error = switch (result.blocking) {
      WeighInRowFlag.outOfRange => l10n.weighInOutOfRange(
        weightWholeText(l10n, WeighInBounds.minIn(row.unit).ceil(), row.unit),
        weightWholeText(l10n, WeighInBounds.maxIn(row.unit).floor(), row.unit),
      ),
      WeighInRowFlag.future => l10n.weightHistoryFuture,
      _ => null,
    };
    final token = result.keepToken;
    final message = switch (result) {
      WeighInRowResult(exclusion: WeighInRowFlag.duplicate)
          when result.duplicateOfRow != null =>
        l10n.weightHistoryDuplicateRow,
      WeighInRowResult(exclusion: WeighInRowFlag.duplicate) =>
        l10n.weightHistoryDuplicate,
      WeighInRowResult(implausible: LikelyOtherUnit(:final suggestedUnit)) =>
        l10n.weightHistoryOtherUnit(
          weighInInputText(l10n, WeighInInput(row.value ?? 0, suggestedUnit)),
        ),
      WeighInRowResult(
        implausible: LargeChange(:final diffKg, :final reference),
      ) =>
        l10n.weightHistoryLargeChange(
          weightDiffText(l10n, diffKg, row.unit),
          dayLabel(context, reference.localDate, today),
        ),
      _ => null,
    };
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: FbSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FbSpace.s1,
        children: [
          // The date and remove on one line, the value under them, so the
          // field keeps its width at large text sizes.
          Row(
            spacing: FbSpace.s2,
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FbChoiceChip(
                    label: row.date == null
                        ? l10n.weightHistoryPickDate
                        : dayLabel(context, row.date!, today),
                    semanticLabel: l10n.weightHistoryDate,
                    icon: FbIcons.calendar,
                    onTap: onPickDate,
                  ),
                ),
              ),
              FbIconButton(
                icon: FbIcons.close,
                tooltip: l10n.weightHistoryRemoveRow,
                onPressed: onRemove,
              ),
            ],
          ),
          FbNumberField(
            key: WeightHistoryScreen.valueKey(row.key),
            controller: _controller,
            label: l10n.weightHistoryValue,
            unit: weightUnitLabel(l10n, row.unit),
            maxDecimals: 1,
            errorText: error,
            // The row's own line below carries the message (A57 A15).
            supportingLines: 0,
            onChanged: onText,
          ),
          // One reserved line per row (A57 A15, UX-045): the error, the
          // row's flag or the same-day note, with Keep / Use unit at its
          // end. Always the same height, so later rows never move when a
          // value crosses validation.
          _RowLine(
            key: WeightHistoryScreen.lineKey(row.key),
            text:
                error ??
                message ??
                (result.sameDay ? l10n.weightHistorySameDay : null),
            isError: error != null,
            actions: [
              if (token != null) ...[
                if (result.implausible
                    case LikelyOtherUnit(:final suggestedUnit)
                    when !result.kept)
                  FbButton.text(
                    label: l10n.weightHistoryUseUnit(
                      weightUnitLabel(l10n, suggestedUnit),
                    ),
                    onPressed: () => onUseUnit(suggestedUnit),
                  ),
                if (result.kept)
                  Text(l10n.weightHistoryKept, style: note)
                else
                  FbButton.text(
                    label: l10n.weightHistoryKeep,
                    onPressed: () => onKeep(token),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// A weight-history row's reserved line: [text] (cut after two lines) with
/// [actions] at its end, always as tall as two lines of small text or a
/// 48 dp target, whichever is taller, at the current text scale. On a
/// narrow screen or at large text the answers go on their own reserved
/// line under the text, at full size (A57 A15), so they never shrink below
/// a 48 dp target.
class _RowLine extends StatelessWidget {
  const new({
    required this.text,
    required this.isError,
    required this.actions,
    super.key,
  });

  final String? text;
  final bool isError;
  final List<Widget> actions;

  // Measures one line's height (and an answer button's); never shown.
  static const String _probe = 'Ag';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = FbType.bodySmall.copyWith(
      color: isError ? scheme.error : scheme.onSurfaceVariant,
    );
    final scaler = MediaQuery.textScalerOf(context);
    final painter = TextPainter(
      text: TextSpan(text: _probe, style: style),
      textDirection: Directionality.of(context),
      textScaler: scaler,
    )..layout();
    final twoLines = painter.height * 2;
    painter.dispose();
    final message = text;
    final line = message == null
        ? const SizedBox.shrink()
        : Semantics(
            liveRegion: isError,
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          );
    final stacked =
        MediaQuery.sizeOf(context).width < 360 || scaler.scale(1) >= 1.3;
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: twoLines, child: line),
          // As tall as an answer button whether or not one shows: an
          // invisible sample holds the height.
          Stack(
            alignment: AlignmentDirectional.centerEnd,
            children: [
              FbInert(
                child: Opacity(
                  opacity: 0,
                  child: FbButton.text(label: _probe, onPressed: () {}),
                ),
              ),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: actions,
              ),
            ],
          ),
        ],
      );
    }
    return SizedBox(
      height: math.max(kMinInteractiveDimension, twoLines),
      child: Row(
        spacing: FbSpace.s2,
        children: [
          Expanded(child: line),
          if (actions.isNotEmpty)
            Row(mainAxisSize: MainAxisSize.min, children: actions),
        ],
      ),
    );
  }
}
