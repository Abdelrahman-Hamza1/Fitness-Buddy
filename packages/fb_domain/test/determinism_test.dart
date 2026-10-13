import 'dart:io';

import 'package:test/test.dart';

/// The one file allowed to read the clock, the device zone and randomness.
const _systemFile = 'lib/system.dart';

/// What domain code must not call (S08 D8, A7). Domain time arithmetic uses
/// `DateTime.utc(...)` and UTC `DateTime`s only. The patterns run over the
/// whole comment-free file, so `\s*` also spans line breaks.
final _banned = <String, RegExp>{
  'DateTime.now': RegExp(r'\bDateTime\s*\.\s*now\b'),
  'DateTime.timestamp': RegExp(r'\bDateTime\s*\.\s*timestamp\b'),
  'local-zone DateTime( constructor': RegExp(r'\bDateTime\s*\('),
  'DateTime.parse (local unless the text has a zone)': RegExp(
    r'\bDateTime\s*\.\s*(?:try)?[pP]arse\b',
  ),
  '.toLocal': RegExp(r'\.\s*toLocal\b'),
  '.timeZoneOffset': RegExp(r'\.\s*timeZoneOffset\b'),
  '.timeZoneName': RegExp(r'\.\s*timeZoneName\b'),
  'Random( / Random.secure(': RegExp(r'\bRandom\s*(?:\.\s*secure\s*)?\('),
  'Random.new / DateTime.new': RegExp(r'\b(?:Random|DateTime)\s*\.\s*new\b'),
  // A dot shorthand (`DateTime at = .now();`). Not a bare `.now(`:
  // `HybridLogicalClock.now()` is fine.
  'shorthand .now( / .timestamp( / .secure(': RegExp(
    r'(?:[=(,:?]|=>|\breturn)\s*\.\s*(?:now|timestamp|secure)\s*\(',
  ),
};

/// `fromMilli/MicrosecondsSinceEpoch` makes a local `DateTime` unless the
/// call passes `isUtc: true`.
final _fromEpoch = RegExp(r'\bfrom(?:Milli|Micro)secondsSinceEpoch\s*\(');
final _isUtcTrue = RegExp(r'\bisUtc\s*:\s*true\b');

/// [source] with its comments (`//`, `///`, nested `/* */`) blanked to
/// spaces, newlines kept so offsets and line numbers stay right. String
/// literals (also raw and triple-quoted) are skipped, so a `//` in a string
/// is not a comment. Quotes inside `${}` interpolations are not tracked.
String stripComments(String source) {
  final out = StringBuffer();
  var i = 0;
  void blank(int end) {
    for (; i < end; i++) {
      out.write(source[i] == '\n' ? '\n' : ' ');
    }
  }

  void keep(int end) {
    out.write(source.substring(i, end));
    i = end;
  }

  while (i < source.length) {
    final rest = source.substring(i);
    if (rest.startsWith('//')) {
      final newline = source.indexOf('\n', i);
      blank(newline < 0 ? source.length : newline);
    } else if (rest.startsWith('/*')) {
      var depth = 0;
      var j = i;
      do {
        if (source.startsWith('/*', j)) {
          depth++;
          j += 2;
        } else if (source.startsWith('*/', j)) {
          depth--;
          j += 2;
        } else {
          j++;
        }
      } while (depth > 0 && j < source.length);
      blank(j);
    } else if (RegExp('^r?(?:\'\'\'|"""|\'|")').firstMatch(rest)
        case final open?) {
      final raw = open[0]!.startsWith('r');
      final quote = open[0]!.substring(raw ? 1 : 0);
      var j = i + open[0]!.length;
      while (j < source.length && !source.startsWith(quote, j)) {
        if (!raw && source[j] == r'\') j++;
        if (quote.length == 1 && source[j] == '\n') break;
        j++;
      }
      keep(j + quote.length > source.length ? source.length : j + quote.length);
    } else {
      keep(i + 1);
    }
  }
  return out.toString();
}

/// The banned uses in [source], as `line: what` strings.
List<String> violations(String source) {
  final code = stripComments(source);
  int lineOf(int offset) =>
      '\n'.allMatches(code.substring(0, offset)).length + 1;
  final found = <(int, String)>[
    for (final MapEntry(key: what, value: pattern) in _banned.entries)
      for (final match in pattern.allMatches(code)) (lineOf(match.start), what),
    for (final match in _fromEpoch.allMatches(code))
      if (!_isUtcTrue.hasMatch(_arguments(code, match.end - 1)))
        (lineOf(match.start), 'fromMillisecondsSinceEpoch without isUtc: true'),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final (line, what) in found) '$line: $what'];
}

