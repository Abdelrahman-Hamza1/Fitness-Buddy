import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows [message] with an Undo action for 5 s (UX-030) and runs the undo of
/// [undoEntryId] when it is tapped. The one helper every direct action uses
/// (A08 D13), so they all treat the outcomes the same way:
/// - undone: nothing more to say (the lists show it);
/// - changed since: "Can't undo: it changed since." (nothing was written);
/// - too late: "Too late to undo.";
/// - unknown entry: nothing.
///
/// The snackbar lives on the root messenger, so it survives the screen that
/// started the action. [context] must be mounted now but may be gone when
/// Undo is tapped: the container and the root context are taken here. A row
/// that is about to leave the tree takes them before it does (the root
/// navigator's context, `Navigator.of(context, rootNavigator: true).context`,
/// outlives it).
///
/// [thenUndoEntryIds] are undone after [undoEntryId], in order, for one
/// message about several actions (A37c D21: "Workout saved, template
/// updated"); the first one that can't be undone stops the rest.
FbSnackBarHandle showUndoFeedback(
  BuildContext context, {
  required String message,
  required String undoEntryId,
  List<String> thenUndoEntryIds = const [],
}) {
  final container = ProviderScope.containerOf(context);
  final host = Navigator.of(context, rootNavigator: true).context;
  return showFbUndoSnackBar(
    host,
    message: message,
    onUndo: () =>
        unawaited(_undo(host, container, [undoEntryId, ...thenUndoEntryIds])),
  );
}

Future<void> _undo(
  BuildContext host,
  ProviderContainer container,
  List<String> undoEntryIds,
) async {
  final stack = container.read(undoStackProvider);
  var outcome = UndoOutcome.unknown;
  for (final id in undoEntryIds) {
    outcome = await stack.undo(id);
    if (outcome == UndoOutcome.conflict || outcome == UndoOutcome.expired) {
      break;
    }
  }
  if (!host.mounted) return;
  switch (outcome) {
    case UndoOutcome.undone || UndoOutcome.unknown:
      break;
    case UndoOutcome.conflict:
      showFbSnackBar(host, host.l10n.diaryUndoConflict);
    case UndoOutcome.expired:
      showFbSnackBar(host, host.l10n.diaryUndoExpired);
  }
}
