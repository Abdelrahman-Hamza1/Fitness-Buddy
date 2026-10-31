import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/workouts/application/exercise_library.dart';
import 'package:fb_mobile/features/workouts/application/workout_actions.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:fb_mobile/features/workouts/presentation/exercise_muscle_map.dart';
import 'package:fb_mobile/features/workouts/presentation/plan_setup_screen.dart';
import 'package:fb_mobile/features/workouts/presentation/template_editor_screen.dart';
import 'package:fb_mobile/features/workouts/presentation/weekly_plan_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// What the plan chooser offers (D-089): no plan first, the starter plans,
/// then "Make my own".
@immutable
sealed class _Choice {
  const new();
}

final class _NoPlan extends _Choice {
  const new();
}

final class _Starter extends _Choice {
  const new(this.plan);

  final StarterPlan plan;

  @override
  bool operator ==(Object other) => other is _Starter && other.plan == plan;

  @override
  int get hashCode => plan.hashCode;
}

final class _Own extends _Choice {
  const new();
}

/// The plan chooser (WO-023, D-085, D-089): "No plan, I'll log as I go",
/// Full body, Upper/Lower, Push/Pull/Legs (with their muscles and days) and
/// "Make my own". A starter plan then asks for the weekdays and opens the
/// day-by-day exercise choice, which starts empty: nothing is assumed, and
/// nothing changes until the user saves it (one change set, one undo,
/// asking first when a plan exists). The first run opens this route too
/// (A51): keep [WorkoutStarterPlansRoute] stable.
class StarterPlansScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  ConsumerState<StarterPlansScreen> createState() => _ChooserState();
}

class _ChooserState extends ConsumerState<StarterPlansScreen> {
  // The highlighted option: ephemeral, nothing is written until Continue.
  _Choice? _choice;

