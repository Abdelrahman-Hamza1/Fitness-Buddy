import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/targets/application/targets_actions.dart';
import 'package:fb_mobile/features/targets/application/targets_screens.dart';
import 'package:fb_mobile/features/targets/presentation/macro_sheet.dart';
import 'package:fb_mobile/features/targets/presentation/macro_summary.dart';
import 'package:fb_mobile/features/targets/presentation/manual_target_sheet.dart';
import 'package:fb_mobile/features/targets/presentation/shifting_sheet.dart';
import 'package:fb_mobile/features/targets/presentation/target_explanation.dart';
import 'package:fb_mobile/features/targets/presentation/targets_feedback.dart';
import 'package:fb_mobile/features/targets/presentation/targets_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:material_ui/material_ui.dart';

/// Me › Targets (A13c D14, TG-021/040–044/054, SF-012): today's target, the
/// weekly budget and its planned days with the "This week" line; the
/// plain-language explanation (or the manual note) with its issue banners
/// and "Recalculate with your current weight"; the budget mode,
/// rebalancing and higher-calorie days (off with a note for an
/// acknowledged below-floor target, PA7); macros; your own target. Every
/// change is one `TargetsActions` command with Undo.
class TargetsScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final view = ref.watch(targetsViewProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.targetsTitle)),
      body: switch (view) {
        AsyncData(value: final view?) => TargetsBody(view: view),
        AsyncData() => FbEmptyState(
          icon: FbIcons.me,
          title: l10n.meSetUpTargets,
          message: l10n.targetsNotSetUpMessage,
          action: FbButton.primary(
            label: l10n.meSetUpTargets,
            onPressed: () =>
                ref.read(appNavigatorProvider).push(const SetupRoute()),
          ),
        ),
        AsyncError() => Padding(
          padding: const EdgeInsetsDirectional.all(FbSpace.s4),
          child: FbInlineBanner(
            kind: FbInlineBannerKind.error,
            message: l10n.targetsLoadFailed,
            actionLabel: l10n.targetsTryAgain,
            onAction: () => ref.invalidate(targetsViewProvider),
          ),
        ),
        AsyncLoading() => const Padding(
          padding: EdgeInsetsDirectional.all(FbSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FbSpace.s4,
            children: [
              FbSkeleton.card(height: 160),
              FbSkeleton.card(height: 200),
            ],
          ),
        ),
      },
    );
  }
}

/// The Targets screen's content for [view] (public for the goldens).
class TargetsBody extends ConsumerWidget {
  /// Shows [view].
  const new({required this.view, super.key});

  /// What the screen shows.
  final TargetsView view;

