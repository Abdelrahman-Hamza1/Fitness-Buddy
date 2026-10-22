import 'dart:convert';
import 'dart:io';

import 'package:fb_catalog/src/load/load_catalog.dart';
import 'package:fb_catalog/src/pack/pack_builder.dart';
import 'package:fb_catalog/src/release/id_lock.dart';
import 'package:fb_catalog/src/release/load_files.dart';
import 'package:fb_catalog/src/release/release.dart';
import 'package:fb_catalog/src/release/release_files.dart';
import 'package:fb_catalog/src/validate/report.dart';
import 'package:fb_catalog/src/validate/validate.dart';
import 'package:path/path.dart' as p;

/// Hard size limit of the pack (A05 D12); warn from [warnPackBytes].
const maxPackBytes = 10000000;
const warnPackBytes = 8000000;

const staleMessage =
    'the catalog is stale: run `make catalog` and commit '
    'data/catalog_ids.lock and data/catalog_release.yaml';

/// Where the catalog's source files live under `data/`.
class DataPaths {
  const new(this.root);

  final String root;

  String get schemaDir => p.join(root, 'schema');
  File get selection => File(p.join(root, 'usda_selection.yaml'));
  File get extract => File(p.join(root, 'usda', 'extract.jsonl'));
  Directory get dishes => Directory(p.join(root, 'reference_dishes'));
  File get yields => File(p.join(root, 'yields.yaml'));
  File get portionWords => File(p.join(root, 'portion_words.yaml'));
  File get exercises => File(p.join(root, 'exercises.yaml'));
  File get cities => File(p.join(root, 'cities.tsv'));
  File get attribution => File(p.join(root, 'attribution.yaml'));
  File get mustCover => File(p.join(root, 'must_cover.yaml'));
  File get lock => File(p.join(root, 'catalog_ids.lock'));
  File get releaseState => File(p.join(root, 'catalog_release.yaml'));
}

/// What to build and where to put it.
class BuildOptions {
  const new({
    required this.data,
    required this.contractDir,
    required this.outDir,
    this.assetsDir,
    this.update = false,
    this.includeDrafts = false,
    this.devPackDir,
    this.baseLock,
    this.gitCommit,
    this.maxBytes = maxPackBytes,
    this.warnBytes = warnPackBytes,
  });

  final DataPaths data;

  /// `contracts/catalog/`: the JSON Schemas of the load files.
  final String contractDir;
  final String outDir;

  /// When set, `catalog.db` and its manifest are copied there (the app's
  /// asset folder).
  final String? assetsDir;

  /// Append new IDs to the lock and bump the version (`make catalog`). Off by
  /// default: a stale lock then fails the build.
  final bool update;

  /// Pack the draft dishes too (dev builds); never for a release.
  final bool includeDrafts;

  /// Also write a pack with drafts to `<dir>/catalog.db` (for the coverage
  /// report).
  final String? devPackDir;

  /// The lock at the merge base, for the stability check.
  final IdLock? baseLock;
  final String? gitCommit;
  final int maxBytes;
  final int warnBytes;
}

/// What a build produced.
class BuildResult {
  const new({
    required this.exitCode,
    this.release,
    this.packPath,
    this.packBytes = 0,
    this.version = 0,
  });

  final int exitCode;
  final Release? release;
  final String? packPath;
  final int packBytes;
  final int version;
}

/// Loads `data/`, validates it, and returns the pieces; problems are written
/// to [err]. `null` when the data is not valid.
({CatalogData data, ValidationReport report, List<Object?> attribution})?
loadAndValidate(DataPaths d, StringSink err) {
  final data = loadCatalog(
    schemaDir: d.schemaDir,
    selection: d.selection,
    extract: d.extract,
    dishesDir: d.dishes,
    yields: d.yields,
    portionWords: d.portionWords,
    exercises: d.exercises,
    cities: d.cities,
  );
  final attribution = loadAttribution(d.attribution, d.schemaDir, data.issues);
  final report = validateCatalog(
    basics: data.basics,
    dishes: data.dishes,
    requireAr: true,
    yields: data.yields,
    portionWords: data.portionWords,
    exercises: data.exercises,
  );
  final errors = [...data.issues, ...report.errors];
  if (errors.isEmpty) {
    return (data: data, report: report, attribution: attribution);
  }
  for (final e in errors) {
    err.writeln('error: $e');
  }
  err.writeln('catalog: validate failed with ${errors.length} error(s)');
  return null;
}

