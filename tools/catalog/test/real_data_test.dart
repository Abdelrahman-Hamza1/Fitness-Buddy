import 'dart:io';

import 'package:fb_catalog/fb_catalog.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

final String dataDir = p.join('..', '..', 'data');

/// The real committed data: selection, extract and the reference dishes.
({CatalogData data, ValidationReport report, String pack}) buildReal() {
  final dir = Directory.systemTemp.createTempSync('real_data');
  addTearDown(() => dir.deleteSync(recursive: true));
  final data = loadCatalog(
    schemaDir: p.join(dataDir, 'schema'),
    selection: File(p.join(dataDir, 'usda_selection.yaml')),
    extract: File(p.join(dataDir, 'usda', 'extract.jsonl')),
    dishesDir: Directory(p.join(dataDir, 'reference_dishes')),
    yields: File(p.join(dataDir, 'yields.yaml')),
    portionWords: File(p.join(dataDir, 'portion_words.yaml')),
  );
  final report = validateCatalog(
    basics: data.basics,
    dishes: data.dishes,
    requireAr: true,
    yields: data.yields,
    portionWords: data.portionWords,
  );
  final out = p.join(dir.path, 'catalog.db');
  buildPack(data: data, report: report, out: out, includeDrafts: true);
  return (data: data, report: report, pack: out);
}

List<String> targets(PackSearch s, String q) => [
  for (final h in s.search(q, limit: 5)) h.target,
];

void main() {
  late PackSearch search;
  late ({CatalogData data, ValidationReport report, String pack}) real;

  setUpAll(() {
    real = buildReal();
    search = PackSearch.open(real.pack);
  });
  tearDownAll(() => search.close());

  test('FD-050 the real data validates with no errors', () {
    expect([...real.data.issues, ...real.report.errors], isEmpty);
    expect(real.data.dishes.length, greaterThanOrEqualTo(5));
  });

  test('FD-060 every staple group has a yields row', () {
    final groups = {for (final y in real.data.yields!) y.group};
    const staples = [
      'rice',
      'bulgur',
      'freekeh',
      'pasta',
      'lentils',
      'chickpeas',
      'beans',
      'chicken',
      'beef',
      'lamb',
      'fish',
      'potatoes',
    ];
    expect(groups, containsAll(staples));
    expect(real.data.portionWords, isNotEmpty);
  });

  test('T07 "akalt sahen maqlobe 3nd sitti" returns ref:maqluba first', () {
    expect(
      targets(search, 'akalt sahen maqlobe 3nd sitti').first,
      'ref:maqluba',
    );
  });

  test('T08 "صحن ملوخية مع رز" returns ref:mloukhiyeh_rice first', () {
    expect(targets(search, 'صحن ملوخية مع رز').first, 'ref:mloukhiyeh_rice');
  });

  test('T12 "شاورما دجاج عربي" returns ref:chicken_shawarma_arabi first', () {
    expect(
      targets(search, 'شاورما دجاج عربي').first,
      'ref:chicken_shawarma_arabi',
    );
  });

  test('FD-020 every real dish resolves by its EN, AR and Arabizi names', () {
    expect(real.data.dishes.length, greaterThanOrEqualTo(5));
    for (final d in real.data.dishes) {
      for (final lang in ['en', 'ar', 'arabizi']) {
        final name = d.names[lang]!.first;
        expect(
          targets(search, name).first,
          d.id,
          reason: '${d.id} by $lang "$name"',
        );
      }
    }
  });
}
