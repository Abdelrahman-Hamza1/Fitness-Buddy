import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Resolves a directory path, like `getApplicationSupportDirectory`.
typedef DirectoryPathResolver = Future<String> Function();

/// Where a profile's database lives (A01 D13, `05` §3): one file per account
/// or guest, `<applicationSupport>/profiles/<profileKey>/user.db`.
///
/// Nothing is resolved until the database opens (lazily, on its first query),
/// so building a location touches no storage (UX-001).
final class DatabaseLocation {
  /// The database of [profileKey] under `root`; SQLite's temporary files go
  /// to `temporary`. Throws an `ArgumentError` if [profileKey] isn't 1-64
  /// lowercase letters, digits or `-` (it becomes a directory name).
  new({
    required this.profileKey,
    required this._root,
    required this._temporary,
    this._resolveProfileKey,
  }) {
    if (!_profileKey.hasMatch(profileKey)) {
      throw ArgumentError(
        'profileKey must be 1-64 lowercase letters, digits or -',
      );
    }
  }

  /// The app's location: application support and temporary cache. A11 PA5
  /// allows encrypted Android 12+ backup of local user.db and sidecars only.
  factory appSupport(
    String profileKey, {
    Future<String> Function()? resolveProfileKey,
  }) => DatabaseLocation(
    profileKey: profileKey,
    root: () async => (await getApplicationSupportDirectory()).path,
    temporary: () async => (await getTemporaryDirectory()).path,
    resolveProfileKey: resolveProfileKey,
  );

  static final _profileKey = RegExp(r'^[a-z0-9][a-z0-9-]{0,63}$');

  /// The profile, `local` until A33 adds accounts and guests.
  final String profileKey;

  final DirectoryPathResolver _root;
  final DirectoryPathResolver _temporary;

  /// A33 D3: the active profile is read from the local registry when the
  /// database opens (lazily, after the first frame), not before `runApp`.
  final Future<String> Function()? _resolveProfileKey;

  /// Whether this location follows the registry's active profile (A33 D3)
  /// rather than being pinned to [profileKey] (an explicit switch, tests).
  bool get followsRegistry => _resolveProfileKey != null;

  String? _resolvedKey;

  /// The profile this location (and so its database) belongs to: the first
  /// resolution wins and is fixed from then on, so the database path and the
  /// A33 write gate agree. Only the key is cached, never a future: a future
  /// created in one zone (a widget test's fake clock) and awaited in another
  /// (`runAsync`) would never complete, and a cached future can't be sent to
  /// the database isolate.
  Future<String> resolvedProfileKey() async {
    if (_resolvedKey case final key?) return key;
    final key = await _resolveProfileKey?.call() ?? profileKey;
    if (!_profileKey.hasMatch(key)) {
      throw ArgumentError(
        'profileKey must be 1-64 lowercase letters, digits or -',
      );
    }
    return _resolvedKey ??= key;
  }

  /// The profile directory, resolving the active profile if needed.
  Future<String> profileDirectory() async =>
      '${await _root()}/profiles/${await resolvedProfileKey()}';

  /// The absolute path of the profile's `user.db`.
  Future<String> userDatabasePath() async =>
      '${await profileDirectory()}/user.db';

  /// Deletes another profile's directory (user.db and sidecars) for an A33
  /// sign-out "remove" or a discarded guest (AC-003/AC-004). Refuses this
  /// location's own profile once resolved and keys that aren't plain
  /// directory names. Never resolves the profile itself: crash recovery runs
  /// inside the resolver (A33 §6).
  Future<void> deleteOtherProfile(String otherKey) async {
    if (otherKey == _resolvedKey) throw StateError('active_profile');
    await deleteProfileDirectory(otherKey);
  }

  /// Deletes `profiles/<key>/` under this location's root, whichever
  /// profile this location itself belongs to: the caller guarantees [key]
  /// is not open (A33 cleanup, after the switch and the close). Refuses keys
  /// that aren't plain directory names.
  Future<void> deleteProfileDirectory(String key) async {
    if (!_profileKey.hasMatch(key)) throw ArgumentError('profileKey');
    final dir = Directory('${await _root()}/profiles/$key');
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  /// The directory for SQLite's temporary files (Android has no `/tmp`).
  Future<String> temporaryDirectory() => _temporary();
}