/// The release build (A05 WP1): validate, check the ID lock and the version,
/// write the load files, the manifest and `catalog.db`, enforce the size
/// budget, print the counts. Without [BuildOptions.update] it writes nothing
/// under `data/` and fails when the lock or the version is stale.
BuildResult runBuild(
  BuildOptions o, {
  required StringSink out,
  required StringSink err,
}) {
  const failed = BuildResult(exitCode: 1);
  final loaded = loadAndValidate(o.data, err);
  if (loaded == null) return failed;
  final (:data, :report, :attribution) = loaded;

  final IdLock lock;
  final ReleaseState state;
  try {
    lock = o.data.lock.existsSync()
        ? IdLock.parse(o.data.lock.readAsStringSync(), source: o.data.lock.path)
        : const IdLock.empty();
    state = ReleaseState.read(o.data.releaseState);
  } on FormatException catch (e) {
    err.writeln('catalog: error: ${e.message}');
    return failed;
  }
  final next = state.version + 1;

  Release compose({required bool drafts, required int Function(String) v}) =>
      composeRelease(
        data: data,
        report: report,
        versionOf: v,
        attribution: attribution,
        includeDrafts: drafts,
      );

  // The reviewed set decides the lock, the version and the hash.
  final released = compose(
    drafts: false,
    v: (id) => lock.entries[id]?.firstVersion ?? next,
  );
  final problems = <String>[
    for (final id in released.released.keys)
      if (!isValidCatalogId(id))
        'ID `$id` is not a valid catalog ID (see A05 D1)',
  ];
  final cmp = compareWithData(lock, released.released);
  problems.addAll(cmp.errors);
  final hash = contentHash(released);
  final stale = cmp.missing.isNotEmpty || hash != state.contentSha256;
  final finalLock = cmp.missing.isEmpty
      ? lock
      : lock.plus([
          for (final id in cmp.missing)
            LockEntry(id: id, kind: released.released[id]!, firstVersion: next),
        ]);
  final version = stale ? next : state.version;
  if (o.baseLock != null) {
    problems.addAll(compareWithBase(o.baseLock!, finalLock));
  }
  if (problems.isNotEmpty) {
    for (final m in problems) {
      err.writeln('error: $m');
    }
    err.writeln('catalog: ID stability check failed');
    return failed;
  }
  if (stale && !o.update) {
    err.writeln(
      'error: $staleMessage (${cmp.missing.length} new ID(s), content '
      '${hash == state.contentSha256 ? 'unchanged' : 'changed'})',
    );
    return failed;
  }
  if (stale) {
    o.data.lock.writeAsStringSync(finalLock.format());
    o.data.releaseState.writeAsStringSync(ReleaseState(version, hash).format());
    out.writeln(
      'catalog: version $version (was ${state.version}): '
      '${cmp.missing.length} new ID(s) locked',
    );
  }

  final shipped = o.includeDrafts
      ? compose(
          drafts: true,
          v: (id) => finalLock.entries[id]?.firstVersion ?? version,
        )
      : released;
  final contract = [...validateLoadFiles(shipped, o.contractDir)];
  if (contract.isNotEmpty) {
    for (final m in contract) {
      err.writeln('error: $m');
    }
    err.writeln('catalog: the load files do not match contracts/catalog');
    return failed;
  }

  final releaseDir = Directory(p.join(o.outDir, 'release'));
  final packPath = p.join(o.outDir, 'catalog.db');
  final shippedHash = contentHash(shipped);
  final files = writeLoadFiles(shipped, releaseDir);
  writePack(shipped, packPath, meta: _packMeta(shipped, version, shippedHash));
  final packBytes = File(packPath).lengthSync();
  final manifest = <String, Object?>{
    'catalog_version': version,
    'schema_version': schemaVersion,
    'content_sha256': shippedHash,
    'git_commit': o.gitCommit,
    'includes_drafts': shipped.includesDrafts,
    'files': {
      for (final f in files)
        '${f.name}.jsonl': {
          'sha256': f.sha256,
          'count': f.count,
          'bytes': f.bytes,
        },
    },
    'pack': {
      'file': 'catalog.db',
      'sha256': sha256Hex(File(packPath).readAsBytesSync()),
      'bytes': packBytes,
    },
    'counts': _counts(shipped),
  };
  final manifestProblems = validateManifest(manifest, o.contractDir);
  if (manifestProblems.isNotEmpty) {
    manifestProblems.forEach(err.writeln);
    return failed;
  }
  final manifestText =
      '${const JsonEncoder.withIndent('  ').convert(manifest)}\n';
  File(p.join(releaseDir.path, 'manifest.json'))
      .writeAsStringSync(manifestText);

  if (o.devPackDir != null && !o.includeDrafts) {
    final dev = compose(
      drafts: true,
      v: (id) => finalLock.entries[id]?.firstVersion ?? version,
    );
    writePack(
      dev,
      p.join(o.devPackDir!, 'catalog.db'),
      meta: _packMeta(dev, version, contentHash(dev)),
    );
  }

  _printSummary(out, shipped, version, packBytes, o);
  if (packBytes >= o.maxBytes) {
    err.writeln(
      'error: catalog.db is $packBytes bytes, the budget is under '
      '${o.maxBytes}',
    );
    return failed;
  }
  if (packBytes >= o.warnBytes) {
    out.writeln('warning: catalog.db is above ${o.warnBytes} bytes');
  }
  if (o.assetsDir != null) {
    _copyToAssets(o.assetsDir!, packPath, manifestText);
    out.writeln('catalog: copied the pack to ${o.assetsDir}');
  }
  return BuildResult(
    exitCode: 0,
    release: shipped,
    packPath: packPath,
    packBytes: packBytes,
    version: version,
  );
}

