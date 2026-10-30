import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:fb_mobile/core/db/database_location.dart';
import 'package:sqlite3/sqlite3.dart';

/// The executor of a profile's `user.db` (A01 D13): SQLite in a background
/// isolate, opened lazily on the first query, so nothing touches storage
/// before the first frame (UX-001). `AppDatabase` adds the write guard.
///
/// Not drift_flutter's `driftDatabase()`: that opens SQLite without URI
/// filenames, and the read-only catalog ATTACH (`file:…?mode=ro`, A01 D14)
/// needs them. This is the same background setup (one isolate, one client)
/// with `uri: true`.
QueryExecutor openUserDatabase(DatabaseLocation location) =>
    LazyDatabase(() async {
      final path = await location.userDatabasePath();
      final temporary = await location.temporaryDirectory();
      final isolate = await _spawn(path, temporary);
      return await isolate.connect(singleClientMode: true);
    });

/// Spawns the background isolate from plain strings only: its entry closure
/// must not capture the location (A33: the location holds a memoized
/// future and a registry resolver, which can't be sent to an isolate).
Future<DriftIsolate> _spawn(String path, String temporary) =>
    DriftIsolate.spawn(
      () => openNativeUserDatabase(path, temporaryDirectory: temporary),
    );

/// Opens the SQLite file at [path] in the current isolate, creating its
/// directory, with URI filenames on and the connection pragmas
/// ([configureConnection]). [openUserDatabase] runs it in the background
/// isolate; tests may call it directly.
QueryExecutor openNativeUserDatabase(
  String path, {
  String? temporaryDirectory,
}) {
  if (temporaryDirectory != null) sqlite3.tempDirectory = temporaryDirectory;
  File(path).parent.createSync(recursive: true);
  return NativeDatabase.opened(
    sqlite3.open(path, uri: true),
    setup: configureConnection,
  );
}

/// The connection pragmas (A01 D13): WAL, `synchronous=NORMAL` (durable at
/// checkpoints, safe in WAL), a 5 s busy timeout, and `trusted_schema=OFF`
/// (an attached catalog pack's views and triggers can't call functions with
/// side effects).
void configureConnection(Database database) {
  database
    ..execute('PRAGMA journal_mode = WAL')
    ..execute('PRAGMA synchronous = NORMAL')
    ..execute('PRAGMA busy_timeout = 5000')
    ..execute('PRAGMA trusted_schema = OFF');
}
