import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('rule 8 raw-string', () {
    test('fires on every marked line of the bad fixture, nothing else', () {
      final source = fixture('raw_strings_bad.txt');
      final violations = check(
        'lib/features/today/presentation/bad_screen.dart',
        source,
      );
      expect(found(violations), expectedMarks(source));
      expect(expectedMarks(source), hasLength(23));
    });

    test('l10n calls, interpolation-only strings, nested calls and allowed '
        'lines pass', () {
      expect(
        check(
          'lib/features/today/presentation/ok_screen.dart',
          fixture('raw_strings_ok.txt'),
        ),
        isEmpty,
      );
    });

    test('applies to presentation/, app/ and main.dart', () {
      const source = "final w = Text('Hello');\n";
      for (final path in [
        'lib/features/me/presentation/widgets/card.dart',
        'lib/app/shell/app_shell.dart',
        'lib/app/app.dart',
        'lib/main.dart',
      ]) {
        expect(found(check(path, source)), {'1 raw-string'}, reason: path);
      }
    });

    test('does not apply to core/, data/, application/', () {
      const source = '''
final error = StateError('Not initialised');
final model = Item(title: 'Stored title', label: 'x');
''';
      for (final path in [
        'lib/core/errors/failure.dart',
        'lib/features/today/data/today_repo.dart',
        'lib/features/today/application/today_controller.dart',
      ]) {
        expect(check(path, source), isEmpty, reason: path);
      }
    });

    test('the message quotes the literal and the argument', () {
      final violation = check(
        'lib/main.dart',
        "final a = Tooltip(message: 'Tip');\n",
      ).single;
      expect(
        violation.message,
        "raw string 'Tip' in message:; user-facing text comes from the ARB "
        'file (lib/l10n/app_en.arb, context.l10n.<key>)',
      );
    });
  });
}
