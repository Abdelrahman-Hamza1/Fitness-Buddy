import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:fb_mobile/features/me/application/me_summary.dart';
import 'package:fb_mobile/features/me/presentation/me_parts.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The Me tab (UX-010, D-088, A51): the account card, a compact summary of
/// today's targets, then two groups of rows that open subpages: Your plan
/// (Targets & goal, Food & meals, Workouts, Ramadan) and App (Preferences,
/// Notifications, Account & data, Help & about). Rows show their current
/// values. In the dev flavor a Developer group has "Design preview" (A02
/// D15).
class MeScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDev = ref.watch(appConfigProvider).flavor == AppFlavor.dev;
    final setup = ref.watch(setupStatusProvider).value;
    final units =
        ref.watch(unitSystemProvider).value ??
        AppSettings.unitSystem.defaultValue;
    final theme =
        ref.watch(themePreferenceProvider).value ??
        AppSettings.theme.defaultValue;
    final weekStart =
        ref.watch(weekStartProvider).value ??
        AppSettings.weekStart.defaultValue;
    final reminders = ref.watch(notificationPrefsProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabMe)),
      // A re-tap of the tab scrolls this list to the top (A45 D13).
      body: ScrollToTopOnTabReselect(
        tab: AppTab.me,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                FbSpace.s4,
                FbSpace.s2,
                FbSpace.s4,
                FbSpace.s5,
              ),
              sliver: SliverList.list(
                children: [
                  const AccountCard(),
                  const SizedBox(height: FbSpace.s3),
                  const _TargetsSummary(),
                  MeGroup(
                    title: l10n.meSectionPlan,
                    children: [
                      MeLink(
                        title: l10n.meTargetsGoal,
                        subtitle: switch (setup) {
                          SetupStatus.setUp => l10n.meTargetsGoalHint,
                          SetupStatus.profileUnreadable =>
                            l10n.setupUpdateTitle,
                          SetupStatus.notSetUp ||
                          null => l10n.meTargetsGoalNotSet,
                        },
                        icon: FbIcons.target,
                        route: const MeTargetsGoalRoute(),
                      ),
                      MeLink(
                        title: l10n.meFoodMeals,
                        subtitle: l10n.meFoodMealsHint,
                        icon: FbIcons.food,
                        route: const MeFoodRoute(),
                      ),
                      MeLink(
                        title: l10n.meWorkouts,
                        subtitle: l10n.meWorkoutsHint,
                        icon: FbIcons.navWorkouts,
                        route: const MeWorkoutsRoute(),
                      ),
                      MeLink(
                        key: const ValueKey('settings-ramadan'),
                        title: l10n.ramadanTitle,
                        subtitle: l10n.ramadanSettingsHint,
                        icon: FbIcons.ramadan,
                        route: const RamadanRoute(),
                      ),
                    ],
                  ),
                  MeGroup(
                    title: l10n.meSectionApp,
                    children: [
                      MeLink(
                        title: l10n.mePreferences,
                        subtitle: l10n.mePreferencesValues(
                          unitsName(context, units),
                          themeName(context, theme),
                          weekdayName(context, weekStart),
                        ),
                        icon: FbIcons.preferences,
                        route: const MePreferencesRoute(),
                      ),
                      MeLink(
                        key: const ValueKey('settings-notifications'),
                        title: l10n.settingsNotifications,
                        subtitle: reminders == null
                            ? null
                            : l10n.meNotificationsOn(
                                reminders.types.values
                                    .where((t) => t.enabled)
                                    .length,
                              ),
                        icon: FbIcons.notifications,
                        route: const NotificationSettingsRoute(),
                      ),
                      MeLink(
                        title: l10n.meAccountData,
                        subtitle: l10n.meAccountDataHint,
                        icon: FbIcons.account,
                        route: const MeAccountRoute(),
                      ),
                      MeLink(
                        title: l10n.meHelpAbout,
                        icon: FbIcons.help,
                        route: const AboutRoute(),
                      ),
                    ],
                  ),
                  MeGroup(
                    title: l10n.meSectionDeveloper,
                    children: [
                      if (isDev)
                        MeLink(
                          title: l10n.meDesignPreview,
                          route: const DesignPreviewRoute(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Today's calorie and protein targets and the goal, in one card that
/// opens Targets & goal; before setup a line and "Set up profile &
/// targets". Nothing while it loads (local reads, no spinner).
class _TargetsSummary extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final setup = ref.watch(setupStatusProvider).value;
    final navigator = ref.read(appNavigatorProvider);
    if (setup == SetupStatus.notSetUp) {
      return FbCard(
        padding: EdgeInsetsDirectional.zero,
        child: FbListRow(
          title: l10n.meSetUpTargets,
          subtitle: l10n.meSummaryNone,
          leading: Icon(FbIcons.target, color: scheme.primary),
          trailing: const Icon(FbIcons.next),
          onTap: () => navigator.push(const SetupRoute()),
        ),
      );
    }
    final summary = ref.watch(meTargetsSummaryProvider).value;
    if (summary == null) return const SizedBox.shrink();
    Widget cell(String value, String caption) => Expanded(
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Text(
              value,
              style: FbType.numeric(FbType.title)
                  .copyWith(color: scheme.onSurface),
            ),
            Text(
              caption,
              style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
    final protein = summary.proteinGrams;
    final goal = summary.goal;
    return FbCard(
      onTap: () => navigator.push(const MeTargetsGoalRoute()),
      padding: const EdgeInsetsDirectional.all(FbSpace.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FbSpace.s3,
        children: [
          cell(
            l10n.diaryBigKcal(DisplayRounding.kcal(summary.kcal)),
            l10n.meSummaryKcal,
          ),
          if (protein != null)
            cell(
              l10n.targetsMacroGrams(DisplayRounding.macroTargetGrams(protein)),
              l10n.meSummaryProtein,
            ),
          if (goal != null) cell(goalTypeLabel(l10n, goal), l10n.meSummaryGoal),
        ],
      ),
    );
  }
}
