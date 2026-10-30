import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/changes/write_gate.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/storage/device_id_store.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'change_providers.g.dart';

/// Makes the op handlers, one per family, for the applier's database.
/// Composed by `lib/app/app_scope.dart`, the only layer that sees every
/// feature (A01 §3.2).
@Riverpod(keepAlive: true)
OpHandlerFactory<AppDatabase> changeOpHandlers(
  Ref ref,
) => throw UnimplementedError(
  'changeOpHandlersProvider must be overridden (see lib/app/app_scope.dart).',
);

/// The app's single writer over the open profile's database.
@Riverpod(keepAlive: true)
ChangeSetApplier<AppDatabase> changeSetApplier(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final location = ref.watch(databaseLocationProvider);
  final applier = ChangeSetApplier(
    db: db,
    tables: db.syncedTables,
    handlers: ref.watch(changeOpHandlersProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
    deviceId: ref.watch(deviceIdStoreProvider).deviceId,
    events: ref.watch(domainEventBusProvider),
    gate: ref.watch(profileWriteGateProvider),
    profileKey: location.followsRegistry ? location.resolvedProfileKey : null,
    generation: ref.watch(profileGenerationProvider),
  );
  // A33: the account transitions reach the open profile through these
  // handles, never through this provider (a circular dependency).
  ref.read(openProfileHandlesProvider)
    ..database = db
    ..location = location
    ..idle = applier.idle;
  return applier;
}

/// A33 §6: the write gate (transition, read-only copy, inactive profile).
/// Null (always writable) unless the app wiring overrides it.
@Riverpod(keepAlive: true)
WriteGate? profileWriteGate(Ref ref) => null;
