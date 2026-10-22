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
    exercises: File(p.join(dataDir, 'exercises.yaml')),
    cities: File(p.join(dataDir, 'cities.tsv')),
  );
  final report = validateCatalog(
    basics: data.basics,
    dishes: data.dishes,
    requireAr: true,
    yields: data.yields,
    portionWords: data.portionWords,
    exercises: data.exercises,
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
  test('WO-001 every built-in exercise and alias is searchable', () {
    expect(real.data.exercises, hasLength(100));
    expect(search.count('exercises'), 100);
    for (final e in real.data.exercises) {
      for (final name in e.names) {
        expect(targets(search, name).first, e.id, reason: name);
      }
    }
  });

  test(
    'WO-002 equipment variants stay distinct; WO-004 all six types ship',
    () {
      final byId = {for (final e in real.data.exercises) e.id: e};
      expect(byId['ex:barbell_bench_press']!.equipment, 'barbell');
      expect(byId['ex:dumbbell_bench_press']!.equipment, 'dumbbell');
      expect(byId['ex:machine_chest_press']!.equipment, 'machine');
      expect(real.data.exercises.map((e) => e.type).toSet(), {
        'weight_reps',
        'bodyweight_reps',
        'assisted',
        'reps_only',
        'duration',
        'distance_duration',
      });
    },
  );

  test(
    'LC-033 real cities include Hebron and regional centres with valid zones',
    () {
      expect(real.data.cities, hasLength(2276));
      expect(search.count('cities'), 2276);
      final byId = {for (final c in real.data.cities) c.id: c};
      expect(byId['city:285066']!.nameEn, 'Hebron');
      expect(byId['city:285066']!.nameAr, 'الخليل');
      expect(byId['city:285066']!.timezone, 'Asia/Hebron');
      expect(byId['city:250441']!.nameEn, 'Amman');
      expect(byId['city:282239']!.nameEn, 'Ramallah');
      expect(byId['city:282615']!.nameEn, 'Nablus');
      expect(byId['city:250441']!.nameAr, 'عمّان');
      expect(byId['city:281577']!.nameAr, 'طولكرم');
      expect(byId['city:281577']!.nameEn, 'Tulkarm');
      expect(
        real.data.cities.every((c) => isEnglishCityName(c.nameEn)),
        isTrue,
      );
      expect(
        real.data.cities.every(
          (c) => c.nameAr == null || isArabicCityName(c.nameAr!),
        ),
        isTrue,
      );
      for (final id in ['101554', '102744', '107968', '110250']) {
        final ar = byId['city:$id']!.nameAr;
        expect(ar == null || isArabicCityName(ar), isTrue);
      }
      for (final id in ['city:250624', 'city:6946409']) {
        expect(byId[id]!.nameEn, 'Karak');
        expect(byId[id]!.nameAr, 'الكرك');
      }
      expect(byId['city:282239']!.toRow(), {
        'id': 'city:282239',
        'name_en': 'Ramallah',
        'name_ar': 'رام الله',
        'country_code': 'PS',
        'admin1': 'WE',
        'lat': 31.89964,
        'lon': 35.20422,
        'timezone': 'Asia/Hebron',
        'population': 43880,
      });
      for (final id in loadCityExclusions(
        File(p.join(dataDir, 'geonames/excluded_cities.tsv')),
      )) {
        expect(byId, isNot(contains('city:$id')));
      }
      for (final id in ['284376', '284335', '281818', '285111', '285279']) {
        expect(byId, contains('city:$id'));
      }
      for (final id in [
        '281184',
        '360630',
        '108410',
        '292223',
        '276781',
        '170654',
      ]) {
        expect(byId['city:$id']!.nameAr, isNotEmpty);
      }

      expect(
        real.data.cities.every((c) => c.lat.isFinite && c.lon.isFinite),
        isTrue,
      );
    },
  );
}
