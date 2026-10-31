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

  /// When the weight card's "weigh in 2–3 times a week" suggestion last
  /// showed and whether it was dismissed (A14 D10, PA10): a display
  /// preference, not user data, so it never syncs.
  static const weightCadenceTip = 'fb.weight_cadence_tip.v1';

  /// When this install was first used and when the guest "create an
  /// account" prompt last showed (AC-002, A33 D8): display state, not user
  /// data, never synced.
  static const guestPrompt = 'fb.guest_prompt.v1';

  /// Barcode lookups found / incomplete / not found on this phone (A28a
  /// D12, TD-064): a debug counter shown on About, never synced or sent.
  static const barcodeCoverage = 'fb.barcode_coverage.v1';

  /// Prefix of the barcodes scanned while the lookup couldn't run (offline,
  /// server unavailable), waiting for a later lookup (A28a D10, OF-02).
  /// Device state, never synced; one list per environment and local profile
  /// (`<prefix>|<namespace>|<profileKey>`), deleted with the profile.
  static const pendingScans = 'fb.pending_scans.v1';

  /// What this install scheduled as local notifications and when (A40 D5):
  /// IDs and times only, device state, never synced or sent.
  static const notificationLedger = 'fb.notifications.ledger.v1';

  /// The tag (a hash of the profile key, not the key) of the profile whose
  /// notifications may be on the phone (A40 fix-check 1): device state,
  /// never synced.
  static const notificationOwner = 'fb.notifications.owner.v1';

  /// Whether the app has asked for the notification permission once (A40
  /// D8): device state, never synced.
  static const notificationPermissionAsked =
      'fb.notifications.permission_asked.v1';

  /// The pending-scan list of [profileKey] in the [namespace] environment
  /// (`flavor|apiBaseUrl`, as the profile registry's).
  static String pendingScansFor(String namespace, String profileKey) =>
      '$pendingScans|$namespace|$profileKey';
}
