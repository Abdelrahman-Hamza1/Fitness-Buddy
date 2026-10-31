import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/diary/application/slot_actions.dart';
import 'package:fb_mobile/features/diary/application/slot_providers.dart';
import 'package:fb_mobile/features/diary/presentation/slots/slot_remove_sheet.dart';
import 'package:fb_mobile/features/diary/presentation/slots/slot_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the sheet that edits [record], or adds a meal when it is null
/// (DY-010, A10 D13). The undo snackbar for a saved change shows on the root
/// messenger, so it outlives the sheet.
/// A new meal joins [mode]'s set (DY-012: the Ramadan set is separate).
Future<void> showSlotEditSheet(
  BuildContext context, {
  SlotRecord? record,
  SlotMode mode = SlotMode.normal,
}) => showFbStatefulSheet<void>(
  context,
  builder: (_) => SlotEditSheet(record: record, mode: mode),
);

/// The edit and add sheet of a meal: name, an optional time window, Save and
/// (for an existing meal) Remove, pinned under the form so they stay
/// reachable at any text size. It follows its meal like every edit sheet
/// (A10 D12): a removed meal disables Save, a changed one offers Reload and
/// keeps what was typed (a field the user hasn't touched takes the new
/// value).
class SlotEditSheet extends ConsumerStatefulWidget {
  /// Creates the sheet for [record], or for a new meal.
  const new({this.record, this.mode = SlotMode.normal, super.key});

  /// The meal as rendered when the sheet opened; null to add one.
  final SlotRecord? record;

  /// The set a new meal joins (an existing meal keeps its own).
  final SlotMode mode;

  /// The set this sheet edits.
  SlotMode get setMode => record?.slot.mode ?? mode;

  @override
  ConsumerState<SlotEditSheet> createState() => _SlotEditSheetState();
}

class _SlotEditSheetState extends ConsumerState<SlotEditSheet> {
  late final TextEditingController _name = TextEditingController();
  late SlotRecord? _opened = widget.record;

  /// "Set times" is on; [_from] and [_to] are minutes of the day.
  bool _timesOn = false;
  int _from = 0;
  int _to = 0;
  bool _initialised = false;
  bool _saving = false;
  String? _failure;

  bool get _adding => widget.record == null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Fills the form from the meal, once the context (labels) is available.
  void _initialise(BuildContext context) {
    if (_initialised) return;
    _initialised = true;
    final slot = _opened?.slot;
    if (slot != null) _name.text = slotLabel(context.l10n, slot);
    _adoptWindow(slot?.window);
  }

  void _adoptWindow(TimeWindow? window) {
    _timesOn = window != null;
    if (window != null) {
      _from = window.startMin;
      _to = window.endMin;
    }
  }

  String get _typed => MealSlotRules.normalizeName(_name.text);

  /// The window the form describes; null when off or empty .
  TimeWindow? get _window =>
      _timesOn && _from != _to ? TimeWindow(_from, _to) : null;

  bool get _sameTimes => _timesOn && _from == _to;

  String _openedLabel(BuildContext context) => _opened == null
      ? ''
      : MealSlotRules.normalizeName(slotLabel(context.l10n, _opened!.slot));

  bool _nameDirty(BuildContext context) =>
      _adding || _typed != _openedLabel(context);

  bool _windowDirty() =>
      _timesOn != (_opened?.slot.window != null) ||
      (_timesOn &&
          (_from != _opened?.slot.window?.startMin ||
              _to != _opened?.slot.window?.endMin));

  /// The own label of a built-in meal ("Breakfast"); null for a custom one.
  String? _defaultLabel(BuildContext context) {
    final slot = _opened?.slot;
    if (slot?.defaultKey == null) return null;
    return slotLabel(
      context.l10n,
      MealSlot(id: slot!.id, sortOrder: 0, defaultKey: slot.defaultKey),
    );
  }

  /// A name for the patch: null resets a built-in meal to its own label.
  String? _patchName(BuildContext context) {
    if (_typed.isEmpty) return null;
    final own = _defaultLabel(context);
    if (own != null && _typed.toLowerCase() == own.toLowerCase()) return null;
    return _typed;
  }

