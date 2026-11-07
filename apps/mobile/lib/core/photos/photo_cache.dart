import 'dart:convert';
import 'dart:io';

/// The picture files the image picker handed this app (A69 fix-check):
/// their paths are recorded in a small app-owned list ([listFile], JSON)
/// before the file is read, deleted after use, and anything left (a kill
/// mid-read) is deleted on the next sweep. Only listed paths are ever
/// deleted, and only when they are plain files: never a directory, never a
/// name pattern. Paths are never logged.
final class OwnedPhotoFiles {
  /// The list kept in [listFile].
  const new(this.listFile);

  /// The JSON list of owned paths (in the app support directory).
  final File listFile;

  /// Records [path] as owned (before it is read).
  Future<void> own(String path) async {
    final paths = await _read()
      ..add(path);
    await _write(paths);
  }

  /// Deletes [path] (when it is a listed plain file) and forgets it.
  Future<void> release(String path) async {
    final paths = await _read();
    if (paths.remove(path)) _delete(path);
    await _write(paths);
  }

  /// Deletes every listed file still there and clears the list.
  Future<void> sweep() async {
    final paths = await _read();
    if (paths.isEmpty) return;
    paths.forEach(_delete);
    await _write({});
  }

  static void _delete(String path) {
    try {
      if (FileSystemEntity.typeSync(path, followLinks: false) ==
          FileSystemEntityType.file) {
        File(path).deleteSync();
      }
      // Gone already or not deletable: forgotten either way.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}
  }

  Future<Set<String>> _read() async {
    try {
      if (!listFile.existsSync()) return {};
      final json = jsonDecode(await listFile.readAsString());
      return {
        if (json is List<Object?>)
          for (final p in json)
            if (p is String && p.isNotEmpty) p,
      };
      // An unreadable list is an empty one (its files go with the OS cache).
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return {};
    }
  }

  Future<void> _write(Set<String> paths) async {
    try {
      await listFile.parent.create(recursive: true);
      await listFile.writeAsString(jsonEncode(paths.toList()));
      // Not writable: the next sweep finds what it can.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}
  }

  @override
  String toString() => 'OwnedPhotoFiles';
}
