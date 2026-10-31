import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/notifications/data/notification_device_store.dart';
import 'package:fb_mobile/features/notifications/data/notification_platform.dart';

/// What one [NotificationScheduler.sync] did (for tests and diagnostics;
/// counts only).
typedef NotificationSyncResult = ({int scheduled, int cancelled, int kept});

/// Makes the platform hold exactly the planned notifications (`09` §1,
/// A40 D5): a diff, so re-planning with the same plan changes nothing.
///
/// Each payload is `v1|<profile tag>|<epoch minute>|<text hash>|<location>`:
/// when the time, the words or the link of an ID change, the payload
/// differs and the notification is replaced. The profile tag ties a
/// notification to the profile that planned it; a tap from another
/// profile is ignored (A40 review 1).
///
/// A pending notification whose time has passed (an inexact alarm not
/// delivered yet, or one restored after a reboot) is kept only while it
/// still applies today (`stillApplying`); otherwise it is cancelled, so a
/// reminder that stopped applying or a prior day's never arrives late (A40
/// review 2). A planned ID already shown today (its ledger time has
/// passed) isn't scheduled again: one per type and day.
final class NotificationScheduler {
  /// Over [platform], keeping its ledger in [store], at [clock]'s time.
  new({required this.platform, required this.store, required this.clock});

  /// The phone's notifications.
  final NotificationPlatform platform;

  /// The ledger and the permission flag.
  final NotificationDeviceStore store;

  /// The time.
  final Clock clock;

  /// Ledger entries older than this are dropped.
  static const Duration ledgerKeep = Duration(days: 2);

  /// The payload for a notification of the profile tagged [profileTag] at
  /// [at] with [title]/[body], linking to [location].
  static String payloadOf({
    required String profileTag,
    required DateTime at,
    required String title,
    required String body,
    required String location,
  }) =>
      'v1|$profileTag'
      '|${at.millisecondsSinceEpoch ~/ Duration.millisecondsPerMinute}'
      '|${fnv1a('$title\n$body')}|$location';

  /// A short tag of a profile key (no key in payloads): its FNV-1a hash.
  static String profileTagOf(String profileKey) =>
      fnv1a(profileKey).toRadixString(16);

  /// The deep link in [payload] when it belongs to [profileTag], or null
  /// when it isn't ours or another profile's: only a relative app path
  /// (`/today`, never a scheme, a host or `//`).
  static String? locationOf(String? payload, {required String profileTag}) {
    final parts = payload?.split('|');
    if (parts == null || parts.length != 5 || parts.first != 'v1') {
      return null;
    }
    if (parts[1] != profileTag) return null;
    final location = parts.last;
    if (!location.startsWith('/') || location.startsWith('//')) return null;
    final uri = Uri.tryParse(location);
    if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
    return location;
  }

  /// The profile tag in [payload], or null when unreadable.
  static String? tagOf(String payload) {
    final parts = payload.split('|');
    return parts.length == 5 && parts.first == 'v1' ? parts[1] : null;
  }

  /// When the notification of [payload] fires, or null when unreadable.
  static DateTime? atOf(String payload) {
    final parts = payload.split('|');
    if (parts.length != 5 || parts.first != 'v1') return null;
    final minute = int.tryParse(parts[2]);
    return minute == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            minute * Duration.millisecondsPerMinute,
            isUtc: true,
          );
  }

  /// How many of our notifications were shown since [since] (an instant):
  /// ledger entries between [since] and now (NT-022).
  Future<int> shownSince(DateTime since) async {
    final now = clock.nowUtc().millisecondsSinceEpoch;
    final from = since.millisecondsSinceEpoch;
    final ledger = await store.readLedger();
    return ledger.values.where((at) => at >= from && at <= now).length;
  }

  /// Schedules [planned] and cancels what isn't planned (see the class
  /// doc): a due pending notification survives only if its ID is in
  /// [stillApplying] and its payload carries [profileTag] (when given).
  /// [isCurrent] is asked before every platform call; once it says no (the
  /// profile changed), nothing more is scheduled.
  /// Idempotent.
  Future<NotificationSyncResult> sync(
    List<ScheduledNotification> planned, {
    Set<int> stillApplying = const {},
    String? profileTag,
    bool Function()? isCurrent,
  }) async {
    bool current() => isCurrent?.call() ?? true;
    final now = clock.nowUtc();
    final pending = await platform.pending();
    final ledger = await store.readLedger();
    if (!current()) return (scheduled: 0, cancelled: 0, kept: 0);
    final before = Map.of(ledger);
    final wanted = {for (final n in planned) n.id: n};
    var cancelled = 0;
    var scheduled = 0;
    var kept = 0;
    for (final MapEntry(key: id, value: payload) in pending.entries) {
      if (wanted.containsKey(id) && wanted[id]!.at.isAfter(now)) continue;
      final at = atOf(payload);
      final due = at != null && !at.isAfter(now);
      // Only the open profile's own alarm may be kept (fix-check 1).
      if (due &&
          stillApplying.contains(id) &&
          (profileTag == null || tagOf(payload) == profileTag)) {
        continue;
      }
      await platform.cancel(id);
      // Never shown: it doesn't count toward today's cap.
      ledger.remove(id);
      cancelled++;
    }
    for (final n in planned) {
      if (!n.at.isAfter(now)) continue;
      if (pending[n.id] == n.payload) {
        kept++;
        continue;
      }
      final shownAt = ledger[n.id];
      if (!pending.containsKey(n.id) &&
          shownAt != null &&
          shownAt <= now.millisecondsSinceEpoch &&
          now.millisecondsSinceEpoch - shownAt < Duration.millisecondsPerDay) {
        // Already shown (today): one per type and day.
        continue;
      }
      if (!current()) break;
      await platform.schedule(n);
      ledger[n.id] = n.at.millisecondsSinceEpoch;
      scheduled++;
    }
    final oldest = now.subtract(ledgerKeep).millisecondsSinceEpoch;
    ledger.removeWhere((_, at) => at < oldest);
    if (!_sameMap(before, ledger)) await store.writeLedger(ledger);
    return (scheduled: scheduled, cancelled: cancelled, kept: kept);
  }

  /// Cancels every notification of ours that hasn't been shown, due ones
  /// included (master switch off, permission withdrawn).
  Future<int> cancelAll() => sync(const []).then((r) => r.cancelled);

  /// Removes everything of the app, scheduled and shown, and forgets the
  /// ledger: the profile changed (sign-in, sign-out, account deletion,
  /// A40 review 1).
  Future<void> purge() async {
    await platform.cancelEverything();
    await store.writeLedger({});
    await store.setOwnerTag(null);
  }

  /// Makes the phone hold only [profileTag]'s notifications: when the
  /// stored owner is another profile (a switch, maybe interrupted by a
  /// crash before its purge), purges first; then records [profileTag] as
  /// the owner. Whether it purged.
  Future<bool> claim(String profileTag) async {
    final owner = await store.ownerTag();
    if (owner == profileTag) return false;
    final purged = owner != null;
    if (purged) await purge();
    await store.setOwnerTag(profileTag);
    return purged;
  }

  static bool _sameMap(Map<int, int> a, Map<int, int> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

  /// A stable 32-bit FNV-1a hash (String.hashCode may change between Dart
  /// versions).
  static int fnv1a(String text) {
    var hash = 0x811c9dc5;
    for (final unit in text.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}
