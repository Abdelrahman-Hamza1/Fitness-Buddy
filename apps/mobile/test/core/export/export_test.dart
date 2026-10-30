import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fb_mobile/app/bootstrap/app_bootstrap.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/db/export_snapshot.dart';
import 'package:fb_mobile/core/db/natural_id.dart';
import 'package:fb_mobile/core/db/tables/sync_columns.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:fb_mobile/core/export/csv_codec.dart';
import 'package:fb_mobile/core/export/export_builder.dart';
import 'package:fb_mobile/core/export/export_registry.dart';
import 'package:fb_mobile/core/export/export_snapshot.dart';
import 'package:fb_mobile/features/settings/application/app_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../helpers/test_phone.dart';
import '../db/support/db_support.dart';

final _date = DateTime(2026, 10, 24, 12);
List<ExportFile> _build(ExportSnapshot snapshot) => ExportBuilder.build(
  snapshot,
  exportedAt: _date,
  version: '0.1.0',
  build: '7',
);
Future<ExportSnapshot> _read(AppDatabase db) =>
    ExportSnapshotReader(db)
        .read(settingNames: AppSettings.all.map((k) => k.name));
Map<String, dynamic> _json(List<ExportFile> files) =>
    jsonDecode(utf8.decode(files.last.bytes)) as Map<String, dynamic>;

// Independent RFC 4180 parser, including embedded CRLF and escaped quotes.
List<List<String>> _csv(ExportFile file) {
  final text = utf8.decode(file.bytes);
  final rows = <List<String>>[];
  var row = <String>[];
  var cell = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (c == '"') {
      if (quoted && i + 1 < text.length && text[i + 1] == '"') {
        cell.write('"');
        i++;
      } else {
        quoted = !quoted;
      }
    } else if (!quoted && c == ',') {
      row.add(cell.toString());
      cell = StringBuffer();
    } else if (!quoted && c == '\r' && text[i + 1] == '\n') {
      row.add(cell.toString());
      rows.add(row);
      row = [];
      cell = StringBuffer();
      i++;
    } else {
      cell.write(c);
    }
  }
  expect(quoted, isFalse);
  return rows;
}

Future<void> _seed(AppDatabase db, {int diaryRows = 1}) async {
  await db.customSelect('SELECT 1').get();
  await runAuthorizedWrite(() async {
    await db.customStatement('UPDATE meal_slots SET deleted_at = 1');
    for (final spec in exportRegistryV1) {
      final ids = spec.entity == 'setting'
          ? [
              ...AppSettings.all.map((k) => naturalId('setting', k.name)),
              'unknown',
            ]
          : [
              '${spec.entity}-live',
              '${spec.entity}-deleted',
              if (spec.entity == 'diaryEntry')
                for (var i = 1; i < diaryRows; i++) 'diary-$i',
            ];
      for (final id in ids) {
        final values = <String, Object?>{
          for (final c in spec.columns.where(
            (c) => c.kind != ExportKind.derived,
          ))
            c.name: switch (c.kind) {
              ExportKind.text => 'text',
              ExportKind.integer => 1,
              ExportKind.utcMs => 1792843200000,
              ExportKind.real => 12.5,
              ExportKind.boolean => 1,
              ExportKind.json => '{"sugar":1.2}',
              ExportKind.derived => null,
            },
          'id': id,
          'device_id': testDevice,
          'updated_hlc': hlcAt(100),
          'deleted_at': id.endsWith('-deleted') ? 100 : null,
          'origin': 'direct',
        };
        values.addAll({
          for (final key in ['amount_basis', 'basis'])
            if (values.containsKey(key)) key: 'g',
        });
        if (spec.entity == 'mealSlot') {
          values.addAll({
            'mode': 'normal',
            'window_start_min': null,
            'window_end_min': null,
            'active': 0,
            'name': 'وجبة محذوفة',
          });
        }
        if (spec.entity == 'diaryEntry') {
          values.addAll({
            'tz_offset_min': 180,
            'local_date': '2026-10-24',
            'slot_id': 'mealSlot-deleted',
            'name_ar': 'حمص، "طازج"\r\nسطر',
            'food_id': null,
          });
        }
        if (spec.entity == 'savedMealItem') {
          values['saved_meal_id'] = 'savedMeal-deleted';
        }
        if (spec.entity == 'savedMeal') values['name'] = 'Saved removed';
        if (spec.entity == 'weighIn') values['input_unit'] = 'kg';
        if (spec.entity == 'workoutSet') values['input_unit'] = 'kg';
        if (spec.entity == 'customExercise') {
          values.addAll({'exercise_type': 'weight_reps', 'equipment': 'cable'});
        }
        if (spec.entity == 'chatMessage') {
          values.addAll({
            'role': 'user',
            'status': 'done',
            'message_text': 'حمص 🍎',
          });
        }
        if (spec.entity == 'proposal') {
          values.addAll({
            'kind': 'foodLog',
            'status': 'pending',
            'outcome': null,
            'resolved_at': null,
            'interpretation_json': '[[0,null,null,null,[],null]]',
          });
        }
        if (spec.entity == 'personalFood') {
          values.addAll({
            'entry_serving_unit': null,
            'entry_serving_amount': null,
          });
        }
        await db.customStatement(
          'INSERT INTO ${spec.table} (${values.keys.join(',')}) '
          "VALUES (${List.filled(values.length, '?').join(',')})",
          values.values.toList(),
        );
      }
    }
  });
}

