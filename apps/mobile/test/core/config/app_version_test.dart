import 'package:fb_mobile/core/config/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppVersion compares numerically (0.1.10 > 0.1.9); malformed input '
      'never gates', () {
    test('parses MAJOR.MINOR.PATCH', () {
      expect(AppVersion.tryParse('0.1.0'), const AppVersion(0, 1, 0));
      expect(AppVersion.tryParse('12.0.345'), const AppVersion(12, 0, 345));
      expect(AppVersion.tryParse('0.0.0'), AppVersion.zero);
      expect(const AppVersion(1, 2, 3).toString(), '1.2.3');
    });

    test('compares part by part, as numbers', () {
      AppVersion v(String text) => AppVersion.tryParse(text)!;
      expect(v('0.1.10') > v('0.1.9'), isTrue);
      expect(v('0.10.0') > v('0.9.99'), isTrue);
      expect(v('2.0.0') > v('1.99.99'), isTrue);
      expect(v('1.2.3') < v('1.2.4'), isTrue);
      expect(v('1.2.3').compareTo(v('1.2.3')), 0);
      expect(v('1.2.3'), v('1.2.3'));
      expect(v('1.2.3').hashCode, v('1.2.3').hashCode);
      expect([v('1.0.0'), v('0.1.10'), v('0.1.9')]..sort(), [
        v('0.1.9'),
        v('0.1.10'),
        v('1.0.0'),
      ]);
    });

    test('rejects anything but three digit-only parts', () {
      for (final text in [
        '',
        '1',
        '1.2',
        '1.2.3.4',
        '1.2.3-beta',
        '1.2.3+4',
        'v1.2.3',
        ' 1.2.3',
        '1.2.3 ',
        '-1.2.3',
        '1..3',
        '1.2.x',
        '1.2.1234567890',
      ]) {
        expect(AppVersion.tryParse(text), isNull, reason: '"$text"');
      }
    });

    test('isBelowMinimum gates only an older installed version', () {
      bool below(String installed, String minimum) =>
          AppVersion.isBelowMinimum(installed: installed, minimum: minimum);
      expect(below('0.1.9', '0.1.10'), isTrue);
      expect(below('0.1.0', '1.0.0'), isTrue);
      expect(below('0.1.10', '0.1.10'), isFalse, reason: 'equal');
      expect(below('0.2.0', '0.1.10'), isFalse, reason: 'newer');
      expect(below('0.1.0', '0.0.0'), isFalse, reason: 'the default');
    });

    test('a malformed version on either side never gates (fail open, A8)', () {
      for (final (installed, minimum) in [
        ('0.1.0', '9.9'),
        ('0.1.0', 'latest'),
        ('0.1.0', ''),
        ('0.1.0-dev', '9.9.9'),
        ('0.1.0.1', '9.9.9'),
        ('', '9.9.9'),
      ]) {
        expect(
          AppVersion.isBelowMinimum(installed: installed, minimum: minimum),
          isFalse,
          reason: '$installed vs $minimum',
        );
      }
    });
  });
}
