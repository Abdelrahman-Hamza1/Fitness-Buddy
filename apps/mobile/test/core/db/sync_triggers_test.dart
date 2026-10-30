import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/tables/sync_columns.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/db_support.dart';

/// SQL without whitespace and trailing `;`, so formatting doesn't matter.
String _squash(String sql) =>
    sql.replaceAll(RegExp(r'\s+'), '').replaceAll(';', '');

const _id = '0199e3c2-5b1a-7c3d-8e4f-0123456789ac';

void main() {
  test('AC-012 every synced table has insert/update/no-delete outbox triggers '
      'with its entity name', () async {
    final db = memoryDatabase();
    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .map((r) => r.read<String>('name'))
        .get();
    final withSyncColumns = <String>{};
    for (final table in tables) {
      final columns = await db
          .customSelect(
            'SELECT name FROM pragma_table_info(?)',
            variables: [Variable.withString(table)],
          )
          .map((r) => r.read<String>('name'))
          .get();
      if (syncColumnNames.every(columns.contains)) {
        withSyncColumns.add(table);
      }
    }
    expect(
      withSyncColumns,
      {for (final t in db.syncedTables) t.sqlName},
      reason:
          'every table with the sync columns is in '
          'AppDatabase.syncedTables, and nothing else',
    );

    for (final synced in db.syncedTables) {
      final table = synced.sqlName;
      final triggers = await db
          .customSelect(
            "SELECT name, sql FROM sqlite_master WHERE type = 'trigger' "
            'AND tbl_name = ? ORDER BY name',
            variables: [Variable.withString(table)],
          )
          .map((r) => (r.read<String>('name'), r.read<String>('sql')))
          .get();
      final expected = expectedTriggers(table, synced.entity);
      final expectedByName = {
        for (final sql in expected.split('\n\n'))
          RegExp(r'CREATE TRIGGER (\w+)').firstMatch(sql)![1]!: _squash(sql),
      };
      expect(
        {for (final (name, sql) in triggers) name: _squash(sql)},
        expectedByName,
        reason:
            '$table must have exactly its three outbox triggers. Paste '
            'this into lib/core/db/sync_triggers.drift and create them in '
            "the table's migration:\n\n$expected",
      );
    }
  });

  group('AC-012 outbox capture', () {
    test('insert, update and tombstone each append one outbox row with the '
        "row's hlc", () async {
      final db = memoryDatabase();
      await insertSetting(db, settingRow(_id));
      await runAuthorizedWrite(
        () => (db.update(db.settingsKv)..where((t) => t.id.equals(_id))).write(
          SettingsKvCompanion(
            updatedHlc: Value(hlcAt(2)),
            version: const Value(2),
            valueJson: const Value('2'),
          ),
        ),
      );
      await runAuthorizedWrite(
        () => (db.update(db.settingsKv)..where((t) => t.id.equals(_id))).write(
          SettingsKvCompanion(
            updatedHlc: Value(hlcAt(3)),
            version: const Value(3),
            deletedAt: const Value(3),
          ),
        ),
      );
      expect(await outbox(db), [
        ('setting', _id, hlcAt(1), false),
        ('setting', _id, hlcAt(2), false),
        ('setting', _id, hlcAt(3), true),
      ]);
    });

    test("an update that doesn't change updated_hlc appends nothing", () async {
      final db = memoryDatabase();
      await insertSetting(db, settingRow(_id));
      await runAuthorizedWrite(
        () => (db.update(db.settingsKv)..where((t) => t.id.equals(_id))).write(
          const SettingsKvCompanion(valueJson: Value('9')),
        ),
      );
      expect(await outbox(db), hasLength(1));
    });

    test("outbox.capture = '0' suppresses outbox rows (A34 path)", () async {
      final db = memoryDatabase();
      await runAuthorizedWrite(
        () => db.transaction(() async {
          await db.customStatement(
            "UPDATE sync_state SET value = '0' WHERE key = 'outbox.capture'",
          );
          await db.into(db.settingsKv).insert(settingRow(_id));
          await db.customStatement(
            "UPDATE sync_state SET value = '1' WHERE key = 'outbox.capture'",
          );
        }),
      );
      expect(await outbox(db), isEmpty);
      await insertSetting(db, settingRow('${_id.substring(0, 35)}d'));
      expect(await outbox(db), hasLength(1));
    });

    for (final capture in ['1', '0']) {
      test('hard DELETE on a synced table aborts (capture $capture)', () async {
        final db = memoryDatabase();
        await insertSetting(db, settingRow(_id));
        await expectLater(
          runAuthorizedWrite(
            () => db.transaction(() async {
              await db.customStatement(
                'UPDATE sync_state SET value = ? '
                "WHERE key = 'outbox.capture'",
                [capture],
              );
              await db.delete(db.settingsKv).go();
            }),
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('tombstone, never delete'),
            ),
          ),
        );
        expect(await db.select(db.settingsKv).get(), hasLength(1));
      });
    }

    // rule: A23 proposal-outbox
    test('AI-045 pending proposal rows reach the outbox like any synced '
        'row', () async {
      final db = memoryDatabase();
      final row = ProposalsCompanion.insert(
        id: _id,
        createdAt: 1,
        updatedHlc: hlcAt(1),
        version: 1,
        deviceId: testDevice,
        origin: 'system',
        kind: 'foodLog',
        status: 'pending',
        codecVersion: 2,
        draftJson: '{"revision":0}',
      );
      await runAuthorizedWrite(() => db.into(db.proposals).insert(row));
      await runAuthorizedWrite(
        () => (db.update(db.proposals)..where((t) => t.id.equals(_id))).write(
          ProposalsCompanion(
            updatedHlc: Value(hlcAt(2)),
            version: const Value(2),
            status: const Value('confirmed'),
            outcome: const Value('unchanged'),
            resolvedAt: const Value(2),
          ),
        ),
      );
      // A write that keeps the HLC (none happens through the writer) adds
      // nothing.
      await runAuthorizedWrite(
        () => (db.update(db.proposals)..where((t) => t.id.equals(_id))).write(
          const ProposalsCompanion(version: Value(2)),
        ),
      );
      await runAuthorizedWrite(
        () => (db.update(db.proposals)..where((t) => t.id.equals(_id))).write(
          ProposalsCompanion(
            updatedHlc: Value(hlcAt(3)),
            version: const Value(3),
            deletedAt: const Value(3),
          ),
        ),
      );
      expect(await outbox(db), [
        ('proposal', _id, hlcAt(1), false),
        ('proposal', _id, hlcAt(2), false),
        ('proposal', _id, hlcAt(3), true),
      ]);
      expect(
        db.syncedTables.singleWhere((t) => t.sqlName == 'proposals').entity,
        'proposal',
      );
      await expectLater(
        runAuthorizedWrite(() => db.delete(db.proposals).go()),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('tombstone, never delete'),
          ),
        ),
      );
      expect(await db.select(db.proposals).get(), hasLength(1));
    });

    // rule: A22 chat-outbox
    test('A22 chat message rows capture the outbox and are never '
        'hard-deleted', () async {
      final db = memoryDatabase();
      final row = ChatMessagesCompanion.insert(
        id: _id,
        createdAt: 1,
        updatedHlc: hlcAt(1),
        version: 1,
        deviceId: testDevice,
        origin: 'direct',
        role: 'user',
        messageText: 'حمص 🍎',
        status: 'queued',
      );
      await runAuthorizedWrite(() => db.into(db.chatMessages).insert(row));
      await runAuthorizedWrite(
        () =>
            (db.update(db.chatMessages)..where((t) => t.id.equals(_id))).write(
              ChatMessagesCompanion(
                updatedHlc: Value(hlcAt(2)),
                version: const Value(2),
                status: const Value('done'),
              ),
            ),
      );
      await runAuthorizedWrite(
        () =>
            (db.update(db.chatMessages)..where((t) => t.id.equals(_id))).write(
              ChatMessagesCompanion(
                updatedHlc: Value(hlcAt(3)),
                version: const Value(3),
                deletedAt: const Value(3),
              ),
            ),
      );
      expect(await outbox(db), [
        ('chatMessage', _id, hlcAt(1), false),
        ('chatMessage', _id, hlcAt(2), false),
        ('chatMessage', _id, hlcAt(3), true),
      ]);
      expect(
        db.syncedTables.singleWhere((t) => t.sqlName == 'chat_messages').entity,
        'chatMessage',
      );
      await expectLater(
        runAuthorizedWrite(() => db.delete(db.chatMessages).go()),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('tombstone, never delete'),
          ),
        ),
      );
      expect(await db.select(db.chatMessages).get(), hasLength(1));
    });

    test('the database opens with capture on', () async {
      final db = memoryDatabase();
      final row = await (db.select(
        db.syncState,
      )..where((t) => t.key.equals('outbox.capture'))).getSingle();
      expect(row.value, '1');
    });
  });
}
