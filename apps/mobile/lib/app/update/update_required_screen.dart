import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/app/update/update_check.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Shown instead of the app when this version is too old for the server
/// (S06 plan D10). Outside the tabs, so it blocks every screen; the router
/// shows it while the update gate is up.
///
/// No store link in R1 (the app is sideloaded): the owner installs the new
/// build, or taps "Check again" after the server's minimum changed. The
/// result of a check shows under the button.
class UpdateRequiredScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final status = ref.watch(updateCheckProvider);
    final checking = status == UpdateCheckStatus.checking;
    final outcome = switch (status) {
      UpdateCheckStatus.idle || UpdateCheckStatus.checking => null,
      UpdateCheckStatus.stillOld => l10n.updateRequiredStillOld,
      UpdateCheckStatus.failed => l10n.updateRequiredCheckFailed,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.updateRequiredTitle)),
      body: SafeArea(
        // Scrolls at large text sizes and in landscape; centred otherwise.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsetsDirectional.all(FbSpace.s5),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 2 * FbSpace.s5).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      FbIcons.info,
                      size: FbSpace.s7,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: FbSpace.s4),
                  Text(l10n.updateRequiredBody),
                  const SizedBox(height: FbSpace.s5),
                  FbButton.primary(
                    label: l10n.updateRequiredCheckAgain,
                    expand: true,
                    // Disabled while a check runs, so taps don't pile up.
                    onPressed: checking
                        ? null
                        : () => ref
                              .read(updateCheckProvider.notifier)
                              .checkAgain(),
                  ),
                  const SizedBox(height: FbSpace.s4),
                  if (checking)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox.square(
                          dimension: FbSpace.s4,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: FbSpace.s2),
                        Flexible(child: Text(l10n.updateRequiredChecking)),
                      ],
                    )
                  else if (outcome != null)
                    // Announced to screen readers when it appears.
                    Semantics(
                      liveRegion: true,
                      child: Text(outcome, textAlign: TextAlign.center),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
