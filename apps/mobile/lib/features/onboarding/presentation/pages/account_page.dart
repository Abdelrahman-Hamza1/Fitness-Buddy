import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/onboarding/presentation/pages/page_parts.dart';
import 'package:flutter/widgets.dart';

/// "Keep your data safe?" (D-088, AC-002): the optional account step at the
/// end of the first run; its buttons are pinned under it by the screen.
/// [signedIn] once the user signed in from here.
class AccountPage extends StatelessWidget {
  /// Creates the page.
  const new({required this.signedIn, super.key});

  /// Whether the user is signed in now.
  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s5,
      children: [
        SetupHeader(
          title: l10n.setupAccountTitle,
          hint: signedIn ? null : l10n.setupAccountHint,
        ),
        if (signedIn)
          FbInlineBanner(
            kind: FbInlineBannerKind.info,
            message: l10n.setupAccountDone,
          )
        else ...[
          SetupBenefit(
            icon: FbIcons.backedUp,
            title: l10n.setupAccountBackup,
            body: l10n.setupAccountBackupBody,
          ),
          SetupBenefit(
            icon: FbIcons.devices,
            title: l10n.setupAccountSync,
            body: l10n.setupAccountSyncBody,
          ),
          SetupBenefit(
            icon: FbIcons.privacy,
            title: l10n.setupAccountPrivate,
            body: l10n.setupAccountPrivateBody,
          ),
        ],
      ],
    );
  }
}
