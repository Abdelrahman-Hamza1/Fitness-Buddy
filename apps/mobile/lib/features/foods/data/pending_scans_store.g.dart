// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_scans_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The environment namespace of device-local per-profile state, the same as
/// the profile registry's.

@ProviderFor(pendingScansNamespace)
final pendingScansNamespaceProvider = PendingScansNamespaceProvider._();

/// The environment namespace of device-local per-profile state, the same as
/// the profile registry's.

final class PendingScansNamespaceProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// The environment namespace of device-local per-profile state, the same as
  /// the profile registry's.
  PendingScansNamespaceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingScansNamespaceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingScansNamespaceHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return pendingScansNamespace(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$pendingScansNamespaceHash() =>
    r'298794c1d032b5f0d51fc5aaf8989303aeca937b';

/// The open profile's pending-scan store (review fix 1). Rebuilt on every
/// profile switch (the generation and the selected key), so the list and
/// everything reading it follow the profile.

@ProviderFor(pendingScansStore)
final pendingScansStoreProvider = PendingScansStoreProvider._();

/// The open profile's pending-scan store (review fix 1). Rebuilt on every
/// profile switch (the generation and the selected key), so the list and
/// everything reading it follow the profile.

final class PendingScansStoreProvider
    extends
        $FunctionalProvider<
          AsyncValue<PendingScansStore>,
          PendingScansStore,
          FutureOr<PendingScansStore>
        >
    with
        $FutureModifier<PendingScansStore>,
        $FutureProvider<PendingScansStore> {
  /// The open profile's pending-scan store (review fix 1). Rebuilt on every
  /// profile switch (the generation and the selected key), so the list and
  /// everything reading it follow the profile.
  PendingScansStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingScansStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingScansStoreHash();

  @$internal
  @override
  $FutureProviderElement<PendingScansStore> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PendingScansStore> create(Ref ref) {
    return pendingScansStore(ref);
  }
}

String _$pendingScansStoreHash() => r'e945e2ea73a9dddb0f24f21b07cb02ea787c0a3d';
