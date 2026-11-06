import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/account/application/account_removed_note.dart';
import 'package:fb_mobile/features/account/application/guest_prompt.dart';
import 'package:fb_mobile/features/account/application/local_identity.dart';
import 'package:fb_mobile/features/account/application/sign_in_controller.dart';
import 'package:fb_mobile/features/account/presentation/account_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The account line on Today (A33): "session expired, sign in again" for a
/// registered account whose session ended (A20 `sessionExpired`), a note on
/// a read-only kept copy (AC-004), the one-time name prompt after an email
/// sign-in whose switch closed the sign-in screen (M2, A63 review), or the
/// gentle guest prompt (AC-002).
/// Renders nothing otherwise; never blocks the day.
///
/// It starts watching only after the frame it first appears in, so its
/// preference reads never run before (or during) the first frame (UX-001).
class AccountTodayBanner extends ConsumerStatefulWidget {
  /// Creates the banner.
  const new({super.key});

  @override
  ConsumerState<AccountTodayBanner> createState() => _AccountTodayBannerState();
}

class _AccountTodayBannerState extends ConsumerState<AccountTodayBanner> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    final l10n = context.l10n;
    final navigator = ref.read(appNavigatorProvider);
    void signIn() => navigator.push(const SignInRoute());
    final removed = ref.watch(accountRemovedNoteProvider).value;
    if (removed != null) {
      // Once, on the new guest's Today after a deletion (#241).
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: FbSpace.s3),
        child: FbInlineBanner(
          key: const ValueKey('account-removed-note'),
          kind: FbInlineBannerKind.info,
          message: switch (removed) {
            AccountRemovedKind.account => l10n.accountRemovedNoteAccount,
            AccountRemovedKind.local => l10n.accountRemovedNoteLocal,
          },
          actionLabel: l10n.accountRemovedNoteOk,
          onAction: ref.read(accountRemovedNoteProvider.notifier).dismiss,
          actionBelow: true,
        ),
      );
    }
    final recent = ref.watch(recentSignInProvider);
    if (recent != null && recent.askName) {
      final who = ref.watch(meIdentityProvider).value;
      if (who != null &&
          who.profileKey == recent.profileKey &&
          who.identity.name == null) {
        final asked = ref.read(recentSignInProvider.notifier).nameAsked;
        return Padding(
          padding: const EdgeInsetsDirectional.only(top: FbSpace.s3),
          child: FbNoticeRow(
            key: const ValueKey('sign-in-name-prompt'),
            icon: FbIcons.me,
            text: l10n.signInNameLabel,
            actionLabel: l10n.accountNameAdd,
            actionKey: const ValueKey('sign-in-name-prompt-add'),
            onAction: () {
              asked();
              unawaited(editAccountName(context, ref, null));
            },
            dismissTooltip: l10n.guestPromptNotNow,
            onDismiss: asked,
          ),
        );
      }
    }
    final status = ref.watch(accountStatusProvider).value;
    if (status == AccountStatus.sessionExpired ||
        status == AccountStatus.readOnlyCopy) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: FbSpace.s3),
        child: FbInlineBanner(
          kind: FbInlineBannerKind.info,
          message: status == AccountStatus.sessionExpired
              ? l10n.accountSessionExpired
              : l10n.accountReadOnly,
          actionLabel: status == AccountStatus.sessionExpired
              ? l10n.accountSignInAgain
              : l10n.accountSignIn,
          onAction: signIn,
          actionBelow: true,
        ),
      );
    }
    if (status == AccountStatus.guest &&
        (ref.watch(guestPromptProvider).value ?? false)) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: FbSpace.s3),
        // One row with one action (UX-047, A63 D8.5); × = Not now.
        child: FbNoticeRow(
          key: const ValueKey('guest-prompt-row'),
          icon: FbIcons.backedUp,
          text: l10n.guestPromptShort,
          actionLabel: l10n.guestPromptSignIn,
          actionKey: const ValueKey('guest-prompt-sign-in'),
          onAction: signIn,
          dismissTooltip: l10n.guestPromptNotNow,
          onDismiss: ref.read(guestPromptProvider.notifier).dismiss,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
