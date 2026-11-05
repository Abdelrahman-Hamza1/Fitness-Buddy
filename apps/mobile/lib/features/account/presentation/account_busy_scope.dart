import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Covers the app with a calm "Updating your account…" state while an
/// account transition with a journal runs (A33 re-check 3), so no
/// profile-dependent form can open until the profile generation switched.
/// Usually a fraction of a second; local only, never waits for the network.
class AccountBusyScope extends ConsumerWidget {
  /// Wraps [child].
  const new({required this.child, super.key});

  /// The app.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(accountBusyProvider);
    return Stack(
      fit: StackFit.expand,
      children: [
        // The app behind stays mounted but out of reach: no focus, no
        // taps and nothing for a screen reader (A57 A59).
        ExcludeFocus(
          excluding: busy,
          child: ExcludeSemantics(
            excluding: busy,
            child: IgnorePointer(ignoring: busy, child: child),
          ),
        ),
        if (busy)
          BlockSemantics(
            child: Material(
              key: const ValueKey('account-busy'),
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(FbSpace.s5),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      context.l10n.accountTransitionBusy,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
