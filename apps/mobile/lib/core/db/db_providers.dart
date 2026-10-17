import 'dart:async';

import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/catalog/catalog_pack_source.dart';
import 'package:fb_mobile/core/db/connection.dart';
import 'package:fb_mobile/core/db/database_location.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'db_providers.g.dart';

/// The open profile (A01 D13): `local` until A33 adds accounts and guests.
@Riverpod(keepAlive: true)
String profileKey(Ref ref) => 'local';

/// Where the catalog pack is: none until A05 (A01 D14).
@Riverpod(keepAlive: true)
CatalogPackSource catalogPackSource(Ref ref) => const NoCatalogPack();

/// Where the open profile's database lives.
@Riverpod(keepAlive: true)
DatabaseLocation databaseLocation(Ref ref) =>
    DatabaseLocation.appSupport(ref.watch(profileKeyProvider));

/// The open profile's database. Synchronous: it opens lazily on the first
/// query, so reading this provider touches no storage (UX-001). Closed when
/// the provider is disposed (a profile switch, A33).
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase(
    openUserDatabase(ref.watch(databaseLocationProvider)),
    catalog: ref.watch(catalogPackSourceProvider),
  );
  ref.onDispose(() => unawaited(db.close()));
  return db;
}
