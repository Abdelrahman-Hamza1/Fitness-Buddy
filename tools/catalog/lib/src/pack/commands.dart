import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:fb_catalog/src/pack/coverage.dart';
import 'package:fb_catalog/src/pack/pack_query.dart';
import 'package:fb_catalog/src/pack/pack_sql.dart';
import 'package:fb_catalog/src/release/build_release.dart';
import 'package:fb_catalog/src/release/git_base.dart';
import 'package:fb_catalog/src/release/id_lock.dart';
import 'package:fb_catalog/src/release/release.dart';
import 'package:path/path.dart' as p;

const _defaultPack = 'build/catalog/catalog.db';

/// Options shared by `build` and `check`.
void _addReleaseOptions(ArgParser a) {
  a
    ..addOption(
      'data-dir',
      help: 'The catalog source data.',
      defaultsTo: 'data',
    )
    ..addOption(
      'contract-dir',
      help: 'The load file JSON Schemas.',
      defaultsTo: 'contracts/catalog',
    )
    ..addOption(
      'out-dir',
      help: 'Where the pack and the load files go (gitignored).',
      defaultsTo: 'build/catalog',
    )
    ..addOption(
      'max-bytes',
      help: 'Pack size budget; the build fails at this size.',
      defaultsTo: '$maxPackBytes',
    );
}

BuildOptions _buildOptions(
  ArgResults args, {
  required bool update,
  required IdLock? baseLock,
  String? assetsDir,
  bool includeDrafts = false,
  String? devPackDir,
}) => BuildOptions(
  data: DataPaths(args.option('data-dir')!),
  contractDir: args.option('contract-dir')!,
  outDir: args.option('out-dir')!,
  update: update,
  baseLock: baseLock,
  assetsDir: assetsDir,
  includeDrafts: includeDrafts,
  devPackDir: devPackDir,
  gitCommit: currentCommit(),
  maxBytes: int.parse(args.option('max-bytes')!),
);

/// `catalog build`: the release build (A05 D2, D3, D5, D6, D12). Writes
/// `catalog.db`, the load files and the manifest. Only `--update` (make
/// catalog) changes the lock and the version; without it a stale lock fails.
class BuildCommand extends Command<int> {
  new(this._out, this._err) {
    _addReleaseOptions(argParser);
    argParser
      ..addOption(
        'assets-dir',
        help: 'Also copy catalog.db and its manifest here (the app assets).',
      )
      ..addFlag(
        'update',
        help: 'Append new IDs to data/catalog_ids.lock and bump the version.',
        negatable: false,
      )
      ..addFlag(
        'include-drafts',
        help:
            'Also pack draft dishes (dev builds only; the lock ignores them).',
        negatable: false,
      )
      ..addFlag(
        'coverage',
        help: 'Print the must-cover table after the build.',
        negatable: false,
      );
  }

  final StringSink _out;
  final StringSink _err;

  @override
  String get name => 'build';

  @override
  String get description =>
      'Build the release pack and load files (drafts excluded unless asked).';

  @override
  Future<int> run() async {
    final args = argResults!;
    final drafts = args.flag('include-drafts');
    final result = runBuild(
      _buildOptions(
        args,
        update: args.flag('update'),
        baseLock: null,
        assetsDir: args.option('assets-dir'),
        includeDrafts: drafts,
        // The table also tells which items exist as drafts.
        devPackDir: args.flag('coverage') && !drafts
            ? p.join(args.option('out-dir')!, 'dev')
            : null,
      ),
      out: _out,
      err: _err,
    );
    if (result.exitCode == 0 && args.flag('coverage')) {
      _out.writeln();
      final list = DataPaths(args.option('data-dir')!).mustCover;
      final items = parseMustCover(list.readAsStringSync(), source: list.path);
      final dev = p.join(args.option('out-dir')!, 'dev', 'catalog.db');
      final search = PackSearch.open(
        !drafts && File(dev).existsSync() ? dev : result.packPath!,
      );
      try {
        _out.write(formatCoverage(measureCoverage(search, items)));
      } finally {
        search.close();
      }
    }
    return result.exitCode;
  }
}

