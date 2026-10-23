import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/theme/theme_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The light/dark/system switch of the design preview (A02 D16). It sets
/// `themeModeProvider`, so the whole app changes, not just this screen.
class PreviewSwitches extends ConsumerWidget {
  /// Creates the switches.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mode = ref.watch(themeModeProvider);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: FbSpace.s4,
        vertical: FbSpace.s2,
      ),
      child: Wrap(
        spacing: FbSpace.s3,
        runSpacing: FbSpace.s2,
        children: [
          Semantics(
            label: l10n.previewModeLabel,
            container: true,
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(l10n.previewModeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(l10n.previewModeDark),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(l10n.previewModeSystem),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (selection) =>
                  ref.read(themeModeProvider.notifier).select(selection.single),
            ),
          ),
        ],
      ),
    );
  }
}
