import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/account/application/account_removed_note.dart';
import 'package:fb_mobile/features/account/application/guest_prompt.dart';
import 'package:fb_mobile/features/account/application/sign_in_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The account line on Today (A33): "session expired, sign in again" for a
/// registered account whose session ended (A20 `sessionExpired`), a note on
/// a read-only kept copy (AC-004), or the gentle guest prompt (AC-002).
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
        child: FbCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.guestPromptBody),
              const SizedBox(height: FbSpace.s2),
              Wrap(
                spacing: FbSpace.s2,
                children: [
                  FbButton.text(
                    label: l10n.guestPromptCreate,
                    onPressed: signIn,
                  ),
                  FbButton.text(
                    label: l10n.guestPromptNotNow,
                    onPressed: ref.read(guestPromptProvider.notifier).dismiss,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
