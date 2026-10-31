import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/account/application/sign_in_controller.dart';
import 'package:fb_mobile/features/account/presentation/sign_out_sheet.dart';
import 'package:fb_mobile/features/sync/sync.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Me › Account (A33): the account state, sign in/out, the sync line (A34)
/// and account deletion (A35). Export is in "Your data" (A11).
class AccountSection extends ConsumerWidget {
  /// Creates the section.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final status = ref.watch(accountStatusProvider).value;
    if (status == null) return const SizedBox.shrink();
    void openSignIn() =>
        ref.read(appNavigatorProvider).push(const SignInRoute());
    final actions = ref.read(accountActionsProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FbSectionHeader(title: l10n.meSectionAccount),
        FbListRow(
          title: switch (status) {
            AccountStatus.guest => l10n.accountGuest,
            AccountStatus.signedIn => l10n.accountSignedIn,
            AccountStatus.sessionExpired => l10n.accountSessionExpired,
            AccountStatus.readOnlyCopy => l10n.accountReadOnly,
          },
        ),
        if (status != AccountStatus.signedIn)
          FbListRow(
            title: status == AccountStatus.sessionExpired
                ? l10n.accountSignInAgain
                : l10n.accountSignIn,
            trailing: const Icon(FbIcons.next),
            onTap: openSignIn,
          ),
        if (status == AccountStatus.readOnlyCopy)
          FbListRow(
            title: l10n.accountContinueAsGuest,
            onTap: () => unawaited(actions.continueAsGuest()),
          ),
        if (status == AccountStatus.signedIn ||
            status == AccountStatus.sessionExpired)
          FbListRow(
            title: l10n.accountSignOut,
            onTap: () async {
              final choice = await showSignOutSheet(context);
              if (choice != null) await actions.signOut(choice);
            },
          ),
        // A34: the sync line for an account; A35: account deletion (a guest
        // deletes the data on this phone).
        if (status == AccountStatus.signedIn ||
            status == AccountStatus.sessionExpired)
          const SyncAccountRow(),
        if (status == AccountStatus.signedIn)
          FbListRow(
            key: const ValueKey('account-delete-row'),
            title: l10n.accountDeleteAccount,
            trailing: const Icon(FbIcons.next),
            onTap: () =>
                ref.read(appNavigatorProvider).push(const DeleteAccountRoute()),
          ),
        if (status == AccountStatus.guest)
          FbListRow(
            key: const ValueKey('account-delete-row'),
            title: l10n.accountDeleteLocal,
            trailing: const Icon(FbIcons.next),
            onTap: () =>
                ref.read(appNavigatorProvider).push(const DeleteAccountRoute()),
          ),
      ],
    );
  }
}
