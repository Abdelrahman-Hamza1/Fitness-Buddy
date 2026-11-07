import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// The export copies the OS share handoff made for each local profile
/// (security audit 2026-11-07, AC-030): a small app-owned JSON map
/// (`path → profile key`) recorded before the share sheet opens, so
/// removing a profile (account deletion, sign-out "remove") deletes that
/// profile's copies at once instead of waiting for the 24-hour sweep.
///
/// Only listed paths are ever deleted, and only when they are plain files:
/// never a directory, never a name pattern. A path holds the profile that
/// last handed it over (share_plus copies by file name, so a later export
/// overwrites the same path). Paths and keys are never logged.
///
/// Android grants the share target a temporary read permission on the
/// FileProvider URI, tied to the receiving task; share_plus offers no way
/// to revoke it, so deleting the copy is the practical revocation: the URI
/// then resolves to no file.
final class ExportHandoffs {
  /// The map kept in the file [listFile] resolves to.
  new(this.listFile);

  /// Resolves the JSON map (in the app support directory).
  final Future<File> Function() listFile;

  /// Serializes read-modify-write cycles on the list.
  Future<void> _queue = Future.value();

  /// Records [paths] as handed over for [profileKey] (before the share).
  /// Entries whose file is gone already are forgotten on the way.
  Future<void> record(String profileKey, Iterable<String> paths) =>
      _serial(() async {
        final file = await listFile();
        final map = await _read(file)
          ..removeWhere((path, _) => !_isFile(path));
        for (final path in paths) {
          map[path] = profileKey;
        }
        await _write(file, map);
      });

  /// Deletes every listed copy handed over for [profileKey] and forgets
  /// them. Best effort: the 24-hour sweep is the backstop, so a failure
  /// here never blocks the profile's removal.
  Future<void> removeProfile(String profileKey) => _serial(() async {
    final file = await listFile();
    final map = await _read(file);
    final owned = [
      for (final MapEntry(:key, :value) in map.entries)
        if (value == profileKey) key,
    ];
    if (owned.isEmpty) return;
    for (final path in owned) {
      _delete(path);
      map.remove(path);
    }
    await _write(file, map);
  });

  /// Deletes [paths] (copies this export handed over for [profileKey])
  /// unless another profile has handed the same path over since, and
  /// forgets them. Used when the profile went while its share sheet was
  /// open: the exact paths, so a removal that ran before the platform
  /// finished copying (and forgot them) still leaves nothing behind.
  Future<void> removePaths(String profileKey, Iterable<String> paths) =>
      _serial(() async {
        final file = await listFile();
        final map = await _read(file);
        for (final path in paths) {
          final owner = map[path];
          if (owner != null && owner != profileKey) continue;
          _delete(path);
          map.remove(path);
        }
        await _write(file, map);
      });

  Future<void> _serial(Future<void> Function() body) {
    final next = _queue.then((_) async {
      try {
        await body();
        // No storage, an unreadable list: optional cleanup either way.
        // ignore: avoid_catches_without_on_clauses
      } catch (_) {}
    });
    return _queue = next;
  }

  static bool _isFile(String path) {
    try {
      return FileSystemEntity.typeSync(path, followLinks: false) ==
          FileSystemEntityType.file;
      // An unreadable path counts as no file.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return false;
    }
  }

  static void _delete(String path) {
    try {
      if (_isFile(path)) File(path).deleteSync();
      // Gone already or not deletable: the sweep retries old copies.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}
  }

  static Future<Map<String, String>> _read(File file) async {
    try {
      if (!file.existsSync()) return {};
      final json = jsonDecode(await file.readAsString());
      return {
        if (json is Map<String, Object?>)
          for (final MapEntry(:key, :value) in json.entries)
            if (key.isNotEmpty && value is String) key: value,
      };
      // An unreadable list is an empty one (the sweep still ages copies out).
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return {};
    }
  }

  static Future<void> _write(File file, Map<String, String> map) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(map), flush: true);
  }

  @override
  String toString() => 'ExportHandoffs';
}
