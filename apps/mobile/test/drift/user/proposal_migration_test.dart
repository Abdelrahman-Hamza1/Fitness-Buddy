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
const _proposalId = '019a1b2c-0000-7000-8000-000000000042';

// NOT NULL columns the shared entity fixture doesn't carry (local or newer
// than the fixture).
const _requiredExtras = <String, Map<String, Object>>{
  'weigh_ins': {'tz_offset_min': 0, 'input_value': 1.0, 'input_unit': 'kg'},
  'chat_messages': {'message_text': 'Synthetic reply'},
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

  // Loops over the generated versions, so a renumbered schema (A23 R2) needs
  // no edit here.
  // rule: A23 proposal-migration
  test(
    'A23 migration adds proposals and preserves every prior schema',
    () async {
      final probe = AppDatabase(NativeDatabase.memory());
      final entityOf = {
        for (final t in probe.syncedTables) t.sqlName: t.entity,
      };
      await probe.close();
      const versions = GeneratedHelper.versions;
      final latest = versions.last;
      expect(latest, greaterThanOrEqualTo(9));
      var seededTables = 0;
      var seededChat = 0;
      // Every version before the latest: the one generic "no row is lost on
      // upgrade" test (TD-104). Proposals arrive in v9; their own checks run
      // for the versions before it.
      for (final from in versions.where((v) => v < latest)) {
        final schema = await verifier.schemaAt(from);
        final raw = schema.rawDatabase;
        final tables = {
          for (final r in raw.select(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%'",
          ))
            r['name'] as String,
        };
        if (from < 9) {
          expect(tables, isNot(contains('proposals')), reason: 'v$from');
        }
        raw.execute(
          "INSERT INTO sync_state (key, value) VALUES ('outbox.capture', '1')",
        );
        // One row per synced table that has a contract fixture, with only the
        // columns that table had at that version (chat rows from v7 on).
        for (final table in tables) {
          if (table == 'proposals') continue;
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
          if (table == 'chat_messages') seededChat++;
        }
        final before = {
          for (final table in tables)
            table: [
              for (final r in raw.select('SELECT * FROM $table')) {...r},
            ],
        };

        final db = AppDatabase(schema.newConnection());
        // Also compares the migrated schema with the generated dump.
        await verifier.migrateAndValidate(db, latest);
        for (final MapEntry(key: table, value: rows) in before.entries) {
          final after = [
            for (final r in await db.customSelect('SELECT * FROM $table').get())
              r.data,
          ];
          // v14 (A53 D2) rewrites a target_settings row's weekday weights
          // as factors, with a new HLC and version: the rest must stay.
          final rewritten = table == 'target_settings' && from < 14
              ? _v14Rewrites
              : const <String>{};
          for (final row in rows) {
            expect(
              after.where(
                (a) => row.entries.every(
                  (e) => rewritten.contains(e.key) || a[e.key] == e.value,
                ),
              ),
              hasLength(1),
              reason: 'v$from → v$latest keeps $table rows',
            );
          }
        }
        if (from < 9) {
          // The local-only chat columns arrive empty on existing rows.
          if (tables.contains('chat_messages')) {
            for (final r
                in await db
                    .customSelect(
                      'SELECT request_json, answer_json FROM chat_messages',
                    )
                    .get()) {
              expect(r.data['request_json'], isNull, reason: 'v$from');
              expect(r.data['answer_json'], isNull, reason: 'v$from');
            }
          }

          // The new table, its indexes and triggers.
          expect(await db.select(db.proposals).get(), isEmpty);
          final triggers = await db
              .customSelect(
                "SELECT name FROM sqlite_master WHERE type = 'trigger' "
                "AND tbl_name = 'proposals'",
              )
              .map((r) => r.read<String>('name'))
              .get();
          expect(triggers.toSet(), {
            'proposals_outbox_ai',
            'proposals_outbox_au',
            'proposals_no_delete',
          });
          for (final (index, columns) in [
            ('ix_proposals_budget', ['budget_message_id']),
            ('ix_proposals_pending', ['created_at']),
          ]) {
            final info = await db
                .customSelect("SELECT name FROM pragma_index_info('$index')")
                .get();
            expect(info.map((r) => r.read<String>('name')), columns);
          }
          // Capture works after the upgrade, CHECKs hold, and rows are never
          // hard-deleted.
          final proposal = fixtures['proposal'] as Map<String, dynamic>;
          Future<void> insert(
            String id,
            String status,
            String? outcome,
          ) => runAuthorizedWrite(
            () => db.customStatement(
              'INSERT INTO proposals (id, created_at, updated_hlc, version, '
              'device_id, origin, edited_by_user, kind, status, outcome, '
              'resolved_at, origin_message_id, budget_message_id, '
              'codec_version, interpretation_json, draft_json) '
              'VALUES (?, 0, ?, 1, ?, ?, 0, ?, ?, ?, NULL, ?, ?, ?, ?, ?)',
              [
                id,
                _hlc,
                _id,
                proposal['origin'],
                proposal['kind'],
                status,
                outcome,
                proposal['originMessageId'],
                proposal['budgetMessageId'],
                proposal['codecVersion'],
                proposal['interpretationJson'],
                proposal['draftJson'],
              ],
            ),
          );
          await insert(_proposalId, 'pending', null);
          expect(
            (await db.select(db.syncOutbox).get()).last.entity,
            'proposal',
          );
          for (final (status, outcome) in [
            ('active', null),
            ('pending', 'adjusted chips'),
          ]) {
            await expectLater(
              insert(_id, status, outcome),
              throwsA(isA<Exception>()),
              reason: '$status/$outcome',
            );
          }
          await expectLater(
            runAuthorizedWrite(
              () => db.customStatement('DELETE FROM proposals'),
            ),
            throwsA(isA<Exception>()),
          );
          expect(await db.select(db.proposals).get(), hasLength(1));
        }
        await db.close();
      }
      // Every prior version with user tables was seeded, chat from v7 on.
      expect(seededTables, greaterThan(10));
      expect(seededChat, greaterThanOrEqualTo(2));
    },
  );
}

/// The target_settings columns the v13 → v14 step rewrites (A53 D2).
const Set<String> _v14Rewrites = {
  'shift_mon',
  'shift_tue',
  'shift_wed',
  'shift_thu',
  'shift_fri',
  'shift_sat',
  'shift_sun',
  'updated_hlc',
  'version',
};
