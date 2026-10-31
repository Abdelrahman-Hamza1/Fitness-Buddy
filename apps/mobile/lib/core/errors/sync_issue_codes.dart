/// The only words a sync data report may carry (A34 D18, fix 8): fixed
/// issue kinds, the sync entity wire names and the reason codes. The
/// scrubber keeps a `SyncIssue` exception value only when every part is on
/// these lists; anything else is scrubbed.
abstract final class SyncIssueCodes {
  /// The exception type of a sync data report.
  static const String type = 'SyncIssue';

  /// The issue kinds.
  static const Set<String> issues = {'parked', 'deferred'};

  /// Every synced entity (pinned to `AppDatabase.syncedTables` by a test).
  static const Set<String> entities = {
    'setting',
    'mealSlot',
    'dishGroup',
    'diaryEntry',
    'dayMark',
    'savedMeal',
    'savedMealItem',
    'weighIn',
    'personalFood',
    'chatMessage',
    'proposal',
    'profile',
    'goalPhase',
    'targetSettings',
    'measurementType',
    'measurement',
    'customExercise',
    'workoutSession',
    'sessionExercise',
    'workoutSet',
    'workoutTemplate',
    'workoutTemplateItem',
    'weeklyPlanDay',
  };

  /// The reason codes of parked and deferred versions.
  static const Set<String> reasons = {
    'unsupported',
    'invalidPayload',
    'tooLarge',
    'unknown',
    'noCodec',
    'encodeFailed',
    'unscrubbedTombstone',
    'unknownEntity',
    'newerSchema',
    'unreadable',
  };

  /// `issue/entity/reason` when all three are allowlisted, else `null`.
  static String? value(String issue, String entity, String reason) =>
      issues.contains(issue) &&
          entities.contains(entity) &&
          reasons.contains(reason)
      ? '$issue/$entity/$reason'
      : null;

  /// Whether [value] is an allowlisted `issue/entity/reason`.
  static bool allowed(String value) {
    final parts = value.split('/');
    return parts.length == 3 &&
        SyncIssueCodes.value(parts[0], parts[1], parts[2]) == value;
  }
}
