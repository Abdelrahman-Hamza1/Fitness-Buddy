import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/workouts/application/exercise_library.dart';
import 'package:fb_mobile/features/workouts/application/workout_actions.dart';
import 'package:fb_mobile/features/workouts/data/workout_repository.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'custom_exercise_form.g.dart';

/// Which custom exercise form: a new one (named [initialName], the picker's
/// search text) or exercise [id].
@immutable
final class CustomExerciseKey {
  /// The form for exercise [id], or a new one when it's `null`.
  const new({this.id, this.initialName = ''});

  /// The exercise to edit, or `null`.
  final String? id;

  /// A new exercise's starting name.
  final String initialName;

  @override
  bool operator ==(Object other) =>
      other is CustomExerciseKey &&
      other.id == id &&
      other.initialName == initialName;

  @override
  int get hashCode => Object.hash(CustomExerciseKey, id, initialName);
}

/// The custom exercise form (WO-003, WO-007, A37 D6, D15).
@immutable
final class CustomExerciseFormState {
  /// A form state.
  new({
    required this.name,
    required this.aliases,
    required this.type,
    required this.equipment,
    this.primary,
    Iterable<Muscle> secondaries = const [],
    this.stored,
    this.inUse = false,
    this.submitted = false,
    this.saving = false,
  }) : secondaries = List.unmodifiable(secondaries);

  /// The name as typed.
  final String name;

  /// The aliases as typed, comma-separated.
  final String aliases;

  /// What a set logs.
  final ExerciseType type;

  /// The equipment.
  final Equipment equipment;

  /// The main muscle (required to save).
  final Muscle? primary;

  /// Secondary muscles (at most 4, never [primary]).
  final List<Muscle> secondaries;

  /// The stored exercise being edited, or `null` for a new one.
  final Stored<CustomExerciseDraft>? stored;

  /// Whether sessions or templates use it: its type is locked and it can't
  /// be deleted (A36, D15).
  final bool inUse;

  /// Whether Save was tapped (errors show from then on).
  final bool submitted;

  /// Whether a save or delete is running.
  final bool saving;

  /// The trimmed alias list.
  List<String> get aliasList => [
    for (final a in aliases.split(','))
      if (a.trim().isNotEmpty) a.trim(),
  ];

  /// Whether there are more aliases than a custom exercise may have.
  bool get tooManyAliases =>
      aliasList.toSet().length > WorkoutLimits.aliasesMax;

  /// Whether an alias is longer than a name may be.
  bool get aliasTooLong =>
      aliasList.any((a) => a.runes.length > WorkoutLimits.nameMax);

  /// Whether the name is missing.
  bool get nameMissing => name.trim().isEmpty;

  /// Whether the main muscle is missing.
  bool get primaryMissing => primary == null;

  /// The draft to save, or `null` while something is missing or invalid.
  CustomExerciseDraft? get draft {
    if (nameMissing || primaryMissing || tooManyAliases || aliasTooLong) {
      return null;
    }
    try {
      return CustomExerciseDraft(
        name: name,
        type: type,
        equipment: equipment,
        aliases: aliasList,
        primaryMuscle: primary,
        secondaryMuscles: secondaries,
      );
      // Too long or too many: the fields' limits show it.
      // ignore: avoid_catching_errors
    } on ArgumentError {
      return null;
    }
  }

  /// This state with some fields changed.
  CustomExerciseFormState copyWith({
    String? name,
    String? aliases,
    ExerciseType? type,
    Equipment? equipment,
    Muscle? primary,
    Iterable<Muscle>? secondaries,
    bool? inUse,
    bool? submitted,
    bool? saving,
  }) => CustomExerciseFormState(
    name: name ?? this.name,
    aliases: aliases ?? this.aliases,
    type: type ?? this.type,
    equipment: equipment ?? this.equipment,
    primary: primary ?? this.primary,
    secondaries: secondaries ?? this.secondaries,
    stored: stored,
    inUse: inUse ?? this.inUse,
    submitted: submitted ?? this.submitted,
    saving: saving ?? this.saving,
  );
}

