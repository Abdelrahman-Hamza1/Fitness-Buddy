import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/account/profile_registry.dart';
import 'package:fb_mobile/core/api/api_providers.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/config/package_info.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/db/sync/drift_sync_store.dart';
import 'package:fb_mobile/core/db/sync/sync_codec.dart';
import 'package:fb_mobile/core/errors/error_reporting.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/core/session/session_providers.dart';
import 'package:fb_mobile/core/session/session_state.dart';
import 'package:fb_mobile/core/storage/device_id_store.dart';
import 'package:fb_mobile/core/sync/sync_guard.dart';
import 'package:fb_mobile/core/sync/sync_scheduler.dart';
import 'package:fb_mobile/core/sync/sync_status.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_sync/fb_sync.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_providers.g.dart';

/// Makes the entity codecs for a database (A34 D16): the generic column
/// codecs, overridden per entity by `app/app_scope.dart` (chat messages and
/// proposals use their feature mappers).
typedef SyncCodecFactory = Map<String, SyncEntityCodec> Function(
  AppDatabase db,
);

/// The codec factory; the generic codecs unless the app wiring overrides it.
@Riverpod(keepAlive: true)
SyncCodecFactory syncCodecFactory(Ref ref) =>
    (db) => columnSyncCodecs(db.syncedTables);

/// The open profile's sync store (rebuilt with the database and applier on
/// a profile switch).
@Riverpod(keepAlive: true)
DriftSyncStore syncStore(Ref ref) {
  // Watches the database only (a profile switch makes a new store). The
  // other collaborators are read when used: re-applied overrides (a new
  // device-id store, codec factory or applier) must not rebuild the store
  // and tear down the indicator's live counts query.
  final db = ref.watch(appDatabaseProvider);
  return DriftSyncStore(
    db,
    codecs: ref.read(syncCodecFactoryProvider)(db),
    clock: ref.read(clockProvider),
    deviceId: () => ref.read(deviceIdStoreProvider).deviceId(),
    // The current applier, read per remote apply; its write gate checks
    // the profile generation.
    exclusive: <T>(body) =>
        ref.read(changeSetApplierProvider).runExclusive(body),
  );
}

/// The sync endpoints on the app's Dio (auth, client headers, guard).
@Riverpod(keepAlive: true)
SyncTransport syncTransport(Ref ref) =>
    ApiSyncTransport(ref.watch(dioProvider));

/// The indicator's local numbers, live.
@Riverpod(keepAlive: true)
Stream<LocalSyncCounts> syncCounts(Ref ref) =>
    ref.watch(syncStoreProvider).watchCounts();

/// Runs sync (A34 D10–D13): owns the [SyncScheduler], decides whether a run
/// may start (registered, writable, ready session, no transition), runs
/// the engine on the open profile's store through a [GuardedSyncTransport],
/// and publishes a [SyncActivity]. Started by the post-frame bootstrap.
@Riverpod(keepAlive: true)
class SyncController extends _$SyncController with WidgetsBindingObserver {
  SyncScheduler? _scheduler;
  bool _paused = false;
  StreamSubscription<ChangeSetApplied>? _changes;

  @override
  SyncActivity build() {
    ref.onDispose(() {
      _scheduler?.dispose();
      unawaited(_changes?.cancel());
      if (_scheduler != null) {
        WidgetsBinding.instance.removeObserver(this);
      }
    });
    return const SyncActivity();
  }

  /// The scheduler, for tests.
  @visibleForTesting
  SyncScheduler? get scheduler => _scheduler;

