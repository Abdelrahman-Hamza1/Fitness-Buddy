import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/account/account_service.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// The sign-out choices (AC-004): keep a read-only copy or remove it.
List<FbOption<SignOutChoice>> signOutOptions(BuildContext context) {
  final l10n = context.l10n;
  return [
    FbOption(
      value: SignOutChoice.keep,
      label: l10n.accountSignOutKeep,
      subtitle: l10n.accountSignOutKeepDetail,
    ),
    FbOption(
      value: SignOutChoice.remove,
      label: l10n.accountSignOutRemove,
      subtitle: l10n.accountSignOutRemoveDetail,
    ),
  ];
}

/// The sign-out sheet's content, on its own for goldens.
class SignOutSheetBody extends StatelessWidget {
  /// Calls [onSelected] with the choice.
  const new({required this.onSelected, super.key});

  /// The chosen option.
  final ValueChanged<SignOutChoice> onSelected;

  @override
  Widget build(BuildContext context) => FbOptionList<SignOutChoice>(
    options: signOutOptions(context),
    selected: null,
    onSelected: onSelected,
  );
}

/// Asks how to sign out (AC-004); `null` when dismissed.
Future<SignOutChoice?> showSignOutSheet(BuildContext context) =>
    showFbSheet<SignOutChoice>(
      context,
      title: context.l10n.accountSignOut,
      builder: (context) => SignOutSheetBody(
        onSelected: (choice) => Navigator.of(context).pop(choice),
      ),
    );
