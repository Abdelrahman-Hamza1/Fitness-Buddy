import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/account/application/delete_account_controller.dart';
import 'package:fb_mobile/features/account/application/sign_in_controller.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Account deletion (A35, AC-031): what goes, that backups expire within 30
/// days, export first, then a confirmation. A guest deletes only this
/// phone's data. Offline, unconfirmed and session-ended outcomes say what
/// happened and offer the next step (B06's contract).
class DeleteAccountScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final status = ref.watch(accountStatusProvider).value;
    final guest = status == AccountStatus.guest;
    final phase = ref.watch(deleteAccountControllerProvider);
    final controller = ref.read(deleteAccountControllerProvider.notifier);
    final busy = phase == DeletePhase.deleting;
    Text body(String text) =>
        Text(text, style: FbType.body.copyWith(color: scheme.onSurface));
    final message = switch (phase) {
      DeletePhase.offline => l10n.deleteOffline,
      DeletePhase.uncertain => l10n.deleteUncertain,
      DeletePhase.sessionEnded => l10n.deleteSessionEnded,
      DeletePhase.needsSignIn => l10n.deleteNeedsSignIn,
      DeletePhase.wipeFailed => l10n.deleteWipeFailed,
      DeletePhase.ready || DeletePhase.deleting => null,
    };
    Future<void> confirmAndDelete() async {
      final yes = await showFbSheet<bool>(
        context,
        title: guest ? l10n.deleteLocalTitle : l10n.deleteAccountTitle,
        builder: (sheet) => _ConfirmBody(guest: guest),
      );
      if (yes ?? false) await controller.delete(guest: guest);
    }

    // While deleting, back is blocked (the work would go on anyway).
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(guest ? l10n.deleteLocalTitle : l10n.deleteAccountTitle),
        ),
        body: ListView(
          padding: const EdgeInsetsDirectional.all(FbSpace.s4),
          children: [
            body(guest ? l10n.deleteLocalWhat : l10n.deleteAccountWhat),
            if (!guest) ...[
              const SizedBox(height: FbSpace.s3),
              body(l10n.deleteAccountBackups),
            ],
            const SizedBox(height: FbSpace.s3),
            body(l10n.deleteExportFirst),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FbButton.text(
                label: l10n.deleteExport,
                onPressed: busy
                    ? null
                    : () => unawaited(showExportSheet(context)),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: FbSpace.s3),
              FbInlineBanner(
                key: const ValueKey('delete-outcome'),
                kind: phase == DeletePhase.offline
                    ? FbInlineBannerKind.offline
                    : FbInlineBannerKind.error,
                message: message,
              ),
            ],
            const SizedBox(height: FbSpace.s4),
            if (busy)
              const Center(child: CircularProgressIndicator())
            else
              ...switch (phase) {
                DeletePhase.sessionEnded => [
                  FbButton.primary(
                    key: const ValueKey('delete-remove-local'),
                    label: l10n.deleteRemoveLocal,
                    onPressed: () => unawaited(controller.removeLocal()),
                  ),
                  const SizedBox(height: FbSpace.s2),
                  FbButton.secondary(
                    label: l10n.deleteSignInAgain,
                    onPressed: () => ref
                        .read(appNavigatorProvider)
                        .push(const SignInRoute()),
                  ),
                ],
                DeletePhase.needsSignIn => [
                  FbButton.primary(
                    label: l10n.deleteSignInAgain,
                    onPressed: () => ref
                        .read(appNavigatorProvider)
                        .push(const SignInRoute()),
                  ),
                ],
                DeletePhase.wipeFailed => [
                  FbButton.primary(
                    key: const ValueKey('delete-remove-local'),
                    label: l10n.deleteRetry,
                    onPressed: () => unawaited(controller.removeLocal()),
                  ),
                ],
                DeletePhase.offline || DeletePhase.uncertain => [
                  FbButton.primary(
                    key: const ValueKey('delete-retry'),
                    label: l10n.deleteRetry,
                    onPressed: () => unawaited(controller.delete(guest: guest)),
                  ),
                ],
                DeletePhase.ready || DeletePhase.deleting => [
                  FbButton.primary(
                    key: const ValueKey('delete-continue'),
                    label: l10n.deleteContinue,
                    onPressed: status == null
                        ? null
                        : () => unawaited(confirmAndDelete()),
                  ),
                ],
              },
            if (busy) ...[
              const SizedBox(height: FbSpace.s2),
              Center(child: body(l10n.deleteInProgress)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConfirmBody extends StatelessWidget {
  const new({required this.guest});

  final bool guest;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          guest ? l10n.deleteConfirmLocal : l10n.deleteConfirmAccount,
          style: FbType.body.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: FbSpace.s4),
        FbButton.primary(
          key: const ValueKey('delete-confirm'),
          label: l10n.deleteConfirmYes,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: FbSpace.s2),
        FbButton.secondary(
          label: l10n.deleteCancel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
