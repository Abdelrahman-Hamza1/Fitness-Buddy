import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:fb_domain/fb_domain.dart';

/// Converts a setting's value to and from its JSON form (A01 D16): the one
/// place a setting's type meets JSON.
final class SettingCodec<T> {
  /// A codec that writes a value with `toJson` and reads it back with
  /// `fromJson`, which throws a [FormatException] for a value it can't
  /// read.
  const new({required this._toJson, required this._fromJson});

  final Object? Function(T value) _toJson;
  final T Function(Object? json) _fromJson;

  /// `true` / `false`.
  static const SettingCodec<bool> boolean = SettingCodec(
    toJson: _same,
    fromJson: _bool,
  );

  /// A whole number.
  static const SettingCodec<int> integer = SettingCodec(
    toJson: _same,
    fromJson: _int,
  );

  /// A number (stored as JSON, so `1` and `1.0` read back as `1.0`).
  static const SettingCodec<double> decimal = SettingCodec(
    toJson: _same,
    fromJson: _double,
  );

  /// A string.
  static const SettingCodec<String> string = SettingCodec(
    toJson: _same,
    fromJson: _string,
  );

  /// A JSON string or null; malformed values fall back through SettingKey.
  static const SettingCodec<String?> optionalString = SettingCodec(
    toJson: _same,
    fromJson: _optionalString,
  );

  /// One of [values], stored by its `name` (so renaming a value is a
  /// migration, reordering isn't).
  static SettingCodec<E> enumeration<E extends Enum>(List<E> values) {
    final byName = {for (final v in values) v.name: v};
    return SettingCodec(
      toJson: (value) => value.name,
      fromJson: (json) =>
          byName[json] ?? (throw const FormatException('unknown enum value')),
    );
  }

  /// [value] as JSON text.
  String encode(T value) => jsonEncode(_toJson(value));

  /// The value of [valueJson]. Throws a [FormatException] if it isn't JSON
  /// or not a value of this codec.
  T decode(String valueJson) => _fromJson(jsonDecode(valueJson));
}

String? _optionalString(Object? json) => json == null ? null : _string(json);

Object? _same(Object? value) => value;

bool _bool(Object? json) =>
    json is bool ? json : throw const FormatException('not a bool');

int _int(Object? json) =>
    json is int ? json : throw const FormatException('not an int');

double _double(Object? json) =>
    json is num ? json.toDouble() : throw const FormatException('not a number');

String _string(Object? json) =>
    json is String ? json : throw const FormatException('not a string');

/// A typed setting (A01 D16): its key, how its value is stored, and the
/// value it has until it's set (and again after a reset).
///
/// Declare each key once, next to the feature that owns it:
/// `final unitSystem = SettingKey.enumeration('units.system',
/// UnitSystem.values, defaultValue: UnitSystem.metric);`. The [name] is part
/// of the row's natural ID (`setting:<name>`, D6), so it never changes.
final class SettingKey<T> {
  /// The setting [name] (dot-separated camelCase, like `units.system`),
  /// stored with [codec], [defaultValue] until set. Throws an
  /// `ArgumentError` for an invalid [name].
  new(this.name, {required this.codec, required this.defaultValue}) {
    if (!SettingsOp.isKey(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'must be dot-separated camelCase segments, like units.system',
      );
    }
  }

  /// A `bool` setting.
  static SettingKey<bool> boolean(String name, {required bool defaultValue}) =>
      SettingKey(name, codec: SettingCodec.boolean, defaultValue: defaultValue);

  /// An `int` setting.
  static SettingKey<int> integer(String name, {required int defaultValue}) =>
      SettingKey(name, codec: SettingCodec.integer, defaultValue: defaultValue);

  /// A `double` setting.
  static SettingKey<double> decimal(
    String name, {
    required double defaultValue,
  }) =>
      SettingKey(name, codec: SettingCodec.decimal, defaultValue: defaultValue);

  /// A `String` setting.
  static SettingKey<String> string(
    String name, {
    required String defaultValue,
  }) =>
      SettingKey(name, codec: SettingCodec.string, defaultValue: defaultValue);

  /// An optional string; reset restores the unset value.
  static SettingKey<String?> optionalString(String name) =>
      SettingKey(name, codec: SettingCodec.optionalString, defaultValue: null);

  /// A setting holding one of [values].
  static SettingKey<E> enumeration<E extends Enum>(
    String name,
    List<E> values, {
    required E defaultValue,
  }) => SettingKey(
    name,
    codec: SettingCodec.enumeration(values),
    defaultValue: defaultValue,
  );

  /// The key, like `units.system`.
  final String name;

  /// How the value is stored.
  final SettingCodec<T> codec;

  /// The value until the setting is set, and after a reset.
  final T defaultValue;

  /// The value stored as [valueJson], or [defaultValue] if there is none or
  /// it can't be read (a value written by a newer app version, say).
  T valueOf(String? valueJson) {
    if (valueJson == null) return defaultValue;
    try {
      return codec.decode(valueJson);
    } on FormatException {
      return defaultValue;
    }
  }

  @override
  String toString() => 'SettingKey($name)';
}
