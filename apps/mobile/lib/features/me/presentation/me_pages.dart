import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:fb_mobile/features/me/presentation/me_parts.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// Me's subpages (UX-010, A51 D8). Every destination the old single Me list
// had is on one of them.

/// Me › Targets & goal: Targets and Profile & goal once set up; "Set up
/// profile & targets" before; "Update the app" for a profile this version
/// can't read (A13a security review #3).
class MeTargetsGoalScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final setup = ref.watch(setupStatusProvider).value;
    return MePage(
      title: l10n.meTargetsGoal,
      children: [
        MeGroup(
          children: [
            if (setup == SetupStatus.notSetUp)
              MeLink(title: l10n.meSetUpTargets, route: const SetupRoute()),
            if (setup == SetupStatus.profileUnreadable)
              MeLink(title: l10n.setupUpdateTitle, route: const SetupRoute()),
            if (setup == SetupStatus.setUp) ...[
              MeLink(title: l10n.meTargets, route: const TargetsRoute()),
              MeLink(title: l10n.meProfileGoal, route: const ProfileRoute()),
            ],
          ],
        ),
      ],
    );
  }
}

/// Me › Food & meals: your foods, saved meals, meal times and halal.
class MeFoodScreen extends StatelessWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MePage(
      title: l10n.meFoodMeals,
      children: [
        MeGroup(
          children: [
            MeLink(title: l10n.meYourFoods, route: const PersonalFoodsRoute()),
            MeLink(title: l10n.meSavedMeals, route: const SavedMealsRoute()),
            MeLink(
              title: l10n.settingsMealTimes,
              route: const MealSlotsRoute(),
            ),
          ],
        ),
        const SizedBox(height: FbSpace.s3),
        const MeGroup(children: [HalalSettingRow()]),
      ],
    );
  }
}

/// Me › Workouts: the weekly plan, starter plans, exercises and history,
/// which open in the Workouts tab.
class MeWorkoutsScreen extends StatelessWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return MePage(
      title: l10n.meWorkouts,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            FbSpace.s4,
            FbSpace.s2,
            FbSpace.s4,
            FbSpace.s3,
          ),
          child: Text(
            l10n.meWorkoutsNote,
            style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        MeGroup(
          children: [
            MeLink(
              title: l10n.workoutPlanTitle,
              route: const WorkoutPlanRoute(),
              go: true,
            ),
            MeLink(
              title: l10n.meStarterPlans,
              route: const WorkoutStarterPlansRoute(),
              go: true,
            ),
            MeLink(
              title: l10n.workoutExercisesTitle,
              route: const WorkoutExercisesRoute(),
              go: true,
            ),
            MeLink(
              title: l10n.workoutHistoryTitle,
              route: const WorkoutHistoryRoute(),
              go: true,
            ),
          ],
        ),
      ],
    );
  }
}

/// Me › Preferences: units, theme, week start, language and energy.
class MePreferencesScreen extends StatelessWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) => MePage(
    title: context.l10n.mePreferences,
    children: const [
      MeGroup(
        children: [
          UnitsSettingRow(),
          ThemeSettingRow(),
          WeekStartSettingRow(),
          LanguageSettingRow(),
          FoodNamesSettingRow(),
          EnergySettingRow(),
        ],
      ),
    ],
  );
}

/// Me › Account & data: the account card, sync and sign-out, export, and
/// deletion kept apart at the bottom (research §5).
class MeAccountScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final status = ref.watch(accountStatusProvider).value;
    final rows = status != null && status != AccountStatus.guest;
    final delete =
        status == AccountStatus.guest || status == AccountStatus.signedIn;
    return MePage(
      title: l10n.meAccountData,
      children: [
        const AccountCard(),
        if (rows) ...[
          const SizedBox(height: FbSpace.s3),
          const MeGroup(children: [AccountRows()]),
        ],
        MeGroup(
          title: l10n.meSectionYourData,
          children: [
            FbListRow(
              title: l10n.meExportData,
              subtitle: l10n.meExportDataHint,
              trailing: const Icon(FbIcons.next),
              onTap: () => unawaited(showExportSheet(context)),
            ),
          ],
        ),
        if (delete) ...[
          const SizedBox(height: FbSpace.s6),
          const MeGroup(children: [AccountDeleteRow()]),
        ],
      ],
    );
  }
}
