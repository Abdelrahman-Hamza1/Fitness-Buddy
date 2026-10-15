import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'preferences.g.dart';

/// Small key-value settings that are not user data: the device id and the
/// cached `/v1/config` (S06 plan D8, D9). User data lives in the database.
///
/// The async API reads the platform on demand, so creating it does no I/O
/// (UX-001). Tests override it with an in-memory store.
@Riverpod(keepAlive: true)
SharedPreferencesAsync sharedPreferences(Ref ref) => SharedPreferencesAsync();

/// The keys the app stores in [sharedPreferences]. One place, so two
/// features can't pick the same key.
abstract final class PreferenceKeys {
  /// The install's device id (`X-Device-Id`).
  static const deviceId = 'fb.device_id';

  /// The last good `/v1/config` response, as JSON. The version suffix lets
  /// a future format change start from defaults instead of misreading it.
  static const clientConfig = 'fb.client_config.v1';
}
