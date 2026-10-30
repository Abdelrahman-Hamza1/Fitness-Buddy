import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
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
  test(
    'LC-033 generated fixture contains the ten real GeoNames city examples',
    () {
      final db = sqlite3.openInMemory()
        ..execute(File(_fixture).readAsStringSync());
      addTearDown(db.close);
      final rows = db.select('SELECT * FROM cities ORDER BY id');
      final expected = <String, List<Object?>>{
        'city:246330': ['Umm ar Rasas', 'أم الرصاص', 'JO', 0, 'Asia/Amman'],
        'city:250441': ['Amman', 'عمّان', 'JO', 1275857, 'Asia/Amman'],
        'city:250624': ['Karak', 'الكرك', 'JO', 22581, 'Asia/Amman'],
        'city:281577': ['Tulkarm', 'طولكرم', 'PS', 44169, 'Asia/Hebron'],
        'city:282239': ['Ramallah', 'رام الله', 'PS', 43880, 'Asia/Hebron'],
        'city:282615': ['Nablus', 'نابلس', 'PS', 130326, 'Asia/Hebron'],
        'city:285066': ['Hebron', 'الخليل', 'PS', 160470, 'Asia/Hebron'],
        'city:360630': ['Cairo', 'القاهرة', 'EG', 9606916, 'Africa/Cairo'],
        'city:6946409': ['Karak', 'الكرك', 'JO', 21678, 'Asia/Amman'],
        'city:7303419': [
          'East Jerusalem',
          'القدس الشرقية',
          'PS',
          428304,
          'Asia/Hebron',
        ],
      };
      expect(rows.map((r) => r['id']).toSet(), fixtureCityIds);
      expect(expected.keys.toSet(), fixtureCityIds);
      for (final row in rows) {
        expect([
          row['name_en'],
          row['name_ar'],
          row['country_code'],
          row['population'],
          row['timezone'],
        ], expected[row['id']]);
      }
    },
  );

  test(
    'A10 fixture cities leave every unrelated generated section byte-identical',
    () {
      final sql = File(_fixture).readAsStringSync();
      final withoutCities = sql
          .split('\n')
          .where((line) => !line.startsWith('INSERT INTO cities '))
          .join('\n');
      // A05 fixture before city support: schema, foods, names, servings,
      // yields, FTS and metadata must stay byte-identical. Re-pinned by B09b
      // WP5 (release v7): two name rows, the EN aliases "Rice" and
      // "Rice, raw" on the fixture's white long-grain rice.
      // Re-pinned by A37a: the exercises table gains secondary_muscles.
      expect(
        sha256.convert(utf8.encode(withoutCities)).toString(),
        '5cc34d5e43f1f92af09601ff1ef65f4c5e96279dd1a65c38999db3a2cfd37e0f',
      );
    },
  );

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
