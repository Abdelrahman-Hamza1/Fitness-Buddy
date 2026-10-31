import 'package:fb_domain/src/time/local_date.dart';

/// Sync document upgraders (A34 D15, `05` §5.2 "schema evolution"): the
/// server stores and returns every document under the `schemaVersion` it was
/// written with and never upgrades one; the app upgrades older payloads on
/// pull, one version step at a time, before mapping them to its tables.
///
/// Payloads are the wire maps (`Map<String, Object?>`, numbers as `num`).
/// An upgrader never reads or logs anything beyond the fields it converts.
abstract final class SyncDocumentUpgraders {
  /// The newest `schemaVersion` this app reads and uploads per entity; an
  /// entity not listed is at version 1.
  static const Map<String, int> currentVersions = {'weighIn': 2};

  /// The version this app uploads for [entity].
  static int currentVersionOf(String entity) => currentVersions[entity] ?? 1;

  /// [payload] of [entity] at [fromVersion], upgraded to the current
  /// version, or `null` when this app can't read it: a version newer than
  /// [currentVersionOf] (written by a newer app), below 1, or a payload an
  /// upgrader can't convert. Returns a new map; [payload] is not changed.
  static Map<String, Object?>? upgrade(
    String entity,
    int fromVersion,
    Map<String, Object?> payload,
  ) {
    final target = currentVersionOf(entity);
    if (fromVersion < 1 || fromVersion > target) return null;
    var current = Map<String, Object?>.of(payload);
    for (var version = fromVersion; version < target; version++) {
      final step = _steps['$entity@$version'];
      if (step == null) return null;
      final next = step(current);
      if (next == null) return null;
      current = next;
    }
    return current;
  }

  static const Map<String, Map<String, Object?>? Function(Map<String, Object?>)>
  _steps = {'weighIn@1': weighInV1ToV2};

  /// `weighIn` v1 → v2 (A14 D7, B19 D6): `inputValue` = `kg`, `inputUnit`
  /// `kg`, `preferredForDay` false and `tzOffsetMin` from
  /// [impliedOffsetMinutes]. `null` when `kg`, `measuredAtUtc` or
  /// `localDate` is missing or unreadable.
  static Map<String, Object?>? weighInV1ToV2(Map<String, Object?> v1) {
    final kg = v1['kg'];
    final measured = v1['measuredAtUtc'];
    final date = v1['localDate'];
    if (kg is! num || measured is! num || date is! String) return null;
    if (measured != measured.roundToDouble()) return null;
    final localDate = LocalDate.tryParse(date);
    if (localDate == null) return null;
    return {
      ...v1,
      'tzOffsetMin': impliedOffsetMinutes(measured.toInt(), localDate),
      'inputValue': kg,
      'inputUnit': 'kg',
      'preferredForDay': false,
    };
  }

  /// The UTC offset in whole minutes nearest 0 at which the instant
  /// [measuredAtUtcMs] falls on [localDate], clamped to −720…840 (the
  /// `tzOffsetMin` range). 0 when the UTC date already is [localDate].
  static int impliedOffsetMinutes(int measuredAtUtcMs, LocalDate localDate) {
    const dayMs = 86400000;
    const minuteMs = 60000;
    final midnight = DateTime.utc(
      localDate.year,
      localDate.month,
      localDate.day,
    ).millisecondsSinceEpoch;
    final sinceMidnight = measuredAtUtcMs - midnight;
    // measured + offset must lie in [midnight, midnight + 1 day).
    final low = _ceilDiv(-sinceMidnight, minuteMs);
    final high = _floorDiv(dayMs - 1 - sinceMidnight, minuteMs);
    final nearest = low > 0 ? low : (high < 0 ? high : 0);
    return nearest.clamp(-720, 840);
  }

  static int _floorDiv(int a, int b) => (a / b).floor();

  static int _ceilDiv(int a, int b) => (a / b).ceil();
}
