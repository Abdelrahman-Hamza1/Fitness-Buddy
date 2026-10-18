import 'package:fb_design_system/l10n/gen/fb_localizations.dart';
import 'package:fb_design_system/src/tokens/motion.dart';
import 'package:material_ui/material_ui.dart';

/// Lets the caller dismiss a snackbar early without triggering its action.
class FbSnackBarHandle {
  new _(this._controller);

  final ScaffoldFeatureController<SnackBar, SnackBarClosedReason> _controller;

  /// Dismisses the snackbar. Never calls the undo callback.
  void close() => _controller.close();

  /// Completes when the snackbar is gone.
  Future<void> get closed => _controller.closed;
}

/// Shows the undo snackbar (UX-030): [message] and an "Undo" action that
/// calls [onUndo] at most once. Stays for [duration] (5 s), except under
/// `MediaQuery.accessibleNavigation` (TalkBack), where it stays until
/// dismissed (WCAG 2.2.1).
///
/// Replaces any snackbar currently shown. A tap after the data layer's undo
/// window closed is the caller's to handle ("can't undo anymore").
FbSnackBarHandle showFbUndoSnackBar(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
  Duration duration = FbMotion.undoWindow,
}) {
  var used = false;
  // Since Flutter 3.4x a snackbar with an action persists unless told
  // otherwise, so the 5 s window must be asked for. Screen-reader users get
  // no timeout (WCAG 2.2.1): they have no way to reach Undo in 5 s.
  final persist = MediaQuery.accessibleNavigationOf(context);
  final messenger = ScaffoldMessenger.of(context)..removeCurrentSnackBar();
  final controller = messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      persist: persist,
      action: SnackBarAction(
        label: FbLocalizations.of(context).fbUndo,
        onPressed: () {
          if (used) return;
          used = true;
          onUndo();
        },
      ),
    ),
  );
  return FbSnackBarHandle._(controller);
}

/// Shows a plain [message] snackbar with no action. Like the undo snackbar,
/// it stays until dismissed under `MediaQuery.accessibleNavigation`.
FbSnackBarHandle showFbSnackBar(BuildContext context, String message) {
  final persist = MediaQuery.accessibleNavigationOf(context);
  final messenger = ScaffoldMessenger.of(context)..removeCurrentSnackBar();
  return FbSnackBarHandle._(
    messenger.showSnackBar(SnackBar(content: Text(message), persist: persist)),
  );
}
