import 'dart:async';

import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/db_support.dart';

const _id = '0199e3c2-5b1a-7c3d-8e4f-0123456789ac';
const _id2 = '0199e3c2-5b1a-7c3d-8e4f-0123456789ad';

final Matcher _unauthorized = throwsA(isA<UnauthorizedWriteError>());

/// The A01 D11 spike: the zone token set by runAuthorizedWrite reaches the
/// interceptor through transaction() and through the background isolate's
/// client, with no special cases.
void main() {
  final connections = <String, AppDatabase Function()>{
    'in-memory': memoryDatabase,
    'background isolate': () => backgroundDatabase(tempDir().path),
  };

  for (final MapEntry(key: name, value: open) in connections.entries) {
    group('WriteGuard ($name)', () {
      test('a raw insert outside the applier throws UnauthorizedWriteError '
          'and writes nothing', () async {
        final db = open();
        await expectLater(
          db.into(db.settingsKv).insert(settingRow(_id)),
          _unauthorized,
        );
        expect(await db.select(db.settingsKv).get(), isEmpty);
      });

      test('customStatement, update, delete and batch outside throw', () async {
        final db = open();
        await insertSetting(db, settingRow(_id));
        await expectLater(
          db.customStatement("DELETE FROM sync_state WHERE key = 'x'"),
          _unauthorized,
        );
        await expectLater(
          db
              .update(db.settingsKv)
              .write(const SettingsKvCompanion(valueJson: Value('2'))),
          _unauthorized,
        );
        await expectLater(db.delete(db.syncOutbox).go(), _unauthorized);
        await expectLater(
          db.batch((b) => b.insert(db.settingsKv, settingRow(_id2))),
          _unauthorized,
        );
        final rows = await db.select(db.settingsKv).get();
        expect(rows.map((r) => (r.id, r.valueJson)), [(_id, '1')]);
        expect(await outbox(db), hasLength(1));
      });

      test('writes run as queries (RETURNING, customSelect) outside throw '
          'and write nothing', () async {
        final db = open();
        await insertSetting(db, settingRow(_id));
        final writes = <String, Future<Object?> Function()>{
          'insertReturning': () =>
              db.into(db.settingsKv).insertReturning(settingRow(_id2)),
          'writeReturning': () => db
              .update(db.settingsKv)
              .writeReturning(const SettingsKvCompanion(valueJson: Value('2'))),
          'goAndReturn': () => db.delete(db.syncState).goAndReturn(),
          'customWriteReturning': () =>
              db.customWriteReturning('DELETE FROM sync_state RETURNING key'),
          'customSelect DELETE … RETURNING': () =>
              db.customSelect('DELETE FROM sync_state RETURNING key').get(),
          'customSelect INSERT': () => db
              .customSelect(
                "INSERT INTO sync_state (key, value) VALUES ('x', 'y')",
              )
              .get(),
          'customSelect WITH … DELETE': () => db
              .customSelect('WITH k AS (SELECT 1) DELETE FROM sync_state')
              .get(),
        };
        for (final MapEntry(key: name, value: write) in writes.entries) {
          await expectLater(
            write(),
            throwsA(
              isA<UnauthorizedWriteError>().having(
                (e) => e.kind,
                'kind',
                'select-write',
              ),
            ),
            reason: name,
          );
        }
        final rows = await db.select(db.settingsKv).get();
        expect(rows.map((r) => (r.id, r.valueJson)), [(_id, '1')]);
        expect(await db.select(db.syncState).get(), isNotEmpty);
        // Inside the scope they run.
        final returned = await runAuthorizedWrite(
          () => db.customWriteReturning(
            "DELETE FROM sync_state WHERE key = 'outbox.capture' RETURNING key",
          ),
        );
        expect(returned, hasLength(1));
      });

      test('a write inside transaction() started outside throws and rolls '
          'back the authorized part', () async {
        final db = open();
        await expectLater(
          db.transaction(() async {
            await runAuthorizedWrite(
              () => db.into(db.settingsKv).insert(settingRow(_id)),
            );
            await db.into(db.settingsKv).insert(settingRow(_id2));
          }),
          _unauthorized,
        );
        expect(await db.select(db.settingsKv).get(), isEmpty);
        expect(await outbox(db), isEmpty);
      });

      test('a transaction() started inside the scope writes', () async {
        final db = open();
        await runAuthorizedWrite(
          () => db.transaction(() async {
            await db.into(db.settingsKv).insert(settingRow(_id));
            // Nested transactions (savepoints) keep the zone too.
            await db.transaction(
              () => db.into(db.settingsKv).insert(settingRow(_id2)),
            );
            await db.batch(
              (b) => b.update(
                db.settingsKv,
                const SettingsKvCompanion(valueJson: Value('3')),
              ),
            );
          }),
        );
        final rows = await db.select(db.settingsKv).get();
        expect(rows.map((r) => r.valueJson), ['3', '3']);
      });

      test(
        'reads are never blocked, and watch() sees authorized writes',
        () async {
          final db = open();
          final seen = <int>[];
          final done = Completer<void>();
          final sub = db.select(db.settingsKv).watch().listen((rows) {
            seen.add(rows.length);
            if (rows.isNotEmpty && !done.isCompleted) done.complete();
          });
          addTearDown(sub.cancel);
          await db.customSelect('SELECT count(*) FROM sync_state').get();
          await insertSetting(db, settingRow(_id));
          await done.future.timeout(const Duration(seconds: 5));
          expect(seen.last, 1);
        },
      );

      test('a read inside runWithReadBarrier awaits the barrier first; the '
          "barrier's own reads and writes don't wait on it", () async {
        final db = open();
        var barriers = 0;
        final count = await db.transaction(
          () => runWithReadBarrier(
            () async {
              barriers++;
              expect(await db.select(db.settingsKv).get(), isEmpty);
              await insertSetting(db, settingRow(_id));
            },
            () async {
              final rows = await db.select(db.settingsKv).get();
              return rows.length;
            },
          ),
        );
        expect((count, barriers), (1, 1));
        // Outside the scope there is no barrier.
        expect(await db.select(db.settingsKv).get(), hasLength(1));
        expect(barriers, 1);
      });

      test('migrations and beforeOpen need no token: the first query, '
          'outside any scope, creates the schema', () async {
        final db = open();
        expect(isWriteAuthorized, isFalse);
        final tables = await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'table' "
              "AND name = 'settings_kv'",
            )
            .get();
        expect(tables, hasLength(1));
      });
    });
  }

  test('isReadOnlyStatement: single SELECT/VALUES/WITH reads only', () {
    for (final read in [
      'SELECT 1',
      '  select * from settings_kv where id = ?;  ',
      'VALUES (1), (2)',
      '(SELECT 1) UNION SELECT 2',
      '-- a comment\nSELECT 1',
      '/* INSERT */ SELECT 1',
      "SELECT 'DELETE FROM x RETURNING y' AS s",
      'SELECT "returning" FROM t',
      "WITH k AS (SELECT 1) SELECT replace(a, 'x', 'y') FROM k",
      'SELECT value FROM sync_state WHERE "key" = \'update;\'',
    ]) {
      expect(isReadOnlyStatement(read), isTrue, reason: read);
    }
    for (final write in [
      '',
      'INSERT INTO t VALUES (1)',
      ' delete from t',
      'UPDATE t SET a = 1',
      'REPLACE INTO t VALUES (1)',
      'INSERT INTO t VALUES (1) RETURNING id',
      'DELETE FROM t returning *',
      'WITH k AS (SELECT 1) INSERT INTO t SELECT * FROM k',
      'WITH k AS (SELECT 1) REPLACE INTO t SELECT * FROM k',
      'WITH k AS (SELECT 1) UPDATE t SET a = 1',
      'SELECT 1; DELETE FROM t',
      'PRAGMA user_version = 3',
      'ATTACH DATABASE ? AS x',
      'CREATE TABLE x (a)',
    ]) {
      expect(isReadOnlyStatement(write), isFalse, reason: write);
    }
  });

  test('the error carries the statement kind only, never SQL or values', () {
    final text = UnauthorizedWriteError('insert').toString();
    expect(text, contains('insert'));
    expect(text, isNot(contains('INSERT')));
  });
}
