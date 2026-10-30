import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/body/application/measurement_actions.dart';
import 'package:fb_mobile/features/body/application/measurement_form.dart';
import 'package:fb_mobile/features/body/application/measurement_providers.dart';
import 'package:fb_mobile/features/body/presentation/measurement_text.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the measurement sheet (WB-040, A15b D18): type chips, the value
/// prefilled with the type's latest entry, cm/in (body fat: %), the date,
/// Save. With [edit] it edits that entry with its exact stored value, unit
/// and time (and offers Delete). [type] preselects the type of a new entry.
/// The sheet closes itself once saved; the Undo snackbar shows on the root
/// messenger.
Future<void> showMeasurementSheet(
  BuildContext context, {
  MeasurementTypeRef? type,
  Measurement? edit,
}) => showFbStatefulSheet<void>(
  context,
  builder: (_) => MeasurementSheet(type: type, edit: edit),
);

/// The body of the measurement sheet. Renders a [MeasurementFormState];
/// the rules live there and in [MeasurementActions].
class MeasurementSheet extends ConsumerStatefulWidget {
  /// Logs a new entry (of [type] when given), or edits [edit].
  const new({this.type, this.edit, super.key});

  /// The preselected type of a new entry; waist when `null`.
  final MeasurementTypeRef? type;

  /// The entry to edit, at the version shown; `null` to log.
  final Measurement? edit;

  @override
  ConsumerState<MeasurementSheet> createState() => _MeasurementSheetState();
}

class _MeasurementSheetState extends ConsumerState<MeasurementSheet> {
  final TextEditingController _value = TextEditingController();
  MeasurementFormState? _form;
  bool _saving = false;
  MeasurementFailure? _failure;

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  MeasurementFormState? _formOf(
    List<MeasurementTypeView>? views,
    AsyncValue<UnitSystem> units,
  ) {
    if (_form != null) return _form;
    if (views == null || units.isLoading) return null;
    final length = (units.value ?? UnitSystem.defaultSystem).length;
    final edit = widget.edit;
    final type =
        widget.type ?? MeasurementTypeRef.builtIn(MeasurementKind.waist);
    final form = edit != null
        ? MeasurementFormState.edit(edit, lengthUnit: length)
        : MeasurementFormState.create(
            type: type,
            lengthUnit: length,
            now: EntryTime.now(ref.read(clockProvider)),
            latest: _latest(views, type),
          );
    _value.text = form.text;
    return _form = form;
  }

  static Measurement? _latest(
    List<MeasurementTypeView> views,
    MeasurementTypeRef type,
  ) {
    for (final view in views) {
      if (view.ref == type) return view.series.latest;
    }
    return null;
  }

  void _update(MeasurementFormState Function(MeasurementFormState f) change) {
    final before = _form!.text;
    setState(() {
      _form = change(_form!);
      _failure = null;
    });
    if (_form!.text != before && _value.text != _form!.text) {
      _value.text = _form!.text;
    }
  }

