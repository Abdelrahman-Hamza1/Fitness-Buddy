import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/ui/load_states.dart';
import 'package:fb_mobile/core/ui/settings_page.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/targets/application/targets_screens.dart';
import 'package:fb_mobile/features/targets/presentation/goal_form.dart'
    show capMessage;
import 'package:fb_mobile/features/targets/presentation/goal_sheet.dart';
import 'package:fb_mobile/features/targets/presentation/phase_history.dart';
import 'package:fb_mobile/features/targets/presentation/profile_edit_sheet.dart';
import 'package:fb_mobile/features/targets/presentation/targets_day_rollover.dart';
import 'package:fb_mobile/features/targets/presentation/targets_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Me › Profile & goal (A13c D13, TG-001/010–012): the profile rows (each
/// opens its edit sheet), the current weight from A14's trend (opens the
/// weigh-in sheet; there is no profile weight, PA1), the current goal with
/// Edit goal / Start a new goal (a passed goal shows a neutral line, PA3)
/// and Past goals. Local data: a skeleton for the first frame only.
class ProfileGoalScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final view = ref.watch(profileGoalViewProvider);
    return TargetsDayRollover(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.profileGoalTitle)),
        body: switch (view) {
          AsyncData(value: final view?) => _Body(view: view),
          AsyncData() => _NotSetUp(
            onSetUp: () =>
                ref.read(appNavigatorProvider).push(const SetupRoute()),
          ),
          AsyncError() => _LoadFailed(
            onRetry: () => ref.invalidate(profileGoalViewProvider),
          ),
          AsyncLoading() => const _Skeleton(),
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const new({required this.view});

  final ProfileGoalView view;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = view.profile.value;
    void edit(ProfileField field) => unawaited(
      showProfileEditSheet(
        context,
        field: field,
        opened: view.profile,
        today: view.today,
      ),
    );
    // The same settings-page layout as the rest of Me (A65 M4): the
    // profile rows in one card, the goal card, past goals in one card.
    return ListView(
      padding: SettingsPage.padding,
      children: [
        FbRowGroup(
          title: l10n.profileSectionAbout,
          children: [
            FbListRow(
              title: l10n.profileSexLabel,
              subtitle: sexLabel(l10n, profile.sex),
              trailing: const Icon(FbIcons.next),
              onTap: () => edit(ProfileField.sex),
            ),
            FbListRow(
              title: l10n.profileBirthYearLabel,
              subtitle: '${profile.birthYear}',
              trailing: const Icon(FbIcons.next),
              onTap: () => edit(ProfileField.birthYear),
            ),
            FbListRow(
              title: l10n.profileHeightLabel,
              subtitle: heightText(l10n, profile),
              trailing: const Icon(FbIcons.next),
              onTap: () => edit(ProfileField.height),
            ),
            FbListRow(
              title: l10n.profileActivityLabel,
              subtitle: activityLabel(l10n, profile.activity),
              trailing: const Icon(FbIcons.next),
              onTap: () => edit(ProfileField.activity),
            ),
            _CurrentWeightRow(view: view),
          ],
        ),
        FbSectionHeader(title: l10n.goalSectionTitle),
        _GoalCard(view: view),
        if (view.past.isEmpty) ...[
          FbSectionHeader(title: l10n.goalPastTitle),
          PhaseHistory(phases: view.past),
        ] else
          FbRowGroup(
            title: l10n.goalPastTitle,
            children: [PhaseHistory(phases: view.past)],
          ),
      ],
    );
  }
}

/// The current goal: its name, since when, the TG-011 line or the PA3
/// neutral line, Edit goal and Start a new goal.
class _GoalCard extends StatelessWidget {
  const new({required this.view});