/// The text of the call arguments in [code] from the `(` at [open] to its
/// matching `)` (or the end).
String _arguments(String code, int open) {
  var depth = 0;
  for (var i = open; i < code.length; i++) {
    if (code[i] == '(') depth++;
    if (code[i] == ')' && --depth == 0) return code.substring(open, i + 1);
  }
  return code.substring(open);
}

/// A `fromMillisecondsSinceEpoch` call with `isUtc: true` on its own line.
const _multiLineUtc =
    'final d = DateTime.fromMillisecondsSinceEpoch(\n'
    '  ms,\n  isUtc: true,\n);';

void main() {
  group('determinism:', () {
    test('DateTime.now / Random only in system.dart (D8, A7)', () {
      final found = <String>[
        for (final file in Directory('lib').listSync(recursive: true))
          if (file is File &&
              file.path.endsWith('.dart') &&
              file.uri.path != File(_systemFile).uri.path)
            for (final hit in violations(file.readAsStringSync()))
              '${file.path}:$hit',
      ];
      expect(found, isEmpty, reason: 'move these into $_systemFile');
    });

    test('system.dart exists and the barrel does not export it', () {
      expect(File(_systemFile).existsSync(), isTrue);
      final barrel = File('lib/fb_domain.dart').readAsStringSync();
      final exportsSystem = RegExp(
        r'''^\s*export\s+['"][^'"]*system\.dart['"]''',
        multiLine: true,
      );
      expect(exportsSystem.hasMatch(barrel), isFalse);
      expect(exportsSystem.hasMatch("export 'system.dart';"), isTrue);
    });

    test('the ban list catches every banned use and allows UTC', () {
      const banned = [
        'final now = DateTime.now();',
        'final now = DateTime.timestamp();',
        'final d = DateTime(2026, 10, 13);',
        'final d = DateTime.parse(text);',
        'final d = DateTime.tryParse(text);',
        'final local = utc.toLocal();',
        'final offset = now.timeZoneOffset;',
        'final zone = now.timeZoneName;',
        'final random = Random(42);',
        'final random = math.Random.secure();',
        'final d = DateTime.fromMillisecondsSinceEpoch(ms);',
        'final d = DateTime.fromMicrosecondsSinceEpoch(us, isUtc: false);',
        'final r = Random.new(1);',
        'final make = DateTime.new;',
        'final r = math.Random . new;',
        'DateTime at = .now();',
        'f(at: .now());',
        'f(a, .timestamp());',
        'DateTime g() => .now();',
        'return .timestamp();',
        'final r = c ? .secure() : null;',
        'Random r = .secure();',
        'final now = DateTime\n    .now();',
        'final r = Random\n  (1);',
        'final d = DateTime.fromMillisecondsSinceEpoch(\n  ms,\n);',
        "final url = 'https://x'; final n = DateTime.now();",
        'final s = "a // b"; final r = Random(1);',
        r"final s = r'\'; final r = Random(1);",
        "final s = '''\n// x\n'''; final r = Random(1);",
      ];
      for (final line in banned) {
        expect(violations(line), hasLength(1), reason: line);
      }
      const allowed = [
        'final d = DateTime.utc(2026, 10, 13);',
        'DateTime nowUtc();',
        'final DateTime? at;',
        'final Random _random;',
        'final d = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);',
        '/// Never call `DateTime.now()` here.',
        'final x = 1; // not Random(1)',
        '/* DateTime.now() */ final y = 2;',
        '/* a /* nested */ DateTime.now() */ final y = 2;',
        'final t = HybridLogicalClock.now();',
        'final t = clock.now();',
        _multiLineUtc,
        r"final s = 'it\'s'; final u = 1; // DateTime.now()",
      ];
      for (final line in allowed) {
        expect(violations(line), isEmpty, reason: line);
      }
      expect(violations('ok;\n/*\nRandom(1)\n*/\nDateTime.now();'), [
        '5: DateTime.now',
      ]);
      expect(violations('ok;\nfinal now = DateTime\n    .now();'), [
        '2: DateTime.now',
      ]);
      expect(stripComments("a; // b\nc = 'd // e';"), "a;     \nc = 'd // e';");
    });
  });
}
