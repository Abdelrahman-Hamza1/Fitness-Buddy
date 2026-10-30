import 'dart:io';

import 'package:fb_catalog/fb_catalog.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'support/data_dir.dart';

final String fixtures = p.join('test', 'fixtures');
final String schemaDir = p.join('..', '..', 'data', 'schema');

/// Builds a pack from the fixture basics and the five pack-fixture dishes.
PackSearch buildFixturePack({bool includeDrafts = true}) {
  final dir = Directory.systemTemp.createTempSync('pack_test');
  addTearDown(() => dir.deleteSync(recursive: true));
  final data = loadCatalog(
    schemaDir: schemaDir,
    selection: File(p.join(fixtures, 'selection.yaml')),
    extract: File(p.join(fixtures, 'extract.jsonl')),
    dishesDir: Directory(p.join(fixtures, 'pack')),
  );
  final report = validateCatalog(basics: data.basics, dishes: data.dishes);
  final out = p.join(dir.path, 'catalog.db');
  buildPack(data: data, report: report, out: out, includeDrafts: includeDrafts);
  final search = PackSearch.open(out);
  addTearDown(search.close);
  return search;
}

List<String> targets(PackSearch s, String q, {int top = 5}) => [
  for (final h in s.search(q, limit: top)) h.target,
];

void main() {
  group('prototype pack', () {
    test('FD-020 / AT-003 resolves maqluba by EN, AR and Arabizi', () {
      final s = buildFixturePack();
      for (final q in ['Maqluba', 'مقلوبة', 'maqlobe', 'ma2lube']) {
        expect(targets(s, q).first, 'ref:maqluba', reason: q);
      }
    });

    test('hits carry review status, display name and per-100 g', () {
      final s = buildFixturePack();
      final hit = s.search('musakhan').first;
      expect(hit.reviewStatus, 'reviewed');
      expect(hit.name, 'Musakhan');
      expect(hit.kcalPer100, 218);
      expect(s.search('maqluba').first.reviewStatus, 'draft');
      expect(s.search('رز').first.reviewStatus, isNull);
    });

    test('D8 drafts are excluded unless --include-drafts', () {
      final plain = buildFixturePack(includeDrafts: false);
      expect(plain.includesDrafts, isFalse);
      expect(targets(plain, 'maqluba'), isEmpty);
      expect(targets(plain, 'musakhan').first, 'ref:musakhan');
      final dev = buildFixturePack();
      expect(dev.includesDrafts, isTrue);
      expect(targets(dev, 'maqluba'), ['ref:maqluba']);
    });

    test('build stops on validation errors', () {
      final data = loadCatalog(
        schemaDir: schemaDir,
        selection: File(p.join(fixtures, 'selection.yaml')),
        extract: File(p.join(fixtures, 'extract.jsonl')),
        dishesDir: Directory(p.join(fixtures, 'bad')),
      );
      final report = validateCatalog(basics: data.basics, dishes: data.dishes);
      expect(
        () => buildPack(data: data, report: report, out: '/nonexistent/x.db'),
        throwsA(isA<PackException>()),
      );
    });

    test('the pack is deterministic: two builds give identical bytes', () {
      final dir = Directory.systemTemp.createTempSync('pack_det');
      addTearDown(() => dir.deleteSync(recursive: true));
      final data = loadCatalog(
        schemaDir: schemaDir,
        selection: File(p.join(fixtures, 'selection.yaml')),
        extract: File(p.join(fixtures, 'extract.jsonl')),
        dishesDir: Directory(p.join(fixtures, 'pack')),
      );
      final report = validateCatalog(basics: data.basics, dishes: data.dishes);
      final a = p.join(dir.path, 'a.db');
      final b = p.join(dir.path, 'b.db');
      buildPack(data: data, report: report, out: a, includeDrafts: true);
      buildPack(data: data, report: report, out: b, includeDrafts: true);
      // Equal bytes mean equal sha256.
      expect(File(a).readAsBytesSync(), File(b).readAsBytesSync());
    });

    test('works with no dishes at all', () {
      final dir = Directory.systemTemp.createTempSync('pack_empty');
      addTearDown(() => dir.deleteSync(recursive: true));
      final data = loadCatalog(
        schemaDir: schemaDir,
        selection: File(p.join(fixtures, 'selection.yaml')),
        extract: File(p.join(fixtures, 'extract.jsonl')),
        dishesDir: Directory(p.join(dir.path, 'none')),
      );
      final report = validateCatalog(basics: data.basics, dishes: data.dishes);
      final out = p.join(dir.path, 'c.db');
      final s = buildPack(
        data: data,
        report: report,
        out: out,
        includeDrafts: true,
      );
      expect(s.dishes, 0);
      expect(s.basics, 3);
    });
  });

  group('coverage', () {
    test('reports resolved, draft, reviewed and missing per language', () {
      final s = buildFixturePack();
      final items = parseMustCover(
        File(p.join(fixtures, 'must_cover.yaml')).readAsStringSync(),
      );
      final rows = {for (final r in measureCoverage(s, items)) r.item.id: r};
      expect(rows['maqluba']!.status, CoverStatus.draft);
      expect(rows['maqluba']!.byLang, {
        'en': true,
        'ar': true,
        'arabizi': true,
      });
      expect(rows['musakhan']!.status, CoverStatus.reviewed);
      expect(rows['kabsa']!.status, CoverStatus.missing);
      expect(rows['kabsa']!.byLang.values, everyElement(isFalse));
      expect(rows['rice_raw']!.status, CoverStatus.basic);
      expect(
        formatCoverage(rows.values.toList()),
        contains('| main | kabsa |'),
      );
    });

    test('must-cover parser rejects duplicates and a missing English name', () {
      expect(
        () => parseMustCover(
          'groups:\n  - id: g\n    items:\n'
          '      - {id: a, names: {en: [A]}}\n'
          '      - {id: a, names: {en: [A]}}\n',
        ),
        throwsA(isA<MustCoverException>()),
      );
      expect(
        () => parseMustCover(
          'groups:\n  - id: g\n    items:\n      - {id: a, names: {ar: [ا]}}\n',
        ),
        throwsA(isA<MustCoverException>()),
      );
    });
  });

  group('cli', () {
    test('build, query and coverage run end to end', () async {
      final data = makeDataDir();
      final dir = Directory.systemTemp.createTempSync('pack_cli');
      addTearDown(() => dir.deleteSync(recursive: true));
      final pack = p.join(dir.path, 'catalog.db');
      final out = StringBuffer();
      final err = StringBuffer();
      Future<int> run(List<String> a) => runCatalog(a, out: out, err: err);
      expect(
        await run([
          'build',
          '--update',
          '--data-dir',
          data.path,
          '--contract-dir',
          contractDir,
          '--out-dir',
          dir.path,
          '--include-drafts',
        ]),
        0,
        reason: '$err',
      );
      expect(await run(['query', '--pack', pack, 'maqlobe']), 0);
      expect(out.toString(), contains('1. ref:maqluba'));
      expect(
        await run([
          'coverage',
          '--pack',
          pack,
          '--must-cover',
          p.join(fixtures, 'must_cover.yaml'),
        ]),
        0,
      );
      expect(
        out.toString(),
        contains('| main | maqluba | yes | yes | yes | draft'),
      );
      expect(await run(['query', '--pack', p.join(dir.path, 'no.db'), 'x']), 1);
    });
  });
}
