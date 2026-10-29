import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/app_database.steps.dart';

/// Additive targets schema and outbox capture (A13a D2, TD-089).
Future<void> from4To5(Migrator m, Schema5 schema) async {
  for (final table in [
    schema.profile,
    schema.goalPhases,
    schema.targetSettings,
  ]) {
    await m.createTable(table);
  }
  await m.createIndex(schema.ixGoalPhasesStart);
  await m.createIndex(schema.ixTargetSettingsEffective);
  for (final trigger in [
    schema.profileOutboxAi,
    schema.profileOutboxAu,
    schema.profileNoDelete,
    schema.goalPhasesOutboxAi,
    schema.goalPhasesOutboxAu,
    schema.goalPhasesNoDelete,
    schema.targetSettingsOutboxAi,
    schema.targetSettingsOutboxAu,
    schema.targetSettingsNoDelete,
  ]) {
    await m.createTrigger(trigger);
  }
}
