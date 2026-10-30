/// The muscle groups that chips and session names use (A37 D2). Every
/// [Muscle] belongs to one.
enum MuscleGroup {
  /// Chest.
  chest,

  /// Back: traps, upper back, lower back.
  back,

  /// Shoulders.
  shoulders,

  /// Biceps.
  biceps,

  /// Triceps.
  triceps,

  /// Forearms.
  forearms,

  /// Legs: quadriceps, hamstrings, glutes, calves, adductors.
  legs,

  /// Core: abs, obliques.
  core,
}

/// The muscle vocabulary of exercises (WO-007, A37 D2): the codes of
/// `primary_muscle` and `secondary_muscles` in the catalog, on custom
/// exercises and in sync. Each maps to body-map regions (A37c) and to one
/// [MuscleGroup].
enum Muscle {
  /// Chest.
  chest('chest', MuscleGroup.chest),

  /// Shoulders (deltoids).
  shoulders('shoulders', MuscleGroup.shoulders),

  /// Biceps.
  biceps('biceps', MuscleGroup.biceps),

  /// Triceps.
  triceps('triceps', MuscleGroup.triceps),

  /// Forearms.
  forearms('forearms', MuscleGroup.forearms),

  /// Trapezius.
  traps('traps', MuscleGroup.back),

  /// Upper back: lats, rhomboids.
  upperBack('upper_back', MuscleGroup.back),

  /// Lower back: spinal erectors.
  lowerBack('lower_back', MuscleGroup.back),

  /// Abdominals.
  abs('abs', MuscleGroup.core),

  /// Obliques.
  obliques('obliques', MuscleGroup.core),

  /// Quadriceps.
  quadriceps('quadriceps', MuscleGroup.legs),

  /// Hamstrings.
  hamstrings('hamstrings', MuscleGroup.legs),

  /// Glutes.
  glutes('glutes', MuscleGroup.legs),

  /// Calves.
  calves('calves', MuscleGroup.legs),

  /// Adductors.
  adductors('adductors', MuscleGroup.legs);

  new(this.code, this.group);

  /// The stable storage, catalog and sync code.
  final String code;

  /// The group for chips and session names.
  final MuscleGroup group;

  /// Most secondary muscles on one exercise (A37 D3).
  static const int secondariesMax = 4;

  /// The muscle with vocabulary [code], or `null` for anything else.
  static Muscle? fromCode(String code) {
    for (final muscle in values) {
      if (muscle.code == code) return muscle;
    }
    return null;
  }

  /// The muscle a catalog pack's [code] means (A37 D4, PA5). Packs built
  /// before A37a use three legacy values: `back` → [upperBack], `core` →
  /// [abs], and `full_body` → none ("no primary muscle" is a first-class
  /// state). Unknown codes (a newer pack) are `null` too: shown, never
  /// guessed.
  static Muscle? fromCatalogCode(String code) => switch (code) {
    'back' => upperBack,
    'core' => abs,
    _ => fromCode(code),
  };

  /// A pack's secondary [codes] read tolerantly: each through
  /// [fromCatalogCode], unknown ones and duplicates dropped, and never
  /// [primary].
  static List<Muscle> secondariesFromCatalog(
    Iterable<String> codes, {
    Muscle? primary,
  }) => List.unmodifiable(<Muscle>{
    for (final code in codes)
      if (fromCatalogCode(code) case final m? when m != primary) m,
  });

  /// Checks [secondaries] for an exercise whose main muscle is [primary]:
  /// at most [secondariesMax], distinct, never [primary]. Returns them as an
  /// unmodifiable list; throws an `ArgumentError` otherwise.
  static List<Muscle> checkSecondaries(
    Iterable<Muscle> secondaries,
    Muscle? primary,
  ) {
    final list = List<Muscle>.unmodifiable(secondaries);
    if (list.length > secondariesMax) {
      throw ArgumentError.value(list.length, 'secondaryMuscles', 'at most 4');
    }
    if (list.toSet().length != list.length) {
      throw ArgumentError.value(list, 'secondaryMuscles', 'has duplicates');
    }
    if (primary != null && list.contains(primary)) {
      throw ArgumentError.value(
        list,
        'secondaryMuscles',
        'contains the primary muscle',
      );
    }
    return list;
  }
}
