import 'dart:io';

/// Best-effort retention for unencrypted OS handoff copies (AC-030).
final class ExportCacheSweeper {
  /// Injects storage and time without opening the user database.
  const new({required this.temporaryDirectory, required this.now});

  /// Resolves private cache storage.
  final Future<Directory> Function() temporaryDirectory;

  /// Clock used for the 24-hour retention threshold.
  final DateTime Function() now;

  /// Visits at most 256 entries for at most two seconds of work per invocation.
  /// Async filesystem work never blocks a frame; failures carry no telemetry.
  Future<void> sweep() async {
    try {
      // No timer or Future.timeout: the app never awaits this (fire-and-forget
      // after the first frame), the stopwatch below bounds the work, and a
      // pending timer would fail every widget test that boots the app.
      await _sweep();
    } on Object {
      // Missing storage, permissions and plugin races are all optional cleanup.
    }
  }

  Future<void> _sweep() async {
    final timer = Stopwatch()..start();
    final cutoff = now().subtract(const Duration(hours: 24));
    final root = await temporaryDirectory();
    final cache = Directory('${root.path}/share_plus');
    await for (final entry in cache.list(followLinks: false).take(256)) {
      if (timer.elapsed >= const Duration(seconds: 2)) break;
      // Never follow links or recursively delete directories/other cache data.
      if (entry is! File) continue;
      try {
        // Keep filesystem metadata work off the UI thread too.
        // ignore: avoid_slow_async_io
        final stat = await entry.stat();
        if (timer.elapsed >= const Duration(seconds: 2)) break;
        if (stat.type == FileSystemEntityType.file &&
            stat.modified.isBefore(cutoff)) {
          await entry.delete();
        }
      } on Object {
        // One vanished/unreadable entry must not stop the rest of the sweep.
      }
    }
  }
}
