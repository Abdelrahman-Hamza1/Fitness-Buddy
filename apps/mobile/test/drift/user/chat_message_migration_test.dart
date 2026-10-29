import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

const _hlc = '1760351234567-00000-0199e3c2-5b1a-7c3d-8e4f-0123456789ab';
const _id = '0199e3c2-5b1a-7c3d-8e4f-0123456789ab';
const _chatId = '019a1b2c-0000-7000-8000-000000000042';

// NOT NULL columns the shared entity fixture doesn't carry (local or newer
// than the fixture).
const _requiredExtras = <String, Map<String, Object>>{
  'weigh_ins': {'tz_offset_min': 0, 'input_value': 1.0, 'input_unit': 'kg'},
};

String _snake(String s) =>
    s.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final verifier = SchemaVerifier(GeneratedHelper());
  final fixtures = jsonDecode(
    File('../../contracts/testdata/sync/entity-payloads.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>;

  // Loops over the generated versions, so a renumbered or later schema needs
  // no edit here (A22 D4).
  // rule: A22 chat-migration
  test('A22 chat message migration preserves existing user rows', () async {
    final probe = AppDatabase(NativeDatabase.memory());
    final entityOf = {for (final t in probe.syncedTables) t.sqlName: t.entity};
    await probe.close();
    const versions = GeneratedHelper.versions;
    final latest = versions.last;
    var seededTables = 0;
    for (final from in versions.where((v) => v < latest)) {
      final schema = await verifier.schemaAt(from);
      final raw = schema.rawDatabase;
      String tablesSql(String type) =>
          "SELECT name FROM sqlite_master WHERE type = '$type' "
          "AND name NOT LIKE 'sqlite_%'";
      final tables = {
        for (final r in raw.select(tablesSql('table'))) r['name'] as String,
      };
      expect(tables, isNot(contains('chat_messages')), reason: 'v$from');
      raw.execute(
        "INSERT INTO sync_state (key, value) VALUES ('outbox.capture', '1')",
      );
      // One row per synced table that has a contract fixture, with only the
      // columns that table had at that version.
      for (final table in tables) {
        final payload = fixtures[entityOf[table]] as Map<String, dynamic>?;
        if (payload == null) continue;
        final columns = {
          for (final r in raw.select('PRAGMA table_info($table)'))
            r['name'] as String,
        };
        final values = <String, Object?>{
          'id': _id,
          'updated_hlc': _hlc,
          'version': 1,
          'device_id': _id,
          'deleted_at': null,
          for (final f in payload.entries)
            f.key == 'createdAtMs' ? 'created_at' : _snake(f.key):
                f.value is bool ? (f.value == true ? 1 : 0) : f.value,
          ...?_requiredExtras[table],
        }..removeWhere((column, _) => !columns.contains(column));
        raw.execute(
          'INSERT INTO $table (${values.keys.join(',')}) '
          'VALUES (${List.filled(values.length, '?').join(',')})',
          values.values.toList(),
        );
        seededTables++;
      }
      final before = {
        for (final table in tables)
          table: [
            for (final r in raw.select('SELECT * FROM $table')) {...r},
          ],
      };

      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, latest);
      for (final MapEntry(key: table, value: rows) in before.entries) {
        final after = [
          for (final r in await db.customSelect('SELECT * FROM $table').get())
            r.data,
        ];
        for (final row in rows) {
          expect(
            after.where((a) => row.entries.every((e) => a[e.key] == e.value)),
            hasLength(1),
            reason: 'v$from → v$latest keeps $table rows',
          );
        }
      }

      // The new table, its indexes and triggers.
      expect(await db.select(db.chatMessages).get(), isEmpty);
      final triggers = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'trigger' "
            "AND tbl_name = 'chat_messages'",
          )
          .map((r) => r.read<String>('name'))
          .get();
      expect(triggers.toSet(), {
        'chat_messages_outbox_ai',
        'chat_messages_outbox_au',
        'chat_messages_no_delete',
      });
      for (final (index, columns) in [
        ('ix_chat_messages_order', ['created_at', 'id']),
        ('ix_chat_messages_reply', ['reply_to_message_id']),
      ]) {
        final info = await db
            .customSelect("SELECT name FROM pragma_index_info('$index')")
            .get();
        expect(info.map((r) => r.read<String>('name')), columns);
      }
      // Capture works after the upgrade, and rows are never hard-deleted.
      final chat = fixtures['chatMessage'] as Map<String, dynamic>;
      await runAuthorizedWrite(
        () => db.customStatement(
          'INSERT INTO chat_messages (id, created_at, updated_hlc, version, '
          'device_id, origin, edited_by_user, role, message_text, status, '
          'language, '
          'reply_to_message_id, codec_version, budget_json) '
          'VALUES (?, 0, ?, 1, ?, ?, 0, ?, ?, ?, ?, ?, ?, ?)',
          [
            _chatId,
            _hlc,
            _id,
            chat['origin'],
            chat['role'],
            chat['text'],
            chat['status'],
            chat['language'],
            chat['replyToMessageId'],
            chat['codecVersion'],
            chat['budgetJson'],
          ],
        ),
      );
      expect((await db.select(db.syncOutbox).get()).last.entity, 'chatMessage');
      await expectLater(
        runAuthorizedWrite(
          () => db.customStatement('DELETE FROM chat_messages'),
        ),
        throwsA(isA<SqliteException>()),
      );
      await db.close();
    }
    // Every prior version with user tables was seeded.
    expect(seededTables, greaterThan(10));
  });
}
