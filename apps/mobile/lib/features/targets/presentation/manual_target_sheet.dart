import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/targets/application/target_form_input.dart';
import 'package:fb_mobile/features/targets/application/targets_actions.dart';
import 'package:fb_mobile/features/targets/application/targets_screens.dart';
import 'package:fb_mobile/features/targets/presentation/below_limit_screen.dart';
import 'package:fb_mobile/features/targets/presentation/targets_feedback.dart';
import 'package:fb_mobile/features/targets/presentation/typed_number_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Targets' "Your own target" section (D14, SF-012): "Set my own target"
/// and, for a manual target, "Use the calculated target".
class ManualTargetSection extends ConsumerWidget {
  /// The section for [view].
  const new({required this.view, super.key});

  /// What Targets shows.
  final TargetsView view;

  Future<void> _useCalculated(BuildContext context, WidgetRef ref) async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final outcome = await ref
        .read(targetsActionsProvider)
        .useCalculatedTarget(view.shown);
    if (!host.mounted) return;
    showTargetsFeedback(host, outcome, done: (_) => host.l10n.targetsUpdated);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FbSectionHeader(title: l10n.targetsSectionOwn),
        FbListRow(
          title: l10n.targetsSetOwn,
          subtitle: l10n.targetsSetOwnHint,
          trailing: const Icon(FbIcons.next),
          onTap: () => unawaited(showManualTargetSheet(context, view: view)),
        ),
        if (view.version.manual)
          FbListRow(
            title: l10n.targetsUseCalculated,
            onTap: () => unawaited(_useCalculated(context, ref)),
          ),
      ],
    );
  }
}

/// Opens the manual target sheet (D11, D14): a number from 500 to 10,000
/// kcal. Within the limits it applies with Undo; below the floor or beyond
/// the 1%/week loss rate the full-screen warning asks for an explicit
/// acknowledgement first (SF-011, SF-012), and Go back writes nothing.
Future<void> showManualTargetSheet(
  BuildContext context, {
  required TargetsView view,
}) => showFbStatefulSheet<void>(
  context,
  builder: (_) => ManualTargetSheet(view: view),
);

/// The body of the manual target sheet.
class ManualTargetSheet extends ConsumerStatefulWidget {
  /// Sets a manual target over [view]'s version.
  const new({required this.view, super.key});

  /// What Targets showed.
  final TargetsView view;

  @override
  ConsumerState<ManualTargetSheet> createState() => _ManualTargetSheetState();
}

class _ManualTargetSheetState extends ConsumerState<ManualTargetSheet> {
  late String _text = widget.view.version.manual
      ? '${DisplayRounding.kcal(widget.view.version.baseKcal)}'
      : '';
  bool _showErrors = false;
  bool _saving = false;
  TargetsFailure? _failure;
  late VersionedId _shown = widget.view.shown;

  double? get _kcal {
    final number = parseTypedNumber(_text);
    if (number == null || !TargetRules.input.manualKcal(number)) return null;
    return number.roundToDouble();
  }

  Future<void> _apply() async {
    final kcal = _kcal;
    if (kcal == null) {
      setState(() => _showErrors = true);
      return;
    }
    final host = Navigator.of(context, rootNavigator: true).context;
    final nav = Navigator.of(context);
    String doneText(TargetsDone _) => host.l10n.targetsUpdated;
    final actions = ref.read(targetsActionsProvider);
    final shown = _shown;
    setState(() {
      _saving = true;
      _failure = null;
    });
    var outcome = await actions.setManualTarget(shown, kcal);
    if (outcome case final TargetsNeedsAcknowledgement need) {
      // The warning opens over the sheet: Go back returns to the number
      // as typed, and nothing is written (SF-012).
      if (!mounted || !host.mounted) return;
      final confirmed = await showBelowLimitScreen(
        host,
        kcal: kcal,
        need: need,
        units: widget.view.units,
      );
      if (confirmed != true) {
        if (mounted) setState(() => _saving = false);
        return;
      }
      outcome = await actions.setManualTarget(shown, kcal, acknowledged: true);
    }
    if (!mounted) {
      // Dismissed during Save: the result, Undo included, still shows on
      // the root messenger (UX-030).
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

  /// Takes the version Targets shows now; the number stays (UX-052).
  void _reload() => setState(() {
    _shown = ref.read(targetsViewProvider).value?.shown ?? _shown;
    _failure = null;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FbSheet(
      title: l10n.targetsSetOwn,
      actions: FbButton.primary(
        label: l10n.targetsManualApply,
        expand: true,
        onPressed: _saving ? null : () => unawaited(_apply()),
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
            if (_failure case final reason?)
              SaveFailedBanner(reason: reason, onReload: _reload),
            TypedNumberField(
              text: _text,
              label: l10n.targetsManualLabel,
              unit: l10n.targetsManualUnit,
              maxDecimals: 0,
              errorText: _kcal == null ? l10n.targetsManualRange : null,
              showError: _showErrors,
              onChanged: (text) => setState(() => _text = text),
            ),
          ],
        ),
      ),
    );
  }
}
