import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/foods/application/personal_food_form.dart';
import 'package:fb_mobile/features/foods/presentation/personal_foods/personal_food_inputs.dart';
import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Divider, IconButton, Theme;

/// The optional nutrients under "More nutrients", in the order shown (FD-002).
const List<(PersonalFoodField, NutrientKey)> extraNutrients = [
  (PersonalFoodField.sugar, NutrientKey.sugar),
  (PersonalFoodField.saturatedFat, NutrientKey.saturatedFat),
  (PersonalFoodField.transFat, NutrientKey.transFat),
  (PersonalFoodField.sodium, NutrientKey.sodium),
  (PersonalFoodField.cholesterol, NutrientKey.cholesterol),
  (PersonalFoodField.alcohol, NutrientKey.alcohol),
];

/// The serving names in the order the picker lists them. The closed
/// vocabulary decides which exist (A09 D2); a test keeps the two in step.
const List<String> servingUnitOrder = [
  'serving',
  'piece',
  'cup',
  'tbsp',
  'tsp',
  'glass',
  'can',
  'plate',
  'loaf',
  'sandwich',
  'disc',
];

/// What the form's sections read and call: the typed state, the controllers
/// of its fields and the view model (A09 D7).
final class PersonalFormBinding {
  /// Creates the binding.
  const new({
    required this.form,
    required this.inputs,
    required this.controller,
    required this.attempted,
  });

  /// The typed state.
  final PersonalFoodFormState form;

  /// The text controllers and focus nodes.
  final PersonalFoodInputs inputs;

  /// The view model that keeps what was typed.
  final PersonalFoodFormController controller;

  /// A save was tried and refused: show every field's error, not only the
  /// ones already edited.
  final bool attempted;

  /// The controller of [field].
  TextEditingController text(PersonalFoodField field) =>
      inputs.controller(field, form);

  /// The words for [field]'s error, once it is edited or a save was tried.
  String? error(AppLocalizations l10n, PersonalFoodField field) {
    if (!attempted && !form.touched.contains(field)) return null;
    return errorWords(l10n, form.validation.errors[field]);
  }

  /// The words for one field error.
  static String? errorWords(
    AppLocalizations l10n,
    PersonalFoodFieldError? error,
  ) {
    return switch (error) {
      PersonalFoodFieldError.required => l10n.personalFoodErrorRequired,
      PersonalFoodFieldError.invalidNumber => l10n.personalFoodErrorNumber,
      PersonalFoodFieldError.bounds => l10n.personalFoodErrorBounds,
      PersonalFoodFieldError.tooSmall => l10n.personalFoodErrorTooSmall,
      PersonalFoodFieldError.invalidText => l10n.personalFoodErrorText,
      PersonalFoodFieldError.invalidBarcode => l10n.personalFoodErrorBarcode,
      PersonalFoodFieldError.invalidServing => l10n.personalFoodErrorServing,
      PersonalFoodFieldError.impossible => l10n.personalFoodErrorImpossible,
      null => null,
    };
  }

  /// The unit word of the basis ("g" or "ml").
  String basisUnit(AppLocalizations l10n) =>
      form.basis == NutrientBasis.per100g ? l10n.unitG : l10n.unitMl;
}

/// Pads [child] like a screen section.
Widget formPad(Widget child) => Padding(
  padding: const EdgeInsetsDirectional.symmetric(horizontal: FbSpace.s4),
  child: child,
);

/// The name and the "You already have" note (FD-070): the first thing on
/// the form.
class NameSection extends StatelessWidget {
  /// Creates the section.
  const new({required this.binding, required this.autofocus, super.key});

  /// The form.
  final PersonalFormBinding binding;

