import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/account/application/sign_in_controller.dart';
import 'package:fb_mobile/features/account/presentation/sign_out_sheet.dart';
import 'package:fb_mobile/features/sync/sync.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The account card at the top of Me and of Me › Account & data (A33,
/// A51 D7): a guest sees "Data on this phone only, not backed up" and Sign
/// in; an account sees its backup state (the sync line, A34). No email or
/// name: the phone keeps none (A33). Nothing while the status loads.
class AccountCard extends ConsumerWidget {
  /// Creates the card.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final status = ref.watch(accountStatusProvider).value;
    if (status == null) return const SizedBox.shrink();
    final signedIn = status == AccountStatus.signedIn;
    final (title, detail) = switch (status) {
      AccountStatus.guest => (l10n.meGuest, l10n.meGuestDetail),
      AccountStatus.signedIn => (
        l10n.accountSignedIn,
        syncStatusText(l10n, ref.watch(syncViewProvider)),
      ),
      AccountStatus.sessionExpired => (
        l10n.accountSignedIn,
        l10n.accountSessionExpired,
      ),
      AccountStatus.readOnlyCopy => (l10n.meReadOnly, l10n.accountReadOnly),
    };
    final action = signedIn
        ? null
        : FbButton.secondary(
            label: status == AccountStatus.sessionExpired
                ? l10n.accountSignInAgain
                : l10n.meSignIn,
            onPressed: () =>
                ref.read(appNavigatorProvider).push(const SignInRoute()),
          );
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final text = MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(
            title,
            style: FbType.body.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            detail,
            style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
    final badge = ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: signedIn ? scheme.primaryContainer : scheme.surfaceContainer,
          shape: BoxShape.circle,
        ),
        child: SizedBox.square(
          dimension: 44,
          child: Icon(
            signedIn ? FbIcons.backedUp : FbIcons.phoneOnly,
            color: signedIn
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
    return FbCard(
      key: const ValueKey('account-card'),
      padding: const EdgeInsetsDirectional.all(FbSpace.s4),
      child: large
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: FbSpace.s3,
              children: [
                Row(
                  spacing: FbSpace.s3,
                  children: [
                    badge,
                    Expanded(child: text),
                  ],
                ),
                ?action,
              ],
            )
          : Row(
              spacing: FbSpace.s3,
              children: [
                badge,
                Expanded(child: text),
                ?action,
              ],
            ),
    );
  }
}

/// Me › Account & data's routine account rows (A33, A34): the sync line
/// for an account, "Continue as guest" for a read-only copy and Sign out.
/// Empty for a guest.
class AccountRows extends ConsumerWidget {
  /// Creates the rows.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final status = ref.watch(accountStatusProvider).value;
    if (status == null) return const SizedBox.shrink();
    final actions = ref.read(accountActionsProvider.notifier);
    final account =
        status == AccountStatus.signedIn ||
        status == AccountStatus.sessionExpired;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (account) const SyncAccountRow(),
        if (status == AccountStatus.readOnlyCopy)
          FbListRow(
            title: l10n.accountContinueAsGuest,
            onTap: () => unawaited(actions.continueAsGuest()),
          ),
        if (account)
          FbListRow(
            title: l10n.accountSignOut,
            onTap: () async {
              final choice = await showSignOutSheet(context);
              if (choice != null) await actions.signOut(choice);
            },
          ),
      ],
    );
  }
}

/// The deletion row (A35), kept apart at the bottom of Me › Account &
/// data: an account deletes the account; a guest deletes the data on this
/// phone.
class AccountDeleteRow extends ConsumerWidget {
  /// Creates the row.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final status = ref.watch(accountStatusProvider).value;
    final title = switch (status) {
      AccountStatus.signedIn => l10n.accountDeleteAccount,
      AccountStatus.guest => l10n.accountDeleteLocal,
      _ => null,
    };
    if (title == null) return const SizedBox.shrink();
    return FbListRow(
      key: const ValueKey('account-delete-row'),
      title: title,
      leading: Icon(FbIcons.delete, color: Theme.of(context).colorScheme.error),
      trailing: const Icon(FbIcons.next),
      onTap: () =>
          ref.read(appNavigatorProvider).push(const DeleteAccountRoute()),
    );
  }
}
