import 'package:fb_domain/src/ids/uuid_v7.dart';
import 'package:fb_domain/src/workouts/muscle.dart';
import 'package:fb_domain/src/workouts/workout_drafts.dart';

final RegExp _catalogExerciseId = RegExp(
  '^ex:[a-z0-9_]{1,${WorkoutWireRules.maxCatalogIdLength}}\$',
);

/// The workout sync wire rules W1–W5 (`contracts/README.md` § "Workout
/// semantic rules", B21). Each is row-local: the app applies it on every
/// write and the server admits exactly these after the schema check. Rules
/// that need another row (ownership, per-type set values) are not here.
abstract final class WorkoutWireRules {
  /// Longest catalog exercise ID after `ex:` (W4).
  static const int maxCatalogIdLength = 60;

  /// `naturalId('weeklyPlanDay', '<weekday>')` (UUIDv5, TD-070) by ISO
  /// weekday, Monday first (W5). The app test pins them to `planDayId`.
  static const List<String> planDayIds = [
    '17605af2-922b-5ee3-8648-11da5a26601f',
    '5b872683-47af-576f-a2ad-4b38b7980f88',
    '30b96b41-d543-5b1b-8d94-1f15769f9c3b',
    '840d975c-6188-5c39-bb01-ab163f0b8dc4',
    '790cb635-2370-51be-8315-a706422fb27d',
    'ff8f65bc-5c85-521a-a8e9-7fb18060ccfe',
    '8009ef9a-6a6f-56d7-a915-30314b3e26f2',
  ];

  /// W1: [decodedSecondaries] (the decoded `secondaryMusclesJson`) is a list
  /// of at most [Muscle.secondariesMax] muscle codes, distinct, none equal to
  /// [primary] (a code, or `null`). [primary] itself is the schema's.
  static bool musclesHold(String? primary, Object? decodedSecondaries) {
    if (decodedSecondaries is! List<Object?> ||
        decodedSecondaries.length > Muscle.secondariesMax) {
      return false;
    }
    final seen = <String>{};
    for (final code in decodedSecondaries) {
      if (code is! String ||
          Muscle.fromCode(code) == null ||
          code == primary ||
          !seen.add(code)) {
        return false;
      }
    }
    return true;
  }

  /// W2: [decoded] (the decoded `aliasesJson`) is a list of at most
  /// [WorkoutLimits.aliasesMax] strings.
  static bool aliasesHold(Object? decoded) =>
      decoded is List<Object?> &&
      decoded.length <= WorkoutLimits.aliasesMax &&
      decoded.every((alias) => alias is String);

  /// W3, a set's shape: exactly one of [reps] and [durationSeconds]; [kg]
  /// only with [reps] and [distanceMeters] only with [durationSeconds];
  /// [kg], [inputValue] and [inputUnit] all null or all set.
  static bool setShapeHolds({
    int? reps,
    double? kg,
    double? inputValue,
    String? inputUnit,
    int? durationSeconds,
    double? distanceMeters,
  }) =>
      (reps == null) != (durationSeconds == null) &&
      (kg == null || reps != null) &&
      (distanceMeters == null || durationSeconds != null) &&
      (kg == null) == (inputValue == null) &&
      (kg == null) == (inputUnit == null);

  /// W4: [id] is a catalog exercise ID (`ex:` then 1–60 of `a`–`z`, `0`–`9`,
  /// `_`) or a lowercase canonical UUID.
  static bool isExerciseRef(String id) =>
      _catalogExerciseId.hasMatch(id) || isUuid(id);

  /// W5: [id] is the natural row ID of ISO [weekday].
  static bool planDayIdHolds(String id, int weekday) =>
      weekday >= 1 && weekday <= 7 && planDayIds[weekday - 1] == id;
}