  /// Whether the name takes the keyboard when the form opens.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final b = binding;
    final duplicate = b.form.duplicate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        formPad(
          FbTextField(
            controller: b.text(PersonalFoodField.name),
            focusNode: b.inputs.focus(PersonalFoodField.name),
            label: l10n.personalFoodNameLabel,
            maxLength: PersonalFoodBounds.name,
            autofocus: autofocus,
            textInputAction: TextInputAction.next,
            errorText: b.error(l10n, PersonalFoodField.name),
            onChanged: (t) => b.controller.setField(PersonalFoodField.name, t),
          ),
        ),
        if (duplicate != null)
          formPad(
            Text(
              l10n.personalFoodDuplicate(duplicate.names.en),
              style: FbType.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

/// The Arabic name, other names and brand, under "More details" (FD-070,
/// FD-020). The Arabic name is typed right to left.
class OtherNamesSection extends StatelessWidget {
  /// Creates the section.
  const new({required this.binding, super.key});

  /// The form.
  final PersonalFormBinding binding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final b = binding;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        formPad(
          FbTextField(
            controller: b.text(PersonalFoodField.nameAr),
            focusNode: b.inputs.focus(PersonalFoodField.nameAr),
            label: l10n.personalFoodNameArLabel,
            maxLength: PersonalFoodBounds.name,
            textDirection: TextDirection.rtl,
            textInputAction: TextInputAction.next,
            errorText: b.error(l10n, PersonalFoodField.nameAr),
            onChanged: (t) =>
                b.controller.setField(PersonalFoodField.nameAr, t),
          ),
        ),
        formPad(
          FbTextField(
            controller: b.text(PersonalFoodField.aliases),
            focusNode: b.inputs.focus(PersonalFoodField.aliases),
            label: l10n.personalFoodAliasesLabel,
            hint: l10n.personalFoodAliasesHint,
            textInputAction: TextInputAction.next,
            errorText: b.error(l10n, PersonalFoodField.aliases),
            onChanged: (t) =>
                b.controller.setField(PersonalFoodField.aliases, t),
          ),
        ),
        formPad(
          FbTextField(
            controller: b.text(PersonalFoodField.brand),
            focusNode: b.inputs.focus(PersonalFoodField.brand),
            label: l10n.personalFoodBrandLabel,
            maxLength: PersonalFoodBounds.brand,
            textInputAction: TextInputAction.next,
            errorText: b.error(l10n, PersonalFoodField.brand),
            onChanged: (t) => b.controller.setField(PersonalFoodField.brand, t),
          ),
        ),
      ],
    );
  }
}

/// "The label's numbers are for" (100 g, 100 ml or one serving), the
/// serving they are for, the five main nutrients, the [notes] about them
/// and "More nutrients" (FD-002, FD-070, D7).
class ValuesSection extends StatelessWidget {
  /// Creates the section.
  const new({
    required this.binding,
    required this.moreOpen,
    required this.onToggleMore,
    required this.onPickServingUnit,
    this.notes = const [],
    this.autofocusKcal = false,
    super.key,
  });

  /// The form.
  final PersonalFormBinding binding;

  /// Whether the optional nutrients are shown.
  final bool moreOpen;

  /// Opens or closes the optional nutrients.
  final VoidCallback onToggleMore;

  /// Opens the list of serving names for the values' serving.
  final VoidCallback onPickServingUnit;

  /// Shown right under Fiber: the calories note or the impossible-values
  /// note (FD-012).
  final List<Widget> notes;

