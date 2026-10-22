import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_text/fb_text.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../diary/support/diary_fixtures.dart';

/// Fixed bilingual prefixes, aliases, typos, quantity and miss for D14.
const benchmarkQueries = [
  'r',
  'ri',
  'ric',
  'rice',
  'رز',
  'ر',
  'خب',
  'خبز',
  'p',
  'pi',
  'pit',
  'pita',
  'khubz arabi',
  'ch',
  'chi',
  'chicken',
  'chiken',
  'chiken breast',
  'rcie',
  'rcie white',
  '2 khubz arabi',
  'zzqxmissing',
];

/// Nearest-rank p95 in milliseconds.
double p95(List<int> micros) {
  final sorted = List.of(micros)..sort();
  return sorted[(sorted.length * .95).ceil() - 1] / 1000;
}

/// Deterministic alphabet permutations, producing distinct real words rather
/// than numeric suffixes. IDs alone get suffixes, as foreign keys require.
String mutateVocabulary(String text, int copy) => String.fromCharCodes(
  text.runes.map((r) {
    if (r >= 97 && r <= 122) return 97 + (r - 97 + copy * 3) % 26;
    if (r >= 65 && r <= 90) return 65 + (r - 65 + copy * 3) % 26;
    if (r >= 0x621 && r <= 0x64a) return 0x621 + (r - 0x621 + copy * 3) % 42;
    return r;
  }),
);

/// Copies real foods, names and servings ×8, with genuinely new vocabulary.
void scalePack(String original, String destination) {
  File(original).copySync(destination);
  final db = sqlite3.open(destination);
  try {
    final foods = db
        .select('SELECT * FROM foods')
        .map(Map<String, Object?>.of)
        .toList();
    final names = db
        .select('SELECT n.* FROM names n JOIN foods f ON f.id=n.target_id')
        .map(Map<String, Object?>.of)
        .toList();
    final servings = db
        .select('SELECT * FROM servings')
        .map(Map<String, Object?>.of)
        .toList();
    void insert(String table, Map<String, Object?> row) => db.execute(
      'INSERT INTO $table (${row.keys.join(',')}) VALUES '
      '(${List.filled(row.length, '?').join(',')})',
      row.values.toList(),
    );
    db.execute('BEGIN');
    for (var copy = 1; copy < 8; copy++) {
      for (final row in foods) {
        insert('foods', {
          ...row,
          'id': '${row['id']}:$copy',
          'name_en': mutateVocabulary(row['name_en']! as String, copy),
          'name_ar': row['name_ar'] == null
              ? null
              : mutateVocabulary(row['name_ar']! as String, copy),
        });
      }
      for (final row in names) {
        insert('names', {
          ...row,
          'target_id': '${row['target_id']}:$copy',
          'name': mutateVocabulary(row['name']! as String, copy),
          'key': normalizeKey(mutateVocabulary(row['name']! as String, copy)),
        });
      }
      for (final row in servings) {
        insert('servings', {...row, 'food_id': '${row['food_id']}:$copy'});
      }
    }
    db
      ..execute("INSERT INTO names_fts(names_fts) VALUES ('rebuild')")
      ..execute('COMMIT');
  } finally {
    db.close();
  }
}

/// Inserts realistic repeated history (including retired snapshot-only IDs).
Future<void> seedHistory(
  AppDatabase db,
  int entries,
  int distinct,
  List<String> catalogIds,
) async {
  await insertEntries(db, [
    for (var i = 1; i <= entries; i++)
      entryRow(
        i,
        date: '2026-10-17',
        slotId: DefaultSlots.all.first.id,
        wall: i,
      ).copyWith(
        foodId: Value(
          i % distinct < catalogIds.length
              ? catalogIds[i % distinct]
              : 'retired:${i % distinct}',
        ),
        nameEn: Value(
          'History food ${mutateVocabulary('snapshot', i % 8)} ${i % distinct}',
        ),
      ),
  ]);
}

/// End-to-end searches through the attached pack on drift's background isolate.
Future<double> searchBenchmark(FoodSearchService service) async {
  for (final query in benchmarkQueries) {
    await service.search(query);
  }
  final micros = <int>[];
  for (var i = 0; i < 10; i++) {
    for (final query in benchmarkQueries) {
      final timer = Stopwatch()..start();
      await service.search(query);
      micros.add(timer.elapsedMicroseconds);
    }
  }
  return p95(micros);
}

/// Aggregate + mapping + history/alias/key refresh; vocabulary is stable, so
/// refreshing usage never rebuilds an unchanged deletion index.
Future<double> historyBenchmark(
  DiaryRepository diary,
  FoodSearchService service,
) async {
  final times = <int>[];
  for (var i = 0; i < 25; i++) {
    final timer = Stopwatch()..start();
    await service.updateHistory(await diary.watchFoodHistory().first);
    if (i >= 5) times.add(timer.elapsedMicroseconds);
  }
  return p95(times);
}

/// Uses a fresh Dart VM because flutter_tester disables its VM service.
Future<({double ms, int bytes, int keys, bool two})> measureIndex(
  List<String> words,
) async {
  var directory = File(Platform.resolvedExecutable).parent;
  var executable = Platform.environment['DART'];
  while (executable == null) {
    final candidate = File('${directory.path}/bin/cache/dart-sdk/bin/dart');
    if (candidate.existsSync()) {
      executable = candidate.path;
      break;
    }
    if (directory.parent.path == directory.path) {
      throw StateError('Dart SDK not found');
    }
    directory = directory.parent;
  }
  final process = await Process.start(executable, [
    '--enable-vm-service=0',
    '--no-dds',
    'test/features/foods/support/fuzzy_index_probe.dart',
  ]);
  final output = utf8.decoder.bind(process.stdout).join();
  final errors = utf8.decoder.bind(process.stderr).join();
  process.stdin.write(jsonEncode(words));
  await process.stdin.close();
  final code = await process.exitCode;
  final text = await output;
  if (code != 0) throw StateError('Heap probe failed: ${await errors}');
  final json = jsonDecode(
    text
        .split('\n')
        .firstWhere((line) => line.startsWith('INDEX_JSON:'))
        .substring(11),
  ) as Map<String, dynamic>;
  return (
    ms: (json['ms'] as num).toDouble(),
    bytes: json['bytes'] as int,
    keys: json['keys'] as int,
    two: json['two'] as bool,
  );
}
