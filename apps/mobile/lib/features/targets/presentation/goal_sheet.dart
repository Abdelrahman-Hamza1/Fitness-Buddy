import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/targets/application/setup_input.dart';
import 'package:fb_mobile/features/targets/application/target_form_input.dart';
import 'package:fb_mobile/features/targets/application/targets_actions.dart';
import 'package:fb_mobile/features/targets/application/targets_providers.dart';
import 'package:fb_mobile/features/targets/application/targets_screens.dart';
import 'package:fb_mobile/features/targets/presentation/goal_form.dart';
import 'package:fb_mobile/features/targets/presentation/targets_feedback.dart';
import 'package:fb_mobile/features/targets/presentation/targets_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the goal sheet (D13, TG-010/011): with [edit] it changes that
/// phase's goal (`saveGoal`); without, it starts a new goal from today
/// (`startPhase`; the current goal ends yesterday, TG-012). The live line
/// and the PA3 message come from the engine at [view]'s weight.
Future<void> showGoalSheet(
  BuildContext context, {
  required ProfileGoalView view,
  Versioned<GoalPhaseRecord>? edit,
}) => showFbStatefulSheet<void>(
  context,
  builder: (_) => GoalSheet(view: view, edit: edit),
);

/// The body of the goal sheet.
class GoalSheet extends ConsumerStatefulWidget {
  /// Edits [edit], or starts a new goal when null.
  const new({required this.view, this.edit, super.key});

  /// What Profile & goal showed.
  final ProfileGoalView view;

  /// The phase to edit, at the version shown; null for a new goal.
  final Versioned<GoalPhaseRecord>? edit;

  @override
  ConsumerState<GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends ConsumerState<GoalSheet> {
  late Versioned<GoalPhaseRecord>? _base = widget.edit;
  late GoalDraft _draft = switch (widget.edit) {
    final edit? => goalDraftOf(edit.value),
    null => GoalDraft(unit: widget.view.units.bodyMass),
  };
  bool _showErrors = false;
  bool _saving = false;
  bool _refused = false;
  TargetsFailure? _failure;

  LocalDate get _today => widget.view.today;

  GoalInput? get _input => _draft.read(_today).input;

  GoalProblem? get _problem {
    final input = _input;
    final kg = widget.view.weightKg;
    if (input == null || kg == null) return null;
    return GoalProblem.of(input, currentKg: kg, today: _today);
  }

  TargetCalculation? get _calculation {
    final input = _input;
    final kg = widget.view.weightKg;
    if (input == null || kg == null || _problem != null) return null;
    return goalPreviewOf(
      widget.view.profile.value,
      kg,
      input,
      _today,
    ).calculation;
  }

  Future<void> _save() async {
    final input = _input;
    if (input == null || _problem != null) {
      setState(() => _showErrors = true);
      return;
    }
    final host = Navigator.of(context, rootNavigator: true).context;
    final nav = Navigator.of(context);
    String doneText(TargetsDone done) {
      final l10n = host.l10n;
      return switch ((done.kind, recomputedKcalOf(done))) {
        (TargetsChangeKind.phaseStarted, final kcal?) => l10n.goalStartedTarget(
          kcal,
        ),
        (TargetsChangeKind.phaseStarted, null) => l10n.goalStarted,
        (_, final kcal?) => l10n.goalUpdatedTarget(kcal),
        (_, null) => l10n.goalUpdated,
      };
    }

    final actions = ref.read(targetsActionsProvider);
    setState(() {
      _saving = true;
      _failure = null;
    });
    final base = _base;
    final outcome = base == null
        ? await actions.startPhase(input)
        : await actions.saveGoal(
            input,
            VersionedId(base.value.id, base.version),
          );
    if (!mounted) {
      // Dismissed during Save: the result, Undo included, still shows on
      // the root messenger (UX-030).
      if (host.mounted) showTargetsFeedback(host, outcome, done: doneText);
      return;
    }
    setState(() => _saving = false);
    switch (outcome) {
      // A refusal keeps the sheet and what was typed (UX-052).
      case TargetsFailed(reason: TargetsFailure.changed):
        setState(() => _refused = true);
        return;
      case TargetsFailed(:final reason):
        setState(() => _failure = reason);
        return;
      case TargetsPending() || TargetsNeedsAcknowledgement():
        return;
      case TargetsDone() || TargetsUnchanged():
        nav.pop();
    }
    if (!host.mounted) return;
    showTargetsFeedback(host, outcome, done: doneText);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final base = _base;
    Versioned<GoalPhaseRecord>? stored;
    if (base != null) {
      stored = ref.watch(goalHistoryProvider).value?.recordOf(base.value.id);
    }
    final stale =
        _refused || (stored != null && stored.version != base!.version);
    return FbSheet(
      title: base == null ? l10n.goalStartTitle : l10n.goalEditTitle,
      actions: FbButton.primary(
        label: l10n.targetsSave,
        expand: true,
        onPressed: stale || _saving ? null : () => unawaited(_save()),
      ),
      child: Padding(
        // Lifts the sheet above the keyboard.
        padding: EdgeInsetsDirectional.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FbSpace.s3,
          children: [
            if (stale)
              FbInlineBanner(
                kind: FbInlineBannerKind.info,
                message: l10n.targetsChangedReload,
                actionLabel: l10n.targetsReload,
                onAction: stored == null
                    ? null
                    : () => setState(() {
                        // What was typed stays (UX-052).
                        _base = stored;
                        _refused = false;
                      }),
              ),
            Text(
              base == null
                  ? l10n.goalStartNote
                  : l10n.goalEditNote(shortDate(l10n, base.value.start)),
              style: FbType.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (_failure case final reason?) SaveFailedBanner(reason: reason),
            GoalForm(
              draft: _draft,
              onChanged: (draft) => setState(() => _draft = draft),
              today: _today,
              calculation: _calculation,
              problem: _problem,
              showErrors: _showErrors,
            ),
          ],
        ),
      ),
    );
  }
}
