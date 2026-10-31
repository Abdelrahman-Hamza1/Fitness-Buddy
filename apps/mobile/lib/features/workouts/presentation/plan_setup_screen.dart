import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/workouts/application/exercise_library.dart';
import 'package:fb_mobile/features/workouts/application/plan_setup.dart';
import 'package:fb_mobile/features/workouts/application/workout_actions.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:fb_mobile/features/workouts/presentation/exercise_muscle_map.dart';
import 'package:fb_mobile/features/workouts/presentation/exercise_picker_screen.dart';
import 'package:fb_mobile/features/workouts/presentation/template_editor_screen.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the day-by-day exercise choice of [plan] (trained on [days],
/// weeks starting on [weekStart]) on the current tab's navigator; resolves
/// with whether the plan was saved (D-089: nothing is written before Save
/// plan).
Future<bool> openPlanSetup(
  BuildContext context,
  StarterPlan plan, {
  required Set<DayOfWeek> days,
  required DayOfWeek weekStart,
}) async =>
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            PlanSetupScreen(plan: plan, days: days, weekStart: weekStart),
      ),
    ) ??
    false;

/// The exercise choice of a starter plan (WO-023, D-089): a tab per
/// workout day ("Push 2 | Pull 0 | Legs 0"), each starting **empty**: "Your
/// Push exercises" (sets × reps editable, remove), "Find any exercise", and
/// "Suggested for Push" with + per exercise and "Add all". "Save plan"
/// writes the templates and weekdays in one change set with one Undo
/// (asking first when a plan exists) and pops with `true`; a refused save
/// keeps the screen and every choice.
class PlanSetupScreen extends ConsumerStatefulWidget {
  /// The choice of [plan]'s exercises, trained on [days].
  const new({
    required this.plan,
    required this.days,
    required this.weekStart,
    super.key,
  });

  /// The starter plan.
  final StarterPlan plan;

  /// The training days picked before.
  final Set<DayOfWeek> days;

  /// The first day of the user's week.
  final DayOfWeek weekStart;

  @override
  ConsumerState<PlanSetupScreen> createState() => _SetupState();
}

