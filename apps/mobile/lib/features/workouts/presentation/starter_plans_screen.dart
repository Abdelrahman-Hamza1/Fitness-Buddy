import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/workouts/application/workout_actions.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:fb_mobile/features/workouts/presentation/template_editor_screen.dart';
import 'package:fb_mobile/features/workouts/presentation/weekly_plan_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The optional starter plans gallery (WO-023, D-085, A37 D18): Full body,
/// Upper/Lower, Push/Pull/Legs and Build my own. Picking a plan opens a
/// sheet with its workouts and pre-filled weekdays; nothing changes until
/// "Use this plan", which copies editable templates and the weekdays in one
/// change set with one undo (asking first when a plan exists).
class StarterPlansScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final weekStart = ref.watch(weekStartProvider).value ?? DayOfWeek.saturday;
    final hasPlan = ref.watch(workoutPlanProvider).value?.isNotEmpty ?? false;
    Widget card({
      required Key key,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) => Padding(
      padding: const EdgeInsetsDirectional.only(bottom: FbDensity.cardGap),
      child: FbCard(
        key: key,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: FbType.title),
            Text(
              subtitle,
              style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.workoutsStarterPlansRow)),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(FbSpace.s4),
        children: [
          Text(
            l10n.workoutStarterIntro,
            style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: FbSpace.s3),
          for (final plan in StarterPlan.values)
            card(
              key: ValueKey('workout-starter-${plan.name}'),
              title: l10n.workoutStarterPlan(plan.name),
              subtitle: l10n.workoutStarterPlanInfo(plan.name),
              onTap: () => unawaited(
                _open(
                  context,
                  ref,
                  plan,
                  weekStart: weekStart,
                  hasPlan: hasPlan,
                ),
              ),
            ),
          card(
            key: const ValueKey('workout-starter-own'),
            title: l10n.workoutStarterOwn,
            subtitle: l10n.workoutStarterOwnInfo,
            onTap: () => unawaited(openTemplateEditor(context)),
          ),
        ],
      ),
    );
  }

  /// Shows [plan]'s sheet; applies it when confirmed.
  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    StarterPlan plan, {
    required DayOfWeek weekStart,
    required bool hasPlan,
  }) async {
    final l10n = context.l10n;
    final days = await showFbSheet<Set<DayOfWeek>>(
      context,
      title: l10n.workoutStarterPlan(plan.name),
      builder: (_) => StarterPlanSheet(plan: plan, weekStart: weekStart),
    );
    if (days == null || !context.mounted) return;
    if (hasPlan) {
      final replace = await showFbSheet<bool>(
        context,
        title: l10n.workoutStarterReplaceTitle,
        builder: (_) => const _ReplaceSheet(),
      );
      if (replace != true || !context.mounted) return;
    }
    final host = Navigator.of(context, rootNavigator: true).context;
    final outcome = await ref
        .read(workoutActionsProvider)
        .applyStarterPlan(
          plan,
          days: days,
          weekStart: weekStart,
          nameOf: (t) => l10n.workoutStarterTemplate(t.name),
        );
    if (!host.mounted) return;
    switch (outcome) {
      case WorkoutActionDone(:final undoId):
        ref.read(appNavigatorProvider).pop();
        showUndoFeedback(
          host,
          message: l10n.workoutStarterApplied,
          undoEntryId: undoId,
        );
      case WorkoutActionFailed() || WorkoutActionUnchanged():
        showFbSnackBar(host, l10n.workoutActionRefused);
    }
  }
}

/// A starter plan's sheet: its workouts, and the weekdays (pre-filled
/// from the week start) to train them on. Pops with the picked days.
class StarterPlanSheet extends StatefulWidget {
  /// The sheet of [plan], weeks starting on [weekStart].
  const new({required this.plan, required this.weekStart, super.key});

  /// The plan.
  final StarterPlan plan;

  /// The first day of the user's week.
  final DayOfWeek weekStart;

  @override
  State<StarterPlanSheet> createState() => _SheetState();
}

class _SheetState extends State<StarterPlanSheet> {
  // Ephemeral selection inside a modal sheet; nothing is written until the
  // caller applies the popped days.
  late final Set<DayOfWeek> _days = widget.plan
      .defaultDays(widget.weekStart)
      .toSet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final plan = widget.plan;
    final locale = Localizations.localeOf(context).toString();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        Text(
          plan.templates
              .map((t) => l10n.workoutStarterTemplate(t.name))
              .join(' · '),
          style: FbType.body,
        ),
        Text(
          plan.minDays == plan.maxDays
              ? l10n.workoutStarterDays(plan.minDays)
              : l10n.workoutStarterDaysRange(plan.minDays, plan.maxDays),
          style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
        ),
        Wrap(
          spacing: FbSpace.s2,
          runSpacing: FbSpace.s2,
          children: [
            for (final day in WeekCalendar(
              weekStart: widget.weekStart,
            ).daysInOrder)
              FbChoiceChip(
                key: ValueKey('workout-starter-day-${day.name}'),
                label: weekdayName(locale, day),
                dropdown: false,
                selected: _days.contains(day),
                onTap: () => setState(
                  () =>
                      _days.contains(day) ? _days.remove(day) : _days.add(day),
                ),
              ),
          ],
        ),
        FbButton.primary(
          key: const ValueKey('workout-starter-apply'),
          label: l10n.workoutStarterApply,
          expand: true,
          onPressed: plan.fits(_days.length)
              ? () => Navigator.of(context).pop(Set.of(_days))
              : null,
        ),
      ],
    );
  }
}

/// "Replace your weekly plan? Your templates stay." Keep (dominant) or
/// Replace.
class _ReplaceSheet extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        Text(
          l10n.workoutStarterReplaceMessage,
          style: FbType.body.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        FbButton.primary(
          label: l10n.workoutStarterKeep,
          expand: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        FbButton.secondary(
          key: const ValueKey('workout-starter-replace'),
          label: l10n.workoutStarterReplace,
          expand: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
