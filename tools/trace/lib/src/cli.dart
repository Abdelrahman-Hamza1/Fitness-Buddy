import 'dart:io';

import 'package:args/args.dart';
import 'package:fb_trace/src/report.dart';
import 'package:fb_trace/src/requirement.dart';
import 'package:fb_trace/src/spec_parser.dart';
import 'package:fb_trace/src/test_scanner.dart';
import 'package:path/path.dart' as p;

/// Exit code: the report was written (whatever the coverage).
const int exitOk = 0;

/// Exit code: the spec is invalid (duplicate IDs), no report.
const int exitSpecErrors = 2;

/// Exit code: bad command line (EX_USAGE).
const int exitUsage = 64;

/// The `--release` value that selects every release plus the untagged IDs.
const String allReleases = 'all';

final ArgParser _parser = ArgParser()
  ..addOption(
    'root',
    defaultsTo: '.',
    help: 'Repository root (contains spec/).',
  )
  ..addOption(
    'release',
    defaultsTo: Release.r1.label,
    allowed: [for (final r in Release.tagged) r.label, allReleases],
    help:
        'Release to report on; "$allReleases" adds every release and the '
        'untagged IDs.',
  )
  ..addOption(
    'out',
    valueHelp: 'file',
    help: 'Write the Markdown report to this file instead of stdout.',
  )
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

/// Runs the trace command line with [arguments] and returns the exit code.
///
/// The Markdown report goes to [out] (or the `--out` file). The one-line
/// summary per release, errors and the usage text go to [err].
int runTrace(
  List<String> arguments, {
  required StringSink out,
  required StringSink err,
}) {
  final ArgResults args;
  try {
    args = _parser.parse(arguments);
  } on FormatException catch (e) {
    return _usageError(err, e.message);
  }
  if (args.flag('help')) {
    out
      ..writeln(_usageTitle)
      ..writeln(_parser.usage);
    return exitOk;
  }
  if (args.rest.isNotEmpty) {
    return _usageError(err, 'Unexpected argument: ${args.rest.first}');
  }

  final root = args.option('root')!;
  if (!Directory(p.join(root, 'spec')).existsSync()) {
    return _usageError(err, 'No spec/ folder under --root "$root".');
  }

  final spec = readSpec(root);
  if (spec.errors.isNotEmpty) {
    for (final error in spec.errors) {
      err.writeln('trace: error: $error');
    }
    return exitSpecErrors;
  }

  final release = args.option('release')!;
  final report = TraceReport(
    spec: spec,
    coverage: const TestScanner().scan(root),
    releases: release == allReleases
        ? Release.tagged
        : [Release.fromTag(release)!],
    includeUntagged: release == allReleases,
  );

  final markdown = report.toMarkdown();
  final outPath = args.option('out');
  if (outPath == null) {
    out.write(markdown);
  } else {
    File(outPath).writeAsStringSync(markdown);
  }

  for (final summary in report.summaries) {
    err.writeln('trace: $summary');
  }
  final warnings = report.warnings.length;
  if (warnings > 0) {
    err.writeln('trace: $warnings warning(s), listed in the report');
  }
  return exitOk;
}

const String _usageTitle =
    'Usage: trace [--root <dir>] [--release R1|R2|R3|Later|all] '
    '[--out <file>]\n'
    'Requirement traceability report: spec IDs vs tests (AT-001).\n';

int _usageError(StringSink err, String message) {
  err
    ..writeln('trace: error: $message')
    ..writeln()
    ..writeln(_usageTitle)
    ..writeln(_parser.usage);
  return exitUsage;
}
