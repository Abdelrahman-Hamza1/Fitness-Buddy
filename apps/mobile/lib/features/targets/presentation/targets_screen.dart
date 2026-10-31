import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/targets/application/targets_actions.dart';
import 'package:fb_mobile/features/targets/application/targets_screens.dart';
import 'package:fb_mobile/features/targets/presentation/day_target_sheet.dart';
import 'package:fb_mobile/features/targets/presentation/how_sheet.dart';
import 'package:fb_mobile/features/targets/presentation/macro_sheet.dart';
import 'package:fb_mobile/features/targets/presentation/macro_summary.dart';
import 'package:fb_mobile/features/targets/presentation/targets_day_rollover.dart';
import 'package:fb_mobile/features/targets/presentation/targets_feedback.dart';
import 'package:fb_mobile/features/targets/presentation/targets_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:material_ui/material_ui.dart';

/// Me › Targets (D-090, A53 D6; TG-021/040–045/054, SF-012): a suggested
/// number a day that the user can change per weekday, the calculation only
/// on demand. Every change is one `TargetsActions` command with Undo.
class TargetsScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final view = ref.watch(targetsViewProvider);
    return TargetsDayRollover(
      child: Scaffold(
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
      ),
    );
  }
}

/// The Targets screen's content for [view] (public for the goldens), the
/// D-090 layout (sketch `Targets`): the issue banners, the top card
/// (today's number, the week's total, "Same every day | Different by day"
/// and the weekday bars), the macros card and three rows: "How is this
/// worked out?", Goal and More options.
class TargetsBody extends StatelessWidget {
  /// Shows [view].
  const new({required this.view, super.key});

  /// What the screen shows.
  final TargetsView view;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        FbSpace.s4,
        FbSpace.s2,
        FbSpace.s4,
        FbSpace.s6,
      ),
      children: [
        _Banners(view: view),
        _WeekCard(view: view),
        const SizedBox(height: FbSpace.s4),
        FbCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FbSpace.s3,
            children: [
              Text(l10n.targetsMacrosTitle, style: FbType.title),
              MacroSummary(macros: view.day.day.macros),
              _Muted(l10n.targetsMacrosNote),
              if (_energyNote(l10n, view.day.day.macros) case final note?)
                _Muted(note),
            ],
          ),
        ),
        const SizedBox(height: FbSpace.s4),
        _Rows(view: view),
      ],
    );
  }

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

/// What needs a look: a manual target to review (SF-012), a goal to update
/// (PA3), a weekday below the floor (A53 D4). Calm info banners.
class _Banners extends ConsumerWidget {
  const new({required this.view});

  final TargetsView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final issues = view.day.issues;
    final floor = DisplayRounding.kcal(view.day.floorKcal);
    final banners = [
      if (issues.contains(TargetIssue.manualNeedsReview))
        FbInlineBanner(
          kind: FbInlineBannerKind.info,
          message: l10n.targetsManualNeedsReview(floor),
        ),
      if (issues.contains(TargetIssue.goalNeedsUpdate))
        FbInlineBanner(
          kind: FbInlineBannerKind.info,
          message: l10n.targetsGoalNeedsUpdate,
          actionLabel: l10n.targetsGoalUpdateAction,
          onAction: () =>
              ref.read(appNavigatorProvider).push(const ProfileRoute()),
        ),
      if (issues.contains(TargetIssue.dayBelowFloor))
        FbInlineBanner(
          kind: FbInlineBannerKind.info,
          message: l10n.targetsDayBelowFloor(floor),
        ),
    ];
    if (banners.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: FbSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s3,
        children: banners,
      ),
    );
  }
}

/// Today's number, the week's total and position, "Same every day |
/// Different by day" and the weekday bars (tap → the day sheet). Under
/// PA7 the segments and bars are read-only with the note.
class _WeekCard extends ConsumerStatefulWidget {
  const new({required this.view});

  final TargetsView view;

  @override
  ConsumerState<_WeekCard> createState() => _WeekCardState();
}

class _WeekCardState extends ConsumerState<_WeekCard> {
  /// "Different by day" picked while every day is still the same: only
  /// the screen's choice, nothing is written until a day changes.
  bool _pickedDifferent = false;