  final ProfileGoalView view;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final muted = FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant);
    final active = view.active;
    final problem = view.goalProblem;
    final calc = view.goalCalculation;
    final unit = active?.value.weightInputUnit ?? view.units.bodyMass;
    return FbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s2,
        children: [
          if (active == null)
            Text(l10n.goalNoneToday, style: FbType.body)
          else ...[
            Text(
              goalPhaseLabel(l10n, active.value),
              style: FbType.title.copyWith(color: scheme.onSurface),
            ),
            Text(
              l10n.goalSince(shortDate(l10n, active.value.start)),
              style: muted,
            ),
            if (problem != null)
              Text(
                storedGoalProblemText(l10n, problem),
                style: FbType.body.copyWith(color: scheme.onSurface),
              )
            else if (active.value.type == GoalType.maintain)
              Text(l10n.goalMaintainNote, style: muted)
            else if (calc != null) ...[
              Text(
                _goalLine(l10n, calc, unit, view.today),
                style: FbType.numeric(FbType.body)
                    .copyWith(color: scheme.onSurface),
              ),
              if (calc.warnings.contains(TargetWarning.lossRateCapped))
                Text(capMessage(l10n, calc, unit), style: muted),
            ],
          ],
          Wrap(
            spacing: FbSpace.s2,
            runSpacing: FbSpace.s2,
            children: [
              if (active != null && problem == null)
                FbButton.secondary(
                  label: l10n.goalEdit,
                  onPressed: () => unawaited(
                    showGoalSheet(context, view: view, edit: active),
                  ),
                ),
              FbButton.secondary(
                label: l10n.goalStartNew,
                onPressed: () => unawaited(showGoalSheet(context, view: view)),
              ),
              if (active != null)
                FbButton.text(
                  label: l10n.goalRename,
                  onPressed: () =>
                      unawaited(showRenamePhaseSheet(context, active)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// "≈ −0.46 kg a week · −2 kg in November" (TG-011), with the projected
  /// month for a target-weight goal.
  static String _goalLine(
    AppLocalizations l10n,
    TargetCalculation calc,
    MassUnit unit,
    LocalDate today,
  ) {
    final month = LocalDate(today.year, today.month, 1);
    final rate = rateText(l10n, calc.achievableKgPerWeek, unit, signed: true);
    final change = massText(
      l10n,
      monthlyKgFromWeeklyRate(calc.achievableKgPerWeek, month),
      unit,
      signed: true,
    );
    final projected = calc.projectedDate;
    return projected == null
        ? l10n.goalProjection(rate, change, monthName(l10n, month))
        : l10n.goalProjectionWithDate(
            rate,
            change,
            monthName(l10n, month),
            monthYear(l10n, projected),
          );
  }
}

class _NotSetUp extends StatelessWidget {
  const new({required this.onSetUp});

  final VoidCallback onSetUp;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FbEmptyState(
      icon: FbIcons.target,
      title: l10n.meSetUpTargets,
      message: l10n.targetsNotSetUpMessage,
      action: FbButton.primary(label: l10n.meSetUpTargets, onPressed: onSetUp),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const new({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) =>
      LoadFailedView(message: context.l10n.targetsLoadFailed, onRetry: onRetry);
}

class _Skeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsetsDirectional.all(FbSpace.s4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s4,
      children: [FbSkeleton.card(height: 220), FbSkeleton.card(height: 140)],
    ),
  );
}

/// The stored height in the unit it was typed in (TD-017): "180 cm",
/// "5 ft 11 in".
String heightText(AppLocalizations l10n, ProfileRecord profile) {
  final length = Length.centimeters(profile.heightCm);
  return switch (profile.heightInputUnit) {
    HeightInputUnit.centimeter => l10n.profileHeightValueCm(
      DisplayRounding.length(profile.heightCm),
    ),
    HeightInputUnit.feetInches => l10n.profileHeightValueFtIn(
      length.toFeetAndInches().feet,
      length.toFeetAndInches().inches,
    ),
  };
}

/// Me › Profile's current weight (WB-011, D-102): the reading's line and
/// its supporting line (the change since the weigh-in before, or the
/// latest next to the trend), read as one node with the shared semantics.
/// A tap logs a weigh-in.
class _CurrentWeightRow extends StatelessWidget {
  const new({required this.view});

  final ProfileGoalView view;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = view.currentWeight;
    final unit = view.units.bodyMass;
    void log() => unawaited(showWeighInSheet(context));
    final String subtitle;
    final String spoken;
    if (current == null) {
      subtitle = l10n.profileCurrentWeightNone;
      spoken = subtitle;
    } else {
      final main = switch (current) {
        LatestWeightReading() => readingLineText(
          context,
          current,
          unit,
          view.today,
        ),
        TrendWeightReading() => l10n.profileCurrentWeightTrend(
          readingMainText(l10n, current, unit),
        ),
      };
      final first = current is LatestWeightReading && current.changeKg == null;
      subtitle = first
          ? main
          : l10n.profileCurrentWeightValue(
              main,
              readingDetailText(context, current, unit, view.today),
            );
      spoken = readingSemantics(context, current, unit, view.today);
    }
    return Semantics(
      key: const ValueKey('profile-current-weight'),
      label: l10n.profileCurrentWeightSemantics(spoken),
      button: true,
      onTap: log,
      excludeSemantics: true,
      child: FbListRow(
        title: l10n.profileCurrentWeight,
        subtitle: subtitle,
        trailing: const Icon(FbIcons.next),
        onTap: log,
      ),
    );
  }
}
