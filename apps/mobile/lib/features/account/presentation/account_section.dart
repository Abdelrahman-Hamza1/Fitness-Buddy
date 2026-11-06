import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/account/local_identity_store.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/account/application/local_identity.dart';
import 'package:fb_mobile/features/account/application/sign_in_controller.dart';
import 'package:fb_mobile/features/account/presentation/sign_out_sheet.dart';
import 'package:fb_mobile/features/sync/sync.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The account card at the top of Me and of Me › Account & data (A33,
/// A51 D7, M1 A, AC-005): who is signed in. An account shows a letter
/// circle, its name (or email), the email under a name, and its state (the
/// sync line, A34; expired; read-only); without a stored identity (signed
/// in before A63) it says "Signed in". A guest sees "Guest", "Data on this
/// phone only, not backed up" and Sign in. The name and email are this
/// phone's only (TD-115). With [onTap] (on Me) the whole card opens
/// Account & data. A card-shaped placeholder while the status loads (A57
/// A11), and a failed read says so with Try again (A63 D11).
class AccountCard extends ConsumerWidget {
  /// Creates the card.
  const new({this.onTap, super.key});

  /// Opens Account & data; `null` on that page itself.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final statusAsync = ref.watch(accountStatusProvider);
    final status = statusAsync.value;
    if (status == null) {
      if (statusAsync.hasError) {
        return FbInlineBanner(
          key: const ValueKey('account-card-error'),
          kind: FbInlineBannerKind.error,
          message: l10n.accountLoadFailed,
          actionLabel: l10n.commonTryAgain,
          onAction: () => ref.invalidate(accountStatusProvider),
        );
      }
      return const _AccountCardSkeleton();
    }
    final guest = status == AccountStatus.guest;
    final who = guest ? null : ref.watch(meIdentityProvider).value?.identity;
    final name = who?.name;
    final email = who?.email;
    final signedIn = status == AccountStatus.signedIn;
    final stateLine = switch (status) {
      AccountStatus.guest => l10n.meGuestDetail,
      AccountStatus.signedIn => syncStatusText(
        l10n,
        ref.watch(syncViewProvider),
      ),
      AccountStatus.sessionExpired => l10n.accountSessionExpired,
      AccountStatus.readOnlyCopy => l10n.accountReadOnly,
    };
    final title =
        name ??
        email ??
        switch (status) {
          AccountStatus.guest => l10n.meGuest,
          AccountStatus.readOnlyCopy => l10n.meReadOnly,
          _ => l10n.accountSignedIn,
        };
    final lines = [if (name != null && email != null) email, stateLine];
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
        spacing: FbSize.lineGap,
        children: [
          Text(
            title,
            key: const ValueKey('account-card-title'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FbType.body.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          for (final line in lines)
            Text(
              line,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
    final letterSource = name ?? email;
    final badge = letterSource != null
        ? FbLetterAvatar(
            key: const ValueKey('account-card-letter'),
            source: letterSource,
            size: FbSize.avatar,
          )
        : ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: guest
                    ? scheme.surfaceContainer
                    : scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: FbSize.avatar,
                child: Icon(
                  guest ? FbIcons.me : FbIcons.backedUp,
                  color: guest
                      ? scheme.onSurfaceVariant
                      : scheme.onPrimaryContainer,
                ),
              ),
            ),
          );
    final chevron = onTap == null
        ? null
        : Icon(FbIcons.next, color: scheme.onSurfaceVariant);
    return FbCard(
      key: const ValueKey('account-card'),
      padding: const EdgeInsetsDirectional.all(FbSpace.s4),
      onTap: onTap,
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
                    ?chevron,
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
                ?chevron,
              ],
            ),
    );
  }
}

/// Me › Account & data's name row (M2, AC-005): the name shown on Me, for
/// an account; a tap edits it in a sheet (clear = remove). Kept on this
/// phone only (TD-115).
class AccountNameRow extends ConsumerWidget {
  /// Creates the row.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(meIdentityProvider).value;
    if (current == null) return const SizedBox.shrink();
    final name = current.identity.name;
    return FbListRow(
      key: const ValueKey('account-name'),
      leading: const Icon(FbIcons.me),
      title: l10n.accountName,
      subtitle: name ?? l10n.accountNameAdd,
      trailing: const Icon(FbIcons.next),
      onTap: () => unawaited(editAccountName(context, ref, name)),
    );
  }
}

/// Edits the name shown on Me in a sheet (M2, AC-005), from [name]; also
/// Today's one-time prompt after a sign-in that switched profiles.
Future<void> editAccountName(
  BuildContext context,
  WidgetRef ref,
  String? name,
) async {
  final l10n = context.l10n;
  final saved = await showFbSheet<String>(
    context,
    title: l10n.accountName,
    builder: (sheet) => _NameSheet(initial: name ?? ''),
  );
  if (saved == null) return;
  final ok = await ref.read(meIdentityProvider.notifier).setName(saved);
  if (!context.mounted) return;
  // Feedback either way (A65 m11).
  showFbSnackBar(
    context,
    ok ? context.l10n.accountNameSaved : context.l10n.accountNameSaveFailed,
  );
}

/// The name field and Save; pops with the typed text.
class _NameSheet extends StatefulWidget {
  const new({required this.initial});

  final String initial;

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial,
  )..addListener(_changed);

  /// Save is off until the name differs from the stored one (A65 m11);
  /// clearing a stored name still saves (it removes the name).
  bool get _dirty => _name.text.trim() != widget.initial.trim();

  void _changed() => setState(() {});

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        FbTextField(
          key: const ValueKey('account-name-field'),
          controller: _name,
          label: l10n.signInNameLabel,
          supportingText: l10n.signInNameHint,
          maxLength: LocalIdentity.nameMax,
          keyboardType: TextInputType.name,
          autofocus: true,
        ),
        FbButton.primary(
          key: const ValueKey('account-name-save'),
          label: l10n.accountNameSave,
          expand: true,
          onPressed: _dirty
              ? () => Navigator.of(context).pop(_name.text)
              : null,
        ),
      ],
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
            leading: const Icon(FbIcons.me),
            title: l10n.accountContinueAsGuest,
            onTap: () => unawaited(actions.continueAsGuest()),
          ),
        if (account)
          FbListRow(
            key: const ValueKey('account-sign-out'),
            leading: const Icon(FbIcons.signOut),
            title: l10n.accountSignOut,
            onTap: () => unawaited(runSignOut(context, actions)),
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

/// The account card's shape while its status loads: the badge and two
/// text lines at the current text scale.
class _AccountCardSkeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return FbCard(
      key: const ValueKey('account-card-loading'),
      padding: const EdgeInsetsDirectional.all(FbSpace.s4),
      child: Row(
        spacing: FbSpace.s3,
        children: [
          const FbSkeleton.box(
            width: FbSize.avatar,
            height: FbSize.avatar,
            radius: FbSize.avatar / 2,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: FbSpace.s2,
              children: [
                FbSkeleton.line(width: 140, height: scaler.scale(16)),
                FbSkeleton.line(height: scaler.scale(13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
