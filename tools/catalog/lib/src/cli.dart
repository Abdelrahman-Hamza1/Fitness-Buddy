import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fb_catalog/src/load/load_catalog.dart';
import 'package:fb_catalog/src/pack/commands.dart';
import 'package:fb_catalog/src/pack/coverage.dart';
import 'package:fb_catalog/src/usda/importer.dart';
import 'package:fb_catalog/src/usda/selection.dart';
import 'package:fb_catalog/src/validate/validate.dart';
import 'package:path/path.dart' as p;

/// Runs the `catalog` tool and returns the exit code: 0 ok, 64 bad usage,
/// 1 the data is wrong (the message names the file, entry or FDC id).
Future<int> runCatalog(
  List<String> arguments, {
  required StringSink out,
  required StringSink err,
}) async {
  final runner =
      CommandRunner<int>('catalog', 'Fitness Buddy food catalog tooling.')
        ..addCommand(ImportUsdaCommand(out))
        ..addCommand(ValidateCommand(out, err))
        ..addCommand(BuildCommand(out, err))
        ..addCommand(QueryCommand(out, err))
        ..addCommand(CoverageCommand(out, err));
  try {
    return await runner.run(arguments) ?? 0;
  } on UsageException catch (e) {
    err.writeln(e.message);
    return 64;
  } on SelectionException catch (e) {
    err.writeln('catalog: error: $e');
    return 1;
  } on ImportException catch (e) {
    err.writeln('catalog: error: $e');
    return 1;
  } on MustCoverException catch (e) {
    err.writeln('catalog: error: $e');
    return 1;
  } on FormatException catch (e) {
    err.writeln('catalog: error: ${e.message}');
    return 1;
  }
}

/// `catalog import-usda`: selection + unpacked FDC CSVs -> `extract.jsonl`.
class ImportUsdaCommand extends Command<int> {
  new(this._out) {
    argParser
      ..addOption(
        'selection',
        help: 'The selection file.',
        defaultsTo: 'data/usda_selection.yaml',
      )
      ..addOption(
        'usda-dir',
        help:
            'Directory with the unpacked datasets (sr_legacy/ and '
            'foundation/), as written by tools/scripts/fetch-usda.sh.',
        mandatory: true,
      )
      ..addOption(
        'out',
        help: 'The extract to write.',
        defaultsTo: 'data/usda/extract.jsonl',
      );
  }

  final StringSink _out;

  @override
  String get name => 'import-usda';

  @override
  String get description =>
      'Write the sorted USDA extract for the selected basics.';

  @override
  Future<int> run() async {
    final args = argResults!;
    final selection = loadSelection(File(args.option('selection')!));
    final root = args.option('usda-dir')!;
    final dirs = <String, Directory>{};
    for (final name in const ['sr_legacy', 'foundation']) {
      final dir = Directory(p.join(root, name));
      if (!dir.existsSync()) {
        throw ImportException('missing dataset directory ${dir.path}');
      }
      dirs[name] = dir;
    }
    final foods = await importUsda(datasetDirs: dirs, selection: selection);
    final text = encodeExtract(foods);
    final outFile = File(args.option('out')!);
    outFile.parent.createSync(recursive: true);
    outFile.writeAsStringSync(text);
    _out.writeln(
      'catalog: wrote ${foods.length} foods to ${outFile.path} '
      '(${text.length} bytes)',
    );
    return 0;
  }
}

/// `catalog validate`: schema, semantic and sanity checks of the selection,
/// the extract and the reference dishes. Prints each variant's per-100 g.
class ValidateCommand extends Command<int> {
  new(this._out, this._err) {
    argParser
      ..addOption(
        'selection',
        help: 'The basics selection.',
        defaultsTo: 'data/usda_selection.yaml',
      )
      ..addOption(
        'extract',
        help: 'The USDA extract.',
        defaultsTo: 'data/usda/extract.jsonl',
      )
      ..addOption(
        'dishes',
        help: 'Folder with the reference dish YAML files.',
        defaultsTo: 'data/reference_dishes',
      )
      ..addOption(
        'schema-dir',
        help: 'Folder with the JSON Schemas.',
        defaultsTo: 'data/schema',
      )
      ..addFlag(
        'require-ar',
        help: 'Every basic needs an Arabic name (A05 turns this on).',
        negatable: false,
      );
  }

  final StringSink _out;
  final StringSink _err;

  @override
  String get name => 'validate';

  @override
  String get description =>
      'Validate the dish format, references, names and sanity.';

  @override
  Future<int> run() async {
    final args = argResults!;
    final data = loadCatalog(
      schemaDir: args.option('schema-dir')!,
      selection: File(args.option('selection')!),
      extract: File(args.option('extract')!),
      dishesDir: Directory(args.option('dishes')!),
    );
    final report = validateCatalog(
      basics: data.basics,
      dishes: data.dishes,
      requireAr: args.flag('require-ar'),
    );
    for (final id in report.computed.keys.toList()..sort()) {
      final t = report.computed[id]!.typical;
      _out.writeln(
        '$id  ${t.kcal} kcal  P ${t.protein}  C ${t.carbs}  F ${t.fat}  '
        'fiber ${t.fiber}  per 100 g',
      );
    }
    for (final w in report.warnings) {
      _out.writeln('warning: $w');
    }
    for (final o in report.overrides) {
      _out.writeln('note: $o');
    }
    final errors = [...data.issues, ...report.errors];
    for (final e in errors) {
      _err.writeln('error: $e');
    }
    if (errors.isNotEmpty) {
      _err.writeln('catalog: validate failed with ${errors.length} error(s)');
      return 1;
    }
    _out.writeln(
      'catalog: ${data.basics.length} basics and ${data.dishes.length} '
      'dishes valid (${report.warnings.length} warnings)',
    );
    return 0;
  }
}
