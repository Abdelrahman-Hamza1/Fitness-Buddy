import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/targets/application/target_form_input.dart';
import 'package:fb_mobile/features/targets/application/targets_actions.dart';
import 'package:fb_mobile/features/targets/application/targets_screens.dart';
import 'package:fb_mobile/features/targets/presentation/below_limit_screen.dart';
import 'package:fb_mobile/features/targets/presentation/targets_feedback.dart';
import 'package:fb_mobile/features/targets/presentation/targets_screen.dart'
    show weekdayName;
import 'package:fb_mobile/features/targets/presentation/typed_number_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

/// Opens the sheet that changes one weekday's number (D-090, sketch
/// `TgDay`): the day, a large number with − / + (50 kcal) that turns into
/// a field on tap, quick chips, "Every Friday. Suggested: … · your week
/// becomes …" and Save → `setDayTarget` with Undo. Below the floor the
/// full-screen warning asks first (A53 D4).
Future<void> showDayTargetSheet(
  BuildContext context, {
  required TargetsView view,
  required DayOfWeek weekday,
}) => showFbStatefulSheet<void>(
  context,
  builder: (_) => DayTargetSheet(view: view, weekday: weekday),
);

/// The body of the day sheet.
class DayTargetSheet extends ConsumerStatefulWidget {
  /// Changes [weekday] of [view]'s version.
  const new({required this.view, required this.weekday, super.key});

  /// What Targets showed.
  final TargetsView view;

  /// The day being changed.
  final DayOfWeek weekday;

  @override
  ConsumerState<DayTargetSheet> createState() => _DayTargetSheetState();
}

class _DayTargetSheetState extends ConsumerState<DayTargetSheet> {
  /// The chips' amounts, kcal, around the suggestion.
  static const List<int> _chips = [-250, 250, 500];

  /// One − / + step.
  static const int _step = 50;

  late TargetsView _view = widget.view;
  late String _text = '${DisplayRounding.kcal(_planned)}';
  bool _typing = false;
  bool _showErrors = false;
  bool _saving = false;
  TargetsFailure? _failure;

  double get _planned => _view.plannedKcal(widget.weekday);

  int get _suggested => DisplayRounding.kcal(_view.suggestionKcal);

  /// The accepted range: 500–10,000 kcal and 0.5–2× the suggestion,
  /// rounded inwards to 10 kcal.
  ({int min, int max}) get _range {
    final s = _view.suggestionKcal;
    final low = [
      TargetInputRules.minManualKcal,
      s * TargetLimits.minDayFactor,
    ].reduce((a, b) => a > b ? a : b);
    final high = [
      TargetInputRules.maxManualKcal,
      s * TargetLimits.maxDayFactor,
    ].reduce((a, b) => a < b ? a : b);
    return (min: (low / 10).ceil() * 10, max: (high / 10).floor() * 10);
  }

  /// The typed number when it is in range, else null.
  int? get _kcal {
    final number = parseTypedNumber(_text);
    if (number == null) return null;
    final kcal = number.round();
    final range = _range;
    return kcal < range.min || kcal > range.max ? null : kcal;
  }

  void _set(int kcal) => setState(() {
    final range = _range;
    _text = '${kcal.clamp(range.min, range.max)}';
    _failure = null;
  });

  Future<void> _save() async {
    final kcal = _kcal;
    if (kcal == null) {
      setState(() => _showErrors = true);
      return;
    }
    final nav = Navigator.of(context);
    // The number it already had: nothing to save.
    if (kcal == DisplayRounding.kcal(_planned)) {
      nav.pop();
      return;
    }
    final host = Navigator.of(context, rootNavigator: true).context;
    String doneText(TargetsDone _) => host.l10n.targetsUpdated;
    final actions = ref.read(targetsActionsProvider);
    final view = _view;
    final day = weekdayName(context.l10n, widget.weekday);
    Future<TargetsOutcome> run({bool acknowledged = false}) =>
        actions.setDayTarget(
          view.shown,
          widget.weekday,
          kcal.toDouble(),
          suggestionKcal: view.suggestionKcal,
          acknowledged: acknowledged,
        );
    setState(() {
      _saving = true;
      _failure = null;
    });
    var outcome = await run();
    if (outcome case final TargetsNeedsAcknowledgement need) {
      // Go back returns to the number as typed; nothing is written.
      if (!mounted || !host.mounted) return;
      final confirmed = await showBelowLimitScreen(
        host,
        kcal: kcal.toDouble(),
        need: need,
        units: view.units,
        weekday: day,
      );
      if (confirmed != true) {
        if (mounted) setState(() => _saving = false);
        return;
      }
      outcome = await run(acknowledged: true);
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

  /// Takes what Targets shows now; the number stays (UX-052).
  void _reload() => setState(() {
    _view = ref.read(targetsViewProvider).value ?? _view;
    _failure = null;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final day = weekdayName(l10n, widget.weekday);
    final kcal = _kcal;
    final shown = kcal ?? DisplayRounding.kcal(_planned);
    final range = _range;
    final number = NumberFormat.decimalPattern(l10n.localeName);
    return FbSheet(
      title: day,
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
            if (_typing)
              TypedNumberField(
                text: _text,
                label: l10n.targetsDayLabel(day),
                unit: l10n.targetsManualUnit,
                maxDecimals: 0,
                autofocus: true,
                textInputAction: TextInputAction.done,
                errorText: kcal == null
                    ? l10n.targetsDayRange(range.min, range.max)
                    : null,
                showError: _showErrors,
                onChanged: (text) => setState(() => _text = text),
              )
            else
              Row(
                children: [
                  FbIconButton(
                    icon: FbIcons.remove,
                    tooltip: l10n.targetsDayLess,
                    onPressed: shown - _step < range.min
                        ? null
                        : () => _set(shown - _step),
                  ),
                  Expanded(
                    child: InkWell(
                      key: const ValueKey('day-target-number'),
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
                            Text(
                              l10n.targetsDayTapToType,
                              style: FbType.bodySmall.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  FbIconButton(
                    icon: FbIcons.add,
                    tooltip: l10n.targetsDayMore,
                    onPressed: shown + _step > range.max
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
                FbChoiceChip(
                  label: l10n.targetsDayUsual(_suggested),
                  selected: kcal == _suggested,
                  dropdown: false,
                  onTap: () => _set(_suggested),
                ),
                for (final delta in _chips)
                  if (_suggested + delta >= range.min &&
                      _suggested + delta <= range.max)
                    FbChoiceChip(
                      label: delta < 0
                          ? l10n.targetsDayMinus(-delta)
                          : l10n.targetsDayPlus(delta),
                      selected: kcal == _suggested + delta,
                      dropdown: false,
                      onTap: () => _set(_suggested + delta),
                    ),
              ],
            ),
            Text(
              l10n.targetsDayLine(
                day,
                _suggested,
                DisplayRounding.kcal(
                  _view.weekTotalWith(widget.weekday, shown.toDouble()),
                ),
              ),
              textAlign: TextAlign.center,
              style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
