import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fb_catalog/src/load/load_catalog.dart';
import 'package:fb_catalog/src/pack/coverage.dart';
import 'package:fb_catalog/src/pack/pack_builder.dart';
import 'package:fb_catalog/src/pack/pack_query.dart';
import 'package:fb_catalog/src/validate/validate.dart';

const _defaultPack = 'build/catalog/catalog.db';

/// `catalog build`: validated data -> prototype `catalog.db` (A03 D8, D9).
class BuildCommand extends Command<int> {
  new(this._out, this._err) {
    argParser
      ..addOption('selection', defaultsTo: 'data/usda_selection.yaml')
      ..addOption('extract', defaultsTo: 'data/usda/extract.jsonl')
      ..addOption('dishes', defaultsTo: 'data/reference_dishes')
      ..addOption('schema-dir', defaultsTo: 'data/schema')
      ..addOption(
        'out',
        help: 'The pack to write (outside data/, gitignored).',
        defaultsTo: _defaultPack,
      )
      ..addFlag(
        'include-drafts',
        help: 'Also pack draft dishes (dev builds and reports only).',
        negatable: false,
      );
  }

  final StringSink _out;
  final StringSink _err;

  @override
  String get name => 'build';

  @override
  String get description =>
      'Write the prototype catalog.db (drafts excluded unless asked).';

  @override
  Future<int> run() async {
    final args = argResults!;
    final data = loadCatalog(
      schemaDir: args.option('schema-dir')!,
      selection: File(args.option('selection')!),
      extract: File(args.option('extract')!),
      dishesDir: Directory(args.option('dishes')!),
    );
    final report = validateCatalog(basics: data.basics, dishes: data.dishes);
    try {
      final s = buildPack(
        data: data,
        report: report,
        out: args.option('out')!,
        includeDrafts: args.flag('include-drafts'),
      );
      _out.writeln(
        'catalog: wrote ${args.option('out')}: ${s.basics} basics, '
        '${s.dishes} dishes (${s.variants} variants), ${s.names} names, '
        '${s.skippedDrafts} draft dish(es) left out, ${s.bytes} bytes',
      );
      return 0;
    } on PackException catch (e) {
      for (final i in [...data.issues, ...report.errors]) {
        _err.writeln('error: $i');
      }
      _err.writeln('catalog: error: $e');
      return 1;
    }
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
          'pack: ${search.meta['dishes']} dishes, ${search.meta['basics']} '
          'basics, includes_drafts=${search.meta['includes_drafts']}',
        )
        ..writeln()
        ..write(formatCoverage(measureCoverage(search, items)));
      return 0;
    } finally {
      search.close();
    }
  }
}
