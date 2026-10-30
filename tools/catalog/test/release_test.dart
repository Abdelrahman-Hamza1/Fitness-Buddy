import 'dart:convert';
import 'dart:io';

import 'package:fb_catalog/fb_catalog.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import 'support/data_dir.dart';

IdLock lockFixture(String name) => IdLock.parse(
  File(p.join(fixtureDir, 'lock', name)).readAsStringSync(),
  source: name,
);

/// Runs a build over [data] into a fresh output folder.
({BuildResult result, String out, StringBuffer log, StringBuffer err}) build(
  Directory data, {
  bool update = true,
  bool drafts = false,
  IdLock? base,
  int maxBytes = maxPackBytes,
}) {
  final out = Directory.systemTemp.createTempSync('release_out');
  addTearDown(() => out.deleteSync(recursive: true));
  final log = StringBuffer();
  final err = StringBuffer();
  final result = runBuild(
    BuildOptions(
      data: DataPaths(data.path),
      contractDir: contractDir,
      outDir: out.path,
      update: update,
      includeDrafts: drafts,
      baseLock: base,
      maxBytes: maxBytes,
      gitCommit: 'abc1234',
    ),
    out: log,
    err: err,
  );
  return (result: result, out: out.path, log: log, err: err);
}

String read(String out, String name) =>
    File(p.join(out, 'release', name)).readAsStringSync();

Database openPack(String out) {
  final db = sqlite3.open(p.join(out, 'catalog.db'), mode: OpenMode.readOnly);
  addTearDown(db.close);
  return db;
}