class _SetupState extends ConsumerState<PlanSetupScreen>
    with SingleTickerProviderStateMixin {
  late final PlanSetupKey _key = PlanSetupKey(
    visitId: ref.read(idGeneratorProvider).next(),
    plan: widget.plan,
  );
  late final TabController _tabs = TabController(
    length: widget.plan.templates.length,
    vsync: this,
  )..addListener(_tabChanged);

  void _tabChanged() {
    if (!_tabs.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _tabs
      ..removeListener(_tabChanged)
      ..dispose();
    super.dispose();
  }

  // Save plan runs once at a time.
  bool _saving = false;

  PlanSetup get _setup => ref.read(planSetupProvider(_key).notifier);

  Future<void> _save(PlanSetupState state) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final l10n = context.l10n;
      // Read now, not from a cached watch: the plan may not be loaded yet.
      final hasPlan = (await ref.read(workoutPlanProvider.future)).isNotEmpty;
      if (!mounted) return;
      if (hasPlan) {
        final replace = await showFbSheet<bool>(
          context,
          title: l10n.workoutStarterReplaceTitle,
          builder: (_) => const _ReplaceSheet(),
        );
        if (replace != true || !mounted) return;
      }
      final host = Navigator.of(context, rootNavigator: true).context;
      final outcome = await ref
          .read(workoutActionsProvider)
          .applyStarterPlan(
            widget.plan,
            days: widget.days,
            weekStart: widget.weekStart,
            nameOf: (t) => l10n.workoutStarterTemplate(t.name),
            itemsOf: state.chosenOf,
          );
      switch (outcome) {
        case WorkoutActionDone(:final undoId):
          if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
            Navigator.of(context).pop(true);
          }
          if (host.mounted) {
            showUndoFeedback(
              host,
              message: l10n.workoutStarterApplied,
              undoEntryId: undoId,
            );
          }
        case WorkoutActionFailed() || WorkoutActionUnchanged():
          // Every choice stays for another try.
          if (host.mounted) showFbSnackBar(host, l10n.workoutActionRefused);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _find(StarterTemplate day) async {
    final picked = await pickExercises(context, setsAndRepsOnly: true);
    if (!mounted || picked.isEmpty) return;
    _setup.add(day, picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(planSetupProvider(_key));
    // Kept loaded for Save plan (is there a plan to replace?).
    ref.watch(workoutPlanProvider);
    final days = widget.plan.templates;
    final index = _tabs.index;
    final last = index == days.length - 1;
    String dayName(StarterTemplate t) => l10n.workoutStarterTemplate(t.name);
    final scrollTabs =
        days.length > 3 ||
        MediaQuery.textScalerOf(context).scale(1) > _fixedTabsMaxScale;
    return PopScope(
      // While Save plan runs, nothing else navigates or edits: the save
      // closes this screen, and only this screen.
      canPop: !_saving,
      child: AbsorbPointer(
        absorbing: _saving,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.workoutStarterPlan(widget.plan.name)),
            bottom: TabBar(
              controller: _tabs,
              // Four days, or large text, don't fit fixed tabs: they scroll.
              isScrollable: scrollTabs,
              tabAlignment: scrollTabs ? TabAlignment.start : null,
              tabs: [
                for (final day in days)
                  Tab(
                    key: ValueKey('workout-setup-tab-${day.name}'),
                    child: Semantics(
                      label: l10n.workoutSetupTabSemantics(
                        dayName(day),
                        state.chosenOf(day).length,
                      ),
                      excludeSemantics: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: FbSpace.s1,
                        children: [
                          Text(dayName(day)),
                          _Count(count: state.chosenOf(day).length),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: [
              for (final day in days)
                _DayPage(
                  key: ValueKey('workout-setup-day-${day.name}'),
                  day: day,
                  name: dayName(day),
                  state: state,
                  setupKey: _key,
                  onFind: () => unawaited(_find(day)),
                ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(FbSpace.s4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: FbSpace.s2,
                children: [
                  if (last && !state.complete)
                    Text(
                      l10n.workoutSetupIncomplete,
                      textAlign: TextAlign.center,
                      style: FbType.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  FbButton.primary(
                    key: const ValueKey('workout-setup-next'),
                    label: last
                        ? l10n.workoutSetupSave
                        : l10n.workoutSetupNext(dayName(days[index + 1])),
                    expand: true,
                    onPressed: switch ((last, state.complete && !_saving)) {
                      (false, _) => () => _tabs.animateTo(index + 1),
                      (true, true) => () => unawaited(_save(state)),
                      (true, false) => null,
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Above this text scale the day tabs scroll instead of sharing the width.
const double _fixedTabsMaxScale = 1.3;

/// A tab's exercise count badge.
class _Count extends StatelessWidget {
  const new({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: FbSpace.s2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: count > 0
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: FbRadius.mdAll,
      ),
      child: Text(
        '$count',
        style: FbType.caption.copyWith(
          color: count > 0 ? scheme.onPrimaryContainer : scheme.onSurface,
        ),
      ),
    );
  }
}

/// One workout day: its chosen exercises, search, and suggestions.
class _DayPage extends ConsumerWidget {
  const new({
    required this.day,
    required this.name,
    required this.state,
    required this.setupKey,
    required this.onFind,
    super.key,
  });

  final StarterTemplate day;
  final String name;
  final PlanSetupState state;
  final PlanSetupKey setupKey;
  final VoidCallback onFind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final library =
        ref.watch(exerciseLibraryProvider).value ?? ExerciseLibrary.empty;
    final setup = ref.read(planSetupProvider(setupKey).notifier);
    final chosen = state.chosenOf(day);
    final suggestions = state.suggestionsOf(day);
    Widget map(String id) => ExerciseMuscleMap(
      primary: library.byId[id]?.primary,
      secondaries: library.byId[id]?.secondaries ?? const [],
      height: ExerciseMuscleMap.rowHeight,
    );
    String detail(String id) => [
      if (library.byId[id]?.primary case final m?) l10n.muscleGroup(m.group),
      if (library.byId[id]?.equipment case final e?) l10n.equipment(e),
    ].join(' · ');
    return ListView(
      padding: const EdgeInsetsDirectional.all(FbSpace.s4),
      children: [
        FbSectionHeader(title: l10n.workoutSetupYour(name)),
        FbCard(
          padding: EdgeInsetsDirectional.zero,
          child: chosen.isEmpty
              ? Padding(
                  padding: const EdgeInsetsDirectional.all(FbSpace.s4),
                  child: Text(
                    l10n.workoutSetupEmpty,
                    style: FbType.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final (i, line) in chosen.indexed) ...[
                      if (i > 0) const Divider(height: 1),
                      FbListRow(
                        key: ValueKey(
                          'workout-setup-line-${day.name}-${line.exerciseId}',
                        ),
                        leading: map(line.exerciseId),
                        title: l10n.exerciseName(library, line.exerciseId),
                        subtitle: l10n.workoutSetupTarget(line.sets, line.reps),
                        onTap: () => unawaited(
                          _editTarget(
                            context,
                            setup,
                            l10n.exerciseName(library, line.exerciseId),
                            line.exerciseId,
                          ),
                        ),
                        trailing: FbIconButton(
                          key: ValueKey(
                            'workout-setup-remove-${line.exerciseId}',
                          ),
                          icon: FbIcons.close,
                          tooltip: l10n.workoutSetupRemove(
                            l10n.exerciseName(library, line.exerciseId),
                          ),
                          onPressed: () => setup.remove(day, line.exerciseId),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: FbSpace.s3),
        FbCard(
          padding: EdgeInsetsDirectional.zero,
          child: FbListRow(
            key: ValueKey('workout-setup-find-${day.name}'),
            leading: const Icon(FbIcons.search),
            title: l10n.workoutSetupFind,
            onTap: onFind,
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          FbSectionHeader(
            title: l10n.workoutSetupSuggested(name),
            trailing: FbButton.text(
              key: ValueKey('workout-setup-add-all-${day.name}'),
              label: l10n.workoutSetupAddAll(suggestions.length),
              onPressed: () => setup.addAll(day),
            ),
          ),
          FbCard(
            padding: EdgeInsetsDirectional.zero,
            child: Column(
              children: [
                for (final (i, s) in suggestions.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  FbListRow(
                    key: ValueKey(
                      'workout-setup-suggestion-${day.name}-${s.exerciseId}',
                    ),
                    leading: map(s.exerciseId),
                    title: l10n.exerciseName(library, s.exerciseId),
                    subtitle: detail(s.exerciseId),
                    trailing: FbIconButton(
                      key: ValueKey('workout-setup-add-${s.exerciseId}'),
                      icon: FbIcons.add,
                      tooltip: l10n.workoutSetupAdd(
                        l10n.exerciseName(library, s.exerciseId),
                      ),
                      onPressed: () => setup.add(day, [s.exerciseId]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Sets and reps of [exerciseId]'s line, edited live in a sheet.
  Future<void> _editTarget(
    BuildContext context,
    PlanSetup setup,
    String title,
    String exerciseId,
  ) async {
    final l10n = context.l10n;
    await showFbSheet<void>(
      context,
      title: title,
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final line = ref
              .watch(planSetupProvider(setupKey))
              .chosenOf(day)
              .where((l) => l.exerciseId == exerciseId)
              .firstOrNull;
          if (line == null) return const SizedBox.shrink();
          return Wrap(
            spacing: FbSpace.s4,
            runSpacing: FbSpace.s2,
            children: [
              TemplateStepper(
                key: const ValueKey('workout-setup-sets'),
                label: l10n.workoutTemplateSets,
                value: line.sets,
                onChanged: (v) =>
                    setup.setTarget(day, exerciseId, sets: v, reps: line.reps),
              ),
              TemplateStepper(
                key: const ValueKey('workout-setup-reps'),
                label: l10n.workoutFieldReps,
                value: line.reps,
                onChanged: (v) =>
                    setup.setTarget(day, exerciseId, sets: line.sets, reps: v),
              ),
            ],
          );
        },
      ),
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
