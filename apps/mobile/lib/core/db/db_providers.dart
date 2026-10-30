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

  /// The last location built. Only its root is used (to find the profiles
  /// directory): it may still belong to a profile that was just switched
  /// away from, so never ask it which profile is open.
  DatabaseLocation? location;

  /// Waits for the open applier's queued writes, if an applier was built.
  Future<void> Function()? get idle => _idle;
  Future<void> Function()? _idle;
  Object? _idleOwner;

  /// Registers the open applier's [idle]; the returned token unregisters
  /// exactly this registration (a newer applier's survives).
  Object registerIdle(Future<void> Function() idle) {
    final owner = Object();
    _idle = idle;
    _idleOwner = owner;
    return owner;
  }

  /// Clears the registration made with [owner], if it is still current.
  void unregisterIdle(Object owner) {
    if (!identical(_idleOwner, owner)) return;
    _idle = null;
    _idleOwner = null;
  }

  /// Clears whatever applier is registered (a profile switch).
  void clearIdle() {
    _idle = null;
    _idleOwner = null;
  }
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
  final handles = ref.read(openProfileHandlesProvider)..database = db;
  ref.onDispose(() {
    if (identical(handles.database, db)) handles.database = null;
    unawaited(closeDatabase(db));
  });
  return db;
}

final _closing = Expando<Future<void>>('closing');

/// Closes [db] once: every caller (the provider's dispose, an A33 profile
/// switch waiting before it deletes files) shares the same close future.
Future<void> closeDatabase(AppDatabase db) => _closing[db] ??= db.close();
