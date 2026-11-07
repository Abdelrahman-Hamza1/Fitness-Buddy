import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/targets/application/target_form_input.dart';
import 'package:fb_mobile/features/targets/application/targets_actions.dart';
import 'package:fb_mobile/features/targets/application/targets_screens.dart';
import 'package:fb_mobile/features/targets/presentation/below_limit_screen.dart';
import 'package:fb_mobile/features/targets/presentation/macro_sheet.dart';
import 'package:fb_mobile/features/targets/presentation/targets_feedback.dart';
import 'package:fb_mobile/features/targets/presentation/typed_number_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

/// Opens "Calories every day" (TG-046, D-102, design board 2): one number
/// for every day with − / + (50 kcal), typing, quick picks (now, ±200,
/// the suggestion) and a live preview of the day's macros against the
/// current ones, the P/F/C shares and a rough weekly rate. "Use N every
/// day" sets the user's own daily target (SF-011/SF-012 warning first when
/// it breaks a limit) with Undo; the suggestion goes back to the
/// calculated target. "Adjust macros myself" opens the macro settings.
Future<void> showDailyTargetSheet(
  BuildContext context, {
  required TargetsView view,
}) => showFbStatefulSheet<void>(
  context,
  builder: (_) => DailyTargetSheet(view: view),
);

/// The body of the Change sheet.
class DailyTargetSheet extends ConsumerStatefulWidget {
  /// Changes [view]'s version.
  const new({required this.view, super.key});

  /// What Targets showed.
  final TargetsView view;

  @override
  ConsumerState<DailyTargetSheet> createState() => _DailyTargetSheetState();
}

class _DailyTargetSheetState extends ConsumerState<DailyTargetSheet> {
  /// The chips' amounts around the current number, kcal.
  static const int _chip = 200;

  /// One − / + step.
  static const int _step = 50;

  static const int _min = 500;
  static const int _max = 10000;

  late TargetsView _view = widget.view;
  late String _text = '$_current';
  bool _typing = false;
  bool _showErrors = false;
  bool _saving = false;
  TargetsFailure? _failure;

  /// Today's daily number, rounded.
  int get _current => DisplayRounding.kcal(_view.dailyKcal);

  /// The calculated suggestion, rounded, or null.
  int? get _suggested => switch (_view.calculatedKcal) {
    final kcal? => DisplayRounding.kcal(kcal),
    null => null,
  };

  /// The typed number when it is in range (500–10,000), else null.
  int? get _kcal {
    final number = parseTypedNumber(_text);
    if (number == null || !TargetRules.input.manualKcal(number)) return null;
    return number.round();
  }

  void _set(int kcal) => setState(() {
    _text = '${kcal.clamp(_min, _max)}';
    _failure = null;
  });

  Future<void> _save() async {
    final kcal = _kcal;
    if (kcal == null) {
      setState(() => _showErrors = true);
      return;
    }
    final nav = Navigator.of(context);
    final view = _view;
    final version = view.version;
    final suggested = kcal == _suggested;
    // Nothing to save only when the stored state already is the intended
    // one (judged on what would be stored, not on the number shown): the
    // own number with no day numbers, or the suggestion with none.
    final noDays = view.plan.dayFactors.isEmpty;
    final unchanged = suggested
        ? !version.manual && noDays
        : version.manual &&
              noDays &&
              kcal == DisplayRounding.kcal(version.baseKcal);
    if (unchanged) {
      nav.pop();
      return;
    }
    final host = Navigator.of(context, rootNavigator: true).context;
    String doneText(TargetsDone _) => host.l10n.targetsUpdated;
    final actions = ref.read(targetsActionsProvider);
    setState(() {
      _saving = true;
      _failure = null;
    });
    var outcome = suggested
        ? await actions.useSuggestedEveryDay(
            view.shown,
            expectedKcal: view.calculatedKcal,
          )
        : await actions.setManualTarget(
            view.shown,
            kcal.toDouble(),
            everyDay: true,
          );
    if (outcome case final TargetsNeedsAcknowledgement need) {
      // Go back returns to the number as typed; nothing is written.
      if (!mounted || !host.mounted) return;
      final confirmed = await showBelowLimitScreen(
        host,
        kcal: kcal.toDouble(),
        need: need,
        units: view.units,
      );
      if (confirmed != true) {
        if (mounted) setState(() => _saving = false);
        return;
      }
      outcome = await actions.setManualTarget(
        view.shown,
        kcal.toDouble(),
        acknowledged: true,
        everyDay: true,
      );
    }
    if (!mounted) {
      if (host.mounted) showTargetsFeedback(host, outcome, done: doneText);
      return;
    }
    setState(() => _saving = false);
    // A refusal keeps the sheet and the number (UX-052).
    if (outcome case TargetsFailed(:final reason)) {
      setState(() => _failure = reason);
      return;
    }
    if (outcome is TargetsPending || outcome is TargetsNeedsAcknowledgement) {
      return;
    }
    nav.pop();
    if (!host.mounted) return;
    showTargetsFeedback(host, outcome, done: doneText);
  }

