import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The Me tab (UX-010). An empty state until profile, goals and settings
/// land; in the dev flavor it also has the "Design preview" row (A02 D15).
class MeScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDev = ref.watch(appConfigProvider).flavor == AppFlavor.dev;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabMe)),
      body: Column(
        children: [
          if (isDev)
            FbListRow(
              title: l10n.meDesignPreview,
              trailing: const Icon(FbIcons.next),
              onTap: () => ref
                  .read(appNavigatorProvider)
                  .push(const DesignPreviewRoute()),
            ),
          Expanded(
            child: FbEmptyState(
              icon: FbIcons.me,
              title: l10n.meEmptyTitle,
              message: l10n.mePlaceholder,
            ),
          ),
        ],
      ),
    );
  }
}