void main() {
  group('ID lock (D2)', () {
    final base = lockFixture('base.lock');

    test('ID stability: a base lock line missing in head fails', () {
      final problems = compareWithBase(base, lockFixture('head_removed.lock'));
      expect(problems, hasLength(1));
      expect(problems.single, contains('ref:musakhan/standard'));
    });

    test('ID stability: an ID whose kind or version changed fails', () {
      final problems = compareWithBase(base, lockFixture('head_changed.lock'));
      expect(problems, hasLength(2));
      expect(problems.join(), contains('changed'));
    });

    test('ID stability: a retired ID that is active again fails', () {
      final problems = compareWithBase(
        lockFixture('base_retired.lock'),
        lockFixture('head_revived.lock'),
      );
      expect(problems.single, contains('active again'));
    });

    test('ID stability: active to retired and new IDs pass', () {
      expect(compareWithBase(base, lockFixture('head_retired.lock')), isEmpty);
    });

    test('ID stability: a retired ID back in the data fails', () {
      final r = compareWithData(lockFixture('base_retired.lock'), {
        'usda:olive_oil': 'food',
      });
      expect(r.errors.single, contains('back in the data'));
    });

    test('ID stability: a released ID gone from the data fails', () {
      final r = compareWithData(base, {'usda:rice_raw': 'food'});
      expect(r.errors.join(), contains('ref:musakhan'));
    });

    test('ID stability: a released ID not in the lock is stale', () {
      final r = compareWithData(const IdLock.empty(), {
        'usda:rice_raw': 'food',
      });
      expect(r.missing, ['usda:rice_raw']);
      expect(r.errors, isEmpty);
    });

    test('lock text round trips and is sorted', () {
      final lock = IdLock.parse(lockFixture('head_retired.lock').format());
      expect(lock.format(), lockFixture('head_retired.lock').format());
      expect(
        () => IdLock.parse('usda:x\tfood\tx\tactive'),
        throwsA(isA<LockFormatException>()),
      );
    });

    test('catalog IDs follow the grammar', () {
      for (final ok in [
        'usda:rice_raw',
        'ref:maqluba',
        'ref:maqluba/chicken',
      ]) {
        expect(isValidFoodId(ok), isTrue, reason: ok);
      }
      for (final bad in ['usda:Rice', 'ref:a/b/c', 'x:y', 'usda:', 'ref:a b']) {
        expect(isValidFoodId(bad), isFalse, reason: bad);
      }
      expect(isValidFoodId('usda:${'a' * 60}'), isFalse);
    });
  });

  group('release build', () {
    test('make catalog flow: stale fails, update locks, then it is fresh', () {
      final data = makeDataDir();
      final stale = build(data, update: false);
      expect(stale.result.exitCode, 1);
      expect(stale.err.toString(), contains('run `make catalog`'));
      expect(File(p.join(data.path, 'catalog_ids.lock')).existsSync(), isFalse);

      final first = build(data);
      expect(first.result.exitCode, 0, reason: '${first.err}');
      expect(first.result.version, 1);
      final lock = IdLock.parse(
        File(p.join(data.path, 'catalog_ids.lock')).readAsStringSync(),
      );
      expect(lock.entries.keys, contains('ref:musakhan/standard'));
      expect(lock.entries['ref:musakhan']!.kind, 'dish');
      expect(lock.entries['usda:rice_raw']!.kind, 'food');
      expect(lock.entries.keys.any((k) => k.contains('maqluba')), isFalse);

      // Nothing changed: fresh without --update, same version.
      final again = build(data, update: false);
      expect(again.result.exitCode, 0, reason: '${again.err}');
      expect(again.result.version, 1);
    });

    test('catalog_version bumps when the content changes, not otherwise', () {
      final data = makeDataDir();
      expect(build(data).result.version, 1);
      expect(build(data).result.version, 1);
      // A new reviewed dish: new IDs, new version, old IDs keep version 1.
      final fix = File(p.join(fixtureDir, 'pack', 'maqluba.yaml'))
          .readAsStringSync()
          .replaceFirst('status: draft', 'status: reviewed');
      File(p.join(data.path, 'reference_dishes', 'maqluba.yaml'))
          .writeAsStringSync(fix);
      final second = build(data);
      expect(second.result.exitCode, 0, reason: '${second.err}');
      expect(second.result.version, 2);
      final lock = IdLock.parse(
        File(p.join(data.path, 'catalog_ids.lock')).readAsStringSync(),
      );
      expect(lock.entries['ref:maqluba']!.firstVersion, 2);
      expect(lock.entries['ref:musakhan']!.firstVersion, 1);
      // A content change without a new ID also bumps.
      File(p.join(data.path, 'yields.yaml')).writeAsStringSync(
        'rows:\n  - {group: rice, from: dry, to: cooked, factor: 2.8, '
        'source: "test"}\n',
      );
      final third = build(data);
      expect(third.result.version, 3, reason: '${third.err}');
    });

    test('two builds give identical load files and an identical pack', () {
      final data = makeDataDir();
      final a = build(data);
      final b = build(data, update: false);
      for (final f in loadFileNames) {
        expect(read(a.out, '$f.jsonl'), read(b.out, '$f.jsonl'), reason: f);
      }
      expect(
        File(p.join(a.out, 'catalog.db')).readAsBytesSync(),
        File(p.join(b.out, 'catalog.db')).readAsBytesSync(),
      );
    });

    test('FD-051 release build has no draft rows; --include-drafts does', () {
      final data = makeDataDir();
      final release = build(data);
      var db = openPack(release.out);
      expect(
        db
            .select("SELECT value FROM meta WHERE key = 'includes_drafts'")
            .single['value'],
        '0',
      );
      expect(
        db
            .select(
              "SELECT count(*) n FROM foods WHERE review_status = 'draft'",
            )
            .single['n'],
        0,
      );
      expect(db.select('SELECT id FROM dishes').single['id'], 'ref:musakhan');
      final dev = build(data, drafts: true);
      db = openPack(dev.out);
      expect(
        db
            .select("SELECT value FROM meta WHERE key = 'includes_drafts'")
            .single['value'],
        '1',
      );
      expect(db.select('SELECT id FROM dishes'), hasLength(5));
      // Drafts are never locked.
      final lock = File(p.join(data.path, 'catalog_ids.lock'))
          .readAsStringSync();
      expect(lock, isNot(contains('maqluba')));
    });

    test('FD-001 / FD-010 every food row is complete with a source', () {
      final data = makeDataDir();
      final r = build(data, drafts: true);
      final db = openPack(r.out);
      final rows = db.select('SELECT * FROM foods');
      expect(rows, isNotEmpty);
      for (final row in rows) {
        for (final c in [
          'name_en', 'state', 'basis', 'kcal', 'protein_g', 'carbs_g',
          'fat_g', 'fiber_g', 'source', 'verified', 'catalog_version', //
        ]) {
          expect(row[c], isNotNull, reason: '${row['id']} $c');
        }
        expect(row['source'], anyOf('usda', 'reference'));
        // Basics have no range; variants have both bounds.
        expect(
          row['kcal_low'] == null,
          row['kind'] == 'basic',
          reason: '${row['id']}',
        );
      }
      expect(db.select("SELECT 1 FROM foods WHERE source = 'off'"), isEmpty);
    });

    test('FD-002 extras only when present', () {
      final data = makeDataDir();
      final r = build(data, drafts: true);
      final db = openPack(r.out);
      final extras = db.select(
        'SELECT extras_json FROM foods WHERE extras_json IS NOT NULL',
      );
      for (final row in extras) {
        expect(jsonDecode(row['extras_json'] as String), isNotEmpty);
      }
    });

    test(
      'pack schema v1 has the full table set, empty exercises and cities',
      () {
        final data = makeDataDir();
        final r = build(data);
        final db = openPack(r.out);
        expect(db.select('PRAGMA user_version').single.values.single, 1);
        final tables = {
          for (final t in db.select(
            "SELECT name FROM sqlite_master WHERE type = 'table'",
          ))
            t['name'],
        };
        expect(
          tables,
          containsAll([
            'meta', 'foods', 'dishes', 'names', 'names_fts', 'servings',
            'yields', 'barcodes', 'exercises', 'cities', //
          ]),
        );
        for (final t in ['exercises', 'cities', 'barcodes']) {
          expect(db.select('SELECT 1 FROM $t'), isEmpty, reason: t);
        }
        final meta = {
          for (final m in db.select('SELECT key, value FROM meta'))
            m['key']: m['value'],
        };
        expect(meta['schema_version'], '1');
        expect(meta['catalog_version'], '1');
        expect(meta['content_sha256'], hasLength(64));
      },
    );

    test('load files validate against contracts/catalog schemas', () {
      final data = makeDataDir();
      final r = build(data, drafts: true);
      expect(r.result.exitCode, 0, reason: '${r.err}');
      expect(validateLoadFiles(r.result.release!, contractDir), isEmpty);
      // A broken row is caught by the schema.
      final bad = r.result.release!.table('foods').first;
      final broken = Release(
        includesDrafts: false,
        released: const {},
        sanity: const {},
        attribution: const [],
        tables: {
          'foods': [
            {...bad, 'kcal': -1},
          ],
        },
      );
      expect(validateLoadFiles(broken, contractDir).join(), contains('foods'));
    });

    test('manifest counts and checksums match the files', () {
      final data = makeDataDir();
      final r = build(data);
      final manifest =
          jsonDecode(read(r.out, 'manifest.json')) as Map<String, dynamic>;
      final files = manifest['files'] as Map<String, dynamic>;
      for (final name in loadFileNames) {
        final text = read(r.out, '$name.jsonl');
        final info = files['$name.jsonl'] as Map<String, dynamic>;
        expect(info['sha256'], sha256Hex(utf8.encode(text)), reason: name);
        expect(info['count'], const LineSplitter().convert(text).length);
        expect(info['bytes'], utf8.encode(text).length);
      }
      final pack = manifest['pack'] as Map<String, dynamic>;
      final bytes = File(p.join(r.out, 'catalog.db')).readAsBytesSync();
      expect(pack['sha256'], sha256Hex(bytes));
      expect(pack['bytes'], bytes.length);
      expect(manifest['catalog_version'], 1);
      expect(manifest['includes_drafts'], false);
      expect(manifest['git_commit'], 'abc1234');
      expect((manifest['counts'] as Map)['dishes'], 1);
    });

    test('content hash is the manifest hash', () {
      final data = makeDataDir();
      final r = build(data);
      expect(
        contentHash(r.result.release!),
        (jsonDecode(read(r.out, 'manifest.json')) as Map)['content_sha256'],
      );
    });

    test('size budget fails a fixture over the limit (limit injected)', () {
      final data = makeDataDir();
      final r = build(data, maxBytes: 1000);
      expect(r.result.exitCode, 1);
      expect(r.err.toString(), contains('budget'));
    });

    test('FD-012 a dish that fails sanity fails the build (fixture)', () {
      final data = makeDataDir(extraDishes: ['bad/sanity_fail.yaml']);
      final r = build(data);
      expect(r.result.exitCode, 1);
      expect(r.err.toString(), contains('sanity fail'));
    });

    test('FD-004 a duplicate normalized name fails the build (fixture)', () {
      final data = makeDataDir(extraDishes: ['bad/duplicate_name.yaml']);
      final r = build(data);
      expect(r.result.exitCode, 1);
      expect(r.err.toString(), contains('duplicate'));
    });

    test('FD-060 yields load and reach the pack', () {
      final data = makeDataDir();
      File(p.join(data.path, 'yields.yaml')).writeAsStringSync(
        'rows:\n  - {group: rice, from: dry, to: cooked, factor: 2.8, '
        'source: "test"}\n',
      );
      final selection = File(p.join(data.path, 'usda_selection.yaml'));
      selection.writeAsStringSync(
        selection.readAsStringSync().replaceFirst(
          '    state: dry\n',
          '    state: dry\n    yield_group: rice\n',
        ),
      );
      final r = build(data);
      expect(r.result.exitCode, 0, reason: '${r.err}');
      final db = openPack(r.out);
      expect(db.select('SELECT factor FROM yields').single['factor'], 2.8);
      expect(
        db
            .select("SELECT yield_group FROM foods WHERE id = 'usda:rice_raw'")
            .single['yield_group'],
        'rice',
      );
    });

    test('FD-003 / LC-051 portion words become servings in g or ml', () {
      final data = makeDataDir();
      File(p.join(data.path, 'portion_words.yaml')).writeAsStringSync(
        'rows:\n'
        '  - {food: "usda:olive_oil", unit: glass, ml: 250, '
        'range: [200, 300], source: "test"}\n'
        '  - {food: "usda:rice_raw", unit: can, g: 160, source: "test"}\n',
      );
      final r = build(data);
      expect(r.result.exitCode, 0, reason: '${r.err}');
      final db = openPack(r.out);
      final glass = db
          .select("SELECT * FROM servings WHERE food_id = 'usda:olive_oil'")
          .single;
      expect(glass['ml'], 250);
      expect(glass['g'], isNull);
      final can = db
          .select("SELECT * FROM servings WHERE food_id = 'usda:rice_raw'")
          .single;
      expect(can['g'], 160);
      // Dish portions are stored on the variant.
      expect(
        db.select("SELECT 1 FROM servings WHERE food_id LIKE 'ref:musakhan/%'"),
        isNotEmpty,
      );
    });

    test('OFF data never enters the pack', () {
      final data = makeDataDir();
      final r = build(data, drafts: true);
      final db = openPack(r.out);
      expect(
        db.select(
          "SELECT 1 FROM foods WHERE source NOT IN ('usda', 'reference') "
          "OR source_ref LIKE '%openfoodfacts%'",
        ),
        isEmpty,
      );
      expect(db.select("SELECT 1 FROM foods WHERE id LIKE 'off:%'"), isEmpty);
    });

    test('attribution reaches meta and is schema checked', () {
      final data = makeDataDir();
      File(p.join(data.path, 'attribution.yaml')).writeAsStringSync(
        'sources:\n  - {id: usda_fdc, name: USDA, licence: CC0, '
        'url: "https://fdc.nal.usda.gov/", credit: c, used_for: u, '
        'status: active}\n',
      );
      final r = build(data);
      final db = openPack(r.out);
      final attribution = jsonDecode(
        db
                .select("SELECT value FROM meta WHERE key = 'attribution'")
                .single['value']
            as String,
      ) as List;
      expect((attribution.single as Map)['id'], 'usda_fdc');
      File(p.join(data.path, 'attribution.yaml'))
          .writeAsStringSync('sources:\n  - {id: x}\n');
      expect(build(data).result.exitCode, 1);
    });
  });

  group('AT-003 coverage (D17)', () {
    test('a reviewed item that stops resolving is a regression', () {
      const item = MustCoverItem(
        id: 'musakhan',
        group: 'main',
        names: {
          'en': ['Musakhan'],
        },
        match: ['ref:musakhan'],
      );
      const ok = CoverRow(
        item: item,
        status: CoverStatus.reviewed,
        byLang: {'en': true, 'ar': true, 'arabizi': true},
        target: 'ref:musakhan',
      );
      const lost = CoverRow(
        item: item,
        status: CoverStatus.reviewed,
        byLang: {'en': true, 'ar': false, 'arabizi': true},
        target: 'ref:musakhan',
      );
      const draft = CoverRow(
        item: item,
        status: CoverStatus.draft,
        byLang: {'en': false, 'ar': false, 'arabizi': false},
        target: null,
      );
      expect(coverageRegressions([ok, draft]), isEmpty);
      expect(coverageRegressions([lost]).single, contains('ar'));
    });

    test('check reports the table and passes on the fixture data', () async {
      final data = makeDataDir();
      build(data);
      final out = Directory.systemTemp.createTempSync('check_out');
      addTearDown(() => out.deleteSync(recursive: true));
      final log = StringBuffer();
      final err = StringBuffer();
      final code = await runCatalog(
        [
          'check',
          '--data-dir',
          data.path,
          '--contract-dir',
          contractDir,
          '--out-dir',
          out.path,
          '--base',
          'HEAD',
        ],
        out: log,
        err: err,
      );
      expect(code, 0, reason: '$err');
      expect(log.toString(), contains('| main | musakhan | yes | yes | yes |'));
      expect(log.toString(), contains('Must-cover:'));
    });
  });
}
