import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/catalog/catalog_pack_source.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'support/db_support.dart';

/// Writes a pack file with one known table, `foods(id, name)`.
String _pack(String dir, String name, List<String> foods) {
  final path = '$dir/$name';
  final db = sqlite3.open(path)
    ..execute('CREATE TABLE foods (id INTEGER PRIMARY KEY, name TEXT)');
  for (final food in foods) {
    db.execute('INSERT INTO foods (name) VALUES (?)', [food]);
  }
  db.close();
  return path;
}

Future<List<String>> _foods(AppDatabase db) => db
    .customSelect('SELECT name FROM catalog.foods ORDER BY id')
    .map((r) => r.read<String>('name'))
    .get();

/// The A01 D14 spike: the pack attaches read-only (`file:…?mode=ro`), a known
/// pack table is readable, and a write to `catalog.*` fails.
void main() {
  test('catalog: no pack → nothing attached', () async {
    final db = fileDatabase('${tempDir().path}/user.db');
    expect(await db.isCatalogAttached(), isFalse);
  });

  for (final background in [false, true]) {
    final where = background ? 'background isolate' : 'main isolate';
    test('catalog ($where): pack attached read-only, select from a known pack '
        'table works, insert into catalog.* fails', () async {
      final dir = tempDir().path;
      // A space and a '#' in the path: the URI must escape them.
      final pack = _pack(dir, 'pack v1 #1.db', ['apple', 'banana']);
      final db = background
          ? backgroundDatabase(dir, catalog: FixedPack(pack))
          : fileDatabase('$dir/user.db', catalog: FixedPack(pack));

      expect(await db.isCatalogAttached(), isTrue);
      expect(await _foods(db), ['apple', 'banana']);
      await expectLater(
        runAuthorizedWrite(
          () => db.customStatement(
            "INSERT INTO catalog.foods (name) VALUES ('x')",
          ),
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('readonly'),
          ),
        ),
      );
      expect(await _foods(db), ['apple', 'banana']);
    });
  }

  test('reattachCatalog swaps the file, and null detaches', () async {
    final dir = tempDir().path;
    final v1 = _pack(dir, 'v1.db', ['apple']);
    final v2 = _pack(dir, 'v2.db', ['cherry', 'date']);
    final db = fileDatabase('$dir/user.db', catalog: FixedPack(v1));
    expect(await _foods(db), ['apple']);

    await db.reattachCatalog(v2);
    expect(await _foods(db), ['cherry', 'date']);

    await db.reattachCatalog(null);
    expect(await db.isCatalogAttached(), isFalse);
  });

  test('a pack that cannot be attached is reported and the database still '
      'opens without a catalog', () async {
    final dir = tempDir().path;
    final errors = <Object>[];
    final db = fileDatabase(
      '$dir/user.db',
      catalog: FixedPack('$dir/missing.db'),
      onCatalogError: (error, _) => errors.add(error),
    );
    expect(await db.select(db.settingsKv).get(), isEmpty);
    expect(await db.isCatalogAttached(), isFalse);
    expect(errors, hasLength(1));
  });

  test('a relative pack path is refused (SQLite would open it writable), '
      'and the database still opens', () async {
    final dir = tempDir().path;
    _pack(dir, 'rel.db', ['apple']);
    final errors = <Object>[];
    final db = fileDatabase(
      '$dir/user.db',
      catalog: const FixedPack('rel.db'),
      onCatalogError: (error, _) => errors.add(error),
    );
    expect(await db.select(db.settingsKv).get(), isEmpty);
    expect(await db.isCatalogAttached(), isFalse);
    expect(errors.single, isA<CatalogAttachException>());
    expect('${errors.single}', isNot(contains('rel.db')));
    await expectLater(
      db.reattachCatalog('rel.db'),
      throwsA(isA<CatalogAttachException>()),
    );
    expect(await db.isCatalogAttached(), isFalse);
  });

  test('reattachCatalog with a missing pack throws', () async {
    final dir = tempDir().path;
    final db = fileDatabase('$dir/user.db');
    await expectLater(
      db.reattachCatalog('$dir/missing.db'),
      throwsA(isA<Exception>()),
    );
    expect(await db.isCatalogAttached(), isFalse);
  });
}