  /// Runs a settings command and shows its feedback ("Targets updated").
  Future<void> _settings(
    BuildContext context,
    Future<TargetsOutcome> Function(TargetsActions actions) command,
    WidgetRef ref,
  ) async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final outcome = await command(ref.read(targetsActionsProvider));
    if (!host.mounted) return;
    if (outcome case TargetsFailed(reason: TargetsFailure.changed)) {
      showFbSnackBar(host, host.l10n.targetsChangedTryAgain);
      return;
    }
    showTargetsFeedback(host, outcome, done: (_) => host.l10n.targetsUpdated);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final version = view.version;
    final weekly = version.mode == TargetMode.weekly;
    final forced = view.forcedFixed;
    final shown = view.shown;
    void run(Future<TargetsOutcome> Function(TargetsActions a) command) =>
        unawaited(_settings(context, command, ref));
    return ListView(
      padding: const EdgeInsetsDirectional.only(bottom: FbSpace.s6),
      children: [
        FbSectionHeader(title: l10n.targetsSectionWeek),
        _Padded(child: _WeekSummary(view: view)),
        FbSectionHeader(title: l10n.targetsSectionHow),
        _Padded(
          child: _HowCalculated(
            view: view,
            onRecalculate: () => run((a) => a.recalculate(shown)),
          ),
        ),
        FbSectionHeader(title: l10n.targetsSectionBudget),
        if (forced) ...[
          FbListRow(
            title: l10n.targetsModeFixed,
            subtitle: l10n.targetsForcedFixedNote,
          ),
          FbSwitchRow(
            title: l10n.targetsRebalancing,
            value: false,
            onChanged: null,
          ),
          FbListRow(
            title: l10n.targetsShifting,
            subtitle: l10n.targetsForcedFixedNote,
          ),
        ] else ...[
          _Padded(
            child: FbOptionList<TargetMode>(
              selected: version.mode,
              onSelected: (mode) {
                if (mode != version.mode) run((a) => a.setMode(shown, mode));
              },
              options: [
                FbOption(
                  value: TargetMode.weekly,
                  label: l10n.targetsModeWeekly,
                  subtitle: l10n.targetsModeWeeklyHint,
                ),
                FbOption(
                  value: TargetMode.fixed,
                  label: l10n.targetsModeFixed,
                  subtitle: l10n.targetsModeFixedHint,
                ),
              ],
            ),
          ),
          if (weekly) ...[
            FbSwitchRow(
              title: l10n.targetsRebalancing,
              subtitle: l10n.targetsRebalancingHint,
              value: version.rebalancing,
              onChanged: (on) => run((a) => a.setRebalancing(shown, on)),
            ),
            FbListRow(
              title: l10n.targetsShifting,
              subtitle: shiftingSummary(context, version.shifts),
              trailing: const Icon(FbIcons.next),
              onTap: () => unawaited(showShiftingSheet(context, view: view)),
            ),
          ],
        ],
        FbSectionHeader(title: l10n.targetsSectionMacros),
        _Padded(child: MacroSummary(macros: view.day.day.macros)),
        if (_energyNote(l10n, view.day.day.macros) case final note?)
          _Padded(child: _Muted(note)),
        FbListRow(
          title: l10n.targetsMacroSettings,
          subtitle: _macroDefaults(version.macros)
              ? l10n.targetsMacroSettingsDefault
              : l10n.targetsMacroSettingsCustom,
          trailing: const Icon(FbIcons.next),
          onTap: () => unawaited(showMacroSheet(context, view: view)),
        ),
        ManualTargetSection(view: view),
      ],
    );
  }

  static bool _macroDefaults(MacroSettings m) =>
      m.protein == null &&
      m.fat == null &&
      m.carbs == null &&
      m.fiberGrams == null &&
      !m.caloriesProteinOnly;

  /// The neutral TG-054 note when the macros' energy is more than 50 kcal
  /// away from the calorie target, else null.
  static String? _energyNote(AppLocalizations l10n, DailyMacros macros) {
    final diff = macros.energyDifferenceKcal;
    if (diff == null || diff.abs() <= 50) return null;
    final kcal = DisplayRounding.kcal(diff.abs());
    return diff > 0
        ? l10n.targetsMacroEnergyAbove(kcal)
        : l10n.targetsMacroEnergyBelow(kcal);
  }
}

/// "Friday: More · Sunday: A little more", or "None".
String shiftingSummary(BuildContext context, Map<DayOfWeek, double> shifts) {
  final l10n = context.l10n;
  if (shifts.isEmpty) return l10n.targetsShiftingNone;
  return [
    for (final day in DayOfWeek.values)
      if (shifts[day] case final weight?)
        '${weekdayName(l10n, day)}: ${shiftLevelLabel(l10n, weight)}',
  ].join(' · ');
}

/// A shift weight's level: "A little more" (up to 1.15), else "More".
String shiftLevelLabel(AppLocalizations l10n, double weight) =>
    weight <= ShiftLevel.little.weight + 1e-9
    ? l10n.targetsShiftLittle
    : l10n.targetsShiftMore;

/// The higher-calorie day levels (D14, TG-043).
enum ShiftLevel {
  /// No shift.
  usual(1),

  /// 15% above the other days' base.
  little(1.15),

  /// 30% above.
  more(1.3);

  new(this.weight);

  /// The stored shifting weight.
  final double weight;

  /// The level shown for a stored [weight] (null: usual).
  static ShiftLevel of(double? weight) => switch (weight) {
    null => usual,
    final w when w <= 1 => usual,
    final w when w <= little.weight + 1e-9 => little,
    _ => more,
  };
}

/// [day]'s full name in the locale ("Friday").
String weekdayName(AppLocalizations l10n, DayOfWeek day) {
  // 2026-10-19 is a Monday; DayOfWeek runs Monday … Sunday.
  final date = DateTime(2026, 10, 19 + day.index);
  return DateFormat.EEEE(l10n.localeName).format(date);
}

