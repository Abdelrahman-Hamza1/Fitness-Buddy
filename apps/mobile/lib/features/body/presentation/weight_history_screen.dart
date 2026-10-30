import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
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

  @override
  ConsumerState<WeightHistoryScreen> createState() =>
      _WeightHistoryScreenState();
}

class _WeightHistoryScreenState extends ConsumerState<WeightHistoryScreen> {
  final Map<int, TextEditingController> _controllers = {};
  WeightHistoryForm? _form;
  bool _saving = false;
  bool _leaving = false;
  WeighInFailure? _failure;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controller(WeightHistoryRow row) => _controllers
      .putIfAbsent(row.key, () => TextEditingController(text: row.text));

  void _update(WeightHistoryForm Function(WeightHistoryForm form) change) =>
      setState(() {
        _form = change(_form!);
        _failure = null;
        final keys = {for (final row in _form!.rows) row.key};
        _controllers.removeWhere((key, controller) {
          if (keys.contains(key)) return false;
          controller.dispose();
          return true;
        });
      });

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
        : form.check(
            existing: weighIns.value!,
            today: today,
            timeFor: (date) => WeighInBatch.timeFor(date, clock),
          );
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
        for (final (i, row) in form.rows.indexed)
          _RowEditor(
            key: ValueKey<int>(row.key),
            row: row,
            result: result.rows[i],
            today: today,
            controller: _controller(row),
            onPickDate: () => unawaited(_pickDate(row)),
            onText: (text) => _update((f) => f.withText(row.key, text)),
            onRemove: () => _update((f) => f.remove(row.key)),
            onKeep: (token) => _update((f) => f.keep(row.key, token)),
            onUseUnit: (unit) => _update((f) => f.withRowUnit(row.key, unit)),
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
/// with its answers.
class _RowEditor extends StatelessWidget {
  const new({
    required this.row,
    required this.result,
    required this.today,
    required this.controller,
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
  final TextEditingController controller;
  final VoidCallback onPickDate;
  final ValueChanged<String> onText;
  final VoidCallback onRemove;
  final ValueChanged<WeighInKeep> onKeep;
  final ValueChanged<MassUnit> onUseUnit;

  @override
  Widget build(BuildContext context) {
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
            controller: controller,
            label: l10n.weightHistoryValue,
            unit: weightUnitLabel(l10n, row.unit),
            maxDecimals: 1,
            errorText: error,
            onChanged: onText,
          ),
          if (message != null) Text(message, style: note),
          if (token != null)
            Wrap(
              spacing: FbSpace.s2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
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
            ),
          if (result.sameDay) Text(l10n.weightHistorySameDay, style: note),
        ],
      ),
    );
  }
}
