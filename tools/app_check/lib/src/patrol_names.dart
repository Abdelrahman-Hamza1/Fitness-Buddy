import 'package:fb_app_check/src/rules.dart';
import 'package:fb_app_check/src/source_scanner.dart';

/// Checks the names of the `patrolTest(` calls in [source] (a file of the
/// app's `patrol_test/` folder): the name must be ASCII and contain no `;` or
/// `/`, because the Patrol/Gradle test runner mangles them (backlog #87).
///
/// The name is the first argument: one string literal or several adjacent
/// ones. Only the literal parts are looked at (an interpolated value is not
/// known statically), and a `\u`/`\x` escape counts as non-ASCII, since it can
/// spell any character. Whitespace and comments between the parts are skipped.
/// A name that isn't a literal is not checked.
List<Violation> checkPatrolNames({
  required String path,
  required String source,
}) {
  final scanned = ScannedSource.scan(source);
  final violations = <Violation>[];
  for (final call in RegExp(r'\bpatrolTest\s*\(').allMatches(scanned.code)) {
    var at = call.end;
    while (true) {
      // Comments are blank in `code`, so whitespace and comments are skipped
      // alike; a literal's own span is never walked (it is blank there too).
      while (at < source.length &&
          !scanned.literals.containsKey(at) &&
          _isSpace(scanned.code.codeUnitAt(at))) {
        at++;
      }
      final literal = scanned.literals[at];
      if (literal == null) break;
      final problem = _problem(
        literal.staticText,
        source.substring(literal.start, literal.end),
      );
      if (problem != null) {
        violations.add(
          Violation(
            path: path,
            line: scanned.lineOf(literal.start),
            rule: Rule.patrolName,
            message:
                'patrolTest name has $problem; use ASCII letters, digits and '
                'spaces only, no `;` or `/` (backlog #87)',
          ),
        );
      }
      at = literal.end;
    }
  }
  return violations;
}

bool _isSpace(int unit) =>
    unit == 0x20 || unit == 0x09 || unit == 0x0A || unit == 0x0D;

String? _problem(String text, String raw) {
  if (text.runes.any((r) => r > 0x7F) || raw.contains(RegExp(r'\\[ux]'))) {
    return 'a non-ASCII character';
  }
  if (text.contains(';')) return 'a `;`';
  if (text.contains('/')) return 'a `/`';
  return null;
}
