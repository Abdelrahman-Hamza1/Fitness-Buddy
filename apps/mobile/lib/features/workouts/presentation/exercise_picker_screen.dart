import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/workouts/application/exercise_library.dart';
import 'package:fb_mobile/features/workouts/application/exercise_picker.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart';
import 'package:fb_mobile/features/workouts/presentation/custom_exercise_screen.dart';
import 'package:fb_mobile/features/workouts/presentation/exercise_muscle_map.dart';
import 'package:fb_mobile/features/workouts/presentation/exercise_screen.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the exercise picker on the current tab's navigator and resolves
/// with the picked exercise IDs in pick order (empty when closed). A page
/// that returns a result, like a sheet (A37 D13). [setsAndRepsOnly] hides
/// time and cardio exercises (template lines, A37 D17).
Future<List<String>> pickExercises(
  BuildContext context, {
  bool setsAndRepsOnly = false,
}) async =>
    await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => ExercisePickerScreen(setsAndRepsOnly: setsAndRepsOnly),
      ),
    ) ??
    const [];

/// The exercise picker (WO-001, A37 D12, D-089): with nothing typed, "Your
/// recent" (with the last result) then "Most popular"; search by name or
/// alias (ties by popularity), a chip per muscle group (and Cardio), an
/// equipment filter, multi-select in order, and "Create …" for a custom
/// exercise (WO-003). Pops with the picked IDs.
///
/// In browse mode ("All exercises", A37 D13) the same list opens an
/// exercise's page instead of selecting it.
class ExercisePickerScreen extends ConsumerStatefulWidget {
  /// Creates the picker.
  const new({this.setsAndRepsOnly = false, super.key}) : browseTab = null;

  /// The "All exercises" list of [tab]: a tap opens the exercise's page.
  const new browse({required ExerciseBrowseTab tab, super.key})
    : browseTab = tab,
      setsAndRepsOnly = false;

  /// The tab browse mode opens pages in, or `null` when picking.
  final ExerciseBrowseTab? browseTab;

  /// Whether only sets × reps exercises are offered (no time or cardio).
  final bool setsAndRepsOnly;

  @override
  ConsumerState<ExercisePickerScreen> createState() => _PickerState();
}

class _PickerState extends ConsumerState<ExercisePickerScreen> {
  final TextEditingController _query = TextEditingController();

