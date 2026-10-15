import 'package:fb_app_check/fb_app_check.dart';
import 'package:test/test.dart';

void main() {
  group('ScannedSource', () {
    test('static text drops interpolations and replaces escapes', () {
      final s = ScannedSource.scan(
        r'''f('a $b ${c.d('x}')} e\n\u{1F600}\$', "q", r'$raw\n');''',
      );
      final texts = [for (final l in s.literals.values) l.staticText];
      expect(texts, ['a   e   ', 'q', r'$raw\n']);
    });

    test('code masks comments and literals, keeping offsets and lines', () {
      const source = '''
a('x'); // c
/* b /* nested */ still */ b
c("""
multi
""");''';
      final s = ScannedSource.scan(source);
      expect(s.code.length, source.length);
      expect(s.code.split('\n'), [
        'a(   );     ',
        '                           b',
        'c(   ',
        '     ',
        '   );',
      ]);
      expect(s.literals.keys, [2, 44]);
      expect(s.lineOf(44), 3);
      expect(s.lineOf(source.length - 1), 5);
      expect(s.lineText(2), '/* b /* nested */ still */ b');
      expect(s.lineCount, 5);
    });

    test('an r at the end of an identifier is not a raw-string prefix', () {
      final s = ScannedSource.scan("bar('x'); r'y';");
      expect(s.literals.keys, [4, 10]);
      expect(s.literals[10]!.staticText, 'y');
    });

    test('an unterminated single-line literal stops at the line end', () {
      final s = ScannedSource.scan("a('open\nb('x');");
      expect(s.literals.values.map((l) => l.staticText), ['open', 'x']);
    });
  });
}
