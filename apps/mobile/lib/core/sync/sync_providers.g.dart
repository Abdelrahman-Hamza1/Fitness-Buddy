// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The codec factory; the generic codecs unless the app wiring overrides it.

@ProviderFor(syncCodecFactory)
final syncCodecFactoryProvider = SyncCodecFactoryProvider._();

/// The codec factory; the generic codecs unless the app wiring overrides it.

final class SyncCodecFactoryProvider
    extends
        $FunctionalProvider<
          SyncCodecFactory,
          SyncCodecFactory,
          SyncCodecFactory
        >
    with $Provider<SyncCodecFactory> {
  /// The codec factory; the generic codecs unless the app wiring overrides it.
  SyncCodecFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncCodecFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncCodecFactoryHash();

  @$internal
  @override
  $ProviderElement<SyncCodecFactory> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncCodecFactory create(Ref ref) {
    return syncCodecFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncCodecFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncCodecFactory>(value),
    );
  }
}

String _$syncCodecFactoryHash() => r'2a1586c030ea653ad300291a10dbcfa4588fe146';

/// The open profile's sync store (rebuilt with the database and applier on
/// a profile switch).

@ProviderFor(syncStore)
final syncStoreProvider = SyncStoreProvider._();

/// The open profile's sync store (rebuilt with the database and applier on
/// a profile switch).

final class SyncStoreProvider
    extends $FunctionalProvider<DriftSyncStore, DriftSyncStore, DriftSyncStore>
    with $Provider<DriftSyncStore> {
  /// The open profile's sync store (rebuilt with the database and applier on
  /// a profile switch).
  SyncStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncStoreHash();

  @$internal
  @override
  $ProviderElement<DriftSyncStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DriftSyncStore create(Ref ref) {
    return syncStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DriftSyncStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DriftSyncStore>(value),
    );
  }
}

String _$syncStoreHash() => r'72592ac3a15def16268a8b62c154bf3346a7c051';

/// The sync endpoints on the app's Dio (auth, client headers, guard).

@ProviderFor(syncTransport)
final syncTransportProvider = SyncTransportProvider._();

/// The sync endpoints on the app's Dio (auth, client headers, guard).

final class SyncTransportProvider
    extends $FunctionalProvider<SyncTransport, SyncTransport, SyncTransport>
    with $Provider<SyncTransport> {
  /// The sync endpoints on the app's Dio (auth, client headers, guard).
  SyncTransportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncTransportProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncTransportHash();

  @$internal
  @override
  $ProviderElement<SyncTransport> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncTransport create(Ref ref) {
    return syncTransport(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncTransport value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncTransport>(value),
    );
  }
}

String _$syncTransportHash() => r'891dddc7216c4a551b9eae1001da922216f1b6e1';

/// The indicator's local numbers, live.

@ProviderFor(syncCounts)
final syncCountsProvider = SyncCountsProvider._();

/// The indicator's local numbers, live.

final class SyncCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<LocalSyncCounts>,
          LocalSyncCounts,
          Stream<LocalSyncCounts>
        >
    with $FutureModifier<LocalSyncCounts>, $StreamProvider<LocalSyncCounts> {
  /// The indicator's local numbers, live.
  SyncCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncCountsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncCountsHash();

  @$internal
  @override
  $StreamProviderElement<LocalSyncCounts> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<LocalSyncCounts> create(Ref ref) {
    return syncCounts(ref);
  }
}

String _$syncCountsHash() => r'30fb6d1c891ba7ce8f63a69fe61c7b0a48f05322';

/// Runs sync (A34 D10–D13): owns the [SyncScheduler], decides whether a run
/// may start (registered, writable, ready session, no transition), runs
/// the engine on the open profile's store through a [GuardedSyncTransport],
/// and publishes a [SyncActivity]. Started by the post-frame bootstrap.

@ProviderFor(SyncController)
final syncControllerProvider = SyncControllerProvider._();

/// Runs sync (A34 D10–D13): owns the [SyncScheduler], decides whether a run
/// may start (registered, writable, ready session, no transition), runs
/// the engine on the open profile's store through a [GuardedSyncTransport],
/// and publishes a [SyncActivity]. Started by the post-frame bootstrap.
final class SyncControllerProvider
    extends $NotifierProvider<SyncController, SyncActivity> {
  /// Runs sync (A34 D10–D13): owns the [SyncScheduler], decides whether a run
  /// may start (registered, writable, ready session, no transition), runs
  /// the engine on the open profile's store through a [GuardedSyncTransport],
  /// and publishes a [SyncActivity]. Started by the post-frame bootstrap.
  SyncControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncControllerHash();

  @$internal
  @override
  SyncController create() => SyncController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncActivity value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncActivity>(value),
    );
  }
}

String _$syncControllerHash() => r'd0145cbf1bec8b524bd25fe152dc97271cda7adc';

/// Runs sync (A34 D10–D13): owns the [SyncScheduler], decides whether a run
/// may start (registered, writable, ready session, no transition), runs
/// the engine on the open profile's store through a [GuardedSyncTransport],
/// and publishes a [SyncActivity]. Started by the post-frame bootstrap.

abstract class _$SyncController extends $Notifier<SyncActivity> {
  SyncActivity build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SyncActivity, SyncActivity>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SyncActivity, SyncActivity>,
              SyncActivity,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