  // Continue runs once at a time: a second tap while a write is pending
  // must not pop another screen.
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final library =
        ref.watch(exerciseLibraryProvider).value ?? ExerciseLibrary.empty;
    // Kept loaded for Continue (does a plan exist to replace or clear?).
    ref.watch(workoutPlanProvider);
    final choice = _choice;
    Widget option({
      required _Choice value,
      required String key,
      required String title,
      required String subtitle,
      String? tag,
      Widget? map,
    }) {
      final selected = choice == value;
      return Padding(
        padding: const EdgeInsetsDirectional.only(bottom: FbDensity.cardGap),
        child: Semantics(
          selected: selected,
          inMutuallyExclusiveGroup: true,
          child: FbCard(
            key: ValueKey('workout-starter-$key'),
            onTap: () => setState(() => _choice = value),
            child: Row(
              spacing: FbSpace.s3,
              children: [
                ?map,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: FbSpace.s1,
                    children: [
                      Text(title, style: FbType.title),
                      Text(
                        subtitle,
                        style: FbType.bodySmall.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (tag != null)
                        Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: FbSpace.s2,
                            vertical: FbSpace.s1,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? scheme.primaryContainer
                                : scheme.surfaceContainerHighest,
                            borderRadius: FbRadius.mdAll,
                          ),
                          child: Text(
                            tag,
                            style: FbType.caption.copyWith(
                              color: selected
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurface,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  selected ? FbIcons.optionOn : FbIcons.optionOff,
                  color: selected ? scheme.primary : scheme.outline,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      // While Continue runs, Back waits: its result closes this screen,
      // and only this screen.
      canPop: !_busy,
      child: AbsorbPointer(
        absorbing: _busy,
        child: Scaffold(
          appBar: AppBar(title: Text(l10n.workoutsChoosePlan)),
          body: ListView(
            padding: const EdgeInsetsDirectional.all(FbSpace.s4),
            children: [
              Text(l10n.workoutStarterHeading, style: FbType.headline),
              const SizedBox(height: FbSpace.s1),
              Text(
                l10n.workoutStarterIntro,
                style: FbType.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: FbSpace.s4),
              option(
                value: const _NoPlan(),
                key: 'none',
                title: l10n.workoutStarterNone,
                subtitle: l10n.workoutStarterNoneInfo,
              ),
              for (final plan in StarterPlan.values)
                option(
                  value: _Starter(plan),
                  key: plan.name,
                  title: l10n.workoutStarterPlan(plan.name),
                  subtitle: l10n.workoutStarterPlanInfo(plan.name),
                  tag: l10n.workoutStarterPlanDays(plan.name),
                  map: ExerciseMuscleMap.union(
                    library.musclesOf([
                      for (final t in plan.templates)
                        for (final i in t.items) i.exerciseId,
                    ]),
                    height: _optionMapHeight,
                  ),
                ),
              option(
                value: const _Own(),
                key: 'own',
                title: l10n.workoutStarterOwn,
                subtitle: l10n.workoutStarterOwnInfo,
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(FbSpace.s4),
              child: FbButton.primary(
                key: const ValueKey('workout-starter-continue'),
                label: switch (choice) {
                  _Starter(:final plan) => l10n.workoutStarterContinue(
                    l10n.workoutStarterPlan(plan.name),
                  ),
                  _ => l10n.workoutStarterContinuePlain,
                },
                expand: true,
                onPressed: choice == null || _busy
                    ? null
                    : () => unawaited(_continue(choice)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Whether the chooser is still open and on top of its own navigator
  /// (only then may a result close it).
  bool get _isCurrent =>
      mounted && (ModalRoute.of(context)?.isCurrent ?? false);

  /// Closes the chooser through its **own** navigator, never the router's
  /// current location: the user may have switched tabs while a write ran,
  /// and that tab's screen must stay (A52 review).
  void _close() {
    if (_isCurrent) Navigator.of(context).pop();
  }

  Future<void> _continue(_Choice choice) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final navigator = ref.read(appNavigatorProvider);
      switch (choice) {
        case _NoPlan():
          await _noPlan();
        case _Own():
          // "Make my own": a first workout, then "Your plan" to give it days.
          final id = await openTemplateEditor(context);
          if (id == null || !_isCurrent) return;
          _close();
          navigator.push(const WorkoutPlanRoute());
        case _Starter(:final plan):
          await _starter(plan);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// "No plan, I'll log as I go": clears a weekly plan (with Undo); without
  /// one there's nothing to change. The chooser closes only while it's
  /// still open.
  Future<void> _noPlan() async {
    // Read now, not from a cached watch: the plan may not be loaded yet.
    final hasPlan = (await ref.read(workoutPlanProvider.future)).isNotEmpty;
    if (!mounted) return;
    if (!hasPlan) {
      _close();
      return;
    }
    final l10n = context.l10n;
    final host = Navigator.of(context, rootNavigator: true).context;
    final outcome = await ref.read(workoutActionsProvider).clearPlan();
    switch (outcome) {
      case WorkoutActionDone(:final undoId):
        _close();
        if (host.mounted) {
          showUndoFeedback(
            host,
            message: l10n.workoutStarterCleared,
            undoEntryId: undoId,
          );
        }
      case WorkoutActionUnchanged():
        _close();
      case WorkoutActionFailed():
        if (host.mounted) showFbSnackBar(host, l10n.workoutActionRefused);
    }
  }

  /// A starter plan: its weekdays, then its days' exercises; the setup
  /// screen saves it (and stays open with every choice if saving fails).
  Future<void> _starter(StarterPlan plan) async {
    final l10n = context.l10n;
    final weekStart = ref.read(weekStartProvider).value ?? DayOfWeek.saturday;
    final days = await showFbSheet<Set<DayOfWeek>>(
      context,
      title: l10n.workoutStarterPlan(plan.name),
      builder: (_) => StarterPlanSheet(plan: plan, weekStart: weekStart),
    );
    if (days == null || !mounted) return;
    final saved = await openPlanSetup(
      context,
      plan,
      days: days,
      weekStart: weekStart,
    );
    if (saved) _close();
  }
}

/// A plan option's map: small, beside its name.
const double _optionMapHeight = 56;

/// A starter plan's weekdays sheet: pre-filled from the week start; pops
/// with the picked days when they fit the plan.
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
  // plan is saved.
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
        Text(l10n.workoutStarterDaysQuestion, style: FbType.body),
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
