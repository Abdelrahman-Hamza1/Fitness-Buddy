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
  }) {
    if (!_profileKey.hasMatch(profileKey)) {
      throw ArgumentError(
        'profileKey must be 1-64 lowercase letters, digits or -',
      );
    }
  }

  /// The app's location: application support and temporary cache. A11 PA5
  /// allows encrypted Android 12+ backup of local user.db and sidecars only.
  factory appSupport(String profileKey) => DatabaseLocation(
    profileKey: profileKey,
    root: () async => (await getApplicationSupportDirectory()).path,
    temporary: () async => (await getTemporaryDirectory()).path,
  );

  static final _profileKey = RegExp(r'^[a-z0-9][a-z0-9-]{0,63}$');

  /// The profile, `local` until A33 adds accounts and guests.
  final String profileKey;

  final DirectoryPathResolver _root;
  final DirectoryPathResolver _temporary;

  /// The absolute path of the profile's `user.db`.
  Future<String> userDatabasePath() async =>
      '${await _root()}/profiles/$profileKey/user.db';

  /// The directory for SQLite's temporary files (Android has no `/tmp`).
  Future<String> temporaryDirectory() => _temporary();
}