  Future<void> _pickDate() async {
    final clock = ref.read(clockProvider);
    final today = EntryTime.now(clock).localDate;
    final current = _form!.time.localDate;
    final picked = await showFbDatePicker(
      context,
      initialDate: DateTime(current.year, current.month, current.day),
      firstDate: DateTime(1970),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (picked == null || !mounted) return;
    _update(
      (f) => f.withDate(
        LocalDate(picked.year, picked.month, picked.day),
        now: EntryTime.now(clock),
        clock: clock,
      ),
    );
  }

  Future<void> _save(String typeName) async {
    final form = _form;
    final draft = form?.draft;
    if (_saving || form == null || draft == null || form.issue != null) {
      return;
    }
    final host = Navigator.of(context, rootNavigator: true).context;
    final nav = Navigator.of(context);
    final actions = ref.read(measurementActionsProvider.notifier);
    setState(() => _saving = true);
    final editing = form.editing;
    final outcome = editing == null
        ? await actions.log(draft)
        : await actions.update(editing, draft);
    if (mounted) setState(() => _saving = false);
    switch (outcome) {
      case MeasurementDone(:final undoId, :final kind):
        if (mounted) nav.pop();
        if (host.mounted) {
          final l10n = host.l10n;
          final value = measurementInputText(l10n, draft.input);
          showUndoFeedback(
            host,
            message: kind == MeasurementKindOfChange.measurementUpdated
                ? l10n.measurementUpdated(typeName, value)
                : l10n.measurementSaved(typeName, value),
            undoEntryId: undoId,
          );
        }
      case MeasurementUnchanged():
        if (mounted) nav.pop();
      case MeasurementPending():
        break;
      case MeasurementFailed(:final reason):
        if (mounted) setState(() => _failure = reason);
    }
  }

  Future<void> _delete(Measurement measurement) async {
    if (_saving) return;
    final host = Navigator.of(context, rootNavigator: true).context;
    final nav = Navigator.of(context);
    setState(() {
      _saving = true;
      _failure = null;
    });
    final outcome = await ref
        .read(measurementActionsProvider.notifier)
        .delete(measurement);
    if (mounted) setState(() => _saving = false);
    switch (outcome) {
      case MeasurementDone(:final undoId):
        if (mounted) nav.pop();
        if (host.mounted) {
          showUndoFeedback(
            host,
            message: host.l10n.measurementDeleted,
            undoEntryId: undoId,
          );
        }
      case MeasurementFailed(:final reason):
        if (mounted) setState(() => _failure = reason);
      case MeasurementUnchanged() || MeasurementPending():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final views = ref.watch(latestByTypeProvider).value;
    final units = ref.watch(unitSystemProvider);
    final form = _formOf(views, units);
    final edit = widget.edit;
    final pending = ref.watch(
      measurementActionsProvider.select(
        (keys) => keys.contains(edit?.id ?? MeasurementActions.logKey),
      ),
    );
    final busy = _saving || pending;
    String nameOf(MeasurementTypeRef type) {
      for (final view in views ?? const <MeasurementTypeView>[]) {
        if (view.ref == type) {
          return measurementTypeName(l10n, type, customName: view.customName);
        }
      }
      return measurementTypeName(l10n, type);
    }

    final canSave = form != null && form.issue == null && !busy;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: FbSheet(
        title: edit == null
            ? l10n.measurementSheetTitle
            : l10n.measurementEditTitle,
        actions: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FbSpace.s2,
          children: [
            FbButton.primary(
              label: l10n.measurementSave,
              expand: true,
              onPressed: canSave
                  ? () => unawaited(_save(nameOf(form.type)))
                  : null,
            ),
            if (edit != null)
              FbButton.text(
                label: l10n.measurementDelete,
                icon: FbIcons.delete,
                expand: true,
                onPressed: busy ? null : () => unawaited(_delete(edit)),
              ),
          ],
        ),
        child: form == null || views == null
            ? const FbSkeleton.line(height: 56)
            : _content(context, form, views, nameOf),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    MeasurementFormState form,
    List<MeasurementTypeView> views,
    String Function(MeasurementTypeRef type) nameOf,
  ) {
    final l10n = context.l10n;
    final today = EntryTime.now(ref.read(clockProvider)).localDate;
    final range = (
      MeasurementBounds.minIn(form.unit),
      MeasurementBounds.maxIn(form.unit),
    );
    String bound(double value) => l10n.measurementValue(
      measurementNumber(l10n, value),
      measurementUnitLabel(l10n, form.unit),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        if (!form.isEdit)
          Semantics(
            label: l10n.measurementTypeLabel,
            container: true,
            child: Wrap(
              spacing: FbSpace.s2,
              runSpacing: FbSpace.s2,
              children: [
                for (final view in views)
                  FbChoiceChip(
                    label: nameOf(view.ref),
                    selected: view.ref == form.type,
                    dropdown: false,
                    onTap: () => _update(
                      (f) => f.withType(view.ref, latest: view.series.latest),
                    ),
                  ),
              ],
            ),
          ),
        FbNumberField(
          controller: _value,
          label: l10n.measurementValueLabel,
          unit: measurementUnitLabel(l10n, form.unit),
          errorText: form.issue == MeasurementFormIssue.outOfRange
              ? l10n.measurementOutOfRange(bound(range.$1), bound(range.$2))
              : null,
          onChanged: (text) => _update((f) => f.withText(text)),
        ),
        if (form.units.length > 1)
          Wrap(
            spacing: FbSpace.s2,
            children: [
              for (final unit in form.units)
                FbChoiceChip(
                  label: measurementUnitLabel(l10n, unit),
                  selected: unit == form.unit,
                  dropdown: false,
                  onTap: () => _update((f) => f.withUnit(unit)),
                ),
            ],
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FbChoiceChip(
            label: l10n.measurementDate,
            value: dayLabel(context, form.time.localDate, today),
            icon: FbIcons.calendar,
            onTap: () => unawaited(_pickDate()),
          ),
        ),
        if (_failure case final failure?)
          FbInlineBanner(
            kind: FbInlineBannerKind.error,
            message: switch (failure) {
              MeasurementFailure.changed => l10n.measurementFailedChanged,
              MeasurementFailure.removed => l10n.measurementFailedRemoved,
              MeasurementFailure.unknownType => l10n.measurementFailedType,
              MeasurementFailure.future => l10n.measurementFailedFuture,
              MeasurementFailure.duplicateName ||
              MeasurementFailure.invalid => l10n.measurementFailedInvalid,
            },
          ),
      ],
    );
  }
}