  /// Takes what Targets shows now; the number stays (UX-052), except a
  /// picked suggestion, which becomes the new one.
  void _reload() => setState(() {
    final wasSuggested = _kcal != null && _kcal == _suggested;
    _view = ref.read(targetsViewProvider).value ?? _view;
    if (wasSuggested && _suggested != null) _text = '$_suggested';
    _failure = null;
  });

  void _macros() {
    final host = Navigator.of(context, rootNavigator: true).context;
    Navigator.of(context).pop();
    unawaited(showMacroSheet(host, view: _view));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final kcal = _kcal;
    final shown = kcal ?? _current;
    final number = NumberFormat.decimalPattern(l10n.localeName);
    final suggested = _suggested;
    final preview = _view.previewDaily(shown.toDouble());
    final muted = FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant);
    final picks = <(String, int)>[
      if (_current != suggested) (l10n.targetsDailyNow(_current), _current),
      if (_current - _chip >= _min)
        (l10n.targetsDayMinus(_chip), _current - _chip),
      if (_current + _chip <= _max)
        (l10n.targetsDayPlus(_chip), _current + _chip),
      if (suggested != null)
        (l10n.targetsDailySuggestedChip(suggested), suggested),
    ];
    // The whole sheet, its pinned button too, sits above the keyboard.
    return Padding(
      padding: EdgeInsetsDirectional.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: FbSheet(
        title: l10n.targetsDailySheetTitle,
        actions: FbButton.primary(
          label: l10n.targetsDailyUse(shown),
          expand: true,
          onPressed: _saving ? null : () => unawaited(_save()),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FbSpace.s4,
          children: [
            if (_failure case final reason?)
              SaveFailedBanner(reason: reason, onReload: _reload),
            if (_typing)
              TypedNumberField(
                text: _text,
                label: l10n.targetsManualLabel,
                unit: l10n.targetsManualUnit,
                maxDecimals: 0,
                autofocus: true,
                textInputAction: TextInputAction.done,
                errorText: kcal == null ? l10n.targetsManualRange : null,
                showError: _showErrors,
                onChanged: (text) => setState(() => _text = text),
              )
            else
              Row(
                children: [
                  FbIconButton(
                    icon: FbIcons.remove,
                    tooltip: l10n.targetsDayLess,
                    onPressed: shown - _step < _min
                        ? null
                        : () => _set(shown - _step),
                  ),
                  Expanded(
                    child: InkWell(
                      key: const ValueKey('daily-target-number'),
                      borderRadius: FbRadius.mdAll,
                      onTap: () => setState(() => _typing = true),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          vertical: FbSpace.s2,
                        ),
                        child: Column(
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                number.format(shown),
                                style: FbType.numeric(FbType.display)
                                    .copyWith(color: scheme.onSurface),
                              ),
                            ),
                            Text(l10n.targetsDayTapToType, style: muted),
                          ],
                        ),
                      ),
                    ),
                  ),
                  FbIconButton(
                    icon: FbIcons.add,
                    tooltip: l10n.targetsDayMore,
                    onPressed: shown + _step > _max
                        ? null
                        : () => _set(shown + _step),
                  ),
                ],
              ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: FbSpace.s2,
              runSpacing: FbSpace.s2,
              children: [
                for (final (label, value) in picks)
                  FbChoiceChip(
                    label: label,
                    selected: kcal == value,
                    dropdown: false,
                    onTap: () => _set(value),
                  ),
              ],
            ),
            if (!_view.everyDaySame)
              Text(
                l10n.targetsDailyReplacesDays,
                textAlign: TextAlign.center,
                style: muted,
              ),
            _Preview(preview: preview, unit: _view.units.bodyMass),
            FbButton.text(
              label: l10n.targetsDailyAdjustMacros,
              expand: true,
              onPressed: _saving ? null : _macros,
            ),
          ],
        ),
      ),
    );
  }
}

