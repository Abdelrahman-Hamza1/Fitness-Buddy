import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/workouts/application/exercise_library.dart';
import 'package:fb_mobile/features/workouts/application/exercise_picker.dart';
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

/// The exercise picker (WO-001, A37 D12): search by name or alias, a chip
/// per muscle group (and Cardio), multi-select in order, and "Create …" for
/// a custom exercise (WO-003). Pops with the picked IDs.
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final library =
        ref.watch(exerciseLibraryProvider).value ?? ExerciseLibrary.empty;
    final picker = ref.watch(exercisePickerProvider(_scope));
    final notifier = ref.read(exercisePickerProvider(_scope).notifier);
    final browseTab = widget.browseTab;
    final setsAndRepsOnly = widget.setsAndRepsOnly;
    final results = [
      for (final e in library.search(picker.query, filter: picker.filter))
        if (!setsAndRepsOnly || e.type.hasReps) e,
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
          const SizedBox(height: FbSpace.s2),
          Expanded(
            child: ListView.builder(
              itemCount: results.length + 1,
              itemBuilder: (context, i) {
                if (i == results.length) {
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
                final exercise = results[i];
                return _ExerciseRow(
                  exercise: exercise,
                  browse: browseTab != null,
                  position: picker.positionOf(exercise.id),
                  onTap: browseTab == null
                      ? () => notifier.toggle(exercise.id)
                      : () => _open(browseTab, exercise.id),
                  onEdit: exercise.isCustom ? () => _edit(exercise.id) : null,
                );
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

/// The height of a picker row's muscle map: small enough for a list row.
const double _mapHeight = 44;

class _ExerciseRow extends StatelessWidget {
  const new({
    required this.exercise,
    required this.browse,
    required this.position,
    required this.onTap,
    required this.onEdit,
  });

  final LibraryExercise exercise;
  final bool browse;
  final int? position;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = exercise.primary;
    final position = this.position;
    return Semantics(
      selected: browse ? null : position != null,
      value: position == null ? null : l10n.workoutPickSelected(position),
      child: FbListRow(
        key: ValueKey('workout-pick-${exercise.id}'),
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
              height: _mapHeight,
            ),
          ],
        ),
        title: exercise.name,
        subtitle: [
          if (primary != null) l10n.muscleGroup(primary.group),
          l10n.equipment(exercise.equipment),
          if (exercise.isCustom) l10n.workoutPickCustomTag,
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
