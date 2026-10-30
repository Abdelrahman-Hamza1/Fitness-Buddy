import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/features/workouts/data/workout_repository.dart';
import 'package:fb_text/fb_text.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'exercise_library.g.dart';

/// One exercise the app knows (WO-001, WO-003): built-in or custom.
final class LibraryExercise {
  /// An exercise.
  new({
    required this.id,
    required this.name,
    required this.type,
    required this.equipment,
    required this.primary,
    required Iterable<String> aliases,
    Iterable<Muscle> secondaries = const [],
    this.custom,
  }) : aliases = List.unmodifiable(aliases),
       secondaries = List.unmodifiable(secondaries);

  /// A catalog ID or a custom exercise's UUID.
  final String id;

  /// The display name. User content for custom exercises.
  final String name;

  /// Other names it's found by (built-ins: the pack's EN aliases).
  final List<String> aliases;

  /// What a set logs.
  final ExerciseType type;

  /// The equipment.
  final Equipment equipment;

  /// The main muscle, or `null` (A37 D2).
  final Muscle? primary;

  /// Secondary muscles.
  final List<Muscle> secondaries;

  /// The stored custom exercise, or `null` for a built-in.
  final Stored<CustomExerciseDraft>? custom;

  /// Whether the user made it.
  bool get isCustom => custom != null;

  /// Whether it's cardio (duration and distance).
  bool get isCardio => type == ExerciseType.distanceDuration;

  @override
  String toString() => 'LibraryExercise($id)';
}

/// Built-in and custom exercises together (A37 §3.5): lookup by ID, search
/// for the picker (D12), and what naming and PRs need. Custom names are user
/// content: never logged.
final class ExerciseLibrary {
  /// Over [exercises] (any order; listed by name).
  new(Iterable<LibraryExercise> exercises)
    : all = List.unmodifiable(
        exercises.toList()..sort((a, b) {
          final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          return byName != 0 ? byName : a.id.compareTo(b.id);
        }),
      ) {
    for (final e in all) {
      byId[e.id] = e;
      _searchable.add(
        SearchableExercise(
          id: e.id,
          keys: {
            for (final n in [e.name, ...e.aliases]) normalizeKey(n),
          },
          group: e.primary?.group,
          isCardio: e.isCardio,
        ),
      );
    }
  }

  /// An empty library (no pack yet, no custom exercises).
  static final ExerciseLibrary empty = ExerciseLibrary(const []);

  /// Every exercise, by name.
  final List<LibraryExercise> all;

  /// Every exercise by ID.
  final Map<String, LibraryExercise> byId = {};

  final List<SearchableExercise> _searchable = [];

  /// The type of exercise [id], or `null` when unknown (a removed custom
  /// exercise or a retired built-in shows as "Removed exercise", D15).
  ExerciseType? typeOf(String id) => byId[id]?.type;

  /// The muscle groups that have at least one exercise: the picker's chips.
  Set<MuscleGroup> get groups => {
    for (final e in all)
      if (e.primary case final m?) m.group,
  };

  /// Whether any exercise is cardio (the Cardio chip).
  bool get hasCardio => all.any((e) => e.isCardio);

  /// The exercises matching [query] under [filter], best first (D12).
  List<LibraryExercise> search(
    String query, {
    ExerciseFilter filter = ExerciseFilter.all,
  }) => [
    for (final hit in ExerciseSearch.search(
      normalizeKey(query),
      _searchable,
      filter: filter,
    ))
      byId[hit.id]!,
  ];

  /// What naming needs of [exercises] (WO-010).
  List<NamingExercise> namingOf(Iterable<SessionExerciseDraft> exercises) => [
    for (final e in exercises)
      (
        primary: byId[e.exerciseId]?.primary,
        isCardio: byId[e.exerciseId]?.isCardio ?? false,
        sets: e.sets.length,
      ),
  ];

  /// The title of [session] (D10).
  SessionTitle titleOf(WorkoutSessionDraft session) =>
      SessionNaming.titleOf(session.name, namingOf(session.exercises));
}

/// The pack's exercises with their names, re-read on every pack swap.
@riverpod
Stream<List<LibraryExercise>> builtInExercises(Ref ref) async* {
  final catalog = ref.watch(offlineCatalogProvider);
  Future<List<LibraryExercise>> read() async {
    final exercises = await catalog.exercises();
    final names = await catalog.exerciseNames();
    return [
      for (final e in exercises)
        LibraryExercise(
          id: e.id,
          name: e.nameEn,
          aliases: (names[e.id] ?? const <String>[]).where(
            (n) => n != e.nameEn,
          ),
          type: e.type,
          equipment: e.equipment,
          primary: e.primary,
          secondaries: e.secondaries,
        ),
    ];
  }

  yield await read();
  await for (final _ in catalog.packChanges) {
    yield await read();
  }
}

/// The live custom exercises.
@riverpod
Stream<List<Stored<CustomExerciseDraft>>> customExercises(Ref ref) =>
    ref.watch(workoutRepositoryProvider).watchCustomExercises();

/// Built-ins and live custom exercises (A37 §3.5).
@riverpod
Future<ExerciseLibrary> exerciseLibrary(Ref ref) async {
  final builtInsFuture = ref.watch(builtInExercisesProvider.future);
  final customsFuture = ref.watch(customExercisesProvider.future);
  final builtIns = await builtInsFuture;
  final customs = await customsFuture;
  return ExerciseLibrary([
    ...builtIns,
    for (final c in customs)
      LibraryExercise(
        id: c.ref.id,
        name: c.draft.name,
        aliases: c.draft.aliases,
        type: c.draft.type,
        equipment: c.draft.equipment,
        primary: c.draft.primaryMuscle,
        secondaries: c.draft.secondaryMuscles,
        custom: c,
      ),
  ]);
}
