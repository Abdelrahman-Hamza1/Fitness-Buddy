import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

void main() {
  group('SettingsOp:', () {
    test('SettingsOp equality and family', () {
      final put = SettingsOp.put('units.system', '"metric"');
      final reset = SettingsOp.reset('units.system');
      expect(put.family, 'settings');
      expect(reset.family, SettingsOp.familyName);
      expect(put, isA<ChangeOp>());

      expect(put, SettingsOp.put('units.system', '"metric"'));
      expect(put.hashCode, SettingsOp.put('units.system', '"metric"').hashCode);
      expect(put, isNot(SettingsOp.put('units.system', '"imperial"')));
      expect(put, isNot(SettingsOp.put('units.energy', '"metric"')));
      expect(reset, SettingsOp.reset('units.system'));
      expect(reset.hashCode, SettingsOp.reset('units.system').hashCode);
      expect(reset, isNot(SettingsOp.reset('units.energy')));
      expect(put, isNot(reset));
      expect(reset, isNot(put));
    });

    test('SettingsOp is exhaustive over put, reset and expect', () {
      String describe(SettingsOp op) => switch (op) {
        SettingsPut(:final key, :final valueJson) => 'put $key=$valueJson',
        SettingsReset(:final key) => 'reset $key',
        SettingsExpect(:final key, :final valueJson) =>
          'expect $key=$valueJson',
      };
      expect(describe(SettingsOp.put('a.b', '1')), 'put a.b=1');
      expect(describe(SettingsOp.reset('a.b')), 'reset a.b');
      expect(describe(SettingsOp.expect('a.b', '1')), 'expect a.b=1');
      expect(SettingsOp.expect('a.b', '1'), SettingsOp.expect('a.b', '1'));
      expect('${SettingsOp.expect('a.b', '"x"')}', isNot(contains('x"')));
    });

    test('toString names the key, never the value', () {
      expect(
        '${SettingsOp.put('profile.goal', '"secret"')}',
        'SettingsOp.put(profile.goal)',
      );
      expect(
        '${SettingsOp.reset('profile.goal')}',
        'SettingsOp.reset(profile.goal)',
      );
    });

    test('keys are dot-separated camelCase segments', () {
      for (final key in [
        'units',
        'units.system',
        'diary.mealSlots2',
        'a.b.c',
      ]) {
        expect(SettingsOp.reset(key).key, key);
        expect(SettingsOp.isKey(key), isTrue, reason: key);
      }
      for (final key in [
        '',
        'Units',
        'units.',
        '.units',
        'units..system',
        'units system',
        'units_system',
        'units-system',
        '2fa',
        'units.System',
      ]) {
        expect(SettingsOp.isKey(key), isFalse, reason: key);
        expect(() => SettingsOp.reset(key), throwsArgumentError, reason: key);
        expect(
          () => SettingsOp.put(key, '1'),
          throwsArgumentError,
          reason: key,
        );
      }
    });

    test('put values must be JSON text', () {
      for (final json in [
        '1',
        '"metric"',
        'true',
        'null',
        '[1,2]',
        '{"a":1}',
      ]) {
        expect(SettingsOp.put('a', json), isA<SettingsPut>());
      }
      for (final json in ['', 'metric', "'metric'", '{a:1}', '[1,']) {
        expect(
          () => SettingsOp.put('a', json),
          throwsArgumentError,
          reason: json,
        );
      }
      // The error doesn't quote the value (user content).
      expect(
        () => SettingsOp.put('a', 'secret-value'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => '$e',
            'text',
            isNot(contains('secret-value')),
          ),
        ),
      );
    });
  });

  group('SettingsChanged:', () {
    test('SettingsChanged carries the keys as a set', () {
      final event = SettingsChanged(['a', 'b', 'a']);
      expect(event, isA<DomainEvent>());
      expect(event.keys, {'a', 'b'});
      expect(() => event.keys.add('c'), throwsUnsupportedError);
      expect(event, SettingsChanged(['b', 'a']));
      expect(event.hashCode, SettingsChanged(['b', 'a']).hashCode);
      expect(event, isNot(SettingsChanged(['a'])));
      expect(event, isNot(SettingsChanged(['a', 'c'])));
      expect('$event', 'SettingsChanged({a, b})');
    });
  });
}
