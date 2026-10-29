import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

const _hlc = '1760351234567-00000-0199e3c2-5b1a-7c3d-8e4f-0123456789ab';
const _id = '0199e3c2-5b1a-7c3d-8e4f-0123456789ab';
const _id2 = '0199e3c2-5b1a-7c3d-8e4f-0123456789ac';

const _tables = {
  'custom_exercises': 'customExercise',
  'workout_sessions': 'workoutSession',
  'session_exercises': 'sessionExercise',
  'workout_sets': 'workoutSet',
  'workout_templates': 'workoutTemplate',
  'workout_template_items': 'workoutTemplateItem',
  'weekly_plan_days': 'weeklyPlanDay',
};

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final verifier = SchemaVerifier(GeneratedHelper());

  // rule: A36 workout-migration
  test('A36 v7 → v8 adds the workout tables, indexes and triggers', () async {
    final schema = await verifier.schemaAt(7);
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 8);

    for (final MapEntry(key: table, value: entity) in _tables.entries) {
      final rows = await db.customSelect('SELECT * FROM $table').get();
      expect(rows, isEmpty, reason: table);
      final triggers = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'trigger' "
            "AND tbl_name = '$table'",
          )
          .map((r) => r.read<String>('name'))
          .get();
      expect(triggers.toSet(), {
        '${table}_outbox_ai',
        '${table}_outbox_au',
        '${table}_no_delete',
      });
      expect(
        db.syncedTables.singleWhere((t) => t.sqlName == table).entity,
        entity,
      );
    }
    for (final (index, columns) in [
      ('ix_workout_sessions_date', ['local_date', 'id']),
      ('ix_session_exercises_session', ['session_id', 'position']),
      ('ix_session_exercises_exercise', ['exercise_id']),
      ('ix_workout_sets_exercise', ['session_exercise_id', 'position']),
      ('ix_workout_template_items_template', ['template_id', 'position']),
      ('ux_weekly_plan_days_weekday', ['weekday']),
    ]) {
      final info = await db
          .customSelect("SELECT name FROM pragma_index_info('$index')")
          .get();
      expect(info.map((r) => r.read<String>('name')), columns, reason: index);
    }
    await db.close();
  });

  test('A36 v7 → v8 keeps chat rows and queued outbox entries', () async {
    final schema = await verifier.schemaAt(7);
    final raw = schema.rawDatabase
      ..execute(
        "INSERT INTO sync_state (key, value) VALUES ('outbox.capture', '1')",
      )
      ..execute(
        'INSERT INTO chat_messages (id, created_at, updated_hlc, version, '
        'device_id, origin, edited_by_user, role, message_text, status) '
        "VALUES (?, 0, ?, 1, ?, 'direct', 0, 'user', 'bench 3x8 80', 'done')",
        [_id, _hlc, _id],
      )
      ..execute(
        'INSERT INTO sync_outbox (entity, row_id, hlc, deleted) '
        "VALUES ('setting', ?, ?, 0)",
        [_id2, _hlc],
      );
    List<Map<String, Object?>> rows(String table) => [
      for (final r in raw.select('SELECT * FROM $table ORDER BY 1')) {...r},
    ];
    final chat = rows('chat_messages');
    final outbox = rows('sync_outbox');
    expect(chat, hasLength(1));
    expect(outbox, hasLength(2)); // the chat trigger's entry + the setting
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 8);
    Future<List<Map<String, Object?>>> after(String table) async => [
      for (final r
          in await db.customSelect('SELECT * FROM $table ORDER BY 1').get())
        r.data,
    ];
    expect(await after('chat_messages'), chat);
    expect(await after('sync_outbox'), outbox);
    await db.close();
  });

  test('A36 workout rows capture the outbox, are never hard-deleted, and '
      'one live plan row per weekday', () async {
    final schema = await verifier.schemaAt(7);
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 8);
    Future<void> insertPlan(String id) => runAuthorizedWrite(
      () => db.customStatement(
        'INSERT INTO weekly_plan_days (id, created_at, updated_hlc, version, '
        'device_id, origin, edited_by_user, weekday, template_id) '
        'VALUES (?, 0, ?, 1, ?, ?, 0, 6, NULL)',
        [id, _hlc, _id, 'direct'],
      ),
    );
    await insertPlan(_id);
    final outbox = await db
        .customSelect('SELECT entity, row_id FROM sync_outbox')
        .map((r) => (r.read<String>('entity'), r.read<String>('row_id')))
        .get();
    expect(outbox, contains(('weeklyPlanDay', _id)));
    await expectLater(insertPlan(_id2), throwsA(anything));
    await expectLater(
      runAuthorizedWrite(
        () => db.customStatement('DELETE FROM weekly_plan_days'),
      ),
      throwsA(anything),
    );
    await db.close();
  });
}
