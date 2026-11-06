import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/ui/success_haptic.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/diary/application/diary_actions.dart';
import 'package:fb_mobile/features/diary/application/slot_providers.dart';
import 'package:fb_mobile/features/diary/presentation/entry_actions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

/// Opens the meal-estimate sheet (DY-005, A62 E1): one calorie number, an
/// optional name and optional protein, carbs and fat. With [entry] it edits
/// that estimate (prefilled); otherwise it adds one on [date] (null: today)
/// in [slotId] (null: by the time of day), named [name] when given (the
/// search query, E1 B; never in a URL).
Future<void> showEstimateSheet(
  BuildContext context, {
  LocalDate? date,
  String? slotId,
  String? name,
  DiaryEntry? entry,
}) => showFbStatefulSheet<void>(
  context,
  builder: (_) => EstimateSheet(
    date: date,
    slotId: slotId ?? entry?.slotId,
    name: name,
    entry: entry,
  ),
);

/// The "~ Your estimate" popup (AI-032, A62 D16): the only place an own
/// estimate is explained. Edit opens the sheet prefilled; Swap for foods
/// opens the search in change-food mode, so the estimate stays until a food
/// is picked (one change set, one Undo).
Future<void> showEstimatePopup(BuildContext context, DiaryEntry entry) =>
    showFbSheet<void>(
      context,
      title: context.l10n.estimatePopupTitle,
      builder: (sheet) => Consumer(
        builder: (context, ref, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FbSpace.s2,
          children: [
            FbButton.secondary(
              key: const ValueKey('estimate-popup-edit'),
              label: context.l10n.estimateEdit,
              icon: FbIcons.edit,
              expand: true,
              onPressed: () {
                final host = Navigator.of(context, rootNavigator: true).context;
                Navigator.of(sheet).pop();
                unawaited(showEstimateSheet(host, entry: entry));
              },
            ),
            FbButton.secondary(
              key: const ValueKey('estimate-popup-swap'),
              label: context.l10n.estimateSwap,
              icon: FbIcons.search,
              expand: true,
              onPressed: () {
                Navigator.of(sheet).pop();
                changeFoodOf(ref, entry);
              },
            ),
          ],
        ),
      ),
    );

/// The body of the estimate sheet.
class EstimateSheet extends ConsumerStatefulWidget {
  /// Adds on [date] in [slotId] named [name], or edits [entry].
  const new({this.date, this.slotId, this.name, this.entry, super.key});

  /// The diary day to add to; null for today.
  final LocalDate? date;

  /// The meal; null to choose by the time of day.
  final String? slotId;

  /// The prefilled name (the search query). User content.
  final String? name;

  /// The estimate being edited, at the version shown.
  final DiaryEntry? entry;

  @override
  ConsumerState<EstimateSheet> createState() => _EstimateSheetState();
}

class _EstimateSheetState extends ConsumerState<EstimateSheet> {
  late final UserEstimate? _prefill = widget.entry == null
      ? null
      : UserEstimate.of(widget.entry!.food);
  late NumberPadBuffer _kcal = NumberPadBuffer(
    maxDigits: 5,
    maxDecimals: 0,
    text: _prefill == null ? '' : '${_prefill.kcal.round()}',
  );
  late final _name = TextEditingController(
    text: _prefill?.name ?? _clip(widget.name),
  );
  late final _protein = TextEditingController(
    text: _gramsText(_prefill?.protein),
  );
  late final _carbs = TextEditingController(text: _gramsText(_prefill?.carbs));
  late final _fat = TextEditingController(text: _gramsText(_prefill?.fat));
  late bool _macrosOpen =
      _prefill != null &&
      (_prefill.protein != null ||
          _prefill.carbs != null ||
          _prefill.fat != null);
  bool _padOpen = true;
  bool _saving = false;
  DiaryActionFailure? _failure;