  bool _nameTaken(BuildContext context, List<SlotRecord> active) {
    final typed = (_typed.isEmpty ? _defaultLabel(context) ?? '' : _typed)
        .toLowerCase();
    if (typed.isEmpty) return false;
    return active.any(
      (r) =>
          r.slot.id != _opened?.slot.id &&
          MealSlotRules.normalizeName(slotLabel(context.l10n, r.slot))
                  .toLowerCase() ==
              typed,
    );
  }

  bool _nameValid() {
    if (_adding) return MealSlotRules.validName(_typed);
    // A built-in meal may be emptied (it goes back to its own label).
    if (_typed.isEmpty) return _opened!.slot.defaultKey != null;
    return MealSlotRules.validName(_typed);
  }

  Future<void> _pickTime({required bool from}) async {
    final minute = from ? _from : _to;
    final picked = await showFbTimePicker(
      context,
      initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
    );
    if (picked == null || !mounted) return;
    setState(() {
      final value = picked.hour * 60 + picked.minute;
      if (from) {
        _from = value;
      } else {
        _to = value;
      }
      _failure = null;
    });
  }

  void _setTimes({required bool on}) {
    setState(() {
      _failure = null;
      if (on && _from == _to) {
        final now = EntryTime.now(ref.read(clockProvider)).localDateTime.time;
        final window = windowAround(now);
        _from = window.startMin;
        _to = window.endMin;
      }
      _timesOn = on;
    });
  }

  /// Takes the stored meal as the new base: what the user changed stays, the
  /// rest follows the stored meal.
  void _reload(BuildContext context, SlotRecord stored) {
    final nameDirty = _nameDirty(context);
    final windowDirty = _windowDirty();
    setState(() {
      _opened = stored;
      _failure = null;
      if (!nameDirty) _name.text = slotLabel(context.l10n, stored.slot);
      if (!windowDirty) _adoptWindow(stored.slot.window);
    });
  }

  Future<void> _save(BuildContext context) async {
    if (_saving) return;
    final host = Navigator.of(context, rootNavigator: true).context;
    final nav = Navigator.of(context);
    final actions = ref.read(slotActionsProvider.notifier);
    final l10n = context.l10n;
    final window = _window;
    final SlotOutcome outcome;
    final String label;
    setState(() {
      _saving = true;
      _failure = null;
    });
    if (_adding) {
      label = _typed;
      outcome = await actions.addSlot(
        _typed,
        window: window,
        mode: widget.setMode,
      );
    } else {
      final nameDirty = _nameDirty(context);
      final patchName = nameDirty ? _patchName(context) : null;
      final windowDirty = _windowDirty();
      label = nameDirty
          ? (patchName ?? _defaultLabel(context) ?? _typed)
          : slotLabel(l10n, _opened!.slot);
      outcome = await actions.updateSlot(
        _opened!,
        MealSlotPatch(
          setName: nameDirty,
          name: patchName,
          setWindow: windowDirty,
          window: windowDirty ? window : null,
        ),
      );
    }
    if (mounted) setState(() => _saving = false);
    switch (outcome) {
      case SlotDone(:final undoEntryId):
        if (mounted) nav.pop();
        if (host.mounted) {
          showUndoFeedback(
            host,
            message: _adding
                ? host.l10n.slotAddedMessage(label)
                : host.l10n.slotUpdatedMessage(label),
            undoEntryId: undoEntryId,
          );
        }
      case SlotUnchanged():
        if (mounted) nav.pop();
      case SlotFailed(:final reason, :final code):
        if (!mounted) return;
        setState(
          () => _failure = switch ((reason, code)) {
            (SlotFailure.changed, _) => l10n.slotSaveChanged,
            (SlotFailure.removed, _) => l10n.slotStaleRemoved,
            (_, 'tooManySlots') => l10n.mealTimesAddLimit(
              MealSlotRules.maxActive,
            ),
            (_, 'nameInvalid') => l10n.slotNameInvalid,
            _ => l10n.diaryActionFailed,
          },
        );
    }
  }

