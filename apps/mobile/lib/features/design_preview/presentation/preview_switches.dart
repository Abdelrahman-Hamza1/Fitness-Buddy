import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The light/dark/system switch of the design preview (A02 D16). It sets
/// the theme setting (UX-040, one path with the Me tab's Theme row), so the
/// whole app changes, not just this screen.
class PreviewSwitches extends ConsumerWidget {
  /// Creates the switches.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mode =
        ref.watch(themePreferenceProvider).value ??
        AppSettings.theme.defaultValue;
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
            child: SegmentedButton<ThemePreference>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: ThemePreference.light,
                  label: Text(l10n.previewModeLight),
                ),
                ButtonSegment(
                  value: ThemePreference.dark,
                  label: Text(l10n.previewModeDark),
                ),
                ButtonSegment(
                  value: ThemePreference.system,
                  label: Text(l10n.previewModeSystem),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (selection) =>
                  unawaited(applyTheme(context, ref, selection.single)),
            ),
          ),
        ],
      ),
    );
  }
}
