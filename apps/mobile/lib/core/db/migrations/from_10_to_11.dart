import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/app_database.steps.dart';

/// Muscles on custom exercises (A37 D6): the main muscle (nullable, the
/// existing rows have none) and the secondary muscles (`'[]'`). Adding a
/// column fires no trigger, so no outbox row is written.
Future<void> from10To11(Migrator m, Schema11 schema) async {
  await m.addColumn(
    schema.customExercises,
    schema.customExercises.primaryMuscle,
  );
  await m.addColumn(
    schema.customExercises,
    schema.customExercises.secondaryMusclesJson,
  );
}
