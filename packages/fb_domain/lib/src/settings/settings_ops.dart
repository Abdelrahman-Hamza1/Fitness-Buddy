import 'dart:convert' show jsonDecode;

import 'package:fb_domain/src/changes/change_op.dart';
import 'package:fb_domain/src/changes/domain_event.dart';

/// The op family of the settings store (A01 D16): one row per setting key.
sealed class SettingsOp implements ChangeOp {
  /// Set [key] to [valueJson], a JSON text.
  factory put(String key, String valueJson) = SettingsPut._;

  /// Set [key] back to its default (the row is tombstoned).
  factory reset(String key) = SettingsReset._;

  /// Writes nothing: refuses the change set unless [key] is stored as
  /// [valueJson] (A38: an automatic check-in rechecks its setting inside the
  /// transaction).
  factory expect(String key, String valueJson) = SettingsExpect._;

  new _(this.key) {
    if (!isKey(key)) {
      throw ArgumentError.value(
        key,
        'key',
        'must be dot-separated camelCase segments, like units.system',
      );
    }
  }

  /// Settings keys are part of the row's natural ID (`setting:<key>`), so
  /// they must stay stable and plain.
  static final _key = RegExp(r'^[a-z][a-zA-Z0-9]*(?:\.[a-z][a-zA-Z0-9]*)*$');

  /// Whether [key] is a valid settings key: dot-separated camelCase
  /// segments, like `units.system`.
  static bool isKey(String key) => _key.hasMatch(key);

  /// The [family] of every settings op.
  static const String familyName = 'settings';

  /// The setting, like `units.system`.
  final String key;

  @override
  String get family => familyName;
}

/// See [SettingsOp.put].
final class SettingsPut extends SettingsOp {
  new _(super.key, this.valueJson) : super._() {
    try {
      jsonDecode(valueJson);
    } on FormatException {
      // Without the value: it's user content.
      throw ArgumentError('valueJson is not JSON');
    }
  }

  /// The new value as JSON text.
  final String valueJson;

  @override
  bool operator ==(Object other) =>
      other is SettingsPut && other.key == key && other.valueJson == valueJson;

  @override
  int get hashCode => Object.hash(SettingsPut, key, valueJson);

  @override
  String toString() => 'SettingsOp.put($key)';
}

/// See [SettingsOp.reset].
final class SettingsReset extends SettingsOp {
  new _(super.key) : super._();

  @override
  bool operator ==(Object other) => other is SettingsReset && other.key == key;

  @override
  int get hashCode => Object.hash(SettingsReset, key);

  @override
  String toString() => 'SettingsOp.reset($key)';
}

/// See [SettingsOp.expect].
final class SettingsExpect extends SettingsOp {
  new _(super.key, this.valueJson) : super._();

  /// The value the stored row must hold, as JSON text.
  final String valueJson;

  @override
  bool operator ==(Object other) =>
      other is SettingsExpect &&
      other.key == key &&
      other.valueJson == valueJson;

  @override
  int get hashCode => Object.hash(SettingsExpect, key, valueJson);

  @override
  String toString() => 'SettingsOp.expect($key)';
}

/// Settings [keys] changed (put or reset).
final class SettingsChanged extends DomainEvent {
  /// The settings [keys] changed.
  new(Iterable<String> keys) : keys = Set.unmodifiable(keys);

  /// The changed keys. Unmodifiable.
  final Set<String> keys;

  @override
  bool operator ==(Object other) =>
      other is SettingsChanged &&
      other.keys.length == keys.length &&
      other.keys.containsAll(keys);

  @override
  int get hashCode => Object.hashAllUnordered(keys);

  @override
  String toString() => 'SettingsChanged($keys)';
}
