import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/app_database.steps.dart';

/// Additive body measurement tables (A15b D13): custom measurement types
/// and measurements, their live index and outbox triggers.
Future<void> from9To10(Migrator m, Schema10 schema) async {
  await m.createTable(schema.measurementTypes);
  await m.createTable(schema.measurements);
  await m.createIndex(schema.ixMeasurementsLive);
  for (final trigger in [
    schema.measurementTypesOutboxAi,
    schema.measurementTypesOutboxAu,
    schema.measurementTypesNoDelete,
    schema.measurementsOutboxAi,
    schema.measurementsOutboxAu,
    schema.measurementsNoDelete,
  ]) {
    await m.createTrigger(trigger);
  }
}
