import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/foods/application/barcode_providers.dart';
import 'package:fb_mobile/features/foods/application/food_choice.dart';
import 'package:fb_mobile/features/foods/application/food_search_row.dart';
import 'package:fb_mobile/features/foods/application/foods_providers.dart';
import 'package:fb_mobile/features/foods/application/personal_food_actions.dart';
import 'package:fb_mobile/features/foods/application/personal_food_form.dart';
import 'package:fb_mobile/features/foods/presentation/food_sheet_entry.dart';
import 'package:fb_mobile/features/foods/presentation/personal_foods/discard_changes_sheet.dart';
import 'package:fb_mobile/features/foods/presentation/personal_foods/merge_food_sheet.dart';
import 'package:fb_mobile/features/foods/presentation/personal_foods/personal_food_form_sections.dart';
import 'package:fb_mobile/features/foods/presentation/personal_foods/personal_food_inputs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Where the food sheet opens once a food made from a search is saved (A09
/// D9): the search's day and meal.
typedef FoodAddTarget = ({LocalDate? date, String? slotId});

enum _MenuAction { merge, delete }

/// The form to create or edit one personal food (FD-070, FD-012, A09 D7).
/// First the name, what the label's numbers are for (100 g, 100 ml or one
/// serving) and the five numbers, with a calm warning under them when the
/// calories don't match the macros (the food still saves). Then "More
/// nutrients" and a collapsed "More details": Arabic name, other names,
/// brand, state, servings and barcodes. "More details" opens by itself for
/// a food that has any of them, or when a field in it needs a look.
///
/// With [id] it edits that food and watches it: deleted means Save is off,
/// changed offers Reload, which keeps what was typed. With [addTo] it came
/// from a search ("Create … as your own food"): after Save the form closes
/// and the food sheet opens for the new food on that day and meal.
///
/// Each form has its own view model ([PersonalFoodFormKey]), so a draft in
/// one tab never shows up in a new form opened in another.
class PersonalFoodFormScreen extends ConsumerStatefulWidget {
  /// Creates the form; [id] is null for a new food.
  const new({this.id, this.addTo, this.fromScan = false, super.key});

  /// The food to edit; null for a new one.
  final String? id;

  /// Set when the form was opened from the add-food search or the scanner.
  final FoodAddTarget? addTo;

  /// Opened from the barcode scanner: prefilled from the scan (A28a D9).
  final bool fromScan;

  @override
  ConsumerState<PersonalFoodFormScreen> createState() =>
      _PersonalFoodFormScreenState();
}

