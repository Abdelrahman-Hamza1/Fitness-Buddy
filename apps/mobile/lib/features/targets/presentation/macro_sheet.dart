import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/targets/application/target_form_input.dart';
import 'package:fb_mobile/features/targets/application/targets_actions.dart';
import 'package:fb_mobile/features/targets/application/targets_screens.dart';
import 'package:fb_mobile/features/targets/presentation/targets_feedback.dart';
import 'package:fb_mobile/features/targets/presentation/typed_number_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the macro settings (TG-054, D14): protein, fat and carbs each
/// Default / grams / % of calories; fiber Default / grams; "Calories and
/// protein only". Save → `setMacros` with Undo.
Future<void> showMacroSheet(
  BuildContext context, {
  required TargetsView view,
}) =>
    showFbStatefulSheet<void>(context, builder: (_) => MacroSheet(view: view));

/// How one macro is set.
enum _Kind { byDefault, grams, percent }

/// One macro's choice and typed amount.
final class _MacroDraft {
  const new(this.kind, this.text);

  factory of(MacroOverride? value) => switch (value) {
    null => const _MacroDraft(_Kind.byDefault, ''),
    MacroOverride(isPercent: true, :final value) => _MacroDraft(
      _Kind.percent,
      _text(value),
    ),
    MacroOverride(:final value) => _MacroDraft(_Kind.grams, _text(value)),
  };

  final _Kind kind;
  final String text;

  static String _text(double value) {
    final rounded = roundHalfAwayFromZero(value, 1);
    return rounded == rounded.truncateToDouble()
        ? '${rounded.toInt()}'
        : '$rounded';
  }

  /// The override (null for the default), and whether it can be used.
  ({MacroOverride? value, bool valid}) read() {
    if (kind == _Kind.byDefault) return (value: null, valid: true);
    final number = parseTypedNumber(text);
    final percent = kind == _Kind.percent;
    if (number == null ||
        !TargetRules.input.macro(number, isPercent: percent)) {
      return (value: null, valid: false);
    }
    return (
      value: percent
          ? MacroOverride.percent(number)
          : MacroOverride.grams(number),
      valid: true,
    );
  }
}

/// The body of the macro settings sheet.
class MacroSheet extends ConsumerStatefulWidget {
  /// Edits the macros of [view]'s version.
  const new({required this.view, super.key});

  /// What Targets showed.
  final TargetsView view;

  @override
  ConsumerState<MacroSheet> createState() => _MacroSheetState();
}

class _MacroSheetState extends ConsumerState<MacroSheet> {
  late final MacroSettings _stored = widget.view.version.macros;
  late _MacroDraft _protein = _MacroDraft.of(_stored.protein);
  late _MacroDraft _fat = _MacroDraft.of(_stored.fat);
  late _MacroDraft _carbs = _MacroDraft.of(_stored.carbs);
  late _MacroDraft _fiber = _stored.fiberGrams == null
      ? const _MacroDraft(_Kind.byDefault, '')
      : _MacroDraft(_Kind.grams, _MacroDraft._text(_stored.fiberGrams!));
  late bool _proteinOnly = _stored.caloriesProteinOnly;
  bool _saving = false;
  TargetsFailure? _failure;
  late VersionedId _shown = widget.view.shown;
  bool _showErrors = false;

  /// The settings, or null while an amount is unusable.
  MacroSettings? get _settings {
    final protein = _protein.read();
    final fat = _fat.read();
    final carbs = _carbs.read();
    double? fiber;
    if (_fiber.kind == _Kind.grams) {
      final number = parseTypedNumber(_fiber.text);
      if (number == null || !TargetRules.input.fiber(number)) return null;
      fiber = number;
    }
    // Calories and protein only: fat and carbs aren't stored, so a stale
    // amount typed for them can't block the save (TG-054).
    if (!protein.valid) return null;
    if (!_proteinOnly && (!fat.valid || !carbs.valid)) return null;
    return MacroSettings(
      protein: protein.value,
      fat: _proteinOnly ? null : fat.value,
      carbs: _proteinOnly ? null : carbs.value,
      fiberGrams: fiber,
      caloriesProteinOnly: _proteinOnly,
    );
  }

