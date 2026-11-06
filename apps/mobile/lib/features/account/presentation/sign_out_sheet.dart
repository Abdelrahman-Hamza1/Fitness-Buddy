import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/account/account_service.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/account/application/sign_in_controller.dart';
import 'package:fb_mobile/features/account/application/sign_out_check.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// What the sign-out sheet asked for (AC-004, A65 M1).
sealed class SignOutRequest {
  const new();
}

/// Keep a read-only copy.
final class KeepCopyRequest extends SignOutRequest {
  /// The request.
  const new();
}

/// Remove this phone's copy, as [confirmation] confirmed.
final class RemoveCopyRequest extends SignOutRequest {
  /// The request.
  const new(this.confirmation);

  /// The profile and the unsynced count the user confirmed.
  final RemoveConfirmation confirmation;
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

/// Asks how to sign out (AC-004); `null` when dismissed, or when [context]
/// went away meanwhile (A65 review 2: a caller that is gone runs nothing).
/// "Remove from this phone" is confirmed in a second step that syncs first
/// and says how many changes would be lost (A65 M1, UX-030, UX-052).
Future<SignOutRequest?> showSignOutSheet(BuildContext context) async {
  final choice = await showFbSheet<SignOutChoice>(
    context,
    title: context.l10n.accountSignOut,
    builder: (context) => SignOutSheetBody(
      onSelected: (choice) => Navigator.of(context).pop(choice),
    ),
  );
  if (choice == null || !context.mounted) return null;
  if (choice == SignOutChoice.keep) return const KeepCopyRequest();
  final confirmed = await confirmRemoveCopy(context);
  return confirmed == null ? null : RemoveCopyRequest(confirmed);
}

/// The "Remove from this phone?" step on its own: also asked again, with
/// [changed], when the removal stopped because something changed after the
/// confirmation (A65 review 1). `null` when cancelled, dismissed or when
/// [context] went away.
Future<RemoveConfirmation?> confirmRemoveCopy(
  BuildContext context, {
  bool changed = false,
}) async {
  final confirmed = await showFbSheet<RemoveConfirmation>(
    context,
    title: context.l10n.accountRemoveTitle,
    builder: (_) => RemoveCopyConfirm(changed: changed),
  );
  return context.mounted ? confirmed : null;
}

/// Signs out as the sheet asks (AC-004, A65 M1): keep, or remove bound to
/// what was confirmed; a removal that stopped because something changed is
/// asked about again until it is removed or cancelled (A65 review 1).
Future<void> runSignOut(BuildContext context, AccountActions actions) async {
  final request = await showSignOutSheet(context);
  switch (request) {
    case null:
      return;
    case KeepCopyRequest():
      await actions.signOut(SignOutChoice.keep);
    case RemoveCopyRequest(:final confirmation):
      var confirmed = confirmation;
      while (!await actions.removeCopy(confirmed)) {
        if (!context.mounted) return;
        final again = await confirmRemoveCopy(context, changed: true);
        if (again == null) return;
        confirmed = again;
      }
  }
}

/// The "Remove from this phone?" step (A65 M1): with changes waiting it
/// syncs first; if some are still waiting it says how many would be lost,
/// with Sync now and Remove anyway; when all is synced it asks once. Pops
/// the [RemoveConfirmation] (the profile and the count shown) to remove.
class RemoveCopyConfirm extends ConsumerStatefulWidget {
  /// Creates the step; [changed]: asked again after a stopped removal.
  const new({this.changed = false, super.key});

  /// The removal stopped because something changed: says so first.
  final bool changed;

  @override
  ConsumerState<RemoveCopyConfirm> createState() => _RemoveCopyConfirmState();
}

class _RemoveCopyConfirmState extends ConsumerState<RemoveCopyConfirm> {
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      ref.read(unsyncedChangesProvider.future).then((read) {
        if ((read.count ?? 0) > 0 && mounted) unawaited(_sync());
      }, onError: (Object _) {}),
    );
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      await ref.read(accountActionsProvider.notifier).syncBeforeRemove();
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final unsynced = ref.watch(unsyncedChangesProvider);
    // Loading, a failed count and an unknown profile are each explicit
    // (A65 review 3): an error never shows an earlier number.
    final read = unsynced.hasError ? null : unsynced.value;
    final checking = _syncing || (read == null && !unsynced.hasError);
    final count = read?.count;
    final message = switch ((checking, count)) {
      (true, _) => l10n.accountRemoveSyncing,
      (false, null) => l10n.accountRemoveCheckFailed,
      (false, 0) => l10n.accountRemoveSynced,
      (false, final n?) => l10n.accountRemoveUnsynced(n),
    };
    final risky = !checking && count != 0;
    final style = FbType.body.copyWith(color: scheme.onSurface);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        if (widget.changed)
          Text(
            l10n.accountRemoveChanged,
            key: const ValueKey('sign-out-remove-changed'),
            style: style,
          ),
        Semantics(
          liveRegion: true,
          child: Text(
            message,
            key: const ValueKey('sign-out-remove-message'),
            style: style,
          ),
        ),
        if (risky && count != null)
          FbButton.primary(
            key: const ValueKey('sign-out-sync-first'),
            label: l10n.accountRemoveSyncFirst,
            expand: true,
            onPressed: () => unawaited(_sync()),
          ),
        FbButton.destructive(
          key: const ValueKey('sign-out-remove-confirm'),
          label: risky ? l10n.accountRemoveAnyway : l10n.accountRemoveConfirm,
          expand: true,
          busy: checking,
          // Bound to the profile the count was read for: without one (its
          // registry couldn't be read) nothing can be removed.
          onPressed: checking || read == null
              ? null
              : () => Navigator.of(context).pop(
                  RemoveConfirmation(
                    profileKey: read.profileKey,
                    unsynced: count,
                  ),
                ),
        ),
        FbButton.text(
          key: const ValueKey('sign-out-remove-cancel'),
          label: l10n.commonCancel,
          expand: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
