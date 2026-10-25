import 'dart:io';
import 'dart:isolate';

import 'package:fb_mobile/core/export/export_builder.dart';
import 'package:fb_mobile/core/export/export_cache_sweeper.dart';
import 'package:fb_mobile/core/export/export_sharer.dart';
import 'package:fb_mobile/core/export/export_snapshot.dart';

/// Failures contain categories only, never paths, SQL or row content.
enum ExportFailureKind {
  /// Database or metadata read failed.
  snapshot,

  /// Pure file encoding failed.
  encoding,

  /// Temporary file preparation failed.
  storage,

  /// OS share handoff failed.
  sharing,
}

/// Typed result of an export attempt, without user-facing strings.
sealed class ExportOutcome {
  /// Base export outcome.
  const new();
}

/// The OS accepted the share handoff.
final class Shared extends ExportOutcome {
  /// Reports aggregate counts from a completed OS handoff.
  const new({required this.fileCount, required this.rowCount});

  /// Number of files passed to the OS.
  final int fileCount;

  /// Total live rows across all exported entities.
  final int rowCount;
}

/// The OS share sheet was cancelled.
final class Dismissed extends ExportOutcome {
  /// The OS share sheet was cancelled.
  const new();
}

/// Another export still owns the temporary files.
final class ExportBusy extends ExportOutcome {
  /// No cancellation or share result is implied.
  const new();
}

/// Preparation was abandoned before opening the OS sheet.
final class ExportAbandoned extends ExportOutcome {
  /// The requesting sheet closed.
  const new();
}

/// An export stage failed; the underlying error is discarded.
final class Failed extends ExportOutcome {
  /// Identifies the failing stage without retaining the error.
  const new(this.kind);

  /// Safe failure category for localized UI.
  final ExportFailureKind kind;
}

/// Offline orchestration: snapshot, isolate encoding, private files, OS share.
final class DataExportService {
  /// Injects every platform and time boundary; no API client is needed.
  new({
    required this.readSnapshot,
    required this.temporaryDirectory,
    required this.sharer,
    required this.now,
    required this.appInfo,
  });

  /// Reads the active profile as plain rows.
  final Future<ExportSnapshot> Function({
    required Iterable<String> settingNames,
  })
  readSnapshot;

  /// Resolves app-private cache storage.
  final Future<Directory> Function() temporaryDirectory;

  /// OS share boundary.
  final ExportSharer sharer;

  /// Local export time supplied by the app clock.
  final DateTime Function() now;

  /// Installed app metadata, resolved without a network call.
  final Future<({String version, String build})> Function() appInfo;
  bool _working = false;

  /// Sweeps aged handoffs and builds one export; concurrent calls skip.
  Future<ExportOutcome> export({
    required Iterable<String> settingNames,
    bool Function()? isCancelled,
  }) async {
    if (_working) return const ExportBusy();
    _working = true;
    Directory? exportDir;
    var stage = ExportFailureKind.storage;
    try {
      final root = await temporaryDirectory();
      final dir = exportDir = Directory('${root.path}/export');
      await ExportCacheSweeper(
        temporaryDirectory: () async => root,
        now: now,
      ).sweep();
      // Keep filesystem work off the UI thread, including existence checks.
      // ignore: avoid_slow_async_io
      if (await dir.exists()) await dir.delete(recursive: true);
      await dir.create(recursive: true);
      stage = ExportFailureKind.snapshot;
      final snapshot = await readSnapshot(settingNames: settingNames);
      final info = await appInfo();
      final date = now();
      stage = ExportFailureKind.encoding;
      final files = await Isolate.run(
        () => ExportBuilder.build(
          snapshot,
          exportedAt: date,
          version: info.version,
          build: info.build,
        ),
      );
      stage = ExportFailureKind.storage;
      final paths = <File>[];
      for (final file in files) {
        final path = File('${dir.path}/${file.name}');
        await path.writeAsBytes(file.bytes, flush: true);
        paths.add(path);
      }
      if (isCancelled?.call() ?? false) return const ExportAbandoned();
      stage = ExportFailureKind.sharing;
      return switch (await sharer.share(paths)) {
        ExportShareResult.dismissed => const Dismissed(),
        ExportShareResult.shared => Shared(
          fileCount: files.length,
          rowCount: snapshot.rows.values.fold(
            0,
            (sum, rows) => sum + rows.length,
          ),
        ),
      };
    } on Object {
      return Failed(stage);
    } finally {
      try {
        for (final dir in [exportDir]) {
          // Keep deletion and existence checks off the UI thread.
          // ignore: avoid_slow_async_io
          if (dir != null && await dir.exists()) {
            await dir.delete(recursive: true);
          }
        }
      } on Object {
        // A later export retries the wipe; never expose paths or file content.
      } finally {
        _working = false;
      }
    }
  }
}
