import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/targets/application/target_form_input.dart';
import 'package:fb_mobile/features/targets/presentation/targets_text.dart';
import 'package:fb_mobile/features/targets/presentation/typed_number_field.dart';
import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Theme;

// The profile fields (TG-001, TG-002), shared by setup's "About you" page
// (A13b WP6) and Me's profile edit sheets (A13c). Each field renders a draft
// and reports edits; the draft (application/target_form_input.dart) decides
// what the text means. Heights and weights are typed in the draft's unit,
// whatever the unit setting (TG-002: inputs accept either system).

/// A label with an optional muted line under it, above a choice.
class _ChoiceLabel extends StatelessWidget {
  const new({required this.label, this.hint});

  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FbType.label.copyWith(color: scheme.onSurface)),
        if (hint != null)
          Text(
            hint!,
            style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
          ),
      ],
    );
  }
}

/// The message under a choice left empty when Next was tapped (UX-052),
/// in the error colour like a field's error, announced when it appears.
class ChoiceError extends StatelessWidget {
  /// Creates the message.
  const new(this.text, {super.key});

  /// The (already translated) message.
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      text,
      style: FbType.bodySmall.copyWith(
        color: Theme.of(context).colorScheme.error,
      ),
    ),
  );
}

/// Two chips, start-aligned, wrapping at large text.
Widget _chips(List<Widget> chips) =>
    Wrap(spacing: FbSpace.s2, runSpacing: FbSpace.s2, children: chips);

/// Formula sex: Male / Female, "Used for the energy formula" (TG-001).
class SexField extends StatelessWidget {
  /// Creates the field.
  const new({
    required this.selected,
    required this.onSelected,
    this.showError = false,
    super.key,
  });

  /// The chosen sex, or null before a choice.
  final FormulaSex? selected;

  /// Called with the tapped sex.
  final ValueChanged<FormulaSex> onSelected;

  /// Say "Choose one to continue." while nothing is chosen (a refused Next).
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s2,
      children: [
        _ChoiceLabel(label: l10n.profileSexLabel, hint: l10n.profileSexHint),
        _chips([
          for (final sex in FormulaSex.values)
            FbChoiceChip(
              label: sexLabel(l10n, sex),
              selected: selected == sex,
              dropdown: false,
              onTap: () => onSelected(sex),
            ),
        ]),
        if (showError && selected == null) ChoiceError(l10n.targetsChooseOne),
      ],
    );
  }
}

/// The birth year, checked against an age of 18–100 on [today] (D15).
class BirthYearField extends StatelessWidget {
  /// Creates the field.
  const new({
    required this.text,
    required this.onChanged,
    required this.today,
    this.showError = false,
    super.key,
  });

  /// The year as typed.
  final String text;

  /// Called with every edit.
  final ValueChanged<String> onChanged;

  /// The evaluation date of the age rule.
  final LocalDate today;

  /// Show the message before the user left the field.
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TypedNumberField(
      text: text,
      onChanged: onChanged,
      label: l10n.profileBirthYearLabel,
      maxDecimals: 0,
      showError: showError,
      errorText: birthYearErrorText(
        l10n,
        readBirthYear(text, today).error,
        today,
      ),
    );
  }
}

/// The height in cm, or in feet and inches (TG-002, D17). With
/// [showUnitChoice] two chips switch the unit (Me's edit sheet); setup's
/// Units chips set it from outside instead.
class HeightField extends StatelessWidget {
  /// Creates the field.
  const new({
    required this.draft,
    required this.onChanged,
    this.showError = false,
    this.showUnitChoice = false,
    super.key,
  });

  /// The height as typed.
  final HeightDraft draft;

  /// Called with every edit, and with a unit switch.
  final ValueChanged<HeightDraft> onChanged;

  /// Show the message before the user left the field.
  final bool showError;

  /// Whether the cm / ft + in chips are shown.
  final bool showUnitChoice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final error = heightErrorText(l10n, draft.read().error, draft.unit);
    final fields = switch (draft.unit) {
      HeightInputUnit.centimeter => TypedNumberField(
        key: const ValueKey('height-cm'),
        text: draft.cm,
        onChanged: (t) => onChanged(draft.copyWith(cm: t)),
        label: l10n.profileHeightLabel,
        unit: l10n.profileUnitCm,
        showError: showError,
        errorText: error,
      ),
      HeightInputUnit.feetInches => _FeetInches(
        draft: draft,
        onChanged: onChanged,
        showError: showError,
        errorText: error,
      ),
    };
    if (!showUnitChoice) return fields;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s2,
      children: [
        _ChoiceLabel(label: l10n.profileHeightLabel),
        _chips([
          for (final (unit, label) in [
            (HeightInputUnit.centimeter, l10n.profileHeightUnitCm),
            (HeightInputUnit.feetInches, l10n.profileHeightUnitFtIn),
          ])
            FbChoiceChip(
              label: label,
              selected: draft.unit == unit,
              dropdown: false,
              onTap: () => onChanged(draft.withUnit(unit)),
            ),
        ]),
        fields,
      ],
    );
  }
}

/// Feet and inches side by side; the message under them both.
class _FeetInches extends StatelessWidget {
  const new({
    required this.draft,
    required this.onChanged,
    required this.showError,
    required this.errorText,
  });

  final HeightDraft draft;
  final ValueChanged<HeightDraft> onChanged;
  final bool showError;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final feet = TypedNumberField(
      key: const ValueKey('height-ft'),
      text: draft.feet,
      onChanged: (t) => onChanged(draft.copyWith(feet: t)),
      label: l10n.profileHeightFeet,
      unit: l10n.profileUnitFt,
      maxDecimals: 0,
      semanticLabel: '${l10n.profileHeightLabel}, ${l10n.profileHeightFeet}',
      showError: showError,
      errorText: errorText,
    );
    final inches = TypedNumberField(
      key: const ValueKey('height-in'),
      text: draft.inches,
      onChanged: (t) => onChanged(draft.copyWith(inches: t)),
      label: l10n.profileHeightInches,
      unit: l10n.profileUnitIn,
      semanticLabel: '${l10n.profileHeightLabel}, ${l10n.profileHeightInches}',
    );
    // At large text sizes the two fields stack, so neither label is cut.
    final scale = MediaQuery.textScalerOf(context).scale(1);
    if (scale > 1.5) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s3,
        children: [feet, inches],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FbSpace.s3,
      children: [
        Expanded(child: feet),
        Expanded(child: inches),
      ],
    );
  }
}

/// A body weight in kg or lb (TD-017): the current weight in setup, which
/// becomes the first weigh-in (D10).
class BodyWeightField extends StatelessWidget {
  /// Creates the field.
  const new({
    required this.draft,
    required this.onChanged,
    this.label,
    this.showError = false,
    this.textInputAction,
    super.key,
  });

  /// The weight as typed.
  final BodyWeightDraft draft;

  /// Called with every edit.
  final ValueChanged<BodyWeightDraft> onChanged;

  /// The label; "Current weight" when null.
  final String? label;

  /// Show the message before the user left the field.
  final bool showError;

  /// The keyboard's action button (next by default).
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TypedNumberField(
      text: draft.text,
      onChanged: (t) => onChanged(draft.withText(t)),
      label: label ?? l10n.profileWeightLabel,
      unit: massUnitLabel(l10n, draft.unit),
      showError: showError,
      textInputAction: textInputAction ?? TextInputAction.next,
      errorText: weightErrorText(l10n, draft.read().error, draft.unit),
    );
  }
}