final class _ReadProbe extends QueryInterceptor {
  int transactions = 0;
  final readsAuthorized = <bool>[];
  @override
  TransactionExecutor beginTransaction(QueryExecutor parent) {
    transactions++;
    return super.beginTransaction(parent);
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    readsAuthorized.add(isWriteAuthorized);
    expect(isReadOnlyStatement(statement), isTrue);
    return super.runSelect(executor, statement, args);
  }
}

void main() {
  test('AT-006 reopening a populated user.db and post-frame bootstrap with '
      'a newer catalog keeps every row', () async {
    final root = tempDir().path;
    Future<List<int>> pack(int version) async {
      final path = '$root/source-$version.db';
      sqlite.sqlite3.open(path)
        ..execute('CREATE TABLE foods (name TEXT)')
        ..execute('INSERT INTO foods VALUES (?)', ['pack-$version'])
        ..close();
      return await File(path).readAsBytes();
    }

    Future<CatalogPackInstaller> installer(int version) async {
      final bytes = await pack(version);
      return CatalogPackInstaller(
        root: () async => root,
        loadAsset: (key) async => key == CatalogPackInstaller.packAsset
            ? bytes
            : utf8.encode(
                jsonEncode({
                  'catalog_version': version,
                  'schema_version': 1,
                  'pack': {'bytes': bytes.length},
                }),
              ),
      );
    }

    final oldPack = await installer(1);
    await oldPack.install();
    final path = '$root/user.db';
    final first = fileDatabase(path, catalog: oldPack);
    await _seed(first);
    final before = await _read(first);
    // Preserve internal state and tombstones too, beyond export's live rows.
    Future<Map<String, Object?>> allRows(AppDatabase db) async => {
      for (final table in db.allTables)
        table.actualTableName:
            (await db
                    .customSelect(
                      'SELECT * FROM "${table.actualTableName}" ORDER BY rowid',
                    )
                    .get())
                .map((r) => r.data)
                .toList(),
    };
    final allBefore = await allRows(first);
    await first.close();
    final nextPack = await installer(2);
    final reopened = fileDatabase(path, catalog: nextPack);
    final phone = TestPhone();
    final container = ProviderContainer.test(
      overrides: [
        ...phone.overrides(),
        appDatabaseProvider.overrideWithValue(reopened),
        catalogPackInstallerProvider.overrideWithValue(nextPack),
      ],
    );
    addTearDown(container.dispose);
    await container.read(appBootstrapProvider).afterFirstFrame();
    var attached = false;
    for (var attempt = 0; attempt < 100; attempt++) {
      try {
        final rows = await reopened
            .customSelect('SELECT name FROM catalog.foods')
            .get();
        attached = rows.single.read<String>('name') == 'pack-2';
      } on Object {
        // Bootstrap is asynchronous; wait for install and reattachment.
      }
      if (attached) break;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(attached, isTrue);
    expect(await allRows(reopened), allBefore);
    final after = await _read(reopened);
    expect(_json(_build(after)), _json(_build(before)));
  });

  // rule: A22 chat-export
  test('A22 export includes chat messages', () async {
    final db = memoryDatabase();
    await _seed(db);
    final files = _build(await _read(db));
    final rows = (_json(files)['data'] as Map)['chatMessage'] as List;
    expect(rows, hasLength(1));
    final row = rows.single as Map<String, dynamic>;
    expect(row['id'], 'chatMessage-live');
    expect(row['role'], 'user');
    expect(row['message_text'], 'حمص 🍎');
    expect(row['status'], 'done');
    expect(row['budget_json'], {'sugar': 1.2});
    expect(row.keys, isNot(contains('device_id')));
    final csv = files.singleWhere((f) => f.name.endsWith('-chat-messages.csv'));
    final header = _csv(csv).first;
    expect(
      [header.first.replaceFirst('\uFEFF', ''), ...header.skip(1)],
      [
        for (final c
            in exportRegistryV1
                .singleWhere((s) => s.entity == 'chatMessage')
                .columns
                .where((c) => c.name != 'version' && c.name != 'origin'))
          c.name,
      ],
    );
  });

  // rule: A23 proposal-export
  test('A23 export includes proposals and the local chat columns', () async {
    final db = memoryDatabase();
    await _seed(db);
    final files = _build(await _read(db));
    final data = _json(files)['data'] as Map;
    final proposals = data['proposal'] as List;
    expect(proposals, hasLength(1));
    final row = proposals.single as Map<String, dynamic>;
    expect(row['id'], 'proposal-live');
    expect(row['kind'], 'foodLog');
    expect(row['status'], 'pending');
    expect(row['outcome'], null);
    expect(row['draft_json'], {'sugar': 1.2});
    expect(row['interpretation_json'], [
      [0, null, null, null, <Object?>[], null],
    ]);
    expect(row.keys, isNot(contains('device_id')));
    final csv = files.singleWhere((f) => f.name.endsWith('-proposals.csv'));
    final header = _csv(csv).first;
    expect(
      [header.first.replaceFirst('\uFEFF', ''), ...header.skip(1)],
      [
        for (final c
            in exportRegistryV1
                .singleWhere((s) => s.entity == 'proposal')
                .columns
                .where((c) => c.name != 'version' && c.name != 'origin'))
          c.name,
      ],
    );
    // The local-only chat columns are the user's own data: exported.
    final chat = (data['chatMessage'] as List).single as Map<String, dynamic>;
    expect(chat['request_json'], {'sugar': 1.2});
    expect(chat['answer_json'], {'sugar': 1.2});
  });

  test('AC-030 every synced table has an export spec', () {
    final db = memoryDatabase();
    final tables = db.allTables.where(
      (t) => syncColumnNames.every((n) => t.$columns.any((c) => c.$name == n)),
    );
    expect(
      tables.map((t) => t.actualTableName).toSet(),
      exportRegistryV1.map((s) => s.table).toSet(),
    );
    expect(
      exportRegistryV1.map((s) => s.entity).toSet().length,
      exportRegistryV1.length,
    );
  });
  test('AC-030 every column is exported or excluded with a reason', () {
    final db = memoryDatabase();
    for (final table in db.allTables.where(
      (t) => syncColumnNames.every((n) => t.$columns.any((c) => c.$name == n)),
    )) {
      final spec = exportRegistryV1.singleWhere(
        (s) => s.table == table.actualTableName,
      );
      final exported = spec.columns
          .where((c) => c.kind != ExportKind.derived)
          .map((c) => c.name)
          .toSet();
      expect(exported.intersection(spec.excluded.keys.toSet()), isEmpty);
      expect({
        ...exported,
        ...spec.excluded.keys,
      }, table.$columns.map((c) => c.$name).toSet());
      expect(spec.excluded.values.every((r) => r.trim().isNotEmpty), isTrue);
    }
  });
  test('AT-006 export counts equal live DB counts per table', () async {
    final db = memoryDatabase();
    await _seed(db, diaryRows: 20000);
    final timer = Stopwatch()..start();
    final snapshot = await _read(db);
    final files = _build(snapshot);
    final json = _json(files);
    for (var i = 0; i < exportRegistryV1.length; i++) {
      final spec = exportRegistryV1[i];
      final count =
          (await db
                  .customSelect(
                    'SELECT COUNT(*) AS n FROM ${spec.table} '
                    'WHERE deleted_at IS NULL',
                  )
                  .getSingle())
              .read<int>('n');
      expect((json['counts'] as Map)[spec.entity], count);
      expect(((json['data'] as Map)[spec.entity] as List).length, count);
      expect(_csv(files[i]).length - 1, count);
      expect(
        snapshot.rows[spec.entity]!.any(
          (r) => (r['id']! as String).endsWith('-deleted'),
        ),
        isFalse,
      );
    }
    expect(snapshot.rows['diaryEntry']!.first['meal'], 'وجبة محذوفة');
    expect(
      snapshot.rows['savedMealItem']!.single['saved_meal_name'],
      'Saved removed',
    );
    expect(snapshot.rows['setting']!.map((r) => r['key']).toSet(), {
      ...AppSettings.all.map((k) => k.name),
      '',
    });
    // Non-gating size/timing evidence, no user data.
    // ignore: avoid_print
    print(
      'A11 20000-entry export: ${timer.elapsedMilliseconds} ms, '
      '${files.last.bytes.length} JSON bytes',
    );
  });
  test('AC-030 JSON round-trips every exported value', () async {
    final db = memoryDatabase();
    await _seed(db);
    final snapshot = await _read(db);
    final files = _build(snapshot);
    final json = _json(files);
    expect(json['schemaVersion'], db.schemaVersion);
    expect(json['formatVersion'], 1);
    expect(json['app'], {'version': '0.1.0', 'build': '7'});
    for (final spec in exportRegistryV1) {
      final output = (json['data'] as Map)[spec.entity] as List;
      for (var i = 0; i < output.length; i++) {
        final row = output[i] as Map;
        final original = snapshot.rows[spec.entity]![i];
        for (final c in spec.columns) {
          final raw = original[c.name];
          final expected = c.name == 'occurred_at'
              ? '2026-10-24T15:00:00.000+03:00'
              : c.name == 'created_at'
              ? DateTime.fromMillisecondsSinceEpoch(
                  raw! as int,
                  isUtc: true,
                ).toIso8601String()
              : c.kind == ExportKind.boolean
              ? raw == 1
              : c.kind == ExportKind.json
              ? jsonDecode(raw! as String)
              : raw;
          expect(row[c.name], expected, reason: '${spec.entity}.${c.name}');
        }
      }
    }
    for (final file in files) {
      final text = utf8.decode(file.bytes);
      expect(text, isNot(contains('device_id')));
      expect(text, isNot(contains('updated_hlc')));
      expect(text, isNot(contains(testDevice)));
    }
  });
  test('AC-030 CSV: BOM, CRLF, header, equal column counts, '
      'quotes/commas/newlines/Arabic survive a RFC 4180 parse', () async {
    final db = memoryDatabase();
    await _seed(db);
    final files = _build(await _read(db));
    for (var i = 0; i < exportRegistryV1.length; i++) {
      final file = files[i];
      expect(file.bytes.take(3), [239, 187, 191]);
      final rows = _csv(file);
      expect(rows.every((r) => r.length == rows.first.length), isTrue);
      expect(
        rows.first,
        exportRegistryV1[i].columns
            .where((c) => c.name != 'version' && c.name != 'origin')
            .map((c) => c.name),
      );
      expect(utf8.decode(file.bytes), endsWith('\r\n'));
    }
    final csv = _csv(files.first);
    expect(csv[1][csv.first.indexOf('name_ar')], 'حمص، "طازج"\r\nسطر');
    final bytes = encodeCsv(
      ['text', 'number'],
      [
        ['a,b"c\nd', 100.0],
        [null, true],
      ],
    );
    expect(_csv(ExportFile('a', 'text/csv', bytes)), [
      ['text', 'number'],
      ['a,b"c\nd', '100'],
      ['', 'true'],
    ]);
  });
  test('AC-030 CSV formula guard prefixes = + - @ tab CR text cells only', () {
    final inputs = [
      '=1',
      '+2',
      '-5',
      '@x',
      '\tx',
      '\rx',
      for (final prefix in [
        ' ',
        '\t',
        '\r',
        '\n',
        ' \t\r\n',
        '\u00a0',
        '\u2003',
        '\ufeff',
        '\u200b',
        '\u0000\u0085',
      ])
        for (final marker in ['=', '+', '-', '@']) '$prefix${marker}1',
    ];
    final csv = _csv(
      ExportFile(
        'a',
        'text/csv',
        encodeCsv(
          ['value'],
          [
            for (final s in inputs) [s],
            [-5],
            [-5.5],
            ["'=1"],
          ],
        ),
      ),
    );
    expect(csv.skip(1).map((r) => r.single), [
      ...inputs.map((s) => "'$s"),
      '-5',
      '-5.5',
      "'=1",
    ]);
  });
  test('AC-030 empty database exports headers only and valid JSON', () async {
    final db = memoryDatabase();
    await db.customSelect('SELECT 1').get();
    await runAuthorizedWrite(
      () => db.customStatement('UPDATE meal_slots SET deleted_at = 1'),
    );
    final files = _build(await _read(db));
    expect(files, hasLength(exportRegistryV1.length + 1));
    for (final file in files.take(exportRegistryV1.length)) {
      expect(_csv(file), hasLength(1));
    }
    expect((_json(files)['counts'] as Map).values, everyElement(0));
  });
  test(
    'export reads in one transaction and is rejected by nothing in WriteGuard',
    () async {
      final probe = _ReadProbe();
      final db = AppDatabase(NativeDatabase.memory().interceptWith(probe));
      addTearDown(db.close);
      await _seed(db);
      probe.transactions = 0;
      probe.readsAuthorized.clear();
      final before = await outbox(db);
      probe.readsAuthorized.clear();
      await _read(db);
      expect(probe.transactions, 1);
      expect(probe.readsAuthorized, isNotEmpty);
      expect(probe.readsAuthorized, everyElement(false));
      expect(await outbox(db), before);
      await expectLater(
        db.customStatement('DELETE FROM settings_kv'),
        throwsA(isA<UnauthorizedWriteError>()),
      );
      expect(
        File('lib/core/db/export_snapshot.dart').readAsStringSync(),
        isNot(contains('runAuthorizedWrite')),
      );
    },
  );
  test('docs/export-format.md lists every file.column of the registry', () {
    final doc = File('../../docs/export-format.md').readAsStringSync();
    for (final spec in exportRegistryV1) {
      for (final c in spec.columns) {
        expect(doc, contains('${spec.fileStem}.${c.name}'));
      }
    }
  });
}
