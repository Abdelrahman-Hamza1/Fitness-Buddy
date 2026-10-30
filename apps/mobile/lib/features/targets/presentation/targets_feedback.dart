import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/targets/presentation/targets_text.dart';
import 'package:flutter/widgets.dart';

/// The feedback of a finished targets command (UX-030, UX-052): a written
/// change shows [done]'s message with Undo; a refusal says why; a pending or
/// unchanged command says nothing. [host] is the root navigator's context
/// (it outlives the sheet that started the command).
void showTargetsFeedback(
  BuildContext host,
  TargetsOutcome outcome, {
  required String Function(TargetsDone done) done,
}) {
  if (!host.mounted) return;
  switch (outcome) {
    case TargetsDone():
      showUndoFeedback(
        host,
        message: done(outcome),
        undoEntryId: outcome.undoEntryId,
      );
    case TargetsFailed(:final reason):
      showFbSnackBar(host, targetsFailureText(host.l10n, reason));
    case TargetsPending() ||
        TargetsUnchanged() ||
        TargetsNeedsAcknowledgement():
      break;
  }
}

/// What a refused targets command tells the user (UX-052).
String targetsFailureText(AppLocalizations l10n, TargetsFailure reason) =>
    goalFailureText(l10n, reason) ??
    switch (reason) {
      TargetsFailure.changed ||
      TargetsFailure.removed => l10n.targetsChangedReload,
      _ => l10n.targetsSaveFailed,
    };

/// A recomputed target in a done message: "Target now 2,150 kcal a day."
/// variants pick it up; null when not recomputed.
int? recomputedKcalOf(TargetsDone done) => switch (done.recomputedKcal) {
  final kcal? => DisplayRounding.kcal(kcal),
  null => null,
};

/// The inline message of a refused save in a sheet (UX-052): what happened
/// and what to do; the sheet and everything typed stay, and Save can be
/// tried again. A row changed elsewhere ([TargetsFailure.changed] /
/// [TargetsFailure.removed]) offers [onReload] (load the row as it is now,
/// keeping the draft) when given.
class SaveFailedBanner extends StatelessWidget {
  /// The banner for [reason].
  const new({required this.reason, this.onReload, super.key});

  /// Why the save was refused.
  final TargetsFailure reason;

  /// Loads the current row, keeping what was typed.
  final VoidCallback? onReload;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stale =
        reason == TargetsFailure.changed || reason == TargetsFailure.removed;
    return FbInlineBanner(
      kind: stale ? FbInlineBannerKind.info : FbInlineBannerKind.error,
      message: targetsFailureText(l10n, reason),
      actionLabel: stale && onReload != null ? l10n.targetsReload : null,
      onAction: stale ? onReload : null,
    );
  }
}
