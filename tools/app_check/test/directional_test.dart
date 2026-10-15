import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('rule 9 directional', () {
    test('fires on every marked line of the bad fixture, nothing else', () {
      final source = fixture('directional_bad.txt');
      final violations = check(
        'lib/features/today/presentation/bad_layout.dart',
        source,
      );
      expect(found(violations), expectedMarks(source));
      expect(expectedMarks(source), hasLength(12));
    });

    test('start/end APIs, comments, strings and allowed lines pass', () {
      expect(
        check(
          'lib/features/today/presentation/ok_layout.dart',
          fixture('directional_ok.txt'),
        ),
        isEmpty,
      );
    });

    test('applies to all of lib/, not only presentation', () {
      const source = 'const a = Alignment.topRight;\n';
      expect(found(check('lib/core/x.dart', source)), {'1 directional'});
      expect(found(check('lib/features/today/application/x.dart', source)), {
        '1 directional',
      });
    });

    test('messages name the start/end replacement', () {
      String message(String code) =>
          check('lib/main.dart', code).single.message;

      expect(
        message('f(left: 1);'),
        startsWith(
          '`left:` is a physical side; '
          'use `start:`',
        ),
      );
      expect(
        message('f(bottomRight: r);'),
        startsWith('`bottomRight:` is a physical corner; use `bottomEnd:`'),
      );
      expect(
        message('final a = Alignment.centerLeft;'),
        '`Alignment.centerLeft` is physical; use '
        '`AlignmentDirectional.centerStart`',
      );
      expect(
        message('final a = TextAlign.right;'),
        '`TextAlign.right` is physical; use `TextAlign.end`',
      );
    });
  });
}
