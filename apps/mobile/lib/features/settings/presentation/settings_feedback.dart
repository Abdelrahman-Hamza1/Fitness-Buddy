import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/settings/application/settings_actions.dart';
import 'package:flutter/widgets.dart';

/// Says what a settings command did: the Undo snackbar with [done]'s text
/// (UX-030), or a calm sentence for a refusal. A value that is already set
/// and a command already running need no message; nothing else is silent.
void reportSettingsOutcome(
  BuildContext host,
  SettingsOutcome outcome,
  String Function() done,
) {
  switch (outcome) {
    case SettingsDone(:final undoEntryId):
      showUndoFeedback(host, message: done(), undoEntryId: undoEntryId);
    case SettingsUnchanged() || SettingsPending():
      break;
    case SettingsFailed():
      showFbSnackBar(host, host.l10n.settingsSaveFailed);
  }
}
