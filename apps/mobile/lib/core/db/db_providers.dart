import 'dart:async';

import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/catalog/catalog_pack_source.dart';
import 'package:fb_mobile/core/db/connection.dart';
import 'package:fb_mobile/core/db/database_location.dart';
import 'package:fb_mobile/core/errors/error_reporting.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'db_providers.g.dart';

/// The open profile (A01 D13), or `null` until an A33 switch: then the
/// database location reads the registry's active profile lazily when the
/// database opens (A33 D3), so no storage is touched here.
@Riverpod(keepAlive: true)
class ProfileKey extends _$ProfileKey {
  @override
  String? build() => null;

  /// Set by the account service after it wrote the registry; disposes and
  /// reopens the database.
  // A command method keeps the selection on Riverpod's state property.
  // ignore: use_setters_to_change_properties
  void select(String key) => state = key;
}

/// Reads the active profile from the registry when the database opens
/// (A33 D3). Overridden by the account layer; tests keep `local`.
@Riverpod(keepAlive: true)
Future<String> Function()? activeProfileResolver(Ref ref) => null;

/// Where the catalog pack is: none until A05 (A01 D14).
@Riverpod(keepAlive: true)
CatalogPackSource catalogPackSource(Ref ref) => const NoCatalogPack();

/// Where the open profile's database lives.
@Riverpod(keepAlive: true)
DatabaseLocation databaseLocation(Ref ref) {
  final key = ref.watch(profileKeyProvider);
  final location = DatabaseLocation.appSupport(
    key ?? 'local',
    resolveProfileKey: key == null
        ? ref.watch(activeProfileResolverProvider)
        : null,
  );
  ref.read(openProfileHandlesProvider).location = location;
  return location;
}

/// What the account transitions need from the open profile (A33), without
/// depending on its providers: the transitions are themselves a dependency
/// of the applier (write gate) and of the location (resolver), so reading
/// those providers from there would be a circular dependency. The providers
/// below register their current instances here.
final class OpenProfileHandles {
  /// The open database, if one was built.
  AppDatabase? database;

  /// The open location, if one was built.
  DatabaseLocation? location;

  /// Waits for the open applier's queued writes, if an applier was built.
  Future<void> Function()? idle;
}

/// The one [OpenProfileHandles] (no dependencies).
@Riverpod(keepAlive: true)
OpenProfileHandles openProfileHandles(Ref ref) => OpenProfileHandles();

/// The open profile's database. Synchronous: it opens lazily on the first
/// query, so reading this provider touches no storage (UX-001). Closed when
/// the provider is disposed (a profile switch, A33).
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase(
    openUserDatabase(ref.watch(databaseLocationProvider)),
    catalog: ref.watch(catalogPackSourceProvider),
    // The error's runtime type only: no paths, no messages.
    onCatalogError: (error, _) =>
        ref.read(errorReportingProvider).reportKind(error),
  );
  ref.onDispose(() => unawaited(closeDatabase(db)));
  ref.read(openProfileHandlesProvider).database = db;
  return db;
}

final _closing = Expando<Future<void>>('closing');

/// Closes [db] once: every caller (the provider's dispose, an A33 profile
/// switch waiting before it deletes files) shares the same close future.
Future<void> closeDatabase(AppDatabase db) => _closing[db] ??= db.close();
