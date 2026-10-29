import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/app_database.steps.dart';

/// Additive workout tables (A36 D7): library, sessions, sets, templates and
/// the weekly plan, with their indexes and outbox triggers.
Future<void> from7To8(Migrator m, Schema8 schema) async {
  await m.createTable(schema.customExercises);
  await m.createTable(schema.workoutSessions);
  await m.createTable(schema.sessionExercises);
  await m.createTable(schema.workoutSets);
  await m.createTable(schema.workoutTemplates);
  await m.createTable(schema.workoutTemplateItems);
  await m.createTable(schema.weeklyPlanDays);
  for (final index in [
    schema.ixWorkoutSessionsDate,
    schema.ixSessionExercisesSession,
    schema.ixSessionExercisesExercise,
    schema.ixWorkoutSetsExercise,
    schema.ixWorkoutTemplateItemsTemplate,
    schema.uxWeeklyPlanDaysWeekday,
  ]) {
    await m.createIndex(index);
  }
  for (final trigger in [
    schema.customExercisesOutboxAi,
    schema.customExercisesOutboxAu,
    schema.customExercisesNoDelete,
    schema.workoutSessionsOutboxAi,
    schema.workoutSessionsOutboxAu,
    schema.workoutSessionsNoDelete,
    schema.sessionExercisesOutboxAi,
    schema.sessionExercisesOutboxAu,
    schema.sessionExercisesNoDelete,
    schema.workoutSetsOutboxAi,
    schema.workoutSetsOutboxAu,
    schema.workoutSetsNoDelete,
    schema.workoutTemplatesOutboxAi,
    schema.workoutTemplatesOutboxAu,
    schema.workoutTemplatesNoDelete,
    schema.workoutTemplateItemsOutboxAi,
    schema.workoutTemplateItemsOutboxAu,
    schema.workoutTemplateItemsNoDelete,
    schema.weeklyPlanDaysOutboxAi,
    schema.weeklyPlanDaysOutboxAu,
    schema.weeklyPlanDaysNoDelete,
  ]) {
    await m.createTrigger(trigger);
  }
}