  Future<void> _remove(BuildContext context, SlotRecord live) async {
    final nav = Navigator.of(context);
    final removed = await showSlotRemoveSheet(context, live);
    if (removed ?? false) {
      if (mounted) nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    _initialise(context);
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final recordsAsync = ref.watch(slotRecordsProvider(widget.setMode));
    final records = recordsAsync.value ?? const [];
    final active = [
      for (final r in records)
        if (r.slot.active) r,
    ];
    final stored = _adding
        ? null
        : records.where((r) => r.slot.id == _opened!.slot.id).firstOrNull;
    final removed =
        !_adding &&
        recordsAsync.hasValue &&
        (stored == null || !stored.slot.active);
    final changed = stored != null && stored.version != _opened!.version;
    final pending = ref.watch(
      slotActionsProvider.select(
        (s) => !_adding && s.contains(_opened!.slot.id),
      ),
    );
    final atLimit = _adding && active.length >= MealSlotRules.maxActive;
    final taken = _nameTaken(context, active);
    final dirty = _adding || _nameDirty(context) || _windowDirty();
    final canSave =
        recordsAsync.hasValue &&
        !removed &&
        !atLimit &&
        !_saving &&
        !pending &&
        dirty &&
        _nameValid() &&
        !taken &&
        !_sameTimes;
    final isLast = active.length <= 1;
    final defaultLabel = _defaultLabel(context);
    return Padding(
      // Lifts the sheet above the keyboard.
      padding: EdgeInsetsDirectional.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: FbSheet(
        title: _adding ? l10n.slotAddTitle : l10n.slotEditTitle,
        actions: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FbSpace.s2,
          children: [
            FbButton.primary(
              label: _adding ? l10n.slotAddButton : l10n.slotSave,
              expand: true,
              onPressed: canSave ? () => unawaited(_save(context)) : null,
            ),
            if (!_adding)
              FbButton.text(
                label: l10n.slotRemoveAction,
                expand: true,
                onPressed: removed || isLast || _saving || pending
                    ? null
                    : () => unawaited(_remove(context, stored!)),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FbSpace.s3,
          children: [
            if (recordsAsync.hasError)
              FbInlineBanner(
                kind: FbInlineBannerKind.error,
                message: l10n.mealTimesLoadFailed,
                actionLabel: l10n.mealTimesTryAgain,
                onAction: () =>
                    ref.invalidate(slotRecordsProvider(widget.setMode)),
              ),
            if (removed)
              FbInlineBanner(
                kind: FbInlineBannerKind.info,
                message: l10n.slotStaleRemoved,
              )
            else if (changed)
              FbInlineBanner(
                kind: FbInlineBannerKind.info,
                message: l10n.slotStaleChanged,
                actionLabel: l10n.diaryReload,
                onAction: () => _reload(context, stored),
              ),
            if (atLimit)
              Text(
                l10n.mealTimesAddLimit(MealSlotRules.maxActive),
                style: FbType.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            FbTextField(
              controller: _name,
              label: l10n.slotNameLabel,
              hint: defaultLabel == null
                  ? null
                  : l10n.slotNameHintDefault(defaultLabel),
              maxLength: MealSlotRules.nameMax,
              autofocus: _adding,
              enabled: !removed && !_saving && !pending,
              textInputAction: TextInputAction.done,
              errorText: taken ? l10n.slotNameTaken : null,
              onChanged: (_) => setState(() => _failure = null),
            ),
            FbSwitchRow(
              title: l10n.slotSetTimes,
              subtitle: l10n.slotSetTimesHint,
              value: _timesOn,
              onChanged: removed || _saving || pending
                  ? null
                  : (on) => _setTimes(on: on),
            ),
            if (_timesOn)
              Wrap(
                spacing: FbSpace.s2,
                runSpacing: FbSpace.s2,
                children: [
                  FbChoiceChip(
                    label: l10n.slotFrom,
                    value: minuteText(context, _from),
                    onTap: removed || _saving || pending
                        ? null
                        : () => _pickTime(from: true),
                  ),
                  FbChoiceChip(
                    label: l10n.slotTo,
                    value: minuteText(context, _to),
                    onTap: removed || _saving || pending
                        ? null
                        : () => _pickTime(from: false),
                  ),
                ],
              ),
            if (_sameTimes)
              FbInlineBanner(
                kind: FbInlineBannerKind.error,
                message: l10n.slotTimesSame,
              ),
            if (!_adding && isLast)
              Text(
                l10n.slotKeepOne,
                style: FbType.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            if (_failure != null)
              FbInlineBanner(
                kind: FbInlineBannerKind.error,
                message: _failure!,
              ),
          ],
        ),
      ),
    );
  }
}
