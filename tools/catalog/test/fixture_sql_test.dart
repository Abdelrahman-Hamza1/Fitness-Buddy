import 'dart:io';

import 'package:fb_catalog/fb_catalog.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

final String _root = p.join('..', '..');
final String _fixture = p.join(
  _root,
  'apps',
  'mobile',
  'test',
  'fixtures',
  'catalog_fixture.sql',
);

void main() {
  test('A05 D7 the committed app fixture SQL is what data/ produces', () {
    final err = StringBuffer();
    final sql = buildFixtureSql(p.join(_root, 'data'), err);
    expect(sql, isNotNull, reason: '$err');
    expect(
      File(_fixture).readAsStringSync(),
      sql,
      reason: 'stale: run `dart run tools/catalog/bin/catalog.dart emit-sql`',
    );
  });

  test(
    'the fixture SQL builds a pack with the schema and the fixture items',
    () {
      final db = sqlite3.openInMemory()
        ..execute(File(_fixture).readAsStringSync());
      addTearDown(db.close);
      final ids = db
          .select('SELECT id FROM foods ORDER BY id')
          .map((r) => r['id'])
          .toList();
      expect(ids, contains('usda:rice_white_long_grain_cooked'));
      expect(ids, contains('ref:mloukhiyeh_rice/chicken'));
      expect(db.select('SELECT id FROM dishes').map((r) => r['id']), [
        'ref:mloukhiyeh_rice',
      ]);
      expect(
        db.select("SELECT 1 FROM names_fts WHERE names_fts MATCH '\"rice\"'"),
        isNotEmpty,
      );
    },
  );
}