  /// This screen's own picker state (A37 D12).
  final Object _scope = Object();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final id = await openCustomExercise(context, initialName: _query.text);
    if (id == null || !mounted) return;
    if (widget.browseTab case final tab?) {
      _open(tab, id);
    } else {
      ref.read(exercisePickerProvider(_scope).notifier).pick(id);
    }
  }

  void _open(ExerciseBrowseTab tab, String id) =>
      ref.read(appNavigatorProvider).push(tab.page(id));

  Future<void> _edit(String id) async {
    await openCustomExercise(context, id: id);
  }

  Future<void> _chooseEquipment(
    ExerciseLibrary library,
    Equipment? current,
  ) async {
    final l10n = context.l10n;
    // The empty string stands for "Any equipment".
    final choice = await showFbSheet<String>(
      context,
      title: l10n.workoutPickEquipmentTitle,
      builder: (sheet) => FbOptionList<String>(
        options: [
          FbOption(value: '', label: l10n.workoutPickEquipmentAny),
          for (final e in Equipment.values)
            if (library.equipment.contains(e))
              FbOption(value: e.name, label: l10n.equipment(e)),
        ],
        selected: current?.name ?? '',
        onSelected: (value) => Navigator.of(sheet).pop(value),
      ),
    );
    if (choice == null || !mounted) return;
    ref
        .read(exercisePickerProvider(_scope).notifier)
        .equipmentIs(Equipment.values.asNameMap()[choice]);
  }

  Widget _row(
    LibraryExercise exercise,
    ExerciseBrowseTab? browseTab,
    ExercisePickerState picker,
    ExercisePicker notifier, {
    SetValues? last,
  }) => _ExerciseRow(
    key: ValueKey('workout-pick-${exercise.id}'),
    exercise: exercise,
    browse: browseTab != null,
    position: picker.positionOf(exercise.id),
    last: last,
    onTap: browseTab == null
        ? () => notifier.toggle(exercise.id)
        : () => _open(browseTab, exercise.id),
    onEdit: exercise.isCustom ? () => _edit(exercise.id) : null,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final library =
        ref.watch(exerciseLibraryProvider).value ?? ExerciseLibrary.empty;
    final picker = ref.watch(exercisePickerProvider(_scope));
    final notifier = ref.read(exercisePickerProvider(_scope).notifier);
    final browseTab = widget.browseTab;
    final setsAndRepsOnly = widget.setsAndRepsOnly;
    bool offered(LibraryExercise e) => !setsAndRepsOnly || e.type.hasReps;
    final results = [
      for (final e in library.search(
        picker.query,
        filter: picker.filter,
        equipment: picker.equipment,
      ))
        if (offered(e)) e,
    ];
    // Nothing typed: "Your recent" first, then the rest, most popular first
    // (D-089). The recent ones pass the same chip and equipment filters.
    final recent = !picker.browsing
        ? const <(LibraryExercise, RecentExercise)>[]
        : [
            for (final r
                in ref.watch(recentExercisesProvider).value ??
                    const <RecentExercise>[])
              if (results.where((e) => e.id == r.exerciseId).firstOrNull
                  case final e?)
                (e, r),
          ];
    final recentIds = {for (final (e, _) in recent) e.id};
    final rest = [
      for (final e in results)
        if (!recentIds.contains(e.id)) e,
    ];
    final rows = <Widget Function()>[
      if (recent.isNotEmpty) ...[
        () => _SectionLabel(
          key: const ValueKey('workout-pick-recent'),
          label: l10n.workoutPickRecent,
        ),
        for (final (e, r) in recent)
          () => _row(e, browseTab, picker, notifier, last: r.top),
      ],
      if (picker.browsing && rest.isNotEmpty)
        () => _SectionLabel(
          key: const ValueKey('workout-pick-popular'),
          label: l10n.workoutPickPopular,
        ),
      for (final e in rest) () => _row(e, browseTab, picker, notifier),
    ];
    final count = picker.selected.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          browseTab == null
              ? l10n.workoutPickTitle
              : l10n.workoutExercisesTitle,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              FbSpace.s4,
              FbSpace.s2,
              FbSpace.s4,
              FbSpace.s2,
            ),
            child: FbSearchField(
              controller: _query,
              hint: l10n.workoutPickSearchHint,
              onChanged: notifier.search,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: FbSpace.s4,
            ),
            child: Row(
              children: [
                for (final (filter, label) in [
                  (ExerciseFilter.all, l10n.workoutPickAll),
                  for (final group in MuscleGroup.values)
                    if (library.groups.contains(group))
                      (ExerciseFilter.group(group), l10n.muscleGroup(group)),
                  if (library.hasCardio && !setsAndRepsOnly)
                    (ExerciseFilter.cardio, l10n.workoutPickCardio),
                ])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: FbSpace.s2),
                    child: FbChoiceChip(
                      label: label,
                      dropdown: false,
                      selected: picker.filter == filter,
                      onTap: () => notifier.filterBy(filter),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              FbSpace.s4,
              FbSpace.s2,
              FbSpace.s4,
              0,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FbChoiceChip(
                key: const ValueKey('workout-pick-equipment'),
                label: switch (picker.equipment) {
                  null => l10n.workoutPickEquipmentAny,
                  final e => l10n.equipment(e),
                },
                selected: picker.equipment != null,
                onTap: () =>
                    unawaited(_chooseEquipment(library, picker.equipment)),
              ),
            ),
          ),
          const SizedBox(height: FbSpace.s2),
          Expanded(
            child: ListView.builder(
              itemCount: rows.length + 1,
              itemBuilder: (context, i) {
                if (i == rows.length) {
                  final name = picker.query.trim();
                  return FbListRow(
                    key: const ValueKey('workout-pick-create'),
                    leading: const Icon(FbIcons.add),
                    title: name.isEmpty
                        ? l10n.workoutPickCreateBlank
                        : l10n.workoutPickCreate(name),
                    subtitle: results.isEmpty
                        ? l10n.workoutPickNoResults
                        : null,
                    onTap: _create,
                  );
                }
                return rows[i]();
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: browseTab != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsetsDirectional.all(FbSpace.s4),
                child: FbButton.primary(
                  key: const ValueKey('workout-pick-add'),
                  label: l10n.workoutPickAdd(count),
                  expand: true,
                  onPressed: count == 0
                      ? null
                      : () => Navigator.of(context).pop(picker.selected),
                ),
              ),
            ),
    );
  }
}

/// A picker section's label ("YOUR RECENT", "MOST POPULAR").
class _SectionLabel extends StatelessWidget {
  const new({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(horizontal: FbSpace.s4),
    child: FbSectionHeader(title: label),
  );
}

class _ExerciseRow extends StatelessWidget {
  const new({
    required this.exercise,
    required this.browse,
    required this.position,
    required this.onTap,
    required this.onEdit,
    this.last,
    super.key,
  });

  final LibraryExercise exercise;
  final bool browse;
  final int? position;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  /// The top set of its latest session ("last: 62.5 kg × 8"), in "Your
  /// recent".
  final SetValues? last;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = exercise.primary;
    final position = this.position;
    return Semantics(
      selected: browse ? null : position != null,
      value: position == null ? null : l10n.workoutPickSelected(position),
      child: FbListRow(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!browse)
              SizedBox.square(
                dimension: FbSpace.s5,
                child: position == null
                    ? null
                    : Center(
                        child: Text(
                          '$position',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
              ),
            ExerciseMuscleMap(
              primary: primary,
              secondaries: exercise.secondaries,
              height: ExerciseMuscleMap.rowHeight,
            ),
          ],
        ),
        title: exercise.name,
        subtitle: [
          if (primary != null) l10n.muscleGroup(primary.group),
          l10n.equipment(exercise.equipment),
          if (exercise.isCustom) l10n.workoutPickCustomTag,
          if (last case final last?)
            l10n.workoutPickLast(l10n.setValues(exercise.type, last)),
        ].join(' · '),
        trailing: onEdit == null
            ? null
            : FbIconButton(
                icon: FbIcons.edit,
                tooltip: l10n.workoutPickEditCustom,
                onPressed: onEdit,
              ),
        onTap: onTap,
      ),
    );
  }
}