  /// Starts scheduling after the first frame (UX-001): local change sets,
  /// foreground, the session becoming ready.
  void start({
    Timer Function(Duration, void Function()) schedule = Timer.new,
    bool observeLifecycle = true,
  }) {
    if (_scheduler != null) return;
    final scheduler = _scheduler = SyncScheduler(_run, schedule: schedule);
    _changes = ref
        .read(domainEventBusProvider)
        .on<ChangeSetApplied>()
        // Only once a run found sync enabled: a guest's change sets arm no
        // timer.
        .listen((_) {
          if (state.enabled) scheduler.localChange();
        });
    ref
      ..listen(sessionStateProvider, (previous, next) {
        if (next.readiness == SessionReadiness.ready &&
            previous?.readiness != SessionReadiness.ready) {
          scheduler.reconnected();
        }
      })
      ..listen(profileGenerationProvider, (_, _) {
        state = const SyncActivity();
        scheduler.reconnected();
      });
    var foreground = true;
    if (observeLifecycle) {
      final binding = WidgetsBinding.instance..addObserver(this);
      final lifecycle = binding.lifecycleState;
      foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    }
    scheduler.start(foreground: foreground);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _scheduler?.setForeground(foreground: state == AppLifecycleState.resumed);

  /// "Sync now" and pull-to-refresh.
  Future<SyncRunOutcome> syncNow() =>
      _scheduler?.syncNow() ?? Future.value(const SyncRunSkipped());

  /// "Try again" for parked changes (A34 D5), then a run.
  Future<void> retryParked() async {
    await ref.read(syncStoreProvider).retryParked();
    unawaited(syncNow());
  }

  /// Stops new runs and requests; an in-flight request is refused by the
  /// guard before it is sent. (An account deletion pauses sync through
  /// `AccountTransitions.deleting`.)
  void pause() => _paused = true;

  /// Allows runs again.
  void resume() => _paused = false;

  Future<bool> _enabled() async {
    if (_paused) return false;
    final session = ref.read(sessionStateProvider);
    if (session.status != SessionStatus.registered ||
        session.readiness != SessionReadiness.ready) {
      return false;
    }
    final transitions = ref.read(accountTransitionsProvider);
    // A35: no sync while an account deletion request is in flight.
    if (transitions.suspended || transitions.deleting) return false;
    final profile = (await ref.read(profileRegistryProvider).read()).active;
    return profile.kind == ProfileKind.registered && !profile.readOnly;
  }

  Future<SyncRunOutcome> _run() async {
    if (!ref.mounted) return const SyncRunSkipped();
    if (!await _enabled()) {
      state = state.copyWith(enabled: false, running: false);
      return const SyncRunSkipped();
    }
    final generation = ref.read(profileGenerationProvider);
    final transitions = ref.read(accountTransitionsProvider);
    final store = ref.read(syncStoreProvider);
    final reporting = ref.read(errorReportingProvider);
    final bus = ref.read(domainEventBusProvider);
    // Requests stop once the app leaves the foreground (A34 fix 6): the
    // next foreground runs again.
    bool valid() =>
        !_paused &&
        ref.mounted &&
        (_scheduler?.foreground ?? true) &&
        ref.read(profileGenerationProvider) == generation &&
        !transitions.suspended &&
        !transitions.deleting;
    state = state.copyWith(running: true, enabled: true, restoredRows: 0);
    try {
      final version = (await ref.read(packageInfoProvider.future)).version;
      await store.retryParkedIfDue(
        nowMs: ref.read(clockProvider).nowUtc().millisecondsSinceEpoch,
        appVersion: version,
      );
      final engine = SyncEngine(
        store: store,
        transport: GuardedSyncTransport(ref.read(syncTransportProvider), valid),
        onProgress: (progress) {
          if (!valid()) return;
          state = state.copyWith(
            restoring: progress.firstSync,
            restoredRows: progress.pulledRows,
          );
        },
        onApplied: (entities) => bus.emit(RemoteChangesApplied(entities)),
        onParked: (parked) {
          for (final p in parked) {
            reporting.reportSyncIssue(
              issue: 'parked',
              entity: p.version.entity,
              reason: p.reason,
            );
          }
        },
        onDeferred: (deferred) {
          for (final d in deferred) {
            reporting.reportSyncIssue(
              issue: 'deferred',
              entity: d.version.entity,
              reason: d.reason,
            );
          }
        },
      );
      await engine.run();
      await store.recordSuccess(ref.read(clockProvider).nowUtc());
      _publish(SyncProblem.none, generation);
      return const SyncRunSucceeded();
    } on SyncFailure catch (failure) {
      if (!(_scheduler?.foreground ?? true)) {
        // Stopped by backgrounding, not a problem to show.
        _publish(SyncProblem.none, generation);
        return const SyncRunSkipped();
      }
      _publish(_problemOf(failure.kind), generation);
      return SyncRunFailed(failure.kind, retryAfter: failure.retryAfter);
    } on RemoteApplyDenied {
      _publish(SyncProblem.none, generation);
      return const SyncRunSkipped();
    } on Object catch (error) {
      reporting.reportKind(error);
      _publish(SyncProblem.error, generation);
      return const SyncRunFailed(SyncFailureKind.server);
    }
  }

  void _publish(SyncProblem problem, int generation) {
    if (!ref.mounted || ref.read(profileGenerationProvider) != generation) {
      return;
    }
    state = state.copyWith(running: false, restoring: false, problem: problem);
  }

  static SyncProblem _problemOf(SyncFailureKind kind) => switch (kind) {
    SyncFailureKind.offline ||
    SyncFailureKind.server ||
    SyncFailureKind.rateLimited => SyncProblem.offline,
    SyncFailureKind.unauthorized ||
    SyncFailureKind.forbidden => SyncProblem.needsSignIn,
    SyncFailureKind.clockAhead => SyncProblem.clockAhead,
    SyncFailureKind.clockBehind => SyncProblem.clockBehind,
    SyncFailureKind.upgradeRequired => SyncProblem.updateRequired,
    SyncFailureKind.payloadTooLarge ||
    SyncFailureKind.protocol ||
    SyncFailureKind.datasetUnstable => SyncProblem.error,
  };
}
