import 'dart:io';

import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../db/support/db_support.dart';

/// The committed fixture script (A05 D7); a tool test keeps it fresh.
String fixtureSql() =>
    File('test/fixtures/catalog_fixture.sql').readAsStringSync();

/// Writes a pack file from the fixture SQL, with [extraSql] run before it is
/// closed (like a barcode row).
String writeFixturePack(String path, {String extraSql = ''}) {
  File(path).parent.createSync(recursive: true);
  sqlite3.open(path)
    ..execute(fixtureSql())
    ..execute(extraSql.isEmpty ? 'SELECT 1' : extraSql)
    ..close();
  return path;
}

/// A database with the fixture pack attached, and the catalog over it.
(AppDatabase, OfflineCatalog) fixtureCatalog({String extraSql = ''}) {
  final dir = tempDir().path;
  final pack = writeFixturePack('$dir/catalog-1.db', extraSql: extraSql);
  final db = fileDatabase('$dir/user.db', catalog: FixedPack(pack));
  return (db, OfflineCatalog(db));
}