class _PersonalFoodFormScreenState
    extends ConsumerState<PersonalFoodFormScreen> {
  final PersonalFoodInputs _inputs = PersonalFoodInputs();
  late final PersonalFoodFormKey _key = widget.fromScan && widget.id == null
      ? PersonalFoodFormKey.scan()
      : PersonalFoodFormKey(widget.id);
  bool _attempted = false;
  bool _leaving = false;
  bool _moreOpen = false;

  /// Whether "More details" is open; decided on the first data, then the
  /// user's.
  bool? _detailsOpen;

  /// Whether Calories takes the keyboard (a name came from a search);
  /// decided on the first data.
  bool? _focusKcal;

  /// Set synchronously by the first Save, so a second tap in the same frame
  /// does nothing.
  bool _saving = false;
  PersonalFoodFailure? _refusal;

  PersonalFoodFormControllerProvider get _provider =>
      personalFoodFormControllerProvider(_key);

  PersonalFoodFormController get _controller => ref.read(_provider.notifier);

  @override
  void dispose() {
    _inputs.dispose();
    super.dispose();
  }

  // The order the fields are shown in, to focus the first one with an error.
  static const List<PersonalFoodField> _fieldOrder = [
    PersonalFoodField.name,
    PersonalFoodField.servingSize,
    PersonalFoodField.kcal,
    PersonalFoodField.protein,
    PersonalFoodField.carbs,
    PersonalFoodField.fat,
    PersonalFoodField.fiber,
    PersonalFoodField.sugar,
    PersonalFoodField.saturatedFat,
    PersonalFoodField.transFat,
    PersonalFoodField.sodium,
    PersonalFoodField.cholesterol,
    PersonalFoodField.alcohol,
    PersonalFoodField.nameAr,
    PersonalFoodField.aliases,
    PersonalFoodField.brand,
    PersonalFoodField.servings,
    PersonalFoodField.barcodes,
  ];

  /// The fields under "More details".
  static const Set<PersonalFoodField> _detailFields = {
    PersonalFoodField.nameAr,
    PersonalFoodField.aliases,
    PersonalFoodField.brand,
    PersonalFoodField.servings,
    PersonalFoodField.barcodes,
  };

  /// Opens what hides a field with an error, then focuses the first one.
  void _focusFirstError(PersonalFoodFormState form) {
    final errors = form.validation.errors;
    final first = _fieldOrder.where(errors.containsKey).firstOrNull;
    final target = first ?? PersonalFoodField.kcal;
    final openMore =
        !_moreOpen && extraNutrients.any((e) => errors.containsKey(e.$1));
    final openDetails =
        _detailsOpen != true && _detailFields.any(errors.containsKey);
    if (openMore || openDetails) {
      setState(() {
        if (openMore) _moreOpen = true;
        if (openDetails) _detailsOpen = true;
      });
    }
    // The opened fields exist after the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (target == PersonalFoodField.servings) {
        final bad = form.validation.badServings;
        final rows = _inputs.servings;
        final row = bad.isEmpty || bad.first >= rows.length
            ? rows.firstOrNull
            : rows[bad.first];
        row?.focus.requestFocus();
      } else {
        _inputs.focus(target).requestFocus();
      }
    });
  }

  Future<void> _save(PersonalFoodFormState form) async {
    // A second activation before the first one's frame: ignore it.
    if (_saving) return;
    if (form.validation.errors.isNotEmpty) {
      setState(() {
        _attempted = true;
        _refusal = null;
      });
      _focusFirstError(form);
      return;
    }
    _saving = true;
    final host = Navigator.of(context, rootNavigator: true).context;
    final container = ProviderScope.containerOf(context);
    final navigator = ref.read(appNavigatorProvider);
    final l10n = context.l10n;
    final addTo = widget.addTo;
    setState(() => _refusal = null);
    final PersonalFoodOutcome outcome;
    try {
      outcome = await _controller.submit();
    } finally {
      _saving = false;
    }
    if (!mounted) return;
    switch (outcome) {
      case PersonalFoodDone(:final undoId, :final args, :final foodId):
        // Saved from the scanner: its waiting scan is done (review fix 3).
        if (widget.fromScan) {
          unawaited(
            ref
                .read(pendingScansProvider.notifier)
                .removeAll(form.validation.draft?.barcodes ?? const []),
          );
        }
        setState(() => _leaving = true);
        navigator.pop();
        final saved = l10n.personalFoodSavedMessage('${args['name']}');
        if (addTo != null && foodId != null && host.mounted) {
          // Creation Undo is skipped in this flow: the root food sheet
          // covers it, and delaying it would outlive the undo window.
          // Logging has its own reachable Undo after the sheet closes.
          unawaited(_openFoodSheet(host, container, foodId, addTo));
        } else if (host.mounted) {
          showUndoFeedback(host, message: saved, undoEntryId: undoId);
        }
      case PersonalFoodUnchanged():
        // Nothing differs from the stored food: just leave.
        if (form.original != null) {
          setState(() => _leaving = true);
          navigator.pop();
        }
      case PersonalFoodPending():
        // The first Save is still running; its outcome decides.
        break;
      case PersonalFoodFailed(:final reason):
        setState(() => _refusal = reason);
    }
  }

  /// The new food is saved: the food sheet takes over on the search's day
  /// and meal, so it can be logged straight away (D9). Resolves to whether
  /// it was logged.
  Future<bool> _openFoodSheet(
    BuildContext host,
    ProviderContainer container,
    String foodId,
    FoodAddTarget target,
  ) async {
    final food = await container
        .read(personalFoodRepositoryProvider)
        .byId(foodId);
    if (food == null || !host.mounted) return false;
    return await openFoodSheet(
      host,
      FoodPick(
        row: FoodSearchRow(
          choice: personalChoice(food),
          tier: SourceTier.personal,
        ),
        date: target.date,
        slotId: target.slotId,
      ),
    );
  }

  Future<void> _openMenu(PersonalFood food) async {
    final l10n = context.l10n;
    final action = await showFbSheet<_MenuAction>(
      context,
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FbListRow(
            title: l10n.personalFoodMenuMerge,
            onTap: () => Navigator.of(sheet).pop(_MenuAction.merge),
          ),
          FbListRow(
            title: l10n.personalFoodMenuDelete,
            onTap: () => Navigator.of(sheet).pop(_MenuAction.delete),
          ),
        ],
      ),
    );
    if (action == null || !mounted) return;
    // Merging or deleting leaves the form: unsaved changes are asked about
    // first, as on Back.
    if (ref.read(_provider).value?.dirty ?? false) {
      final discard = await showDiscardChangesSheet(context);
      if (!discard || !mounted) return;
    }
    switch (action) {
      case _MenuAction.merge:
        await _merge(food);
      case _MenuAction.delete:
        await _delete(food);
    }
  }

  Future<void> _delete(PersonalFood food) async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final navigator = ref.read(appNavigatorProvider);
    final l10n = context.l10n;
    setState(() => _refusal = null);
    final outcome = await ref.read(personalFoodActionsProvider).delete(food);
    if (!mounted) return;
    switch (outcome) {
      case PersonalFoodDone(:final undoId, :final args):
        setState(() => _leaving = true);
        navigator.pop();
        if (host.mounted) {
          showUndoFeedback(
            host,
            message: l10n.personalFoodDeletedMessage('${args['name']}'),
            undoEntryId: undoId,
          );
        }
      case PersonalFoodUnchanged() || PersonalFoodPending():
        break;
      case PersonalFoodFailed(:final reason):
        setState(() => _refusal = reason);
    }
  }

  Future<void> _merge(PersonalFood food) async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final navigator = ref.read(appNavigatorProvider);
    final l10n = context.l10n;
    final done = await showMergeFoodSheet(context, food: food);
    if (done == null || !mounted) return;
    // Whichever food was kept, this form's food is now stale or gone.
    setState(() => _leaving = true);
    navigator.pop();
    if (host.mounted) {
      final merged = '${done.args['merged']}';
      final survivor = '${done.args['survivor']}';
      showUndoFeedback(
        host,
        // "Merged Labneh into Labneh" says nothing: name only the survivor.
        message: merged == survivor
            ? l10n.personalFoodsMergedSameName(survivor)
            : l10n.personalFoodsMergedMessage(merged, survivor),
        undoEntryId: done.undoId,
      );
    }
  }

  /// Asks whether to discard the unsaved edits; the guard (back) or the
  /// tab bar (re-tap, A45 D12) closes the form on true.
  Future<bool> _confirmDiscard() => showDiscardChangesSheet(context);

  void _reload() {
    _controller.reload();
    final form = ref.read(_provider).value;
    if (form != null) {
      setState(() {
        _inputs.resync(form);
        _refusal = null;
      });
    }
  }

  Future<void> _pickUnit({
    required String current,
    required Set<String> taken,
    required ValueChanged<String> onPicked,
  }) async {
    final l10n = context.l10n;
    final order = [
      ...servingUnitOrder.where(PersonalFoodBounds.units.contains),
      ...PersonalFoodBounds.units.difference(servingUnitOrder.toSet()),
    ];
    final picked = await showFbSheet<String>(
      context,
      title: l10n.personalFoodServingUnitTitle,
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final code in order)
            if (code == current || !taken.contains(code))
              FbListRow(
                title: unitLabel(l10n, code, 1),
                trailing: code == current ? const Icon(FbIcons.check) : null,
                onTap: () => Navigator.of(sheet).pop(code),
              ),
        ],
      ),
    );
    if (picked != null && mounted) onPicked(picked);
  }

  void _pushServings() => _controller.setServings(_inputs.servingInputs);

  void _addServing(PersonalFoodFormState form) {
    final taken = {for (final row in _inputs.servings) row.unit};
    final unit = servingUnitOrder.firstWhere(
      (code) => !taken.contains(code),
      orElse: () => servingUnitOrder.first,
    );
    setState(() => _inputs.addServing(unit));
    _pushServings();
    _inputs.servings.last.focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final async = ref.watch(_provider);
    final form = async.value;
    final dirty = form?.dirty ?? false;
    final editing = widget.id != null;
    final food = form?.original;
    final removed = form?.staleness == PersonalFoodStaleness.removed;
    return UnsavedEditsGuard(
      dirty: dirty && !_leaving,
      confirmDiscard: _confirmDiscard,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            editing ? l10n.personalFoodEditTitle : l10n.personalFoodNewTitle,
          ),
          actions: [
            if (food != null && !removed)
              FbIconButton(
                tooltip: l10n.personalFoodMenuTooltip,
                icon: FbIcons.more,
                onPressed: () => _openMenu(food),
              ),
          ],
        ),
        body: switch (async) {
          AsyncData(:final value) => _content(context, value),
          AsyncError() => Padding(
            padding: const EdgeInsetsDirectional.all(FbSpace.s4),
            child: FbInlineBanner(
              kind: FbInlineBannerKind.error,
              message: l10n.personalFoodLoadFailed,
              actionLabel: l10n.foodTryAgain,
              onAction: () => ref.invalidate(_provider),
            ),
          ),
          _ => const Padding(
            padding: EdgeInsetsDirectional.all(FbSpace.s4),
            child: Column(
              spacing: FbSpace.s3,
              children: [
                FbSkeleton.line(height: 56),
                FbSkeleton.line(height: 56),
              ],
            ),
          ),
        },
      ),
    );
  }

  Widget _content(BuildContext context, PersonalFoodFormState form) {
    final l10n = context.l10n;
    final deleted =
        form.staleness == PersonalFoodStaleness.removed &&
        form.original == null;
    if (deleted) {
      return Padding(
        padding: const EdgeInsetsDirectional.all(FbSpace.s4),
        child: FbInlineBanner(
          kind: FbInlineBannerKind.info,
          message: l10n.personalFoodDeletedBanner,
        ),
      );
    }
    _inputs.ensureServings(form);
    // Decided once, on the first data: an edited food with details shows
    // them; a name from a search sends the keyboard to Calories.
    final detailsOpen = _detailsOpen ??= form.hasDetails;
    final focusKcal = _focusKcal ??=
        widget.id == null && form.text(PersonalFoodField.name).isNotEmpty;
    final binding = PersonalFormBinding(
      form: form,
      inputs: _inputs,
      controller: _controller,
      attempted: _attempted,
    );
    final canSave =
        !form.submitting && form.staleness == PersonalFoodStaleness.current;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: FbSpace.s3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: FbSpace.s3,
              children: [
                if (form.staleness != PersonalFoodStaleness.current)
                  formPad(_staleBanner(l10n, form)),
                NameSection(
                  binding: binding,
                  autofocus: widget.id == null && !focusKcal,
                ),
                ValuesSection(
                  binding: binding,
                  autofocusKcal: focusKcal,
                  moreOpen: _moreOpen,
                  onToggleMore: () => setState(() => _moreOpen = !_moreOpen),
                  onPickServingUnit: () => _pickUnit(
                    current: form.servingUnit,
                    taken: const {},
                    onPicked: (code) => _controller.setMode(
                      PersonalFoodMode.perServing,
                      unit: code,
                    ),
                  ),
                  notes: _nutritionNotes(l10n, form),
                ),
                FbDisclosureRow(
                  title: l10n.personalFoodMoreDetails,
                  expanded: detailsOpen,
                  onToggle: () => setState(() => _detailsOpen = !detailsOpen),
                ),
                if (detailsOpen) ...[
                  OtherNamesSection(binding: binding),
                  StateSection(binding: binding),
                  ServingsSection(
                    binding: binding,
                    onAdd: () => _addServing(form),
                    onRemove: (index) {
                      setState(() => _inputs.removeServing(index));
                      _pushServings();
                    },
                    onPickUnit: (index) => _pickUnit(
                      current: _inputs.servings[index].unit,
                      taken: {for (final row in _inputs.servings) row.unit},
                      onPicked: (code) {
                        setState(() => _inputs.servings[index].unit = code);
                        _pushServings();
                      },
                    ),
                    onChanged: _pushServings,
                  ),
                  BarcodesSection(binding: binding),
                ],
                // A food saved from a barcode scan carries OFF data (ODbL).
                if (OffOrigin.decode(
                      form.original?.createdFrom ?? form.newCreatedFrom,
                    ) !=
                    null)
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: FbSpace.s4,
                      vertical: FbSpace.s2,
                    ),
                    child: Text(
                      l10n.personalFoodOffSource,
                      style: FbType.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        _bottom(l10n, form, canSave),
      ],
    );
  }

  Widget _staleBanner(AppLocalizations l10n, PersonalFoodFormState form) =>
      switch (form.staleness) {
        PersonalFoodStaleness.removed => FbInlineBanner(
          kind: FbInlineBannerKind.info,
          message: l10n.personalFoodDeletedBanner,
        ),
        PersonalFoodStaleness.changed => FbInlineBanner(
          kind: FbInlineBannerKind.info,
          message: l10n.personalFoodChangedBanner,
          actionLabel: l10n.personalFoodReload,
          onAction: _reload,
        ),
        PersonalFoodStaleness.current => const SizedBox.shrink(),
      };

  /// The calories-versus-macros note (FD-012) and the impossible-values
  /// note, once every number they depend on is acceptable.
  List<Widget> _nutritionNotes(
    AppLocalizations l10n,
    PersonalFoodFormState form,
  ) {
    const core = [
      PersonalFoodField.kcal,
      PersonalFoodField.protein,
      PersonalFoodField.carbs,
      PersonalFoodField.fat,
      PersonalFoodField.fiber,
      PersonalFoodField.servingSize,
    ];
    final errors = form.validation.errors;
    if (core.any(errors.containsKey)) return const [];
    if (errors[PersonalFoodField.nutrients] != null) {
      return [
        formPad(
          FbInlineBanner(
            kind: FbInlineBannerKind.error,
            message: l10n.personalFoodErrorImpossible,
          ),
        ),
      ];
    }
    final sanity = form.sanity;
    if (!form.showSanityWarning || sanity == null) return const [];
    // The check works on per-100 values; say it in the numbers typed.
    var expected = sanity.expectedKcal;
    if (form.mode == PersonalFoodMode.perServing) {
      final size = parsePersonalFoodNumber(
        form.text(PersonalFoodField.servingSize),
      );
      if (size != null) expected = expected * size / 100;
    }
    return [
      formPad(
        FbInlineBanner(
          kind: FbInlineBannerKind.info,
          message: l10n.personalFoodSanityWarn(DisplayRounding.kcal(expected)),
        ),
      ),
    ];
  }

  Widget _bottom(
    AppLocalizations l10n,
    PersonalFoodFormState form,
    bool canSave,
  ) {
    final refusal = _refusal;
    final message = refusal != null
        ? switch (refusal) {
            PersonalFoodFailure.changed => l10n.personalFoodSaveChanged,
            PersonalFoodFailure.removed => l10n.personalFoodSaveRemoved,
            _ => l10n.personalFoodSaveFailed,
          }
        : _attempted && form.validation.errors.isNotEmpty
        ? l10n.personalFoodFixFields
        : null;
    // A save refused because the food changed can be fixed from here.
    final reload = refusal == PersonalFoodFailure.changed;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: FbSpace.s4,
          end: FbSpace.s4,
          top: FbSpace.s2,
          bottom: FbSpace.s3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FbSpace.s2,
          children: [
            if (message != null)
              FbInlineBanner(
                kind: FbInlineBannerKind.error,
                message: message,
                actionLabel: reload ? l10n.personalFoodReload : null,
                onAction: reload ? _reload : null,
              ),
            FbButton.primary(
              label: l10n.personalFoodSave,
              expand: true,
              onPressed: canSave ? () => unawaited(_save(form)) : null,
            ),
          ],
        ),
      ),
    );
  }
}
