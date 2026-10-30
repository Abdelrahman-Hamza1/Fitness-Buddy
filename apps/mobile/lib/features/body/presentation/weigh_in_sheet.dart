import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/body/application/weigh_in_actions.dart';
import 'package:fb_mobile/features/body/application/weigh_in_form.dart';
import 'package:fb_mobile/features/body/application/weight_providers.dart';
import 'package:fb_mobile/features/body/presentation/weight_text.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the weigh-in sheet (WB-001, A14 D8): the number pad prefilled with
/// the latest weigh-in, kg/lb, date and time, an optional note, Save. With
/// [edit] it edits that weigh-in (and offers Delete). [date] presets the
/// day when logging from a past day page (at now's clock time; never in the
/// future). The sheet closes itself once saved; the Undo snackbar shows on
/// the root messenger.
Future<void> showWeighInSheet(
  BuildContext context, {
  LocalDate? date,
  WeighIn? edit,
}) => showFbStatefulSheet<void>(
  context,
  builder: (_) => WeighInSheet(date: date, edit: edit),
);

/// The body of the weigh-in sheet. Renders a [WeighInFormState]; the
/// rules live there and in [WeighInActions].
class WeighInSheet extends ConsumerStatefulWidget {
  /// Logs a weigh-in (on [date] when given), or edits [edit].
  const new({this.date, this.edit, super.key});

  /// The day page it was opened from; `null` for today.
  final LocalDate? date;

  /// The weigh-in to edit, at the version shown; `null` to log.
  final WeighIn? edit;

  @override
  ConsumerState<WeighInSheet> createState() => _WeighInSheetState();
}

class _WeighInSheetState extends ConsumerState<WeighInSheet> {
  /// How long the confirmation's answers ignore taps after it appears, so
  /// a blind double tap on Save doesn't answer it (A14 UX review M1).
  static const Duration _confirmGuard = Duration(milliseconds: 300);

  final TextEditingController _note = TextEditingController();
  final FocusNode _noteFocus = FocusNode();
  WeighInFormState? _form;

  /// The pad is open from the start: the sheet exists to type.
  bool _padOpen = true;
  bool _noteOpen = false;
  bool _saving = false;
  WeighInFailure? _failure;

  /// Whether the open confirmation takes answers yet ([_confirmGuard]).
  bool _confirmArmed = false;
  Timer? _confirmTimer;

  @override
  void initState() {
    super.initState();
    // Typing a note closes the pad: the keyboard takes its place.
    _noteFocus.addListener(() {
      if (_noteFocus.hasFocus && _padOpen) setState(() => _padOpen = false);
    });
  }

  @override
  void dispose() {
    _confirmTimer?.cancel();
    _noteFocus.dispose();
    _note.dispose();
    super.dispose();
  }

  /// Starts the confirmation's tap guard.
  void _armConfirm() {
    _confirmTimer?.cancel();
    _confirmArmed = false;
    _confirmTimer = Timer(_confirmGuard, () {
      if (mounted) setState(() => _confirmArmed = true);
    });
  }

  /// Opens or closes the pad; opening it ends the note's typing.
  void _togglePad() {
    if (!_padOpen) _noteFocus.unfocus();
    setState(() => _padOpen = !_padOpen);
  }

  /// "Reload" (A14 m6): the edited weigh-in as stored now, with what was
  /// typed kept.
  void _reload() {
    final next = _form!.reload();
    setState(() {
      if (next == null) {
        _failure = WeighInFailure.removed;
        return;
      }
      _form = next;
      _failure = null;
      if (_note.text != next.note) _note.text = next.note;
    });
  }

  /// The form, once the weigh-ins and the unit setting have loaded (local,
  /// so at once in practice).
  WeighInFormState? _formOf(
    AsyncValue<List<WeighIn>> weighIns,
    AsyncValue<UnitSystem> units,
  ) {
    if (_form != null) return _form;
    final list = weighIns.value;
    if (list == null || units.isLoading) return null;
    final edit = widget.edit;
    final form = edit != null
        ? WeighInFormState.edit(edit, weighIns: list)
        : WeighInFormState.log(
            weighIns: list,
            unit: (units.value ?? UnitSystem.defaultSystem).bodyMass,
            time: _initialTime(),
          );
    _note.text = form.note;
    _noteOpen = form.note.isNotEmpty;
    return _form = form;
  }

  /// Now, or the page's day at now's clock time (A14 PA3), never later
  /// than now.
  EntryTime _initialTime() {
    final clock = ref.read(clockProvider);
    final now = EntryTime.now(clock);
    final date = widget.date;
    if (date == null || !date.isBefore(now.localDate)) return now;
    final wall = now.localDateTime;
    return EntryTime.fromLocal(
      LocalDateTime(date, hour: wall.hour, minute: wall.minute),
      clock,
    );
  }

