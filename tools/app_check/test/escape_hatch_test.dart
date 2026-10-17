import 'package:fb_app_check/fb_app_check.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  const screen = 'lib/features/today/presentation/s.dart';

  group('// app-check: allow <rule-id> <reason>', () {
    test('silences only the named lexical rule, on its line only', () {
      const source = '''
final a = Text('Debug'); // app-check: allow raw-string developer-only banner
final b = Alignment.centerLeft; // app-check:allow directional chart axis stays LTR
final c = Text('Next line still counts');
final d = Text('x', textAlign: TextAlign.left); // app-check: allow raw-string debug
''';
      expect(found(check(screen, source)), {
        '3 raw-string',
        // The allow names raw-string, so the directional problem still counts.
        '4 directional',
      });
    });

    test('an allow on an import line never silences a boundary rule', () {
      const source = '''
import 'package:go_router/go_router.dart'; // app-check: allow raw-string S99 spike
import 'package:fb_mobile/app/app.dart'; // app-check: allow directional spike
import 'package:fb_mobile/features/me/presentation/x.dart'; // app-check: allow raw-string x
import 'package:dio/dio.dart'; // app-check: allow directional x
''';
      expect(found(check(screen, source)), {
        '1 go-router',
        '2 feature-app',
        '3 feature-barrel',
        '4 io-package',
      });
    });

    test('naming a boundary rule is itself an error and silences nothing', () {
      for (final rule in Rule.values) {
        if (allowableRules.contains(rule) || rule == Rule.invalidAllow) {
          continue;
        }
        final source =
            "import 'package:go_router/go_router.dart'; "
            '// app-check: allow ${rule.id} S99 spike\n';
        expect(found(check(screen, source)), {
          '1 go-router',
          '1 invalid-allow',
        }, reason: rule.id);
      }
    });

    test('without a rule id, with an unknown rule id or without a reason it '
        'fails, and silences nothing', () {
      const source = '''
final a = Text('Debug'); // app-check: allow
final b = 1; //app-check: allow   
final c = Text('Debug'); // app-check: allow developer-only banner
final d = Text('Debug'); // app-check: allow raw-string
''';
      expect(found(check(screen, source)), {
        '1 raw-string',
        '1 invalid-allow',
        '2 invalid-allow',
        '3 raw-string',
        '3 invalid-allow',
        '4 raw-string',
        '4 invalid-allow',
      });
    });

    test('allowCount counts the valid allows only', () {
      const source = '''
final a = Text('Debug'); // app-check: allow raw-string developer-only banner
final b = Alignment.centerLeft; // app-check: allow directional chart axis
final c = 1; // app-check: allow go-router nope
final d = 1; // app-check: allow
''';
      expect(allowCount(path: screen, source: source), 2);
      expect(allowCount(path: 'lib/app/x.g.dart', source: source), 0);
    });

    test('messages say what to write', () {
      final messages = {
        for (final v in check(
          screen,
          "import 'package:go_router/go_router.dart'; "
          '// app-check: allow go-router spike\n'
          'final a = 1; // app-check: allow\n',
        ))
          if (v.rule == Rule.invalidAllow) v.line: v.message,
      };
      expect(
        messages[1],
        contains('boundary and write-path rules have no exceptions'),
      );
      expect(messages[2], contains('// app-check: allow <rule-id> <reason>'));
    });
  });
}
