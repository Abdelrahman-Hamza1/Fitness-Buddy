import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

void main() {
  test('WO-004 type codes round-trip and match the catalog', () {
    expect(ExerciseType.values.map((t) => t.code), [
      'weight_reps',
      'bodyweight_reps',
      'assisted',
      'reps_only',
      'duration',
      'distance_duration',
    ]);
    for (final type in ExerciseType.values) {
      expect(ExerciseType.fromCode(type.code), type);
    }
    expect(ExerciseType.fromCode('rpe'), isNull);
    for (final e in Equipment.values) {
      expect(Equipment.fromCode(e.code), e);
    }
    expect(Equipment.fromCode('band'), isNull);
  });

  test('WO-004 weight × reps needs weight and reps', () {
    const type = ExerciseType.weightReps;
    expect(const SetValues(reps: 8, kg: 80).issueFor(type), isNull);
    expect(const SetValues(reps: 8).issueFor(type), WorkoutSetIssue.weight);
    expect(const SetValues(kg: 80).issueFor(type), WorkoutSetIssue.reps);
    expect(
      const SetValues(reps: 8, kg: 1001).issueFor(type),
      WorkoutSetIssue.weight,
    );
    expect(
      const SetValues(reps: 8, kg: 80, durationSeconds: 30).issueFor(type),
      WorkoutSetIssue.unexpectedDuration,
    );
  });

  test('WO-004 bodyweight takes reps with an optional added load', () {
    const type = ExerciseType.bodyweightReps;
    expect(const SetValues(reps: 8).issueFor(type), isNull);
    expect(const SetValues(reps: 8, kg: 10).issueFor(type), isNull);
    expect(const SetValues(reps: 8, kg: 0).issueFor(type), isNull);
    expect(
      const SetValues(reps: 8, kg: -1).issueFor(type),
      WorkoutSetIssue.weight,
    );
  });

  test('WO-004 assisted needs reps and the assistance weight', () {
    const type = ExerciseType.assisted;
    expect(const SetValues(reps: 8, kg: 20).issueFor(type), isNull);
    expect(const SetValues(reps: 8).issueFor(type), WorkoutSetIssue.weight);
    expect(
      const SetValues(reps: 8, kg: 0).issueFor(type),
      WorkoutSetIssue.weight,
    );
    expect(
      const SetValues(reps: 8, kg: 1001).issueFor(type),
      WorkoutSetIssue.weight,
    );
  });

  test('WO-004 reps only rejects a weight', () {
    expect(const SetValues(reps: 20).issueFor(ExerciseType.repsOnly), isNull);
    expect(
      const SetValues(reps: 20, kg: 5).issueFor(ExerciseType.repsOnly),
      WorkoutSetIssue.unexpectedWeight,
    );
  });

  test('WO-004 time and cardio take a duration, cardio a distance', () {
    expect(
      const SetValues(durationSeconds: 60).issueFor(ExerciseType.duration),
      isNull,
    );
    expect(
      const SetValues(
        durationSeconds: 60,
        distanceMeters: 100,
      ).issueFor(ExerciseType.duration),
      WorkoutSetIssue.distance,
    );
    expect(
      const SetValues(
        durationSeconds: 1800,
        distanceMeters: 3000,
      ).issueFor(ExerciseType.distanceDuration),
      isNull,
    );
    expect(
      const SetValues(reps: 3).issueFor(ExerciseType.distanceDuration),
      WorkoutSetIssue.unexpectedReps,
    );
    expect(
      const SetValues().issueFor(ExerciseType.duration),
      WorkoutSetIssue.duration,
    );
  });
}
