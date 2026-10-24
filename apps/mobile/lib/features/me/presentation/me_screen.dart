import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The Me tab (UX-010). Its Food section opens Your foods and Saved meals
/// (A09 D10); profile, goals and settings arrive later (A10), so the tab no
/// longer shows an empty state. In the dev flavor it also has the "Design
/// preview" row (A02 D15).
class MeScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDev = ref.watch(appConfigProvider).flavor == AppFlavor.dev;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabMe)),
      body: CustomScrollView(
        slivers: [
          SliverList.list(
            children: [
              FbSectionHeader(title: l10n.meSectionFood),
              FbListRow(
                title: l10n.meYourFoods,
                trailing: const Icon(FbIcons.next),
                onTap: () => ref
                    .read(appNavigatorProvider)
                    .push(const PersonalFoodsRoute()),
              ),
              FbListRow(
                title: l10n.meSavedMeals,
                trailing: const Icon(FbIcons.next),
                onTap: () => ref
                    .read(appNavigatorProvider)
                    .push(const SavedMealsRoute()),
              ),
              if (isDev)
                FbListRow(
                  title: l10n.meDesignPreview,
                  trailing: const Icon(FbIcons.next),
                  onTap: () => ref
                      .read(appNavigatorProvider)
                      .push(const DesignPreviewRoute()),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
