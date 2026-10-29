/// What an exercise logs per set (WO-004). The codes match the catalog pack
/// (`data/exercises.yaml`) and the custom-exercise rows.
enum ExerciseType {
  /// Weight and reps: bench press, squat.
  weightReps('weight_reps'),

  /// Reps, plus optional added weight: pull-ups, dips.
  bodyweightReps('bodyweight_reps'),

  /// Reps and assistance weight: assisted pull-up machine.
  assisted('assisted'),

  /// Reps only: push-ups.
  repsOnly('reps_only'),

  /// Duration only: plank.
  duration('duration'),

  /// Duration and optional distance: treadmill, cycling, walking.
  distanceDuration('distance_duration');

  new(this.code);

  /// The stable storage and catalog code.
  final String code;

  /// The type with [code], or `null` for an unknown one (a newer pack or a
  /// synced row from a newer app: shown, never guessed).
  static ExerciseType? fromCode(String code) {
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }

  /// Whether a set of this type has reps.
  bool get hasReps => switch (this) {
    weightReps || bodyweightReps || assisted || repsOnly => true,
    duration || distanceDuration => false,
  };

  /// Whether a set of this type has a duration.
  bool get hasDuration => !hasReps;
}

/// The equipment an exercise uses (WO-002: equipment variants are separate
/// exercises). Codes match the catalog pack.
enum Equipment {
  /// Barbell.
  barbell('barbell'),

  /// Dumbbells: weights are per dumbbell (WO-005).
  dumbbell('dumbbell'),

  /// Cable stack.
  cable('cable'),

  /// Machine.
  machine('machine'),

  /// Kettlebell.
  kettlebell('kettlebell'),

  /// Bodyweight.
  bodyweight('bodyweight'),

  /// Anything else.
  other('other');

  new(this.code);

  /// The stable storage and catalog code.
  final String code;

  /// The equipment with [code], or `null` for an unknown one.
  static Equipment? fromCode(String code) {
    for (final equipment in values) {
      if (equipment.code == code) return equipment;
    }
    return null;
  }

  /// Whether a logged weight means "per dumbbell" (WO-005): the input field
  /// says so, and the stored kg is the weight of one dumbbell.
  bool get weightIsPerImplement => this == dumbbell;
}
