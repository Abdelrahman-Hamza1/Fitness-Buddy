import 'package:fb_mobile/core/settings/setting_key.dart';
import 'package:flutter_test/flutter_test.dart';

enum _Units { metric, imperial }

void main() {
  group('SettingKey', () {
    test('typed codecs round trip through JSON text', () {
      final flag = SettingKey.boolean('a.flag', defaultValue: false);
      final count = SettingKey.integer('a.count', defaultValue: 0);
      final ratio = SettingKey.decimal('a.ratio', defaultValue: 0);
      final text = SettingKey.string('a.text', defaultValue: '');
      final units = SettingKey.enumeration(
        'units.system',
        _Units.values,
        defaultValue: _Units.metric,
      );

      expect(flag.codec.encode(true), 'true');
      expect(flag.valueOf('true'), isTrue);
      expect(count.codec.encode(42), '42');
      expect(count.valueOf('42'), 42);
      expect(ratio.codec.encode(1.5), '1.5');
      expect(ratio.valueOf('1.5'), 1.5);
      expect(ratio.valueOf('2'), 2.0, reason: 'a whole number reads back');
      expect(text.codec.encode('a "b"'), r'"a \"b\""');
      expect(text.valueOf(r'"a \"b\""'), 'a "b"');
      expect(units.codec.encode(_Units.imperial), '"imperial"');
      expect(units.valueOf('"imperial"'), _Units.imperial);
    });

    test('no value, unreadable JSON or a value of another type reads as the '
        'default', () {
      final count = SettingKey.integer('a.count', defaultValue: 7);
      final units = SettingKey.enumeration(
        'units.system',
        _Units.values,
        defaultValue: _Units.metric,
      );
      final flag = SettingKey.boolean('a.flag', defaultValue: true);
      final ratio = SettingKey.decimal('a.ratio', defaultValue: 0.5);
      final text = SettingKey.string('a.text', defaultValue: 'x');

      expect(count.valueOf(null), 7);
      expect(count.valueOf('not json'), 7);
      expect(count.valueOf('1.5'), 7);
      expect(count.valueOf('"1"'), 7);
      expect(units.valueOf('"stone"'), _Units.metric, reason: 'newer value');
      expect(flag.valueOf('1'), isTrue);
      expect(ratio.valueOf('"1"'), 0.5);
      expect(text.valueOf('1'), 'x');
    });

    test('a custom codec', () {
      final pair = SettingKey<(int, int)>(
        'a.pair',
        codec: SettingCodec(
          toJson: (v) => [v.$1, v.$2],
          fromJson: (json) => json is List && json.length == 2
              ? (json[0] as int, json[1] as int)
              : throw const FormatException('not a pair'),
        ),
        defaultValue: (0, 0),
      );
      expect(pair.codec.encode((1, 2)), '[1,2]');
      expect(pair.valueOf('[1,2]'), (1, 2));
      expect(pair.valueOf('{}'), (0, 0));
    });

    test('names are dot-separated camelCase, as fb_domain enforces', () {
      for (final name in ['', 'Units', 'units.', 'units_system', '2fa']) {
        expect(
          () => SettingKey.boolean(name, defaultValue: false),
          throwsArgumentError,
          reason: name,
        );
      }
      expect(
        SettingKey.boolean('diary.showFiber', defaultValue: false).name,
        'diary.showFiber',
      );
    });
  });
}
