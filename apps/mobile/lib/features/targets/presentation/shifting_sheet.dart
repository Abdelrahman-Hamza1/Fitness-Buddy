import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/targets/application/targets_actions.dart';
import 'package:fb_mobile/features/targets/application/targets_screens.dart';
import 'package:fb_mobile/features/targets/presentation/targets_feedback.dart';
import 'package:fb_mobile/features/targets/presentation/targets_screen.dart'
    show ShiftLevel, weekdayName;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Opens Higher-calorie days (TG-043, D14): each weekday Usual / A little
/// more (1.15) / More (1.3), with each day's planned target previewed by
/// the engine (the weekly total stays the same). Save → `setShifting`.
Future<void> showShiftingSheet(
  BuildContext context, {
  required TargetsView view,
}) => showFbStatefulSheet<void>(
  context,
  builder: (_) => ShiftingSheet(view: view),
);

/// The body of the higher-calorie days sheet.
class ShiftingSheet extends ConsumerStatefulWidget {
  /// Edits the shifts of [view]'s version.
  const new({required this.view, super.key});

  /// What Targets showed.
  final TargetsView view;

  @override
  ConsumerState<ShiftingSheet> createState() => _ShiftingSheetState();
}

class _ShiftingSheetState extends ConsumerState<ShiftingSheet> {
  /// What the sheet is based on: Targets' view when it opened, or the
  /// current one after Reload.
  late TargetsView _view = widget.view;

  /// The weekdays the user changed, with the chosen weight (null: usual);
  /// only these are submitted, and they survive Reload.
  final Map<DayOfWeek, double?> _drafts = {};
  bool _saving = false;
  TargetsFailure? _failure;

  /// Each shifted day's weight: the stored one, exactly (a synced 1.8 stays
  /// 1.8), with the user's changes on top.
  Map<DayOfWeek, double> get _weights {
    final weights = {..._view.version.shifts};
    for (final MapEntry(key: day, value: weight) in _drafts.entries) {
      if (weight == null) {
        weights.remove(day);
      } else {
        weights[day] = weight;
      }
    }
    return weights;
  }

  void _pick(DayOfWeek day, ShiftLevel level) => setState(
    () => _drafts[day] = level == ShiftLevel.usual ? null : level.weight,
  );

  Future<void> _save() async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final nav = Navigator.of(context);
    String doneText(TargetsDone _) => host.l10n.targetsUpdated;
    if (_drafts.isEmpty) {
      nav.pop();
      return;
    }
    setState(() {
      _saving = true;
      _failure = null;
    });
    final outcome = await ref.read(targetsActionsProvider).setShifting(
      _view.shown,
      {..._drafts},
    );
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

  /// Takes the settings Targets shows now: the preview and the untouched
  /// days follow them, the changed days stay as chosen (UX-052).
  void _reload() => setState(() {
    _view = ref.read(targetsViewProvider).value ?? _view;
    _failure = null;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final view = _view;
    final weights = _weights;
    final planned = view.plannedWith(weights);
    final start = view.calendar.weekStartOf(view.today);
    return FbSheet(
      title: l10n.targetsShifting,
      actions: FbButton.primary(
        label: l10n.targetsSave,
        expand: true,
        onPressed: _saving ? null : () => unawaited(_save()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s4,
        children: [
          if (_failure case final reason?)
            SaveFailedBanner(reason: reason, onReload: _reload),
          Text(
            l10n.targetsShiftingHint,
            style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
          ),
          for (var i = 0; i < 7; i++)
            _DayRow(
              label: weekdayName(l10n, start.plusDays(i).weekday),
              kcal: planned[start.plusDays(i)],
              level: ShiftLevel.of(weights[start.plusDays(i).weekday]),
              onSelected: (level) => _pick(start.plusDays(i).weekday, level),
            ),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const new({
    required this.label,
    required this.kcal,
    required this.level,
    required this.onSelected,
  });

  final String label;
  final double? kcal;
  final ShiftLevel level;
  final ValueChanged<ShiftLevel> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s2,
      children: [
        Text(
          kcal == null
              ? label
              : l10n.targetsShiftDayPlanned(label, DisplayRounding.kcal(kcal!)),
          style: FbType.numeric(FbType.label).copyWith(color: scheme.onSurface),
        ),
        Wrap(
          spacing: FbSpace.s2,
          runSpacing: FbSpace.s2,
          children: [
            for (final (option, text) in [
              (ShiftLevel.usual, l10n.targetsShiftNormal),
              (ShiftLevel.little, l10n.targetsShiftLittle),
              (ShiftLevel.more, l10n.targetsShiftMore),
            ])
              FbChoiceChip(
                label: text,
                selected: level == option,
                dropdown: false,
                onTap: () => onSelected(option),
              ),
          ],
        ),
      ],
    );
  }
}
