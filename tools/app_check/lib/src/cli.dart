import 'dart:io';

import 'package:fb_app_check/src/checker.dart';
import 'package:fb_app_check/src/rules.dart';

/// Exit code: no violations.
const int exitOk = 0;

/// Exit code: at least one violation.
const int exitViolations = 1;

/// Exit code: bad command line or app folder (EX_USAGE).
const int exitUsage = 64;

/// The app folder checked when none is given (run from the repo root).
const String defaultAppDir = 'apps/mobile';

const String _usage =
    '''
Usage: app_check [<app-dir>]

Checks the Flutter app's lib/ folder: import boundaries, the single-writer
write path, raw user-facing strings, left/right layout. <app-dir> holds pubspec.yaml and lib/
(default: $defaultAppDir). Rules: tools/app_check/README.md.

Exit codes: 0 no violations, 1 violations (one per line on stderr,
"path:line: rule: message"), 64 bad command line.''';

final RegExp _pubspecName = RegExp(r'^name:\s*([A-Za-z_]\w*)', multiLine: true);

/// Runs app_check with [arguments] and returns the exit code.
///
/// The OK line goes to [out]; violations, the summary and errors to [err].
int runAppCheck(
  List<String> arguments, {
  required StringSink out,
  required StringSink err,
}) {
  if (arguments.contains('--help') || arguments.contains('-h')) {
    out.writeln(_usage);
    return exitOk;
  }
  if (arguments.length > 1 || arguments.any((a) => a.startsWith('-'))) {
    err
      ..writeln(
        'app-check: error: unexpected arguments: ${arguments.join(' ')}',
      )
      ..writeln(_usage);
    return exitUsage;
  }

  var appDir = arguments.isEmpty ? defaultAppDir : arguments.single;
  appDir = appDir.replaceAll(r'\', '/');
  while (appDir.length > 1 && appDir.endsWith('/')) {
    appDir = appDir.substring(0, appDir.length - 1);
  }
  final pubspec = File('$appDir/pubspec.yaml');
  final lib = Directory('$appDir/lib');
  if (!pubspec.existsSync() || !lib.existsSync()) {
    err.writeln(
      'app-check: error: "$appDir" is not an app folder '
      '(needs pubspec.yaml and lib/)',
    );
    return exitUsage;
  }
  final packageName = _pubspecName
      .firstMatch(pubspec.readAsStringSync())
      ?.group(1);
  if (packageName == null) {
    err.writeln('app-check: error: no `name:` in $appDir/pubspec.yaml');
    return exitUsage;
  }

  final files =
      lib
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .map((f) => f.path.replaceAll(r'\', '/'))
          .where((path) => path.endsWith('.dart'))
          .toList()
        ..sort();
  final shown = appDir == '.' ? '' : '$appDir/';
  final violations = <Violation>[];
  var allows = 0;
  for (final file in files) {
    final relative = file.substring(file.indexOf('/lib/', appDir.length) + 1);
    final source = File(file).readAsStringSync();
    violations.addAll(
      checkFile(
        path: relative,
        source: source,
        packageName: packageName,
      ).map((v) => v.withPath('$shown$relative')),
    );
    allows += allowCount(path: relative, source: source);
  }

  if (violations.isEmpty) {
    out.writeln(
      'app-check: OK, ${files.length} Dart files under ${shown}lib '
      '(generated files skipped), $allows allow comment(s)',
    );
    return exitOk;
  }
  violations.forEach(err.writeln);
  final fileCount = violations.map((v) => v.path).toSet().length;
  err.writeln(
    'app-check: ${violations.length} problem(s) in $fileCount file(s). '
    'Rules and fixes: tools/app_check/README.md. A deliberate raw-string '
    'or directional exception takes `// app-check: allow <rule-id> <reason>` '
    'on the line.',
  );
  return exitViolations;
}