/// `catalog check`: everything CI verifies, writing nothing under `data/`
/// (A05 D2, D11, D17): validation, the lock against the merge base, stale
/// lock/version, contract schemas, size budget, and the AT-003 coverage.
class CheckCommand extends Command<int> {
  new(this._out, this._err) {
    _addReleaseOptions(argParser);
    argParser.addOption(
      'base',
      help:
          'Git ref to compare the ID lock with (default: CATALOG_BASE_REF, '
          'else the merge-base with origin/main).',
    );
  }

  final StringSink _out;
  final StringSink _err;

  @override
  String get name => 'check';

  @override
  String get description =>
      'Verify validation, ID stability, freshness, size and coverage.';

  @override
  Future<int> run() async {
    final args = argResults!;
    final d = DataPaths(args.option('data-dir')!);
    final lockPath = d.lock.path;
    IdLock? base;
    final ref = resolveBaseRef(flag: args.option('base'));
    if (ref == null) {
      _out.writeln(
        'catalog: NOTICE: no merge base (no git history or origin/main): '
        'the ID lock is not compared with an earlier version.',
      );
    } else {
      base = readLockAt(ref, lockPath);
      _out.writeln(
        base == null
            ? 'catalog: no ID lock at $ref yet: nothing to compare with'
            : 'catalog: ID lock compared with the one at $ref',
      );
    }
    final outDir = args.option('out-dir')!;
    final result = runBuild(
      _buildOptions(
        args,
        update: false,
        baseLock: base,
        devPackDir: p.join(outDir, 'dev'),
      ),
      out: _out,
      err: _err,
    );
    if (result.exitCode != 0) return result.exitCode;

    final items = parseMustCover(
      d.mustCover.readAsStringSync(),
      source: d.mustCover.path,
    );
    final release = PackSearch.open(result.packPath!);
    final dev = PackSearch.open(p.join(outDir, 'dev', 'catalog.db'));
    try {
      final rows = measureCoverage(release, items);
      final regressions = coverageRegressions(rows);
      _out
        ..writeln()
        ..write(formatCoverage(measureCoverage(dev, items)));
      for (final r in regressions) {
        _err.writeln('error: $r');
      }
      if (regressions.isNotEmpty) {
        _err.writeln('catalog: a reviewed must-cover item stopped resolving');
        return 1;
      }
    } finally {
      release.close();
      dev.close();
    }
    return 0;
  }
}

/// `catalog query <text>`: ranked hits from the pack.
class QueryCommand extends Command<int> {
  new(this._out, this._err) {
    argParser
      ..addOption('pack', defaultsTo: _defaultPack)
      ..addOption('limit', defaultsTo: '10');
  }

  final StringSink _out;
  final StringSink _err;

  @override
  String get name => 'query';

  @override
  String get description => 'Search the pack: catalog query <text>.';

  @override
  String get invocation => 'catalog query [options] <text>';

  @override
  Future<int> run() async {
    final args = argResults!;
    if (args.rest.isEmpty) usageException('missing the text to search for');
    final pack = args.option('pack')!;
    if (!File(pack).existsSync()) {
      _err.writeln('catalog: error: no pack at $pack (run `catalog build`)');
      return 1;
    }
    final search = PackSearch.open(pack);
    try {
      final hits = search.search(
        args.rest.join(' '),
        limit: int.tryParse(args.option('limit')!) ?? 10,
      );
      if (hits.isEmpty) _out.writeln('no hits');
      for (var i = 0; i < hits.length; i++) {
        final h = hits[i];
        _out.writeln(
          '${i + 1}. ${h.target}  ${h.name}  '
          '[${h.reviewStatus ?? 'basic'}]  '
          '${h.kcalPer100 == null ? '' : '${h.kcalPer100} kcal/100 g  '}'
          '(${h.matchedTokens} tokens)',
        );
      }
      return 0;
    } finally {
      search.close();
    }
  }
}

