import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/targets/application/targets_actions.dart';
import 'package:fb_mobile/features/targets/application/targets_providers.dart';
import 'package:fb_mobile/features/targets/application/targets_screens.dart';
import 'package:fb_mobile/features/targets/presentation/targets_feedback.dart';
import 'package:fb_mobile/features/targets/presentation/targets_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// "Past goals" (TG-012): each ended phase as "Lose weight" over
/// "3 Jan 2026 – 30 Apr 2026", newest first; a tap renames it. An empty
/// list says where finished goals will show (UX-050).
class PhaseHistory extends StatelessWidget {
  /// Lists [phases] (ended, newest first).
  const new({required this.phases, super.key});

  /// The ended phases.
  final List<Versioned<GoalPhaseRecord>> phases;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    if (phases.isEmpty) {
      return Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: FbSpace.s4,
          vertical: FbSpace.s2,
        ),
        child: Text(
          l10n.goalPastNone,
          style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final phase in phases)
          FbListRow(
            title: goalPhaseLabel(l10n, phase.value),
            subtitle: l10n.goalPastRange(
              shortDate(l10n, phase.value.start),
              shortDate(l10n, phase.value.end ?? phase.value.start),
            ),
            trailing: const Icon(FbIcons.edit),
            onTap: () => unawaited(showRenamePhaseSheet(context, phase)),
          ),
      ],
    );
  }
}

/// Opens the rename sheet of [phase] (TG-012): an empty name means the
/// default label; Save → `renamePhase` with Undo.
Future<void> showRenamePhaseSheet(
  BuildContext context,
  Versioned<GoalPhaseRecord> phase,
) => showFbSheet<void>(
  context,
  title: context.l10n.goalRenameTitle,
  builder: (_) => RenamePhaseSheet(phase: phase),
);

/// The body of the rename sheet.
class RenamePhaseSheet extends ConsumerStatefulWidget {
  /// Renames [phase] as shown.
  const new({required this.phase, super.key});

  /// The phase at the version shown.
  final Versioned<GoalPhaseRecord> phase;

  @override
  ConsumerState<RenamePhaseSheet> createState() => _RenamePhaseSheetState();
}

class _RenamePhaseSheetState extends ConsumerState<RenamePhaseSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.phase.value.name ?? '',
  );

  /// The row the name is saved against; Reload moves it to the stored
  /// row, keeping the typed name (UX-052).
  late Versioned<GoalPhaseRecord> _base = widget.phase;
  bool _saving = false;
  TargetsFailure? _failure;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? get _trimmed {
    final name = _name.text.trim();
    return name.isEmpty ? null : name;
  }

  bool get _valid => TargetRules.input.name(_trimmed);

  Future<void> _save() async {
    if (!_valid) return;
    final host = Navigator.of(context, rootNavigator: true).context;
    final nav = Navigator.of(context);
    String doneText(TargetsDone _) => host.l10n.goalRenamed;
    setState(() => _saving = true);
    final phase = _base;
    final outcome = await ref
        .read(targetsActionsProvider)
        .renamePhase(VersionedId(phase.value.id, phase.version), _trimmed);
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final defaultLabel = goalTypeLabel(l10n, _base.value.type);
    final stored = ref
        .watch(goalHistoryProvider)
        .value
        ?.recordOf(_base.value.id);
    final stale = stored != null && stored.version != _base.version;
    final failure = _failure ?? (stale ? TargetsFailure.changed : null);
    // A changed or removed row blocks Save until Reload; other refusals can
    // be retried as they are.
    final blocked =
        failure == TargetsFailure.changed || failure == TargetsFailure.removed;
    return Padding(
      // Lifts the sheet above the keyboard.
      padding: EdgeInsetsDirectional.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s3,
        children: [
          FbTextField(
            controller: _name,
            label: l10n.goalNameLabel,
            hint: l10n.goalNameHint(defaultLabel),
            maxLength: TargetInputRules.maxNameLength,
            autofocus: true,
            textInputAction: TextInputAction.done,
            errorText: _valid ? null : l10n.goalNameRange,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => unawaited(_save()),
          ),
          if (failure case final reason?)
            SaveFailedBanner(
              reason: reason,
              onReload: stored == null
                  ? null
                  : () => setState(() {
                      // The stored row becomes the base; the typed name
                      // stays.
                      _base = stored;
                      _failure = null;
                    }),
            ),
          FbButton.primary(
            label: l10n.targetsSave,
            expand: true,
            onPressed: !_valid || _saving || blocked
                ? null
                : () => unawaited(_save()),
          ),
        ],
      ),
    );
  }
}
