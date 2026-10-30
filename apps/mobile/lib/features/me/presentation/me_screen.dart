import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The Me tab (UX-010, A10 D8): one scrolling list of sections in a fixed
/// order, each shown once its step exists. Today that is You ("Set up
/// profile & targets" until setup has run, A13 D10; "Update the app" for a
/// profile this version can't read; Profile & goal and Targets once set
/// up, A13c), Food (Your foods and Saved meals, A09 D10), Settings (units, week
/// start, halal, theme, city and the energy unit), Your data (Export your
/// data, A11 D9) and About; Buddy remembers (A26) and Account (A33) add their
/// own sections. A section with no rows is not shown. In the dev flavor a
/// Developer section has the "Design preview" row (A02 D15).
class MeScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDev = ref.watch(appConfigProvider).flavor == AppFlavor.dev;
    final open = ref.read(appNavigatorProvider).push;
    final setup = ref.watch(setupStatusProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabMe)),
      // A re-tap of the tab scrolls this list to the top (A45 D13).
      body: ScrollToTopOnTabReselect(
        tab: AppTab.me,
        child: CustomScrollView(
          slivers: [
            SliverList.list(
              children: [
                ..._group(l10n.meSectionYou, open, [
                  if (setup == SetupStatus.notSetUp)
                    _Row(l10n.meSetUpTargets, const SetupRoute()),
                  if (setup == SetupStatus.profileUnreadable)
                    _Row(l10n.setupUpdateTitle, const SetupRoute()),
                  if (setup == SetupStatus.setUp)
                    _Row(l10n.meProfileGoal, const ProfileRoute()),
                  if (setup == SetupStatus.setUp)
                    _Row(l10n.meTargets, const TargetsRoute()),
                ]),
                ..._group(l10n.meSectionFood, open, [
                  _Row(l10n.meYourFoods, const PersonalFoodsRoute()),
                  _Row(l10n.meSavedMeals, const SavedMealsRoute()),
                ]),
                const SettingsSection(),
                FbSectionHeader(title: l10n.meSectionYourData),
                FbListRow(
                  title: l10n.meExportData,
                  trailing: const Icon(FbIcons.next),
                  onTap: () => unawaited(showExportSheet(context)),
                ),
                const AccountSection(),
                ..._group(l10n.meSectionAbout, open, [
                  _Row(l10n.meAbout, const AboutRoute()),
                ]),
                ..._group(l10n.meSectionDeveloper, open, [
                  if (isDev)
                    _Row(l10n.meDesignPreview, const DesignPreviewRoute()),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One row that opens [route].
final class _Row {
  const new(this.title, this.route);

  final String title;
  final AppRoute route;
}

/// A section: its header and rows, or nothing when it has no rows.
List<Widget> _group(
  String title,
  void Function(AppRoute) open,
  List<_Row> rows,
) => [
  if (rows.isNotEmpty) ...[
    FbSectionHeader(title: title),
    for (final row in rows)
      FbListRow(
        title: row.title,
        trailing: const Icon(FbIcons.next),
        onTap: () => open(row.route),
      ),
  ],
];