  /// Whether Calories takes the keyboard when the form opens (the name
  /// came from a search).
  final bool autofocusKcal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final b = binding;
    final form = b.form;
    final perServing = form.mode == PersonalFoodMode.perServing;
    final per100 = form.mode == PersonalFoodMode.per100;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    Widget number(
      PersonalFoodField field,
      String label,
      String unit, {
      String? hint,
      bool autofocus = false,
    }) => formPad(
      FbNumberField(
        controller: b.text(field),
        focusNode: b.inputs.focus(field),
        label: label,
        unit: unit,
        hint: hint,
        autofocus: autofocus,
        textInputAction: TextInputAction.next,
        errorText: b.error(l10n, field),
        onChanged: (t) => b.controller.setField(field, t),
      ),
    );
    // Changing what the numbers are for never converts them (A09 D7).
    final numbersStay =
        form.configurationTouched &&
        nutrientFields.any((f) => form.text(f).trim().isNotEmpty);
    final size = parsePersonalFoodNumber(
      form.text(PersonalFoodField.servingSize),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        formPad(
          Text(
            l10n.personalFoodValuesPer,
            style: FbType.label.copyWith(color: muted),
          ),
        ),
        formPad(
          Wrap(
            spacing: FbSpace.s2,
            runSpacing: FbSpace.s2,
            children: [
              FbChoiceChip(
                label: l10n.personalFoodBasis100g,
                selected: per100 && form.basis == NutrientBasis.per100g,
                dropdown: false,
                onTap: () => b.controller.setMode(
                  PersonalFoodMode.per100,
                  basis: NutrientBasis.per100g,
                ),
              ),
              FbChoiceChip(
                label: l10n.personalFoodBasis100ml,
                selected: per100 && form.basis == NutrientBasis.per100ml,
                dropdown: false,
                onTap: () => b.controller.setMode(
                  PersonalFoodMode.per100,
                  basis: NutrientBasis.per100ml,
                ),
              ),
              FbChoiceChip(
                label: l10n.personalFoodBasisServing,
                selected: perServing,
                dropdown: false,
                onTap: () => b.controller.setMode(PersonalFoodMode.perServing),
              ),
            ],
          ),
        ),
        if (numbersStay)
          formPad(
            Text(
              l10n.personalFoodNumbersStay,
              style: FbType.bodySmall.copyWith(color: muted),
            ),
          ),
        if (perServing) ...[
          // "Serving size [30] [g | ml]": the size and what it is measured
          // in, together.
          formPad(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: FbSpace.s2,
              children: [
                Expanded(
                  flex: 3,
                  child: FbNumberField(
                    controller: b.text(PersonalFoodField.servingSize),
                    focusNode: b.inputs.focus(PersonalFoodField.servingSize),
                    label: l10n.personalFoodServingSize,
                    semanticLabel: l10n.personalFoodServingSizeSemantics,
                    unit: b.basisUnit(l10n),
                    textInputAction: TextInputAction.next,
                    errorText: b.error(l10n, PersonalFoodField.servingSize),
                    onChanged: (t) =>
                        b.controller.setField(PersonalFoodField.servingSize, t),
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: Wrap(
                    spacing: FbSpace.s2,
                    runSpacing: FbSpace.s2,
                    children: [
                      FbChoiceChip(
                        label: l10n.unitG,
                        semanticLabel: l10n.personalFoodServingInGrams,
                        selected: form.basis == NutrientBasis.per100g,
                        dropdown: false,
                        onTap: () => b.controller.setMode(
                          PersonalFoodMode.perServing,
                          basis: NutrientBasis.per100g,
                        ),
                      ),
                      FbChoiceChip(
                        label: l10n.unitMl,
                        semanticLabel: l10n.personalFoodServingInMl,
                        selected: form.basis == NutrientBasis.per100ml,
                        dropdown: false,
                        onTap: () => b.controller.setMode(
                          PersonalFoodMode.perServing,
                          basis: NutrientBasis.per100ml,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          formPad(
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FbChoiceChip(
                label: l10n.personalFoodServingCalled,
                value: unitLabel(l10n, form.servingUnit, 1),
                onTap: onPickServingUnit,
              ),
            ),
          ),
          if (size != null && size > 0)
            formPad(
              Text(
                l10n.personalFoodServingShownAs(
                  unitLabel(l10n, form.servingUnit, 1),
                  size,
                  b.basisUnit(l10n),
                ),
                style: FbType.bodySmall.copyWith(color: muted),
              ),
            ),
        ],
        number(
          PersonalFoodField.kcal,
          l10n.foodNutrientEnergy,
          l10n.personalFoodUnitKcal,
          autofocus: autofocusKcal,
        ),
        number(PersonalFoodField.protein, l10n.foodNutrientProtein, l10n.unitG),
        number(PersonalFoodField.carbs, l10n.foodNutrientCarbs, l10n.unitG),
        number(PersonalFoodField.fat, l10n.foodNutrientFat, l10n.unitG),
        number(
          PersonalFoodField.fiber,
          l10n.foodNutrientFiber,
          l10n.unitG,
          hint: l10n.personalFoodFiberHint,
        ),
        ...notes,
        FbDisclosureRow(
          title: l10n.personalFoodMoreNutrients,
          expanded: moreOpen,
          onToggle: onToggleMore,
        ),
        if (moreOpen) ...[
          formPad(
            Text(
              l10n.personalFoodExtraHint,
              style: FbType.bodySmall.copyWith(color: muted),
            ),
          ),
          for (final (field, key) in extraNutrients)
            number(
              field,
              nutrientKeyLabel(l10n, key),
              key.unit == NutrientUnit.milligram
                  ? l10n.personalFoodUnitMg
                  : l10n.unitG,
            ),
        ],
      ],
    );
  }
}

/// The preparation state of the food (FD-060): one choice of six.
class StateSection extends StatelessWidget {
  /// Creates the section.
  const new({required this.binding, super.key});

  /// The form.
  final PersonalFormBinding binding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final b = binding;
    const order = [
      FoodState.asSold,
      FoodState.raw,
      FoodState.cooked,
      FoodState.dry,
      FoodState.drained,
      FoodState.fried,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s2,
      children: [
        formPad(
          Text(
            l10n.personalFoodStateLabel,
            style: FbType.label.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        formPad(
          Wrap(
            spacing: FbSpace.s2,
            runSpacing: FbSpace.s2,
            children: [
              for (final state in order)
                FbChoiceChip(
                  label: l10n.personalFoodStateChoice(state.code),
                  selected: b.form.foodState == state,
                  dropdown: false,
                  onTap: () => b.controller.setFoodState(state),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The food's own servings: a name and a size each (FD-003, D7).
class ServingsSection extends StatelessWidget {
  /// Creates the section.
  const new({
    required this.binding,
    required this.onAdd,
    required this.onRemove,
    required this.onPickUnit,
    required this.onChanged,
    super.key,
  });

  /// The form.
  final PersonalFormBinding binding;

  /// Adds a row.
  final VoidCallback onAdd;

  /// Removes the row at an index.
  final ValueChanged<int> onRemove;

  /// Opens the list of names for the row at an index.
  final ValueChanged<int> onPickUnit;

  /// A row's size was edited.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final b = binding;
    final rows = b.inputs.servings;
    final error = b.error(l10n, PersonalFoodField.servings);
    // The rows at fault carry the error; the list only when none does
    // (too many rows).
    final bad = b.form.validation.badServings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        FbSectionHeader(title: l10n.personalFoodSectionServings),
        formPad(
          Text(
            l10n.personalFoodServingsHint,
            style: FbType.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (var i = 0; i < rows.length; i++)
          formPad(
            Column(
              key: ObjectKey(rows[i]),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: FbSpace.s2,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: FbChoiceChip(
                          label: l10n.personalFoodServingCalled,
                          value: unitLabel(l10n, rows[i].unit, 1),
                          onTap: () => onPickUnit(i),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.personalFoodRemoveServing,
                      icon: const Icon(FbIcons.close),
                      onPressed: () => onRemove(i),
                    ),
                  ],
                ),
                FbNumberField(
                  controller: rows[i].amount,
                  focusNode: rows[i].focus,
                  label: l10n.personalFoodServingSize,
                  semanticLabel: l10n.personalFoodServingRowSemantics(
                    unitLabel(l10n, rows[i].unit, 1),
                  ),
                  unit: b.basisUnit(l10n),
                  textInputAction: TextInputAction.next,
                  errorText: error != null && bad.contains(i) ? error : null,
                  onChanged: (_) => onChanged(),
                ),
                const Divider(),
              ],
            ),
          ),
        if (error != null && bad.isEmpty)
          formPad(
            Text(
              error,
              style: FbType.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        formPad(
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FbButton.secondary(
              label: l10n.personalFoodAddServing,
              icon: FbIcons.add,
              onPressed: rows.length >= PersonalFoodBounds.servings
                  ? null
                  : onAdd,
            ),
          ),
        ),
      ],
    );
  }
}

/// Barcodes, stored for scanning later (FD-070).
class BarcodesSection extends StatelessWidget {
  /// Creates the section.
  const new({required this.binding, super.key});

  /// The form.
  final PersonalFormBinding binding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final b = binding;
    return formPad(
      FbTextField(
        controller: b.text(PersonalFoodField.barcodes),
        focusNode: b.inputs.focus(PersonalFoodField.barcodes),
        label: l10n.personalFoodBarcodesLabel,
        hint: l10n.personalFoodBarcodesHint,
        textInputAction: TextInputAction.done,
        errorText: b.error(l10n, PersonalFoodField.barcodes),
        onChanged: (t) => b.controller.setField(PersonalFoodField.barcodes, t),
      ),
    );
  }
}