  void _update(WeighInFormState Function(WeighInFormState form) change) =>
      setState(() {
        _form = change(_form!);
        _failure = null;
      });

  Future<void> _pickWhen() async {
    final clock = ref.read(clockProvider);
    final today = EntryTime.now(clock).localDate;
    final current = _form!.time.localDateTime;
    final day = await showFbDatePicker(
      context,
      initialDate: DateTime(
        current.date.year,
        current.date.month,
        current.date.day,
      ),
      firstDate: DateTime(1970),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (day == null || !mounted) return;
    final time = await showFbTimePicker(
      context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (!mounted) return;
    final local = LocalDateTime(
      LocalDate(day.year, day.month, day.day),
      hour: time?.hour ?? current.hour,
      minute: time?.minute ?? current.minute,
    );
    _update((form) => form.withTime(EntryTime.fromLocal(local, clock)));
  }

  /// Save, from the pinned button or the confirmation's answers (which
  /// ignore taps for [_confirmGuard] after it appears).
  Future<void> _save({bool confirm = false, bool otherUnit = false}) async {
    if (_saving || _form == null) return;
    // A Save that reaches an open confirmation answers it: guarded too.
    if ((confirm || _form!.confirming != null) && !_confirmArmed) return;
    final now = ref.read(clockProvider).nowUtc();
    final (next, submission) = confirm
        ? _form!.confirm(otherUnit: otherUnit)
        : _form!.save(now);
    setState(() {
      // The confirmation shows in place of the pad, its answers in place of
      // the pinned actions.
      if (next.confirming != null && _form!.confirming == null) {
        _padOpen = false;
        _noteFocus.unfocus();
        _armConfirm();
      }
      _form = next;
      _failure = null;
    });
    if (submission == null) return;
    final host = Navigator.of(context, rootNavigator: true).context;
    final nav = Navigator.of(context);
    final actions = ref.read(weighInActionsProvider.notifier);
    final today = EntryTime.now(ref.read(clockProvider)).localDate;
    setState(() => _saving = true);
    final editing = submission.editing;
    final outcome = editing == null
        ? await actions.log(submission.draft, trend: submission.trend)
        : await actions.update(
            editing,
            submission.draft,
            trend: submission.trend,
          );
    if (mounted) setState(() => _saving = false);
    switch (outcome) {
      case WeighInDone(:final undoId, :final kind):
        if (mounted) nav.pop();
        if (host.mounted) {
          final l10n = host.l10n;
          final weight = weighInInputText(l10n, submission.draft.input);
          final message = switch (kind) {
            WeighInKind.weighInLogged ||
            WeighInKind.weighInsLogged => withDayClause(
              host,
              l10n.weighInSaved(weight),
              submission.draft.localDate,
              today,
            ),
            WeighInKind.weighInTrendChosen => l10n.weighInTrendChosen,
            WeighInKind.weighInDeleted => l10n.weighInDeleted,
            WeighInKind.weighInUpdated => l10n.weighInUpdated(weight),
          };
          showUndoFeedback(host, message: message, undoEntryId: undoId);
        }
      case WeighInUnchanged():
        if (mounted) nav.pop();
      case WeighInPending():
        // The first Save is still running; its outcome decides.
        break;
      case WeighInFailed(:final reason):
        if (mounted) setState(() => _failure = reason);
    }
  }

  Future<void> _delete(WeighIn weighIn) async {
    if (_saving) return;
    final host = Navigator.of(context, rootNavigator: true).context;
    final nav = Navigator.of(context);
    setState(() {
      _saving = true;
      _failure = null;
    });
    final outcome = await ref
        .read(weighInActionsProvider.notifier)
        .delete(weighIn);
    if (mounted) setState(() => _saving = false);
    switch (outcome) {
      case WeighInDone(:final undoId):
        if (mounted) nav.pop();
        if (host.mounted) {
          showUndoFeedback(
            host,
            message: host.l10n.weighInDeleted,
            undoEntryId: undoId,
          );
        }
      case WeighInFailed(:final reason):
        if (mounted) setState(() => _failure = reason);
      case WeighInUnchanged() || WeighInPending():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final weighIns = ref.watch(weighInsProvider);
    final units = ref.watch(unitSystemProvider);
    ref.listen(weighInsProvider, (_, next) {
      if (next.value case final list? when _form != null) {
        setState(() => _form = _form!.withWeighIns(list));
      }
    });
    final form = _formOf(weighIns, units);
    final edit = widget.edit;
    final pending = ref.watch(
      weighInActionsProvider.select(
        (keys) => keys.contains(edit?.id ?? WeighInActions.logKey),
      ),
    );
    final busy = _saving || pending;
    final issue = form?.issueAt(ref.read(clockProvider).nowUtc());
    final canSave = form != null && issue == null && !busy;
    // After a Reload the form edits the weigh-in at its new version.
    final editing = form?.editing ?? edit;
    final asked = form?.confirming;
    return Padding(
      // Lifts the sheet above the keyboard (the note field).
      padding: EdgeInsetsDirectional.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: FbSheet(
        title: edit == null ? l10n.weighInSheetTitle : l10n.weighInEditTitle,
        actions: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FbSpace.s2,
          children: form != null && asked != null && asked is! Plausible
              ? _answers(context, form, asked, busy: busy)
              : [
                  FbButton.primary(
                    label: l10n.weighInSave,
                    expand: true,
                    onPressed: canSave ? () => unawaited(_save()) : null,
                  ),
                  if (editing != null)
                    FbButton.text(
                      label: l10n.weighInDelete,
                      icon: FbIcons.delete,
                      expand: true,
                      onPressed: busy
                          ? null
                          : () => unawaited(_delete(editing)),
                    ),
                ],
        ),
        child: form == null
            ? weighIns.hasError
                  ? FbInlineBanner(
                      kind: FbInlineBannerKind.error,
                      message: l10n.weighInLoadFailed,
                      actionLabel: l10n.weighInTryAgain,
                      onAction: () => ref.invalidate(weighInsProvider),
                    )
                  : const FbSkeleton.card()
            : _content(context, form, issue),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    WeighInFormState form,
    WeighInFormIssue? issue,
  ) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final muted = FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant);
    final unit = weightUnitLabel(l10n, form.unit);
    final typed = weightTyped(l10n, form.buffer);
    final today = EntryTime.now(ref.read(clockProvider)).localDate;
    final used = form.usedForTrendNow;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        if (_failure case final failure?)
          FbInlineBanner(
            kind:
                failure == WeighInFailure.changed ||
                    failure == WeighInFailure.removed
                ? FbInlineBannerKind.info
                : FbInlineBannerKind.error,
            message: switch (failure) {
              // Logging: the day's other weigh-ins changed; the form already
              // has them, so saving again works.
              WeighInFailure.changed when !form.isEdit =>
                l10n.weighInDayChanged,
              WeighInFailure.changed => l10n.weighInChanged,
              WeighInFailure.removed => l10n.weighInRemoved,
              WeighInFailure.future => l10n.weighInFuture,
              WeighInFailure.invalid => l10n.weighInSaveFailed,
            },
            actionLabel: failure == WeighInFailure.changed && form.isEdit
                ? l10n.weighInReload
                : null,
            onAction: failure == WeighInFailure.changed && form.isEdit
                ? _reload
                : null,
          ),
        FbAmountDisplay(
          amount: typed,
          unit: unit,
          semanticLabel: l10n.weighInValueSemantics(
            l10n.weightValue(typed, unit),
          ),
          active: _padOpen,
          onTap: _togglePad,
        ),
        FbUnitPicker(
          units: [
            for (final u in WeighInInput.units)
              FbUnitOption(id: u.code, label: weightUnitLabel(l10n, u)),
          ],
          selected: form.unit.code,
          onSelected: (code) =>
              _update((f) => f.withUnit(MassUnit.fromCode(code)!)),
        ),
        Wrap(
          spacing: FbSpace.s2,
          runSpacing: FbSpace.s2,
          children: [
            FbChoiceChip(
              label: l10n.weighInWhenLabel,
              value: l10n.weighInDayTime(
                dayLabel(context, form.date, today),
                _timeText(context, form.time.localDateTime),
              ),
              icon: FbIcons.calendar,
              onTap: () => unawaited(_pickWhen()),
            ),
            if (!_noteOpen)
              FbChoiceChip(
                label: l10n.weighInAddNote,
                icon: FbIcons.add,
                dropdown: false,
                onTap: () => setState(() => _noteOpen = true),
              ),
          ],
        ),
        if (_noteOpen)
          FbTextField(
            controller: _note,
            focusNode: _noteFocus,
            label: l10n.weighInNoteLabel,
            hint: l10n.weighInNoteHint,
            maxLength: WeighInBounds.noteMax,
            autofocus: form.note.isEmpty,
            textInputAction: TextInputAction.done,
            errorText: switch (issue) {
              WeighInFormIssue.noteTooLong => l10n.weighInNoteTooLong(
                WeighInBounds.noteMax,
              ),
              WeighInFormIssue.noteInvalid => l10n.weighInNoteInvalid,
              _ => null,
            },
            onChanged: (text) => _update((f) => f.withNote(text)),
          ),
        for (final other in form.sameDay)
          Text(
            (other.id == used?.id
                ? l10n.weighInSameDayUsed
                : l10n.weighInSameDay)(
              weighInInputText(l10n, other.input),
              _timeText(context, other.time.localDateTime),
            ),
            style: muted,
          ),
        if (form.showTrendSwitch)
          FbSwitchRow(
            title: l10n.weighInUseForTrend,
            value: form.forTrend,
            onChanged: (on) => _update((f) => f.withUseForTrend(on: on)),
          ),
        if (form.confirming case final asked?)
          if (_confirmationMessage(context, form, asked, today)
              case final message?)
            FbInlineBanner(kind: FbInlineBannerKind.info, message: message),
        if (_hint(l10n, form, issue) case final hint?) Text(hint, style: muted),
        if (_padOpen)
          FbNumberPad(
            onKey: (key) => _update((f) => f.key(key)),
            // Done closes the pad (like the diary's amount sheets); Save
            // stays pinned below.
            onDone: () => setState(() => _padOpen = false),
          ),
      ],
    );
  }