  Future<void> _save() async {
    final settings = _settings;
    if (settings == null) {
      setState(() => _showErrors = true);
      return;
    }
    final host = Navigator.of(context, rootNavigator: true).context;
    final nav = Navigator.of(context);
    String doneText(TargetsDone _) => host.l10n.targetsUpdated;
    setState(() {
      _saving = true;
      _failure = null;
    });
    final outcome = await ref
        .read(targetsActionsProvider)
        .setMacros(_shown, settings);
    if (!mounted) {
      // Dismissed during Save: the result, Undo included, still shows on
      // the root messenger (UX-030).
      if (host.mounted) showTargetsFeedback(host, outcome, done: doneText);
      return;
    }
    setState(() => _saving = false);
    // A refusal keeps the sheet and what was chosen (UX-052).
    if (outcome case TargetsFailed(:final reason)) {
      setState(() => _failure = reason);
      return;
    }
    if (outcome is TargetsPending) return;
    nav.pop();
    if (!host.mounted) return;
    showTargetsFeedback(host, outcome, done: doneText);
  }

  /// Takes the version Targets shows now; the draft stays (UX-052).
  void _reload() => setState(() {
    _shown = ref.read(targetsViewProvider).value?.shown ?? _shown;
    _failure = null;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FbSheet(
      title: l10n.targetsMacroSettings,
      actions: FbButton.primary(
        label: l10n.targetsSave,
        expand: true,
        onPressed: _saving ? null : () => unawaited(_save()),
      ),
      child: Padding(
        // Lifts the sheet above the keyboard.
        padding: EdgeInsetsDirectional.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FbSpace.s4,
          children: [
            if (_failure case final reason?)
              SaveFailedBanner(reason: reason, onReload: _reload),
            _MacroRow(
              label: l10n.targetsMacroProtein,
              draft: _protein,
              showErrors: _showErrors,
              onChanged: (d) => setState(() => _protein = d),
            ),
            FbSwitchRow(
              title: l10n.targetsMacroProteinOnly,
              subtitle: l10n.targetsMacroProteinOnlyHint,
              value: _proteinOnly,
              onChanged: (on) => setState(() => _proteinOnly = on),
            ),
            if (!_proteinOnly) ...[
              _MacroRow(
                label: l10n.targetsMacroFat,
                draft: _fat,
                showErrors: _showErrors,
                onChanged: (d) => setState(() => _fat = d),
              ),
              _MacroRow(
                label: l10n.targetsMacroCarbs,
                draft: _carbs,
                showErrors: _showErrors,
                onChanged: (d) => setState(() => _carbs = d),
              ),
            ],
            _MacroRow(
              label: l10n.targetsMacroFiber,
              draft: _fiber,
              showErrors: _showErrors,
              gramsOnly: true,
              onChanged: (d) => setState(() => _fiber = d),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const new({
    required this.label,
    required this.draft,
    required this.onChanged,
    required this.showErrors,
    this.gramsOnly = false,
  });

  final String label;
  final _MacroDraft draft;
  final ValueChanged<_MacroDraft> onChanged;
  final bool showErrors;
  final bool gramsOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final percent = draft.kind == _Kind.percent;
    final number = parseTypedNumber(draft.text);
    final valid = gramsOnly
        ? number != null && TargetRules.input.fiber(number)
        : number != null && TargetRules.input.macro(number, isPercent: percent);
    final error = valid
        ? null
        : percent
        ? l10n.targetsMacroPercentRange
        : l10n.targetsMacroGramsRange(
            gramsOnly
                ? TargetInputRules.maxFiberG.toInt()
                : TargetInputRules.maxMacroGrams.toInt(),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s2,
      children: [
        Text(label, style: FbType.label.copyWith(color: scheme.onSurface)),
        Wrap(
          spacing: FbSpace.s2,
          runSpacing: FbSpace.s2,
          children: [
            for (final (kind, text) in [
              (_Kind.byDefault, l10n.targetsMacroDefault),
              (_Kind.grams, l10n.targetsMacroGramsChoice),
              if (!gramsOnly) (_Kind.percent, l10n.targetsMacroPercentChoice),
            ])
              FbChoiceChip(
                label: text,
                selected: draft.kind == kind,
                dropdown: false,
                onTap: () => onChanged(_MacroDraft(kind, draft.text)),
              ),
          ],
        ),
        if (draft.kind != _Kind.byDefault)
          TypedNumberField(
            text: draft.text,
            label: label,
            unit: percent
                ? l10n.targetsMacroPercentUnit
                : l10n.targetsMacroGramsUnit,
            errorText: error,
            showError: showErrors,
            onChanged: (text) => onChanged(_MacroDraft(draft.kind, text)),
          ),
      ],
    );
  }
}