class _WeekSummary extends StatelessWidget {
  const new({required this.view});

  final TargetsView view;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final day = view.day;
    final week = day.day.week;
    final position = day.week;
    final dayFormat = DateFormat.MMMEd(l10n.localeName);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s2,
      children: [
        Text(
          l10n.targetsTodayKcal(DisplayRounding.kcal(day.day.kcal)),
          style: FbType.numeric(FbType.headline)
              .copyWith(color: scheme.onSurface),
        ),
        _Muted(l10n.targetsTodayCaption),
        if (week != null) ...[
          Text(
            l10n.targetsWeeklyBudget(DisplayRounding.kcal(week.budgetKcal)),
            style: FbType.numeric(FbType.body)
                .copyWith(color: scheme.onSurface),
          ),
          if (position != null)
            Text(
              weekPositionText(l10n, position),
              style: FbType.body.copyWith(color: scheme.onSurface),
            ),
          for (final date in week.planned.keys.toList()..sort())
            Row(
              children: [
                Expanded(
                  child: Text(
                    dayFormat.format(DateTime(date.year, date.month, date.day)),
                    style: FbType.bodySmall.copyWith(
                      color: date == view.today
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  l10n.targetsPlannedDay(
                    DisplayRounding.kcal(week.planned[date]!),
                  ),
                  style: FbType.numeric(FbType.bodySmall).copyWith(
                    color: date == view.today
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          if (DisplayRounding.kcal(week.carryKcal) != 0)
            _Muted(l10n.targetsCarryNote),
        ],
      ],
    );
  }
}

class _HowCalculated extends ConsumerWidget {
  const new({required this.view, required this.onRecalculate});

  final TargetsView view;
  final VoidCallback onRecalculate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final version = view.version;
    final explanation = view.explanation;
    final issues = view.day.issues;
    final unit = view.units.bodyMass;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        if (issues.contains(TargetIssue.manualNeedsReview))
          FbInlineBanner(
            kind: FbInlineBannerKind.info,
            message: l10n.targetsManualNeedsReview(
              DisplayRounding.kcal(view.day.floorKcal),
            ),
          ),
        if (issues.contains(TargetIssue.goalNeedsUpdate))
          FbInlineBanner(
            kind: FbInlineBannerKind.info,
            message: l10n.targetsGoalNeedsUpdate,
            actionLabel: l10n.targetsGoalUpdateAction,
            onAction: () =>
                ref.read(appNavigatorProvider).push(const ProfileRoute()),
          ),
        if (explanation != null) ...[
          if (version.manual)
            Text(
              l10n.targetsManualNote(
                DisplayRounding.kcal(version.baseKcal),
                DisplayRounding.kcal(explanation.calculated.kcal),
              ),
              style: FbType.body.copyWith(color: scheme.onSurface),
            )
          else
            TargetExplanationView(
              calculation: explanation.calculated,
              activity: view.profile.activity,
              units: view.units,
              weeklyKcal: view.day.day.week?.budgetKcal,
              showGoal: explanation.goal != null,
            ),
        ],
        if (view.recalculateOffered) ...[
          _Muted(
            l10n.targetsRecalculateHint(
              massText(l10n, version.basisWeightKg, unit),
              massText(l10n, view.trendKg!, unit),
            ),
          ),
          FbButton.secondary(
            label: l10n.targetsRecalculate,
            onPressed: onRecalculate,
          ),
        ],
      ],
    );
  }
}

class _Padded extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(horizontal: FbSpace.s4),
    child: child,
  );
}

class _Muted extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: FbType.bodySmall.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

/// "This week: 350 kcal under · 1 day not counted" (D7, TG-032): under, over
/// or on track (0 after rounding), plus the earlier days not counted.
String weekPositionText(AppLocalizations l10n, WeekPosition position) {
  final kcal = DisplayRounding.kcal(position.kcal);
  final amount = NumberFormat.decimalPattern(l10n.localeName)
      .format(kcal.abs());
  final line = switch (kcal) {
    0 => l10n.todayWeekOnTrack,
    > 0 => l10n.todayWeekOver(amount),
    _ => l10n.todayWeekUnder(amount),
  };
  return position.uncountedDays == 0
      ? line
      : l10n.todayWeekWithUncounted(
          line,
          l10n.todayWeekUncounted(position.uncountedDays),
        );
}