  /// The in-sheet confirmation's message for an unusual value (WB-005,
  /// UX-022), or `null`. Factual, no judgement; its answers replace the
  /// pinned actions ([_answers]).
  String? _confirmationMessage(
    BuildContext context,
    WeighInFormState form,
    WeighInCheckResult asked,
    LocalDate today,
  ) {
    final l10n = context.l10n;
    return switch (asked) {
      LikelyOtherUnit(:final suggestedUnit, :final suggestedKg) =>
        l10n.weighInConfirmUnit(
          weighInInputText(l10n, WeighInInput(form.value ?? 0, suggestedUnit)),
          weightText(l10n, suggestedKg, form.unit),
        ),
      LargeChange(:final reference, :final diffKg) => l10n.weighInConfirmChange(
        weightDiffText(l10n, diffKg, form.unit),
        dayLabelInline(context, reference.localDate, today),
        weightText(l10n, reference.kg, form.unit),
      ),
      Plausible() => null,
    };
  }

  /// The confirmation's two answers, pinned where Save and Delete were:
  /// "Save 100.0 kg" / "Edit" for a large change, "Save as 214.0 lb" /
  /// "Keep kg" for a likely unit mix-up. The saving answers ignore taps for
  /// [_confirmGuard] after the confirmation appears.
  List<Widget> _answers(
    BuildContext context,
    WeighInFormState form,
    WeighInCheckResult asked, {
    required bool busy,
  }) {
    final l10n = context.l10n;
    switch (asked) {
      case LikelyOtherUnit(:final suggestedUnit):
        return [
          FbButton.primary(
            label: l10n.weighInSaveAsUnit(
              weighInInputText(
                l10n,
                WeighInInput(form.value ?? 0, suggestedUnit),
              ),
            ),
            expand: true,
            onPressed: busy
                ? null
                : () => unawaited(_save(confirm: true, otherUnit: true)),
          ),
          FbButton.text(
            label: l10n.weighInKeepUnit(weightUnitLabel(l10n, form.unit)),
            expand: true,
            onPressed: busy ? null : () => unawaited(_save(confirm: true)),
          ),
        ];
      case LargeChange():
        final typed = form.input;
        return [
          FbButton.primary(
            label: typed == null
                ? l10n.weighInSave
                : l10n.weighInConfirmSaveValue(weighInInputText(l10n, typed)),
            expand: true,
            onPressed: busy ? null : () => unawaited(_save(confirm: true)),
          ),
          FbButton.text(
            label: l10n.weighInConfirmEdit,
            expand: true,
            onPressed: busy
                ? null
                : () => setState(() {
                    _form = form.backToPad();
                    _padOpen = true;
                  }),
          ),
        ];
      case Plausible():
        return const [];
    }
  }

  /// Why Save is off, when the user can act on it (the note's own issues
  /// show under the field).
  String? _hint(
    AppLocalizations l10n,
    WeighInFormState form,
    WeighInFormIssue? issue,
  ) => switch (issue) {
    // Only once more digits can't fix it (A14 m2); the bounds as whole
    // numbers inside the range ("20 kg", "1,102 lb").
    WeighInFormIssue.outOfRange when form.showRangeHint =>
      l10n.weighInOutOfRange(
        weightWholeText(l10n, WeighInBounds.minIn(form.unit).ceil(), form.unit),
        weightWholeText(
          l10n,
          WeighInBounds.maxIn(form.unit).floor(),
          form.unit,
        ),
      ),
    WeighInFormIssue.future => l10n.weighInFuture,
    WeighInFormIssue.tooEarly => l10n.weighInTooEarly,
    _ => null,
  };
}

/// A clock time in the device's 12 or 24 hour format.
String _timeText(BuildContext context, LocalDateTime time) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: time.hour, minute: time.minute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