/// "Your day becomes": each macro's new target and "was X", the P/F/C
/// share bar and the rough weekly rate (TG-046).
class _Preview extends StatelessWidget {
  const new({required this.preview, required this.unit});

  final DailyTargetPreview preview;
  final MassUnit unit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.fbColors;
    final now = preview.macros;
    final was = preview.currentMacros;
    final shares = preview.shares;
    final rate = preview.kgPerWeek;
    return Column(
      key: const ValueKey('daily-target-preview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s2,
      children: [
        Text(
          l10n.targetsDailyBecomes,
          style: FbType.label.copyWith(color: scheme.onSurface),
        ),
        _MacroLine(
          label: l10n.todayMacroProtein,
          color: colors.protein,
          grams: now.proteinGrams,
          was: was.proteinGrams,
        ),
        _MacroLine(
          label: l10n.todayMacroCarbs,
          color: colors.carbs,
          grams: now.carbsGrams,
          was: was.carbsGrams,
        ),
        _MacroLine(
          label: l10n.todayMacroFat,
          color: colors.fat,
          grams: now.fatGrams,
          was: was.fatGrams,
        ),
        _MacroLine(
          label: l10n.todayMacroFiber,
          color: colors.fiber,
          grams: now.fiberGrams,
          was: was.fiberGrams,
        ),
        if (shares != null)
          _ShareBar(
            protein: shares.protein,
            fat: shares.fat,
            carbs: shares.carbs,
          ),
        if (rate != null)
          Text(
            l10n.targetsDailyRate(weightRateText(l10n, rate, unit)),
            key: const ValueKey('daily-target-rate'),
            style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
          ),
      ],
    );
  }
}

class _MacroLine extends StatelessWidget {
  const new({
    required this.label,
    required this.color,
    required this.grams,
    required this.was,
  });

  final String label;
  final Color color;
  final double? grams;
  final double? was;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final value = switch (grams) {
      final g? => l10n.targetsMacroGrams(DisplayRounding.macroTargetGrams(g)),
      null => l10n.targetsDailyNoTarget,
    };
    final before = switch (was) {
      final g? => l10n.targetsDailyWas(DisplayRounding.macroTargetGrams(g)),
      null => null,
    };
    final name = Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const SizedBox.square(dimension: FbSpace.s2),
        ),
        const SizedBox(width: FbSpace.s2),
        Expanded(
          child: Text(
            label,
            style: FbType.body.copyWith(color: scheme.onSurface),
          ),
        ),
      ],
    );
    final amounts = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: value,
            style: FbType.numeric(FbType.body)
                .copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600),
          ),
          if (before != null)
            TextSpan(
              text: '  $before',
              style: FbType.numeric(FbType.bodySmall)
                  .copyWith(color: scheme.onSurfaceVariant),
            ),
        ],
      ),
      textAlign: TextAlign.end,
    );
    final large = MediaQuery.textScalerOf(context).scale(14) >= 14 * 1.4;
    return MergeSemantics(
      child: large
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [name, amounts],
            )
          : Row(
              children: [
                Expanded(child: name),
                const SizedBox(width: FbSpace.s2),
                amounts,
              ],
            ),
    );
  }
}

/// The protein, fat and carbs shares of the day's energy as one bar, in
/// the macro colours; a screen reader hears the percentages.
class _ShareBar extends StatelessWidget {
  const new({required this.protein, required this.fat, required this.carbs});

  final double protein;
  final double fat;
  final double carbs;

  @override
  Widget build(BuildContext context) {
    final colors = context.fbColors;
    int percent(double share) => (share * 100).round();
    int flex(double share) => (share * 1000).round().clamp(1, 1000);
    return Semantics(
      label: context.l10n.targetsDailyShares(
        percent(protein),
        percent(fat),
        percent(carbs),
      ),
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: FbRadius.smAll,
        child: SizedBox(
          height: FbSpace.s2,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: flex(protein),
                child: ColoredBox(color: colors.protein),
              ),
              Expanded(
                flex: flex(fat),
                child: ColoredBox(color: colors.fat),
              ),
              Expanded(
                flex: flex(carbs),
                child: ColoredBox(color: colors.carbs),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