Map<String, String> _packMeta(Release r, int version, String hash) => {
  'schema_version': '$schemaVersion',
  'catalog_version': '$version',
  'content_sha256': hash,
  'includes_drafts': r.includesDrafts ? '1' : '0',
  'attribution': jsonEncode(r.attribution),
};

Map<String, int> _counts(Release r) => {
  'basics': r.countFoods('basic'),
  'dishes': r.count('dishes'),
  'variants': r.countFoods('variant'),
  'exercises': r.count('exercises'),
  'cities': r.count('cities'),
  'names': r.count('names'),
  'servings': r.count('servings'),
  'yields': r.count('yields'),
};

void _copyToAssets(String dir, String pack, String manifestText) {
  Directory(dir).createSync(recursive: true);
  // Temp name then rename, so a reader never sees half a file.
  final tmp = File(p.join(dir, 'catalog.db.tmp'));
  File(pack).copySync(tmp.path);
  tmp.renameSync(p.join(dir, 'catalog.db'));
  File(p.join(dir, 'catalog_manifest.json')).writeAsStringSync(manifestText);
}

void _printSummary(
  StringSink out,
  Release r,
  int version,
  int packBytes,
  BuildOptions o,
) {
  final c = _counts(r);
  out
    ..writeln(
      'catalog v$version${r.includesDrafts ? ' (with drafts)' : ''}: '
      '${c['basics']} basics, ${c['dishes']} dishes '
      '(${c['variants']} variants), ${c['exercises']} exercises, '
      '${c['cities']} cities',
    )
    ..writeln(
      '  ${c['names']} names, ${c['servings']} servings, '
      '${c['yields']} yield rows; catalog.db $packBytes bytes '
      '(budget under ${o.maxBytes})',
    );
  final levels = <String, int>{};
  final buckets = {
    '< 5': 0,
    '5 to 10': 0,
    '10 to 25': 0,
    '25 to 50': 0,
    '50 or more': 0,
  };
  for (final s in r.sanity.entries) {
    levels[s.value.level] = (levels[s.value.level] ?? 0) + 1;
    final d = s.value.deviation;
    final key = d < 5
        ? '< 5'
        : d < 10
        ? '5 to 10'
        : d < 25
        ? '10 to 25'
        : d < 50
        ? '25 to 50'
        : '50 or more';
    buckets[key] = buckets[key]! + 1;
  }
  out
    ..writeln(
      '  sanity: ${levels['ok'] ?? 0} ok, ${levels['warn'] ?? 0} warn, '
      '${levels['waived'] ?? 0} waived by override',
    )
    ..writeln(
      '  kcal deviation from macros: '
      '${buckets.entries.map((e) => '${e.key}: ${e.value}').join(', ')}',
    );
}