  @override
  void dispose() {
    for (final c in [_name, _protein, _carbs, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  static String _clip(String? name) {
    final trimmed = name?.trim() ?? '';
    final chars = trimmed.characters;
    return chars.length <= UserEstimate.maxNameLength
        ? trimmed
        : chars.take(UserEstimate.maxNameLength).toString();
  }

  static String _gramsText(double? grams) {
    if (grams == null) return '';
    final rounded = (grams * 10).round() / 10;
    return rounded == rounded.truncateToDouble()
        ? '${rounded.toInt()}'
        : '$rounded';
  }

  /// A macro field: null when empty (not given), NaN when unreadable.
  static double? _macro(TextEditingController c) {
    final text = c.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.')) ?? double.nan;
  }

  UserEstimate? get _draft {
    final kcal = _kcal.value;
    if (kcal == null) return null;
    return UserEstimate(
      kcal: kcal,
      name: _name.text,
      protein: _macrosOpen ? _macro(_protein) : _prefill?.protein,
      carbs: _macrosOpen ? _macro(_carbs) : _prefill?.carbs,
      fat: _macrosOpen ? _macro(_fat) : _prefill?.fat,
    );
  }

  Future<void> _submit(UserEstimate estimate) async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final nav = Navigator.of(context);
    final actions = ref.read(diaryActionsControllerProvider.notifier);
    setState(() {
      _saving = true;
      _failure = null;
    });
    final entry = widget.entry;
    final outcome = entry == null
        ? await actions.logEstimate(
            estimate,
            date:
                widget.date ?? EntryTime.now(ref.read(clockProvider)).localDate,
            slotId: widget.slotId,
          )
        : await actions.editEstimate(entry, estimate);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (outcome) {
      case DiaryActionFailed(:final reason):
        setState(() => _failure = reason);
      case DiaryActionUnchanged():
        nav.pop();
      case DiaryActionDone(:final undoEntryId):
        nav.pop();
        successHaptic();
        if (host.mounted) {
          showUndoFeedback(
            host,
            message: entry == null
                ? host.l10n.estimateAdded(_kcalText(host.l10n, estimate.kcal))
                : host.l10n.estimateChanged,
            undoEntryId: undoEntryId,
          );
        }
    }
  }

  static String _kcalText(AppLocalizations l10n, double kcal) =>
      NumberFormat.decimalPattern(l10n.localeName).format(kcal.round());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final slots = ref.watch(liveSlotsProvider).value ?? const <MealSlot>[];
    final slot = slots.where((s) => s.id == widget.slotId).firstOrNull;
    final draft = _draft;
    final problem = draft?.check();
    final kcalShown = _kcal.isEmpty ? '0' : _kcalText(l10n, _kcal.value!);
    final canSave = draft != null && problem == null && !_saving;
    final muted = FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant);
    // The reserved line under the fields (UX-045): never moves the button.
    final message = switch ((draft, problem, _failure)) {
      (null, _, _) => l10n.estimateKcalNeeded,
      (_, final _?, _) => l10n.estimateOutOfRange,
      (_, _, DiaryActionFailure.slotRemoved) => l10n.diarySlotRemoved,
      (_, _, DiaryActionFailure.changed) => l10n.diaryItemChanged,
      (_, _, DiaryActionFailure.removed) => l10n.diaryActionRemoved,
      (_, _, DiaryActionFailure.invalid) => l10n.diaryActionFailed,
      _ => '',
    };
    final error = problem != null || _failure != null;
    return FbSheet(
      title: slot == null
          ? l10n.estimateSheetTitleNoMeal
          : l10n.estimateSheetTitle(slotLabel(l10n, slot)),
      actions: FbButton.primary(
        key: const ValueKey('estimate-submit'),
        label: widget.entry == null
            ? l10n.estimateAdd(kcalShown)
            : l10n.estimateSave(kcalShown),
        expand: true,
        busy: _saving,
        onPressed: canSave ? () => _submit(draft) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s3,
        children: [
          FbAmountDisplay(
            key: const ValueKey('estimate-kcal'),
            amount: kcalShown,
            unit: l10n.diaryUnitKcal,
            semanticLabel: l10n.estimateKcalLabel(kcalShown),
            active: _padOpen,
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() => _padOpen = !_padOpen);
            },
            onKey: _onKey,
          ),
          if (_padOpen)
            FbNumberPad(
              onKey: _onKey,
              onDone: () => setState(() => _padOpen = false),
              allowDecimal: false,
            ),
          Focus(
            onFocusChange: (focused) {
              if (focused) setState(() => _padOpen = false);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: FbSpace.s3,
              children: [
                FbTextField(
                  key: const ValueKey('estimate-name'),
                  controller: _name,
                  label: l10n.estimateName,
                  maxLength: UserEstimate.maxNameLength,
                  onChanged: (_) => setState(() {}),
                ),
                if (!_macrosOpen)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FbButton.text(
                      key: const ValueKey('estimate-macros'),
                      label: l10n.estimateMacros,
                      onPressed: () => setState(() => _macrosOpen = true),
                    ),
                  ),
                FbReveal(
                  visible: _macrosOpen,
                  child: Row(
                    spacing: FbSpace.s2,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (key, controller, field) in [
                        ('estimate-protein', _protein, NutrientField.protein),
                        ('estimate-carbs', _carbs, NutrientField.carbs),
                        ('estimate-fat', _fat, NutrientField.fat),
                      ])
                        Expanded(
                          child: FbNumberField(
                            key: ValueKey(key),
                            controller: controller,
                            label: nutrientLabel(l10n, field),
                            unit: l10n.unitG,
                            maxDecimals: 1,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(
            message,
            key: const ValueKey('estimate-message'),
            maxLines: 2,
            style: error
                ? FbType.bodySmall.copyWith(color: scheme.error)
                : muted,
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
