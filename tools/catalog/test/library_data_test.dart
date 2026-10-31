import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:fb_catalog/fb_catalog.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import 'support/data_dir.dart';

const exercise = '''
exercises:
  - id: ex:barbell_bench_press
    names: {en: [Barbell bench press, BB bench]}
    type: weight_reps
    equipment: barbell
    primary_muscle: chest
    secondary_muscles: [triceps, shoulders]
    popularity: 1
''';

const _plank = '''
  - id: ex:plank
    names: {en: [Plank]}
    type: duration
    equipment: bodyweight
    primary_muscle: abs
    secondary_muscles: []
    popularity: 19
''';

String geoname(
  String id,
  String country,
  int population, {
  String name = 'Town',
  String ascii = 'Town',
  String alternates = '',
  String zone = 'Asia/Hebron',
  String lat = '31.5',
}) => [
  id,
  name,
  ascii,
  alternates,
  lat,
  '35.0',
  'P',
  'PPL',
  country,
  '',
  '01',
  '',
  '',
  '',
  '$population',
  '',
  '',
  zone,
  '2026-10-22',
].join('\t');

void main() {
  late Directory data;
  late Set<String> zones;
  setUp(() {
    data = makeDataDir();
    zones = loadTimezones(File(p.join(realSchemaDir, 'iana_timezones.txt')));
  });

  List<CatalogIssue> exerciseIssues(String text) {
    final file = File(p.join(data.path, 'exercises.yaml'))
      ..writeAsStringSync(text);
    final issues = <CatalogIssue>[];
    loadExercises(
      file,
      loadSchema(realSchemaDir, 'exercises.v1.schema.json'),
      issues,
    );
    return issues;
  }

  test('WO-001 WO-002 stable IDs and deterministic searchable aliases', () {
    File(p.join(data.path, 'exercises.yaml')).writeAsStringSync(exercise);
    final logs = StringBuffer();
    BuildResult build({required bool update}) => runBuild(
      BuildOptions(
        data: DataPaths(data.path),
        contractDir: contractDir,
        outDir: p.join(data.path, 'out'),
        update: update,
      ),
      out: logs,
      err: logs,
    );
    final first = build(update: true);
    expect(first.exitCode, 0, reason: '$logs');
    final bytes = File(first.packPath!).readAsBytesSync();
    final second = build(update: false);
    expect(second.exitCode, 0, reason: '$logs');
    expect(File(second.packPath!).readAsBytesSync(), bytes);
    expect(first.release!.released['ex:barbell_bench_press'], 'exercise');
    expect(validateLoadFiles(first.release!, contractDir), isEmpty);
    final search = PackSearch.open(first.packPath!);
    addTearDown(search.close);
    expect(search.search('BB bench').first.target, 'ex:barbell_bench_press');
    expect(search.search('BB bench').first.kcalPer100, isNull);
  });

  test(
    'WO-001 invalid exercise fields, types, IDs and aliases fail validation',
    () {
      for (final text in [
        exercise.replaceFirst('weight_reps', 'made_up'),
        exercise.replaceFirst('barbell\n', 'tractor\n'),
        exercise.replaceFirst(
          'primary_muscle: chest',
          'primary_muscle: unknown',
        ),
        exercise.replaceFirst('ex:barbell_bench_press', 'ex:UPPER'),
        exercise.replaceFirst('BB bench', 'Barbell BENCH press'),
        exercise.replaceFirst('names: {en:', 'names: {ar:'),
        exercise.replaceFirst(
          'type: weight_reps',
          'typo: true\n    type: weight_reps',
        ),
        '$exercise${exercise.substring(exercise.indexOf('  - id:'))}',
      ]) {
        expect(exerciseIssues(text), isNotEmpty, reason: text);
      }
    },
  );

  test('WO-007 secondary muscles flow into release and pack', () {
    File(p.join(data.path, 'exercises.yaml'))
        .writeAsStringSync('$exercise$_plank');
    final logs = StringBuffer();
    final result = runBuild(
      BuildOptions(
        data: DataPaths(data.path),
        contractDir: contractDir,
        outDir: p.join(data.path, 'out'),
        update: true,
      ),
      out: logs,
      err: logs,
    );
    expect(result.exitCode, 0, reason: '$logs');
    final rows = {
      for (final row in result.release!.table('exercises'))
        row['id']! as String: row,
    };
    expect(rows['ex:barbell_bench_press']!['secondary_muscles'], [
      'triceps',
      'shoulders',
    ]);
    expect(rows['ex:plank']!['secondary_muscles'], isEmpty);
    expect(rows['ex:plank']!['popularity'], 19);
    expect(validateLoadFiles(result.release!, contractDir), isEmpty);
    final pack = sqlite3.open(result.packPath!, mode: OpenMode.readOnly);
    addTearDown(pack.close);
    expect(
      {
        for (final r in pack.select(
          'SELECT id, primary_muscle, secondary_muscles, popularity '
          'FROM exercises',
        ))
          r['id']:
              '${r['primary_muscle']}|${r['secondary_muscles']}|'
              '${r['popularity']}',
      },
      {
        'ex:barbell_bench_press': 'chest|triceps,shoulders|1',
        'ex:plank': 'abs||19',
      },
    );
  });

  test('WO-007 loader rejects secondary equal to primary or duplicated', () {
    expect(exerciseIssues(exercise), isEmpty);
    for (final secondaries in [
      '[chest]',
      '[triceps, chest]',
      '[triceps, triceps]',
      '[triceps, shoulders, abs, forearms, biceps]',
      '[neck]',
      '[back]',
    ]) {
      expect(
        exerciseIssues(
          exercise.replaceFirst('[triceps, shoulders]', secondaries),
        ),
        isNotEmpty,
        reason: secondaries,
      );
    }
    // The key is required, even when empty.
    expect(
      exerciseIssues(
        exercise.replaceFirst(
          '    secondary_muscles: [triceps, shoulders]\n',
          '',
        ),
      ),
      isNotEmpty,
    );
    // Legacy primaries left the vocabulary (A37 D2).
    for (final legacy in ['back', 'core', 'full_body']) {
      expect(
        exerciseIssues(
          exercise.replaceFirst(
            'primary_muscle: chest',
            'primary_muscle: $legacy',
          ),
        ),
        isNotEmpty,
        reason: legacy,
      );
    }
  });

  test('WO-001 loader requires a unique popularity rank in 1..100', () {
    expect(exerciseIssues('$exercise$_plank'), isEmpty);
    for (final bad in ['0', '101', '1.5', '"1"']) {
      expect(
        exerciseIssues(
          exercise.replaceFirst('popularity: 1', 'popularity: $bad'),
        ),
        isNotEmpty,
        reason: bad,
      );
    }
    expect(
      exerciseIssues(exercise.replaceFirst('    popularity: 1\n', '')),
      isNotEmpty,
    );
    expect(
      exerciseIssues(
        '$exercise${_plank.replaceFirst('popularity: 19', 'popularity: 1')}',
      ),
      isNotEmpty,
    );
  });

  test('WO-001 normalized exercise aliases cannot collide with foods', () {
    File(p.join(data.path, 'exercises.yaml'))
        .writeAsStringSync(exercise.replaceFirst('BB bench', 'Olive oil'));
    final logs = StringBuffer();
    expect(loadAndValidate(DataPaths(data.path), logs), isNull);
    expect('$logs', contains('duplicate en name'));
  });

  test('LC-033 GeoNames selection covers PS/JO, region and million-population boundary', () {
    final lines = [
      geoname('1', 'PS', 1),
      geoname('2', 'JO', 5000),
      geoname('3', 'TR', 15001),
      geoname('4', 'US', 999999),
      geoname('5', 'US', 1000000),
      geoname('6', 'AE', 15001),
    ];
    expect(
      selectCities(lines, localDataset: true, zones: zones).map((c) => c.id),
      ['city:1', 'city:2'],
    );
    expect(
      selectCities(lines, localDataset: false, zones: zones).map((c) => c.id),
      ['city:3', 'city:5', 'city:6'],
    );
  });

  test(
    'LC-033 language tags, preferred names and fallbacks are deterministic',
    () {
      final alternates = [
        ['1', '1', 'ku', 'ئاممان', '1', '', '', '', '', ''].join('\t'),
        ['2', '1', 'ar', 'عمان', '', '', '', '', '', ''].join('\t'),
        ['3', '1', 'ar', 'عمّان', '1', '', '', '', '', ''].join('\t'),
        ['4', '1', 'en', 'Amman', '1', '', '', '', '', ''].join('\t'),
        ['5', '1', 'en', 'Old town', '1', '', '', '1', '', ''].join('\t'),
        ['6', '1', 'ar', 'قديم', '1', '', '', '', '', '1950'].join('\t'),
        ['7', '1', 'ar', 'كرك', '1', '', '', '', '', ''].join('\t'),
        ['8', '1', 'ar', 'Amman', '1', '', '', '', '', ''].join('\t'),
        ['9', '2', 'ar', 'Tulkarm', '1', '', '', '', '', ''].join('\t'),
        ['10', '2', 'en', 'Ţūlkarm', '1', '', '', '', '', ''].join('\t'),
      ];
      final rows = [
        geoname('1', 'JO', 1000, name: 'Default'),
        geoname(
          '2',
          'PS',
          1000,
          name: 'Ţūlkarm',
          ascii: 'Tulkarm',
          alternates: 'فارسی',
        ),
      ];
      List<CitySeed> select(Iterable<String> names) => selectCities(
        rows,
        localDataset: true,
        zones: zones,
        names: CityNames(names),
      );
      final cities = select(alternates);
      expect(cities.first.nameEn, 'Amman');
      expect(cities.first.nameAr, 'عمّان');
      expect(cities.last.nameEn, 'Tulkarm');
      expect(cities.last.nameAr, isNull);
      expect(encodeCities(cities), encodeCities(select(alternates.reversed)));
      final file = File(p.join(data.path, 'cities.tsv'))
        ..writeAsStringSync(encodeCities(cities));
      final issues = <CatalogIssue>[];
      expect(
        loadCities(file, zones, issues).first.toRow(),
        cities.first.toRow(),
      );
      expect(issues, isEmpty);
    },
  );

  test(
    'LC-033 Persian/Kurdish forms normalize without losing Arabic diacritics',
    () {
      expect(normalizeArabicCityName('  کڪیےہھەۀ\u200f '), 'ككييهههه');
      expect(normalizeArabicCityName('عمّان'), 'عمّان');
      expect(normalizeArabicCityName(normalizeArabicCityName('کریم')), 'كريم');
    },
  );

  test(
    'LC-033 exclusion uses IDs and keeps Palestinian Asia/Jerusalem rows',
    () {
      final rows = [
        geoname('11979628', 'PS', 3151, zone: 'Asia/Jerusalem'),
        geoname('284375', 'PS', 56746, zone: 'Asia/Jerusalem'),
      ];
      expect(
        selectCities(
          rows,
          localDataset: true,
          zones: zones,
          excludedIds: {'11979628'},
        ).map((c) => c.id),
        ['city:284375'],
      );
    },
  );

  test('LC-033 committed city checks reject invalid '
      'English and Arabic scripts', () {
    const valid =
        "city:1\tAl-Town 2, St. John's\tعمّان\tPS\t01\t31.5\t35.0\t"
        'Asia/Hebron\t100';
    for (final bad in [
      'Ţūlkarm',
      'عمان',
      'Town/City',
      'Town (City)',
      'Town`City',
      'Town\n',
    ]) {
      final file = File(p.join(data.path, 'cities.tsv'))
        ..writeAsStringSync(
          '$cityHeader\n${valid.replaceFirst("Al-Town 2, St. John's", bad)}\n',
        );
      final issues = <CatalogIssue>[];
      loadCities(file, zones, issues);
      expect(issues, isNotEmpty, reason: bad);
    }
    for (final bad in [
      'Tārūt',
      'Rumāḩ',
      'Aţ Ţā’if',
      '‘Afīf',
      'عمان Amman',
      'عمان 1',
      'عمان،',
      'ַ',
      'ّ',
    ]) {
      final file = File(p.join(data.path, 'cities.tsv'))
        ..writeAsStringSync(
          '$cityHeader\n${valid.replaceFirst('عمّان', bad)}\n',
        );
      final issues = <CatalogIssue>[];
      loadCities(file, zones, issues);
      expect(issues, isNotEmpty, reason: bad);
    }
    for (final ar in ['', 'عمّان', 'القُدْس', 'رام الله']) {
      final file = File(
        p.join(data.path, 'cities.tsv'),
      )..writeAsStringSync('$cityHeader\n${valid.replaceFirst('عمّان', ar)}\n');
      final issues = <CatalogIssue>[];
      expect(loadCities(file, zones, issues), hasLength(1));
      expect(issues, isEmpty);
    }
  });

  test('LC-033 English source punctuation normalizes before validation', () {
    expect(normalizeEnglishCityName(' Giv‘at–Town` '), "Giv'at-Town'");
  });

  test('LC-033 invalid coordinates, zones, populations and IDs fail', () {
    const valid =
        'city:1\tHebron\tالخليل\tPS\t01\t31.5\t35.0\tAsia/Hebron\t100';
    for (final row in [
      valid.replaceFirst('31.5', 'NaN'),
      valid.replaceFirst('31.5', '91'),
      valid.replaceFirst('35.0', '-181'),
      valid.replaceFirst('Asia/Hebron', 'Mars/Olympus'),
      valid.replaceFirst('\t100', '\t-1'),
      valid.replaceFirst('city:1', 'city:0'),
      valid.replaceFirst('\t31.5', '\t'),
      '$valid\n$valid',
      'short',
    ]) {
      final file = File(p.join(data.path, 'cities.tsv'))
        ..writeAsStringSync('$cityHeader\n$row\n');
      final issues = <CatalogIssue>[];
      loadCities(file, zones, issues);
      expect(issues, isNotEmpty, reason: row);
    }
    expect(
      parseCity(
        valid.replaceFirst('Asia/Hebron', 'US/Eastern').split('\t'),
        zones,
      ).timezone,
      'US/Eastern',
    );
  });

  test(
    'LC-033 local import verifies text pins before writing any subset',
    () async {
      final files = <Map<String, String>>[];
      for (final name in [
        'cities1000',
        'cities15000',
        'PS',
        'JO',
        ...regionCountries,
      ]) {
        final text = name.length == 2
            ? '${['1', '1', 'ar', 'اسم', '1', '', '', '', '', ''].join('\t')}\n'
            : '${geoname(name == 'cities1000' ? '1' : '2', 'PS', 1000)}\n';
        File(p.join(data.path, '$name.txt')).writeAsStringSync(text);
        files.add({
          'name': name,
          'text_sha256': sha256.convert(utf8.encode(text)).toString(),
        });
      }
      File(p.join(data.path, 'excluded_cities.tsv'))
          .writeAsStringSync('geonameid\tname\n');
      final sources = File(p.join(data.path, 'sources.yaml'))
        ..writeAsStringSync(jsonEncode({'datasets': files}));
      final cities = await importCities(
        directory: data,
        sources: sources,
        zones: zones,
      );
      expect(cities.map((c) => c.id), ['city:1']);
      expect(cities.single.nameAr, 'اسم');
      expect(
        encodeCities(
          await importCities(directory: data, sources: sources, zones: zones),
        ),
        encodeCities(cities),
      );
      File(p.join(data.path, 'JO.txt')).writeAsStringSync('changed');
      await expectLater(
        importCities(directory: data, sources: sources, zones: zones),
        throwsA(isA<FormatException>()),
      );
      File(p.join(data.path, 'cities1000.txt')).writeAsStringSync('changed');
      expect(
        importCities(directory: data, sources: sources, zones: zones),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('checksum mismatch'),
          ),
        ),
      );
    },
  );
  test('LC-033 malformed source pins have a readable format error', () async {
    final sources = File(p.join(data.path, 'sources.yaml'));
    for (final text in [
      '',
      '[',
      '[]',
      '{}',
      '{"datasets": [null]}',
      '{"datasets": [{"name": "cities1000", "text_sha256": "bad"}]}',
    ]) {
      sources.writeAsStringSync(text);
      await expectLater(
        importCities(directory: data, sources: sources, zones: zones),
        throwsA(isA<FormatException>()),
      );
    }
  });
}
