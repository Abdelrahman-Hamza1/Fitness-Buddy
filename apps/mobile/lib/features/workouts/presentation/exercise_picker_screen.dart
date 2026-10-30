import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/workouts/application/exercise_library.dart';
import 'package:fb_mobile/features/workouts/application/exercise_picker.dart';
import 'package:fb_mobile/features/workouts/presentation/custom_exercise_screen.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the exercise picker on the current tab's navigator and resolves
/// with the picked exercise IDs in pick order (empty when closed). A page
/// that returns a result, like a sheet (A37 D13).
Future<List<String>> pickExercises(BuildContext context) async =>
    await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
    ) ??
    const [];

/// The exercise picker (WO-001, A37 D12): search by name or alias, a chip
/// per muscle group (and Cardio), multi-select in order, and "Create …" for
/// a custom exercise (WO-003). Pops with the picked IDs.
class ExercisePickerScreen extends ConsumerStatefulWidget {
  /// Creates the picker.
  const new({super.key});

  @override
  ConsumerState<ExercisePickerScreen> createState() => _PickerState();
}

class _PickerState extends ConsumerState<ExercisePickerScreen> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final id = await openCustomExercise(context, initialName: _query.text);
    if (id != null && mounted) {
      ref.read(exercisePickerProvider.notifier).pick(id);
    }
  }

  Future<void> _edit(String id) async {
    await openCustomExercise(context, id: id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final library =
        ref.watch(exerciseLibraryProvider).value ?? ExerciseLibrary.empty;
    final picker = ref.watch(exercisePickerProvider);
    final notifier = ref.read(exercisePickerProvider.notifier);
    final results = library.search(picker.query, filter: picker.filter);
    final count = picker.selected.length;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.workoutPickTitle)),
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
                  if (library.hasCardio)
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
                  position: picker.positionOf(exercise.id),
                  onTap: () => notifier.toggle(exercise.id),
                  onEdit: exercise.isCustom ? () => _edit(exercise.id) : null,
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
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

class _ExerciseRow extends StatelessWidget {
  const new({
    required this.exercise,
    required this.position,
    required this.onTap,
    required this.onEdit,
  });

  final LibraryExercise exercise;
  final int? position;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = exercise.primary;
    final position = this.position;
    return Semantics(
      selected: position != null,
      value: position == null ? null : l10n.workoutPickSelected(position),
      child: FbListRow(
        key: ValueKey('workout-pick-${exercise.id}'),
        leading: SizedBox.square(
          dimension: FbSpace.s5,
          child: position == null
              ? null
              : Center(
                  child: Text(
                    '$position',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
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