/// The custom exercise form's view model: edits, Save and Delete as direct
/// actions with undo (through [WorkoutActions]).
@riverpod
class CustomExerciseForm extends _$CustomExerciseForm {
  @override
  Future<CustomExerciseFormState> build(CustomExerciseKey key) async {
    final id = key.id;
    if (id == null) {
      return CustomExerciseFormState(
        name: key.initialName.trim(),
        aliases: '',
        type: ExerciseType.weightReps,
        equipment: Equipment.machine,
      );
    }
    // Live: a session logged meanwhile locks the type and hides Delete.
    ref.listen(_exerciseReferencesProvider, (_, next) {
      final used = next.value;
      if (used != null && state.value != null) {
        _set(_form.copyWith(inUse: used.contains(id)));
      }
    });
    final inUse = (await ref.read(_exerciseReferencesProvider.future))
        .contains(id);
    final library = await ref.read(exerciseLibraryProvider.future);
    final stored = library.byId[id]?.custom;
    if (stored == null) throw StateError('the exercise is gone');
    final draft = stored.draft;
    return CustomExerciseFormState(
      name: draft.name,
      aliases: draft.aliases.join(', '),
      type: draft.type,
      equipment: draft.equipment,
      primary: draft.primaryMuscle,
      secondaries: draft.secondaryMuscles,
      stored: stored,
      inUse: inUse,
    );
  }

  CustomExerciseFormState get _form => state.requireValue;

  void _set(CustomExerciseFormState next) => state = AsyncData(next);

  /// The name changed.
  void setName(String name) => _set(_form.copyWith(name: name));

  /// The aliases changed.
  void setAliases(String aliases) => _set(_form.copyWith(aliases: aliases));

  /// The type was picked (ignored while locked).
  void setType(ExerciseType type) {
    if (_form.stored != null && _form.inUse) return;
    _set(_form.copyWith(type: type));
  }

  /// The equipment was picked.
  void setEquipment(Equipment equipment) =>
      _set(_form.copyWith(equipment: equipment));

  /// The main muscle was picked; it leaves the secondaries.
  void setPrimary(Muscle muscle) => _set(
    _form.copyWith(
      primary: muscle,
      secondaries: _form.secondaries.where((m) => m != muscle),
    ),
  );

  /// A secondary muscle was tapped: toggled, at most 4, never the main one.
  void toggleSecondary(Muscle muscle) {
    final form = _form;
    if (muscle == form.primary) return;
    if (form.secondaries.contains(muscle)) {
      _set(
        form.copyWith(secondaries: form.secondaries.where((m) => m != muscle)),
      );
    } else if (form.secondaries.length < Muscle.secondariesMax) {
      _set(form.copyWith(secondaries: [...form.secondaries, muscle]));
    }
  }

  /// Saves; `null` while something is missing (errors show).
  Future<WorkoutActionOutcome?> save() async {
    final form = _form;
    final draft = form.draft;
    if (draft == null || form.saving) {
      _set(form.copyWith(submitted: true));
      return null;
    }
    _set(form.copyWith(submitted: true, saving: true));
    final actions = ref.read(workoutActionsProvider);
    final stored = form.stored;
    final outcome = stored == null
        ? await actions.createExercise(draft)
        : await actions.updateExercise(stored, draft);
    if (ref.mounted) _set(_form.copyWith(saving: false));
    return outcome;
  }

  /// Deletes the exercise (only while unused, D15).
  Future<WorkoutActionOutcome?> delete() async {
    final stored = _form.stored;
    if (stored == null || _form.inUse || _form.saving) return null;
    _set(_form.copyWith(saving: true));
    final outcome = await ref
        .read(workoutActionsProvider)
        .deleteExercise(stored);
    if (ref.mounted) _set(_form.copyWith(saving: false));
    return outcome;
  }
}

/// The exercises sessions or templates use (D15).
@riverpod
Stream<Set<String>> _exerciseReferences(Ref ref) =>
    ref.watch(workoutRepositoryProvider).watchExerciseReferences();
