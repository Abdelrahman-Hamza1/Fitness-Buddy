import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/app_database.steps.dart';

/// Additive personal-food schema and outbox capture (A09, 05 §3).
Future<void> from3To4(Migrator m, Schema4 schema) async {
  await m.createTable(schema.personalFoods);
  await m.createIndex(schema.ixDiaryEntriesFood);
  await m.createIndex(schema.ixSavedMealItemsFood);
  for (final trigger in [
    schema.personalFoodsOutboxAi,
    schema.personalFoodsOutboxAu,
    schema.personalFoodsNoDelete,
  ]) {
    await m.createTrigger(trigger);
  }
}