  Future<void> _sameEveryDay() async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final view = widget.view;
    setState(() => _pickedDifferent = false);
    final outcome = await ref
        .read(targetsActionsProvider)
        .sameEveryDay(view.shown);
    if (!host.mounted) return;
    showTargetsFeedback(
      host,
      outcome,
      done: (_) => host.l10n.targetsSameEveryDayDone(
        DisplayRounding.kcal(view.suggestionKcal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final view = widget.view;
    final forced = view.forcedFixed;
    final different = view.differentByDay || (_pickedDifferent && !forced);
    final position = view.day.week;
    final week = view.day.day.week;
    final dayFormat = DateFormat.E(l10n.localeName);
    final dates = view.weekDates;
    return FbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s2,
        children: [
          _Muted(l10n.targetsTodayOn(weekdayName(l10n, view.today.weekday))),
          Text(
            l10n.targetsTodayKcal(DisplayRounding.kcal(view.day.day.kcal)),
            key: const ValueKey('targets-today'),
            style: FbType.numeric(FbType.headline)
                .copyWith(color: scheme.onSurface),
          ),
          Text(
            l10n.targetsWeekTotal(DisplayRounding.kcal(view.weekTotalKcal)),
            style: FbType.numeric(FbType.body)
                .copyWith(color: scheme.onSurface),
          ),
          if (position != null)
            Text(
              weekPositionText(l10n, position),
              style: FbType.bodySmall.copyWith(color: scheme.onSurface),
            ),
          if (week != null && DisplayRounding.kcal(week.carryKcal) != 0)
            _Muted(l10n.targetsCarryNote),
          const SizedBox(height: FbSpace.s2),
          FbSegmented<bool>(
            options: [
              FbOption(value: false, label: l10n.targetsSameEveryDay),
              FbOption(value: true, label: l10n.targetsDifferentByDay),
            ],
            selected: different,
            onSelected: (pick) {
              if (forced) return;
              if (pick) {
                setState(() => _pickedDifferent = true);
              } else if (view.differentByDay) {
                unawaited(_sameEveryDay());
              } else {
                setState(() => _pickedDifferent = false);
              }
            },
          ),
          if (forced) _Muted(l10n.targetsForcedFixedNote),
          const SizedBox(height: FbSpace.s2),
          FbWeekBars(
            key: const ValueKey('targets-week-bars'),
            bars: [
              for (final date in dates)
                FbWeekBar(
                  value: view.plannedKcal(date.weekday),
                  valueLabel: NumberFormat.decimalPattern(l10n.localeName)
                      .format(
                        DisplayRounding.kcal(view.plannedKcal(date.weekday)),
                      ),
                  label: dayFormat.format(
                    DateTime(date.year, date.month, date.day),
                  ),
                  highlighted: date == view.today,
                  semanticLabel:
                      (date == view.today
                      ? l10n.targetsDayBarToday
                      : l10n.targetsDayBarLabel)(
                        weekdayName(l10n, date.weekday),
                        DisplayRounding.kcal(view.plannedKcal(date.weekday)),
                      ),
                ),
            ],
            onTap: forced
                ? null
                : (i) => unawaited(
                    showDayTargetSheet(
                      context,
                      view: view,
                      weekday: dates[i].weekday,
                    ),
                  ),
          ),
          if (!forced) _Muted(l10n.targetsTapDayHint),
        ],
      ),
    );
  }
}

/// "How is this worked out?", Goal and More options.
class _Rows extends ConsumerWidget {
  const new({required this.view});

  final TargetsView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final goal = view.explanation?.goal;
    final weight = massText(l10n, view.day.weightKg, view.units.bodyMass);
    return FbCard(
      padding: EdgeInsetsDirectional.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FbListRow(
            title: l10n.targetsHowRow,
            subtitle: l10n.targetsHowRowHint,
            trailing: const Icon(FbIcons.next),
            onTap: () => unawaited(showHowSheet(context, view: view)),
          ),
          FbListRow(
            title: l10n.targetsGoalRow,
            subtitle: goal == null
                ? weight
                : l10n.targetsGoalRowValue(
                    goalTypeLabel(l10n, goal.type),
                    weight,
                  ),
            trailing: const Icon(FbIcons.next),
            onTap: () =>
                ref.read(appNavigatorProvider).push(const ProfileRoute()),
          ),
          FbListRow(
            title: l10n.targetsMoreOptions,
            subtitle: l10n.targetsMoreOptionsHint,
            trailing: const Icon(FbIcons.next),
            onTap: () => unawaited(
              showFbSheet<void>(
                context,
                builder: (_) => const MoreOptionsSheet(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// More options (D-090): "Balance over/under across the week" (TG-041,
/// off with the note under PA7) and the macro split. Follows the live view,
/// so the switch shows each change at once.
class MoreOptionsSheet extends ConsumerWidget {
  /// Creates the sheet.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final view = ref.watch(targetsViewProvider).value;
    if (view == null) return const SizedBox.shrink();
    final macros = view.version.macros;
    final custom =
        macros.protein != null ||
        macros.fat != null ||
        macros.carbs != null ||
        macros.fiberGrams != null ||
        macros.caloriesProteinOnly;
    return FbSheet(
      title: l10n.targetsMoreOptions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FbSwitchRow(
            title: l10n.targetsBalancing,
            subtitle: view.forcedFixed
                ? l10n.targetsForcedFixedNote
                : l10n.targetsRebalancingHint,
            value: view.balancing && !view.forcedFixed,
            onChanged: view.forcedFixed
                ? null
                : (on) => unawaited(_balancing(context, ref, view, on)),
          ),
          FbListRow(
            title: l10n.targetsMacroSettings,
            subtitle: custom
                ? l10n.targetsMacroSettingsCustom
                : l10n.targetsMacroSettingsDefault,
            trailing: const Icon(FbIcons.next),
            onTap: () {
              final host = Navigator.of(context, rootNavigator: true).context;
              Navigator.of(context).pop();
              unawaited(showMacroSheet(host, view: view));
            },
          ),
        ],
      ),
    );
  }

  static Future<void> _balancing(
    BuildContext context,
    WidgetRef ref,
    TargetsView view,
    bool on,
  ) async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final outcome = await ref
        .read(targetsActionsProvider)
        .setBalancing(view.shown, on);
    if (!host.mounted) return;
    if (outcome case TargetsFailed(reason: TargetsFailure.changed)) {
      showFbSnackBar(host, host.l10n.targetsChangedTryAgain);
      return;
    }
    showTargetsFeedback(host, outcome, done: (_) => host.l10n.targetsUpdated);
  }
}

/// [day]'s full name in the locale ("Friday").
String weekdayName(AppLocalizations l10n, DayOfWeek day) {
  // 2026-10-19 is a Monday; DayOfWeek runs Monday … Sunday.
  final date = DateTime(2026, 10, 19 + day.index);
  return DateFormat.EEEE(l10n.localeName).format(date);
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