/// `catalog coverage`: the must-cover list against the pack.
class CoverageCommand extends Command<int> {
  new(this._out, this._err) {
    argParser
      ..addOption('pack', defaultsTo: _defaultPack)
      ..addOption('must-cover', defaultsTo: 'data/must_cover.yaml');
  }

  final StringSink _out;
  final StringSink _err;

  @override
  String get name => 'coverage';

  @override
  String get description =>
      'Report how each must-cover item resolves (EN / AR / Arabizi).';

  @override
  Future<int> run() async {
    final args = argResults!;
    final pack = args.option('pack')!;
    final list = File(args.option('must-cover')!);
    if (!File(pack).existsSync() || !list.existsSync()) {
      _err.writeln('catalog: error: need the pack ($pack) and ${list.path}');
      return 1;
    }
    final items = parseMustCover(list.readAsStringSync(), source: list.path);
    final search = PackSearch.open(pack);
    try {
      _out
        ..writeln(
          'pack: ${search.count('dishes')} dishes, '
          '${search.count('foods')} foods, '
          'includes_drafts=${search.meta['includes_drafts']}',
        )
        ..writeln()
        ..write(formatCoverage(measureCoverage(search, items)));
      return 0;
    } finally {
      search.close();
    }
  }
}

/// The items in the app's catalog fixture: two rice basics and a reference
/// dish with variants, servings and ranges (A05 D7).
const fixtureIds = {
  'usda:rice_white_long_grain_cooked',
  'usda:rice_white_long_grain_raw',
  'ref:mloukhiyeh_rice',
};

/// Real GeoNames examples for A10: regional cities, duplicate names, a
/// zero-population village and an outside-region city. IDs never synthesized.
const fixtureCityIds = {
  'city:282615', // Nablus
  'city:282239', // Ramallah
  'city:285066', // Hebron
  'city:7303419', // East Jerusalem
  'city:281577', // Tulkarm
  'city:250441', // Amman (عمّان)
  'city:250624', // Karak
  'city:6946409', // Karak
  'city:246330', // Umm ar Rasas (population zero)
  'city:360630', // Cairo
};

/// The fixture script for the current `data/` (drafts included, so a dish is
/// in it).
String? buildFixtureSql(String dataDir, StringSink err) {
  final loaded = loadAndValidate(DataPaths(dataDir), err);
  if (loaded == null) return null;
  final release = composeRelease(
    data: loaded.data,
    report: loaded.report,
    versionOf: (_) => 1,
    attribution: const [],
    includeDrafts: true,
  );
  return packFixtureSql(release, fixtureIds, cityIds: fixtureCityIds);
}

/// `catalog emit-sql`: writes the app's catalog fixture (A05 D7). With
/// `--check` it writes nothing and fails when the file is out of date.
class EmitSqlCommand extends Command<int> {
  new(this._out, this._err) {
    argParser
      ..addOption('data-dir', defaultsTo: 'data')
      ..addOption(
        'out',
        defaultsTo: 'apps/mobile/test/fixtures/catalog_fixture.sql',
      )
      ..addFlag(
        'check',
        help: 'Only compare, write nothing.',
        negatable: false,
      );
  }

  final StringSink _out;
  final StringSink _err;

  @override
  String get name => 'emit-sql';

  @override
  String get description => 'Write (or check) the app catalog fixture SQL.';

  @override
  Future<int> run() async {
    final args = argResults!;
    final sql = buildFixtureSql(args.option('data-dir')!, _err);
    if (sql == null) return 1;
    final file = File(args.option('out')!);
    if (args.flag('check')) {
      if (file.existsSync() && file.readAsStringSync() == sql) return 0;
      _err.writeln(
        'error: ${file.path} is stale: run `dart run '
        'tools/catalog/bin/catalog.dart emit-sql` and commit it',
      );
      return 1;
    }
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(sql);
    _out.writeln('catalog: wrote ${file.path} (${sql.length} bytes)');
    return 0;
  }
}
