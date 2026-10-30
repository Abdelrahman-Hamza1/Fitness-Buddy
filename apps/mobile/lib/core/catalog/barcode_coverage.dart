import 'dart:convert';

import 'package:fb_mobile/core/storage/preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'barcode_coverage.g.dart';

/// How a barcode lookup ended, for the coverage counter.
enum BarcodeCoverageKind {
  /// A product with all core values (local hits count here).
  found,

  /// A product with missing values.
  incomplete,

  /// No product for the code.
  notFound,
}

/// The counts so far.
typedef BarcodeCoverageCounts = ({int found, int incomplete, int notFound});

/// The on-device barcode coverage counter (TD-064, A28a D12): the real Open
/// Food Facts hit rate from daily use. Three integers in shared preferences;
/// never synced, never sent. A read or write failure is ignored: it's a
/// debug line.
final class BarcodeCoverage {
  /// A counter over [_preferences].
  const new(this._preferences);
  final SharedPreferencesAsync _preferences;

  /// The counts, zero when nothing is stored yet.
  Future<BarcodeCoverageCounts> read() async {
    try {
      final raw = await _preferences.getString(PreferenceKeys.barcodeCoverage);
      final map = raw == null ? null : jsonDecode(raw);
      int count(String key) =>
          map is Map && map[key] is int ? map[key] as int : 0;
      return (
        found: count('found'),
        incomplete: count('incomplete'),
        notFound: count('notFound'),
      );
    } on Object {
      return (found: 0, incomplete: 0, notFound: 0);
    }
  }

  /// Adds one lookup of [kind].
  Future<void> add(BarcodeCoverageKind kind) async {
    try {
      final now = await read();
      await _preferences.setString(
        PreferenceKeys.barcodeCoverage,
        jsonEncode({
          'found': now.found + (kind == BarcodeCoverageKind.found ? 1 : 0),
          'incomplete':
              now.incomplete + (kind == BarcodeCoverageKind.incomplete ? 1 : 0),
          'notFound':
              now.notFound + (kind == BarcodeCoverageKind.notFound ? 1 : 0),
        }),
      );
    } on Object {
      return;
    }
  }
}

/// The coverage counter.
@Riverpod(keepAlive: true)
BarcodeCoverage barcodeCoverage(Ref ref) =>
    BarcodeCoverage(ref.watch(sharedPreferencesProvider));

/// The counts for About; refreshed when About opens.
@riverpod
Future<BarcodeCoverageCounts> barcodeCoverageCounts(Ref ref) =>
    ref.watch(barcodeCoverageProvider).read();
